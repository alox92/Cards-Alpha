import SwiftUI
import CoreData
import Combine

class DeckViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var decks: [Deck] = []
    @Published var selectedDeck: Deck?
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    @Published var searchText: String = ""
    @Published var isAddingDeck: Bool = false
    @Published var filteredDecks: [Deck] = []
    @Published var sortOption: DeckSortOption = .alphabetical
    
    // MARK: - Private Properties
    private let cardService: CardService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Properties
    var cardViewModel: CardViewModel?
    
    // MARK: - Initialization
    init(cardService: CardService) {
        self.cardService = cardService
        setupSubscriptions()
    }
    
    // MARK: - Setup
    private func setupSubscriptions() {
        // Réagir aux changements de texte de recherche et d'option de tri
        Publishers.CombineLatest($searchText, $sortOption)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] (searchText, sortOption) in
                self?.filterAndSortDecks(searchText: searchText, sortOption: sortOption)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func fetchDecks() {
        isLoading = true
        
        Task {
            do {
                let fetchedDecks = try await cardService.fetchDecks()
                
                await MainActor.run {
                    self.decks = fetchedDecks
                    self.filterAndSortDecks(searchText: self.searchText, sortOption: self.sortOption)
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
    
    func addDeck(name: String, description: String, color: Color) async throws {
        isLoading = true
        
        do {
            let colorCode = color.toHex() ?? "#3478F6"
            let newDeck = try await cardService.createDeck(name: name, description: description, color: colorCode)
            
            await MainActor.run {
                self.decks.append(newDeck)
                self.filterAndSortDecks(searchText: self.searchText, sortOption: self.sortOption)
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
    
    func updateDeck(_ deck: Deck, name: String, description: String, color: Color) async throws {
        isLoading = true
        
        do {
            let colorCode = color.toHex() ?? "#3478F6"
            let updatedDeck = try await cardService.updateDeck(deck, name: name, description: description, color: colorCode)
            
            await MainActor.run {
                if let index = self.decks.firstIndex(where: { $0.id == updatedDeck.id }) {
                    self.decks[index] = updatedDeck
                }
                self.filterAndSortDecks(searchText: self.searchText, sortOption: self.sortOption)
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
    
    func deleteDeck(_ deck: Deck) async throws {
        isLoading = true
        
        do {
            try await cardService.deleteDeck(deck)
            
            await MainActor.run {
                self.decks.removeAll { $0.id == deck.id }
                if self.selectedDeck?.id == deck.id {
                    self.selectedDeck = nil
                }
                self.filterAndSortDecks(searchText: self.searchText, sortOption: self.sortOption)
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
    
    func selectDeck(_ deck: Deck?) {
        self.selectedDeck = deck
        
        if let deck = deck, let cardViewModel = self.cardViewModel {
            cardViewModel.fetchCards(for: deck)
        }
    }
    
    func importDeck(from url: URL) async throws {
        isLoading = true
        
        do {
            let importedDeck = try await cardService.importDeck(from: url)
            
            await MainActor.run {
                self.decks.append(importedDeck)
                self.filterAndSortDecks(searchText: self.searchText, sortOption: self.sortOption)
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
    
    func exportDeck(_ deck: Deck, to url: URL) async throws {
        isLoading = true
        
        do {
            try await cardService.exportDeck(deck, to: url)
            
            await MainActor.run {
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
    private func filterAndSortDecks(searchText: String, sortOption: DeckSortOption) {
        let lowercasedText = searchText.lowercased()
        
        // Filtrer
        let filtered = decks.filter { deck in
            searchText.isEmpty ||
            deck.name.lowercased().contains(lowercasedText) ||
            deck.description.lowercased().contains(lowercasedText)
        }
        
        // Trier
        switch sortOption {
        case .alphabetical:
            filteredDecks = filtered.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .dateCreated:
            filteredDecks = filtered.sorted { $0.createdAt > $1.createdAt }
        case .dateModified:
            filteredDecks = filtered.sorted { $0.updatedAt > $1.updatedAt }
        case .cardCount:
            filteredDecks = filtered.sorted { $0.cardCount > $1.cardCount }
        case .dueCardCount:
            filteredDecks = filtered.sorted { $0.dueCardCount > $1.dueCardCount }
        }
    }
    
    func clearError() {
        error = nil
    }
} 