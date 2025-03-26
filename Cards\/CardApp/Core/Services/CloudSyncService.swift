import Foundation
import CoreData
import CloudKit

class CloudSyncService {
    static let shared = CloudSyncService()
    
    private let container: NSPersistentCloudKitContainer
    private let cloudContainerIdentifier = "iCloud.com.votreapp.cartes"
    
    private init() {
        container = NSPersistentCloudKitContainer(name: "CardsDataModel")
        
        // Configuration pour iCloud
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Impossible de récupérer la description du store persistant")
        }
        
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: cloudContainerIdentifier
        )
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Erreur lors du chargement du persistent store: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        setupNotifications()
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
        
        // Observer les changements de disponibilité iCloud
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accountStatusChanged),
            name: NSNotification.Name.CKAccountChanged,
            object: nil
        )
    }
    
    @objc private func storeRemoteChange(_ notification: Notification) {
        // Traitement des modifications distantes
        print("Modification distante détectée dans iCloud")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("CloudDataDidChange"),
                object: nil
            )
        }
    }
    
    @objc private func accountStatusChanged(_ notification: Notification) {
        checkCloudStatus()
    }
    
    // MARK: - Status
    
    func checkCloudStatus(completion: ((Bool, Error?) -> Void)? = nil) {
        CKContainer(identifier: cloudContainerIdentifier).accountStatus { status, error in
            var isAvailable = false
            
            switch status {
            case .available:
                isAvailable = true
                print("iCloud disponible")
            case .noAccount:
                print("Pas de compte iCloud")
            case .restricted:
                print("iCloud restreint")
            case .couldNotDetermine:
                print("Impossible de déterminer le statut iCloud")
            @unknown default:
                print("Statut iCloud inconnu")
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("CloudStatusDidChange"),
                    object: nil,
                    userInfo: ["isAvailable": isAvailable]
                )
                
                completion?(isAvailable, error)
            }
        }
    }
    
    // MARK: - Synchronisation manuelle
    
    func forceSynchronization() {
        do {
            try container.initializeCloudKitSchema(options: [])
            print("Synchronisation iCloud initialisée")
        } catch {
            print("Erreur lors de l'initialisation de la synchronisation: \(error)")
        }
    }
    
    // MARK: - Accès au contexte
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
}

// MARK: - Extensions pour faciliter l'accès
extension NSManagedObjectContext {
    var cloudContext: NSManagedObjectContext {
        return CloudSyncService.shared.viewContext
    }
} 