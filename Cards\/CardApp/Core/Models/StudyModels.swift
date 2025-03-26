import Foundation
import SwiftUI

// MARK: - Study Session
struct StudySession: Identifiable, Codable {
    let id: UUID
    let deckId: UUID
    let startTime: Date
    var endTime: Date?
    var reviews: [CardReview]
    
    // MARK: - Initialization
    init(id: UUID = UUID(), deckId: UUID, startTime: Date = Date(), endTime: Date? = nil, reviews: [CardReview] = []) {
        self.id = id
        self.deckId = deckId
        self.startTime = startTime
        self.endTime = endTime
        self.reviews = reviews
    }
    
    // MARK: - Methods
    mutating func addReview(_ review: CardReview) {
        reviews.append(review)
    }
    
    mutating func endSession() {
        self.endTime = Date()
    }
    
    // MARK: - Computed Properties
    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }
    
    var averageResponseTime: TimeInterval {
        guard !reviews.isEmpty else { return 0 }
        let total = reviews.reduce(0) { $0 + $1.timeSpent }
        return total / Double(reviews.count)
    }
    
    var successRate: Double {
        guard !reviews.isEmpty else { return 0 }
        let correctCount = reviews.filter { $0.rating == .good || $0.rating == .easy }.count
        return Double(correctCount) / Double(reviews.count) * 100
    }
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration ?? 0) ?? "0s"
    }
    
    var totalReviews: Int {
        reviews.count
    }
    
    var correctReviews: Int {
        reviews.filter { $0.rating == .good || $0.rating == .easy }.count
    }
    
    var incorrectReviews: Int {
        reviews.filter { $0.rating == .hard || $0.rating == .again }.count
    }
    
    var formattedSuccessRate: String {
        String(format: "%.1f%%", successRate)
    }
    
    // MARK: - Sample Data
    static var sampleData: [StudySession] = [
        StudySession(
            id: UUID(),
            deckId: UUID(),
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date(),
            reviews: [
                CardReview(cardID: UUID(), rating: .good, timeSpent: 8.5),
                CardReview(cardID: UUID(), rating: .hard, timeSpent: 15.2),
                CardReview(cardID: UUID(), rating: .easy, timeSpent: 5.1)
            ]
        )
    ]
    
    static var activeSession: StudySession {
        StudySession(
            id: UUID(),
            deckId: UUID(),
            startTime: Date().addingTimeInterval(-300),
            endTime: nil,
            reviews: []
        )
    }
}

// MARK: - Card Review
struct CardReview: Identifiable, Codable {
    let id: UUID
    let cardID: UUID
    let timestamp: Date
    let rating: ReviewRating
    let timeSpent: TimeInterval
    
    init(id: UUID = UUID(), cardID: UUID, rating: ReviewRating, timeSpent: TimeInterval) {
        self.id = id
        self.cardID = cardID
        self.timestamp = Date()
        self.rating = rating
        self.timeSpent = timeSpent
    }
    
    var isCorrect: Bool {
        rating != .again
    }
}

// MARK: - Review Rating
enum ReviewRating: String, CaseIterable, Codable {
    case again = "again"
    case hard = "hard" 
    case good = "good"
    case easy = "easy"
    
    var title: String {
        switch self {
        case .again: return "Encore"
        case .hard: return "Difficile"
        case .good: return "Bien"
        case .easy: return "Facile"
        }
    }
    
    var emoji: String {
        switch self {
        case .again: return "😕"
        case .hard: return "😐"
        case .good: return "🙂"
        case .easy: return "😀" 
        }
    }
    
    var color: Color {
        switch self {
        case .again: return .red
        case .hard: return .orange
        case .good: return .green
        case .easy: return .blue
        }
    }
}

// MARK: - Study Statistics
struct StudyStatistics {
    let totalReviews: Int
    let correctReviews: Int
    let incorrectReviews: Int
    let averageResponseTime: TimeInterval
    let totalStudyTime: TimeInterval
    
    var successRate: Double {
        guard totalReviews > 0 else { return 0 }
        return Double(correctReviews) / Double(totalReviews) * 100.0
    }
    
    var formattedSuccessRate: String {
        String(format: "%.1f%%", successRate)
    }
    
    static func formatSuccessRate(_ rate: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: rate / 100)) ?? "0%"
    }
}

// MARK: - StudySessionStatistics
struct StudySessionStatistics {
    let totalSessions: Int
    let totalCardsReviewed: Int
    let totalTimeSpent: TimeInterval
    let averageSuccessRate: Double
    let sessionsPerDay: [Date: Int]
    
    // MARK: - Computed Properties
    
    /// Average time spent per session in seconds
    var averageSessionDuration: TimeInterval {
        guard totalSessions > 0 else { return 0 }
        return totalTimeSpent / Double(totalSessions)
    }
    
    /// Formatted average session duration
    var formattedAverageSessionDuration: String {
        let totalSeconds = Int(averageSessionDuration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Formatted average success rate
    var formattedAverageSuccessRate: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: averageSuccessRate / 100.0)) ?? "0%"
    }
    
    /// Current streak in days
    var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        
        while true {
            let dateKey = calendar.startOfDay(for: currentDate)
            if sessionsPerDay[dateKey] != nil && sessionsPerDay[dateKey]! > 0 {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
}

// MARK: - Sample Data
extension StudySession {
    static var sampleData: [StudySession] {
        [
            StudySession(
                id: UUID(),
                deckId: UUID(),
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date().addingTimeInterval(-3000),
                reviews: [
                    CardReview(cardID: UUID(), rating: .good, timeSpent: 15),
                    CardReview(cardID: UUID(), rating: .again, timeSpent: 20),
                    CardReview(cardID: UUID(), rating: .easy, timeSpent: 8),
                    CardReview(cardID: UUID(), rating: .good, timeSpent: 12)
                ]
            ),
            StudySession(
                id: UUID(),
                deckId: UUID(),
                startTime: Date().addingTimeInterval(-86400),
                endTime: Date().addingTimeInterval(-86100),
                reviews: [
                    CardReview(cardID: UUID(), rating: .good, timeSpent: 10),
                    CardReview(cardID: UUID(), rating: .good, timeSpent: 12),
                    CardReview(cardID: UUID(), rating: .hard, timeSpent: 25)
                ]
            )
        ]
    }
    
    static var activeSession: StudySession {
        StudySession(
            id: UUID(),
            deckId: UUID(),
            startTime: Date().addingTimeInterval(-300),
            endTime: nil,
            reviews: []
        )
    }
} 