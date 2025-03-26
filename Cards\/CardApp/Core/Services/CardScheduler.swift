import Foundation
import CoreData
import SwiftUI

/// Service responsable de la planification des révisions des cartes
class CardScheduler {
    // MARK: - Properties
    // Intervalles de base pour chaque niveau (en jours)
    private let baseIntervals: [MasteryLevel: Double] = [
        .new: 1,
        .learning: 3,
        .reviewing: 7,
        .mastered: 14
    ]
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Public Methods
    /// Calcule la prochaine date de révision
    func calculateNextReview(currentLevel: MasteryLevel, rating: ReviewRating, lastReview: Date) -> Date {
        let baseInterval = baseIntervals[currentLevel] ?? 1.0
        let intervalMultiplier = rating.intervalMultiplier
        let intervalDays = baseInterval * intervalMultiplier
        
        // Si la réponse était "again", prévoir une révision plus rapprochée
        if rating == .again {
            return Date().addingTimeInterval(60 * 10) // 10 minutes
        }
        
        let intervalSeconds = max(0.25, intervalDays) * 24 * 60 * 60 // Au moins 6 heures
        return Date().addingTimeInterval(intervalSeconds)
    }
    
    /// Calcule le nouveau niveau de maîtrise
    func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel {
        switch rating {
        case .again:
            // Régresser d'un niveau si c'est un échec, mais pas en dessous de new
            if currentLevel == .learning {
                return .new
            } else if currentLevel == .reviewing {
                return .learning
            } else if currentLevel == .mastered {
                return .reviewing
            }
            return .new
            
        case .hard:
            // Conserver le niveau actuel
            return currentLevel
            
        case .good:
            // Progresser d'un niveau si c'est une bonne réponse
            if currentLevel == .new {
                return .learning
            } else if currentLevel == .learning {
                return .reviewing
            } else if currentLevel == .reviewing {
                return .mastered
            }
            return currentLevel
            
        case .easy:
            // Progresser potentiellement de deux niveaux si c'est une réponse facile
            if currentLevel == .new {
                return .reviewing
            } else if currentLevel == .learning || currentLevel == .reviewing {
                return .mastered
            }
            return .mastered
        }
    }
}

// MARK: - Preview
extension CardScheduler {
    static var preview: CardScheduler {
        CardScheduler(context: PersistenceController.preview.container.viewContext)
    }
}

// MARK: - Review Rating
enum ReviewRating: Int, CaseIterable, Identifiable {
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
        case .again: return 0.5
        case .hard: return 0.8
        case .good: return 1.0
        case .easy: return 1.5
        }
    }
} 