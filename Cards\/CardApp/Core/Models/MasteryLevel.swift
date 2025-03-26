import Foundation
import SwiftUI

/// Représente le niveau de maîtrise d'une carte
enum MasteryLevel: String, Codable, CaseIterable {
    case new = "new"
    case learning = "learning"
    case reviewing = "reviewing"
    case mastered = "mastered"
    
    /// Titre localisé pour l'interface utilisateur
    var title: String {
        switch self {
        case .new:
            return "Nouveau"
        case .learning:
            return "En apprentissage"
        case .reviewing:
            return "En révision"
        case .mastered:
            return "Maîtrisé"
        }
    }
    
    /// Icône représentative
    var icon: String {
        switch self {
        case .new:
            return "star"
        case .learning:
            return "book"
        case .reviewing:
            return "arrow.clockwise"
        case .mastered:
            return "checkmark.seal"
        }
    }
    
    /// Couleur associée
    var color: Color {
        switch self {
        case .new:
            return .blue
        case .learning:
            return .orange
        case .reviewing:
            return .purple
        case .mastered:
            return .green
        }
    }
    
    /// Progrès d'apprentissage en pourcentage
    var progress: Double {
        switch self {
        case .new:
            return 0.0
        case .learning:
            return 0.33
        case .reviewing:
            return 0.66
        case .mastered:
            return 1.0
        }
    }
} 