import Foundation

/// Statistiques d'étude pour une carte
public struct CardStudyStats: Codable, Equatable, Sendable {
    public let cardID: UUID
    public let totalReviews: Int
    public let correctReviews: Int
    public let incorrectReviews: Int
    public let successRate: Double
    public let averageResponseTime: TimeInterval
    public let firstStudyDate: Date?
    public let lastStudyDate: Date?
    
    public init(
        cardID: UUID,
        totalReviews: Int = 0,
        correctReviews: Int = 0,
        incorrectReviews: Int = 0,
        successRate: Double = 0,
        averageResponseTime: TimeInterval = 0,
        firstStudyDate: Date? = nil,
        lastStudyDate: Date? = nil
    ) {
        self.cardID = cardID
        self.totalReviews = totalReviews
        self.correctReviews = correctReviews
        self.incorrectReviews = incorrectReviews
        self.successRate = successRate
        self.averageResponseTime = averageResponseTime
        self.firstStudyDate = firstStudyDate
        self.lastStudyDate = lastStudyDate
    }
} 