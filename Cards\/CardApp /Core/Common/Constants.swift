import Foundation

/// Constantes pour la révision des cartes
public enum ReviewConstants {
    /// Durée minimale d'une révision en secondes
    public static let minReviewDuration: TimeInterval = 1.0
    
    /// Durée maximale d'une révision en secondes
    public static let maxReviewDuration: TimeInterval = 3600.0
    
    /// Durée par défaut d'une révision en secondes
    public static let defaultReviewDuration: TimeInterval = 300.0
    
    /// Nombre maximum de cartes par session de révision
    public static let maxCardsPerSession = 50
    
    /// Intervalle minimum entre deux révisions (en heures)
    public static let minReviewInterval: TimeInterval = 4 * 3600
    
    /// Intervalle maximum entre deux révisions (en jours)
    public static let maxReviewInterval: TimeInterval = 365 * 24 * 3600
}

/// Constantes pour la gestion des cartes
public enum CardConstants {
    /// Longueur minimale du contenu d'une carte
    public static let minContentLength = 1
    
    /// Longueur maximale du contenu d'une carte
    public static let maxContentLength = 10000
    
    /// Nombre maximum de tags par carte
    public static let maxTagsPerCard = 10
    
    /// Nombre minimum de cartes par session de révision
    public static let minCardsPerSession = 1
    
    /// Nombre par défaut de cartes par session de révision
    public static let defaultCardsPerSession = 20
    
    /// Longueur maximale du titre d'une carte
    public static let maxCardTitleLength = 100
    
    /// Longueur maximale du contenu d'une carte
    public static let maxCardContentLength = 1000
}

/// Constantes pour la gestion des paquets
public enum DeckConstants {
    /// Longueur minimale du nom d'un paquet
    public static let minNameLength = 1
    
    /// Longueur maximale du nom d'un paquet
    public static let maxNameLength = 100
    
    /// Nombre maximum de cartes par paquet
    public static let maxCardsPerDeck = 10000
    
    /// Nombre maximum de sous-paquets
    public static let maxSubdecks = 100
    
    /// Nombre maximum de paquets par utilisateur
    public static let maxDecksPerUser = 100
    
    /// Longueur maximale du nom d'un paquet
    public static let maxDeckNameLength = 50
    
    /// Longueur maximale de la description d'un paquet
    public static let maxDeckDescriptionLength = 500
}

/// Constantes pour la gestion des tags
public enum TagConstants {
    /// Longueur minimale du nom d'un tag
    public static let minNameLength = 1
    
    /// Longueur maximale du nom d'un tag
    public static let maxNameLength = 50
    
    /// Nombre maximum de tags dans le système
    public static let maxTotalTags = 1000
    
    /// Nombre maximum de tags par item
    public static let maxTagsPerItem = 10
    
    /// Longueur maximale de la description d'un tag
    public static let maxTagDescriptionLength = 200
}

/// Configuration de l'application
public struct AppConfig {
    /// Version de l'application
    public static let version = "1.0.0"
    
    /// Version minimale supportée de la base de données
    public static let minSupportedDBVersion = "1.0.0"
    
    /// Nom du fichier de base de données
    public static let databaseFileName = "cards.sqlite"
    
    /// Nom du fichier de sauvegarde
    public static let backupFileName = "cards_backup.json"
    
    /// Intervalle entre les sauvegardes automatiques (en heures)
    public static let autoBackupInterval: TimeInterval = 24 * 3600
    
    /// Nombre maximum de sauvegardes à conserver
    public static let maxBackupCount = 5
}

/// Constantes pour les applications
public enum AppConstants {
    /// Nom de l'application
    public static let appName = "CardApp"
    
    /// Version de l'application
    public static let appVersion = "1.0.0"
    
    /// Numéro de build de l'application
    public static let appBuild = "1"
    
    /// Identifiant de bundle de l'application
    public static let appBundleID = "com.cardapp"
    
    /// Thème par défaut de l'application
    public static let defaultTheme = "system"
    
    /// Langue par défaut de l'application
    public static let defaultLanguage = "fr"
    
    /// TimeZone par défaut de l'application
    public static let defaultTimeZone = "Europe/Paris"
    
    /// Longueur minimale du mot de passe
    public static let minPasswordLength = 8
    
    /// Longueur maximale du mot de passe
    public static let maxPasswordLength = 32
    
    /// Expression régulière pour le mot de passe
    public static let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
} 