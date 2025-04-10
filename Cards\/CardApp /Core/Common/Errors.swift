import Foundation

// MARK: - App Error
public struct AppError: Error, Identifiable {
    public let id = UUID()
    let message: String
    let type: AppErrorType
    
    public init(message: String, type: AppErrorType = .general) {
        self.message = message
        self.type = type
    }
    
    public init(error: Error) {
        self.message = error.localizedDescription
        self.type = .general
    }
    
    public var title: String {
        switch type {
        case .network: return "Erreur réseau"
        case .data: return "Erreur de données"
        case .auth: return "Erreur d'authentification"
        case .general: return "Erreur"
        }
    }
    
    public static func dataError(_ message: String) -> AppError {
        AppError(message: message, type: .data)
    }
    
    public static func networkError(_ message: String) -> AppError {
        AppError(message: message, type: .network)
    }
}

public enum AppErrorType: Sendable {
    case network
    case data
    case auth
    case general
}

/// Erreurs communes du module Core
public enum CoreError: LocalizedError {
    case invalidData
    case entityNotFound
    case persistenceError(Error)
    case networkError(Error)
    case validationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Les données sont invalides"
        case .entityNotFound:
            return "L'entité n'a pas été trouvée"
        case .persistenceError(let error):
            return "Erreur de persistance : \(error.localizedDescription)"
        case .networkError(let error):
            return "Erreur réseau : \(error.localizedDescription)"
        case .validationError(let message):
            return "Erreur de validation : \(message)"
        }
    }
}

/// Erreurs spécifiques au service de cartes
public enum CardServiceError: LocalizedError {
    case cardNotFound
    case invalidCardData
    case duplicateCard
    case cardUpdateFailed
    case cardDeletionFailed
    
    public var errorDescription: String? {
        switch self {
        case .cardNotFound:
            return "La carte n'a pas été trouvée"
        case .invalidCardData:
            return "Les données de la carte sont invalides"
        case .duplicateCard:
            return "Une carte avec cet identifiant existe déjà"
        case .cardUpdateFailed:
            return "La mise à jour de la carte a échoué"
        case .cardDeletionFailed:
            return "La suppression de la carte a échoué"
        }
    }
}

/// Erreurs spécifiques au service de paquets
public enum DeckServiceError: LocalizedError {
    case deckNotFound
    case invalidDeckData
    case duplicateDeck
    case deckUpdateFailed
    case deckDeletionFailed
    case circularReference
    
    public var errorDescription: String? {
        switch self {
        case .deckNotFound:
            return "Le paquet n'a pas été trouvé"
        case .invalidDeckData:
            return "Les données du paquet sont invalides"
        case .duplicateDeck:
            return "Un paquet avec cet identifiant existe déjà"
        case .deckUpdateFailed:
            return "La mise à jour du paquet a échoué"
        case .deckDeletionFailed:
            return "La suppression du paquet a échoué"
        case .circularReference:
            return "Référence circulaire détectée dans la hiérarchie des paquets"
        }
    }
}

/// Erreurs spécifiques au service de tags
public enum TagServiceError: LocalizedError {
    case tagNotFound
    case invalidTagData
    case duplicateTag
    case tagUpdateFailed
    case tagDeletionFailed
    
    public var errorDescription: String? {
        switch self {
        case .tagNotFound:
            return "Le tag n'a pas été trouvé"
        case .invalidTagData:
            return "Les données du tag sont invalides"
        case .duplicateTag:
            return "Un tag avec cet identifiant existe déjà"
        case .tagUpdateFailed:
            return "La mise à jour du tag a échoué"
        case .tagDeletionFailed:
            return "La suppression du tag a échoué"
        }
    }
}

/// Erreurs du service d'étude
public enum StudyServiceError: Error, LocalizedError {
    case persistenceError(Error)
    case deckNotFound
    case cardNotFound
    case sessionNotFound
    case invalidSessionData
    case sessionAlreadyStarted
    case sessionNotInProgress
    case invalidData
    case noActiveSession
    case cardAlreadyReviewed
    
    public var errorDescription: String? {
        switch self {
        case .persistenceError(let error):
            return "Erreur de persistance : \(error.localizedDescription)"
        case .deckNotFound:
            return "Paquet non trouvé"
        case .cardNotFound:
            return "Carte non trouvée"
        case .sessionNotFound:
            return "Session non trouvée"
        case .invalidSessionData:
            return "Données de session invalides"
        case .sessionAlreadyStarted:
            return "Une session est déjà en cours"
        case .sessionNotInProgress:
            return "Aucune session en cours"
        case .invalidData:
            return "Données invalides"
        case .noActiveSession:
            return "Aucune session active"
        case .cardAlreadyReviewed:
            return "Cette carte a déjà été révisée"
        }
    }
} 