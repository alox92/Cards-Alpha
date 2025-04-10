import Foundation
import SwiftUI

/// Période pour les statistiques
public enum StatsPeriod: String, CaseIterable, Identifiable, Sendable {
    case today
    case week
    case month
    case year
    case allTime
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .today: return "Aujourd'hui"
        case .week: return "Cette semaine"
        case .month: return "Ce mois"
        case .year: return "Cette année"
        case .allTime: return "Toute la durée"
        }
    }
}

/// Type de statistique
public enum StatType: String, CaseIterable, Identifiable, Sendable {
    case cards
    case time
    case accuracy
    case streak
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .cards: return "Cartes"
        case .time: return "Temps d'étude"
        case .accuracy: return "Précision"
        case .streak: return "Séquence"
        }
    }
    
    public var icon: String {
        switch self {
        case .cards: return "rectangle.stack"
        case .time: return "clock"
        case .accuracy: return "checkmark.circle"
        case .streak: return "flame"
        }
    }
}

/// Point de données pour les graphiques
public struct ChartDataPoint: Identifiable, Sendable {
    public let id = UUID()
    public let date: Date
    public let value: Double
    public let label: String
    
    public init(date: Date, value: Double, label: String = "") {
        self.date = date
        self.value = value
        self.label = label
    }
}

/// Statistiques globales
public struct GlobalStats: Sendable {
    public var totalCards: Int = 0
    public var totalStudyTime: TimeInterval = 0
    public var averageAccuracy: Double = 0
    public var currentStreak: Int = 0
    public var longestStreak: Int = 0
    public var totalDecks: Int = 0
    public var masteredCards: Int = 0
    public var cardsStudiedToday: Int = 0
    public var averageResponseTime: TimeInterval = 0
    
    public init() {}
    
    public init(
        totalCards: Int = 0,
        totalStudyTime: TimeInterval = 0,
        averageAccuracy: Double = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalDecks: Int = 0,
        masteredCards: Int = 0,
        cardsStudiedToday: Int = 0,
        averageResponseTime: TimeInterval = 0
    ) {
        self.totalCards = totalCards
        self.totalStudyTime = totalStudyTime
        self.averageAccuracy = averageAccuracy
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalDecks = totalDecks
        self.masteredCards = masteredCards
        self.cardsStudiedToday = cardsStudiedToday
        self.averageResponseTime = averageResponseTime
    }
}

/// Informations statistiques sur un paquet
public struct DeckStatInfo: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let color: Color
    public let cardCount: Int
    public let masteredCount: Int
    public let dueCount: Int
    public let accuracy: Double
    public let lastStudied: Date?
    
    public init(
        id: UUID,
        name: String,
        color: Color = .blue,
        cardCount: Int = 0,
        masteredCount: Int = 0,
        dueCount: Int = 0,
        accuracy: Double = 0,
        lastStudied: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.cardCount = cardCount
        self.masteredCount = masteredCount
        self.dueCount = dueCount
        self.accuracy = accuracy
        self.lastStudied = lastStudied
    }
} 