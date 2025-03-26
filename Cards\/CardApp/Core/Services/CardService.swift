import Foundation
import CoreData
import Combine
import SwiftUI

/// Service responsable des opérations sur les cartes et les paquets
class CardService {
    // MARK: - Propriétés
    private let context: NSManagedObjectContext
    
    // MARK: - Initialisation
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Méthodes pour les cartes
    
    /// Récupère toutes les cartes ou les cartes d'un paquet spécifique
    func fetchCards(for deck: Deck? = nil) async throws -> [Card] {
        let request = NSFetchRequest<CardEntity>(entityName: "CardEntity")
        
        if let deck = deck {
            request.predicate = NSPredicate(format: "deck.id == %@", deck.id as CVarArg)
        }
        
        let entities = try context.fetch(request)
        return entities.compactMap { entity -> Card? in
            guard let id = entity.id,
                  let question = entity.question,
                  let answer = entity.answer else {
                return nil
            }
            
            let masteryLevel = MasteryLevel(rawValue: entity.masteryLevel ?? "") ?? .new
            let tags = entity.tags?.components(separatedBy: ",") ?? []
            
            return Card(
                id: id,
                question: question,
                answer: answer,
                additionalInfo: entity.additionalInfo,
                deckID: entity.deck?.id,
                createdAt: entity.createdAt ?? Date(),
                updatedAt: entity.updatedAt ?? Date(),
                masteryLevel: masteryLevel,
                reviewCount: Int(entity.reviewCount),
                lastReviewedAt: entity.lastReviewedAt,
                nextReviewDate: entity.nextReviewDate,
                tags: tags,
                isFlagged: entity.isFlagged,
                correctCount: Int(entity.correctCount),
                incorrectCount: Int(entity.incorrectCount)
            )
        }
    }
    
    /// Crée une nouvelle carte
    func createCard(front: String, back: String, in deck: Deck, additionalInfo: String? = nil, tags: [String] = []) async throws -> Card {
        // Créer la nouvelle entité
        let cardEntity = CardEntity(context: context)
        cardEntity.id = UUID()
        cardEntity.question = front
        cardEntity.answer = back
        cardEntity.additionalInfo = additionalInfo
        cardEntity.createdAt = Date()
        cardEntity.updatedAt = Date()
        cardEntity.masteryLevel = MasteryLevel.new.rawValue
        cardEntity.reviewCount = 0
        cardEntity.correctCount = 0
        cardEntity.incorrectCount = 0
        cardEntity.tags = tags.joined(separator: ",")
        cardEntity.isFlagged = false
        
        // Associer au paquet
        let deckRequest = NSFetchRequest<DeckEntity>(entityName: "DeckEntity")
        deckRequest.predicate = NSPredicate(format: "id == %@", deck.id as CVarArg)
        let deckEntities = try context.fetch(deckRequest)
        
        if let deckEntity = deckEntities.first {
            cardEntity.deck = deckEntity
        } else {
            throw NSError(domain: "CardService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Paquet non trouvé"])
        }
        
        // Sauvegarder les changements
        try context.save()
        
