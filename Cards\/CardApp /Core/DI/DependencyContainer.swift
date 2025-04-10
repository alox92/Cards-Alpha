import Foundation
import SwiftUI
import CoreData
import Combine
import os.log
import CoreData
import SwiftUI
import Combine

// Stubs temporaires pour les types manquants
// Protocole défini dans Core/Persistence/PersistenceController.swift
public class PersistenceController: PersistenceControllerProtocol, @unchecked Sendable {
    public init(inMemory: Bool = false) {}
    public static let shared = PersistenceController()
    public var container: NSPersistentContainer {
        let container = NSPersistentContainer(name: "CardApp")
        container.loadPersistentStores { _, _ in }
        return container
    }
}

public class CardScheduler: CardSchedulerProtocolV2 {}
public class StatisticsService: StatisticsServiceProtocol {
    public init(persistenceController: PersistenceControllerProtocol) {}
}
public class ImportExportService: ImportExportServiceProtocol {}
public class BackupService: BackupServiceProtocol {}
public class DataManagementService: DataManagementServiceProtocol {
    public init(persistenceController: PersistenceControllerProtocol) {}
}
public class SyncService: SyncServiceProtocol {
    public init(persistenceController: PersistenceControllerProtocol) {}
}
public class NotificationSchedulingService: NotificationSchedulingServiceProtocol {}
public class EmptyPerformanceMonitor: PerformanceMonitorProtocol {}
public class UnifiedTagService: TagServiceProtocol {}
public class UnifiedCardService: CardServiceProtocol {}
public class UnifiedDeckService: DeckServiceProtocol {}
public class UnifiedStudyService: StudyServiceProtocol {}
// Protocole défini dans Core/Protocols/Services/CardServiceProtocol.swift
// Protocole défini dans Core/Protocols/Services/DeckServiceProtocol.swift
public protocol StatisticsServiceProtocol {}
// Protocole défini dans Core/Protocols/Services/TagServiceProtocol.swift
public protocol ImportExportServiceProtocol {}
// Protocole défini dans Core/Protocols/StudyServiceProtocol.swift
public protocol BackupServiceProtocol {}
// Protocole défini dans Core/Protocols/DataManagementServiceProtocol.swift
public protocol SyncServiceProtocol {}
public protocol NotificationSchedulingServiceProtocol {}
public protocol CacheManagerProtocol {}
public protocol PerformanceMonitorProtocol {}

/**
 Conteneur de dépendances centralisé pour l'application CardApp
 
 Ce conteneur suit le pattern Service Locator et fournit toutes les
 dépendances nécessaires au fonctionnement de l'application.
 
 Il est responsable de :
 1. L'initialisation des services
 2. La fourniture de ces services aux ViewModels
 3. L'adaptation des services pour les plateformes spécifiques (macOS/iOS)
 4. La fourniture de services de test pour les prévisualisations SwiftUI
 */

@MainActor
public final class DependencyContainer: ObservableObject {
    
    // MARK: - Singleton partagé
    
    /// Instance partagée du conteneur de dépendances
    public static let shared = DependencyContainer()

    /// Instance pour les prévisualisations SwiftUI
    public static var preview: DependencyContainer {
        let container = DependencyContainer(useInMemoryStore: true)
        return container
    }
    
    // MARK: - Services de base
    
    /// Contrôleur de persistance pour CoreData
    @Published public private(set) var persistenceController: PersistenceControllerProtocol!
    
    /// Planificateur de cartes pour spaced repetition
    public private(set) lazy var cardScheduler: CardSchedulerProtocolV2 = {
        if let scheduler = _cardSchedulerService {
            return scheduler
        }
        let scheduler = CardScheduler()
        _cardSchedulerService = scheduler
        return scheduler
    }()

    /// Service de gestion des cartes
    @Published public private(set) var cardService: CardServiceProtocol!
    
    /// Service étendu de gestion des cartes
    public private(set) lazy var extendedCardService: CardServiceProtocol = {
        if let extCardService = _extCardService { return extCardService }
        // Retourner le service de cartes standard
        return self.cardService
    }()
    
    /// Service de gestion des paquets
    @Published public private(set) var deckService: DeckServiceProtocol!

    /// Service de gestion des statistiques
    public private(set) lazy var statisticsService: StatisticsServiceProtocol = {
        if let statService = _statisticsManagerService { return statService }
        // Convertir en PersistenceController si nécessaire
        if let persistenceCtrl = persistenceController as? PersistenceController {
            return StatisticsService(persistenceController: persistenceCtrl)
        } else {
            // Retour d'une implémentation par défaut
            fatalError("PersistenceControllerProtocol ne peut pas être converti en PersistenceController")
        }
    }()
    
    /// Service de gestion des tags
    @Published public private(set) var tagService: TagServiceProtocol!
    
    /// Service d'import/export
    public private(set) lazy var importExportService: ImportExportServiceProtocol = {
        if let impExpService = _importExportManagerService { return impExpService }
        return ImportExportService(
            cardService: cardService,
            deckService: deckService,
            dataManagementService: dataManagementService
        )
    }()
    
    /// Service de gestion des études
    @Published public private(set) var studyService: StudyServiceProtocol!

    // MARK: - Services Système & Paramètres
    
