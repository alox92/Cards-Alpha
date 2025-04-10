import Foundation
import CoreData

@MainActor
class CoreDataManager: @unchecked Sendable {
    @MainActor
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Core", managedObjectModel: self.managedObjectModel)
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        guard let modelURL = Bundle.main.url(forResource: "Core", withExtension: "momd") else {
            fatalError("Failed to find data model")
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load data model")
        }
        return model
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
}

// MARK: - Deck Operations
extension CoreDataManager {
    func createDeck(name: String, description: String = "", icon: String = "rectangle.stack.fill", colorName: String = "blue", tags: [String] = []) throws -> DeckEntity {
        let context = viewContext
        let deck = DeckEntity(context: context)
        deck.id = UUID()
        deck.name = name
        deck.desc = description
        deck.icon = icon
        deck.colorName = colorName
        deck.tags = tags
        deck.createdAt = Date()
        deck.updatedAt = Date()
        deck.cardCount = 0
        try context.save()
        return deck
    }
    
    func getDeck(byID id: UUID) throws -> DeckEntity? {
        let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchBatchSize = 20; return try viewContext.fetch(fetchRequest).first
    }
    
    func getAllDecks() throws -> [DeckEntity] {
        let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
        return try viewContext.fetch(fetchRequest)
        fetchRequest.fetchBatchSize = 20    }
    
    func updateDeck(_ deck: DeckEntity) throws {
        deck.updatedAt = Date()
        try viewContext.save()
    }
    
    func deleteDeck(_ deck: DeckEntity) throws {
        viewContext.delete(deck)
        try viewContext.save()
    }
}

// MARK: - Card Operations
extension CoreDataManager {
    func createCard(question: String, answer: String, additionalInfo: String? = nil, deck: DeckEntity, tags: [String] = []) throws -> CardEntity {
        let context = viewContext
        let card = CardEntity(context: context)
        card.id = UUID()
        card.deckID = deck.id
        card.question = question
        card.answer = answer
        card.additionalInfo = additionalInfo
        card.tags = tags
        card.createdAt = Date()
        card.updatedAt = Date()
        card.masteryLevel = 0
        card.interval = 0
        card.ease = 2.5
        card.reviewCount = 0
        card.correctCount = 0
        card.incorrectCount = 0
        card.deck = deck
        try context.save()
        return card
    }
    
    func getCard(byID id: UUID) throws -> CardEntity? {
        let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchBatchSize = 20; return try viewContext.fetch(fetchRequest).first
    }
    
    func getCards(forDeckID deckID: UUID) throws -> [CardEntity] {
        let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "deckID == %@", deckID as CVarArg)
        fetchRequest.fetchBatchSize = 20; return try viewContext.fetch(fetchRequest)
    }
    
    func updateCard(_ card: CardEntity) throws {
        card.updatedAt = Date()
        try viewContext.save()
    }
    
    func deleteCard(_ card: CardEntity) throws {
        viewContext.delete(card)
        try viewContext.save()
    }
}

// MARK: - Study Session Operations
extension CoreDataManager {
    func createStudySession(deck: DeckEntity, includeSubdecks: Bool = false, reviewLimit: Int? = nil) throws -> StudySessionEntity {
        let context = viewContext
        let session = StudySessionEntity(context: context)
        session.id = UUID()
        session.deckID = deck.id
        session.startTime = Date()
        session.includeSubdecks = includeSubdecks
        session.reviewLimit = Int32(reviewLimit ?? 0)
        session.deck = deck
        try context.save()
        return session
    }
    
    func getStudySession(byID id: UUID) throws -> StudySessionEntity? {
        let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchBatchSize = 20; return try viewContext.fetch(fetchRequest).first
    }
    
    func updateStudySession(_ session: StudySessionEntity) throws {
        try viewContext.save()
    }
    
    func deleteStudySession(_ session: StudySessionEntity) throws {
        viewContext.delete(session)
        try viewContext.save()
    }
}

// MARK: - Card Review Operations
extension CoreDataManager {
    func createCardReview(card: CardEntity, session: StudySessionEntity, rating: String, responseTime: Double, newInterval: Int16, newEase: Double, newMasteryLevel: Int16) throws -> CardReviewEntity {
        let context = viewContext
        let review = CardReviewEntity(context: context)
        review.id = UUID()
        review.timestamp = Date()
        review.responseTime = responseTime
        review.rating = rating
        review.newInterval = newInterval
        review.newEase = newEase
        review.newMasteryLevel = newMasteryLevel
        review.card = card
        review.session = session
        try context.save()
        return review
    }
    
    func getCardReview(byID id: UUID) throws -> CardReviewEntity? {
        let fetchRequest: NSFetchRequest<CardReviewEntity> = CardReviewEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchBatchSize = 20; return try viewContext.fetch(fetchRequest).first
    }
    
    func getCardReviews(forCardID cardID: UUID) throws -> [CardReviewEntity] {
        let fetchRequest: NSFetchRequest<CardReviewEntity> = CardReviewEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "card.id == %@", cardID as CVarArg)
        fetchRequest.fetchBatchSize = 20; return try viewContext.fetch(fetchRequest)
    }
    
    func updateCardReview(_ review: CardReviewEntity) throws {
        try viewContext.save()
    }
    
    func deleteCardReview(_ review: CardReviewEntity) throws {
        viewContext.delete(review)
        try viewContext.save()
    }
} 