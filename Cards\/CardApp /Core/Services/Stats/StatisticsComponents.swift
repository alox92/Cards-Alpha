import SwiftUI

/**
 Composants de visualisation des statistiques
 
 Ce fichier contient les composants d'interface utilisateur pour la visualisation
 des statistiques d'apprentissage et des données d'étude.
 */

// MARK: - Indicateur de Progression Circulaire

/// Indicateur de progression circulaire animé
struct CircularProgressIndicator: View {
    let value: Double // 0.0 - 1.0
    var color: Color = .blue
    var lineWidth: CGFloat = 8
    var showText: Bool = true
    var subtitle: String? = nil
    
    private var percentage: Int {
        Int(value * 100)
    }
    
    var body: some View {
        ZStack {
            // Cercle de fond
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Arc de progression
            Circle()
                .trim(from: 0, to: CGFloat(value))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: value)
            
            // Texte de pourcentage
            if showText {
                VStack(spacing: 4) {
                    Text("\(percentage)%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Barre de Progression Statistique

/// Barre horizontale de progression avec titre et valeur
struct StatProgressBar: View {
    let title: String
    let value: Double // 0.0 - 1.0
    let total: Int
    var color: Color = .blue
    var height: CGFloat = 10
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(value * Double(total))) / \(total)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ZStack(alignment: .leading) {
                // Fond
                Rectangle()
                    .fill(color.opacity(0.2))
                    .cornerRadius(height / 2)
                
                // Barre de progression
                Rectangle()
                    .fill(color)
                    .cornerRadius(height / 2)
                    .frame(width: max(CGFloat(value) * 300, 0))
            }
            .frame(height: height)
        }
    }
}

// MARK: - Carte de Statistique

/// Carte pour afficher une statistique importante
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .blue
    var trend: Trend? = nil
    
    enum Trend {
        case up(Double)   // augmentation (%)
        case down(Double) // diminution (%)
        case neutral      // stable
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "arrow.right"
            }
        }
        
