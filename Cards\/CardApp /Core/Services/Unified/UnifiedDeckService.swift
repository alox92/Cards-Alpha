import Core
import Foundation
@preconcurrency import CoreData
import Combine
import SwiftUI
import os.log
// Nous utilisons l'énumération DeckServiceError existante dans Core/Common/Errors.swift

/// Service unifié de gestion des paquets
@preconcurrency
public class UnifiedDeckService: DeckServiceProtocol, @unchecked Sendable {
    // MARK: - Propriétés
    
    private let persistenceController: PersistenceController
    private let logger = Logger(subsystem: "com.app.cardapp", category: "UnifiedDeckService")
    
    private let decksSubject = CurrentValueSubject<[Deck], Never>([])
    @preconcurrency
    public var decksPublisher: AnyPublisher<[Deck], Never> {
        decksSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Propriétés privées
    
    private var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    private func newBackgroundContext() -> NSManagedObjectContext {
        return persistenceController.container.newBackgroundContext()
    }
    
    // MARK: - Initialisation
    
    public init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        
        // Charger les paquets au démarrage
        Task { @MainActor [weak self] in
            do {
                let decks = try await getAllDecks()
                decksSubject.send(decks)
            } catch {
                logger.error("Erreur lors du chargement initial des paquets: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Méthodes privées
    
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
    
    private func getAllDecksFromContext(context: NSManagedObjectContext) async throws -> [Deck] {
        let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
        let entities = try context.fetch(fetchRequest)
        fetchRequest.fetchBatchSize = 20; return entities.map { self.mapDeckEntityToModel($0) }
    }
    
    // MARK: - Implémentation du protocole DeckServiceProtocol
    
    public func getDeck(byID id: UUID) async throws -> Deck {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let entity = try context.fetch(fetchRequest).first else {
                throw DeckServiceError.deckNotFound
            }
            
            return self.mapDeckEntityToModel(entity)
        }
    }
    
    public func getDeckOptional(byID id: UUID) async -> Deck? {
        do {
            return try await getDeck(byID: id)
        } catch {
            return nil
        }
    }
    
    public func getAllDecks() async throws -> [Deck] {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            try await self.getAllDecksFromContext(context: context)
        }
    }
    
    public func getChildDecks(ofDeckID deckID: UUID) async throws -> [Deck] {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Charger d'abord le paquet parent pour vérifier son existence
            let parentFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            parentFetchRequest.predicate = NSPredicate(format: "id == %@", deckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     parentFetchRequest.fetchLimit = 1
            
            guard let parentDeck = try context.fetch(parentFetchRequest).first else {
                throw DeckServiceError.deckNotFound
            }
            
            // Charger les sous-paquets
            let childDecks = Array(parentDeck.subdecks)
            return await Task.detached {
                return childDecks.map { [self] entity in
                    return self.mapDeckEntityToModel(entity)
                }
            }.value
        }
    }
    
    public func updateDeck(_ deck: Deck) async throws -> Deck {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", deck.id as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let deckEntity = try context.fetch(fetchRequest).first else {
                throw DeckServiceError.deckNotFound
            }
            
            // Mettre à jour les propriétés
            deckEntity.name = deck.name
            deckEntity.desc = deck.description
            deckEntity.icon = deck.icon
            deckEntity.colorName = deck.colorName
            deckEntity.tags = deck.tags
            deckEntity.updatedAt = Date()
            deckEntity.cardCount = Int32(deck.cardCount)
            
            try context.save()
            
            // Retourner le paquet mis à jour
            let updatedDeck = await Task.detached {
                return self.mapDeckEntityToModel(deckEntity)
            }.value
            
            // Notifier les abonnés en utilisant MainActor pour éviter les problèmes de concurrence
            await MainActor.run {
                var decks = self.decksSubject.value
                if let index = decks.firstIndex(where: { $0.id == deck.id }) {
                    decks[index] = updatedDeck
                    self.decksSubject.send(decks)
                }
            }
            
            return updatedDeck
        }
    }
    
