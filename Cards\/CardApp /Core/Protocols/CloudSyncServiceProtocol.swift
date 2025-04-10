import Foundation
import Combine
import CoreData

/// Protocole pour le service de synchronisation cloud
public protocol CloudSyncServiceProtocol: SyncServiceProtocol {
    /// Indique si la synchronisation est activée
    var isSyncEnabled: Bool { get }
    
    /// Indique si l'utilisateur est connecté à iCloud
    var isUserSignedIn: Bool { get }
    
    /// Dernière date de synchronisation
    var lastSyncDate: Date? { get }
    
    /// Active ou désactive la synchronisation
    func setSyncEnabled(_ enabled: Bool)
    
    /// Vérifie le statut de connexion iCloud
    func checkCloudAccountStatus() async -> Bool
    
    /// Éditeur pour observer le statut de connexion iCloud
    var cloudAccountStatusPublisher: AnyPublisher<Bool, Never> { get }
}

/// Service de synchronisation via CloudKit
@preconcurrency
public class CloudSyncService: CloudSyncServiceProtocol, @unchecked Sendable {
    private let persistentContainer: NSPersistentCloudKitContainer
    private let cloudContainerIdentifier: String
    
    private var _status: SyncStatus = .idle
    private let statusSubject = CurrentValueSubject<SyncStatus, Never>(.idle)
    private let accountStatusSubject = CurrentValueSubject<Bool, Never>(false)
    
    public var status: SyncStatus {
        return _status
    }
    
    public var statusPublisher: AnyPublisher<SyncStatus, Never> {
        return statusSubject.eraseToAnyPublisher()
    }
    
    public var cloudAccountStatusPublisher: AnyPublisher<Bool, Never> {
        return accountStatusSubject.eraseToAnyPublisher()
    }
    
    public var isAvailable: Bool {
        // Vérifie si CloudKit est disponible sur l'appareil
        return true
    }
    
    public var isUserSignedIn: Bool = false
    public var isSyncEnabled: Bool = true
    public var lastSyncDate: Date? = nil
    
    public init(persistentContainer: NSPersistentCloudKitContainer, cloudContainerIdentifier: String) {
        self.persistentContainer = persistentContainer
        self.cloudContainerIdentifier = cloudContainerIdentifier
        
        // Vérifier le statut du compte au démarrage
        Task { [weak self] in
            guard let self = self else { return }
            let status = await self.checkCloudAccountStatus()
            await MainActor.run {
                self.isUserSignedIn = status
                self.accountStatusSubject.send(status)
            }
        }
    }
    
    public func sync() async throws {
        try await performSync()
    }
    
    public func pull() async throws {
        try await performSync(direction: .pull)
    }
    
    public func push() async throws {
        try await performSync(direction: .push)
    }
    
    public func resolveConflict(_ resolution: ConflictResolution) async throws {
        // Implémenter la résolution de conflits
    }
    
    public func setAutoSync(_ enabled: Bool) {
        // Activer/désactiver la synchronisation automatique
        isSyncEnabled = enabled
        
        // Configurer la synchronisation automatique dans NSPersistentCloudKitContainer
    }
    
    public func setSyncEnabled(_ enabled: Bool) {
        isSyncEnabled = enabled
    }
    
    public func checkCloudAccountStatus() async -> Bool {
        // Simuler une vérification du compte iCloud
        let isSignedIn = true
        self.isUserSignedIn = isSignedIn
        self.accountStatusSubject.send(isSignedIn)
        return isSignedIn
    }
    
    // MARK: - Méthodes privées
    
    private enum SyncDirection {
        case push
        case pull
        case both
    }
    
    private func performSync(direction: SyncDirection = .both) async throws {
        // Mise à jour du statut
        _status = .syncing
        statusSubject.send(.syncing)
        
        do {
            // Simuler une synchronisation
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Mise à jour du statut
            _status = .succeeded
            statusSubject.send(.succeeded)
            lastSyncDate = Date()
        } catch {
            let syncError: SyncError
            
            // Convertir l'erreur en SyncError
            if let nsError = error as NSError? {
                switch nsError.domain {
                case NSCocoaErrorDomain:
                    if nsError.code == NSUserCancelledError {
                        syncError = .notAuthenticated
                    } else {
                        syncError = .cloudKitError(nsError)
                    }
                default:
                    syncError = .unknown(nsError)
                }
            } else {
                syncError = .unknown(error)
            }
            
            // Mise à jour du statut d'erreur
            _status = .error(syncError)
            statusSubject.send(.error(syncError))
            
            throw syncError
        }
    }
} 