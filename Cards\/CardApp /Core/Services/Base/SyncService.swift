import Foundation
import Combine
import CoreData

/// Service de synchronisation utilisé comme wrapper pour CloudSyncService
public class SyncService: CloudSyncService, @unchecked Sendable {
    
    /// Initialisation du service
    /// - Parameter persistenceController: Le contrôleur de persistance
    public init(persistenceController: PersistenceController) {
        guard let cloudKitContainer = persistenceController.container as? NSPersistentCloudKitContainer else {
            fatalError("PersistenceController ne fournit pas un NSPersistentCloudKitContainer requis pour CloudSyncService.")
        }
        
        let cloudKitIdentifier = "iCloud.com.app.cardapp"
        super.init(persistentContainer: cloudKitContainer, cloudContainerIdentifier: cloudKitIdentifier)
    }
} 