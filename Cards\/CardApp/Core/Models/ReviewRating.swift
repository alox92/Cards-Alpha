import SwiftUI

enum ReviewRating: Int, CaseIterable, Identifiable {
    case again = 0
    case hard = 1
    case good = 2
    case easy = 3
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .again:
            return "Encore"
        case .hard:
            return "Difficile"
        case .good:
            return "Correct"
        case .easy:
            return "Facile"
        }
    }
    
    var color: Color {
        switch self {
        case .again:
            return .red
        case .hard:
            return .orange
        case .good:
            return .blue
        case .easy:
            return .green
        }
    }
    
    var isCorrect: Bool {
        self != .again
    }
    
    var keyboardShortcut: String {
        switch self {
        case .again:
            return "1"
        case .hard:
            return "2"
        case .good:
            return "3"
        case .easy:
            return "4"
        }
    }
    
    var interval: TimeInterval {
        switch self {
        case .again:
            return 60 * 5 // 5 minutes
        case .hard:
            return 60 * 60 * 24 // 1 jour
        case .good:
            return 60 * 60 * 24 * 3 // 3 jours
        case .easy:
            return 60 * 60 * 24 * 7 // 7 jours
        }
    }
} 