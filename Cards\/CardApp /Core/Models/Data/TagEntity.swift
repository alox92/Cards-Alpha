import Foundation
import CoreData

@objc(TagEntity)
public class TagEntity: NSManagedObject, @unchecked Sendable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String
    @NSManaged public var color: String
    @NSManaged public var tagDescription: String?
    @NSManaged public var usage: Int16
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

extension TagEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TagEntity> {
        return NSFetchRequest<TagEntity>(entityName: "TagEntity")
    }
}

// MARK: - Conversion vers le modèle Tag

extension Tag {
    public init(from entity: TagEntity) {
        self.init(
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