import Foundation
import CoreData

@objc(DeckEntity)
public class DeckEntity: NSManagedObject, @unchecked Sendable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String
    @NSManaged public var desc: String
    @NSManaged public var icon: String
    @NSManaged public var colorName: String
    @NSManaged public var tags: [String]
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var cardCount: Int32
    
    // Relations
    @NSManaged public var cards: Set<CardEntity>
    @NSManaged public var parentDeck: DeckEntity?
    @NSManaged public var subdecks: Set<DeckEntity>
}

extension DeckEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeckEntity> {
        return NSFetchRequest<DeckEntity>(entityName: "DeckEntity")
    }
} 