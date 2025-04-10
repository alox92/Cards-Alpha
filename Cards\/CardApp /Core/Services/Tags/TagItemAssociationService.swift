import Foundation
import CoreData
import Combine

/// Protocole définissant les fonctionnalités du service d'association des tags aux items
public protocol TagItemAssociationServiceProtocol {
    // Récupère tous les IDs d'items d'un type spécifique associés à un tag
    func getItemsForTag(tagID: UUID, itemType: TaggedItemType) async throws -> [UUID]
    
    // Récupère tous les tags associés à un item spécifique
    func getTagsForItem(itemID: UUID, itemType: TaggedItemType) async throws -> [Tag]
    
    // Associe un tag à des items
    func addTagToItems(tagID: UUID, itemIDs: [UUID], itemType: TaggedItemType) async throws
    
    // Retire un tag de certains items
    func removeTagFromItems(tagID: UUID, itemIDs: [UUID], itemType: TaggedItemType) async throws
    
    // Retire tous les tags des items spécifiés
    func removeAllTagsFromItems(itemIDs: [UUID], itemType: TaggedItemType) async throws
    
    // Retire tous les tags d'un certain type
    func removeAllTagsOfType(itemType: TaggedItemType) async throws
}

/// Service gérant les associations entre les tags et les différents types d'items
@preconcurrency
public class TagItemAssociationService: TagItemAssociationServiceProtocol, @unchecked Sendable {
    // MARK: - Propriétés
    private let dataService: DataManagementServiceProtocol
    private let tagsSubject = CurrentValueSubject<[TagItemAssociation], Never>([])
    