    /// Service de sauvegarde
    public private(set) lazy var backupService: BackupServiceProtocol = {
        if let backupServ = _backupManagerService { return backupServ }
        return BackupService()
    }()
    
    /// Service de gestion des données (reset, taille, etc.)
    public private(set) lazy var dataManagementService: DataManagementServiceProtocol = {
        if let dataManagerService = _dataManagerService { return dataManagerService }
        
        // Convertir en PersistenceController si nécessaire
        if let persistenceCtrl = persistenceController as? PersistenceController {
            return DataManagementService(persistenceController: persistenceCtrl)
        } else {
            // Retour d'une implémentation par défaut
            fatalError("PersistenceControllerProtocol ne peut pas être converti en PersistenceController")
        }
    }()
    
    /// Service de synchronisation
    public private(set) lazy var syncService: SyncServiceProtocol = {
        if let syncManagerService = _syncManagerService { return syncManagerService }
        
        // Convertir en PersistenceController si nécessaire
        if let persistenceCtrl = persistenceController as? PersistenceController {
            return SyncService(persistenceController: persistenceCtrl)
        } else {
            // Retour d'une implémentation par défaut
            fatalError("PersistenceControllerProtocol ne peut pas être converti en PersistenceController")
        }
    }()
    
    /// Service de planification des notifications
    public private(set) lazy var notificationSchedulingService: NotificationSchedulingServiceProtocol = NotificationSchedulingService()
    
    // MARK: - Services d'optimisation
    
    /// Gestionnaire de cache adaptatif (optionnel)
    public private(set) lazy var cacheManager: CacheManagerProtocol? = {
        if let cacheManagerService = _cacheManagerService { return cacheManagerService }
        return nil
    }()
    
    /// Moniteur de performance
    public private(set) lazy var performanceMonitor: any PerformanceMonitorProtocol = {
        if let perfMonitorService = _perfMonitorService { return perfMonitorService }
        return EmptyPerformanceMonitor()
    }()
    
    // MARK: - Variables pour test et injection
    // (Utilisées pour surcharger les lazy vars lors des tests ou des previews)
    private var _cardSchedulerService: CardSchedulerProtocolV2?
    private var _statisticsManagerService: StatisticsServiceProtocol?
    private var _importExportManagerService: ImportExportServiceProtocol?
    private var _backupManagerService: BackupServiceProtocol?
    private var _dataManagerService: DataManagementServiceProtocol?
    private var _syncManagerService: SyncServiceProtocol?
    private var _notificationManagerService: NotificationSchedulingServiceProtocol?
    private var _cacheManagerService: CacheManagerProtocol?
    private var _perfMonitorService: (any PerformanceMonitorProtocol)?
    private var _extCardService: CardServiceProtocol?
    
    // MARK: - État du conteneur
    @Published public private(set) var isInitialized: Bool = false
    
    // MARK: - Initialisation
    
    /// Initialise un nouveau conteneur
    /// - Parameter useInMemoryStore: Si true, utilise un stockage en mémoire (pour les prévisualisations)
    public init(useInMemoryStore: Bool = false) {
        Logger(subsystem: "com.app.cardapp", category: "DependencyContainer").info("Initialisation du conteneur de dépendances")
        self.persistenceController = useInMemoryStore ? 
            PersistenceController(inMemory: true) : 
            PersistenceController.shared
        // Initialiser les services qui dépendent du contexte CoreData
        _ = persistenceController.container.viewContext
        // Note: L'initialisation des lazy vars se fera à la première demande.
        // Il faut s'assurer que persistenceController est prêt avant d'accéder aux services qui en dépendent.
    }
    
    /// Initialise tous les services
    public func initialize() {
        guard !isInitialized else { return }
        
        // Créer le contrôleur de persistance
        let persistenceController = PersistenceController()
        self.persistenceController = persistenceController
        
        // Créer les services de données
        let dataService = DataManagementService(persistenceController: persistenceController)
        
        // Créer les services de domaine
        let tagService = UnifiedTagService(persistenceController: persistenceController)
        self.tagService = tagService
        
        let cardScheduler = CardScheduler()
        
        let cardService = UnifiedCardService(persistenceController: persistenceController)
        self.cardService = cardService
        
        let deckService = UnifiedDeckService(persistenceController: persistenceController)
        self.deckService = deckService
        
        // Créer le service d'étude avec les paramètres disponibles
        // Utilisation de l'initialisation avec uniquement les paramètres nécessaires
        let studyService = UnifiedStudyService(
            persistence: persistenceController,
            cardService: cardService
        )
        self.studyService = studyService
        
        isInitialized = true
    }
    
    /// Réinitialise tous les services
    public func reset() {
        cardService = nil
        deckService = nil
        tagService = nil
        studyService = nil
        persistenceController = nil
        isInitialized = false
    }
    
    // MARK: - Placeholder pour les Mocks (à créer dans un dossier Tests/Mocks)
    #if DEBUG
    // class MockCardService: CardServiceProtocol { /* ... implémentation mock ... */ }
    // class MockDeckService: DeckServiceProtocol { /* ... implémentation mock ... */ }
    // ... autres mocks ...
    #endif

    /// Recharger tous les services (pour les tests)
    public func reloadServices() {
        let _ = cardService
        let _ = deckService
        let _ = studyService
        let _ = tagService
        let _ = importExportService
        let _ = extendedCardService
    }
}
