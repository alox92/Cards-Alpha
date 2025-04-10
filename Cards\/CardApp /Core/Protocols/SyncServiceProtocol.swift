import Foundation
import Combine
import CoreData

/// Erreurs possibles du service de synchronisation
public enum SyncError: Error, LocalizedError {
    case cloudKitError(Error)
    case connectionError(Error)
    case mergeConflict
    case notAuthenticated
    case permissionDenied
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .cloudKitError(let error):
            return "Erreur CloudKit: \(error.localizedDescription)"
        case .connectionError(let error):
            return "Erreur de connexion: \(error.localizedDescription)"
        case .mergeConflict:
            return "Conflit lors de la fusion des données"
        case .notAuthenticated:
            return "Non authentifié"
        case .permissionDenied:
            return "Permission refusée"
        case .unknown(let error):
            return "Erreur inconnue lors de la synchronisation: \(error.localizedDescription)"
        }
    }
}

/// État actuel de la synchronisation
public enum SyncStatus {
    case idle
    case syncing
    case error(SyncError)
    case succeeded
}

/// Protocole définissant le service de synchronisation
public protocol SyncServiceProtocol {
    /// État actuel de la synchronisation
    var status: SyncStatus { get }
    
    /// Publisher pour l'état de synchronisation
    var statusPublisher: AnyPublisher<SyncStatus, Never> { get }
    
    /// Vérifie si la synchronisation est disponible
    var isAvailable: Bool { get }
    
    /// Démarre la synchronisation
    func sync() async throws
    
    /// Récupère les dernières modifications depuis le cloud
    func pull() async throws
    
    /// Envoie les modifications locales vers le cloud
    func push() async throws
    
    /// Résout un conflit de synchronisation
    func resolveConflict(_ resolution: ConflictResolution) async throws
    
    /// Active ou désactive la synchronisation automatique
    func setAutoSync(_ enabled: Bool)
}

/// Résolution d'un conflit de synchronisation
public enum ConflictResolution {
    case useLocal
    case useCloud
    case merge
} 