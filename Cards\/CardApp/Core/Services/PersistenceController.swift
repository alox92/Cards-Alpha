import CoreData

/// Contrôleur responsable de la persistance des données avec Core Data
struct PersistenceController {
    // MARK: - Propriétés
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    // MARK: - Initialisation
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Cards")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Erreur lors du chargement de Core Data: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Prévisualisation
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        // Créer des données de prévisualisation
        let context = controller.container.viewContext

        // Créer des paquets
        let deck1 = DeckEntity(context: context)
        deck1.id = UUID()
        deck1.name = "Langues"
        deck1.icon = "text.bubble"
        deck1.colorName = "blue"
        deck1.createdAt = Date()

        let deck2 = DeckEntity(context: context)
        deck2.id = UUID()
        deck2.name = "Histoire"
        deck2.icon = "book.closed"
        deck2.colorName = "orange"
        deck2.createdAt = Date()

        // Créer des cartes pour le paquet Langues
        let cards1 = [
            ("Bonjour", "Hello", "new"),
            ("Au revoir", "Goodbye", "learning"),
            ("Merci", "Thank you", "reviewing"),
            ("S'il vous plaît", "Please", "mastered")
        ]

        for (front, back, level) in cards1 {
            let card = CardEntity(context: context)
            card.id = UUID()
            card.question = front
            card.answer = back
            card.deck = deck1
            card.masteryLevel = level
            card.createdAt = Date()
            card.nextReviewDate = Date().addingTimeInterval(Double.random(in: 0...7) * 24 * 60 * 60)
            card.reviewCount = Int16.random(in: 0...10)
            card.correctCount = Int16.random(in: 0...Int16(card.reviewCount))
            card.lastReviewedAt = Date().addingTimeInterval(-24 * 60 * 60)
        }

        // Créer des cartes pour le paquet Histoire
        let cards2 = [
            ("Première Guerre mondiale", "1914-1918", "new"),
            ("Révolution française", "1789", "learning"),
            ("Chute du mur de Berlin", "1989", "reviewing"),
            ("Indépendance des États-Unis", "1776", "mastered")
        ]

        for (front, back, level) in cards2 {
            let card = CardEntity(context: context)
            card.id = UUID()
            card.question = front
            card.answer = back
            card.deck = deck2
            card.masteryLevel = level
            card.createdAt = Date()
            card.nextReviewDate = Date().addingTimeInterval(Double.random(in: 0...7) * 24 * 60 * 60)
            card.reviewCount = Int16.random(in: 0...10)
            card.correctCount = Int16.random(in: 0...Int16(card.reviewCount))
            card.lastReviewedAt = Date().addingTimeInterval(-48 * 60 * 60)
        }

        do {
            try context.save()
        } catch {
            fatalError("Erreur lors de la sauvegarde des données de prévisualisation: \(error.localizedDescription)")
        }

        return controller
    }()

    // MARK: - Méthodes publiques
    /// Sauvegarde les modifications du contexte
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Erreur lors de la sauvegarde du contexte: \(nsError), \(nsError.userInfo)")
            }
        }
    }
} 