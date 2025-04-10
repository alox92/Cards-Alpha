import Foundation
import Combine

/// Protocole pour le service d'étude
@MainActor @preconcurrency public protocol StudyServiceProtocol {
    /// Crée une nouvelle session d'étude
    func createSession(deckID: UUID, includeSubdecks: Bool, reviewLimit: Int?) async throws -> StudySession
    
    /// Récupère une session d'étude par son ID
    func getSession(byID id: UUID) async throws -> StudySession
    
    /// Met à jour une session d'étude
    func updateSession(_ session: StudySession) async throws -> StudySession
    
    /// Termine une session d'étude
    func endSession(_ session: StudySession) async throws -> StudySession
    
    /// Récupère les cartes programmées pour une session
    func getScheduledCards(forSessionID sessionID: UUID) async throws -> [Card]
    
    /// Récupère les cartes déjà révisées dans une session
    func getReviewedCards(forSessionID sessionID: UUID) async throws -> [Card]
    
    /// Enregistre une révision de carte
    func recordCardReview(cardID: UUID, sessionID: UUID, rating: Core.Common.ReviewRating, responseTime: TimeInterval) async throws -> CardReview
    
    /// Récupère l'historique des révisions d'une carte
    func getCardReviews(forCardID cardID: UUID) async throws -> [CardReview]
    
    /// Récupère les statistiques d'étude d'une carte
    func getCardStudyStats(forCardID cardID: UUID) async throws -> CardStudyStats
    
    /// Récupère les statistiques d'étude d'un paquet
    func getDeckStudyStats(forDeckID deckID: UUID) async throws -> DeckStudyStats
    
    /// Récupère les statistiques d'une session
    func getSessionStats(forSessionID sessionID: UUID) async throws -> StudySessionStats
} 