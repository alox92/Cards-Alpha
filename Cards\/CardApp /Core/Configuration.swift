import Foundation

/// Configuration du module Core
public enum CoreConfiguration {
    /// Version du module
    public static let version = "1.0.0"
    
    /// Namespace pour les modèles
    public enum Models {
        /// Chemin vers les modèles de données
        public static let dataPath = "Models/Data"
        
        /// Chemin vers les modèles communs
        public static let commonPath = "Models/Common"
    }
    
    /// Namespace pour les services
    public enum Services {
        /// Chemin vers les services de base
        public static let basePath = "Services"
        
        /// Chemin vers les services de données
        public static let dataPath = "Services/Data"
    }
    
    /// Namespace pour les ressources
    public enum Resources {
        /// Chemin vers les ressources
        public static let path = "Resources"
    }
}

// Note: CoreError est défini dans Core/Common/Errors.swift 