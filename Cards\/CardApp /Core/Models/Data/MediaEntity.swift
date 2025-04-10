import Foundation
import CoreData

extension MediaEntity {
    @NSManaged public var id: UUID?
    @NSManaged public var url: URL?
    @NSManaged public var type: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var card: CardEntity?
    
    static func fetchRequest() -> NSFetchRequest<MediaEntity> {
        return NSFetchRequest<MediaEntity>(entityName: "MediaEntity")
    }
}

// MARK: - Initializers & Lifecycle
extension MediaEntity {
    @discardableResult
    static func create(in context: NSManagedObjectContext,
                      url: URL,
                      type: String,
                      card: CardEntity? = nil) -> MediaEntity {
        let entity = MediaEntity(context: context)
        entity.id = UUID()
        entity.url = url
        entity.type = type
        entity.createdAt = Date()
        entity.updatedAt = Date()
        entity.card = card
        return entity
    }
    
    func update(url: URL? = nil,
               type: String? = nil,
               card: CardEntity? = nil) {
        if let url = url { self.url = url }
        if let type = type { self.type = type }
        if let card = card { self.card = card }
        self.updatedAt = Date()
    }
}
