import Foundation
import Combine

/// Protocole définissant les fonctionnalités du service de gestion des paquets
@MainActor @preconcurrency public protocol DeckServiceProtocol {
    // MARK: - Publishers
    var decksPublisher: AnyPublisher<[Deck], Never> { get }
    
    // MARK: - CRUD Operations
    func createDeck(_ deck: Deck) async throws -> Deck
    func getDeck(byID id: UUID) async throws -> Deck
    func updateDeck(_ deck: Deck) async throws -> Deck
    func deleteDeck(_ deck: Deck) async throws
    func deleteDecks(_ decks: [Deck]) async throws
    
    // MARK: - Batch Operations
    func getAllDecks() async throws -> [Deck]
    func getDecks(withTags tags: [String]) async throws -> [Deck]
    func getSubdecks(forDeckID deckID: UUID) async throws -> [Deck]
    
    // MARK: - Deck Management
    func addCardToDeck(cardID: UUID, deckID: UUID) async throws
    func removeCardFromDeck(cardID: UUID, deckID: UUID) async throws
    func moveCardToDeck(cardID: UUID, fromDeckID: UUID, toDeckID: UUID) async throws
    func addSubdeck(_ subdeck: Deck, toParentID parentID: UUID) async throws
    func removeSubdeck(deckID: UUID, fromParentID parentID: UUID) async throws
    
    // MARK: - Statistics
    func getDeckStatistics(forDeckID deckID: UUID) async throws -> DeckStudyStats
    func updateDeckStatistics(forDeckID deckID: UUID) async throws
    
    // MARK: - Search
    func searchDecks(query: String) async throws -> [Deck]
    
    // MARK: - Import/Export
    func importDecks(_ decks: [Deck]) async throws -> [Deck]
    func exportDecks(_ decks: [Deck]) async throws -> Data
} 