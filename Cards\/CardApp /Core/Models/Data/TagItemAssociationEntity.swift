import Foundation
import CoreData

/// Représentation CoreData d'une association tag-item
@objc(TagItemAssociationEntity)
public class TagItemAssociationEntity: NSManagedObject, @unchecked Sendable {
    @NSManaged public var id: UUID?
    @NSManaged public var tagID: UUID?
    @NSManaged public var itemID: UUID?
    @NSManaged public var itemType: String?
    @NSManaged public var createdAt: Date?
}

extension TagItemAssociationEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TagItemAssociationEntity> {
        return NSFetchRequest<TagItemAssociationEntity>(entityName: "TagItemAssociationEntity")
    }
}

// MARK: - Conversion pour TagItemAssociation

extension TagItemAssociation {
    /// Crée une association à partir d'une entité CoreData
    public init(from entity: TagItemAssociationEntity) throws {
        guard let id = entity.id,
              let tagID = entity.tagID,
              let itemID = entity.itemID,
              let itemTypeRaw = entity.itemType,
              let itemType = TaggedItemType(rawValue: itemTypeRaw),
              let createdAt = entity.createdAt else {
            throw NSError(domain: "TagItemAssociation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Données invalides"])
        }
        
        self.init(
            id: id,
            tagID: tagID,
            itemID: itemID,
            itemType: itemType,
            createdAt: createdAt
        )
    }
} 