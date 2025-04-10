import Foundation
import Core
import Combine
import CoreData
import OSLog

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
                throw Core.Common.StudyServiceError.sessionAlreadyStarted
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
                logger.log("Session courante mise à jour : \(session.id)")
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
                throw Core.Common.StudyServiceError.sessionNotFound
            }
            
            return try await self.mapStudySessionEntityToModel(entity)
        }
    }
    
    public func updateSession(_ session: StudySession) async throws -> StudySession {
        let context = newBackgroundContext()
        
        // Récupérer les données de session de manière sûre pour la concurrence
        let sessionData = try await context.performAsync {
            let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
            fetchRequest.fetchBatchSize = 20
            fetchRequest.fetchLimit = 1
            
            guard let entity = try context.fetch(fetchRequest).first else {
                throw Core.Common.StudyServiceError.sessionNotFound
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
        
        // Récupérer les données de session de manière sûre pour la concurrence
        let sessionData = try await context.performAsync {
            let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
            fetchRequest.fetchBatchSize = 20
            fetchRequest.fetchLimit = 1
            
            guard let sessionEntity = try context.fetch(fetchRequest).first else {
                throw Core.Common.StudyServiceError.sessionNotFound
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
    
    // Méthode utilitaire pour récupérer les cartes d'une session
    private func getCardsForSession(_ sessionID: UUID, context: NSManagedObjectContext) async throws -> [Card] {
        let sessionFetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
        sessionFetchRequest.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
        sessionFetchRequest.fetchBatchSize = 20
        sessionFetchRequest.fetchLimit = 1
        
        guard let session = try context.fetch(sessionFetchRequest).first else {
            throw Core.Common.StudyServiceError.sessionNotFound
        }
        
        // Récupérer les cartes associées aux révisions
        let cardIDs = Array(session.reviews).compactMap { $0.card?.id }
        let cardsFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
        cardsFetchRequest.predicate = NSPredicate(format: "id IN %@", cardIDs)
        cardsFetchRequest.fetchBatchSize = 20
        
        let cards = try context.fetch(cardsFetchRequest)
        return cards.map { Card(from: $0) }
    }
    
    public func getScheduledCards(forSessionID sessionID: UUID) async throws -> [Card] {
        let context = newBackgroundContext()
        return try await context.performAsync {
            try await getCardsForSession(sessionID, context: context)
        }
    }
    
    public func getReviewedCards(forSessionID sessionID: UUID) async throws -> [Card] {
        let context = newBackgroundContext()
        return try await context.performAsync {
            try await getCardsForSession(sessionID, context: context)
        }
    }
    
    // MARK: - Structures Sendable pour le passage de données entre acteurs
    
    /// Structure Sendable pour les données de révision
    struct SendableReviewData: Sendable {
        let id: UUID?
        let cardID: UUID
        let sessionID: UUID?
        let timestamp: Date
        let rating: Core.Common.ReviewRating
        let responseTime: Double
    }
    
    /// Structure Sendable pour les données de carte
    struct SendableCardData: Sendable {
        let id: UUID
        let masteryLevel: Int16
        let nextReviewDate: Date?
        let reviews: [SendableReviewData]
    }
    
    /// Structure Sendable pour les données de révision de carte
    struct SendableCardReviewData: Sendable {
        let id: UUID?
        let cardID: UUID
        let sessionID: UUID?
        let timestamp: Date
        let rating: Core.Common.ReviewRating
        let responseTime: Double
        let newInterval: Int16
        let newEase: Double
        let newMasteryLevel: Int16
    }
    
    /// Structure Sendable pour les données de révision de session
    struct SendableSessionReviewData: Sendable {
        let cardID: UUID?
        let timestamp: Date
        let rating: Core.Common.ReviewRating
        let responseTime: Double
    }
    
    /// Structure Sendable pour les données de session
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
    
    // MARK: - Méthodes utilitaires
    
    /// Récupère les cartes dues pour un paquet donné, avec option d'inclure les sous-paquets.
    /// Fonction fusionnée et avec logique includeSubdecks implémentée.
    private func getDueCards(forDeckID deckID: UUID, includeSubdecks: Bool, limit: Int? = nil) async throws -> [Card] {
        let context = newBackgroundContext()
        
        // Déterminer les IDs de paquets à inclure
        var targetDeckIDs: [UUID] = [deckID]
        if includeSubdecks {
            if let deckService = self.deckService {
                do {
                    // Note: Pour activer complètement la fonctionnalité includeSubdecks, 
                    // il faut implémenter la méthode suivante dans DeckServiceProtocol:
                    //
                    // func getAllSubdeckIDsIncludingParent(for deckID: UUID) async throws -> [UUID]
                    //
                    // Cette méthode devrait retourner l'ID du paquet parent ainsi que les IDs de tous ses sous-paquets récursivement.
                    
                    // VERSION TEMPORAIRE: Utiliser seulement le paquet principal
                    // Décommenter et adapter quand la méthode sera implémentée:
                    /*
                    let subdeckIDs = try await deckService.getAllSubdeckIDsIncludingParent(for: deckID)
                    if !subdeckIDs.isEmpty {
                        targetDeckIDs = subdeckIDs
                        logger.debug("Inclusion des sous-paquets: \(targetDeckIDs.count) paquets ciblés.")
                    } else {
                        logger.debug("includeSubdecks est vrai mais aucun sous-paquet trouvé pour \(deckID)")
                    }
                    */
                    
                    // Utilisation de targetDeckIDs = [deckID] temporairement (paquet principal seulement)
                    logger.warning("La méthode getAllSubdeckIDsIncludingParent n'est pas implémentée dans DeckServiceProtocol. Utilisation du paquet principal uniquement.")
                } catch {
                    logger.error("Erreur lors de la récupération des sous-paquets pour \(deckID): \(error). Retour au paquet principal uniquement.")
                    // En cas d'erreur, on continue avec le paquet principal seul
                }
            } else {
                logger.warning("deckService non disponible, impossible d'inclure les sous-paquets.")
                // Comportement fallback: utiliser uniquement le deckID principal
            }
        }

        return try await context.performAsync {
            // Créer la requête pour les cartes dues
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            
            // Construire le prédicat
            let datePredicate = NSPredicate(format: "(nextReviewDate <= %@ OR nextReviewDate == nil)", Date() as NSDate)
            let deckPredicate: NSPredicate
            if targetDeckIDs.count > 1 {
                deckPredicate = NSPredicate(format: "deckID IN %@", targetDeckIDs)
                 logger.debug("Prédicat pour getDueCards: deckID IN [...]")
            } else {
                deckPredicate = NSPredicate(format: "deckID == %@", deckID as CVarArg)
                 logger.debug("Prédicat pour getDueCards: deckID == %@")
            }
            
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [deckPredicate, datePredicate])
            
            // Ajouter une limite si spécifiée
            if let limit = limit, limit > 0 {
                fetchRequest.fetchLimit = limit
            }
            
            fetchRequest.fetchBatchSize = 20 // Garder une taille de batch raisonnable
            
            // Trier par date de révision (d'abord les plus anciennes), puis par date de création
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \CardEntity.nextReviewDate, ascending: true),
                NSSortDescriptor(keyPath: \CardEntity.createdAt, ascending: true)
            ]
            
            // Exécuter la requête
            let cardEntities = try context.fetch(fetchRequest)
            logger.info("\(cardEntities.count) cartes dues trouvées pour les paquets ciblés.")
            
            // Convertir les entités en modèles Card
            // Assurez-vous que Card(from: CardEntity) gère correctement les optionnels
            return cardEntities.map { Card(from: $0) }
        }
    }
    
    @MainActor
    private func mapStudySessionEntityToModel(_ entity: StudySessionEntity) async throws -> StudySession {
        // Utiliser un contexte séparé pour la récupération des détails
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Récupérer l'entité dans le contexte actuel pour garantir la sécurité des threads
            guard let safeEntity = context.object(with: entity.objectID) as? StudySessionEntity else {
                throw Core.Common.StudyServiceError.invalidData // Ou une erreur plus spécifique
            }
            
            let cardReviews = safeEntity.reviews?.allObjects as? [CardReviewEntity] ?? []
            
            // Mapper correctement les CardReviewEntity vers CardReview
            // En supposant que CardReview a un initialiseur `init(from: CardReviewEntity)`
            let mappedReviews: [CardReview] = try cardReviews.compactMap { reviewEntity in
                // Vérifier si l'entité CardReview existe toujours
                guard context.object(with: reviewEntity.objectID) is CardReviewEntity else {
                    return nil // Ignorer les révisions dont l'entité a été supprimée
                }
                // Utiliser l'initialiseur défini dans l'extension CardReview
                return try? CardReview(from: reviewEntity)
            }
            
            // Filtrer les nil potentiels introduits par try?
            let validMappedReviews = mappedReviews.compactMap { $0 }

            let reviewedCardIDs = Set(validMappedReviews.map { $0.cardID })
            let scheduledCardIDs = Array(reviewedCardIDs) // Simplification: utiliser les cartes revues comme cartes planifiées pour le moment

            // Calculer les statistiques
            let correctCount = validMappedReviews.filter { $0.rating == .good || $0.rating == .easy }.count
            let incorrectCount = validMappedReviews.count - correctCount

            // Calculer le temps total
            let totalStudyTime: TimeInterval
            if let endTime = safeEntity.endTime, let startTime = safeEntity.startTime {
                totalStudyTime = endTime.timeIntervalSince(startTime)
            } else {
                // Si la session n'est pas terminée, calculer basé sur les temps de réponse
                 totalStudyTime = validMappedReviews.reduce(0.0) { $0 + $1.responseTime }
            }

            guard let sessionID = safeEntity.id,
                  let deckID = safeEntity.deckID,
                  let startDate = safeEntity.startTime else {
                throw Core.Common.StudyServiceError.invalidData // Ou une erreur plus spécifique
            }

            return StudySession(
                id: sessionID,
                deckID: deckID,
                startDate: startDate,
                endDate: safeEntity.endTime,
                scheduledCards: scheduledCardIDs,
                reviewedCards: Array(reviewedCardIDs),
                correctCount: correctCount,
                incorrectCount: incorrectCount,
                includeSubdecks: safeEntity.includeSubdecks,
                reviewLimit: safeEntity.reviewLimit > 0 ? Int(safeEntity.reviewLimit) : nil,
                totalStudyTime: totalStudyTime
            )
        }
    }
    
    /// Calcule les statistiques d'une session à partir des données brutes de manière thread-safe
    // NOTE: Cette fonction semble non utilisée dans ce fichier. Vérifier son usage avant de modifier/supprimer.
    // Si elle est utilisée, passer sessionID et deckID en paramètres serait plus sûr.
    nonisolated private func calculateSessionStats(
        reviews: [CardReviewEntity],
        reviewedCardIDs: [UUID],
        startTime: Date,
        endTime: Date?,
        includeSubdecks: Bool,
        reviewLimit: Int32
    ) -> StudySession {
        // Protéger contre les données invalides
        // L'ID de session et de paquet devrait idéalement être passé en paramètre
        guard let sessionID = reviews.first?.session?.id,
              let deckID = reviews.first?.session?.deckID else {
             // Retourner une session vide ou lever une erreur selon le cas d'usage
             logger.warning("Impossible de déterminer l'ID de session/paquet dans calculateSessionStats")
             return StudySession(
                 id: UUID(), // ID Provisoire
                 deckID: UUID(), // ID Provisoire
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
            id: sessionID,
            deckID: deckID,
            startDate: startTime,
            endDate: endTime,
            scheduledCards: reviewedCardIDs, // Ces IDs devraient être déterminés plus précisément
            reviewedCards: reviewedCardIDs,
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            includeSubdecks: includeSubdecks,
            reviewLimit: reviewLimit > 0 ? Int(reviewLimit) : nil,
            totalStudyTime: totalStudyTime
        )
    }
    
    // Mettre à jour également les méthodes Task et DispatchQueue.main.async
    private func refreshCurrentSession() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let currentSession = try await fetchCurrentSession()
                self.currentSessionSubject.send(currentSession)
                logger.log("Session courante mise à jour: \(currentSession?.id.uuidString ?? "nil")")
            } catch {
                logger.error("Erreur lors du rafraîchissement de la session: \(error)")
            }
        }
    }
    
    public func updateCardReview(cardID: UUID, rating: Core.Common.ReviewRating) async throws {
        // Utiliser un contexte d'arrière-plan pour la modification
        let context = newBackgroundContext()
        
        try await context.performAsync {
            let fetchRequest: NSFetchRequest<CardReviewEntity> = CardReviewEntity.fetchRequest()
            // Assurer que la recherche se fait sur la bonne propriété `card.id`
            fetchRequest.predicate = NSPredicate(format: "card.id == %@", cardID as CVarArg)
            fetchRequest.fetchBatchSize = 1 // On ne s'attend qu'à un seul résultat pertinent
            fetchRequest.fetchLimit = 1 
            
            let results = try context.fetch(fetchRequest)
            guard let review = results.first else {
                // Correction de la typo dans le nom de l'erreur
                throw Core.Common.StudyServiceError.cardNotFound 
            }
            
            // Utiliser la propriété calculée pour définir le rating
            review.reviewRating = rating
            
            // Sauvegarder dans le contexte d'arrière-plan
            try context.save()
            self.logger.info("Révision de carte mise à jour: \(cardID)")
        }
    }
}
