#!/bin/bash

# Définition des couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Chemin vers le fichier UnifiedStudyService.swift
FILE_PATH="Core/Services/Unified/UnifiedStudyService.swift"

# Vérifier si le fichier existe
if [ ! -f "$FILE_PATH" ]; then
    echo -e "${RED}Erreur: Le fichier $FILE_PATH n'existe pas.${NC}"
    exit 1
fi

# Créer un répertoire de sauvegarde avec horodatage
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups_manual_fixes_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Créer une copie de sauvegarde
cp "$FILE_PATH" "$BACKUP_DIR/UnifiedStudyService.swift"
echo -e "${GREEN}Sauvegarde créée dans $BACKUP_DIR/UnifiedStudyService.swift${NC}"

# Créer un fichier temporaire pour les modifications
TMP_FILE=$(mktemp)

# Fonction pour remplacer complètement le fichier avec une version corrigée
replace_entire_file() {
    echo -e "${BLUE}Remplacement du fichier entier avec une version corrigée...${NC}"
    
    # Nous allons créer directement un nouveau fichier propre
    cat > "$TMP_FILE" << 'EOF'
import Foundation
import Combine
import CoreData
import Core

/// Service unifié pour les fonctionnalités d'étude
/// Implémente le protocole StudyServiceProtocol
@MainActor
public final class UnifiedStudyService: StudyServiceProtocol, @unchecked Sendable {
    // MARK: - Propriétés
    
    private let persistence: PersistenceController
    private let cardService: CardServiceProtocol
    private let logger = Logger(subsystem: "com.app.cardapp", category: "UnifiedStudyService")
    private let deckService: DeckServiceProtocol?
    private let scheduler: CardSchedulerProtocolV2?
    
    private var currentSessionSubject = CurrentValueSubject<StudySession?, Never>(nil)
    public var currentSessionPublisher: AnyPublisher<StudySession?, Never> {
        return currentSessionSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialisation
    
    public init(persistence: PersistenceController, cardService: CardServiceProtocol) {
        self.persistence = persistence
        self.cardService = cardService
        self.deckService = nil
        self.scheduler = CardScheduler()
        
        // Vérifier s'il y a une session active au démarrage
        logger.log("Rafraîchissement de la session courante")
        refreshCurrentSession()
    }
    
    public init(
        persistenceController: PersistenceController,
        cardService: CardServiceProtocol,
        deckService: DeckServiceProtocol,
        scheduler: CardSchedulerProtocolV2
    ) {
        self.persistence = persistenceController
        self.cardService = cardService
        self.deckService = deckService
        self.scheduler = scheduler
        
        // Vérifier s'il y a une session active au démarrage
        logger.log("Rafraîchissement de la session courante avec dépendances")
        refreshCurrentSession()
    }
    
    // MARK: - Méthodes privées
    
    private func viewContext() -> NSManagedObjectContext {
        return persistence.container.viewContext
    }
    
    private func newBackgroundContext() -> NSManagedObjectContext {
        return persistence.container.newBackgroundContext()
    }
    
    private func fetchCurrentSession() async throws -> StudySession? {
        let context = newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "endTime == nil")
        fetchRequest.fetchBatchSize = 20
        fetchRequest.fetchLimit = 1
        
        return try await context.performAsync {
            guard let entity = try context.fetch(fetchRequest).first else {
                return nil
            }
            
            return try await self.mapStudySessionEntityToModel(entity)
        }
    }
    
    // MARK: - Implémentation du protocole StudyServiceProtocol
    
    public func createSession(deckID: UUID, includeSubdecks: Bool, reviewLimit: Int?) async throws -> StudySession {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Vérifier s'il y a déjà une session active
            let activeSessionFetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
            activeSessionFetchRequest.predicate = NSPredicate(format: "endTime == nil")
            activeSessionFetchRequest.fetchBatchSize = 20
            activeSessionFetchRequest.fetchLimit = 1
            
            if try context.fetch(activeSessionFetchRequest).first != nil {
                logger.log("Tentative de création d'une session alors qu'une est déjà active")
                throw StudyServiceError.sessionAlreadyStarted
            }
            
            // Créer la nouvelle session
            let sessionEntity = StudySessionEntity(context: context)
            sessionEntity.id = UUID()
            sessionEntity.deckID = deckID
            sessionEntity.startTime = Date()
            sessionEntity.includeSubdecks = includeSubdecks
            sessionEntity.reviewLimit = Int32(reviewLimit ?? 0)
            sessionEntity.totalReviews = 0
            sessionEntity.totalCorrect = 0
            sessionEntity.totalIncorrect = 0
            sessionEntity.totalTime = 0
            
            do {
                try context.save()
                logger.log("Contexte sauvegardé avec succès")
            } catch {
                logger.error("Erreur lors de la sauvegarde du contexte: \(error)")
                throw error
            }
            
            let session = try await self.mapStudySessionEntityToModel(sessionEntity)
            
            // Mettre à jour le sujet de session courante
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.currentSessionSubject.send(session)
                logger.log("Session courante mise à jour : \(session.id ?? UUID())")
            }
            
            return session
        }
    }
    
    public func getSession(byID id: UUID) async throws -> StudySession {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchBatchSize = 20
            fetchRequest.fetchLimit = 1
            
            guard let entity = try context.fetch(fetchRequest).first else {
                throw StudyServiceError.sessionNotFound
            }
            
            return try await self.mapStudySessionEntityToModel(entity)
        }
    }
    
    public func updateSession(_ session: StudySession) async throws -> StudySession {
        let context = newBackgroundContext()
        
        // Création d'une structure Sendable pour transférer les données entre contextes
        struct SendableSessionData: Sendable {
            let id: UUID
            let deckID: UUID
            let startDate: Date
            let endDate: Date?
            let includeSubdecks: Bool
            let reviewLimit: Int32
            let reviews: [(
                id: UUID?,
                cardID: UUID?,
                rating: Int,
                responseTime: Double
            )]
        }
        
        // Récupérer les données de session de manière sûre pour la concurrence
        let sessionData = try await context.performAsync {
            let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
            fetchRequest.fetchBatchSize = 20
            fetchRequest.fetchLimit = 1
            
            guard let entity = try context.fetch(fetchRequest).first else {
                throw StudyServiceError.sessionNotFound
            }
            
            // Mettre à jour les propriétés
            entity.endTime = session.endDate
            entity.includeSubdecks = session.includeSubdecks
            entity.reviewLimit = Int32(session.reviewLimit ?? 0)
            
            // Sauvegarder le contexte
            do {
                try context.save()
                logger.log("Contexte sauvegardé avec succès")
            } catch {
                logger.error("Erreur lors de la sauvegarde du contexte: \(error)")
                throw error
            }
            
            // Extraire les données dans un format Sendable
            let reviewsData = Array(entity.reviews).map { review in
                return (
                    id: review.id,
                    cardID: review.card?.id,
                    rating: Int(review.rating) ?? 0,
                    responseTime: review.responseTime
                )
            }
            
            return SendableSessionData(
                id: entity.id ?? UUID(),
                deckID: entity.deckID ?? UUID(),
                startDate: entity.startTime ?? Date(),
                endDate: entity.endTime,
                includeSubdecks: entity.includeSubdecks,
                reviewLimit: entity.reviewLimit,
                reviews: reviewsData
            )
        }
        
        // Calculer les statistiques et construire le modèle StudySession
        let correctCount = sessionData.reviews.filter { review in
            let rating = review.rating
            return rating == 2 || rating == 3 // .good or .easy
        }.count
        
        let incorrectCount = sessionData.reviews.count - correctCount
        let reviewedCardIDs = Set(sessionData.reviews.compactMap { $0.cardID })
        
        // Calculer le temps total d'étude si possible
        let totalStudyTime: TimeInterval
        if let endDate = sessionData.endDate {
            totalStudyTime = endDate.timeIntervalSince(sessionData.startDate)
        } else {
            totalStudyTime = sessionData.reviews.reduce(0.0) { $0 + $1.responseTime }
        }
        
        let updatedSession = StudySession(
            id: sessionData.id,
            deckID: sessionData.deckID,
            startDate: sessionData.startDate,
            endDate: sessionData.endDate,
            scheduledCards: Array(reviewedCardIDs), // On utilise les mêmes IDs pour simplifier
            reviewedCards: Array(reviewedCardIDs),
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            includeSubdecks: sessionData.includeSubdecks,
            reviewLimit: sessionData.reviewLimit > 0 ? Int(sessionData.reviewLimit) : nil,
            totalStudyTime: totalStudyTime
        )
        
        // Si c'est la session active, mettre à jour le sujet
        if sessionData.endDate == nil {
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.currentSessionSubject.send(updatedSession)
            }
        }
        
        self.logger.info("Session d'étude mise à jour: \(session.id)")
        return updatedSession
    }
    
    public func endSession(_ session: StudySession) async throws -> StudySession {
        let context = newBackgroundContext()
        
        // Utilisation de la même structure SendableSessionData que dans updateSession
        struct SendableSessionData: Sendable {
            let id: UUID
            let deckID: UUID
            let startDate: Date
            let endDate: Date?
            let includeSubdecks: Bool
            let reviewLimit: Int32
            let reviews: [(
                id: UUID?,
                cardID: UUID?,
                rating: Int,
                responseTime: Double
            )]
        }
        
        // Récupérer les données de session de manière sûre pour la concurrence
        let sessionData = try await context.performAsync {
            let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
            fetchRequest.fetchBatchSize = 20
            fetchRequest.fetchLimit = 1
            
            guard let sessionEntity = try context.fetch(fetchRequest).first else {
                throw StudyServiceError.sessionNotFound
            }
            
            sessionEntity.endTime = Date()
            do {
                try context.save()
                logger.log("Contexte sauvegardé avec succès")
            } catch {
                logger.error("Erreur lors de la sauvegarde du contexte: \(error)")
                throw error
            }
            
            // Extraire les données dans un format Sendable
            let reviewsData = Array(sessionEntity.reviews).map { review in
                return (
                    id: review.id,
                    cardID: review.card?.id,
                    rating: Int(review.rating) ?? 0,
                    responseTime: review.responseTime
                )
            }
            
            return SendableSessionData(
                id: sessionEntity.id ?? UUID(),
                deckID: sessionEntity.deckID ?? UUID(),
                startDate: sessionEntity.startTime ?? Date(),
                endDate: sessionEntity.endTime,
                includeSubdecks: sessionEntity.includeSubdecks,
                reviewLimit: sessionEntity.reviewLimit,
                reviews: reviewsData
            )
        }
        
        // Calculer les statistiques et construire le modèle StudySession
        let correctCount = sessionData.reviews.filter { review in
            let rating = review.rating
            return rating == 2 || rating == 3 // .good or .easy
        }.count
        
        let incorrectCount = sessionData.reviews.count - correctCount
        let reviewedCardIDs = Set(sessionData.reviews.compactMap { $0.cardID })
        
        // Calculer le temps total d'étude si possible
        let totalStudyTime: TimeInterval
        if let endDate = sessionData.endDate {
            totalStudyTime = endDate.timeIntervalSince(sessionData.startDate)
        } else {
            totalStudyTime = sessionData.reviews.reduce(0.0) { $0 + $1.responseTime }
        }
        
        let endedSession = StudySession(
            id: sessionData.id,
            deckID: sessionData.deckID,
            startDate: sessionData.startDate,
            endDate: sessionData.endDate,
            scheduledCards: Array(reviewedCardIDs), // On utilise les mêmes IDs pour simplifier
            reviewedCards: Array(reviewedCardIDs),
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            includeSubdecks: sessionData.includeSubdecks,
            reviewLimit: sessionData.reviewLimit > 0 ? Int(sessionData.reviewLimit) : nil,
            totalStudyTime: totalStudyTime
        )
        
        // Mettre à jour le sujet de session courante
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            self.currentSessionSubject.send(nil) // La session active est terminée
        }
            
        return endedSession
    }
    
    public func getScheduledCards(forSessionID sessionID: UUID) async throws -> [Card] {
        let context = newBackgroundContext()
        
        // Récupérer la session
        let sessionFetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
        sessionFetchRequest.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
        sessionFetchRequest.fetchBatchSize = 20
        sessionFetchRequest.fetchLimit = 1
        
        return try await context.performAsync {
            guard let session = try context.fetch(sessionFetchRequest).first else {
                throw StudyServiceError.sessionNotFound
            }
            
            // Récupérer les cartes associées aux révisions
            let cardIDs = Array(session.reviews).compactMap { $0.card?.id }
            let cardsFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            cardsFetchRequest.predicate = NSPredicate(format: "id IN %@", cardIDs)
            cardsFetchRequest.fetchBatchSize = 20
            
            let cards = try context.fetch(cardsFetchRequest)
            return cards.map { Card(from: $0) }
        }
    }
    
    public func getReviewedCards(forSessionID sessionID: UUID) async throws -> [Card] {
        let context = newBackgroundContext()
        
        // Récupérer la session
        let sessionFetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
        sessionFetchRequest.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
        sessionFetchRequest.fetchBatchSize = 20
        sessionFetchRequest.fetchLimit = 1
        
        return try await context.performAsync {
            guard let session = try context.fetch(sessionFetchRequest).first else {
                throw StudyServiceError.sessionNotFound
            }
            
            // Récupérer les cartes associées aux révisions
            let cardIDs = Array(session.reviews).compactMap { $0.card?.id }
            let cardsFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            cardsFetchRequest.predicate = NSPredicate(format: "id IN %@", cardIDs)
            cardsFetchRequest.fetchBatchSize = 20
            
            let cards = try context.fetch(cardsFetchRequest)
            return cards.map { Card(from: $0) }
        }
    }
    
    // Définitions des structures Sendable
    // MARK: - Structures Sendable pour le passage de données entre acteurs
    
    /// Structure Sendable pour les données de révision
    private struct SendableReviewData: Sendable {
        let timestamp: Date
        let rating: ReviewRating
        let responseTime: Double
    }
    
    /// Structure Sendable pour les données de carte
    private struct SendableCardData: Sendable {
        let id: UUID
        let masteryLevel: Int16
        let nextReviewDate: Date?
        let reviews: [SendableReviewData]
    }
    
    /// Structure Sendable pour les données de révision de carte
    private struct SendableCardReviewData: Sendable {
        let id: UUID?
        let cardID: UUID
        let sessionID: UUID?
        let timestamp: Date
        let rating: ReviewRating
        let responseTime: Double
        let newInterval: Int16
        let newEase: Double
        let newMasteryLevel: Int16
    }
    
    /// Structure Sendable pour les données de révision de session
    private struct SendableSessionReviewData: Sendable {
        let cardID: UUID?
        let timestamp: Date
        let rating: ReviewRating
        let responseTime: Double
    }
    
    // MARK: - Méthodes utilitaires
    
    /// Récupère les cartes dues pour un paquet donné
    private func getDueCards(forDeckID deckID: UUID, includeSubdecks: Bool, limit: Int? = nil) async throws -> [Card] {
        let context = newBackgroundContext()
        
        // Créer la requête pour les cartes dues
        let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
        
        fetchRequest.fetchBatchSize = 20 // Gérer les sous-paquets si nécessaire
        
        // Gérer les sous-paquets si nécessaire
        if includeSubdecks {
            // Cette partie nécessiterait de récupérer récursivement les IDs des sous-paquets
            // Pour simplifier, on suppose que nous avons seulement le paquet principal
            fetchRequest.predicate = NSPredicate(format: "deckID == %@ AND (nextReviewDate <= %@ OR nextReviewDate == nil)", 
                                                deckID as CVarArg, 
                                                Date() as NSDate)
        } else {
            fetchRequest.predicate = NSPredicate(format: "deckID == %@ AND (nextReviewDate <= %@ OR nextReviewDate == nil)", 
                                                deckID as CVarArg, 
                                                Date() as NSDate)
        }
        
        // Ajouter une limite si spécifiée
        if let limit = limit, limit > 0 {
            fetchRequest.fetchLimit = limit
        }
        
        // Trier par date de révision (d'abord les plus anciennes)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "nextReviewDate", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        
        return try await context.performAsync {
            // Exécuter la requête
            let cardEntities = try context.fetch(fetchRequest)
            
            // Convertir les entités en modèles Card
            return cardEntities.map { Card(from: $0) }
        }
    }
    
    private func getDueCards(for deckID: UUID, limit: Int? = nil) async throws -> [Card] {
        let context = newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "deckID == %@ AND (nextReviewDate <= %@ OR nextReviewDate == nil)", 
                                            deckID as CVarArg, 
                                            Date() as NSDate)
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CardEntity.nextReviewDate, ascending: true)]
        
        if let limit = limit {
            fetchRequest.fetchLimit = limit
        }
        
        return try await context.performAsync {
            let entities = try context.fetch(fetchRequest)
            return entities.map { Card(from: $0) }
        }
    }
    
    @MainActor
    private func mapStudySessionEntityToModel(_ entity: StudySessionEntity) async throws -> StudySession {
        // Extraire les données en structures sendable
        let reviews = Array(entity.reviews)
        let reviewedCardIDs = Set(reviews.compactMap { $0.card?.id })
        
        // Calculer les statistiques en utilisant une méthode nonisolated
        let sessionStats = calculateSessionStats(
            reviews: reviews,
            reviewedCardIDs: Array(reviewedCardIDs),
            startTime: entity.startTime ?? Date(),
            endTime: entity.endTime,
            includeSubdecks: entity.includeSubdecks,
            reviewLimit: entity.reviewLimit
        )
        
        return sessionStats
    }
    
    /// Calcule les statistiques d'une session à partir des données brutes de manière thread-safe
    nonisolated private func calculateSessionStats(
        reviews: [CardReviewEntity],
        reviewedCardIDs: [UUID],
        startTime: Date,
        endTime: Date?,
        includeSubdecks: Bool,
        reviewLimit: Int32
    ) -> StudySession {
        // Protéger contre les données invalides
        guard !reviews.isEmpty || !reviewedCardIDs.isEmpty else {
            return StudySession(
                id: UUID(),
                deckID: UUID(),
                startDate: startTime,
                endDate: endTime,
                scheduledCards: [],
                reviewedCards: [],
                correctCount: 0,
                incorrectCount: 0,
                includeSubdecks: includeSubdecks,
                reviewLimit: reviewLimit > 0 ? Int(reviewLimit) : nil,
                totalStudyTime: 0
            )
        }
        
        // Calculer les statistiques de manière plus robuste
        let correctCount = reviews.filter { review in
            let rating = Int(review.rating) ?? 0
            return rating == 2 || rating == 3 // .good or .easy
        }.count
        
        let incorrectCount = reviews.count - correctCount
        
        // Calculer le temps total d'étude avec protection contre les valeurs invalides
        let totalStudyTime: TimeInterval
        if let endTime = endTime, endTime > startTime {
            totalStudyTime = endTime.timeIntervalSince(startTime)
        } else {
            totalStudyTime = max(0, reviews.reduce(0.0) { $0 + max(0, $1.responseTime) })
        }
        
        return StudySession(
            id: reviews.first?.session?.id ?? UUID(),
            deckID: reviews.first?.session?.deckID ?? UUID(),
            startDate: startTime,
            endDate: endTime,
            scheduledCards: reviewedCardIDs,
            reviewedCards: reviewedCardIDs,
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            includeSubdecks: includeSubdecks,
            reviewLimit: reviewLimit > 0 ? Int(reviewLimit) : nil,
            totalStudyTime: totalStudyTime
        )
    }
    
    nonisolated private func mapCardReviewEntityToModel(_ entity: CardReviewEntity) -> CardReview {
        return CardReview(
            id: entity.id ?? UUID(),
            cardID: entity.card?.id ?? UUID(),
            sessionID: entity.session?.id,
            timestamp: entity.timestamp,
            rating: entity.reviewRating,
            responseTime: entity.responseTime,
            newInterval: Int(entity.newInterval),
            newEase: entity.newEase,
            newMasteryLevel: MasteryLevel(rawValue: Int(entity.newMasteryLevel)) ?? .novice
        )
    }
    
    // Mettre à jour également les méthodes Task et DispatchQueue.main.async
    private func refreshCurrentSession() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let currentSession = try await fetchCurrentSession()
                self.currentSessionSubject.send(currentSession)
                logger.log("Session courante mise à jour: \(currentSession?.id?.uuidString ?? "nil")")
            } catch {
                logger.error("Erreur lors du rafraîchissement de la session: \(error)")
            }
        }
    }
}
EOF
    
    # Remplacer le fichier original par notre version manuellement corrigée
    mv "$TMP_FILE" "$FILE_PATH"
    
    echo -e "${GREEN}Le fichier a été remplacé par une version manuellement corrigée.${NC}"
}

# Fonction principale d'exécution
main() {
    echo -e "${BLUE}Démarrage des corrections manuelles pour $FILE_PATH...${NC}"
    
    # Appliquer toutes les corrections
    replace_entire_file
    
    echo -e "${GREEN}Corrections manuelles terminées.${NC}"
    echo -e "${YELLOW}Note: La version originale du fichier a été sauvegardée dans $BACKUP_DIR/UnifiedStudyService.swift${NC}"
}

# Exécution du script
main 