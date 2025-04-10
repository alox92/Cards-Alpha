import Core
import Foundation
import Combine
@preconcurrency import CoreData
import SwiftUI
import os.log

/// Service de gestion des cartes unifié
@preconcurrency
public class UnifiedCardService: CardServiceProtocol, @unchecked Sendable {
    // MARK: - Propriétés
    
    private let persistenceController: PersistenceController
    private let logger = Logger(subsystem: "com.app.cardapp", category: "UnifiedCardService")
    
    private let cardsSubject = CurrentValueSubject<[Card], Never>([])
    public var cardsPublisher: AnyPublisher<[Card], Never> {
        cardsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialisation
    
    public init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        
        // Charger les cartes au démarrage
        Task { @MainActor [weak self] in
            do {
                let cards = try await getAllCards()
                cardsSubject.send(cards)
            } catch {
                logger.error("Erreur lors du chargement initial des cartes: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Méthodes privées
    
    private func viewContext() -> NSManagedObjectContext {
        return persistenceController.container.viewContext
    }
    
    private func newBackgroundContext() -> NSManagedObjectContext {
        return persistenceController.container.newBackgroundContext()
    }
    
    nonisolated private func mapCardEntityToModel(_ entity: CardEntity) -> Card {
        return Card(
            id: entity.id ?? UUID(),
            deckID: entity.deckID ?? UUID(),
            question: entity.question,
            answer: entity.answer,
            additionalInfo: entity.additionalInfo,
            tags: entity.tags,
            masteryLevel: MasteryLevel(rawValue: Int(entity.masteryLevel)) ?? .novice,
            interval: Int(entity.interval),
            ease: entity.ease,
            reviewCount: Int(entity.reviewCount),
            correctCount: Int(entity.correctCount),
            incorrectCount: Int(entity.incorrectCount),
            lastReviewedAt: entity.lastReviewedAt,
            nextReviewDate: entity.nextReviewDate,
            isFlagged: entity.isFlagged,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
    
    // MARK: - Implementation of CardServiceProtocol
    
    public func createCard(_ card: Card) async throws -> Card {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let entity = CardEntity(context: context)
            
            entity.id = card.id
            entity.deckID = card.deckID
            entity.question = card.question
            entity.answer = card.answer
            entity.additionalInfo = card.additionalInfo
            entity.tags = card.tags
            entity.masteryLevel = Int16(card.masteryLevel.rawValue)
            entity.interval = Int16(card.interval)
            entity.ease = card.ease
            entity.reviewCount = Int16(card.reviewCount)
            entity.correctCount = Int16(card.correctCount)
            entity.incorrectCount = Int16(card.incorrectCount)
            entity.lastReviewedAt = card.lastReviewedAt
            entity.nextReviewDate = card.nextReviewDate
            entity.isFlagged = card.isFlagged
            entity.createdAt = card.createdAt
            entity.updatedAt = card.updatedAt
            
            try context.save()
            
            let newCard = self.mapCardEntityToModel(entity)
            await MainActor.run {
                self.cardsSubject.value.append(newCard)
            }
            
            return newCard
        }
    }
    
    public func getCard(byID id: UUID) async throws -> Card {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let entity = try context.fetch(fetchRequest).first else {
                throw CardServiceError.cardNotFound
            }
            
            return self.mapCardEntityToModel(entity)
        }
    }
    
    public func updateCard(_ card: Card) async throws -> Card {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", card.id as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let entity = try context.fetch(fetchRequest).first else {
                throw CardServiceError.cardNotFound
            }
            
            entity.question = card.question
            entity.answer = card.answer
            entity.additionalInfo = card.additionalInfo
            entity.tags = card.tags
            entity.masteryLevel = Int16(card.masteryLevel.rawValue)
            entity.interval = Int16(card.interval)
            entity.ease = card.ease
            entity.reviewCount = Int16(card.reviewCount)
            entity.correctCount = Int16(card.correctCount)
            entity.incorrectCount = Int16(card.incorrectCount)
            entity.lastReviewedAt = card.lastReviewedAt
            entity.nextReviewDate = card.nextReviewDate
            entity.isFlagged = card.isFlagged
            entity.updatedAt = Date()
            
            try context.save()
            
            let updatedCard = self.mapCardEntityToModel(entity)
            
            // Mettre à jour le sujet de publication
            await MainActor.run {
                var cards = self.cardsSubject.value
                if let index = cards.firstIndex(where: { $0.id == card.id }) {
                    cards[index] = updatedCard
                    self.cardsSubject.send(cards)
                }
            }
            
            return updatedCard
        }
    }
    
    public func deleteCard(_ card: Card) async throws {
        let context = newBackgroundContext()
        
        try await context.performAsync {
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", card.id as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let entity = try context.fetch(fetchRequest).first else {
                throw CardServiceError.cardNotFound
            }
            
            context.delete(entity)
            try context.save()
            
            // Mettre à jour le sujet de publication
            await MainActor.run {
                var cards = self.cardsSubject.value
                cards.removeAll { $0.id == card.id }
                self.cardsSubject.send(cards)
            }
        }
    }
    
    public func deleteCards(_ cards: [Card]) async throws {
        let context = newBackgroundContext()
        let ids = cards.map { $0.id }
        
        try await context.performAsync {
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)
        fetchRequest.fetchBatchSize = 20;     
            let entities = try context.fetch(fetchRequest)
            
            for entity in entities {
                context.delete(entity)
            }
            
            try context.save()
            
            // Mettre à jour le sujet de publication
            await MainActor.run {
                var currentCards = self.cardsSubject.value
                currentCards.removeAll { card in ids.contains(card.id) }
                self.cardsSubject.send(currentCards)
            }
        }
    }
    
