import Foundation
import CoreData
import SwiftUI

// MARK: - Card Model
struct Card: Identifiable, Hashable, Codable {
    let id: UUID
    let question: String
    let answer: String
    let additionalInfo: String?
    let deckID: UUID?
    let createdAt: Date
    let updatedAt: Date
    let masteryLevel: MasteryLevel
    let reviewCount: Int
    let lastReviewedAt: Date?
    let nextReviewDate: Date?
    let tags: [String]
    let isFlagged: Bool
    let correctCount: Int
    let incorrectCount: Int
    
    // MARK: - Initialization
    init(id: UUID = UUID(),
         question: String,
         answer: String,
         additionalInfo: String? = nil,
         deckID: UUID? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         masteryLevel: MasteryLevel = .new,
         reviewCount: Int = 0,
         lastReviewedAt: Date? = nil,
         nextReviewDate: Date? = nil,
         tags: [String] = [],
         isFlagged: Bool = false,
         correctCount: Int = 0,
         incorrectCount: Int = 0) {
        self.id = id
        self.question = question
        self.answer = answer
        self.additionalInfo = additionalInfo
        self.deckID = deckID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.masteryLevel = masteryLevel
        self.reviewCount = reviewCount
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewDate = nextReviewDate
        self.tags = tags
        self.isFlagged = isFlagged
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
    }
    
    // MARK: - Computed Properties
    
    /// Checks if the card is due for review
    var isDue: Bool {
        guard let nextReviewDate = nextReviewDate else {
            // If no next review date is set, new cards are always due
            return masteryLevel == .new
        }
        return nextReviewDate <= Date()
    }
    
    /// Vérifie si la carte est nouvelle
    var isNew: Bool {
        return masteryLevel == .new
    }
    
    /// Vérifie si la carte est apprise
    var isLearned: Bool {
        return masteryLevel == .mastered
    }
    
    /// Calcule la difficulté de la carte (0.0 à 1.0)
    var difficulty: Double {
        guard reviewCount > 0 else { return 0.0 }
        return Double(incorrectCount) / Double(reviewCount)
    }
    
    /// Checks if the card is due today
    var isDueToday: Bool {
        guard let nextReviewDate = nextReviewDate else {
            // If no next review date, new cards are considered due today
            return masteryLevel == .new
        }
        
        let calendar = Calendar.current
        return calendar.isDateInToday(nextReviewDate)
    }
    
    /// Checks if the card is overdue
    var isOverdue: Bool {
        guard let nextReviewDate = nextReviewDate else {
            return false
        }
        
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        return nextReviewDate <= yesterday
    }
    
