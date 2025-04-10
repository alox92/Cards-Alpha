import Foundation
import Combine
import CoreData
import Core

@MainActor
public final class StudyService: StudyServiceProtocol, @unchecked Sendable {
    // MARK: - Propriétés
    private let persistence: PersistenceControllerProtocol
    private let cardService: CardServiceProtocol
    private let deckService: DeckServiceProtocol
    private let scheduler: CardSchedulerProtocolV2
    
    private var currentSession: StudySession?
    private let currentSessionSubject = CurrentValueSubject<StudySession?, Never>(nil)
    
    // MARK: - Publishers
    public var currentSessionPublisher: AnyPublisher<StudySession?, Never> {
        currentSessionSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialisation
    public init(
        persistence: PersistenceControllerProtocol,
        cardService: CardServiceProtocol,
        deckService: DeckServiceProtocol,
        scheduler: CardSchedulerProtocolV2
    ) {
        self.persistence = persistence
        self.cardService = cardService
        self.deckService = deckService
        self.scheduler = scheduler
    }
    
    // MARK: - Gestion des sessions
    public func startStudySession(deckID: UUID, includeSubdecks: Bool, reviewLimit: Int?) async throws -> StudySession {
        // Vérifier si une session est déjà en cours
        if currentSession != nil {
            throw Core.Common.StudyServiceError.sessionAlreadyStarted
        }
        
        // Créer une nouvelle session
        let session = StudySession(
            id: UUID(),
            deckID: deckID,
            startDate: Date(),
            includeSubdecks: includeSubdecks,
            reviewLimit: reviewLimit
        )
        
        currentSession = session
        currentSessionSubject.send(session)
        
        return session
    }
    
    public func endStudySession(sessionID: UUID, saveProgress: Bool) async throws {
        guard let session = currentSession, session.id == sessionID else {
            throw Core.Common.StudyServiceError.sessionNotFound
        }
        
        if saveProgress {
            try await saveSessionProgress(session)
        }
        
        currentSession = nil
        currentSessionSubject.send(nil)
    }
    
    public func getCurrentSession() async throws -> StudySession? {
        return currentSession
    }
    
    public func getSessionHistory(limit: Int) async throws -> [StudySession] {
        let context = persistence.newBackgroundContext()
        let request = StudySessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StudySessionEntity.startTime, ascending: false)]
        request.fetchLimit = limit
        