    public func createDeck(name: String, description: String = "", icon: String = "rectangle.stack.fill", colorName: String = "blue", tags: [String] = []) async throws -> Deck {
        guard !name.isEmpty else {
            throw CoreError.validationError("Le nom du paquet ne peut pas être vide")
        }
        
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Créer la nouvelle entité
            let deckEntity = DeckEntity(context: context)
            deckEntity.id = UUID()
            deckEntity.name = name
            deckEntity.desc = description
            deckEntity.icon = icon
            deckEntity.colorName = colorName
            deckEntity.tags = tags
            deckEntity.createdAt = Date()
            deckEntity.updatedAt = Date()
            deckEntity.cardCount = 0
            
            try context.save()
            
            // Mapper l'entité vers le modèle
            let newDeck = Deck(
                id: deckEntity.id ?? UUID(),
                name: deckEntity.name,
                description: deckEntity.desc,
                icon: deckEntity.icon,
                colorName: deckEntity.colorName,
                tags: deckEntity.tags,
                cardCount: 0,
                createdAt: deckEntity.createdAt,
                updatedAt: deckEntity.updatedAt
            )
            
            // Mettre à jour la liste des paquets
            await MainActor.run {
                var decks = self.decksSubject.value
                decks.append(newDeck)
                self.decksSubject.send(decks)
            }
            
            return newDeck
        }
    }
    
    public func deleteDeck(byID deckID: UUID) async throws -> Bool {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", deckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let deckEntity = try context.fetch(fetchRequest).first else {
                return false
            }
            
            // Supprimer l'entité
            context.delete(deckEntity)
            try context.save()
            
            // Mettre à jour la liste des paquets
            await MainActor.run {
                var decks = self.decksSubject.value
                decks.removeAll { $0.id == deckID }
                self.decksSubject.send(decks)
            }
            
            return true
        }
    }
    
    public func deleteDeck(_ deck: Deck) async throws {
        _ = try await deleteDeck(byID: deck.id)
    }
    
    public func searchDecks(query: String) async throws -> [Deck] {
        let context = newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR desc CONTAINS[cd] %@", query, query)
        fetchRequest.fetchBatchSize = 20; 
        return try await context.performAsync {
            let entities = try context.fetch(fetchRequest)
            return await Task.detached {
                return entities.map { [self] entity in
                    return self.mapDeckEntityToModel(entity)
                }
            }.value
        }
    }
    
    public func getDecks(withTag tag: String) async throws -> [Deck] {
        let context = newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tags CONTAINS %@", tag)
        fetchRequest.fetchBatchSize = 20; 
        return try await context.performAsync {
            let entities = try context.fetch(fetchRequest)
            return await Task.detached {
                return entities.map { [self] entity in
                    return self.mapDeckEntityToModel(entity)
                }
            }.value
        }
    }
    
    public func moveCard(cardID: UUID, fromDeckID sourceDeckID: UUID, toDeckID targetDeckID: UUID) async throws -> Card {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Vérifier que les deux paquets existent
            let deckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            deckFetchRequest.predicate = NSPredicate(format: "id IN %@", [sourceDeckID, targetDeckID])
        fetchRequest.fetchBatchSize = 20;     
            let decks = try context.fetch(deckFetchRequest)
            
            guard decks.count == 2 else {
                throw DeckServiceError.deckNotFound
            }
            
            // Récupérer la carte
            let cardFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            cardFetchRequest.predicate = NSPredicate(format: "id == %@", cardID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     guard let cardEntity = try context.fetch(cardFetchRequest).first else {
                throw CoreError.entityNotFound
            }
            
            // Mettre à jour le paquet de la carte
            cardEntity.deckID = targetDeckID
            
            // Mettre à jour les compteurs de cartes
            if let sourceDeck = decks.first(where: { $0.id == sourceDeckID }) {
                sourceDeck.cardCount = max(0, sourceDeck.cardCount - 1)
            }
            
            if let targetDeck = decks.first(where: { $0.id == targetDeckID }) {
                targetDeck.cardCount += 1
                cardEntity.deck = targetDeck
            }
            
            try context.save()
            
            // Mettre à jour les paquets dans le subject
            await MainActor.run {
                var currentDecks = self.decksSubject.value
                
                if let sourceIndex = currentDecks.firstIndex(where: { $0.id == sourceDeckID }),
                   let targetIndex = currentDecks.firstIndex(where: { $0.id == targetDeckID }) {
                    
                    var sourceDeckUpdated = currentDecks[sourceIndex]
                    sourceDeckUpdated.cardCount = max(0, sourceDeckUpdated.cardCount - 1)
                    
                    var targetDeckUpdated = currentDecks[targetIndex]
                    targetDeckUpdated.cardCount += 1
                    
                    currentDecks[sourceIndex] = sourceDeckUpdated
                    currentDecks[targetIndex] = targetDeckUpdated
                    
                    self.decksSubject.send(currentDecks)
                }
            }
            
            // Retourner la carte mise à jour
            return Card(
                id: cardEntity.id ?? UUID(),
                deckID: targetDeckID,
                question: cardEntity.question,
                answer: cardEntity.answer,
                additionalInfo: cardEntity.additionalInfo,
                tags: cardEntity.tags,
                masteryLevel: MasteryLevel(rawValue: Int(cardEntity.masteryLevel)) ?? .novice,
                interval: Int(cardEntity.interval),
                ease: cardEntity.ease,
                reviewCount: Int(cardEntity.reviewCount),
                correctCount: Int(cardEntity.correctCount),
                incorrectCount: Int(cardEntity.incorrectCount),
                lastReviewedAt: cardEntity.lastReviewedAt,
                nextReviewDate: cardEntity.nextReviewDate,
                isFlagged: cardEntity.isFlagged,
                createdAt: cardEntity.createdAt,
                updatedAt: cardEntity.updatedAt
            )
        }
    }
    
    public func copyCard(cardID: UUID, fromDeckID sourceDeckID: UUID, toDeckID targetDeckID: UUID) async throws -> Card {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Vérifier que les deux paquets existent
            let deckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            deckFetchRequest.predicate = NSPredicate(format: "id IN %@", [sourceDeckID, targetDeckID])
        fetchRequest.fetchBatchSize = 20;     
            let decks = try context.fetch(deckFetchRequest)
            
            guard decks.count == 2 else {
                throw DeckServiceError.deckNotFound
            }
            
            // Récupérer la carte source
            let cardFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            cardFetchRequest.predicate = NSPredicate(format: "id == %@ AND deckID == %@", cardID as CVarArg, sourceDeckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     guard let sourceCardEntity = try context.fetch(cardFetchRequest).first else {
                throw CoreError.entityNotFound
            }
            
            // Créer une nouvelle carte dans le paquet cible
            let newCardEntity = CardEntity(context: context)
            newCardEntity.id = UUID()
            newCardEntity.deckID = targetDeckID
            newCardEntity.question = sourceCardEntity.question
            newCardEntity.answer = sourceCardEntity.answer
            newCardEntity.additionalInfo = sourceCardEntity.additionalInfo
            newCardEntity.tags = sourceCardEntity.tags
            newCardEntity.createdAt = Date()
            newCardEntity.updatedAt = Date()
            
            // Réinitialiser les statistiques d'apprentissage
            newCardEntity.masteryLevel = 0
            newCardEntity.interval = 0
            newCardEntity.ease = 2.5
            newCardEntity.reviewCount = 0
            newCardEntity.correctCount = 0
            newCardEntity.incorrectCount = 0
            newCardEntity.lastReviewedAt = nil
            newCardEntity.nextReviewDate = nil
            newCardEntity.isFlagged = false
            
            // Mettre à jour le compteur de cartes du paquet cible
            if let targetDeck = decks.first(where: { $0.id == targetDeckID }) {
                targetDeck.cardCount += 1
                newCardEntity.deck = targetDeck
            }
            
            try context.save()
            
            // Mettre à jour les paquets dans le subject
            await MainActor.run {
                var currentDecks = self.decksSubject.value
                
                if let targetIndex = currentDecks.firstIndex(where: { $0.id == targetDeckID }) {
                    var targetDeckUpdated = currentDecks[targetIndex]
                    targetDeckUpdated.cardCount += 1
                    currentDecks[targetIndex] = targetDeckUpdated
                    self.decksSubject.send(currentDecks)
                }
            }
            
            // Retourner la nouvelle carte
            return Card(
                id: newCardEntity.id ?? UUID(),
                deckID: targetDeckID,
                question: newCardEntity.question,
                answer: newCardEntity.answer,
                additionalInfo: newCardEntity.additionalInfo,
                tags: newCardEntity.tags,
                masteryLevel: .novice,
                interval: 0,
                ease: 2.5,
                reviewCount: 0,
                correctCount: 0,
                incorrectCount: 0,
                lastReviewedAt: nil,
                nextReviewDate: nil,
                isFlagged: false,
                createdAt: newCardEntity.createdAt,
                updatedAt: newCardEntity.updatedAt
            )
        }
    }
    
    public func addTagToDeck(deckID: UUID, tag: String) async throws -> Deck {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", deckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let deckEntity = try context.fetch(fetchRequest).first else {
                throw DeckServiceError.deckNotFound
            }
            
            // Ajouter le tag s'il n'existe pas déjà
            var tags = deckEntity.tags
            
            if !tags.contains(tag) {
                tags.append(tag)
                deckEntity.tags = tags
                deckEntity.updatedAt = Date()
                
                try context.save()
            }
            
            // Retourner le paquet mis à jour
            let updatedDeck = await Task.detached {
                return self.mapDeckEntityToModel(deckEntity)
            }.value
            
            // Mettre à jour les paquets dans le subject
            await MainActor.run {
                var decks = self.decksSubject.value
                if let index = decks.firstIndex(where: { $0.id == deckID }) {
                    decks[index] = updatedDeck
                    self.decksSubject.send(decks)
                }
            }
            
            return updatedDeck
        }
    }
    
    public func removeTagFromDeck(deckID: UUID, tag: String) async throws -> Deck {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", deckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let deckEntity = try context.fetch(fetchRequest).first else {
                throw DeckServiceError.deckNotFound
            }
            
            // Supprimer le tag s'il existe
            var tags = deckEntity.tags
            
            if let index = tags.firstIndex(of: tag) {
                tags.remove(at: index)
                deckEntity.tags = tags
                deckEntity.updatedAt = Date()
                
                try context.save()
            }
            
            // Retourner le paquet mis à jour
            let updatedDeck = await Task.detached {
                return self.mapDeckEntityToModel(deckEntity)
            }.value
            
            // Mettre à jour les paquets dans le subject
            await MainActor.run {
                var decks = self.decksSubject.value
                if let index = decks.firstIndex(where: { $0.id == deckID }) {
                    decks[index] = updatedDeck
                    self.decksSubject.send(decks)
                }
            }
            
            return updatedDeck
        }
    }
    
    public func mergeDeck(_ sourceDeckID: UUID, intoDeckID targetDeckID: UUID) async throws -> Deck {
        // Vérifier que ce ne sont pas les mêmes paquets
        if sourceDeckID == targetDeckID {
            throw DeckServiceError.invalidDeckData
        }
        
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Vérifier que les deux paquets existent
            let decksFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            decksFetchRequest.predicate = NSPredicate(format: "id IN %@", [sourceDeckID, targetDeckID])
        fetchRequest.fetchBatchSize = 20;     
            let decks = try context.fetch(decksFetchRequest)
            guard decks.count == 2,
                  let sourceDeck = decks.first(where: { $0.id == sourceDeckID }),
                  let targetDeck = decks.first(where: { $0.id == targetDeckID }) else {
                throw DeckServiceError.deckNotFound
            }
            
            // Récupérer toutes les cartes du paquet source
            let cardsFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            cardsFetchRequest.predicate = NSPredicate(format: "deckID == %@", sourceDeckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            let cards = try context.fetch(cardsFetchRequest)
            
            // Déplacer les cartes vers le paquet cible
            for cardEntity in cards {
                cardEntity.deckID = targetDeckID
                cardEntity.deck = targetDeck
            }
            
            // Mettre à jour le compteur de cartes
            targetDeck.cardCount += Int32(cards.count)
            targetDeck.updatedAt = Date()
            
            // Fusionner les tags uniques
            var targetTags = Set(targetDeck.tags)
            targetTags.formUnion(sourceDeck.tags)
            targetDeck.tags = Array(targetTags)
            
            // Supprimer le paquet source
            context.delete(sourceDeck)
            
            try context.save()
            
            // Retourner le paquet cible mis à jour
            let updatedTargetDeck = await Task.detached {
                return self.mapDeckEntityToModel(targetDeck)
            }.value
            
            // Mettre à jour les paquets dans le subject
            await MainActor.run {
                var currentDecks = self.decksSubject.value
                currentDecks.removeAll { $0.id == sourceDeckID }
                
                if let targetIndex = currentDecks.firstIndex(where: { $0.id == targetDeckID }) {
                    currentDecks[targetIndex] = updatedTargetDeck
                }
                
                self.decksSubject.send(currentDecks)
            }
            
            return updatedTargetDeck
        }
    }
    
    // MARK: - Méthodes du protocole DeckServiceProtocol
    
    public func createDeck(_ deck: Deck) async throws -> Deck {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Vérifier si le paquet existe déjà
            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", deck.id as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            if let existingDeck = try context.fetch(fetchRequest).first {
                // Le paquet existe déjà, renvoyer une erreur
                throw DeckServiceError.duplicateDeck
            }
            
            // Créer une nouvelle entité de paquet
            let deckEntity = DeckEntity(context: context)
            deckEntity.id = deck.id
            deckEntity.name = deck.name
            deckEntity.desc = deck.description
            deckEntity.icon = deck.icon
            deckEntity.colorName = deck.colorName
            deckEntity.tags = deck.tags
            deckEntity.cardCount = Int32(deck.cardCount)
            deckEntity.createdAt = deck.createdAt
            deckEntity.updatedAt = deck.updatedAt
            
            // Sauvegarder le contexte
            try context.save()
            
            // Retourner le paquet mis à jour
            let updatedDeck = await Task.detached {
                return self.mapDeckEntityToModel(deckEntity)
            }.value
            
            // Notifier les abonnés en utilisant MainActor pour éviter les problèmes de concurrence
            await MainActor.run {
                var updatedDecks = self.decksSubject.value
                updatedDecks.append(updatedDeck)
                self.decksSubject.send(updatedDecks)
            }
            
            return updatedDeck
        }
    }
    
    public func deleteDecks(_ decks: [Deck]) async throws {
        for deck in decks {
            try await deleteDeck(deck)
        }
    }
    
    public func getDecks(withTags tags: [String]) async throws -> [Deck] {
        let context = newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
        
        fetchRequest.fetchBatchSize = 20; if !tags.isEmpty {
            let predicates = tags.map { tag in
                NSPredicate(format: "ANY tags == %@", tag)
            }
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        return try await context.performAsync {
            let entities = try context.fetch(fetchRequest)
            return await Task.detached {
                return entities.map { [self] entity in
                    return self.mapDeckEntityToModel(entity)
                }
            }.value
        }
    }
    
    public func getSubdecks(forDeckID deckID: UUID) async throws -> [Deck] {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Récupérer le paquet parent
            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", deckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let parentDeck = try context.fetch(fetchRequest).first else {
                return []
            }
            
            // Charger les sous-paquets
            let childDecks = Array(parentDeck.subdecks)
            return await Task.detached {
                return childDecks.map { [self] entity in
                    return self.mapDeckEntityToModel(entity)
                }
            }.value
        }
    }
    
    public func addCardToDeck(cardID: UUID, deckID: UUID) async throws {
        let context = newBackgroundContext()
        
        try await context.performAsync {
            // Vérifier que le paquet existe
            let deckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            deckFetchRequest.predicate = NSPredicate(format: "id == %@", deckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            guard let deckEntity = try context.fetch(deckFetchRequest).first else {
                throw DeckServiceError.deckNotFound
            }
            
            // Récupérer la carte
            let cardFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            cardFetchRequest.predicate = NSPredicate(format: "id == %@", cardID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            guard let cardEntity = try context.fetch(cardFetchRequest).first else {
                throw CoreError.entityNotFound
            }
            
            // Mettre à jour le paquet de la carte
            let oldDeckID = cardEntity.deckID
            cardEntity.deckID = deckID
            cardEntity.deck = deckEntity
            
            // Mettre à jour le compteur de cartes
            deckEntity.cardCount += 1
            
            // Si la carte était déjà dans un paquet, mettre à jour son compteur
            if let oldDeckID = oldDeckID {
                let oldDeckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
                oldDeckFetchRequest.predicate = NSPredicate(format: "id == %@", oldDeckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;         
                if let oldDeckEntity = try context.fetch(oldDeckFetchRequest).first {
                    oldDeckEntity.cardCount = max(0, oldDeckEntity.cardCount - 1)
                }
            }
            
            try context.save()
            
            // Mettre à jour les paquets dans le subject
            await MainActor.run {
                var decks = self.decksSubject.value
                
                if let deckIndex = decks.firstIndex(where: { $0.id == deckID }) {
                    var updatedDeck = decks[deckIndex]
                    updatedDeck.cardCount += 1
                    decks[deckIndex] = updatedDeck
                }
                
                if let oldDeckID = oldDeckID, 
                   let oldDeckIndex = decks.firstIndex(where: { $0.id == oldDeckID }) {
                    var oldDeck = decks[oldDeckIndex]
                    oldDeck.cardCount = max(0, oldDeck.cardCount - 1)
                    decks[oldDeckIndex] = oldDeck
                }
                
                self.decksSubject.send(decks)
            }
        }
    }
    
    public func removeCardFromDeck(cardID: UUID, deckID: UUID) async throws {
        let context = newBackgroundContext()
        
        try await context.performAsync {
            // Vérifier que le paquet existe
            let deckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            deckFetchRequest.predicate = NSPredicate(format: "id == %@", deckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            guard let deckEntity = try context.fetch(deckFetchRequest).first else {
                throw DeckServiceError.deckNotFound
            }
            
            // Récupérer la carte
            let cardFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            cardFetchRequest.predicate = NSPredicate(format: "id == %@ AND deckID == %@", cardID as CVarArg, deckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            guard let cardEntity = try context.fetch(cardFetchRequest).first else {
                // Si la carte n'existe pas dans ce paquet, on ne fait rien
                return
            }
            
            // Mettre à jour le paquet de la carte (à nil)
            cardEntity.deck = nil
            cardEntity.deckID = nil
            
            // Mettre à jour le compteur de cartes
            deckEntity.cardCount = max(0, deckEntity.cardCount - 1)
            
            try context.save()
            
            // Mettre à jour les paquets dans le subject
            await MainActor.run {
                var decks = self.decksSubject.value
                
                if let deckIndex = decks.firstIndex(where: { $0.id == deckID }) {
                    var updatedDeck = decks[deckIndex]
                    updatedDeck.cardCount = max(0, updatedDeck.cardCount - 1)
                    decks[deckIndex] = updatedDeck
                    self.decksSubject.send(decks)
                }
            }
        }
    }
    
    public func moveCardToDeck(cardID: UUID, fromDeckID: UUID, toDeckID: UUID) async throws {
        _ = try await moveCard(cardID: cardID, fromDeckID: fromDeckID, toDeckID: toDeckID)
    }
    
    public func addSubdeck(_ subdeck: Deck, toParentID parentID: UUID) async throws {
        let context = newBackgroundContext()
        
        try await context.performAsync {
            // Vérifier que le paquet parent existe
            let parentFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            parentFetchRequest.predicate = NSPredicate(format: "id == %@", parentID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            guard let parentEntity = try context.fetch(parentFetchRequest).first else {
                throw DeckServiceError.deckNotFound
            }
            
            // Créer ou récupérer le sous-paquet
            let subdeckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            subdeckFetchRequest.predicate = NSPredicate(format: "id == %@", subdeck.id as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            let subdeckEntity: DeckEntity
            if let existingSubdeck = try context.fetch(subdeckFetchRequest).first {
                subdeckEntity = existingSubdeck
            } else {
                // Créer un nouveau sous-paquet
                subdeckEntity = DeckEntity(context: context)
                subdeckEntity.id = subdeck.id
                subdeckEntity.name = subdeck.name
                subdeckEntity.desc = subdeck.description
                subdeckEntity.icon = subdeck.icon
                subdeckEntity.colorName = subdeck.colorName
                subdeckEntity.tags = subdeck.tags
                subdeckEntity.createdAt = subdeck.createdAt
                subdeckEntity.updatedAt = Date()
                subdeckEntity.cardCount = Int32(subdeck.cardCount)
            }
            
            // Établir la relation parent-enfant
            subdeckEntity.parentDeck = parentEntity
            
            try context.save()
        }
    }
    
    public func removeSubdeck(deckID: UUID, fromParentID parentID: UUID) async throws {
        let context = newBackgroundContext()
        
        try await context.performAsync {
            // Vérifier que le paquet parent existe
            let parentFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            parentFetchRequest.predicate = NSPredicate(format: "id == %@", parentID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            guard let parentEntity = try context.fetch(parentFetchRequest).first else {
                throw DeckServiceError.deckNotFound
            }
            
            // Récupérer le sous-paquet
            let subdeckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            subdeckFetchRequest.predicate = NSPredicate(format: "id == %@ AND parentDeck.id == %@", deckID as CVarArg, parentID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            guard let subdeckEntity = try context.fetch(subdeckFetchRequest).first else {
                // Si le sous-paquet n'existe pas sous ce parent, on ne fait rien
                return
            }
            
            // Retirer la relation parent-enfant
            subdeckEntity.parentDeck = nil
            
            try context.save()
        }
    }
    
    public func getDeckStatistics(forDeckID deckID: UUID) async throws -> DeckStudyStats {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Vérifier que le paquet existe
            let deckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            deckFetchRequest.predicate = NSPredicate(format: "id == %@", deckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            guard let deckEntity = try context.fetch(deckFetchRequest).first else {
                throw DeckServiceError.deckNotFound
            }
            
            // Récupérer toutes les cartes du paquet
            let cardsFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            cardsFetchRequest.predicate = NSPredicate(format: "deckID == %@", deckID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            let cards = try context.fetch(cardsFetchRequest)
            
            // Compter les cartes par niveau de maîtrise
            let totalCards = cards.count
            let newCards = cards.filter { $0.masteryLevel == 0 }.count
            let learningCards = cards.filter { $0.masteryLevel == 1 || $0.masteryLevel == 2 }.count
            let reviewingCards = cards.filter { $0.masteryLevel == 3 }.count
            let masteredCards = cards.filter { $0.masteryLevel == 4 }.count
            
            // Compter les cartes dues
            let now = Date()
            let dueCards = cards.filter { $0.nextReviewDate != nil && $0.nextReviewDate! <= now }.count
            
            // Calculer la rétention moyenne (ratio de réponses correctes)
            let averageRetention: Double
            if cards.isEmpty {
                averageRetention = 0
            } else {
                let totalReviews = cards.reduce(0) { $0 + Int($1.reviewCount) }
                let totalCorrect = cards.reduce(0) { $0 + Int($1.correctCount) }
                
                averageRetention = totalReviews > 0 ? Double(totalCorrect) / Double(totalReviews) : 0
            }
            
            // Calculer le taux de complétion (ratio de cartes maîtrisées)
            let completionRate = totalCards > 0 ? Double(masteredCards) / Double(totalCards) : 0
            
            // Trouver la dernière date d'étude
            let lastStudyDate = cards.compactMap { $0.lastReviewedAt }.max()
            
            // Compter les cartes étudiées aujourd'hui
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let cardsStudiedToday = cards.filter {
                guard let lastReviewedAt = $0.lastReviewedAt else { return false }
                return calendar.isDate(lastReviewedAt, inSameDayAs: today)
            }.count
            
            // Pour simplifier, on utilise une valeur par défaut pour le temps d'étude aujourd'hui
            let studyTimeToday: TimeInterval = 0 // À implémenter si nécessaire
            
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
                lastStudyDate: lastStudyDate,
                cardsStudiedToday: cardsStudiedToday,
                studyTimeToday: studyTimeToday
            )
        }
    }
    
    public func updateDeckStatistics(forDeckID deckID: UUID) async throws {
        // Cette méthode met simplement à jour les statistiques qui sont calculées à la volée
        _ = try await getDeckStatistics(forDeckID: deckID)
    }
    
    public func importDecks(_ decks: [Deck]) async throws -> [Deck] {
        var importedDecks: [Deck] = []
        
        for deck in decks {
            do {
                let importedDeck = try await createDeck(deck)
                importedDecks.append(importedDeck)
            } catch {
                self.logger.error("Erreur lors de l'importation du paquet \(deck.name): \(error.localizedDescription)")
                // Continuer avec le paquet suivant
            }
        }
        
        return importedDecks
    }
    
    public func exportDecks(_ decks: [Deck]) async throws -> Data {
        // Simuler l'exportation en convertissant les paquets en JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(decks)
    }
} 