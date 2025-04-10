import Foundation
import CoreData

/// Utilitaire pour gérer la migration entre modèles CoreData
public class CoreDataMigration {
    
    /// Vérifie si une migration est nécessaire
    public static func isMigrationNeeded() -> Bool {
        guard let storeURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Core/Core.sqlite") else {
            return false
        }
        
        // Vérifier si le magasin existe
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return false
        }
        
        do {
            // Vérifier la compatibilité du modèle
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType, 
                at: storeURL
            )
            
            let model = NSManagedObjectModel.mergedModel(from: [Bundle.main])
            return !(model?.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) ?? false)
        } catch {
            print("Erreur lors de la vérification de migration: \(error.localizedDescription)")
            return true
        }
    }
    
    /// Effectue la migration entre les modèles
    public static func migrateStore(completion: @escaping (Bool) -> Void) {
        // Implémentation à compléter en fonction des besoins spécifiques
        // Cette méthode devrait:
        // 1. Sauvegarder les données existantes
        // 2. Supprimer l'ancien magasin
        // 3. Créer un nouveau magasin avec le modèle cible
        // 4. Transférer les données selon un mappage
        
        // Exemple simplifié (à adapter):
        DispatchQueue.global(qos: .background).async {
            do {
                // Chemins des magasins
                let fileManager = FileManager.default
                let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                
                let sourceStoreURL = applicationSupportURL.appendingPathComponent("Core/Core.sqlite")
                let targetStoreURL = applicationSupportURL.appendingPathComponent("CardApp/CardApp.sqlite")
                
                // Charger les données actuelles
                // ... (code pour extraire les données)
                
                // Supprimer l'ancien magasin si nécessaire
                if fileManager.fileExists(atPath: sourceStoreURL.path) {
                    try fileManager.removeItem(at: sourceStoreURL)
                }
                
                // Créer le nouveau conteneur et importer les données
                // ... (code pour importer les données)
                
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("Erreur pendant la migration: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
}
