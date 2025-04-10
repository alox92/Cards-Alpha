import Foundation
import CoreData

/// Protocole définissant les opérations du contrôleur de persistance
@MainActor
public protocol PersistenceControllerProtocol: Sendable {
    var container: NSPersistentContainer { get }
    func save() async throws
    func reset() async throws
    func newBackgroundContext() -> NSManagedObjectContext
}

/// Contrôleur de persistance principal pour CoreData
@MainActor
public final class PersistenceController: PersistenceControllerProtocol, @unchecked Sendable {
    /// Instance partagée du contrôleur (singleton)
    public static let shared = PersistenceController()
    
    /// Conteneur de persistance CoreData
    public let container: NSPersistentContainer
    
    /// Crée une instance du contrôleur avec un magasin en mémoire ou sur disque
    /// - Parameter inMemory: Si true, utilise un magasin en mémoire (pour les prévisualisations et tests)
    public init(inMemory: Bool = false) {
        // Créer le conteneur
        container = NSPersistentContainer(name: "CardApp")
        
        // Configurer le magasin
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configurer la migration automatique
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        
        // Charger les magasins persistants
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Erreur lors du chargement des données : \(error.localizedDescription)")
            }
        }
        
        // Configurer les options de fusion
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Utiliser une version concurrency-safe de la politique de fusion
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    /// Sauvegarde les changements du contexte principal
    public func save() async throws {
        let context = container.viewContext
        if context.hasChanges {
            try context.save()
        }
    }
    
    /// Réinitialise la base de données
    public func reset() async throws {
        // Supprimer tous les magasins existants
        try container.persistentStoreCoordinator.persistentStores.forEach { store in
            try container.persistentStoreCoordinator.remove(store)
        }
        
        // Supprimer les fichiers de base de données
        try container.persistentStoreDescriptions.forEach { description in
            if let url = description.url {
                try FileManager.default.removeItem(at: url)
            }
        }
        
        // Recharger les magasins
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Erreur lors de la réinitialisation : \(error.localizedDescription)")
            }
        }
    }
    
    /// Crée un nouveau contexte en arrière-plan
    public func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
} 