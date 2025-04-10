import Core
import Foundation

// MARK: - Types locaux pour éviter les ambiguïtés


/// Représente une révision individuelle d'une carte
public struct CardReview: Identifiable, Hashable, Sendable {
    /// Identifiant unique de la révision
    public let id: UUID
    
    /// Identifiant de la carte révisée
    public let cardID: UUID
    
    /// Identifiant de la session d'étude associée
    public let sessionID: UUID?
    
    /// Date et heure de la révision
    public let timestamp: Date
    
    /// Note attribuée à la révision
    public let rating: Core.Common.ReviewRating
    
    /// Temps de réponse en secondes
    public let responseTime: TimeInterval
    
    /// Nouvel intervalle calculé
    public let newInterval: Int
    
    /// Nouveau facteur de facilité calculé
    public let newEase: Double
    
    /// Nouveau niveau de maîtrise calculé
    public let newMasteryLevel: Core.Models.Common.MasteryLevel
    
    /// Indique si la réponse était correcte
    public var isCorrect: Bool {
        return rating != .again
    }
    
    /// Initialisation d'une nouvelle révision
    public init(
        id: UUID = UUID(),
        cardID: UUID,
        sessionID: UUID? = nil,
        timestamp: Date = Date(),
        rating: Core.Common.ReviewRating,
        responseTime: TimeInterval,
        newInterval: Int = 0,
        newEase: Double = 2.5,
        newMasteryLevel: Core.Models.Common.MasteryLevel = .novice
    ) {
        self.id = id
        self.cardID = cardID
        self.sessionID = sessionID
        self.timestamp = timestamp
        self.rating = rating
        self.responseTime = responseTime
        self.newInterval = newInterval
        self.newEase = newEase
        self.newMasteryLevel = newMasteryLevel
    }
} 