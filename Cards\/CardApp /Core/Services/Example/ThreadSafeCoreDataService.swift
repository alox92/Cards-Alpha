import Foundation
import Core
import CoreData
import Combine
import os.log

/// Service d'exemple montrant comment utiliser CoreDataConversionUtils 
/// pour créer des opérations Core Data thread-safe
@MainActor
@preconcurrency
public class ThreadSafeCoreDataService: @unchecked Sendable {
    // MARK: - Propriétés
    
    private let persistenceController: PersistenceController
    private let logger = Logger(subsystem: "com.app.cardapp", category: "ThreadSafeCoreDataService")
    
    // MARK: - Initialisation
    
    public init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        logger.debug("ThreadSafeCoreDataService initialisé")
    }
    
    // MARK: - Helpers
    
    private func newBackgroundContext() -> NSManagedObjectContext {
        return persistenceController.container.newBackgroundContext()
    }
    
    // MARK: - Conversion de modèles
    
    /// Convertit une entité DeckEntity en modèle Deck de manière thread-safe
    nonisolated private func mapDeckEntityToModel(_ entity: DeckEntity) -> Deck {
        return Deck(
            id: entity.id ?? UUID(),
            name: entity.name,
            description: entity.desc,
            icon: entity.icon,
            colorName: entity.colorName,
            tags: entity.tags,
            cardCount: Int(entity.cardCount),
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
    
    /// Convertit une entité CardEntity en modèle Card de manière thread-safe
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
    
    // MARK: - Opérations sur les paquets
    
    /// Récupère un paquet par ID avec gestion thread-safe
    public func getDeck(byID id: UUID) async throws -> Deck {
        let context = newBackgroundContext()
        
        // Définition de l'opération qui récupère l'entité
        let fetchOperation = { () throws -> DeckEntity? in
            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchBatchSize = 20
            fetchRequest.fetchLimit = 1
            
            return try context.fetch(fetchRequest).first
        }
        
        // Utilisation de CoreDataConversionUtils pour exécuter l'opération et convertir le résultat
        return try await CoreDataConversionUtils.executeAndConvertSingle(
            context: context,
            operation: fetchOperation,
            converter: self.mapDeckEntityToModel,
            notFoundError: DeckServiceError.deckNotFound
        )
    }
    
    /// Récupère tous les paquets avec gestion thread-safe
    public func getAllDecks() async throws -> [Deck] {
        let context = newBackgroundContext()
        
        // Définition de l'opération qui récupère les entités
        let fetchOperation = { () throws -> [DeckEntity] in
            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            fetchRequest.fetchBatchSize = 20
            return try context.fetch(fetchRequest)
        }
        
        // Utilisation de CoreDataConversionUtils pour exécuter l'opération et convertir les résultats
        return try await CoreDataConversionUtils.executeAndConvert(
            context: context,
            operation: fetchOperation,
            converter: self.mapDeckEntityToModel
        )
    }
    
    /// Crée un nouveau paquet avec gestion thread-safe
    public func createDeck(_ deck: Deck) async throws -> Deck {
        let context = newBackgroundContext()
        
        // Définition de l'opération qui crée l'entité
        let createOperation = { () throws -> DeckEntity in
            let entity = DeckEntity(context: context)
            
            entity.id = deck.id
            entity.name = deck.name
            entity.desc = deck.description
            entity.icon = deck.icon
            entity.colorName = deck.colorName
            entity.tags = deck.tags
            entity.cardCount = Int32(deck.cardCount)
            entity.createdAt = deck.createdAt
            entity.updatedAt = deck.updatedAt
            
            try context.save()
            return entity
        }
        
        // Utilisation de CoreDataConversionUtils pour exécuter l'opération et convertir le résultat
        return try await CoreDataConversionUtils.executeAndConvertSingle(
            context: context,
            operation: createOperation,
            converter: self.mapDeckEntityToModel,
            notFoundError: DeckServiceError.deckNotFound
        )
    }
    
    // MARK: - Opérations sur les cartes
    
    /// Récupère une carte par ID avec gestion thread-safe
    public func getCard(byID id: UUID) async throws -> Card {
        let context = newBackgroundContext()
        
        // Définition de l'opération qui récupère l'entité
        let fetchOperation = { () throws -> CardEntity? in
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchBatchSize = 20
            fetchRequest.fetchLimit = 1
            
            return try context.fetch(fetchRequest).first
        }
        
        // Utilisation de CoreDataConversionUtils pour exécuter l'opération et convertir le résultat
        return try await CoreDataConversionUtils.executeAndConvertSingle(
            context: context,
            operation: fetchOperation,
            converter: self.mapCardEntityToModel,
            notFoundError: CardServiceError.cardNotFound
        )
    }
    
    /// Récupère toutes les cartes d'un paquet avec gestion thread-safe
    public func getCards(forDeckID deckID: UUID) async throws -> [Card] {
        let context = newBackgroundContext()
        
        // Définition de l'opération qui récupère les entités
        let fetchOperation = { () throws -> [CardEntity] in
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "deckID == %@", deckID as CVarArg)
            fetchRequest.fetchBatchSize = 20
            return try context.fetch(fetchRequest)
        }
        
        // Utilisation de CoreDataConversionUtils pour exécuter l'opération et convertir les résultats
        return try await CoreDataConversionUtils.executeAndConvert(
            context: context,
            operation: fetchOperation,
            converter: self.mapCardEntityToModel
        )
    }
    
    /// Crée une nouvelle carte avec gestion thread-safe
    public func createCard(_ card: Card) async throws -> Card {
        let context = newBackgroundContext()
        
        // Définition de l'opération qui crée l'entité
        let createOperation = { () throws -> CardEntity in
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
            return entity
        }
        
        // Utilisation de CoreDataConversionUtils pour exécuter l'opération et convertir le résultat
        return try await CoreDataConversionUtils.executeAndConvertSingle(
            context: context,
            operation: createOperation,
            converter: self.mapCardEntityToModel,
            notFoundError: CardServiceError.cardNotFound
        )
    }
} 