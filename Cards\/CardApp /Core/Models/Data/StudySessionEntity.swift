import Foundation
import CoreData

@objc(StudySessionEntity)
public class StudySessionEntity: NSManagedObject, @unchecked Sendable {
    @NSManaged public var id: UUID?
    @NSManaged public var deckID: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var reviewsData: Data?
    @NSManaged public var includeSubdecks: Bool
    @NSManaged public var reviewLimit: Int32
    @NSManaged public var totalReviews: Int32
    @NSManaged public var totalCorrect: Int32
    @NSManaged public var totalIncorrect: Int32
    @NSManaged public var totalTime: Double
    
    // Relations
    @NSManaged public var deck: DeckEntity?
    @NSManaged public var reviews: Set<CardReviewEntity>
}

extension StudySessionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StudySessionEntity> {
        return NSFetchRequest<StudySessionEntity>(entityName: "StudySessionEntity")
    }
}

// MARK: - Conversion vers le modèle StudySession

extension StudySession {
    public init(from entity: StudySessionEntity) throws {
        guard let id = entity.id,
              let startTime = entity.startTime else {
            throw Core.Common.StudyServiceError.invalidData
        }
        
        let cardIDs = entity.reviews.compactMap { $0.card?.id }
        let goodRatings = entity.reviews.filter { 
            if let ratingValue = Int($0.rating), 
               let rating = ReviewRating(rawValue: ratingValue) {
                return rating == .good || rating == .easy
            }
            return false
        }
        let badRatings = entity.reviews.filter { 
            if let ratingValue = Int($0.rating), 
               let rating = ReviewRating(rawValue: ratingValue) {
                return rating == .again || rating == .hard
            }
            return false
        }
        
        // Calculer la durée totale d'étude si possible
        var totalStudyTime: TimeInterval = 0
        if let endTime = entity.endTime {
            totalStudyTime = endTime.timeIntervalSince(startTime)
        }
        
        self.init(
            id: id,
            deckID: entity.deckID ?? UUID(),
            startDate: startTime,
            endDate: entity.endTime,
            scheduledCards: cardIDs,
            reviewedCards: cardIDs,
            correctCount: goodRatings.count,
            incorrectCount: badRatings.count,
            includeSubdecks: entity.includeSubdecks,
            reviewLimit: entity.reviewLimit > 0 ? Int(entity.reviewLimit) : nil,
            totalStudyTime: totalStudyTime
        )
    }
} 