import Foundation
@preconcurrency import CoreData
import Combine
import SwiftUI
import os.log

/// Erreurs potentielles du service de tags
public enum UnifiedTagServiceError: Error, LocalizedError {
    case persistenceError(Error)
    case tagNotFound
    case invalidInput
    case duplicateTag
    
    public var errorDescription: String? {
        switch self {
        case .persistenceError(let error):
            return "Erreur de persistance : \(error.localizedDescription)"
        case .tagNotFound:
            return "Tag non trouvé"
        case .invalidInput:
            return "Données d'entrée invalides"
        case .duplicateTag:
            return "Ce tag existe déjà"
        }
    }
}

/// Structure pour stocker les statistiques des tags
public struct TagStatistics: Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID { tagID }
    public let tagID: UUID
    public let name: String
    public let usage: Int
    public let cardsCount: Int
    public let decksCount: Int
}

/// Implémentation unifiée du service de tags
@MainActor
public class UnifiedTagService: TagServiceProtocol {
    // MARK: - Propriétés
    private let persistenceController: PersistenceController
    private let dataService: DataManagementServiceProtocol
    private let tagItemAssociationService: TagItemAssociationServiceProtocol
    private let logger = Logger(subsystem: "com.app.cardapp", category: "UnifiedTagService")
    private let tagsSubject = CurrentValueSubject<[Tag], Never>([])
    
    public var tagsPublisher: AnyPublisher<[Tag], Never> {
        return tagsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialisation
    public init(persistenceController: PersistenceController, 
                dataService: DataManagementServiceProtocol,
                tagItemAssociationService: TagItemAssociationServiceProtocol) {
        self.persistenceController = persistenceController
        self.dataService = dataService
        self.tagItemAssociationService = tagItemAssociationService
        logger.info("UnifiedTagService initialisé")
        
        // Charger les données initiales
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let tags = try await self.getAllTags()
                self.tagsSubject.send(tags)
            } catch {
                self.logger.error("Erreur lors du chargement initial des tags: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Propriétés privées
    private var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    private func newBackgroundContext() -> NSManagedObjectContext {
        return persistenceController.container.newBackgroundContext()
    }
    
    // MARK: - Opérations CRUD de base
    
    public func getAllTags() async throws -> [Tag] {
        let context = newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TagEntity.name, ascending: true)]
        fetchRequest.fetchBatchSize = 20; 
        return try await context.performAsync {
            let tagEntities = try context.fetch(fetchRequest)
            let mappedTags = tagEntities.map { entity -> Tag in
                return Tag(
                    id: entity.id ?? UUID(),
                    name: entity.name,
                    color: entity.color,
                    description: entity.tagDescription,
                    usage: Int(entity.usage),
                    createdAt: entity.createdAt,
                    updatedAt: entity.updatedAt
                )
            }
            return mappedTags
        }
    }
    
    public func getTag(byID id: UUID) async throws -> Tag {
        let context = newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchBatchSize = 20; fetchRequest.fetchLimit = 1
        
        return try await context.performAsync {
            guard let tagEntity = try context.fetch(fetchRequest).first else {
                throw UnifiedTagServiceError.tagNotFound
            }
            
            return Tag(
                id: tagEntity.id ?? UUID(),
                name: tagEntity.name,
                color: tagEntity.color,
                description: tagEntity.tagDescription,
                usage: Int(tagEntity.usage),
                createdAt: tagEntity.createdAt,
                updatedAt: tagEntity.updatedAt
            )
        }
    }
    
    public func getTag(byName name: String) async throws -> Tag {
        let context = newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", name)
        fetchRequest.fetchBatchSize = 20; fetchRequest.fetchLimit = 1
        
        return try await context.performAsync {
            guard let tagEntity = try context.fetch(fetchRequest).first else {
                throw UnifiedTagServiceError.tagNotFound
            }
            
            return Tag(
                id: tagEntity.id ?? UUID(),
                name: tagEntity.name,
                color: tagEntity.color,
                description: tagEntity.tagDescription,
                usage: Int(tagEntity.usage),
                createdAt: tagEntity.createdAt,
                updatedAt: tagEntity.updatedAt
            )
        }
    }
    
    public func createTag(_ tag: Tag) async throws -> Tag {
        guard !tag.name.isEmpty else {
            throw UnifiedTagServiceError.invalidInput
        }
        
        // Vérifier si le tag existe déjà
        do {
            _ = try await getTag(byName: tag.name)
            // Si on arrive ici, c'est que le tag existe déjà
            throw UnifiedTagServiceError.duplicateTag
        } catch UnifiedTagServiceError.tagNotFound {
            // C'est le cas attendu - le tag n'existe pas, on peut continuer
        } catch {
            // Une autre erreur s'est produite, la propager
            throw error
        }
        
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Créer la nouvelle entité de tag
            let tagEntity = TagEntity(context: context)
            tagEntity.id = tag.id
            tagEntity.name = tag.name
            tagEntity.color = tag.color
            tagEntity.tagDescription = tag.description
            tagEntity.createdAt = tag.createdAt
            tagEntity.updatedAt = tag.updatedAt
            tagEntity.usage = Int16(tag.usage)
            
            // Sauvegarder le contexte
            try context.save()
            
            let createdTag = Tag(
                id: tagEntity.id ?? UUID(),
                name: tagEntity.name,
                color: tagEntity.color,
                description: tagEntity.tagDescription,
                usage: Int(tagEntity.usage),
                createdAt: tagEntity.createdAt,
                updatedAt: tagEntity.updatedAt
            )
            
            // Mettre à jour le publisher
            Task { await self.refreshTagsPublisher() }
            
            return createdTag
        }
    }
    
