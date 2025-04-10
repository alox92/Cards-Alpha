import Foundation
import Combine

/// Protocole pour le service de statistiques
@MainActor public protocol StatisticsServiceProtocol {
    /// Récupère les statistiques globales d'utilisation
    func getOverallStats() async throws -> OverallStats
    
    /// Récupère les statistiques pour un deck spécifique
    func getStatsForDeck(id: UUID) async throws -> DeckStats
    
    /// Récupère l'historique d'activité pour une période donnée
    func getReviewActivity(period: ReviewPeriod) async throws -> [ReviewActivity]
    
    /// Met à jour les statistiques après une session d'étude
    func updateStats(for session: StudySession) async throws
    
    /// Réinitialise toutes les statistiques
    func resetAllStats() async throws
    
    /// Publie les changements de statistiques
    var statsPublisher: AnyPublisher<OverallStats, Never> { get }
}

/// Statistiques globales d'utilisation
public struct OverallStats: Codable, Equatable, Sendable {
    public let totalCards: Int
    public let totalDecks: Int
    public let cardsCreatedToday: Int
    public let cardsReviewedToday: Int
    public let totalReviews: Int
    public let averageSuccessRate: Double
    public let streakDays: Int
    public let lastReviewDate: Date?
    
    public init(
        totalCards: Int = 0,
        totalDecks: Int = 0,
        cardsCreatedToday: Int = 0,
        cardsReviewedToday: Int = 0,
        totalReviews: Int = 0,
        averageSuccessRate: Double = 0.0,
        streakDays: Int = 0,
        lastReviewDate: Date? = nil
    ) {
        self.totalCards = totalCards
        self.totalDecks = totalDecks
        self.cardsCreatedToday = cardsCreatedToday
        self.cardsReviewedToday = cardsReviewedToday
        self.totalReviews = totalReviews
        self.averageSuccessRate = averageSuccessRate
        self.streakDays = streakDays
        self.lastReviewDate = lastReviewDate
    }
}

/// Période pour l'affichage des statistiques de révision
public enum ReviewPeriod: String, CaseIterable, Identifiable, Sendable {
    case day
    case week
    case month
    case year
    case allTime
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        switch self {
        case .day: return "Aujourd'hui"
        case .week: return "Cette semaine"
        case .month: return "Ce mois-ci"
        case .year: return "Cette année"
        case .allTime: return "Tout l'historique"
        }
    }
    
    public var daysAgo: Int? {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .year: return 365
        case .allTime: return nil
        }
    }
}

/// Activité de révision pour une journée
public struct ReviewActivity: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let date: Date
    public let reviewCount: Int
    public let correctCount: Int
    public let newCardsCount: Int
    
    public var successRate: Double {
        guard reviewCount > 0 else { return 0 }
        return Double(correctCount) / Double(reviewCount)
    }
    
    public init(id: UUID = UUID(), date: Date, reviewCount: Int, correctCount: Int, newCardsCount: Int) {
        self.id = id
        self.date = date
        self.reviewCount = reviewCount
        self.correctCount = correctCount
        self.newCardsCount = newCardsCount
    }
}

/// Statistiques pour un deck spécifique
public struct DeckStats: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID  // ID du deck
    public let cardCount: Int
    public let masteredCardCount: Int
    public let learningCardCount: Int
    public let newCardCount: Int
    public let lastReviewDate: Date?
    public let creationDate: Date
    public let reviewHistory: [ReviewActivity]
    
    public var masteryPercentage: Double {
        guard cardCount > 0 else { return 0 }
        return Double(masteredCardCount) / Double(cardCount) * 100.0
    }
    
    public init(
        id: UUID,
        cardCount: Int = 0,
        masteredCardCount: Int = 0,
        learningCardCount: Int = 0,
        newCardCount: Int = 0,
        lastReviewDate: Date? = nil,
        creationDate: Date = Date(),
        reviewHistory: [ReviewActivity] = []
    ) {
        self.id = id
        self.cardCount = cardCount
        self.masteredCardCount = masteredCardCount
        self.learningCardCount = learningCardCount
        self.newCardCount = newCardCount
        self.lastReviewDate = lastReviewDate
        self.creationDate = creationDate
        self.reviewHistory = reviewHistory
    }
}

/// Implémentation du service de statistiques
@MainActor
public class StatisticsService: StatisticsServiceProtocol {
    private let persistenceController: PersistenceController
    private let statsSubject = CurrentValueSubject<OverallStats, Never>(OverallStats())
    
    public var statsPublisher: AnyPublisher<OverallStats, Never> {
        return statsSubject.eraseToAnyPublisher()
    }
    
    public init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        
        // Charger les statistiques initiales de manière asynchrone
        Task {
            if let stats = try? await getOverallStats() {
                statsSubject.send(stats)
            }
        }
    }
    
    public func getOverallStats() async throws -> OverallStats {
        // Simuler le chargement des statistiques
        return OverallStats(
            totalCards: 145,
            totalDecks: 8,
            cardsCreatedToday: 5,
            cardsReviewedToday: 23,
            totalReviews: 1250,
            averageSuccessRate: 0.76,
            streakDays: 5,
            lastReviewDate: Date()
        )
    }
    
    public func getStatsForDeck(id: UUID) async throws -> DeckStats {
        // Simuler le chargement des statistiques de deck
        return DeckStats(
            id: id,
            cardCount: 42,
            masteredCardCount: 28,
            learningCardCount: 10,
            newCardCount: 4,
            lastReviewDate: Date().addingTimeInterval(-86400), // Hier
            creationDate: Date().addingTimeInterval(-2592000), // Il y a 30 jours
            reviewHistory: generateSampleReviewHistory()
        )
    }
    
    public func getReviewActivity(period: ReviewPeriod) async throws -> [ReviewActivity] {
        // Simuler le chargement de l'historique d'activité
        return generateSampleReviewHistory()
    }
    
    public func updateStats(for session: StudySession) async throws {
        // Simuler la mise à jour des statistiques
        
        // Mettre à jour le sujet pour notifier les observateurs
        let currentStats = statsSubject.value
        let updatedStats = OverallStats(
            totalCards: currentStats.totalCards,
            totalDecks: currentStats.totalDecks,
            cardsCreatedToday: currentStats.cardsCreatedToday,
            cardsReviewedToday: currentStats.cardsReviewedToday + session.reviewedCards.count,
            totalReviews: currentStats.totalReviews + session.reviewedCards.count,
            averageSuccessRate: session.successRate,
            streakDays: currentStats.streakDays + 1,
            lastReviewDate: Date()
        )
        
        statsSubject.send(updatedStats)
    }
    
    public func resetAllStats() async throws {
        // Simuler la réinitialisation des statistiques
        statsSubject.send(OverallStats())
    }
    
    // Fonction helper pour générer des données d'exemple
    private func generateSampleReviewHistory() -> [ReviewActivity] {
        var activities = [ReviewActivity]()
        let calendar = Calendar.current
        
        // Générer 10 jours d'activité
        for day in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -day, to: Date()) ?? Date()
            let reviewCount = Int.random(in: 5...20)
            let correctCount = Int.random(in: 0...reviewCount)
            let newCardsCount = Int.random(in: 0...5)
            
            let activity = ReviewActivity(
                date: date,
                reviewCount: reviewCount,
                correctCount: correctCount,
                newCardsCount: newCardsCount
            )
            
            activities.append(activity)
        }
        
        return activities
    }
} 