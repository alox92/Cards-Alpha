import Foundation
import SwiftUI

// MARK: - Card Filter Option
public enum CardFilterOption: String, CaseIterable {
    case all = "all"
    case due = "due"
    case new = "new"
    case learned = "learned"
    case difficult = "difficult"
    case flagged = "flagged"
    
    public var displayName: String {
        switch self {
        case .all: return "Toutes"
        case .due: return "À réviser"
        case .new: return "Nouvelles"
        case .learned: return "Apprises"
        case .difficult: return "Difficiles"
        case .flagged: return "Marquées"
        }
    }
    
    public var icon: String {
        switch self {
        case .all: return "square.stack.3d.up"
        case .due: return "timer"
        case .new: return "sparkles"
        case .learned: return "checkmark.circle"
        case .difficult: return "exclamationmark.triangle"
        case .flagged: return "flag.fill"
        }
    }
}

// MARK: - Deck Sort Option
public enum DeckSortOption: String, CaseIterable {
    case name = "name"
    case dateCreated = "dateCreated"
    case dateModified = "dateModified"
    case cardCount = "cardCount"
    case dueCardCount = "dueCardCount"
    
    public var displayName: String {
        switch self {
        case .name: return "Nom"
        case .dateCreated: return "Date de création"
        case .dateModified: return "Dernière modification"
        case .cardCount: return "Nombre de cartes"
        case .dueCardCount: return "Cartes à réviser"
        }
    }
}

// MARK: - Study Mode Option
public enum StudyModeOption: String, CaseIterable {
    case spaced = "spaced"
    case quiz = "quiz"
    case shuffle = "shuffle"
    case difficult = "difficult"
    
    public var displayName: String {
        switch self {
        case .spaced: return "Révision espacée"
        case .quiz: return "Quiz"
        case .shuffle: return "Aléatoire"
        case .difficult: return "Difficiles"
        }
    }
    
    public var description: String {
        switch self {
        case .spaced: return "Utilise un algorithme de répétition espacée"
        case .quiz: return "Mode questions-réponses avec score"
        case .shuffle: return "Cartes présentées dans un ordre aléatoire"
        case .difficult: return "Focus sur les cartes difficiles"
        }
    }
    
    public var icon: String {
        switch self {
        case .spaced: return "calendar"
        case .quiz: return "gamecontroller"
        case .shuffle: return "shuffle"
        case .difficult: return "exclamationmark.triangle"
        }
    }
}

/// Type de carte
public enum CardType: String, Codable, CaseIterable {
    case basic = "basic"
    case cloze = "cloze"
    case image = "image"
    case audio = "audio"
    case video = "video"
    
    public var description: String {
        switch self {
        case .basic:
            return "Basique"
        case .cloze:
            return "À trous"
        case .image:
            return "Image"
        case .audio:
            return "Audio"
        case .video:
            return "Vidéo"
        }
    }
    
    public var icon: String {
        switch self {
        case .basic:
            return "text.alignleft"
        case .cloze:
            return "text.redaction"
        case .image:
            return "photo"
        case .audio:
            return "waveform"
        case .video:
            return "video"
        }
    }
}

// MARK: - Mastery Level
public enum MasteryLevel: Int, Codable, CaseIterable, Sendable {
    case novice = 0
    case beginner = 1
    case intermediate = 2
    case advanced = 3
    case expert = 4
    
    public var description: String {
        switch self {
        case .novice:
            return "Novice"
        case .beginner:
            return "Débutant"
        case .intermediate:
            return "Intermédiaire"
        case .advanced:
            return "Avancé"
        case .expert:
            return "Expert"
        }
    }
    
    public var icon: String {
        switch self {
        case .novice:
            return "star"
        case .beginner:
            return "star.fill"
        case .intermediate:
            return "star.circle"
        case .advanced:
            return "star.circle.fill"
        case .expert:
            return "star.square"
        }
    }
}

// MARK: - Learning State
public enum LearningState: String, Codable, CaseIterable, Sendable {
    case all = "all"
    case new = "new"
    case learning = "learning"
    case mastered = "mastered"
    case dueForReview = "dueForReview"
    
    public var description: String {
        switch self {
        case .all:
            return "Tous"
        case .new:
            return "Nouvelle"
        case .learning:
            return "En apprentissage"
        case .mastered:
            return "Maîtrisée"
        case .dueForReview:
            return "À réviser"
        }
    }
    
    public var icon: String {
        switch self {
        case .all:
            return "square.stack.3d.up"
        case .new:
            return "sparkles"
        case .learning:
            return "brain"
        case .mastered:
            return "checkmark.seal"
        case .dueForReview:
            return "timer"
        }
    }
}

// MARK: - Difficulty Level
public enum DifficultyLevel: String, Codable, CaseIterable, Sendable {
    case all = "all"
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    public var description: String {
        switch self {
        case .all:
            return "Tous niveaux"
        case .easy:
            return "Facile"
        case .medium:
            return "Moyen"
        case .hard:
            return "Difficile"
        }
    }
    
    public var icon: String {
        switch self {
        case .all:
            return "square.stack.3d.up"
        case .easy:
            return "face.smiling"
        case .medium:
            return "face.neutral"
        case .hard:
            return "exclamationmark.triangle"
        }
    }
}