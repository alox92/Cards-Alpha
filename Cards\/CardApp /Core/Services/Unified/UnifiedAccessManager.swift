// Fichier temporairement désactivé pour permettre la compilation
// Version simplifiée à remplacer par l'implémentation réelle ultérieurement

import Foundation
import os.log
import Combine

@MainActor
public class UnifiedAccessManager {
    private let logger = Logger(subsystem: "com.app.cardapp", category: "UnifiedAccessManager")
    
    public init() {
        logger.debug("Version simplifiée de UnifiedAccessManager pour compilation")
    }
    
    @MainActor
    public static func createDefault() -> UnifiedAccessManager {
        return UnifiedAccessManager()
    }
} 