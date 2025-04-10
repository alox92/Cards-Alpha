import SwiftUI
import Combine
import Foundation

/// Type spécifique pour les niveaux de maîtrise dans les statistiques,
/// distinct de l'énumération MasteryLevel utilisée dans le modèle de carte
public enum StatsMasteryLevel: String, CaseIterable, Identifiable {
    case new
    case learning
    case reviewing
    case mastered
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .new: return "Nouvelles"
        case .learning: return "En apprentissage"
        case .reviewing: return "En révision"
        case .mastered: return "Maîtrisées"
        }
    }
    
    public var color: Color {
        switch self {
        case .new: return .gray
        case .learning: return .blue
        case .reviewing: return .orange
        case .mastered: return .green
        }
    }
    
    /// Convertit un MasteryLevel du modèle en StatsMasteryLevel pour l'affichage
    public static func from(masteryLevel: Core.Models.Common.MasteryLevel) -> StatsMasteryLevel {
        switch masteryLevel {
        case .novice:
            return .new
        case .beginner:
            return .learning
        case .intermediate:
            return .learning
        case .advanced:
            return .reviewing
        case .expert:
            return .mastered
        }
    }
}

/// ViewModel pour la vue des statistiques
@MainActor
final class StatisticsViewModel: ObservableObject {
    // MARK: - Propriétés Publiées
    
    /// Période sélectionnée pour les statistiques
    @Published var selectedPeriod: StatsPeriod = .allTime
    
    /// Type de statistique sélectionné
    @Published var selectedStatType: StatType = .cards
    
    /// ID du paquet sélectionné (nil pour tous les paquets)
    @Published var selectedDeckID: UUID? = nil
    
    /// Données pour le graphique principal
    @Published var chartData: [ChartDataPoint] = []
    
    /// Données de répartition par niveau de maîtrise
    @Published var masteryData: [StatsMasteryLevel: Int] = [:]
    
    /// Statistiques globales
    @Published var globalStats: GlobalStats = GlobalStats()
    
    /// Top des paquets
    @Published var topDecks: [DeckStatInfo] = []
    
    /// État de chargement
    @Published var isLoading: Bool = false
    
    /// Erreur éventuelle
    @Published var errorMessage: String? = nil
    
    // MARK: - Dépendances
    private let statisticsService: StatisticsServiceProtocol
    private let deckService: DeckServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialisation
    init(statisticsService: StatisticsServiceProtocol, deckService: DeckServiceProtocol) {
        self.statisticsService = statisticsService
        self.deckService = deckService
        
        // Observer les changements de sélection pour recharger les données
        Publishers.CombineLatest3($selectedPeriod, $selectedStatType, $selectedDeckID)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.loadStatistics()
            }
            .store(in: &cancellables)
            
