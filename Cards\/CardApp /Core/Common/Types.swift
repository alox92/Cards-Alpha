import Core
import Foundation

/// Espace de noms pour les types communs
public enum Common {}

/// Type d'évaluation pour une révision de carte
public extension Common {
    enum ReviewRating: Int, Codable, CaseIterable, Sendable {
        case again = 0
        case hard = 1
        case good = 2
        case easy = 3
        
        public var description: String {
            switch self {
            case .again:
                return "Encore"
            case .hard:
                return "Difficile"
            case .good:
                return "Bien"
            case .easy:
                return "Facile"
            }
        }
        
        public var icon: String {
            switch self {
            case .again:
                return "xmark.circle"
            case .hard:
                return "exclamationmark.circle"
            case .good:
                return "checkmark.circle"
            case .easy:
                return "checkmark.circle.fill"
            }
        }
    }
}

/// Type d'erreur pour le service d'étude
public extension Common {
    enum StudyServiceError: Error, Sendable {
        case sessionNotFound
        case sessionAlreadyStarted
        case noActiveSession
        case cardNotFound
        case cardAlreadyReviewed
        case invalidData
        case internalError
        
        public var description: String {
            switch self {
            case .sessionNotFound:
                return "Session d'étude introuvable"
            case .sessionAlreadyStarted:
                return "Une session d'étude est déjà démarrée"
            case .noActiveSession:
                return "Aucune session d'étude active"
            case .cardNotFound:
                return "Carte introuvable"
            case .cardAlreadyReviewed:
                return "Carte déjà révisée dans cette session"
            case .invalidData:
                return "Données invalides"
            case .internalError:
                return "Erreur interne"
            }
        }
    }
}

// MARK: - Type Aliases
// Les typealias CardID, DeckID, TagID, SessionID et ReviewID sont définis ailleurs et ne sont pas nécessaires ici

// Note: Core.Models.Common.MasteryLevel est maintenant défini dans Core/Models/Common/Enums.swift

// MARK: - Enums
/// Options de tri pour les cartes
public enum CardSortOption: String, Codable, CaseIterable, Sendable {
    case createdAt = "createdAt"
    case updatedAt = "updatedAt"
    case lastReviewed = "lastReviewed"
    case nextReview = "nextReview"
    case masteryLevel = "masteryLevel"
    case front = "front"
    case back = "back"
    case relevance = "relevance"
}

/// Type de filtrage par date
public enum DateFilterType: String, Codable, Sendable {
    case creationDate = "creationDate"
    case modificationDate = "modificationDate"
}

/// Ordre de tri
public enum SortOrder: String, Codable, CaseIterable, Sendable {
    case ascending = "ascending"
    case descending = "descending"
}

/// Options de filtrage pour les cartes
public struct CardFilterOptions: Codable, Equatable, Sendable {
    public struct DateRange: Codable, Equatable, Sendable {
        public let start: Date?
        public let end: Date?
        
        public init(start: Date? = nil, end: Date? = nil) {
            self.start = start
            self.end = end
        }
    }
    
    public let tags: [String]?
    public let masteryLevel: Core.Models.Common.MasteryLevel?
    public let isDue: Bool?
    public let isFlagged: Bool?
    public let sortBy: CardSortOption
    public let sortOrder: SortOrder
    public let includeArchived: Bool
    public let dateFilterType: DateFilterType
    public let dateRange: DateRange?
    public let learningState: LearningState
    public let difficultyLevel: DifficultyLevel
    
    public init(
        tags: [String]? = nil,
        masteryLevel: Core.Models.Common.MasteryLevel? = nil,
        isDue: Bool? = nil,
        isFlagged: Bool? = nil,
        sortBy: CardSortOption = .createdAt,
        sortOrder: SortOrder = .ascending,
        includeArchived: Bool = false,
        dateFilterType: DateFilterType = .creationDate,
        dateRange: DateRange? = nil,
        learningState: LearningState = .all,
        difficultyLevel: DifficultyLevel = .all
    ) {
        self.tags = tags
        self.masteryLevel = masteryLevel
        self.isDue = isDue
        self.isFlagged = isFlagged
        self.sortBy = sortBy
        self.sortOrder = sortOrder
        self.includeArchived = includeArchived
        self.dateFilterType = dateFilterType
        self.dateRange = dateRange
        self.learningState = learningState
        self.difficultyLevel = difficultyLevel
    }
    
    /// Crée une option de filtrage par date
    public static func withDateRange(
        startDate: Date?,
        endDate: Date?,
        type: DateFilterType = .creationDate
    ) -> CardFilterOptions {
        return CardFilterOptions(
            dateFilterType: type,
            dateRange: DateRange(start: startDate, end: endDate)
        )
    }
    
    /// Crée une option de filtrage pour les cartes récentes
    public static func recentCards(days: Int) -> CardFilterOptions {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)
        
        return CardFilterOptions(
            dateFilterType: .creationDate,
            dateRange: DateRange(start: startDate, end: endDate)
        )
    }
}

/// Statistiques d'une carte
public struct CardStats: Codable, Equatable {
    public let totalReviews: Int
    public let correctReviews: Int
    public let streak: Int
    public let averageResponseTime: TimeInterval
    public let firstStudyDate: Date?
    public let lastStudyDate: Date?
    
    public init(
        totalReviews: Int = 0,
        correctReviews: Int = 0,
        streak: Int = 0,
        averageResponseTime: TimeInterval = 0,
        firstStudyDate: Date? = nil,
        lastStudyDate: Date? = nil
    ) {
        self.totalReviews = totalReviews
        self.correctReviews = correctReviews
        self.streak = streak
        self.averageResponseTime = averageResponseTime
        self.firstStudyDate = firstStudyDate
        self.lastStudyDate = lastStudyDate
    }
    
    public var successRate: Double {
        guard totalReviews > 0 else { return 0 }
        return Double(correctReviews) / Double(totalReviews)
    }
}

// MARK: - Protocols
public protocol IdentifiableModel: Identifiable, Hashable {
    var id: UUID { get }
}

public protocol TimestampedModel {
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

// MARK: - Extensions
// Extension supprimée pour éviter les conflits potentiels avec le SDK d'Apple
// UUID est déjà identifiable conceptuellement, nous utiliserons directement son ID

// Fonction d'aide pour traiter UUID comme un identifiable sans l'extension
public func getID(of uuid: UUID) -> UUID {
    return uuid
}

extension Date {
    public static var now: Date { Date() }
} 