    public func updateTag(_ tag: Tag) async throws -> Tag {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Trouver l'entité existante
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let tagEntity = try context.fetch(fetchRequest).first else {
                throw UnifiedTagServiceError.tagNotFound
            }
            
            // Mettre à jour les propriétés
            tagEntity.name = tag.name
            tagEntity.color = tag.color
            tagEntity.tagDescription = tag.description
            tagEntity.updatedAt = Date()
            tagEntity.usage = Int16(tag.usage)
            
            // Sauvegarder le contexte
            try context.save()
            
            let updatedTag = Tag(
                id: tagEntity.id ?? UUID(),
                name: tagEntity.name,
                color: tagEntity.color,
                description: tagEntity.tagDescription,
                usage: Int(tagEntity.usage),
                createdAt: tagEntity.createdAt,
                updatedAt: tagEntity.updatedAt
            )
            
            // Mettre à jour le publisher
            Task { await self.refreshTagsPublisher() }
            
            return updatedTag
        }
    }
    
    public func deleteTag(id: UUID) async throws {
        let context = newBackgroundContext()
        
        try await context.performAsync {
            // Trouver l'entité à supprimer
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let tagEntity = try context.fetch(fetchRequest).first else {
                throw UnifiedTagServiceError.tagNotFound
            }
            
            // Supprimer l'entité
            context.delete(tagEntity)
            
            // Sauvegarder le contexte
            try context.save()
            
            // Mettre à jour le publisher
            Task { await self.refreshTagsPublisher() }
        }
        
        // Supprimer toutes les associations de ce tag avec les items
        try await tagItemAssociationService.removeTagFromItems(tagID: id, itemIDs: [], itemType: .card)
        try await tagItemAssociationService.removeTagFromItems(tagID: id, itemIDs: [], itemType: .deck)
    }
    
    public func deleteTags(_ tags: [Tag]) async throws {
        for tag in tags {
            try await deleteTag(tag)
        }
    }
    
    public func searchTags(query: String) async throws -> [Tag] {
        let context = newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
        fetchRequest.fetchBatchSize = 20; fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TagEntity.usage, ascending: false)]
        
        return try await context.performAsync {
            let tagEntities = try context.fetch(fetchRequest)
            return tagEntities.map { entity in
                return Tag(
                    id: entity.id ?? UUID(),
                    name: entity.name,
                    color: entity.color,
                    description: entity.tagDescription,
                    usage: Int(entity.usage),
                    createdAt: entity.createdAt,
                    updatedAt: entity.updatedAt
                )
            }
        }
    }
    
    public func getMostUsedTags(limit: Int = 10) async throws -> [Tag] {
        let context = newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TagEntity.usage, ascending: false)]
        fetchRequest.fetchBatchSize = 20; fetchRequest.fetchLimit = limit
        
        return try await context.performAsync {
            let tagEntities = try context.fetch(fetchRequest)
            return tagEntities.map { entity in
                return Tag(
                    id: entity.id ?? UUID(),
                    name: entity.name,
                    color: entity.color,
                    description: entity.tagDescription,
                    usage: Int(entity.usage),
                    createdAt: entity.createdAt,
                    updatedAt: entity.updatedAt
                )
            }
        }
    }
    
    // MARK: - Tag Management
    
    public func addTagToCard(tagName: String, cardID: UUID) async throws {
        // Vérifier si le tag existe, sinon le créer
        let tag: Tag
        do {
            tag = try await getTag(byName: tagName)
        } catch UnifiedTagServiceError.tagNotFound {
            // Créer le tag s'il n'existe pas
            tag = try await createTag(Tag(name: tagName))
        }
        
        // Utiliser le service d'association tag-item
        try await tagItemAssociationService.addTagToItems(tagID: tag.id, itemIDs: [cardID], itemType: .card)
        
        // Incrémenter l'utilisation du tag
        try await incrementTagUsage(tagID: tag.id)
        
        // Mettre à jour le publisher
        await refreshTagsPublisher()
    }
    
    public func removeTagFromCard(tagName: String, cardID: UUID) async throws {
        // Récupérer le tag
        do {
            let tag = try await getTag(byName: tagName)
            
            // Utiliser le service d'association tag-item
            try await tagItemAssociationService.removeTagFromItems(tagID: tag.id, itemIDs: [cardID], itemType: .card)
            
            // Décrémenter l'utilisation du tag
            try await decrementTagUsage(tagID: tag.id)
            
            // Mettre à jour le publisher
            await refreshTagsPublisher()
        } catch UnifiedTagServiceError.tagNotFound {
            // Le tag n'existe pas, rien à faire
            return
        }
    }
    
    public func addTagToDeck(tagName: String, deckID: UUID) async throws {
        // Vérifier si le tag existe, sinon le créer
        let tag: Tag
        do {
            tag = try await getTag(byName: tagName)
        } catch UnifiedTagServiceError.tagNotFound {
            // Créer le tag s'il n'existe pas
            tag = try await createTag(Tag(name: tagName))
        }
        
        // Utiliser le service d'association tag-item
        try await tagItemAssociationService.addTagToItems(tagID: tag.id, itemIDs: [deckID], itemType: .deck)
        
        // Incrémenter l'utilisation du tag
        try await incrementTagUsage(tagID: tag.id)
        
        // Mettre à jour le publisher
        await refreshTagsPublisher()
    }
    
    public func removeTagFromDeck(tagName: String, deckID: UUID) async throws {
        // Récupérer le tag
        do {
            let tag = try await getTag(byName: tagName)
            
            // Utiliser le service d'association tag-item
            try await tagItemAssociationService.removeTagFromItems(tagID: tag.id, itemIDs: [deckID], itemType: .deck)
            
            // Décrémenter l'utilisation du tag
            try await decrementTagUsage(tagID: tag.id)
            
            // Mettre à jour le publisher
            await refreshTagsPublisher()
        } catch UnifiedTagServiceError.tagNotFound {
            // Le tag n'existe pas, rien à faire
            return
        }
    }
    
    // MARK: - Import/Export
    
    public func importTags(_ tags: [Tag]) async throws -> [Tag] {
        var importedTags: [Tag] = []
        
        for tag in tags {
            do {
                let importedTag = try await createTag(tag)
                importedTags.append(importedTag)
            } catch UnifiedTagServiceError.duplicateTag {
                // Ignorer les tags en double
                continue
            }
        }
        
        return importedTags
    }
    
    public func exportTags(_ tags: [Tag]) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(tags)
    }
    
    // MARK: - Méthodes d'extension
    
    public func incrementTagUsage(tagID: UUID) async throws -> Bool {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Trouver l'entité existante
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", tagID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let tagEntity = try context.fetch(fetchRequest).first else {
                return false
            }
            
            // Incrémenter l'usage
            tagEntity.usage += 1
            tagEntity.updatedAt = Date()
            
            // Sauvegarder le contexte
            try context.save()
            
            // Mettre à jour le publisher
            Task { await self.refreshTagsPublisher() }
            
            return true
        }
    }
    
    public func decrementTagUsage(tagID: UUID) async throws -> Bool {
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Trouver l'entité existante
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", tagID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            guard let tagEntity = try context.fetch(fetchRequest).first else {
                return false
            }
            
            // Décrémenter l'usage (s'assurer qu'il ne descend pas en dessous de 0)
            if tagEntity.usage > 0 {
                tagEntity.usage -= 1
            }
            tagEntity.updatedAt = Date()
            
            // Sauvegarder le contexte
            try context.save()
            
            // Mettre à jour le publisher
            Task { await self.refreshTagsPublisher() }
            
            return true
        }
    }
    
    public func mergeTags(sourceID: UUID, targetID: UUID) async throws -> Tag {
        guard sourceID != targetID else {
            throw UnifiedTagServiceError.invalidInput
        }
        
        // Obtenir les items associés au tag source
        let cardItemsSource = try await tagItemAssociationService.getItemsForTag(tagID: sourceID, itemType: .card)
        let deckItemsSource = try await tagItemAssociationService.getItemsForTag(tagID: sourceID, itemType: .deck)
        
        // Ajouter ces items au tag cible
        if !cardItemsSource.isEmpty {
            try await tagItemAssociationService.addTagToItems(tagID: targetID, itemIDs: cardItemsSource, itemType: .card)
        }
        
        if !deckItemsSource.isEmpty {
            try await tagItemAssociationService.addTagToItems(tagID: targetID, itemIDs: deckItemsSource, itemType: .deck)
        }
        
        // Supprimer les associations du tag source
        try await tagItemAssociationService.removeTagFromItems(tagID: sourceID, itemIDs: [], itemType: .card)
        try await tagItemAssociationService.removeTagFromItems(tagID: sourceID, itemIDs: [], itemType: .deck)
        
        let context = newBackgroundContext()
        
        return try await context.performAsync {
            // Récupérer les deux tags
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@ OR id == %@", sourceID as CVarArg, targetID as CVarArg)
        fetchRequest.fetchBatchSize = 20;     
            let tagEntities = try context.fetch(fetchRequest)
            
            guard tagEntities.count == 2 else {
                throw UnifiedTagServiceError.tagNotFound
            }
            
            // Identifier source et cible
            guard let sourceTag = tagEntities.first(where: { $0.id == sourceID }),
                  let targetTag = tagEntities.first(where: { $0.id == targetID }) else {
                throw UnifiedTagServiceError.tagNotFound
            }
            
            // Fusionner l'utilisation
            targetTag.usage += sourceTag.usage
            targetTag.updatedAt = Date()
            
            // Supprimer le tag source
            context.delete(sourceTag)
            
            // Sauvegarder le contexte
            try context.save()
            
            let mergedTag = Tag(
                id: targetTag.id ?? UUID(),
                name: targetTag.name,
                color: targetTag.color,
                description: targetTag.tagDescription,
                usage: Int(targetTag.usage),
                createdAt: targetTag.createdAt,
                updatedAt: targetTag.updatedAt
            )
            
            // Mettre à jour le publisher
            Task { await self.refreshTagsPublisher() }
            
            return mergedTag
        }
    }
    
    // MARK: - Méthodes privées
    
    /// Vérifie si un tag avec le nom spécifié existe déjà.
    private func tagExists(name: String, context: NSManagedObjectContext) throws -> Bool {
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", name)
        fetchRequest.fetchBatchSize = 20; let count = try context.count(for: fetchRequest)
        return count > 0
    }
    
    /// Met à jour le publisher de tags.
    private func refreshTagsPublisher() async {
        do {
            let tags = try await getAllTags()
            tagsSubject.send(tags)
        } catch {
            logger.error("Erreur lors de la mise à jour du publisher de tags: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Conformité au protocole TagServiceProtocol
    
    public func getTags(withNames names: [String]) async throws -> [Tag] {
        let context = newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name IN %@", names)
        fetchRequest.fetchBatchSize = 20; 
        return try await context.performAsync {
            let tagEntities = try context.fetch(fetchRequest)
            return tagEntities.map { entity in
                return Tag(
                    id: entity.id ?? UUID(),
                    name: entity.name,
                    color: entity.color,
                    description: entity.tagDescription,
                    usage: Int(entity.usage),
                    createdAt: entity.createdAt,
                    updatedAt: entity.updatedAt
                )
            }
        }
    }
    
    public func getTagsUsage() async throws -> [(String, Int)] {
        let context = newBackgroundContext()
        
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TagEntity.usage, ascending: false)]
        fetchRequest.fetchBatchSize = 20; 
        return try await context.performAsync {
            let tagEntities = try context.fetch(fetchRequest)
            return tagEntities.map { (entity) -> (String, Int) in
                return (entity.name, Int(entity.usage))
            }
        }
    }
    
    public func getTagsStatistics() async throws -> [TagStatistics] {
        // Récupérer tous les tags
        let tags = try await getAllTags()
        var statistics: [TagStatistics] = []
        
        // Pour chaque tag, récupérer les statistiques d'utilisation
        for tag in tags {
            // Récupérer les comptages via le service d'association tag-item
            let cardsCount = try await tagItemAssociationService.getItemsForTag(tagID: tag.id, itemType: .card).count
            let decksCount = try await tagItemAssociationService.getItemsForTag(tagID: tag.id, itemType: .deck).count
            
            let stat = TagStatistics(
                tagID: tag.id,
                name: tag.name,
                usage: tag.usage,
                cardsCount: cardsCount,
                decksCount: decksCount
            )
            
            statistics.append(stat)
        }
        
        // Trier par utilisation (descendant)
        return statistics.sorted { $0.usage > $1.usage }
    }
    
    /// Supprime un tag par son modèle
    public func deleteTag(_ tag: Tag) async throws {
        try await deleteTag(id: tag.id)
    }
} 