        loadStatistics() // Chargement initial
    }
    
    // MARK: - Méthodes Publiques
    
    /// Charge ou recharge toutes les statistiques basées sur les filtres actuels
    func loadStatistics() {
        Task { @MainActor in
            await fetchStatistics()
        }
    }
    
    private func fetchStatistics() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Conversion de StatsPeriod vers ReviewPeriod
            let reviewPeriod = convertToReviewPeriod(selectedPeriod)
            
            // Chargement des statistiques globales
            let overallStats = try await statisticsService.getOverallStats()
            
            // Chargement des statistiques du deck sélectionné ou des activités générales
            var deckStats: DeckStats?
            var activities: [ReviewActivity] = []
            
            if let deckID = selectedDeckID {
                deckStats = try await statisticsService.getStatsForDeck(id: deckID)
                activities = deckStats?.reviewHistory ?? []
            } else {
                activities = try await statisticsService.getReviewActivity(period: reviewPeriod)
            }
            
            // Chargement des decks
            let decks = try await deckService.getAllDecks()
            
            // Mise à jour des propriétés publiées
            updateUI(
                overallStats: overallStats,
                deckStats: deckStats,
                activities: activities,
                decks: decks
            )
            
        } catch {
            errorMessage = "Erreur lors du chargement des statistiques: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func updateUI(
        overallStats: OverallStats,
        deckStats: DeckStats?,
        activities: [ReviewActivity],
        decks: [Deck]
    ) {
        // Mise à jour des statistiques globales
        self.globalStats = convertToGlobalStats(overallStats, deckStats)
        
        // Mise à jour des données du graphique
        self.chartData = convertToChartData(activities)
        
        // Mise à jour de la répartition des niveaux de maîtrise
        self.masteryData = generateMasteryDistributionFromDeckStats(deckStats)
        
        // Mise à jour des top decks
        self.topDecks = convertToTopDecks(decks)
    }
    
    // MARK: - Actions Utilisateur
    
    func changePeriod(_ period: StatsPeriod) {
        selectedPeriod = period
        loadStatistics()
    }
    
    func changeStatType(_ type: StatType) {
        selectedStatType = type
        loadStatistics()
    }
    
    func selectDeck(_ deckID: UUID?) {
        selectedDeckID = deckID
        loadStatistics()
    }
    
    // MARK: - Fonctions utilitaires de conversion
    
    private func convertToReviewPeriod(_ statsPeriod: StatsPeriod) -> ReviewPeriod {
        switch statsPeriod {
        case .today:
            return .day
        case .week:
            return .week
        case .month:
            return .month
        case .year:
            return .year
        case .allTime:
            return .allTime
        }
    }
    
    private func convertToGlobalStats(_ overallStats: OverallStats, _ deckStats: DeckStats?) -> GlobalStats {
        return GlobalStats(
            totalCards: overallStats.totalCards,
            totalStudyTime: 0, // Non disponible dans OverallStats
            averageAccuracy: overallStats.averageSuccessRate * 100,
            currentStreak: overallStats.streakDays,
            longestStreak: overallStats.streakDays, // Non disponible dans OverallStats
            totalDecks: overallStats.totalDecks,
            masteredCards: deckStats?.masteredCardCount ?? 0,
            cardsStudiedToday: overallStats.cardsReviewedToday,
            averageResponseTime: 0 // Non disponible dans OverallStats
        )
    }
    
    private func convertToChartData(_ activities: [ReviewActivity]) -> [ChartDataPoint] {
        return activities.map { activity in
            let value: Double
            switch selectedStatType {
            case .cards:
                value = Double(activity.reviewCount)
            case .time:
                value = 0 // Non disponible dans ReviewActivity
            case .accuracy:
                value = activity.successRate * 100
            case .streak:
                value = 0 // Non disponible dans ReviewActivity
            }
            return ChartDataPoint(date: activity.date, value: value)
        }
    }
    
    private func generateMasteryDistributionFromDeckStats(_ deckStats: DeckStats?) -> [StatsMasteryLevel: Int] {
        guard let stats = deckStats else {
            return [:]
        }
        
        return [
            .new: stats.newCardCount,
            .learning: stats.learningCardCount,
            .reviewing: stats.learningCardCount, // Approximation
            .mastered: stats.masteredCardCount
        ]
    }
    
    private func convertToTopDecks(_ decks: [Deck]) -> [DeckStatInfo] {
        // Prendre les 5 premiers decks comme exemple
        return decks.prefix(5).map { deck in
            DeckStatInfo(
                id: deck.id,
                name: deck.name,
                cardCount: deck.cardCount
            )
        }
    }
}

// MARK: - Preview Mock ViewModel

#if DEBUG
extension StatisticsViewModel {
    /// Crée un ViewModel pré-configuré pour les previews SwiftUI
    static var preview: StatisticsViewModel {
        let persistenceController = PersistenceController(inMemory: true)
        let statisticsService = StatisticsService(persistenceController: persistenceController)
        let deckService = UnifiedDeckService(persistenceController: persistenceController)
        
        return StatisticsViewModel(
            statisticsService: statisticsService,
            deckService: deckService
        )
    }
}
#endif 