import Foundation
import CoreData

@objc(CardReviewEntity)
public class CardReviewEntity: NSManagedObject, @unchecked Sendable {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date
    @NSManaged public var responseTime: Double
    @NSManaged public var rating: String
    @NSManaged public var newInterval: Int16
    @NSManaged public var newEase: Double
    @NSManaged public var newMasteryLevel: Int16
    
    // Relations
    @NSManaged public var card: CardEntity?
    @NSManaged public var session: StudySessionEntity?
}

extension CardReviewEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CardReviewEntity> {
        return NSFetchRequest<CardReviewEntity>(entityName: "CardReviewEntity")
    }
    
    // MARK: - Méthodes d'aide pour le rating
    
    public var reviewRating: Core.Common.ReviewRating {
        get {
            if let intValue = Int(rating) {
                return Core.Common.ReviewRating(rawValue: intValue) ?? .again
            }
            return .again
        }
        set {
            rating = String(newValue.rawValue)
        }
    }
}

// MARK: - Conversion vers le modèle CardReview

extension CardReview {
    public init(from entity: CardReviewEntity) throws {
        guard let id = entity.id,
              let card = entity.card,
              let cardID = card.id else {
            throw Core.Common.StudyServiceError.invalidData
        }
        
        self.init(
            id: id,
            cardID: cardID,
            sessionID: entity.session?.id,
            timestamp: entity.timestamp,
            rating: entity.reviewRating,
            responseTime: entity.responseTime,
            newInterval: Int(entity.newInterval),
            newEase: entity.newEase,
            newMasteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(entity.newMasteryLevel)) ?? .novice
        )
    }
} 
