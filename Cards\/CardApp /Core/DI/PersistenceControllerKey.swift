import Foundation
import SwiftUI
import CoreData

/// Clé d'environnement pour accéder au PersistenceController
public struct PersistenceControllerKey: EnvironmentKey {
    /// Valeur par défaut (on utilise une instance en mémoire qui sera remplacée)
    public static let defaultValue: PersistenceController = {
        // Créer une instance en mémoire qui sera remplacée plus tard
        let result = PersistenceController(inMemory: true)
        return result
    }()
}

/// Wrapper non-isolé pour fournir le PersistenceController
@objc public class PersistenceControllerWrapper: NSObject, @unchecked Sendable {
    public static let shared = PersistenceControllerWrapper()
    
    private override init() {
        self.persistenceController = PersistenceController(inMemory: true)
        super.init()
    }
    
    let persistenceController: PersistenceController
}

/// Extension pour ajouter le PersistenceController à l'environnement
public extension EnvironmentValues {
    var persistenceController: PersistenceController {
        get { self[PersistenceControllerKey.self] }
        set { self[PersistenceControllerKey.self] = newValue }
    }
} 