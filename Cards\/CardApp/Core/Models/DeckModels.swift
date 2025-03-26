import Foundation
import SwiftUI
import CoreData

// MARK: - Deck Model
struct Deck: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let colorName: String
    let createdAt: Date
    let updatedAt: Date
    
    // Statistiques calculées
    var totalCards: Int = 0
    var newCards: Int = 0
    var learningCards: Int = 0
    var reviewingCards: Int = 0
    var masteredCards: Int = 0
    var dueCards: Int = 0
    
    // MARK: - Initialization
    init(id: UUID = UUID(),
         name: String,
         description: String = "",
         icon: String = "rectangle.stack",
         colorName: String = "blue",
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.colorName = colorName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    var color: Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
    
    var progressPercentage: Double {
        guard totalCards > 0 else { return 0 }
        return Double(masteredCards) / Double(totalCards) * 100
    }
    
    // MARK: - CoreData Integration
    static func from(_ entity: DeckEntity) -> Deck {
        var cardCount = 0
        var dueCardCount = 0
        
        if let cardEntities = entity.cards as? Set<CardEntity> {
            cardCount = cardEntities.count
            
            let now = Date()
            dueCardCount = cardEntities.filter { entity in
                if let nextReview = entity.nextReviewDate {
                    return nextReview <= now
                } else {
                    return entity.masteryLevel == "new"
                }
            }.count
        }
        
        return Deck(
            id: entity.id,
            name: entity.name ?? "Sans titre",
            description: entity.description ?? "",
            icon: entity.icon ?? "rectangle.stack",
            colorName: entity.colorName ?? "blue",
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
    
    func toEntity(in context: NSManagedObjectContext) -> DeckEntity {
        let entity = DeckEntity(context: context)
        entity.id = id
        entity.name = name
        entity.description = description
        entity.icon = icon
        entity.colorName = colorName
        entity.createdAt = createdAt
        entity.updatedAt = updatedAt
        
        return entity
    }
    
    // MARK: - Sample Data
    static var sampleData: [Deck] = [
        Deck(
            id: UUID(),
            name: "Swift",
            description: "Concepts fondamentaux du langage Swift",
            icon: "swift",
            colorName: "orange"
        ),
        Deck(
            id: UUID(),
            name: "SwiftUI",
            description: "Apprendre à créer des interfaces avec SwiftUI",
            icon: "macwindow",
            colorName: "blue"
        )
    ]
}

// MARK: - Import/Export
struct DeckExport: Codable {
    let name: String
    let description: String
    let cards: [CardExport]
    let createdAt: Date
    
    struct CardExport: Codable {
        let question: String
        let answer: String
        let additionalInfo: String?
        let tags: [String]
    }
}

// MARK: - Deck Sort Options
enum DeckSortOption: String, CaseIterable, Identifiable {
    case alphabetical
    case dateCreated
    case dateModified
    case cardCount
    case dueCardCount
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .alphabetical:
            return "Alphabétique"
        case .dateCreated:
            return "Date de création"
        case .dateModified:
            return "Dernière modification"
        case .cardCount:
            return "Nombre de cartes"
        case .dueCardCount:
            return "Cartes à réviser"
        }
    }
    
    var systemImage: String {
        switch self {
        case .alphabetical:
            return "textformat.abc"
        case .dateCreated:
            return "calendar.badge.plus"
        case .dateModified:
            return "calendar.badge.clock"
        case .cardCount:
            return "number"
        case .dueCardCount:
            return "timer"
        }
    }
} 