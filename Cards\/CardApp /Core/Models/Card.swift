import Foundation
 
// Types importés depuis Common/Types.swift
// Les types définis dans ce module sont déjà accessibles car dans le même package

/// Modèle représentant une carte d'apprentissage
public struct Card: Identifiable, Codable, Equatable, Sendable {
    // MARK: - Propriétés d'identification
    public let id: UUID
    public let deckID: UUID
    
    // MARK: - Contenu de la carte
    public let question: String
    public let answer: String
    public let additionalInfo: String?
    public var tags: [String]
    
    // MARK: - Paramètres d'étude
    public var masteryLevel: Core.Models.Common.MasteryLevel
    public var interval: Int
    public var ease: Double
    public var reviewCount: Int
    public var correctCount: Int
    public var incorrectCount: Int
    public var lastReviewedAt: Date?
    public var nextReviewDate: Date?
    
    // MARK: - Méta-données
    public var isFlagged: Bool
    public let createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialisation
    public init(
        id: UUID = UUID(),
        deckID: UUID,
        question: String,
        answer: String,
        additionalInfo: String? = nil,
        tags: [String] = [],
        masteryLevel: Core.Models.Common.MasteryLevel = .novice,
        interval: Int = 0,
        ease: Double = 2.5,
        reviewCount: Int = 0,
        correctCount: Int = 0,
        incorrectCount: Int = 0,
        lastReviewedAt: Date? = nil,
        nextReviewDate: Date? = nil,
        isFlagged: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.deckID = deckID
        self.question = question
        self.answer = answer
        self.additionalInfo = additionalInfo
        self.tags = tags
        self.masteryLevel = masteryLevel
        self.interval = interval
        self.ease = ease
        self.reviewCount = reviewCount
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewDate = nextReviewDate
        self.isFlagged = isFlagged
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
public init(from entity: CardEntity) {
self.id = entity.id ?? UUID()
self.deckID = entity.deckID ?? UUID()
self.question = entity.question ?? ""
self.answer = entity.answer ?? ""
self.additionalInfo = entity.additionalInfo
self.tags = entity.tags ?? []
self.masteryLevel = MasteryLevel(rawValue: Int(entity.masteryLevel)) ?? .novice
self.interval = Int(entity.interval)
self.ease = entity.ease
self.reviewCount = Int(entity.reviewCount)
self.correctCount = Int(entity.correctCount)
self.incorrectCount = Int(entity.incorrectCount)
self.lastReviewedAt = entity.lastReviewedAt
self.nextReviewDate = entity.nextReviewDate
self.isFlagged = entity.isFlagged
self.createdAt = entity.createdAt ?? Date()
self.updatedAt = entity.updatedAt ?? Date()
}
    
    // MARK: - Méthodes utilitaires
    
    /// Vérifie si une carte est due pour révision
    public var isDue: Bool {
        guard let nextReviewDate = nextReviewDate else {
            return true
        }
        return nextReviewDate <= Date()
    }
    
    /// Retourne une copie de la carte avec une date de mise à jour actualisée
    public func withUpdatedTimestamp() -> Card {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }
    
    /// Crée une version de la carte après une révision
    public func recordReview(rating: Core.Common.ReviewRating, scheduler: any CardSchedulerProtocolV2) -> Card {
        var copy = self
        let result = scheduler.calculateNextReview(currentInterval: interval, currentEase: ease, rating: rating)
        let newMasteryLevel = scheduler.calculateNewMasteryLevel(currentLevel: masteryLevel, rating: rating)
        
        copy.interval = result.interval
        copy.ease = result.ease
        copy.masteryLevel = newMasteryLevel
        copy.reviewCount += 1
        copy.lastReviewedAt = Date()
        copy.nextReviewDate = scheduler.calculateNextReviewDate(currentInterval: result.interval, rating: rating)
        
        if rating == .good || rating == .easy {
            copy.correctCount += 1
        } else {
            copy.incorrectCount += 1
        }
        
        return copy
    }
    
    /// Réinitialise les données de progression d'une carte
    public func reset() -> Card {
        var copy = self
        copy.masteryLevel = .novice
        copy.interval = 0
        copy.ease = 2.5
        copy.reviewCount = 0
        copy.correctCount = 0
        copy.incorrectCount = 0
        copy.lastReviewedAt = nil
        copy.nextReviewDate = nil
        copy.updatedAt = Date()
        return copy
    }
}

// MARK: - Méthodes statiques
extension Card {
    /// Crée une carte avec des données de prévisualisation
    public static var preview: Card {
        Card(
            id: UUID(),
            deckID: UUID(),
            question: "Qu'est-ce que la mémorisation active?",
            answer: "Une technique d'apprentissage où l'on teste activement sa mémoire plutôt que de relire passivement.",
            additionalInfo: "Également connue sous le nom de rappel actif ou récupération pratique.",
            tags: ["Apprentissage", "Techniques", "Mémoire"],
            masteryLevel: .intermediate,
            interval: 7,
            ease: 2.3,
            reviewCount: 5,
            correctCount: 4,
            incorrectCount: 1,
            lastReviewedAt: Date().addingTimeInterval(-7 * 24 * 3600),
            nextReviewDate: Date().addingTimeInterval(24 * 3600),
            isFlagged: false,
            createdAt: Date().addingTimeInterval(-30 * 24 * 3600),
            updatedAt: Date().addingTimeInterval(-7 * 24 * 3600)
        )
    }
} 