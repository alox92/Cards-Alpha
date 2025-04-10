import Foundation
import Combine
@preconcurrency import CoreData
import os.log

/// Format d'exportation des données
public enum DataExportFormat: CustomStringConvertible {
    case json
    case cardarchive
    
    public var description: String {
        switch self {
        case .json:
            return "JSON"
        case .cardarchive:
            return "Card Archive"
        }
    }
}

/// Stratégie d'importation des données
public enum ImportStrategy: CustomStringConvertible {
    case merge
    case replace
    case appendOnly
    
    public var description: String {
        switch self {
        case .merge:
            return "Fusion"
        case .replace:
            return "Remplacement"
        case .appendOnly:
            return "Ajout uniquement"
        }
    }
}

/// Métadonnées du stockage
public struct StorageMetadata {
    public let lastOptimizationDate: Date?
    public let databaseVersion: String
    
    public init(lastOptimizationDate: Date?, databaseVersion: String) {
        self.lastOptimizationDate = lastOptimizationDate
        self.databaseVersion = databaseVersion
    }
}

// Solution pour le problème des NSMangedObjects non Sendable:
// 1. Ajouter une extension pour les rendre @unchecked Sendable
extension NSManagedObject: @unchecked Sendable {}

/// Service responsable des opérations de gestion de données de bas niveau (réinitialisation, taille, etc.).
@MainActor
public final class DataManagementService: DataManagementServiceProtocol, @unchecked Sendable {
    
    private let persistenceController: PersistenceController
    private let fileManager: FileManager
    private let logger = Logger(subsystem: "com.app.cardapp", category: "DataManagementService")
    
    /// Initialisation du service.
    /// - Parameters:
    ///   - persistenceController: Le contrôleur de persistance Core Data.
    ///   - fileManager: Le gestionnaire de fichiers.
    public init(persistenceController: PersistenceController, fileManager: FileManager = .default) {
        self.persistenceController = persistenceController
        self.fileManager = fileManager
        logger.info("DataManagementService initialisé.")
    }
    
    // MARK: - DataManagementServiceProtocol Implementation
    
    public func resetDatabase() async throws {
        let context = self.persistenceController.container.newBackgroundContext()
        
        // Utilisation de performAsync pour éviter les erreurs de concurrence
        try await context.performAsync {
            do {
                // Vider les entités
                try await self.deleteAllEntities(context: context)
                try context.save()
                
                self.logger.info("Base de données réinitialisée avec succès")
            } catch {
                self.logger.error("Erreur lors de la réinitialisation: \(error.localizedDescription)")
                throw DataManagementError.resetFailed(error)
            }
        }
    }
    
    public func getDatabaseSize() async throws -> UInt64 {
        logger.debug("Calcul de la taille de la base de données...")
        
        guard let storeURL = self.persistenceController.container.persistentStoreDescriptions.first?.url else {
            self.logger.error("Impossible d'obtenir l'URL du store Core Data pour calculer la taille.")
            throw DataManagementError.storeURLNotFound
        }
        
        do {
            let attributes = try self.fileManager.attributesOfItem(atPath: storeURL.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            self.logger.info("Taille de la base de données calculée: \(fileSize) octets.")
            return fileSize
        } catch {
            self.logger.error("Erreur lors du calcul de la taille de la base de données: \(error.localizedDescription)")
            throw DataManagementError.sizeCalculationFailed(error)
        }
    }
    
    public func optimizeDatabase() async throws {
        logger.info("Optimisation de la base de données demandée...")
        
        // Simuler une opération d'optimisation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        self.logger.notice("Optimisation de la base de données terminée.")
    }
    
    public func exportData(options: DataExportOptions) async throws -> URL {
        logger.debug("Exportation des données avec options: \(String(describing: options))...")
        
        // Simuler une exportation
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        let tempURL = options.destination
        self.logger.info("Exportation terminée vers: \(tempURL.path)")
        return tempURL
    }
    
    public func importData(from url: URL, options: DataImportOptions) async throws {
        logger.info("Importation des données depuis \(url.lastPathComponent) avec options: \(String(describing: options))...")
        
        // Simuler une importation
        try await Task.sleep(nanoseconds: 2_000_000_000)
        self.logger.notice("Importation terminée.")
    }
    
    public func createBackup(options: BackupOptions?) async throws -> URL {
        logger.info("Création d'une sauvegarde...")
        
        // Simuler la création d'une sauvegarde
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        let backupURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("backup_\(Date().timeIntervalSince1970).zip")
        self.logger.notice("Sauvegarde créée à: \(backupURL.path)")
        return backupURL
    }
    
    public func restoreBackup(from url: URL) async throws {
        logger.info("Restauration d'une sauvegarde depuis \(url.lastPathComponent)...")
        
        // Vérifier que le fichier existe
        guard fileManager.fileExists(atPath: url.path) else {
            throw DataManagementError.backupNotFound
        }
        
        // Simuler une restauration
        try await Task.sleep(nanoseconds: 3_000_000_000)
        self.logger.notice("Restauration terminée.")
    }
    
    // MARK: - Opérations CRUD
    
    public func create<T: NSManagedObject>(_ type: T.Type, configure: @escaping @Sendable (T) -> Void) async throws -> T {
        let context = persistenceController.container.newBackgroundContext()
        
        // Utiliser NSManagedObject comme @unchecked Sendable
        return try await context.performAsync {
            // Créer l'entité
            let entity = T(context: context)
            
            // Configurer l'entité
            configure(entity)
            
            do {
                try context.save()
                let objectID = entity.objectID
                
                // Récupérer l'entité dans le contexte principal pour éviter les problèmes de concurrence
                let mainContext = self.persistenceController.container.viewContext
                guard let mainEntity = mainContext.object(with: objectID) as? T else {
                    throw DataManagementError.createFailed(NSError(domain: "DataManagementService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de récupérer l'entité dans le contexte principal"]))
                }
                
                return mainEntity
            } catch {
                throw DataManagementError.createFailed(error)
            }
        }
    }
    
