import Foundation
import Combine

/// Protocole définissant les fonctionnalités du service de gestion des tags
@MainActor @preconcurrency public protocol TagServiceProtocol {
    // MARK: - Publishers
    var tagsPublisher: AnyPublisher<[Tag], Never> { get }
    
    // MARK: - CRUD Operations
    func createTag(_ tag: Tag) async throws -> Tag
    func getTag(byID id: UUID) async throws -> Tag
    func updateTag(_ tag: Tag) async throws -> Tag
    func deleteTag(_ tag: Tag) async throws
    func deleteTags(_ tags: [Tag]) async throws
    
    // MARK: - Batch Operations
    func getAllTags() async throws -> [Tag]
    func getTags(withNames names: [String]) async throws -> [Tag]
    func getTagsUsage() async throws -> [(String, Int)]
    
    // MARK: - Tag Management
    func addTagToCard(tagName: String, cardID: UUID) async throws
    func removeTagFromCard(tagName: String, cardID: UUID) async throws
    func addTagToDeck(tagName: String, deckID: UUID) async throws
    func removeTagFromDeck(tagName: String, deckID: UUID) async throws
    
    // MARK: - Search
    func searchTags(query: String) async throws -> [Tag]
    
    // MARK: - Import/Export
    func importTags(_ tags: [Tag]) async throws -> [Tag]
    func exportTags(_ tags: [Tag]) async throws -> Data
} 