        // Construire et retourner la carte
        return Card(
            id: cardEntity.id!,
            question: front,
            answer: back,
            additionalInfo: additionalInfo,
            deckID: deck.id,
            createdAt: cardEntity.createdAt!,
            updatedAt: cardEntity.updatedAt!,
            masteryLevel: .new,
            reviewCount: 0,
            tags: tags,
            correctCount: 0,
            incorrectCount: 0
        )
    }
    
    /// Met à jour une carte existante
    func updateCard(_ card: Card) async throws {
        let request = NSFetchRequest<CardEntity>(entityName: "CardEntity")
        request.predicate = NSPredicate(format: "id == %@", card.id as CVarArg)
        
        let entities = try context.fetch(request)
        
        guard let entity = entities.first else {
            throw NSError(domain: "CardService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Carte non trouvée"])
        }
        
        entity.question = card.question
        entity.answer = card.answer
        entity.additionalInfo = card.additionalInfo
        entity.updatedAt = Date()
        entity.tags = card.tags.joined(separator: ",")
        entity.isFlagged = card.isFlagged
        
        try context.save()
    }
    
    /// Met à jour les statistiques de révision d'une carte
    func updateReviewForCard(_ card: Card, rating: ReviewRating) async throws {
        let request = NSFetchRequest<CardEntity>(entityName: "CardEntity")
        request.predicate = NSPredicate(format: "id == %@", card.id as CVarArg)
        
        let entities = try context.fetch(request)
        
        guard let entity = entities.first else {
            throw NSError(domain: "CardService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Carte non trouvée"])
        }
        
        // Mettre à jour les statistiques
        let isCorrect = rating == .good || rating == .easy
        entity.reviewCount += 1
        
        if isCorrect {
            entity.correctCount += 1
        } else {
            entity.incorrectCount += 1
        }
        
        entity.lastReviewedAt = Date()
        
        // Calculer le nouveau niveau de maîtrise
        let currentLevel = MasteryLevel(rawValue: entity.masteryLevel ?? "") ?? .new
        let newLevel: MasteryLevel
        
        switch (currentLevel, rating) {
        case (_, .again):
            newLevel = .new
        case (.new, .hard), (.new, .good):
            newLevel = .learning
        case (.learning, .hard):
            newLevel = .learning
        case (.learning, .good), (.learning, .easy):
            newLevel = .reviewing
        case (.reviewing, .hard):
            newLevel = .learning
        case (.reviewing, .good):
            newLevel = .reviewing
        case (.reviewing, .easy), (.mastered, _):
            newLevel = .mastered
        default:
            newLevel = currentLevel
        }
        
        entity.masteryLevel = newLevel.rawValue
        
        // Calculer la prochaine date de révision
        let nextReview: Date
        
        switch (newLevel, rating) {
        case (.new, _):
            nextReview = Date().addingTimeInterval(1 * 3600) // 1 heure
        case (.learning, .hard):
            nextReview = Date().addingTimeInterval(12 * 3600) // 12 heures
        case (.learning, .good):
            nextReview = Date().addingTimeInterval(24 * 3600) // 1 jour
        case (.learning, .easy):
            nextReview = Date().addingTimeInterval(2 * 24 * 3600) // 2 jours
        case (.reviewing, .hard):
            nextReview = Date().addingTimeInterval(3 * 24 * 3600) // 3 jours
        case (.reviewing, .good):
            nextReview = Date().addingTimeInterval(7 * 24 * 3600) // 1 semaine
        case (.reviewing, .easy):
            nextReview = Date().addingTimeInterval(14 * 24 * 3600) // 2 semaines
        case (.mastered, _):
            nextReview = Date().addingTimeInterval(30 * 24 * 3600) // 1 mois
        default:
            nextReview = Date().addingTimeInterval(24 * 3600) // 1 jour par défaut
        }
        
        entity.nextReviewDate = nextReview
        
        try context.save()
    }
    
    // MARK: - Méthodes pour les paquets
    
    /// Récupère tous les paquets
    func fetchDecks() async throws -> [Deck] {
        let request = NSFetchRequest<DeckEntity>(entityName: "DeckEntity")
        let entities = try context.fetch(request)
        
        return entities.compactMap { entity -> Deck? in
            guard let id = entity.id,
                  let name = entity.name else {
                return nil
            }
            
            // Créer le paquet
            var deck = Deck(
                id: id,
                name: name,
                description: entity.descriptionText ?? "",
                icon: entity.icon ?? "rectangle.stack",
                colorName: entity.colorName ?? "blue",
                createdAt: entity.createdAt ?? Date(),
                updatedAt: entity.updatedAt ?? Date()
            )
            
            // Ajouter les statistiques du paquet
            if let cards = entity.cards as? Set<CardEntity> {
                deck.totalCards = cards.count
                
                deck.newCards = cards.filter { ($0.masteryLevel ?? "") == MasteryLevel.new.rawValue }.count
                deck.learningCards = cards.filter { ($0.masteryLevel ?? "") == MasteryLevel.learning.rawValue }.count
                deck.reviewingCards = cards.filter { ($0.masteryLevel ?? "") == MasteryLevel.reviewing.rawValue }.count
                deck.masteredCards = cards.filter { ($0.masteryLevel ?? "") == MasteryLevel.mastered.rawValue }.count
                
                // Cartes dues (avec une date de révision dans le passé)
                deck.dueCards = cards.filter { card in
                    if let nextReview = card.nextReviewDate {
                        return nextReview <= Date()
                    }
                    return ($0.masteryLevel ?? "") == MasteryLevel.new.rawValue
                }.count
            }
            
            return deck
        }
    }
    
    // MARK: - Méthodes pour les sessions d'étude
    
    /// Sauvegarde une session d'étude
    func saveStudySession(_ session: StudySession) async throws {
        let entity = StudySessionEntity(context: context)
        entity.id = session.id
        entity.deckID = session.deckId
        entity.startTime = session.startTime
        entity.endTime = session.endTime
        
        // Convertir les révisions en données JSON
        if !session.reviews.isEmpty {
            let encoder = JSONEncoder()
            entity.reviewsData = try encoder.encode(session.reviews)
        }
        
        try context.save()
    }
    
    /// Récupère l'historique des sessions d'étude
    func fetchStudySessions() async throws -> [StudySession] {
        let request = NSFetchRequest<StudySessionEntity>(entityName: "StudySessionEntity")
        let entities = try context.fetch(request)
        
        return entities.compactMap { entity -> StudySession? in
            guard let id = entity.id,
                  let deckID = entity.deckID,
                  let startTime = entity.startTime else {
                return nil
            }
            
            var reviews: [CardReview] = []
            
            // Décoder les révisions
            if let reviewsData = entity.reviewsData {
                let decoder = JSONDecoder()
                if let decodedReviews = try? decoder.decode([CardReview].self, from: reviewsData) {
                    reviews = decodedReviews
                }
            }
            
            return StudySession(
                id: id,
                deckId: deckID,
                startTime: startTime,
                endTime: entity.endTime,
                reviews: reviews
            )
        }
    }
}

// MARK: - MediaItem pour la gestion des médias
struct MediaItem: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let type: MediaType
    
    enum MediaType: String {
        case image
        case audio
        case video
    }
}

// MARK: - Preview
extension CardService {
    static var preview: CardService {
        let service = CardService(context: PersistenceController.preview.container.viewContext)
        return service
    }
} 