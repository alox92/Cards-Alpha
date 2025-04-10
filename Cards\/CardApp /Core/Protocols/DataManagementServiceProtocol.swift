import Foundation
import CoreData

/// Protocole pour le service de gestion des données (base de données)
@MainActor @preconcurrency public protocol DataManagementServiceProtocol {
    /// Réinitialise la base de données aux valeurs par défaut
    func resetDatabase() async throws
    
    /// Récupère la taille actuelle de la base de données en octets
    func getDatabaseSize() async throws -> UInt64
    
    /// Effectue une opération d'optimisation/nettoyage de la base
    func optimizeDatabase() async throws
    
    /// Exporte les données de l'application dans un format spécifié
    func exportData(options: DataExportOptions) async throws -> URL
    
    /// Importe des données depuis un fichier
    func importData(from url: URL, options: DataImportOptions) async throws
    
    /// Réalise une sauvegarde complète des données de l'application
    func createBackup(options: BackupOptions?) async throws -> URL
    
    /// Restaure une sauvegarde précédente
    func restoreBackup(from url: URL) async throws
    
    /// Crée une nouvelle entité du type spécifié
    func create<T: NSManagedObject>(_ type: T.Type, configure: @escaping @Sendable (T) -> Void) async throws -> T
    
    /// Récupère une entité par son identifiant
    func fetch<T: NSManagedObject>(_ type: T.Type, id: UUID) async throws -> T?
    
    /// Récupère des entités selon un prédicat personnalisé
    func fetch<T: NSManagedObject>(_ type: T.Type, configure: @escaping @Sendable (NSFetchRequest<T>) -> Void) async throws -> [T]
    
    /// Récupère toutes les entités du type spécifié
    func fetchAll<T: NSManagedObject>(_ type: T.Type) async throws -> [T]
    
    /// Récupère toutes les entités du type spécifié avec prédicat et tri optionnels
    func fetchAll<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [T]
    
    /// Met à jour une entité existante par ID
    func update<T: NSManagedObject>(_ type: T.Type, id: UUID, configure: @escaping @Sendable (T) -> Void) async throws -> T
    
    /// Met à jour une entité existante
    func update<T: NSManagedObject>(_ entity: T, configure: @escaping @Sendable (T) -> Void) async throws -> T
    
    /// Supprime une entité par ID
    func delete<T: NSManagedObject>(_ type: T.Type, id: UUID) async throws
    
    /// Supprime une entité existante
    func delete<T: NSManagedObject>(_ entity: T) async throws
    
    /// Supprime plusieurs entités selon un prédicat
    func deleteMultiple<T: NSManagedObject>(_ type: T.Type, configure: @escaping @Sendable (NSFetchRequest<T>) -> Void) async throws
    
    /// Supprime plusieurs entités à la fois
    func deleteAll<T: NSManagedObject>(_ entities: [T]) async throws
    
    /// Compte le nombre d'entités correspondant au prédicat configuré
    func count<T: NSManagedObject>(_ type: T.Type, configure: @escaping @Sendable (NSFetchRequest<T>) -> Void) async throws -> Int
}

/// Options pour l'exportation de données
public struct DataExportOptions: CustomStringConvertible {
    public let includeDecks: Bool
    public let includeCards: Bool
    public let includeStatistics: Bool
    public let includeSettings: Bool
    public let destination: URL
    
    public init(
        includeDecks: Bool = true,
        includeCards: Bool = true,
        includeStatistics: Bool = true,
        includeSettings: Bool = true,
        destination: URL
    ) {
        self.includeDecks = includeDecks
        self.includeCards = includeCards
        self.includeStatistics = includeStatistics
        self.includeSettings = includeSettings
        self.destination = destination
    }
    
    public var description: String {
        return "DataExportOptions(decks: \(includeDecks), cards: \(includeCards), stats: \(includeStatistics), settings: \(includeSettings), destination: \(destination.lastPathComponent))"
    }
}

/// Options pour l'importation de données
public struct DataImportOptions: CustomStringConvertible {
    public let overwriteExisting: Bool
    public let validateBeforeImport: Bool
    
    public init(
        overwriteExisting: Bool = false,
        validateBeforeImport: Bool = true
    ) {
        self.overwriteExisting = overwriteExisting
        self.validateBeforeImport = validateBeforeImport
    }
    
    public var description: String {
        return "DataImportOptions(overwrite: \(overwriteExisting), validate: \(validateBeforeImport))"
    }
}

/// Options pour la sauvegarde
public struct BackupOptions: CustomStringConvertible {
    public let includeUserData: Bool
    public let includeSettings: Bool
    public let includeImages: Bool
    public let compress: Bool
    public let encrypt: Bool
    public let password: String?
    
    public init(
        includeUserData: Bool = true,
        includeSettings: Bool = true,
        includeImages: Bool = true,
        compress: Bool = true,
        encrypt: Bool = false,
        password: String? = nil
    ) {
        self.includeUserData = includeUserData
        self.includeSettings = includeSettings
        self.includeImages = includeImages
        self.compress = compress
        self.encrypt = encrypt
        self.password = password
    }
    
    public var description: String {
        return "BackupOptions(userData: \(includeUserData), settings: \(includeSettings), images: \(includeImages), compress: \(compress), encrypt: \(encrypt), hasPassword: \(password != nil))"
    }
} 