import Foundation

/// Configuration du module Core
public enum Core {
    /// Version du module
    public static let version = "1.0.0"
    
    /// Namespace pour les modèles
    public enum Models {}
    
    /// Namespace pour les services
    public enum Services {}
    
    /// Namespace pour les protocoles
    public enum Protocols {}
    
    /// Namespace pour les erreurs
    public enum Errors {}
}

// Note: CoreError est défini dans Core/Common/Errors.swift 