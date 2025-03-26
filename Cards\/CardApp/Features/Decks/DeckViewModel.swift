import Foundation
import Combine
import SwiftUI
import CoreData

class DeckViewModel: ObservableObject {
    // MARK: - Propriétés publiées
    @Published var decks: [Deck] = []
    @Published var filteredDecks: [Deck] = []
    @Published var selectedDeck: Deck?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var filterOption: CardFilterOption = .all
    @Published var isAddingDeck: Bool = false
    @Published var showingDeckDetail: Bool = false
    
    // MARK: - Services
    private let cardService: CardService
    private var cancellables = Set<AnyCancellable>()
    weak var studyViewModel: StudyViewModel?
    weak var cardViewModel: CardViewModel?
    
    // MARK: - Initialisation
    init(cardService: CardService) {
        self.cardService = cardService
        
        // Observer les changements de recherche
        $searchText
            .combineLatest($decks)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] (searchText, decks) in
                self?.applySearch(searchText: searchText, decks: decks)
            }
            .store(in: &cancellables)
        
        loadDecks()
    }
    
    // MARK: - Méthodes publiques
    
    /// Récupère tous les paquets
    func fetchDecks() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedDecks = try await cardService.fetchDecks()
                await MainActor.run {
                    self.decks = fetchedDecks
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors du chargement des paquets: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Crée un nouveau paquet
    func createDeck(name: String, description: String = "", icon: String = "rectangle.stack", colorName: String = "blue") {
        isLoading = true
        errorMessage = nil
        
        let newDeck = Deck(
            id: UUID(),
            name: name,
            description: description,
            icon: icon,
            colorName: colorName,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Pour l'exemple, nous ajoutons directement le paquet à la liste
        // Dans une application réelle, il faudrait l'enregistrer dans CoreData
        self.decks.append(newDeck)
        self.selectedDeck = newDeck
        self.isLoading = false
    }
    
    /// Sélectionne un paquet
    func selectDeck(_ deck: Deck?) {
        self.selectedDeck = deck
    }
    
    /// Retourne les cartes dues pour un paquet
    func getDueCards(for deck: Deck) -> Int {
        return deck.dueCards
    }
    
    /// Retourne les statistiques d'un paquet
    func getStats(for deck: Deck) -> (total: Int, new: Int, learning: Int, reviewing: Int, mastered: Int) {
        return (
            total: deck.totalCards,
            new: deck.newCards,
            learning: deck.learningCards,
            reviewing: deck.reviewingCards,
            mastered: deck.masteredCards
        )
    }
    
    func loadDecks() {
        isLoading = true
        
        fetchDecks()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Erreur lors du chargement des paquets: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] decks in
                    self?.decks = decks
                }
            )
            .store(in: &cancellables)
    }
    
    func addDeck(_ deck: Deck) {
        saveDeck(deck)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Erreur lors de l'ajout du paquet: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.loadDecks()
                }
            )
            .store(in: &cancellables)
    }
    
    func updateDeck(_ deck: Deck) {
        saveDeck(deck)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Erreur lors de la mise à jour du paquet: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] _ in
                    if let index = self?.decks.firstIndex(where: { $0.id == deck.id }) {
                        self?.decks[index] = deck
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteDeck(_ deck: Deck) {
        removeDeck(deck)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Erreur lors de la suppression du paquet: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.decks.removeAll { $0.id == deck.id }
                }
            )
            .store(in: &cancellables)
    }
    
    func getDeckById(_ id: UUID) -> Deck? {
        return decks.first { $0.id == id }
    }
    
    var dueDecks: [Deck] {
        return decks.filter { $0.dueCards > 0 }
    }
    
    // MARK: - Méthodes privées
    
    /// Applique la recherche aux paquets
    private func applySearch(searchText: String, decks: [Deck]) {
        if searchText.isEmpty {
            filteredDecks = decks
            return
        }
        
        let searchTextLower = searchText.lowercased()
        filteredDecks = decks.filter {
            $0.name.lowercased().contains(searchTextLower) ||
            $0.description.lowercased().contains(searchTextLower)
        }
    }
    
    private func saveDeck(_ deck: Deck) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DeckViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "View model not available"])))
                return
            }
            
            do {
                let fetchRequest = NSFetchRequest<DeckEntity>(entityName: "DeckEntity")
                fetchRequest.predicate = NSPredicate(format: "id == %@", deck.id as CVarArg)
                fetchRequest.fetchLimit = 1
                
                let results = try self.context.fetch(fetchRequest)
                let entity: DeckEntity
                
                if let existingEntity = results.first {
                    entity = existingEntity
                } else {
                    entity = DeckEntity(context: self.context)
                    entity.id = deck.id
                }
                
                entity.name = deck.name
                entity.icon = deck.icon
                entity.description = deck.description
                entity.colorName = deck.colorName
                entity.createdAt = deck.createdAt
                
                try self.context.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func removeDeck(_ deck: Deck) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DeckViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "View model not available"])))
                return
            }
            
            do {
                let fetchRequest = NSFetchRequest<DeckEntity>(entityName: "DeckEntity")
                fetchRequest.predicate = NSPredicate(format: "id == %@", deck.id as CVarArg)
                fetchRequest.fetchLimit = 1
                
                let results = try self.context.fetch(fetchRequest)
                
                if let entity = results.first {
                    self.context.delete(entity)
                    try self.context.save()
                    promise(.success(()))
                } else {
                    promise(.failure(NSError(domain: "DeckViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Deck not found"])))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Preview
extension DeckViewModel {
    static var preview: DeckViewModel {
        let viewModel = DeckViewModel(cardService: CardService())
        return viewModel
    }
}

// MARK: - Extensions for Study Dashboard
extension Deck {
    var cardCount: Int {
        return totalCards
    }
    
    var dueTodayCount: Int {
        return dueCards
    }
    
    var progressPercentage: Double {
        guard cardCount > 0 else { return 0 }
        
        // Calculer le pourcentage de cartes maîtrisées
        let masteredPercentage = Double(masteredCards) / Double(cardCount) * 100
        return masteredPercentage
    }
} 