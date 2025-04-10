import Foundation

/// Représente une session d'étude
public struct StudySession: Identifiable, Codable, Sendable {
    /// Identifiant unique de la session
    public let id: UUID
    
    /// Identifiant du paquet étudié
    public let deckID: UUID
    
    /// Date de début de la session
    public let startDate: Date
    
    /// Date de fin de la session (optionnelle)
    public var endDate: Date?
    
    /// Cartes programmées pour cette session
    public let scheduledCards: [UUID]
    
    /// Cartes déjà révisées dans cette session
    public var reviewedCards: [UUID]
    
    /// Nombre de réponses correctes
    public var correctCount: Int
    
    /// Nombre de réponses incorrectes
    public var incorrectCount: Int
    
    /// Indique si les sous-paquets sont inclus
    public let includeSubdecks: Bool
    
    /// Limite de révisions pour cette session
    public let reviewLimit: Int?
    
    /// Temps total d'étude
    public let totalStudyTime: TimeInterval
    
    /// Taux de réussite
    public var successRate: Double {
        let total = correctCount + incorrectCount
        return total > 0 ? Double(correctCount) / Double(total) : 0
    }
    
    /// Nombre de cartes restantes à réviser
    public var remainingCount: Int {
        return scheduledCards.count - reviewedCards.count
    }
    
    /// Durée de la session
    public var duration: TimeInterval {
        if let endDate = endDate {
            return endDate.timeIntervalSince(startDate)
        }
        return Date().timeIntervalSince(startDate)
    }
    
    /// Initialisation d'une nouvelle session
    public init(
        id: UUID = UUID(),
        deckID: UUID,
        startDate: Date = Date(),
        endDate: Date? = nil,
        scheduledCards: [UUID] = [],
        reviewedCards: [UUID] = [],
        correctCount: Int = 0,
        incorrectCount: Int = 0,
        includeSubdecks: Bool = false,
        reviewLimit: Int? = nil,
        totalStudyTime: TimeInterval = 0
    ) {
        self.id = id
        self.deckID = deckID
        self.startDate = startDate
        self.endDate = endDate
        self.scheduledCards = scheduledCards
        self.reviewedCards = reviewedCards
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.includeSubdecks = includeSubdecks
        self.reviewLimit = reviewLimit
        self.totalStudyTime = totalStudyTime
    }
} 