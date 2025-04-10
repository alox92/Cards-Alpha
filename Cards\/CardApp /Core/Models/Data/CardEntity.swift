import Foundation
import CoreData

@objc(CardEntity)
public class CardEntity: NSManagedObject, @unchecked Sendable {
    @NSManaged public var id: UUID?
    @NSManaged public var deckID: UUID?
    @NSManaged public var question: String
    @NSManaged public var answer: String
    @NSManaged public var additionalInfo: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var lastReviewedAt: Date?
    @NSManaged public var nextReviewDate: Date?
    @NSManaged public var reviewCount: Int16
    @NSManaged public var correctCount: Int16
    @NSManaged public var incorrectCount: Int16
    @NSManaged public var masteryLevel: Int16
    @NSManaged public var interval: Int16
    @NSManaged public var ease: Double
    @NSManaged public var isFlagged: Bool
    @NSManaged public var tags: [String]
    
    // Relations
    @NSManaged public var deck: DeckEntity?
    @NSManaged public var reviews: Set<CardReviewEntity>
}

extension CardEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CardEntity> {
        return NSFetchRequest<CardEntity>(entityName: "CardEntity")
    }
} 