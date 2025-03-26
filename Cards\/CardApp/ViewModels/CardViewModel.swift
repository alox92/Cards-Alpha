import SwiftUI
import CoreData
import Combine

class CardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var cards: [Card] = []
    @Published var filteredCards: [Card] = []
    @Published var selectedCard: Card?
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    @Published var filterOption: CardFilterOption = .all
    @Published var searchText: String = ""
    @Published var isAddingCard: Bool = false
    
    // MARK: - Private Properties
    private let cardService: CardService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(cardService: CardService) {
        self.cardService = cardService
        setupSubscriptions()
    }
    
    // MARK: - Setup
    private func setupSubscriptions() {
        // Réagir aux changements de texte de recherche et d'option de filtre
        Publishers.CombineLatest($searchText, $filterOption)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] (searchText, filterOption) in
                self?.filterCards(searchText: searchText, option: filterOption)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func fetchCards(for deck: Deck? = nil) {
        isLoading = true
        
        Task {
            do {
                let fetchedCards = try await cardService.fetchCards(for: deck)
                
                await MainActor.run {
                    self.cards = fetchedCards
                    self.filterCards(searchText: self.searchText, option: self.filterOption)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = AppError(error: error)
                    self.isLoading = false
                }
            }
        }
    }
    
    func addCard(front: String, back: String, deck: Deck, mediaItems: [MediaItem] = [], tags: [String] = []) async throws {
        isLoading = true
        
        do {
            let newCard = try await cardService.createCard(front: front, back: back, in: deck, mediaItems: mediaItems, tags: tags)
            
            await MainActor.run {
                self.cards.append(newCard)
                self.filterCards(searchText: self.searchText, option: self.filterOption)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = AppError(error: error)
                self.isLoading = false
            }
            throw error
        }
    }
    
    func updateCard(_ card: Card, front: String, back: String, mediaItems: [MediaItem] = [], tags: [String] = []) async throws {
        isLoading = true
        
        do {
            let updatedCard = try await cardService.updateCard(card, front: front, back: back, mediaItems: mediaItems, tags: tags)
            
            await MainActor.run {
                if let index = self.cards.firstIndex(where: { $0.id == updatedCard.id }) {
                    self.cards[index] = updatedCard
                }
                self.filterCards(searchText: self.searchText, option: self.filterOption)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = AppError(error: error)
                self.isLoading = false
            }
            throw error
        }
    }
    
    func deleteCard(_ card: Card) async throws {
        isLoading = true
        
        do {
            try await cardService.deleteCard(card)
            
            await MainActor.run {
                self.cards.removeAll { $0.id == card.id }
                self.filterCards(searchText: self.searchText, option: self.filterOption)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = AppError(error: error)
                self.isLoading = false
            }
            throw error
        }
    }
    
    func moveCard(_ card: Card, to deck: Deck) async throws {
        isLoading = true
        
        do {
            let updatedCard = try await cardService.moveCard(card, to: deck)
            
            await MainActor.run {
                if let index = self.cards.firstIndex(where: { $0.id == updatedCard.id }) {
                    self.cards[index] = updatedCard
                }
                self.filterCards(searchText: self.searchText, option: self.filterOption)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = AppError(error: error)
                self.isLoading = false
            }
            throw error
        }
    }
    
    // MARK: - Private Methods
    private func filterCards(searchText: String, option: CardFilterOption) {
        let lowercasedText = searchText.lowercased()
        
        filteredCards = cards.filter { card in
            let matchesSearch = searchText.isEmpty ||
                card.front.lowercased().contains(lowercasedText) ||
                card.back.lowercased().contains(lowercasedText) ||
                card.tags.contains { $0.lowercased().contains(lowercasedText) }
            
            let matchesFilter: Bool
            switch option {
            case .all:
                matchesFilter = true
            case .due:
                matchesFilter = card.isDue
            case .new:
                matchesFilter = card.isNew
            case .learned:
                matchesFilter = card.isLearned
            case .difficult:
                matchesFilter = card.difficulty > 0.7
            case .flagged:
                matchesFilter = card.isFlagged
            }
            
            return matchesSearch && matchesFilter
        }
    }
    
    func clearError() {
        error = nil
    }
} 