    /// Returns the number of days until the next review
    var daysUntilNextReview: Int? {
        guard let nextReviewDate = nextReviewDate else {
            return nil
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let reviewDay = calendar.startOfDay(for: nextReviewDate)
        
        let components = calendar.dateComponents([.day], from: today, to: reviewDay)
        return components.day
    }
    
    var formattedLastReviewed: String {
        guard let date = lastReviewedAt else { return "Jamais" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Mutating Methods
    mutating func updateReviewStats(correct: Bool) {
        reviewCount += 1
        lastReviewedAt = Date()
    }
    
    mutating func updateMasteryLevel(_ level: MasteryLevel) {
        masteryLevel = level
    }
    
    mutating func updateNextReviewDate(_ date: Date) {
        nextReviewDate = date
    }
    
    // MARK: - Methods pour le système de révision
    
    func withUpdatedReview(rating: ReviewRating) -> Card {
        var updatedCard = self
        let isCorrect = rating == .good || rating == .easy
        
        updatedCard.reviewCount += 1
        if isCorrect {
            updatedCard.correctCount += 1
        } else {
            updatedCard.incorrectCount += 1
        }
        
        return updatedCard
    }
    
    // MARK: - CoreData Integration
    static func from(_ entity: CardEntity) -> Card {
        Card(
            id: entity.id ?? UUID(),
            question: entity.question ?? "",
            answer: entity.answer ?? "",
            additionalInfo: entity.additionalInfo,
            deckID: entity.deck?.id,
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date(),
            masteryLevel: MasteryLevel(rawValue: entity.masteryLevel ?? "") ?? .new,
            reviewCount: Int(entity.reviewCount),
            lastReviewedAt: entity.lastReviewedAt,
            nextReviewDate: entity.nextReviewDate,
            tags: entity.tags?.components(separatedBy: ",") ?? [],
            isFlagged: entity.isFlagged,
            correctCount: Int(entity.correctCount),
            incorrectCount: Int(entity.incorrectCount)
        )
    }
    
    func toEntity(in context: NSManagedObjectContext) -> CardEntity {
        let entity = CardEntity(context: context)
        entity.id = id
        entity.question = question
        entity.answer = answer
        entity.additionalInfo = additionalInfo
        entity.createdAt = createdAt
        entity.updatedAt = updatedAt
        entity.masteryLevel = masteryLevel.rawValue
        entity.reviewCount = Int16(reviewCount)
        entity.lastReviewedAt = lastReviewedAt
        entity.nextReviewDate = nextReviewDate
        entity.tags = tags.joined(separator: ",")
        entity.isFlagged = isFlagged
        entity.correctCount = Int16(correctCount)
        entity.incorrectCount = Int16(incorrectCount)
        
        if let deckID = deckID {
            let fetchRequest = NSFetchRequest<DeckEntity>(entityName: "DeckEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", deckID as CVarArg)
            fetchRequest.fetchLimit = 1
            
            if let decks = try? context.fetch(fetchRequest), let deck = decks.first {
                entity.deck = deck
            }
        }
        
        return entity
    }
}

// MARK: - Preview
extension Card {
    static var preview: Card {
        Card(
            question: "Question d'exemple",
            answer: "Réponse d'exemple",
            lastReviewedAt: Date().addingTimeInterval(-86400),
            reviewCount: 5,
            masteryLevel: .learning
        )
    }
}

// MARK: - Mastery Level Enum
enum MasteryLevel: String, Codable, CaseIterable, Identifiable {
    case new = "new"
    case learning = "learning"
    case reviewing = "reviewing"
    case mastered = "mastered"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .new:
            return "Nouvelle"
        case .learning:
            return "En apprentissage"
        case .reviewing:
            return "À réviser"
        case .mastered:
            return "Maîtrisée"
        }
    }
    
    var icon: String {
        switch self {
        case .new:
            return "star"
        case .learning:
            return "brain.head.profile"
        case .reviewing:
            return "arrow.clockwise"
        case .mastered:
            return "checkmark.seal.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .new:
            return .blue
        case .learning:
            return .orange
        case .reviewing:
            return .red
        case .mastered:
            return .green
        }
    }
    
    var description: String {
        switch self {
        case .new:
            return "Carte jamais étudiée"
        case .learning:
            return "En cours d'apprentissage"
        case .reviewing:
            return "Nécessite une révision"
        case .mastered:
            return "Bien maîtrisée"
        }
    }
    
    var nextReviewInterval: TimeInterval {
        switch self {
        case .new: 
            return 24 * 3600 // 1 jour
        case .learning: 
            return 3 * 24 * 3600 // 3 jours
        case .reviewing: 
            return 7 * 24 * 3600 // 1 semaine
        case .mastered: 
            return 14 * 24 * 3600 // 2 semaines
        }
    }
}

// MARK: - Card Filter Options
enum CardFilterOption: Codable, Equatable, Identifiable {
    case all
    case new
    case learning
    case reviewing
    case mastered
    case due
    case needsReview
    case failed
    case custom(String)
    
    var id: String {
        switch self {
        case .all, .new, .learning, .reviewing, .mastered, .due, .needsReview, .failed:
            return String(describing: self)
        case .custom(let name):
            return "custom_\(name)"
        }
    }
    
    static var allCases: [CardFilterOption] {
        [.all, .new, .learning, .reviewing, .mastered, .due, .needsReview, .failed]
    }
    
    var displayName: String {
        switch self {
        case .all:
            return "Toutes les cartes"
        case .new:
            return "Nouvelles cartes"
        case .learning:
            return "En apprentissage"
        case .reviewing:
            return "En révision"
        case .mastered:
            return "Maîtrisées"
        case .due:
            return "À réviser aujourd'hui"
        case .needsReview:
            return "À revoir"
        case .failed:
            return "Échouées"
        case .custom(let name):
            return name
        }
    }
    
    var systemImage: String {
        switch self {
        case .all:
            return "rectangle.stack.fill"
        case .new:
            return "sparkles"
        case .mastered:
            return "checkmark.circle.fill"
        case .learning:
            return "brain"
        case .reviewing:
            return "arrow.clockwise"
        case .due:
            return "calendar"
        case .needsReview:
            return "exclamationmark.circle"
        case .failed:
            return "xmark.circle.fill"
        case .custom:
            return "tag"
        }
    }
}

// MARK: - Review Rating
enum ReviewRating: Int, CaseIterable, Identifiable, Codable {
    case again = 0
    case hard = 1
    case good = 2
    case easy = 3
    
    var id: Int { self.rawValue }
    
    var isCorrect: Bool {
        self != .again
    }
    
