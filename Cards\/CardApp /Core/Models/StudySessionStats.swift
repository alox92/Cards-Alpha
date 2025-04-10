import Foundation

/// Statistiques d'une session d'étude
public struct StudySessionStats: Codable, Equatable, Sendable {
    public let deckID: UUID
    public let totalCards: Int
    public let newCards: Int
    public let learningCards: Int
    public let reviewingCards: Int
    public let masteredCards: Int
    public let dueCards: Int
    public let averageRetention: Double
    public let completionRate: Double
    public let lastStudyDate: Date?
    public let cardsStudiedToday: Int
    public let studyTimeToday: TimeInterval
    
    public init(
        deckID: UUID,
        totalCards: Int,
        newCards: Int,
        learningCards: Int,
        reviewingCards: Int,
        masteredCards: Int,
        dueCards: Int,
        averageRetention: Double,
        completionRate: Double,
        lastStudyDate: Date?,
        cardsStudiedToday: Int,
        studyTimeToday: TimeInterval
    ) {
        self.deckID = deckID
        self.totalCards = totalCards
        self.newCards = newCards
        self.learningCards = learningCards
        self.reviewingCards = reviewingCards
        self.masteredCards = masteredCards
        self.dueCards = dueCards
        self.averageRetention = averageRetention
        self.completionRate = completionRate
        self.lastStudyDate = lastStudyDate
        self.cardsStudiedToday = cardsStudiedToday
        self.studyTimeToday = studyTimeToday
    }
} 