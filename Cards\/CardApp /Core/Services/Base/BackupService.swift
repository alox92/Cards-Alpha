import Foundation
import Combine
import os.log

/// Service responsable de la gestion des sauvegardes manuelles et automatiques.
public final class BackupService: BackupServiceProtocol {
    
    private let fileManager: FileManager
    private let backupDirectoryURL: URL
    private let logger = Logger(subsystem: "com.app.cardapp", category: "BackupService")
    
    // Dépendances potentielles (pour exporter les données CoreData)
    // private let persistenceController: PersistenceController
    // private let exportService: ImportExportServiceProtocol
    
    // Pour la configuration auto
    private let userDefaults: UserDefaults
    private let autoBackupEnabledKey = "autoBackupEnabled"
    private let autoBackupIntervalKey = "autoBackupInterval"
    private let autoBackupRetentionKey = "autoBackupRetention"
    
    /// Initialisation du service.
    /// - Parameters:
    ///   - fileManager: Le gestionnaire de fichiers à utiliser.
    ///   - userDefaults: UserDefaults pour stocker la configuration.
    public init(fileManager: FileManager = .default, userDefaults: UserDefaults = .standard) {
        self.fileManager = fileManager
        self.userDefaults = userDefaults
        
        // Déterminer le répertoire des sauvegardes (ex: dans Application Support)
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Impossible d'accéder au répertoire Application Support.")
        }
        // Utiliser un sous-dossier spécifique à l'application
        self.backupDirectoryURL = appSupportURL.appendingPathComponent(Bundle.main.bundleIdentifier ?? "CardApp", isDirectory: true).appendingPathComponent("Backups", isDirectory: true)
        
        // Créer le répertoire s'il n'existe pas
        createBackupDirectoryIfNeeded()
        
        logger.info("BackupService initialisé. Répertoire des sauvegardes: \(self.backupDirectoryURL.path)")
    }
    
    /// Crée le répertoire des sauvegardes si nécessaire.
    private func createBackupDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: backupDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: backupDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                logger.info("Répertoire des sauvegardes créé à: \(self.backupDirectoryURL.path)")
            } catch {
                logger.critical("Impossible de créer le répertoire des sauvegardes: \(error.localizedDescription)")
                // Gérer cette erreur critique (ex: empêcher le fonctionnement du service)
            }
        }
    }
    
    // MARK: - BackupServiceProtocol Implementation
    
    /// Crée une sauvegarde des données
    public func createBackup() async throws -> BackupResult {
        logger.debug("Début de la sauvegarde...")
        
        // Créer un nom de fichier unique avec la date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let backupFileName = "backup_\(dateString).zip"
        
        let backupURL = backupDirectoryURL.appendingPathComponent(backupFileName)
        
        // Simuler la création d'une sauvegarde
        // Dans une vraie implémentation, on compresserait les fichiers CoreData et autres données
        try "Contenu de la sauvegarde".data(using: .utf8)?.write(to: backupURL)
        
        // Obtenir la taille du fichier
        let attributes = try FileManager.default.attributesOfItem(atPath: backupURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        logger.info("Sauvegarde créée avec succès: \(backupFileName)")
        return BackupResult(url: backupURL, date: Date(), size: fileSize)
    }
    
    /// Restaure une sauvegarde depuis une URL
    public func restoreBackup(from url: URL) async throws {
        logger.debug("Début de la restauration depuis: \(url.lastPathComponent)")
        
        // Vérifier que le fichier existe
        guard fileManager.fileExists(atPath: url.path) else {
            logger.error("Fichier de sauvegarde introuvable: \(url.path)")
            throw NSError(domain: "com.app.backup", code: 404, userInfo: [NSLocalizedDescriptionKey: "Fichier de sauvegarde introuvable"])
        }
        
        // Simuler un délai de traitement
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
        
        logger.info("Restauration depuis \(url.lastPathComponent) réussie")
    }
    
    /// Récupère la liste des sauvegardes disponibles
    public func fetchAllBackups() async -> [BackupResult] {
        logger.debug("Listage des sauvegardes disponibles...")
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: backupDirectoryURL,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            let backupResults = fileURLs.compactMap { url -> BackupResult? in
                guard url.pathExtension == "zip" else { return nil }
                
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: url.path)
                    let date = attributes[.modificationDate] as? Date ?? Date()
                    let size = attributes[.size] as? Int64 ?? 0
                    
                    return BackupResult(url: url, date: date, size: size)
                } catch {
                    logger.error("Erreur lors de la récupération des attributs pour \(url.path): \(error.localizedDescription)")
                    return nil
                }
            }.sorted { $0.date > $1.date } // Trier par date décroissante
            
            logger.info("\(backupResults.count) sauvegardes trouvées")
            return backupResults
            
        } catch {
            logger.error("Erreur lors du listage des sauvegardes: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Récupère la date de la dernière sauvegarde
    public func fetchLastBackupDate() -> Date? {
        logger.debug("Récupération de la date de la dernière sauvegarde...")
        
        // Cette méthode n'est pas asynchrone, nous utilisons donc une approche synchrone
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: backupDirectoryURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )
            
            let dates = fileURLs.compactMap { url -> Date? in
                guard url.pathExtension == "zip" else { return nil }
                
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: url.path)
                    return attributes[.modificationDate] as? Date
                } catch {
                    return nil
                }
            }
            
            return dates.max()
            
        } catch {
            logger.error("Erreur lors de la récupération de la date de dernière sauvegarde: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Supprime une sauvegarde spécifique
    public func deleteBackup(at url: URL) async throws {
        logger.debug("Suppression de la sauvegarde: \(url.lastPathComponent)")
        
        // Vérifier que le fichier existe et est dans le répertoire de sauvegarde
        guard url.deletingLastPathComponent().path == backupDirectoryURL.path,
              fileManager.fileExists(atPath: url.path) else {
            logger.error("Fichier de sauvegarde introuvable ou hors du répertoire de sauvegarde: \(url.path)")
            throw NSError(domain: "com.app.backup", code: 404, userInfo: [NSLocalizedDescriptionKey: "Fichier de sauvegarde introuvable"])
        }
        
        // Supprimer le fichier
        try fileManager.removeItem(at: url)
        logger.info("Sauvegarde supprimée avec succès: \(url.lastPathComponent)")
    }
    
    /// Configure les sauvegardes automatiques
    public func configureAutoBackup(enabled: Bool, interval: TimeInterval? = nil, retentionDays: Int? = nil) {
        logger.info("Configuration sauvegarde auto: enabled=\(enabled), interval=\(String(describing: interval)), retentionDays=\(String(describing: retentionDays))")
        
        userDefaults.set(enabled, forKey: autoBackupEnabledKey)
        
        if let interval = interval {
            userDefaults.set(interval, forKey: autoBackupIntervalKey)
        }
        
        if let retentionDays = retentionDays {
            userDefaults.set(retentionDays, forKey: autoBackupRetentionKey)
        }
        
        // Configurer une tâche planifiée si enabled est true
        if enabled {
            // À implémenter : planifier la tâche récurrente
        } else {
            // À implémenter : annuler la tâche planifiée
        }
    }
}

// MARK: - Erreurs Possibles (Exemple)
/* Déjà défini ou à définir globalement
enum BackupError: LocalizedError {
    case directoryCreationFailed
    case backupFailed(String)
    case restoreFailed(String)
    case listingFailed
    
    var errorDescription: String? { ... }
}
*/ 