    var displayName: String {
        switch self {
        case .again: return "À revoir"
        case .hard: return "Difficile"
        case .good: return "Bien"
        case .easy: return "Facile"
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
    
    var intervalMultiplier: Double {
        switch self {
        case .again: return 0.5   // Réduire l'intervalle de moitié
        case .hard: return 0.8    // Légèrement réduit
        case .good: return 1.0    // Intervalle standard
        case .easy: return 1.5    // Augmenter de 50%
        }
    }
    
    var description: String {
        switch self {
        case .again:
            return "Vous ne vous souvenez pas de cette carte et devez la réviser bientôt."
        case .hard:
            return "Vous vous en souvenez mais avec difficulté."
        case .good:
            return "Vous vous en souvenez correctement avec un effort modéré."
        case .easy:
            return "Vous vous en souvenez parfaitement sans effort."
        }
    }
}

// MARK: - Card Study Extensions
extension Card {
    var isDue: Bool {
        guard let nextReview = nextReview else {
            // Nouvelle carte, jamais révisée
            return true
        }
        return nextReview <= Date()
    }
    
    func withUpdatedReview(rating: ReviewRating) -> Card {
        var updatedCard = self
        
        // Mettre à jour la date de dernière révision
        updatedCard.lastReviewed = Date()
        
        // Ajuster le niveau de maîtrise
        switch rating {
        case .again:
            // Régresser le niveau de maîtrise si la réponse était incorrecte
            if updatedCard.masteryLevel != .new {
                updatedCard.masteryLevel = updatedCard.masteryLevel.previousLevel ?? .new
            }
        case .hard:
            // Maintenir le niveau actuel
            break
        case .good, .easy:
            // Avancer au niveau suivant si possible
            if let nextLevel = updatedCard.masteryLevel.nextLevel {
                updatedCard.masteryLevel = nextLevel
            }
        }
        
        // Calculer la nouvelle date de révision
        let baseInterval: TimeInterval
        switch updatedCard.masteryLevel {
        case .new:
            baseInterval = 60 * 60 * 24 // 1 jour
        case .learning:
            baseInterval = 60 * 60 * 24 * 3 // 3 jours
        case .familiar:
            baseInterval = 60 * 60 * 24 * 7 // 1 semaine
        case .mastered:
            baseInterval = 60 * 60 * 24 * 14 // 2 semaines
        }
        
        // Appliquer le multiplicateur basé sur la notation
        let intervalMultiplier = rating.intervalMultiplier
        let newInterval = baseInterval * intervalMultiplier
        
        // Si la réponse était "again", prévoir une révision plus rapprochée
        if rating == .again {
            updatedCard.nextReview = Date().addingTimeInterval(60 * 10) // 10 minutes
        } else {
            updatedCard.nextReview = Date().addingTimeInterval(newInterval)
        }
        
        return updatedCard
    }
}

// MARK: - Array Extensions
extension Array where Element == Card {
    func filterByOption(_ option: CardFilterOption) -> [Card] {
        switch option {
        case .all:
            return self
        case .new:
            return filter { $0.masteryLevel == .new }
        case .learning:
            return filter { $0.masteryLevel == .learning }
        case .reviewing:
            return filter { $0.masteryLevel == .reviewing }
        case .mastered:
            return filter { $0.masteryLevel == .mastered }
        case .dueToday:
            return filter { $0.isDueToday }
        case .overdue:
            return filter { $0.isOverdue }
        }
    }
    
    func filterBySearchTerm(_ searchText: String) -> [Card] {
        guard !searchText.isEmpty else { return self }
        
        return filter { card in
            card.question.localizedCaseInsensitiveContains(searchText) ||
            card.answer.localizedCaseInsensitiveContains(searchText) ||
            (card.additionalInfo ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Sample Data
extension Card {
    static var sampleData: [Card] {
        [
            Card(
                question: "Qu'est-ce que Swift?",
                answer: "Swift est un langage de programmation développé par Apple pour iOS, macOS, watchOS et tvOS.",
                additionalInfo: "Swift a été introduit en 2014 et est devenu open source en 2015.",
                masteryLevel: .new
            ),
            Card(
                question: "Quelle est la différence entre une structure et une classe en Swift?",
                answer: "Les structures sont des types valeur tandis que les classes sont des types référence.",
                additionalInfo: "Les structures sont copiées lors de l'assignation, tandis que les classes sont passées par référence.",
                masteryLevel: .learning,
                reviewCount: 2,
                lastReviewedAt: Date().addingTimeInterval(-86400)
            ),
            Card(
                question: "Qu'est-ce que SwiftUI?",
                answer: "SwiftUI est un framework déclaratif pour construire des interfaces utilisateur sur toutes les plateformes Apple.",
                masteryLevel: .reviewing,
                reviewCount: 5,
                lastReviewedAt: Date().addingTimeInterval(-172800)
            ),
            Card(
                question: "Qu'est-ce qu'un optional en Swift?",
                answer: "Un optional est un type qui peut contenir soit une valeur, soit nil (absence de valeur).",
                masteryLevel: .mastered,
                reviewCount: 10,
                lastReviewedAt: Date().addingTimeInterval(-604800)
            ),
            Card(
                question: "Comment déclarer une constante en Swift?",
                answer: "Utilisez le mot-clé 'let' suivi du nom et de la valeur: let constante = valeur",
                masteryLevel: .new
            )
        ]
    }
} 