// Stubs temporaires
// Type déplacé vers Core/Common/Types.swift pour éviter les ambiguïtés
// Type déplacé vers Core/Models/Common/Enums.swift pour éviter les ambiguïtés


import Foundation

@preconcurrency
public protocol CardSchedulerProtocolV2: Sendable {
    // Méthodes d'instance
    func calculateNextReview(currentInterval: Int, currentEase: Double, rating: Core.Common.ReviewRating) -> (interval: Int, ease: Double)
    func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
    func calculateNextReviewDate(currentInterval: Int, rating: Core.Common.ReviewRating) -> Date
}