    // MARK: - Publishers
    public var associationsPublisher: AnyPublisher<[TagItemAssociation], Never> {
        tagsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialisation
    public init(dataService: DataManagementServiceProtocol) {
        self.dataService = dataService
        
        // Initialiser la liste des associations
        Task {
            do {
                let associations = try await getAllAssociations()
                await updateAssociationsPublisher(with: associations)
            } catch {
                print("Erreur lors de l'initialisation des associations de tags: \(error)")
            }
        }
    }
    
    // MARK: - Implémentation de TagItemAssociationServiceProtocol
    
    public func getItemsForTag(tagID: UUID, itemType: TaggedItemType) async throws -> [UUID] {
        let entities = try await dataService.fetch(TagItemAssociationEntity.self) { request in
            request.predicate = NSPredicate(format: "tagID == %@ AND itemType == %@", tagID as CVarArg, itemType.rawValue)
        }
        
        return entities.compactMap { $0.itemID }
    }
    
    public func getTagsForItem(itemID: UUID, itemType: TaggedItemType) async throws -> [Tag] {
        let entities = try await dataService.fetch(TagItemAssociationEntity.self) { request in
            request.predicate = NSPredicate(format: "itemID == %@ AND itemType == %@", itemID as CVarArg, itemType.rawValue)
        }
        
        let tagIDs = entities.compactMap { $0.tagID }
        
        // Récupérer les entités de tag correspondantes
        let tagEntities = try await dataService.fetch(TagEntity.self) { request in
            request.predicate = NSPredicate(format: "id IN %@", tagIDs as NSArray)
        }
        
        return tagEntities.map { convertTagEntityToModel($0) }
    }
    
    /// Convertit une entité TagEntity en modèle Tag de manière thread-safe
    nonisolated private func convertTagEntityToModel(_ entity: TagEntity) -> Tag {
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
    
    public func addTagToItems(tagID: UUID, itemIDs: [UUID], itemType: TaggedItemType) async throws {
        for itemID in itemIDs {
            // Vérifier si l'association existe déjà
            let existing = try await getAssociation(tagID: tagID, itemID: itemID, itemType: itemType)
            
            if existing == nil {
                // Créer une nouvelle association
                try await dataService.create(TagItemAssociationEntity.self) { entity in
                    entity.id = UUID()
                    entity.tagID = tagID
                    entity.itemID = itemID
                    entity.itemType = itemType.rawValue
                    entity.createdAt = Date()
                }
            }
        }
        
        await updateAssociationsPublisher()
    }
    
    public func removeTagFromItems(tagID: UUID, itemIDs: [UUID], itemType: TaggedItemType) async throws {
        try await dataService.deleteMultiple(TagItemAssociationEntity.self) { request in
            request.predicate = NSPredicate(
                format: "tagID == %@ AND itemID IN %@ AND itemType == %@", 
                tagID as CVarArg,
                itemIDs as NSArray,
                itemType.rawValue
            )
        }
        
        await updateAssociationsPublisher()
    }
    
    public func removeAllTagsFromItems(itemIDs: [UUID], itemType: TaggedItemType) async throws {
        try await dataService.deleteMultiple(TagItemAssociationEntity.self) { request in
            request.predicate = NSPredicate(
                format: "itemID IN %@ AND itemType == %@", 
                itemIDs as NSArray,
                itemType.rawValue
            )
        }
        
        await updateAssociationsPublisher()
    }
    
    public func removeAllTagsOfType(itemType: TaggedItemType) async throws {
        try await dataService.deleteMultiple(TagItemAssociationEntity.self) { request in
            request.predicate = NSPredicate(format: "itemType == %@", itemType.rawValue)
        }
        
        await updateAssociationsPublisher()
    }
    
    // MARK: - Méthodes internes
    
    /// Récupère toutes les associations tag-item
    @MainActor
    public func getAllAssociations() async throws -> [TagItemAssociation] {
        let entities = try await dataService.fetchAll(TagItemAssociationEntity.self)
        return entities.compactMap { convertEntityToAssociation($0) }
    }
    
    /// Convertit une entité en modèle d'association de manière thread-safe
    nonisolated private func convertEntityToAssociation(_ entity: TagItemAssociationEntity) -> TagItemAssociation? {
        guard let id = entity.id,
              let tagID = entity.tagID,
              let itemID = entity.itemID,
              let itemTypeRaw = entity.itemType,
              let itemType = TaggedItemType(rawValue: itemTypeRaw),
              let createdAt = entity.createdAt else {
            return nil
        }
        
        return TagItemAssociation(
            id: id,
            tagID: tagID,
            itemID: itemID,
            itemType: itemType,
            createdAt: createdAt
        )
    }
    
    /// Récupérer une association spécifique
    private func getAssociation(tagID: UUID, itemID: UUID, itemType: TaggedItemType) async throws -> TagItemAssociation? {
        let entities = try await dataService.fetch(TagItemAssociationEntity.self) { request in
            request.predicate = NSPredicate(
                format: "tagID == %@ AND itemID == %@ AND itemType == %@", 
                tagID as CVarArg,
                itemID as CVarArg,
                itemType.rawValue
            )
            request.fetchLimit = 1
        }
        
        guard let entity = entities.first else {
            return nil
        }
        
        return convertEntityToAssociation(entity)
    }
    
    /// Met à jour le publisher des associations
    @MainActor
    private func updateAssociationsPublisher(with associations: [TagItemAssociation]? = nil) async {
        if let associations = associations {
            tagsSubject.send(associations)
            return
        }
        
        do {
            let fetchedAssociations = try await getAllAssociations()
            tagsSubject.send(fetchedAssociations)
        } catch {
            print("Erreur lors de la mise à jour du publisher d'associations: \(error)")
        }
    }
    
    private func fetchAllAssociations() async -> [TagItemAssociation] {
        do {
            return try await getAllAssociations()
        } catch {
            print("Erreur lors de la récupération des associations: \(error)")
            return []
        }
    }
}

/*
IMPORTANT: Pour que ce service fonctionne correctement, vous devez ajouter l'entité
TagItemAssociationEntity au modèle Core Data (Cards.xcdatamodeld) avec les attributs suivants:
- id (UUID)
- tagID (UUID)
- itemID (UUID)
- itemType (String)
- createdAt (Date)
*/

// MARK: - Modèles

/// Modèle représentant une association entre un tag et un item
public struct TagItemAssociation: Identifiable, Codable, Sendable {
    public let id: UUID
    public let tagID: UUID
    public let itemID: UUID
    public let itemType: TaggedItemType
    public let createdAt: Date
    
    public init(id: UUID = UUID(), tagID: UUID, itemID: UUID, itemType: TaggedItemType, createdAt: Date = Date()) {
        self.id = id
        self.tagID = tagID
        self.itemID = itemID
        self.itemType = itemType
        self.createdAt = createdAt
    }
} 