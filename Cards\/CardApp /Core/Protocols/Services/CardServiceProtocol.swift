import Foundation
import Combine

/// Protocole définissant les fonctionnalités du service de gestion des cartes
@MainActor @preconcurrency public protocol CardServiceProtocol {
    // MARK: - Publishers
    var cardsPublisher: AnyPublisher<[Card], Never> { get }
    
    // MARK: - CRUD Operations
    func createCard(_ card: Card) async throws -> Card
    func getCard(byID id: UUID) async throws -> Card
    func updateCard(_ card: Card) async throws -> Card
    func deleteCard(_ card: Card) async throws
    func deleteCards(_ cards: [Card]) async throws
    
    // MARK: - Batch Operations
    func getAllCards() async throws -> [Card]
    func getCards(forDeckID deckID: UUID) async throws -> [Card]
    func getCards(withTags tags: [String]) async throws -> [Card]
    func getDueCards(forDeckID deckID: UUID, limit: Int?) async throws -> [Card]
    
    // MARK: - Card Updates
    func updateCardAfterReview(_ card: Card, rating: Core.Common.ReviewRating) async throws -> Card
    func updateCardTags(_ card: Card, tags: [String]) async throws -> Card
    func flagCard(_ card: Card, isFlagged: Bool) async throws -> Card
    
    // MARK: - Search
    func searchCards(query: String, options: CardFilterOptions?) async throws -> [Card]
    
    // MARK: - Import/Export
    func importCards(_ cards: [Card], toDeckID deckID: UUID) async throws -> [Card]
    func exportCards(_ cards: [Card]) async throws -> Data
} 