        let entities = try context.fetch(request)
        return try entities.map { try StudySession(from: $0) }
    }
    
    // MARK: - Étude des cartes
    public func getNextCardForReview() async throws -> Card? {
        guard let session = currentSession else {
            throw Core.Common.StudyServiceError.noActiveSession
        }
        
        // Récupérer les cartes du paquet
        let cards = try await cardService.getCards(forDeckID: session.deckID)
        
        // Filtrer les cartes déjà révisées
        let remainingCards = cards.filter { !session.reviewedCards.contains($0.id) }
        
        // Si toutes les cartes ont été révisées ou si on a atteint la limite
        if remainingCards.isEmpty || (session.reviewLimit != nil && session.reviewedCards.count >= session.reviewLimit!) {
            return nil
        }
        
        // Retourner la première carte non révisée
        return remainingCards.first
    }
    
    public func recordCardReview(cardID: UUID, rating: Core.Common.ReviewRating, responseTime: TimeInterval) async throws -> Card {
        guard let session = currentSession else {
            throw Core.Common.StudyServiceError.noActiveSession
        }
        
        // Récupérer la carte
        let card = try await cardService.getCard(byID: cardID)
        
        // Mettre à jour la carte avec la nouvelle révision
        let updatedCard = card.recordReview(rating: rating, scheduler: scheduler)
        
        // Sauvegarder la carte mise à jour
        let savedCard = try await cardService.updateCard(updatedCard)
        
        // Mettre à jour la session
        var updatedSession = session
        updatedSession.reviewedCards.append(cardID)
        if rating == .again || rating == .hard {
            updatedSession.incorrectCount += 1
        } else {
            updatedSession.correctCount += 1
        }
        
        // Mettre à jour la session dans le système de stockage
        try await updateSession(updatedSession)
        
        // Publier la session mise à jour
        currentSessionSubject.send(updatedSession)
        
        return savedCard
    }
    
    public func skipCard(cardID: UUID) async throws {
        guard let session = currentSession else {
            throw Core.Common.StudyServiceError.noActiveSession
        }
        
        // Vérifier que la carte n'a pas déjà été révisée
        if session.reviewedCards.contains(cardID) {
            throw Core.Common.StudyServiceError.cardAlreadyReviewed
        }
        
        // Marquer la carte comme révisée sans révision
        var updatedSession = session
        updatedSession.reviewedCards.append(cardID)
        currentSessionSubject.send(updatedSession)
    }
    
    // MARK: - Statistiques d'étude
    public func getDeckStudyStats(forDeckID deckID: UUID) async throws -> DeckStudyStats {
        let cards = try await cardService.getCards(forDeckID: deckID)
        
        let totalCards = cards.count
        let newCards = cards.filter { $0.masteryLevel == .novice }.count
        let learningCards = cards.filter { $0.masteryLevel == .beginner || $0.masteryLevel == .intermediate }.count
        let reviewingCards = cards.filter { $0.masteryLevel == .advanced }.count
        let masteredCards = cards.filter { $0.masteryLevel == .expert }.count
        
        let dueCards = cards.filter { $0.isDue }.count
        
        let averageRetention = cards.reduce(0.0) { sum, card in
            sum + (Double(card.correctCount) / Double(max(1, card.reviewCount)))
        } / Double(max(1, totalCards))
        
        let completionRate = Double(masteredCards) / Double(max(1, totalCards))
        
        return DeckStudyStats(
            deckID: deckID,
            totalCards: totalCards,
            newCards: newCards,
            learningCards: learningCards,
            reviewingCards: reviewingCards,
            masteredCards: masteredCards,
            dueCards: dueCards,
            averageRetention: averageRetention,
            completionRate: completionRate,
            lastStudyDate: cards.compactMap { $0.lastReviewedAt }.max(),
            cardsStudiedToday: cards.filter { $0.lastReviewedAt?.isToday ?? false }.count,
            studyTimeToday: 0 // À implémenter si nécessaire
        )
    }
    
    public func getCardStudyStats(forCardID cardID: UUID) async throws -> CardStudyStats {
        let card = try await cardService.getCard(byID: cardID)
        
        return CardStudyStats(
            cardID: cardID,
            totalReviews: card.reviewCount,
            correctReviews: card.correctCount,
            incorrectReviews: card.incorrectCount,
            successRate: Double(card.correctCount) / Double(max(1, card.reviewCount)),
            averageResponseTime: 0, // À implémenter si nécessaire
            firstStudyDate: card.createdAt,
            lastStudyDate: card.lastReviewedAt
        )
    }
    
    // MARK: - Implémentations du protocole StudyServiceProtocol
    
    public func createSession(deckID: UUID, includeSubdecks: Bool, reviewLimit: Int?) async throws -> StudySession {
        return try await startStudySession(deckID: deckID, includeSubdecks: includeSubdecks, reviewLimit: reviewLimit)
    }
    
    public func getSession(byID id: UUID) async throws -> StudySession {
        // Vérifier si c'est la session courante
        if let currentSession = currentSession, currentSession.id == id {
            return currentSession
        }
        
        // Sinon, chercher dans la base de données
        let context = persistence.newBackgroundContext()
        
        return try await Task.detached {
            let fetchRequest = NSFetchRequest<StudySessionEntity>(entityName: "StudySessionEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            do {
                guard let entity = try context.fetch(fetchRequest).first else {
                    throw Core.Common.StudyServiceError.sessionNotFound
                }
                
                return try StudySession(from: entity)
            } catch {
                throw error
            }
        }.value
    }
    
    public func updateSession(_ session: StudySession) async throws -> StudySession {
        // Mettre à jour dans la base de données
        try await self.persistSession(session)
        
        // Si c'est la session courante, mettre à jour également celle-ci
        if currentSession?.id == session.id {
            currentSession = session
            currentSessionSubject.send(session)
        }
        
        return session
    }
    
    public func endSession(_ session: StudySession) async throws -> StudySession {
        var updatedSession = session
        updatedSession.endDate = Date()
        
        try await self.persistSession(updatedSession)
        
        // Si c'est la session courante, la terminer
        if currentSession?.id == session.id {
            currentSession = nil
            currentSessionSubject.send(nil)
        }
        
        return updatedSession
    }
    
    public func getScheduledCards(forSessionID sessionID: UUID) async throws -> [Card] {
        // Vérifier si c'est la session courante
        if let session = currentSession, session.id == sessionID {
            let allCards = try await cardService.getCards(forDeckID: session.deckID)
            return allCards.filter { !session.reviewedCards.contains($0.id) }
        }
        
        // Sinon, chercher dans la base de données
        let session = try await getSession(byID: sessionID)
        let allCards = try await cardService.getCards(forDeckID: session.deckID)
        return allCards.filter { !session.reviewedCards.contains($0.id) }
    }
    
    public func getReviewedCards(forSessionID sessionID: UUID) async throws -> [Card] {
        // Récupérer la session
        let session = try await getSession(byID: sessionID)
        
        // Récupérer toutes les cartes du paquet
        let allCards = try await cardService.getCards(forDeckID: session.deckID)
        
        // Filtrer pour ne garder que les cartes révisées
        return allCards.filter { session.reviewedCards.contains($0.id) }
    }
    
    public func recordCardReview(cardID: UUID, sessionID: UUID, rating: Core.Common.ReviewRating, responseTime: TimeInterval) async throws -> CardReview {
        // Vérifier si la session existe
        let session = try await getSession(byID: sessionID)
        
        // Récupérer la carte
        let card = try await cardService.getCard(byID: cardID)
        
        // Créer la révision
        let newReview = CardReview(
            cardID: cardID,
            sessionID: sessionID,
            rating: rating,
            responseTime: responseTime,
            newInterval: card.interval,
            newEase: card.ease,
            newMasteryLevel: card.masteryLevel
        )
        
        // Sauvegarder la révision en base de données
        let context = persistence.newBackgroundContext()
        let entity = CardReviewEntity(context: context)
        
        entity.id = newReview.id
        entity.timestamp = newReview.timestamp
        entity.responseTime = newReview.responseTime
        entity.rating = String(newReview.rating.rawValue)
        entity.newInterval = Int16(newReview.newInterval)
        entity.newEase = newReview.newEase
        entity.newMasteryLevel = Int16(newReview.newMasteryLevel.rawValue)
        
        try context.save()
        
        return newReview
    }
    
    public func getCardReviews(forCardID cardID: UUID) async throws -> [CardReview] {
        let context = persistence.newBackgroundContext()
        
        // Rechercher les reviews pour cette carte
        return try await Task.detached {
            do {
                let fetchRequest = NSFetchRequest<CardReviewEntity>(entityName: "CardReviewEntity")
                let cardFetchRequest = NSFetchRequest<CardEntity>(entityName: "CardEntity")
        fetchRequest.fetchBatchSize = 20;         cardFetchRequest.predicate = NSPredicate(format: "id == %@", cardID as CVarArg)
                
                guard let cardEntity = try context.fetch(cardFetchRequest).first else {
                    throw Core.Common.StudyServiceError.cardNotFound
                }
                
                fetchRequest.predicate = NSPredicate(format: "card == %@", cardEntity)
                let entities = try context.fetch(fetchRequest)
                
                return try entities.map { try CardReview(from: $0) }
            } catch {
                throw error
            }
        }.value
    }
    
    public func getSessionStats(forSessionID sessionID: UUID) async throws -> StudySessionStats {
        // Récupérer la session
        let session = try await getSession(byID: sessionID)
        
        // Calculer les statistiques
        return StudySessionStats(
            deckID: session.deckID,
            totalCards: session.scheduledCards.count,
            newCards: 0, // À calculer si nécessaire
            learningCards: 0, // À calculer si nécessaire
            reviewingCards: 0, // À calculer si nécessaire
            masteredCards: 0, // À calculer si nécessaire
            dueCards: 0, // À calculer si nécessaire
            averageRetention: session.successRate,
            completionRate: Double(session.reviewedCards.count) / Double(max(1, session.scheduledCards.count)),
            lastStudyDate: session.endDate,
            cardsStudiedToday: session.reviewedCards.count,
            studyTimeToday: session.duration
        )
    }
    
    // MARK: - Méthodes privées
    private func saveSessionProgress(_ session: StudySession) async throws {
        let context = persistence.newBackgroundContext()
        let entity = StudySessionEntity(context: context)
        
        entity.id = session.id
        entity.deckID = session.deckID
        entity.startTime = session.startDate
        entity.endTime = session.endDate
        entity.includeSubdecks = session.includeSubdecks
        entity.reviewLimit = Int32(session.reviewLimit ?? 0)
        
        try context.save()
    }
    
    private func persistSession(_ session: StudySession) async throws {
        let context = persistence.newBackgroundContext()
        
        try await Task.detached {
            let fetchRequest = NSFetchRequest<StudySessionEntity>(entityName: "StudySessionEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            do {
                let entity: StudySessionEntity
                
                if let existingEntity = try context.fetch(fetchRequest).first {
                    // Mettre à jour l'entité existante
                    entity = existingEntity
                } else {
                    // Créer une nouvelle entité
                    entity = StudySessionEntity(context: context)
                    entity.id = session.id
                }
                
                // Mettre à jour les propriétés
                entity.deckID = session.deckID
                entity.startTime = session.startDate
                entity.endTime = session.endDate
                entity.reviewLimit = Int32(session.reviewLimit ?? 0)
                entity.includeSubdecks = session.includeSubdecks
                entity.totalReviews = Int32(session.reviewedCards.count)
                entity.totalCorrect = Int32(session.correctCount)
                entity.totalIncorrect = Int32(session.incorrectCount)
                entity.totalTime = session.totalStudyTime
                
                // Stocker les données des cartes révisées
                if !session.reviewedCards.isEmpty {
                    entity.reviewsData = try JSONEncoder().encode(session.reviewedCards)
                }
                
                try context.save()
            } catch {
                throw error
            }
        }.value
    }
} 
