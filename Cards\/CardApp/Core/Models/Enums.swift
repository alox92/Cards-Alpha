import Foundation
import SwiftUI

// MARK: - MasteryLevel
enum MasteryLevel: String, Codable, CaseIterable, Identifiable {
    case new
    case learning
    case reviewing
    case mastered
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .new: return "Nouveau"
        case .learning: return "Apprentissage"
        case .reviewing: return "Révision"
        case .mastered: return "Maîtrisé"
        }
    }
    
    var color: Color {
        switch self {
        case .new: return .blue
        case .learning: return .orange
        case .reviewing: return .purple
        case .mastered: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .new: return "sparkles"
        case .learning: return "book"
        case .reviewing: return "repeat"
        case .mastered: return "checkmark.circle"
        }
    }
}

// MARK: - Card Filter Option
enum CardFilterOption: String, CaseIterable, Identifiable {
    case all = "all"
    case due = "due"
    case new = "new"
    case learned = "learned"
    case difficult = "difficult"
    case flagged = "flagged"
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .all: return "Toutes"
        case .due: return "À réviser"
        case .new: return "Nouvelles"
        case .learned: return "Maîtrisées"
        case .difficult: return "Difficiles"
        case .flagged: return "Marquées"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "rectangle.stack"
        case .due: return "clock"
        case .new: return "sparkles"
        case .learned: return "checkmark.circle"
        case .difficult: return "exclamationmark.triangle"
        case .flagged: return "flag"
        }
    }
}

// MARK: - ReviewRating
enum ReviewRating: String, CaseIterable, Identifiable, Codable {
    case again = "again"
    case hard = "hard" 
    case good = "good"
    case easy = "easy"
    
    var id: String { rawValue }
    
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
        case .good: return .blue
        case .easy: return .green
        }
    }
    
    var intervalMultiplier: Double {
        switch self {
        case .again: return 0
        case .hard: return 1.2
        case .good: return 1.5
        case .easy: return 2.0
        }
    }
}

// MARK: - App Error
struct AppError: Error, Identifiable {
    let id = UUID()
    let message: String
    let type: AppErrorType
    
    init(message: String, type: AppErrorType = .general) {
        self.message = message
        self.type = type
    }
    
    init(error: Error) {
        self.message = error.localizedDescription
        self.type = .general
    }
    
    var title: String {
        switch type {
        case .network: return "Erreur réseau"
        case .data: return "Erreur de données"
        case .auth: return "Erreur d'authentification"
        case .general: return "Erreur"
        }
    }
    
    static func dataError(_ message: String) -> AppError {
        AppError(message: message, type: .data)
    }
    
    static func networkError(_ message: String) -> AppError {
        AppError(message: message, type: .network)
    }
}

enum AppErrorType {
    case network
    case data
    case auth
    case general
} 