    public func getAllCards() async throws -> [Card] {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            let entities = try context.fetch(fetchRequest)
        fetchRequest.fetchBatchSize = 20;     // Utiliser mapCardEntityToModel de manière sûre car la méthode est nonisolated
            let cards = entities.map { entity in
                self.mapCardEntityToModel(entity)
            }
            return cards
        }
    }
    
    public func getCards(forDeckID deckID: UUID) async throws -> [Card] {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "deckID == %@", deckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            let entities = try context.fetch(fetchRequest)
            // Utiliser mapCardEntityToModel de manière sûre car la méthode est nonisolated
            let cards = entities.map { entity in
                self.mapCardEntityToModel(entity)
            }
            return cards
        }
    }
    
    public func getCards(withTags tags: [String]) async throws -> [Card] {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            
        fetchRequest.fetchBatchSize = 20;     // Construire un prédicat pour les tags
            let tagPredicates = tags.map { tag in
                NSPredicate(format: "tags CONTAINS %@", tag)
            }
            
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: tagPredicates)
            
            let entities = try context.fetch(fetchRequest)
            // Utiliser mapCardEntityToModel de manière sûre car la méthode est nonisolated
            let cards = entities.map { entity in
                self.mapCardEntityToModel(entity)
            }
            return cards
        }
    }
    
    public func getDueCards(forDeckID deckID: UUID, limit: Int?) async throws -> [Card] {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            
        fetchRequest.fetchBatchSize = 20;     // Prédicat pour les cartes dues du deck spécifié
            fetchRequest.predicate = NSPredicate(
                format: "deckID == %@ AND (nextReviewDate <= %@ OR nextReviewDate == nil)",
                deckID as CVarArg,
                Date() as NSDate
            )
            
            // Définir une limite si spécifiée
            if let limit = limit {
                fetchRequest.fetchLimit = limit
            }
            
            // Trier par date de révision (anciennes en premier)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "nextReviewDate", ascending: true),
                NSSortDescriptor(key: "createdAt", ascending: true)
            ]
            
            let entities = try context.fetch(fetchRequest)
            // Utiliser mapCardEntityToModel de manière sûre car la méthode est nonisolated
            let cards = entities.map { entity in
                self.mapCardEntityToModel(entity)
            }
            return cards
        }
    }
    
    public func updateCardAfterReview(_ card: Card, rating: Core.Common.ReviewRating) async throws -> Card {
        // Créer une copie mutable de la carte
        var updatedCard = card
        
        // Calculer les nouveaux paramètres en utilisant le planificateur
        let result = CardScheduler.calculateNextReview(
            currentInterval: card.interval,
            currentEase: card.ease,
            rating: rating
        )
        
        // Mettre à jour les propriétés de la carte
        updatedCard.interval = result.interval
        updatedCard.ease = result.ease
        updatedCard.masteryLevel = CardScheduler.calculateNewMasteryLevel(
            currentLevel: card.masteryLevel,
            rating: rating
        )
        updatedCard.reviewCount += 1
        updatedCard.lastReviewedAt = Date()
        
        // Mettre à jour les compteurs de réussite/échec
        if rating == .good || rating == .easy {
            updatedCard.correctCount += 1
        } else {
            updatedCard.incorrectCount += 1
        }
        
        // Calculer la prochaine date de révision
        updatedCard.nextReviewDate = CardScheduler.calculateNextReviewDate(
            currentInterval: result.interval,
            rating: rating
        )
        
        // Mettre à jour la carte dans la base de données
        return try await updateCard(updatedCard)
    }
    
    public func updateCardTags(_ card: Card, tags: [String]) async throws -> Card {
        var updatedCard = card
        updatedCard.tags = tags
        return try await updateCard(updatedCard)
    }
    
    public func flagCard(_ card: Card, isFlagged: Bool) async throws -> Card {
        var updatedCard = card
        updatedCard.isFlagged = isFlagged
        return try await updateCard(updatedCard)
    }
    
    public func searchCards(query: String, options: CardFilterOptions?) async throws -> [Card] {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            
        fetchRequest.fetchBatchSize = 20;     // Construire le prédicat de recherche
            var predicates: [NSPredicate] = []
            
            // Recherche textuelle
            if !query.isEmpty {
                let textPredicate = NSPredicate(
                    format: "question CONTAINS[cd] %@ OR answer CONTAINS[cd] %@ OR additionalInfo CONTAINS[cd] %@",
                    query, query, query
                )
                predicates.append(textPredicate)
            }
            
            // Appliquer les options de filtrage si fournies
            if let options = options {
                // Filtrer par tags
                if let tags = options.tags, !tags.isEmpty {
                    let tagPredicates = tags.map { tag in
                        NSPredicate(format: "tags CONTAINS %@", tag)
                    }
                    predicates.append(NSCompoundPredicate(andPredicateWithSubpredicates: tagPredicates))
                }
                
                // Filtrer par niveau de maîtrise
                if let level = options.masteryLevel {
                    predicates.append(NSPredicate(format: "masteryLevel == %d", level.rawValue))
                }
                
                // Filtrer les cartes dues
                if let isDue = options.isDue, isDue {
                    predicates.append(NSPredicate(format: "nextReviewDate <= %@", Date() as NSDate))
                }
                
                // Filtrer les cartes marquées
                if let isFlagged = options.isFlagged {
                    predicates.append(NSPredicate(format: "isFlagged == %@", NSNumber(value: isFlagged)))
                }
                
                // Appliquer le filtrage par date
                if let dateRange = options.dateRange {
                    let dateKey = options.dateFilterType == .creationDate ? "createdAt" : "updatedAt"
                    
                    if let start = dateRange.start, let end = dateRange.end {
                        predicates.append(NSPredicate(format: "%K >= %@ AND %K <= %@", dateKey, start as NSDate, dateKey, end as NSDate))
                    } else if let start = dateRange.start {
                        predicates.append(NSPredicate(format: "%K >= %@", dateKey, start as NSDate))
                    } else if let end = dateRange.end {
                        predicates.append(NSPredicate(format: "%K <= %@", dateKey, end as NSDate))
                    }
                }
            }
            
            // Combiner tous les prédicats
            if !predicates.isEmpty {
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            
            // Appliquer le tri
            let sortKey: String
            if let options = options {
                switch options.sortBy {
                case .createdAt: sortKey = "createdAt"
                case .updatedAt: sortKey = "updatedAt"
                case .lastReviewed: sortKey = "lastReviewedAt"
                case .nextReview: sortKey = "nextReviewDate"
                case .masteryLevel: sortKey = "masteryLevel"
                case .front: sortKey = "question"
                case .back: sortKey = "answer"
                case .relevance: sortKey = "question" // Par défaut pour la pertinence
                }
                
                fetchRequest.sortDescriptors = [
                    NSSortDescriptor(key: sortKey, ascending: options.sortOrder == .ascending)
                ]
            } else {
                fetchRequest.sortDescriptors = [
                    NSSortDescriptor(key: "updatedAt", ascending: false)
                ]
            }
            
            let entities = try context.fetch(fetchRequest)
            // Utiliser mapCardEntityToModel de manière sûre car la méthode est nonisolated
            let cards = entities.map { entity in
                self.mapCardEntityToModel(entity)
            }
            return cards
        }
    }
    
    public func importCards(_ cards: [Card], toDeckID deckID: UUID) async throws -> [Card] {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            var importedCards: [Card] = []
            
            for card in cards {
                let entity = CardEntity(context: context)
                
                entity.id = UUID() // Nouvelle ID pour éviter les conflits
                entity.deckID = deckID
                entity.question = card.question
                entity.answer = card.answer
                entity.additionalInfo = card.additionalInfo
                entity.tags = card.tags
                entity.masteryLevel = Int16(MasteryLevel.novice.rawValue) // Réinitialiser le niveau de maîtrise
                entity.interval = 0
                entity.ease = 2.5
                entity.reviewCount = 0
                entity.correctCount = 0
                entity.incorrectCount = 0
                entity.lastReviewedAt = nil
                entity.nextReviewDate = nil
                entity.isFlagged = false
                entity.createdAt = Date()
                entity.updatedAt = Date()
                
                importedCards.append(self.mapCardEntityToModel(entity))
            }
            
            try context.save()
            
            // Mettre à jour le sujet de publication
            await MainActor.run {
                let currentCards = self.cardsSubject.value
                self.cardsSubject.send(currentCards + importedCards)
            }
            
            return importedCards
        }
    }
    
    public func exportCards(_ cards: [Card]) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(cards)
    }
} 