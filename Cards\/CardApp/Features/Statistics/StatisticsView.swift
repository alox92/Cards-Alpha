import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var cardViewModel: CardViewModel
    @EnvironmentObject var deckViewModel: DeckViewModel
    @EnvironmentObject var studyViewModel: StudyViewModel
    
    @State private var selectedPeriod: StatsPeriod = .allTime
    @State private var selectedStatType: StatType = .cards
    @State private var selectedDeckId: UUID? = nil
    
    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }
    
    // MARK: - Layouts
    
    private var macOSLayout: some View {
        VStack(spacing: 0) {
            // Barre d'outils
            HStack {
                Picker("Période", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 400)
                
                Spacer()
                
                Picker("Type", selection: $selectedStatType) {
                    ForEach(StatType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Spacer()
                
                Picker("Paquet", selection: $selectedDeckId) {
                    Text("Tous les paquets").tag(nil as UUID?)
                    ForEach(deckViewModel.decks) { deck in
                        Text(deck.name).tag(deck.id as UUID?)
                    }
                }
                .frame(width: 200)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            // Contenu principal
            ScrollView {
                VStack(spacing: 20) {
                    // Statistiques globales
                    HStack(spacing: 20) {
                        statsCard(
                            title: "Cartes étudiées",
                            value: "\(getTotalCardsStudied())",
                            icon: "rectangle.stack",
                            color: .blue
                        )
                        
                        statsCard(
                            title: "Sessions",
                            value: "\(getTotalSessions())",
                            icon: "calendar",
                            color: .green
                        )
                        
                        statsCard(
                            title: "Taux de réussite",
                            value: "\(getSuccessRate())%",
                            icon: "chart.bar",
                            color: .orange
                        )
                        
                        statsCard(
                            title: "Temps d'étude",
                            value: getFormattedStudyTime(),
                            icon: "clock",
                            color: .purple
                        )
                    }
                    
                    // Graphique principal
                    VStack(alignment: .leading) {
                        Text("Progression")
                            .font(.headline)
                            .padding(.leading)
                        
                        mainStatsChart
                    }
                    .padding()
                    .background(Color(.textBackgroundColor).opacity(0.05))
                    .cornerRadius(12)
                    
                    // Statistiques détaillées
                    HStack(alignment: .top, spacing: 20) {
                        // Statistiques par niveau de maîtrise
                        VStack(alignment: .leading) {
                            Text("Répartition par niveau")
                                .font(.headline)
                            
                            ForEach(MasteryLevel.allCases) { level in
                                masteryLevelRow(level: level)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.textBackgroundColor).opacity(0.05))
                        .cornerRadius(12)
                        
                        // Statistiques par paquet
                        VStack(alignment: .leading) {
                            Text("Paquets les plus étudiés")
                                .font(.headline)
                            
                            ForEach(getTopDecks()) { deck in
                                deckStatsRow(deck: deck)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.textBackgroundColor).opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Statistiques")
        .onAppear {
            if deckViewModel.decks.isEmpty {
                deckViewModel.loadDecks()
            }
        }
    }
    
    private var iOSLayout: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Période", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Statistiques globales
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
                        statsCard(
                            title: "Cartes étudiées",
                            value: "\(getTotalCardsStudied())",
                            icon: "rectangle.stack",
                            color: .blue
                        )
                        
                        statsCard(
                            title: "Sessions",
                            value: "\(getTotalSessions())",
                            icon: "calendar",
                            color: .green
                        )
                    }
                    
                    HStack(spacing: 15) {
                        statsCard(
                            title: "Taux de réussite",
                            value: "\(getSuccessRate())%",
                            icon: "chart.bar",
                            color: .orange
                        )
                        
                        statsCard(
                            title: "Temps d'étude",
                            value: getFormattedStudyTime(),
                            icon: "clock",
                            color: .purple
                        )
                    }
                }
                .padding(.horizontal)
                
                Picker("Détails", selection: $selectedStatType) {
                    ForEach(StatType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Graphique principal
                VStack(alignment: .leading) {
                    Text("Progression")
                        .font(.headline)
                        .padding(.leading)
                    
                    mainStatsChart
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Sélection de paquet
                Picker("Paquet", selection: $selectedDeckId) {
                    Text("Tous les paquets").tag(nil as UUID?)
                    ForEach(deckViewModel.decks) { deck in
                        Text(deck.name).tag(deck.id as UUID?)
                    }
                }
                .pickerStyle(.wheel)
                .padding(.vertical)
                
                // Statistiques détaillées
                VStack(alignment: .leading, spacing: 20) {
                    // Statistiques par niveau de maîtrise
                    Text("Répartition par niveau")
                        .font(.headline)
                        .padding(.leading)
                    
                    ForEach(MasteryLevel.allCases) { level in
                        masteryLevelRow(level: level)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Statistiques par paquet
                VStack(alignment: .leading, spacing: 15) {
                    Text("Paquets les plus étudiés")
                        .font(.headline)
                        .padding(.leading)
                    
                    ForEach(getTopDecks()) { deck in
                        deckStatsRow(deck: deck)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Statistiques")
        .onAppear {
            if deckViewModel.decks.isEmpty {
                deckViewModel.loadDecks()
            }
        }
    }
    
    // MARK: - Subviews
    
    private func statsCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.textBackgroundColor).opacity(0.05))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
    
    private var mainStatsChart: some View {
        // Simuler un graphique avec des barres
        VStack(spacing: 8) {
            ForEach(getChartData(), id: \.label) { data in
                HStack {
                    Text(data.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: CGFloat(data.successCount) / CGFloat(data.maxValue) * geometry.size.width * 0.9, height: 20)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red)
                                .frame(width: CGFloat(data.failureCount) / CGFloat(data.maxValue) * geometry.size.width * 0.9, height: 20)
                        }
                    }
                    .frame(height: 20)
                    
                    Text("\(data.successCount + data.failureCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
            
            // Légende
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                
                Text("Réussites")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .padding(.leading)
                
                Text("Échecs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.top, 8)
        }
    }
    
    private func masteryLevelRow(level: MasteryLevel) -> some View {
        HStack {
            MasteryLevelBadge(level: level)
            
            Text("\(getCardsCount(forLevel: level))")
                .font(.headline)
            
            Spacer()
            
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(level.color.opacity(0.3))
                    .frame(width: CGFloat(getCardsCount(forLevel: level)) / CGFloat(max(1, getTotalCards())) * geometry.size.width, height: 8)
            }
            .frame(height: 8)
            
            Text("\(getPercent(level: level))%")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    private func deckStatsRow(deck: Deck) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(deck.colorName).opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: deck.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(deck.colorName))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(deck.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(getDeckCardsStudied(deck: deck)) cartes étudiées")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(getDeckSuccessRate(deck: deck))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("de réussite")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Methods
    
    private func getTotalCardsStudied() -> Int {
        // Simplification pour l'exemple
        return 158
    }
    
    private func getTotalSessions() -> Int {
        // Simplification pour l'exemple
        return 23
    }
    
    private func getSuccessRate() -> Int {
        // Simplification pour l'exemple
        return 78
    }
    
    private func getFormattedStudyTime() -> String {
        // Simplification pour l'exemple
        return "12h 34m"
    }
    
    private func getChartData() -> [(label: String, successCount: Int, failureCount: Int, maxValue: Int)] {
        // Données simulées pour le graphique
        let data: [(label: String, successCount: Int, failureCount: Int)] = [
            ("Lun", 12, 3),
            ("Mar", 15, 4),
            ("Mer", 8, 2),
            ("Jeu", 20, 5),
            ("Ven", 10, 2),
            ("Sam", 5, 1),
            ("Dim", 18, 3)
        ]
        
        let maxValue = data.map { $0.successCount + $0.failureCount }.max() ?? 1
        
        return data.map { ($0.label, $0.successCount, $0.failureCount, maxValue) }
    }
    
    private func getCardsCount(forLevel level: MasteryLevel) -> Int {
        // Simuler des données
        switch level {
        case .new:
            return 45
        case .learning:
            return 32
        case .reviewing:
            return 68
        case .mastered:
            return 87
        }
    }
    
    private func getTotalCards() -> Int {
        return MasteryLevel.allCases.reduce(0) { $0 + getCardsCount(forLevel: $1) }
    }
    
    private func getPercent(level: MasteryLevel) -> Int {
        let total = getTotalCards()
        guard total > 0 else { return 0 }
        return Int((Double(getCardsCount(forLevel: level)) / Double(total) * 100).rounded())
    }
    
    private func getTopDecks() -> [Deck] {
        // Pour l'exemple, on retourne simplement les premiers paquets disponibles
        return Array(deckViewModel.decks.prefix(5))
    }
    
    private func getDeckCardsStudied(deck: Deck) -> Int {
        // Simuler des données
        return Int.random(in: 10...50)
    }
    
    private func getDeckSuccessRate(deck: Deck) -> String {
        // Simuler des données
        return "\(Int.random(in: 60...95))%"
    }
}

// MARK: - Supporting Types

enum StatsPeriod: String, CaseIterable, Identifiable {
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"
    case allTime = "all_time"
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .day:
            return "Jour"
        case .week:
            return "Semaine"
        case .month:
            return "Mois"
        case .year:
            return "Année"
        case .allTime:
            return "Tout"
        }
    }
}

enum StatType: String, CaseIterable, Identifiable {
    case cards = "cards"
    case time = "time"
    case success = "success"
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .cards:
            return "Cartes"
        case .time:
            return "Temps"
        case .success:
            return "Réussite"
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .environmentObject(DeckViewModel.preview)
            .environmentObject(CardViewModel.preview)
    }
} 