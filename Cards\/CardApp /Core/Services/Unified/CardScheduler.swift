import Foundation
import Core

/// Service de planification des cartes basé sur l'algorithme SM-2
@preconcurrency
public class CardSchedulerV2: CardSchedulerProtocolV2, @unchecked Sendable {
    // MARK: - Constantes
    
    /// Facteur de facilité par défaut
    let defaultEaseFactor: Double = 2.5
    
    /// Facteur de facilité minimum
    let easeFactorMin: Double = 1.3
    
    /// Facteur de facilité maximum
    let easeFactorMax: Double = 3.0
    
    /// Pas d'ajustement du facteur de facilité
    let easeFactorStep: Double = 0.15
    
    // MARK: - Initialisation
    
    /// Initialise un nouveau planificateur de cartes
    public init() {}
    
    // MARK: - Méthodes publiques
    
    /// Calcule le nouvel intervalle et facteur de facilité
    nonisolated public func calculateNextReview(currentInterval: Int, currentEase: Double, rating: Core.Common.ReviewRating) -> (interval: Int, ease: Double) {
        // Valeurs par défaut
        var newInterval = 1
        var newEase = max(easeFactorMin, currentEase)
        
        // Ajustement en fonction de l'évaluation
        switch rating {
        case .again:
            newInterval = 1
            newEase = max(easeFactorMin, newEase - easeFactorStep)
            
        case .hard:
            newInterval = max(1, Int(Double(currentInterval) * 0.8))
            newEase = max(easeFactorMin, newEase - easeFactorStep / 2)
            
        case .good:
            newInterval = max(1, Int(Double(currentInterval) * newEase))
            // Facteur de facilité inchangé
            
        case .easy:
            newInterval = Int(Double(currentInterval) * newEase * 1.5)
            newEase = min(easeFactorMax, newEase + easeFactorStep)
        }
        
        return (newInterval, newEase)
    }
    
    /// Calcule le nouveau niveau de maîtrise
    nonisolated public func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel {
        switch rating {
        case .again:
            return Core.Models.Common.MasteryLevel(rawValue: max(0, currentLevel.rawValue - 1)) ?? .novice
            
        case .hard:
            return currentLevel
            
        case .good:
            return Core.Models.Common.MasteryLevel(rawValue: min(4, currentLevel.rawValue + 1)) ?? .expert
            
        case .easy:
            return Core.Models.Common.MasteryLevel(rawValue: min(4, currentLevel.rawValue + 2)) ?? .expert
        }
    }
    
    /// Méthode helper - Calcule la date de la prochaine révision à partir d'une date donnée et un intervalle
    nonisolated public func calculateNextReviewDate(currentDate: Date = Date(), interval: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: interval, to: currentDate) ?? currentDate
    }
    
    /// Calcule la date de la prochaine révision en fonction de l'intervalle actuel et de l'évaluation
    /// Implémentation requise par le protocole CardSchedulerProtocolV2
    nonisolated public func calculateNextReviewDate(currentInterval: Int, rating: Core.Common.ReviewRating) -> Date {
        // Pour les cartes difficiles ou à revoir, l'intervalle est ajusté
        let adjustedInterval: Int
        switch rating {
        case .again:
            adjustedInterval = 1  // Revoir demain
        case .hard:
            adjustedInterval = max(1, currentInterval / 2)  // Réduire l'intervalle de moitié
        case .good:
            adjustedInterval = currentInterval  // Garder l'intervalle calculé
        case .easy:
            adjustedInterval = Int(Double(currentInterval) * 1.2)  // Augmenter légèrement l'intervalle
        }
        
        // Utiliser la méthode existante pour le calcul effectif de la date
        return calculateNextReviewDate(currentDate: Date(), interval: adjustedInterval)
    }
    
    // MARK: - Méthodes statiques pour compatibilité
    
    /// Version statique pour la compatibilité avec le code existant
    nonisolated public static func calculateNextReview(currentInterval: Int, currentEase: Double, rating: Core.Common.ReviewRating) -> (interval: Int, ease: Double) {
        return CardSchedulerV2().calculateNextReview(currentInterval: currentInterval, currentEase: currentEase, rating: rating)
    }
    
    /// Version statique pour la compatibilité avec le code existant
    nonisolated public static func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel {
        return CardSchedulerV2().calculateNewMasteryLevel(currentLevel: currentLevel, rating: rating)
    }
    
    /// Version statique pour la compatibilité avec le code existant - méthode helper non requise par le protocole
    nonisolated public static func calculateNextReviewDate(currentDate: Date = Date(), interval: Int) -> Date {
        return CardSchedulerV2().calculateNextReviewDate(currentDate: currentDate, interval: interval)
    }
    
    /// Version statique pour la compatibilité avec le code existant
    nonisolated public static func calculateNextReviewDate(currentInterval: Int, rating: Core.Common.ReviewRating) -> Date {
        return CardSchedulerV2().calculateNextReviewDate(currentInterval: currentInterval, rating: rating)
    }
} 