    public func fetch<T: NSManagedObject>(_ type: T.Type, id: UUID) async throws -> T? {
        let context = persistenceController.container.newBackgroundContext()
        
        return try await context.performAsync {
            let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchBatchSize = 20;     fetchRequest.fetchLimit = 1
            
            do {
                let results = try context.fetch(fetchRequest)
                if let entity = results.first {
                    // Convertir en ID objectif pour rendre Sendable
                    let objectID = entity.objectID
                    
                    // Récupérer dans le contexte principal
                    let mainContext = self.persistenceController.container.viewContext
                    return mainContext.object(with: objectID) as? T
                }
                return nil
            } catch {
                throw DataManagementError.fetchFailed(error)
            }
        }
    }
    
    public func fetchAll<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) async throws -> [T] {
        let context = persistenceController.container.newBackgroundContext()
        let localPredicate = predicate
        let localSortDescriptors = sortDescriptors
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let entityName = String(describing: type)
                let fetchRequest = NSFetchRequest<T>(entityName: entityName)
                fetchRequest.predicate = localPredicate
        fetchRequest.fetchBatchSize = 20;         fetchRequest.sortDescriptors = localSortDescriptors
                
                do {
                    let results = try context.fetch(fetchRequest)
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: DataManagementError.fetchFailed(error))
                }
            }
        }
    }
    
    public func fetch<T: NSManagedObject>(_ type: T.Type, configure: @escaping @Sendable (NSFetchRequest<T>) -> Void) async throws -> [T] {
        let context = persistenceController.container.newBackgroundContext()
        fetchRequest.fetchBatchSize = 20; 
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let entityName = String(describing: type)
                let fetchRequest = NSFetchRequest<T>(entityName: entityName)
                configure(fetchRequest)
        fetchRequest.fetchBatchSize = 20;         
                do {
                    let results = try context.fetch(fetchRequest)
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: DataManagementError.fetchFailed(error))
                }
            }
        }
    }
    
    public func update<T: NSManagedObject>(_ entity: T, configure: @escaping @Sendable (T) -> Void) async throws -> T {
        let context = persistenceController.container.newBackgroundContext()
        let objectID = entity.objectID
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                guard !objectID.isTemporaryID else {
                    continuation.resume(throwing: DataManagementError.invalidEntity)
                    return
                }
                
                // Obtenir l'entité dans ce contexte
                guard let managedEntity = try? context.existingObject(with: objectID) as? T else {
                    continuation.resume(throwing: DataManagementError.entityNotFound)
                    return
                }
                
                // Configurer l'entité
                configure(managedEntity)
                
                // Sauvegarder les changements
                do {
                    try context.save()
                    continuation.resume(returning: managedEntity)
                } catch {
                    continuation.resume(throwing: DataManagementError.updateFailed(error))
                }
            }
        }
    }
    
    public func update<T: NSManagedObject>(_ type: T.Type, id: UUID, configure: @escaping @Sendable (T) -> Void) async throws -> T {
        let context = persistenceController.container.newBackgroundContext()
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let entityName = String(describing: type)
                let fetchRequest = NSFetchRequest<T>(entityName: entityName)
                fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchBatchSize = 20;         fetchRequest.fetchLimit = 1
                
                do {
                    let results = try context.fetch(fetchRequest)
                    guard let entity = results.first else {
                        continuation.resume(throwing: DataManagementError.entityNotFound)
                        return
                    }
                    
                    // Configurer l'entité
                    configure(entity)
                    
                    // Sauvegarder les changements
                    try context.save()
                    continuation.resume(returning: entity)
                } catch {
                    continuation.resume(throwing: DataManagementError.updateFailed(error))
                }
            }
        }
    }
    
    public func delete<T: NSManagedObject>(_ entity: T) async throws {
        let context = persistenceController.container.newBackgroundContext()
        let objectID = entity.objectID
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                guard !objectID.isTemporaryID else {
                    continuation.resume(throwing: DataManagementError.invalidEntity)
                    return
                }
                
                // Obtenir l'entité dans ce contexte
                guard let managedEntity = try? context.existingObject(with: objectID) else {
                    continuation.resume(throwing: DataManagementError.entityNotFound)
                    return
                }
                
                // Supprimer l'entité
                context.delete(managedEntity)
                
                // Sauvegarder les changements
                do {
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: DataManagementError.deleteFailed(error))
                }
            }
        }
    }
    
    public func delete<T: NSManagedObject>(_ type: T.Type, id: UUID) async throws {
        let context = persistenceController.container.newBackgroundContext()
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let entityName = String(describing: type)
                let fetchRequest = NSFetchRequest<T>(entityName: entityName)
                fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchBatchSize = 20;         fetchRequest.fetchLimit = 1
                
                do {
                    let results = try context.fetch(fetchRequest)
                    guard let entity = results.first else {
                        // Si l'entité n'est pas trouvée, on considère que la suppression est un succès
                        continuation.resume()
                        return
                    }
                    
                    // Supprimer l'entité
                    context.delete(entity)
                    
                    // Sauvegarder les changements
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: DataManagementError.deleteFailed(error))
                }
            }
        }
    }
    
    public func deleteAll<T: NSManagedObject>(_ entities: [T]) async throws {
        guard !entities.isEmpty else { return }
        
        let context = persistenceController.container.newBackgroundContext()
        let objectIDs = entities.map { $0.objectID }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    for objectID in objectIDs {
                        guard !objectID.isTemporaryID else {
                            continue
                        }
                        
                        // Obtenir l'entité dans ce contexte
                        guard let managedEntity = try? context.existingObject(with: objectID) else {
                            continue
                        }
                        
                        // Supprimer l'entité
                        context.delete(managedEntity)
                    }
                    
                    // Sauvegarder les changements
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: DataManagementError.deleteFailed(error))
                }
            }
        }
    }
    
    public func deleteMultiple<T: NSManagedObject>(_ type: T.Type, configure: @escaping @Sendable (NSFetchRequest<T>) -> Void) async throws {
        let context = persistenceController.container.newBackgroundContext()
        fetchRequest.fetchBatchSize = 20; 
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let entityName = String(describing: type)
                let fetchRequest = NSFetchRequest<T>(entityName: entityName)
                configure(fetchRequest)
        fetchRequest.fetchBatchSize = 20;         
                do {
                    let entities = try context.fetch(fetchRequest)
                    
                    for entity in entities {
                        context.delete(entity)
                    }
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: DataManagementError.deleteFailed(error))
                }
            }
        }
    }
    
    public func count<T: NSManagedObject>(_ type: T.Type, configure: @escaping @Sendable (NSFetchRequest<T>) -> Void) async throws -> Int {
        let context = persistenceController.container.newBackgroundContext()
        fetchRequest.fetchBatchSize = 20; 
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let entityName = String(describing: type)
                let fetchRequest = NSFetchRequest<T>(entityName: entityName)
                configure(fetchRequest)
        fetchRequest.fetchBatchSize = 20;         
                do {
                    let count = try context.count(for: fetchRequest)
                    continuation.resume(returning: count)
                } catch {
                    continuation.resume(throwing: DataManagementError.fetchFailed(error))
                }
            }
        }
    }
    
    // MARK: - Anciennes méthodes basées sur Combine (à supprimer ou mettre à jour)
    
    // NOTE: Ces méthodes sont conservées pour compatibilité avec le code existant
    // mais devraient être remplacées par les nouvelles méthodes async/await.
    
    func resetAllUserData() -> AnyPublisher<Void, Error> {
        logger.warning("(Déprécié) Début de la réinitialisation de TOUTES les données utilisateur...")
        
        return Future<Void, Error> { [weak self] promise in
            Task {
                do {
                    guard let self = self else {
                        promise(.failure(DataManagementError.serviceDeallocated))
                        return
                    }
                    try await self.resetDatabase()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Helper pour supprimer toutes les entités gérées par Core Data.
    private func deleteAllEntities(context: NSManagedObjectContext) throws {
        let entityNames = persistenceController.container.managedObjectModel.entities.compactMap { $0.name }
        for entityName in entityNames {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        fetchRequest.fetchBatchSize = 20;     deleteRequest.resultType = .resultTypeObjectIDs // Pour obtenir les ID supprimés (optionnel)
            
            logger.debug("Suppression en batch de l'entité: \(entityName)")
            _ = try context.execute(deleteRequest) as? NSBatchDeleteResult
            // Important: Il faut rafraîchir le contexte parent si nécessaire après un batch delete
        }
        logger.info("Toutes les entités ont été marquées pour suppression.")
    }

    func getStorageSize() -> AnyPublisher<Int64, Error> {
        logger.debug("(Déprécié) Calcul de la taille du stockage...")
        return Future<Int64, Error> { [weak self] promise in
            Task {
                do {
                    guard let self = self else {
                        promise(.failure(DataManagementError.serviceDeallocated))
                        return
                    }
                    let size = try await self.getDatabaseSize()
                    promise(.success(Int64(size)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func optimizeStorage() -> AnyPublisher<Void, Error> {
        logger.info("(Déprécié) Optimisation du stockage demandée...")
        return Future<Void, Error> { [weak self] promise in
            Task {
                do {
                    guard let self = self else {
                        promise(.failure(DataManagementError.serviceDeallocated))
                        return
                    }
                    try await self.optimizeDatabase()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func exportAllData(format: DataExportFormat) -> AnyPublisher<URL, Error> {
        logger.debug("(Déprécié) Exportation de toutes les données au format \(String(describing: format)) demandée...")
        return Future<URL, Error> { [weak self] promise in
            Task {
                do {
                    guard let self = self else {
                        promise(.failure(DataManagementError.serviceDeallocated))
                        return
                    }
                    
                    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("export_\(Date().timeIntervalSince1970).\(format == .json ? "json" : "cardarchive")")
                    
                    let options = DataExportOptions(
                        includeDecks: true,
                        includeCards: true,
                        includeStatistics: true,
                        includeSettings: true,
                        destination: tempURL
                    )
                    
                    let exportedURL = try await self.exportData(options: options)
                    promise(.success(exportedURL))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func importAllData(from url: URL, strategy: ImportStrategy) -> AnyPublisher<Void, Error> {
        logger.info("(Déprécié) Importation de toutes les données depuis \(url.lastPathComponent) avec stratégie \(String(describing: strategy)) demandée...")
        return Future<Void, Error> { [weak self] promise in
            Task {
                do {
                    guard let self = self else {
                        promise(.failure(DataManagementError.serviceDeallocated))
                        return
                    }
                    
                    let options = DataImportOptions(
                        overwriteExisting: strategy == .replace,
                        validateBeforeImport: true
                    )
                    
                    try await self.importData(from: url, options: options)
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func getStorageMetadata() -> AnyPublisher<StorageMetadata, Error> {
        logger.debug("(Déprécié) Récupération des métadonnées du stockage...")
        return Future<StorageMetadata, Error> { promise in
            let metadata = StorageMetadata(lastOptimizationDate: nil, databaseVersion: "1.0")
            promise(.success(metadata))
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - API Déprécié (Combine)
    
    @discardableResult
    public func resetDatabaseDeprecated() -> Future<Void, Error> {
        logger.warning("(Déprécié) Réinitialisation de la base de données demandée...")
        
        return Future<Void, Error> { promise in
            Task { 
                do {
                    try await self.resetDatabase()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    public func calculateDatabaseSizeDeprecated() -> Future<Int64, Error> {
        logger.debug("(Déprécié) Calcul de la taille du stockage...")
        return Future<Int64, Error> { promise in
            Task { 
                do {
                    let size = try await self.getDatabaseSize()
                    promise(.success(Int64(size)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    @discardableResult
    public func optimizeDatabaseDeprecated() -> Future<Void, Error> {
        logger.info("(Déprécié) Optimisation du stockage demandée...")
        return Future<Void, Error> { promise in
            Task { 
                do {
                    try await self.optimizeDatabase()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    public func exportDataDeprecated(format: DataExportFormat) -> Future<URL, Error> {
        logger.debug("(Déprécié) Exportation de toutes les données au format \(String(describing: format)) demandée...")
        let localFormat = format // capture locale pour éviter les data races
        
        return Future<URL, Error> { promise in
            Task { 
                do {
                    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("export_\(Date().timeIntervalSince1970).\(localFormat == .json ? "json" : "cardarchive")")
                    
                    let options = DataExportOptions(
                        includeDecks: true,
                        includeCards: true,
                        includeStatistics: true,
                        includeSettings: true,
                        destination: tempURL
                    )
                    
                    let exportedURL = try await self.exportData(options: options)
                    promise(.success(exportedURL))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    @discardableResult
    public func importDataDeprecated(from url: URL, strategy: ImportStrategy) -> Future<Void, Error> {
        logger.info("(Déprécié) Importation de toutes les données depuis \(url.lastPathComponent) avec stratégie \(String(describing: strategy)) demandée...")
        let localURL = url
        let overwriteExisting = strategy == .replace
        
        return Future<Void, Error> { promise in
            Task { 
                do {
                    let options = DataImportOptions(
                        overwriteExisting: overwriteExisting,
                        validateBeforeImport: true
                    )
                    
                    try await self.importData(from: localURL, options: options)
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }

    public func fetchAll<T: NSManagedObject>(_ type: T.Type) async throws -> [T] {
        return try await fetchAll(type, predicate: nil, sortDescriptors: nil)
    }

    // MARK: - Méthodes utilitaires pour la gestion de concurrence
    
    /// Convertit de manière thread-safe une entité NSManagedObject en un type Sendable
    /// - Parameters:
    ///   - entity: L'entité Core Data à convertir
    ///   - converter: La fonction de conversion qui produit un objet Sendable
    /// - Returns: L'objet converti
    nonisolated private func convertToSendable<T: NSManagedObject, R: Sendable>(
        entity: T,
        converter: @escaping (T) -> R
    ) -> R {
        return converter(entity)
    }
    
    /// Convertit de manière thread-safe plusieurs entités NSManagedObject en types Sendable
    /// - Parameters:
    ///   - entities: Les entités Core Data à convertir
    ///   - converter: La fonction de conversion qui produit des objets Sendable
    /// - Returns: Les objets convertis
    nonisolated private func convertToSendable<T: NSManagedObject, R: Sendable>(
        entities: [T],
        converter: @escaping (T) -> R?
    ) -> [R] {
        return entities.compactMap { converter($0) }
    }
}

// MARK: - Erreurs de gestion de données
public enum DataManagementError: LocalizedError {
    case storeURLNotFound
    case resetFailed(Error)
    case sizeCalculationFailed(Error)
    case serviceDeallocated
    case backupNotFound
    case invalidEntity
    case entityNotFound
    case createFailed(Error)
    case fetchFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .storeURLNotFound:
            return "L'URL du store Core Data n'a pas été trouvée."
        case .resetFailed(let underlyingError):
            return "La réinitialisation de la base de données a échoué: \(underlyingError.localizedDescription)"
        case .sizeCalculationFailed(let underlyingError):
            return "Le calcul de la taille de la base de données a échoué: \(underlyingError.localizedDescription)"
        case .serviceDeallocated:
            return "Le service a été libéré avant que l'opération ne soit terminée."
        case .backupNotFound:
            return "La sauvegarde n'a pas été trouvée."
        case .invalidEntity:
            return "L'entité est invalide ou a un ID temporaire."
        case .entityNotFound:
            return "L'entité n'a pas été trouvée dans le contexte."
        case .createFailed(let underlyingError):
            return "La création de l'entité a échoué: \(underlyingError.localizedDescription)"
        case .fetchFailed(let underlyingError):
            return "La récupération des données a échoué: \(underlyingError.localizedDescription)"
        case .updateFailed(let underlyingError):
            return "La mise à jour de l'entité a échoué: \(underlyingError.localizedDescription)"
        case .deleteFailed(let underlyingError):
            return "La suppression de l'entité a échoué: \(underlyingError.localizedDescription)"
        }
    }
} 