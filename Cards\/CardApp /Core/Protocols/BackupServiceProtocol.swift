import Foundation
import Combine

/// Résultat d'une opération de sauvegarde
public struct BackupResult {
    public let url: URL
    public let date: Date
    public let size: Int64
    
    public init(url: URL, date: Date = Date(), size: Int64 = 0) {
        self.url = url
        self.date = date
        self.size = size
    }
}

/// Protocole pour le service de sauvegarde
public protocol BackupServiceProtocol {
    /// Crée une sauvegarde des données
    func createBackup() async throws -> BackupResult
    
    /// Restaure une sauvegarde depuis une URL
    func restoreBackup(from url: URL) async throws
    
    /// Récupère la liste des sauvegardes disponibles
    func fetchAllBackups() async -> [BackupResult]
    
    /// Récupère la date de la dernière sauvegarde
    func fetchLastBackupDate() -> Date?
    
    /// Supprime une sauvegarde spécifique
    func deleteBackup(at url: URL) async throws
    
    /// Configure les sauvegardes automatiques
    func configureAutoBackup(enabled: Bool, interval: TimeInterval?, retentionDays: Int?)
}

// MARK: - Types Associés (Exemples)

/// Informations sur une sauvegarde spécifique.
struct BackupInfo: Identifiable {
    let id: UUID
    let date: Date
    let url: URL
    let size: Int64 // Taille en octets
}

/// Fréquence des sauvegardes automatiques.
enum BackupFrequency {
    case daily
    case weekly
    case monthly
}

/// Politique de rétention des sauvegardes.
enum BackupRetentionPolicy {
    case keepLast(Int) // Garder les N dernières sauvegardes
    case keepForDays(Int) // Garder les sauvegardes des N derniers jours
}

/// Configuration des sauvegardes automatiques.
struct AutoBackupConfig {
    let isEnabled: Bool
    let frequency: BackupFrequency
    let retentionPolicy: BackupRetentionPolicy
}

/// Options pour la sauvegarde automatique (rendue publique)
public struct AutoBackupOptions {
    public enum Frequency {
        case daily, weekly, monthly
    }
    
    public var frequency: Frequency
    public var destinationURL: URL? // Si nil, utilise un emplacement par défaut
    public var maxBackupsToKeep: Int? // Si nil, conserve toutes les sauvegardes
} 