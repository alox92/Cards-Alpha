import Foundation
import Combine
import CoreData
import SwiftUI

class CardViewModel: ObservableObject {
    // MARK: - Propriétés publiées
    @Published var cards: [Card] = []
    @Published var filteredCards: [Card] = []
    @Published var selectedDeck: Deck?
    @Published var selectedCard: Card?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filterOption: CardFilterOption = .all
    @Published var searchText = ""
    
    // MARK: - Services
    private let cardService: CardService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialisation
    init(cardService: CardService) {
        self.cardService = cardService
        
        // Observer les changements de filtres
        $filterOption
            .combineLatest($searchText, $cards)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] (filterOption, searchText, cards) in
                self?.applyFilters(filterOption: filterOption, searchText: searchText, cards: cards)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Méthodes publiques
    
    /// Récupère les cartes d'un paquet spécifique
    func fetchCards(for deck: Deck? = nil) {
        isLoading = true
        errorMessage = nil
        selectedDeck = deck
        
        Task {
            do {
                let fetchedCards = try await cardService.fetchCards(for: deck)
                await MainActor.run {
                    self.cards = fetchedCards
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors du chargement des cartes: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Crée une nouvelle carte
    func createCard(question: String, answer: String, additionalInfo: String? = nil, tags: [String] = []) {
        guard let deck = selectedDeck else {
            errorMessage = "Aucun paquet sélectionné"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let newCard = try await cardService.createCard(
                    front: question,
                    back: answer,
                    in: deck,
                    additionalInfo: additionalInfo,
                    tags: tags
                )
                
                await MainActor.run {
                    self.cards.append(newCard)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors de la création de la carte: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Met à jour une carte existante
    func updateCard(_ card: Card) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await cardService.updateCard(card)
                
                await MainActor.run {
                    if let index = self.cards.firstIndex(where: { $0.id == card.id }) {
                        self.cards[index] = card
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors de la mise à jour de la carte: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Met à jour une carte après une révision
    func updateCardAfterReview(_ card: Card, rating: ReviewRating) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await cardService.updateReviewForCard(card, rating: rating)
                await fetchCards(for: selectedDeck)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors de la mise à jour de la révision: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Change le statut marqué d'une carte
    func toggleFlagged(for card: Card) {
        var updatedCard = card
        updatedCard.isFlagged.toggle()
        updateCard(updatedCard)
    }
    
    // MARK: - Méthodes privées
    
    /// Applique les filtres et la recherche aux cartes
    private func applyFilters(filterOption: CardFilterOption, searchText: String, cards: [Card]) {
        let searchTextLower = searchText.lowercased()
        
        // Filtrer par l'option sélectionnée
        var filtered = cards
        
        switch filterOption {
        case .all:
            // Pas de filtrage supplémentaire
            break
        case .due:
            filtered = cards.filter { $0.isDue }
        case .new:
            filtered = cards.filter { $0.isNew }
        case .learning:
            filtered = cards.filter { $0.masteryLevel == .learning }
        case .reviewing:
            filtered = cards.filter { $0.masteryLevel == .reviewing }
        case .mastered:
            filtered = cards.filter { $0.masteryLevel == .mastered }
        case .flagged:
            filtered = cards.filter { $0.isFlagged }
        case .difficult:
            filtered = cards.filter { $0.difficulty > 0.7 } // Les cartes avec plus de 70% d'erreurs
        }
        
        // Appliquer la recherche
        if !searchTextLower.isEmpty {
            filtered = filtered.filter {
                $0.question.lowercased().contains(searchTextLower) ||
                $0.answer.lowercased().contains(searchTextLower) ||
                ($0.additionalInfo?.lowercased().contains(searchTextLower) ?? false) ||
                $0.tags.contains { $0.lowercased().contains(searchTextLower) }
            }
        }
        
        self.filteredCards = filtered
    }
}

// MARK: - Preview
extension CardViewModel {
    static var preview: CardViewModel {
        let viewModel = CardViewModel(cardService: CardService(context: PersistenceController.shared.container.viewContext))
        viewModel.cards = Card.sampleData
        return viewModel
    }
} 