        var text: String {
            switch self {
            case .up(let value): return "+\(String(format: "%.1f", value))%"
            case .down(let value): return "-\(String(format: "%.1f", value))%"
            case .neutral: return "0%"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                        
                        Text(trend.text)
                            .font(.caption)
                    }
                    .foregroundColor(trend.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(trend.color.opacity(0.1))
                    .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Graphique en Bâtons Simple

/// Graphique en bâtons simple pour visualiser des données
struct SimpleBarChart: View {
    struct DataPoint: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let color: Color
    }
    
    let dataPoints: [DataPoint]
    var title: String? = nil
    var maxValue: Double? = nil
    var showValues: Bool = true
    
    private var normalizedDataPoints: [DataPoint] {
        let max = maxValue ?? (dataPoints.map { $0.value }.max() ?? 1.0)
        return dataPoints.map { DataPoint(label: $0.label, value: $0.value / max, color: $0.color) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 4)
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(normalizedDataPoints) { point in
                    VStack {
                        if showValues {
                            Text("\(Int(point.value * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Rectangle()
                            .fill(point.color)
                            .frame(height: max(20, 100 * CGFloat(point.value)))
                            .cornerRadius(6)
                        
                        Text(point.label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(height: 120)
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Graphique Temporel

/// Graphique linéaire pour visualiser des données temporelles
struct TimelineChart: View {
    struct TimelineDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM"
            return formatter.string(from: date)
        }
    }
    
    let dataPoints: [TimelineDataPoint]
    var title: String? = nil
    var color: Color = .blue
    var showValues: Bool = true
    
    private var normalizedDataPoints: [TimelineDataPoint] {
        let maxValue = dataPoints.map { $0.value }.max() ?? 1.0
        return dataPoints.map { TimelineDataPoint(date: $0.date, value: $0.value / maxValue) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 4)
            }
            
            if dataPoints.isEmpty {
                Text("Aucune donnée disponible")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .frame(height: 120)
            } else {
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        // Lignes de grille
                        VStack(spacing: 0) {
                            ForEach(0..<5) { i in
                                Divider()
                                Spacer()
                                    .frame(height: i < 4 ? geometry.size.height / 4 : 0)
                            }
                        }
                        
                        // Ligne de tendance
                        Path { path in
                            guard !normalizedDataPoints.isEmpty else { return }
                            
                            let pointWidth = geometry.size.width / CGFloat(normalizedDataPoints.count - 1)
                            
                            // Tracer la ligne
                            path.move(to: CGPoint(
                                x: 0,
                                y: geometry.size.height * (1 - CGFloat(normalizedDataPoints.first?.value ?? 0))
                            ))
                            
                            for (index, point) in normalizedDataPoints.dropFirst().enumerated() {
                                path.addLine(to: CGPoint(
                                    x: CGFloat(index + 1) * pointWidth,
                                    y: geometry.size.height * (1 - CGFloat(point.value))
                                ))
                            }
                        }
                        .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        
                        // Points de données
                        HStack(spacing: 0) {
                            ForEach(0..<normalizedDataPoints.count, id: \.self) { index in
                                Circle()
                                    .fill(color)
                                    .frame(width: 6, height: 6)
                                    .position(x: geometry.size.width * CGFloat(index) / CGFloat(normalizedDataPoints.count - 1),
                                              y: geometry.size.height * (1 - CGFloat(normalizedDataPoints[index].value)))
                                    .overlay(
                                        VStack {
                                            if showValues {
                                                Text("\(Int(dataPoints[index].value))")
                                                    .font(.caption2)
                                                    .padding(4)
                                                    .background(Color.white.opacity(0.8))
                                                    .cornerRadius(4)
                                                    .offset(y: -20)
                                                    .opacity(0) // Par défaut invisible
                                            }
                                        }
                                    )
                            }
                        }
                    }
                }
                .frame(height: 120)
                .overlay(
                    VStack {
                        Spacer()
                        HStack(spacing: 0) {
                            ForEach(0..<min(normalizedDataPoints.count, 7), id: \.self) { index in
                                let step = normalizedDataPoints.count / min(normalizedDataPoints.count, 7)
                                if index * step < normalizedDataPoints.count {
                                    Text(normalizedDataPoints[index * step].formattedDate)
                                        .font(.caption2)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Carte de Recommandation d'Étude

/// Carte de recommandation pour l'étude
struct StudyRecommendationCard: View {
    let title: String
    let description: String
    var icon: String = "lightbulb.fill"
    var color: Color = .blue
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            // Texte
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Bouton d'action
            if let actionLabel = actionLabel, let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(color)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Étiquette de Productivité

/// Indicateur de productivité d'une période
struct ProductivityBadge: View {
    let hourOfDay: Int
    let productivityLevel: Double // 0.0 - 1.0
    var selected: Bool = false
    
    private var formattedHour: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hourOfDay
        
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        
        return "\(hourOfDay):00"
    }
    
    private var color: Color {
        if productivityLevel > 0.7 {
            return .green
        } else if productivityLevel > 0.4 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(formattedHour)
                .font(.caption)
                .foregroundColor(selected ? .white : .primary)
            
            Text("\(Int(productivityLevel * 100))%")
                .font(.caption2)
                .foregroundColor(selected ? .white.opacity(0.9) : color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(selected ? color : color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Résumé de Statistiques

/// Vue de résumé des statistiques
struct StatisticsSummaryView: View {
    let totalCards: Int
    let masteredCards: Int
    let dueCards: Int
    let averageSuccessRate: Double
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Cartes maîtrisées
                StatisticCard(
                    title: "Cartes maîtrisées",
                    value: "\(masteredCards)",
                    icon: "checkmark.seal.fill",
                    color: .green,
                    trend: .up(5.2)
                )
                
                // Cartes à réviser
                StatisticCard(
                    title: "À réviser aujourd'hui",
                    value: "\(dueCards)",
                    icon: "clock.fill",
                    color: .orange
                )
            }
            
            HStack(spacing: 20) {
                // Total de cartes
                StatisticCard(
                    title: "Total de cartes",
                    value: "\(totalCards)",
                    icon: "square.stack.3d.up.fill",
                    color: .blue
                )
                
                // Taux de réussite
                StatisticCard(
                    title: "Taux de réussite",
                    value: "\(Int(averageSuccessRate))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple,
                    trend: .up(3.8)
                )
            }
        }
    }
}

// MARK: - Prévisualisations

struct StatisticsComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Indicateur de progression circulaire
                CircularProgressIndicator(value: 0.75, color: .green, subtitle: "Maîtrisé")
                    .frame(width: 100, height: 100)
                    .previewDisplayName("Indicateur Circulaire")
                
                // Barre de progression
                StatProgressBar(title: "Progrès d'apprentissage", value: 0.65, total: 100, color: .blue)
                    .frame(maxWidth: 300)
                    .previewDisplayName("Barre de Progression")
                
                // Carte de statistique
                StatisticCard(
                    title: "Cartes maîtrisées",
                    value: "42",
                    icon: "checkmark.seal.fill",
                    color: .green,
                    trend: .up(5.2)
                )
                .frame(width: 200)
                .previewDisplayName("Carte de Statistique")
                
                // Graphique en bâtons
                SimpleBarChart(
                    dataPoints: [
                        SimpleBarChart.DataPoint(label: "Lun", value: 10, color: .blue),
                        SimpleBarChart.DataPoint(label: "Mar", value: 25, color: .blue),
                        SimpleBarChart.DataPoint(label: "Mer", value: 15, color: .blue),
                        SimpleBarChart.DataPoint(label: "Jeu", value: 30, color: .blue),
                        SimpleBarChart.DataPoint(label: "Ven", value: 20, color: .blue)
                    ],
                    title: "Cartes étudiées par jour"
                )
                .frame(height: 180)
                .previewDisplayName("Graphique en Bâtons")
                
                // Graphique temporel
                TimelineChart(
                    dataPoints: [
                        TimelineChart.TimelineDataPoint(date: Date().addingTimeInterval(-6*86400), value: 5),
                        TimelineChart.TimelineDataPoint(date: Date().addingTimeInterval(-5*86400), value: 12),
                        TimelineChart.TimelineDataPoint(date: Date().addingTimeInterval(-4*86400), value: 8),
                        TimelineChart.TimelineDataPoint(date: Date().addingTimeInterval(-3*86400), value: 15),
                        TimelineChart.TimelineDataPoint(date: Date().addingTimeInterval(-2*86400), value: 10),
                        TimelineChart.TimelineDataPoint(date: Date().addingTimeInterval(-1*86400), value: 22),
                        TimelineChart.TimelineDataPoint(date: Date(), value: 18)
                    ],
                    title: "Progression sur 7 jours",
                    color: .green
                )
                .frame(height: 180)
                .previewDisplayName("Graphique Temporel")
                
                // Étiquettes de productivité
                HStack {
                    ForEach(8..<13) { hour in
                        ProductivityBadge(
                            hourOfDay: hour,
                            productivityLevel: Double.random(in: 0.3...0.9),
                            selected: hour == 10
                        )
                    }
                }
                .previewDisplayName("Badges de Productivité")
                
                // Carte de recommandation
                StudyRecommendationCard(
                    title: "Réviser aujourd'hui",
                    description: "Vous avez 15 cartes à réviser pour maintenir votre progression",
                    icon: "arrow.clockwise",
                    color: .orange,
                    actionLabel: "Étudier",
                    action: {}
                )
                .frame(maxWidth: 400)
                .previewDisplayName("Carte de Recommandation")
                
                // Résumé des statistiques
                StatisticsSummaryView(
                    totalCards: 120,
                    masteredCards: 72,
                    dueCards: 15,
                    averageSuccessRate: 85
                )
                .frame(maxWidth: 500)
                .previewDisplayName("Résumé des Statistiques")
            }
            .padding()
        }
    }
} 