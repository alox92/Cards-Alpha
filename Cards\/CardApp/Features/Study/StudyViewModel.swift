import Foundation
import Combine
import CoreData
import SwiftUI

class StudyViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSession: StudySession?
    @Published var isStudying: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentDeck: Deck?
    @Published var cardsToStudy: [Card] = []
    @Published var currentCardIndex: Int = 0
    @Published var error: String?
    @Published var reviewStartTime: Date?
    @Published var showDeckSelection: Bool = false
    @Published var sessionCompleted: Bool = false
    @Published var sessionStats: SessionStats = SessionStats()
    @Published var currentCard: Card?
    @Published var isShowingAnswer = false
    @Published var sessionCards: [Card] = []
    @Published var remainingCards: [Card] = []
    @Published var completedCount = 0
    @Published var errorMessage: String?
    @Published var studyOptions = StudyOptions()
    
    // MARK: - Computed Properties
    var progress: Double {
        guard !cardsToStudy.isEmpty else { return 0 }
        return Double(currentCardIndex) / Double(cardsToStudy.count)
    }
    
    var remainingCards: Int {
        cardsToStudy.count - currentCardIndex
    }
    
    // MARK: - Private Properties
    private let cardService: CardService
    private var cancellables = Set<AnyCancellable>()
    private weak var deckViewModel: DeckViewModel?
    
    // MARK: - Initialization
    init(cardService: CardService = CardService(context: PersistenceController.shared.container.viewContext), deckViewModel: DeckViewModel? = nil) {
        self.cardService = cardService
        self.deckViewModel = deckViewModel
    }
    
    // MARK: - Public Methods
    func startSession(deckId: UUID) {
        isLoading = true
        
        // Récupérer le paquet actuel
        if let deckVM = deckViewModel {
            currentDeck = deckVM.decks.first(where: { $0.id == deckId })
        }
        
        Task {
            do {
                let cards = try await cardService.fetchCards(for: currentDeck)
                
                await MainActor.run {
                    setupSession(deckId: deckId, cards: cards)
                }
            } catch {
                await MainActor.run {
                    self.error = error?.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func startCardReview() {
        reviewStartTime = Date()
    }
    
    func recordReview(rating: ReviewRating) {
        guard let card = currentCard, let startTime = reviewStartTime else { return }
        
        let timeSpent = Date().timeIntervalSince(startTime)
        let review = CardReview(
            cardID: card.id,
            rating: rating,
            timeSpent: timeSpent
        )
        
        // Ajouter la révision à la session courante
        if var session = currentSession {
            session.addReview(review)
            currentSession = session
        }
        
        // Mettre à jour les statistiques
        sessionStats.cardsReviewed += 1
        if rating == .easy || rating == .good {
            sessionStats.correctAnswers += 1
        } else {
            sessionStats.incorrectAnswers += 1
        }
        
        // Mettre à jour la carte avec le résultat de la révision
        Task {
            do {
                let updatedCard = card.withUpdatedReview(rating: rating)
                try await cardService.updateReviewForCard(updatedCard, rating: rating)
                
                await MainActor.run {
                    advanceToNextCard()
                }
            } catch {
                await MainActor.run {
                    self.error = error?.localizedDescription
                }
            }
        }
        
        // Réinitialiser le temps de départ pour la prochaine carte
        reviewStartTime = nil
    }
    
    func advanceToNextCard() {
        if currentCardIndex < cardsToStudy.count - 1 {
            currentCardIndex += 1
            startCardReview()
        } else {
            endSession()
        }
    }
    
    func endSession() {
        guard var session = currentSession else { return }
        
        // Mettre à jour la session avec la date de fin
        session.endSession()
        currentSession = session
        
        // Sauvegarder la session terminée
        Task {
            do {
                try await cardService.saveStudySession(session)
            } catch {
                // Gérer l'erreur silencieusement, car nous terminons déjà la session
                print("Erreur lors de la sauvegarde de la session: \(error?.localizedDescription ?? "Erreur inconnue")")
            }
        }
        
        // Réinitialiser l'état
        isStudying = false
        sessionCompleted = true
    }
    
    func getStudiedCardsToday() -> [Card] {
        // Cette méthode devrait être implémentée pour retourner les cartes étudiées aujourd'hui
        // Pour l'instant, elle retourne un tableau vide
        return []
    }
    
    func resetError() {
        error = nil
    }
    
    func prepareStudySession(for deck: Deck? = nil, count: Int = 20) {
        isLoading = true
        
        Task {
            do {
                let allCards = try await cardService.fetchCards(for: deck)
                let dueCards = allCards.filter { $0.isDue }
                
                await MainActor.run {
                    self.cardsToStudy = Array(dueCards.prefix(count)).shuffled()
                    self.currentCardIndex = 0
                    self.sessionCompleted = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func recordReviewForCurrentCard(rating: ReviewRating) {
        guard let card = currentCard else { return }
        
        Task {
            do {
                try await cardService.updateReviewForCard(card, rating: rating)
                
                await MainActor.run {
                    moveToNextCard()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func moveToNextCard() {
        if currentCardIndex + 1 < cardsToStudy.count {
            currentCardIndex += 1
        } else {
            sessionCompleted = true
        }
    }
    
    // MARK: - Public Methods
    func startStudySession(for deck: Deck, options: StudyOptions? = nil) {
        isLoading = true
        errorMessage = nil
        
        if let options = options {
            self.studyOptions = options
        }
        
        Task {
            do {
                // Récupérer toutes les cartes du paquet
                let deckCards = try await cardService.fetchCards(for: deck)
                
                // Filtrer selon les options d'étude
                var cardsToStudy = deckCards
                
                // Filtrer par statut
                switch studyOptions.cardFilter {
                case .all:
                    break // Pas de filtrage
                case .due:
                    cardsToStudy = deckCards.filter { $0.isDue }
                case .new:
                    cardsToStudy = deckCards.filter { $0.isNew }
                case .reviewing:
                    cardsToStudy = deckCards.filter { $0.masteryLevel == .reviewing && $0.isDue }
                case .flagged:
                    cardsToStudy = deckCards.filter { $0.isFlagged }
                default:
                    break
                }
                
                // Limiter le nombre de cartes
                if let limit = studyOptions.cardLimit, limit > 0 && cardsToStudy.count > limit {
                    cardsToStudy = Array(cardsToStudy.prefix(limit))
                }
                
                // Mélanger si nécessaire
                if studyOptions.shouldShuffle {
                    cardsToStudy.shuffle()
                }
                
                // Créer la session
                let session = StudySession(
                    id: UUID(),
                    deckId: deck.id,
                    startTime: Date()
                )
                
                await MainActor.run {
                    self.sessionCards = cardsToStudy
                    self.remainingCards = cardsToStudy
                    self.currentSession = session
                    self.nextCard()
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors du démarrage de la session: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Termine la session d'étude actuelle
    func endSession() {
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        
        Task {
            do {
                try await cardService.saveStudySession(session)
                
                await MainActor.run {
                    self.clearSession()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors de la sauvegarde de la session: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Passe à la carte suivante
    func nextCard() {
        isShowingAnswer = false
        
        if remainingCards.isEmpty {
            currentCard = nil
            return
        }
        
        currentCard = remainingCards.removeFirst()
    }
    
    /// Montre la réponse pour la carte actuelle
    func showAnswer() {
        isShowingAnswer = true
    }
    
    /// Évalue la carte actuelle
    func rateCard(_ rating: ReviewRating) {
        guard let currentCard = currentCard, var session = currentSession else { return }
        
        // Enregistrer cette révision
        let review = CardReview(
            cardID: currentCard.id,
            rating: rating,
            timeSpent: 0, // À implémenter avec un timer
            timestamp: Date()
        )
        
        session.reviews.append(review)
        self.currentSession = session
        
        // Mettre à jour les statistiques de la carte
        Task {
            do {
                try await cardService.updateReviewForCard(currentCard, rating: rating)
                
                await MainActor.run {
                    self.completedCount += 1
                    
                    // Si option de répétition, remettre en jeu selon la note
                    if studyOptions.shouldRepeatDifficult && (rating == .again || rating == .hard) {
                        // Remettre la carte à la fin du paquet ou à une position aléatoire
                        let updatedCard = currentCard.withUpdatedReview(rating: rating)
                        if studyOptions.shouldShuffle {
                            let randomPosition = min(Int.random(in: 1...max(1, remainingCards.count)), remainingCards.count)
                            remainingCards.insert(updatedCard, at: randomPosition)
                        } else {
                            remainingCards.append(updatedCard)
                        }
                    }
                    
                    // Passer à la carte suivante
                    self.nextCard()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors de la mise à jour de la carte: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupSession(deckId: UUID, cards: [Card]) {
        // Filtrer les cartes dues pour révision
        let dueCards = cards.filter { $0.isDue }
        
        // Si pas de cartes dues, prendre quelques nouvelles cartes
        let cardsForStudy = dueCards.isEmpty 
            ? Array(cards.filter { $0.isNew }.prefix(10)) 
            : dueCards
        
        guard !cardsForStudy.isEmpty else {
            error = "Ce paquet ne contient pas de cartes à étudier maintenant."
            isLoading = false
            return
        }
        
        // Créer une nouvelle session
        let session = StudySession(
            id: UUID(),
            deckId: deckId,
            startTime: Date()
        )
        
        currentSession = session
        cardsToStudy = cardsForStudy.shuffled()
        currentCardIndex = 0
        isStudying = true
        sessionStats = SessionStats()
        isLoading = false
        
        // Commencer le chronométrage de la première carte
        startCardReview()
    }
    
    private func clearSession() {
        currentSession = nil
        currentCard = nil
        sessionCards = []
        remainingCards = []
        completedCount = 0
        isShowingAnswer = false
    }
}

// MARK: - Errors
enum StudyError: Error, LocalizedError {
    case deckEmpty
    case dataError(String)
    
    var errorDescription: String? {
        switch self {
        case .deckEmpty:
            return "Ce paquet ne contient pas de cartes à étudier maintenant."
        case .dataError(let message):
            return "Erreur de données: \(message)"
        }
    }
}

// MARK: - Session Statistics
extension StudyViewModel {
    struct SessionStats {
        var cardsReviewed: Int = 0
        var correctAnswers: Int = 0
        var incorrectAnswers: Int = 0
        
        var successRate: Double {
            guard cardsReviewed > 0 else { return 0 }
            return Double(correctAnswers) / Double(cardsReviewed) * 100.0
        }
    }
}

// MARK: - Preview
extension StudyViewModel {
    static var preview: StudyViewModel {
        let viewModel = StudyViewModel()
        viewModel.cardsToStudy = Card.sampleData
        viewModel.isStudying = true
        viewModel.currentSession = StudySession.sampleData.first
        return viewModel
    }
}

/// Options pour une session d'étude
struct StudyOptions {
    var cardFilter: CardFilterOption = .due
    var cardLimit: Int? = 20
    var shouldShuffle: Bool = true
    var shouldRepeatDifficult: Bool = true
    var showStats: Bool = true
} 