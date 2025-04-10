import Foundation
import CoreData

struct SimplifiedPersistenceController {
    static let shared = SimplifiedPersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "CardApp")
        
        // Configuration simplifiée pour les tests
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Erreur lors du chargement du store CoreData: \(error), \(error.userInfo)")
            }
        }
    }
}
