import Foundation
import CoreData

// MARK: - CardEntity
class CardEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var question: String?
    @NSManaged var answer: String?
    @NSManaged var additionalInfo: String?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var masteryLevel: String?
    @NSManaged var reviewCount: Int16
    @NSManaged var correctCount: Int16
    @NSManaged var incorrectCount: Int16
    @NSManaged var lastReviewedAt: Date?
    @NSManaged var nextReviewDate: Date?
    @NSManaged var tags: String?
    @NSManaged var isFlagged: Bool
    @NSManaged var deck: DeckEntity?
}

// MARK: - DeckEntity
class DeckEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var descriptionText: String?
    @NSManaged var icon: String?
    @NSManaged var colorName: String?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var cards: NSSet?
    
    public var cardsArray: [CardEntity] {
        let set = cards as? Set<CardEntity> ?? []
        return set.sorted { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
    }
    
    public var cardCount: Int {
        return cards?.count ?? 0
    }
    
    public var dueCardCount: Int {
        let set = cards as? Set<CardEntity> ?? []
        let now = Date()
        return set.filter { entity in
            if let nextReview = entity.nextReviewDate {
                return nextReview <= now
            } else {
                return entity.masteryLevel == "new"
            }
        }.count
    }
}

// MARK: - Accessors for Card Relationship
extension DeckEntity {
    @objc(addCardsObject:)
    @NSManaged public func addToCards(_ value: CardEntity)
    
    @objc(removeCardsObject:)
    @NSManaged public func removeFromCards(_ value: CardEntity)
    
    @objc(addCards:)
    @NSManaged public func addToCards(_ values: NSSet)
    
    @objc(removeCards:)
    @NSManaged public func removeFromCards(_ values: NSSet)
}

// MARK: - StudySessionEntity
class StudySessionEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var deckID: UUID?
    @NSManaged var startTime: Date?
    @NSManaged var endTime: Date?
    @NSManaged var reviewsData: Data?
} 