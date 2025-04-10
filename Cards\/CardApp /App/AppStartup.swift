import Foundation
import Combine
import SwiftUI
import os.log

/// Classe responsable de l'initialisation des services de l'application au démarrage
@MainActor
public class AppStartup: ObservableObject {
    private let logger = Logger(subsystem: "com.app.cardapp", category: "AppStartup")
    private var cancellables = Set<AnyCancellable>()
    
    // Instance partagée (singleton)
    public static let shared = AppStartup()
    
    // Indique si l'initialisation est terminée
    @Published public private(set) var isInitialized: Bool = false
    
    // Services principaux
    private var accessManager: UnifiedAccessManager?
    private var container: DependencyContainer?
    
    // Empêcher l'instanciation directe
    private init() {}
    
    /// Initialise tous les services nécessaires au fonctionnement de l'application
    /// - Parameter completionHandler: Bloc exécuté une fois l'initialisation terminée
    public func initializeServices(completionHandler: @escaping (Bool) -> Void) {
        logger.debug("Démarrage de l'initialisation des services...")
        
        // Créer le conteneur de dépendances
        let container = DependencyContainer(useInMemoryStore: false)
        self.container = container
        
        // Créer le gestionnaire d'accès unifié
        let accessManager = UnifiedAccessManager.createDefault()
        self.accessManager = accessManager
        
        // Initialiser le CardViewModel global avec notre gestionnaire d'accès
        initializeViewModels(with: accessManager, container: container)
        
        // Nettoyer les caches au démarrage
        cleanupCaches()
        
        // Simuler un délai pour laisser le temps aux services de s'initialiser
        // Dans une vraie application, cela pourrait être remplacé par une vérification réelle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            Task { @MainActor in
                self?.logger.debug("Initialisation des services terminée avec succès")
                self?.isInitialized = true
                completionHandler(true)
            }
        }
    }
    
    /// Configure les ViewModels principaux de l'application
    /// - Parameters:
    ///   - accessManager: Le gestionnaire d'accès unifié
    ///   - container: Le conteneur de dépendances
    private func initializeViewModels(with accessManager: UnifiedAccessManager, container: DependencyContainer) {
        // Trouver l'instance de CardViewModel ou en créer une nouvelle
        _ = findOrCreateCardViewModel(container: container)
        Task { @MainActor in
            // Note: La méthode configure a été supprimée car elle n'existe pas dans CardViewModel
            // Dans une future mise à jour, il faudrait soit ajouter cette méthode à CardViewModel,
            // soit trouver une autre façon d'injecter l'accessManager
            logger.debug("CardViewModel initialisé")
        }
        
        // Autres initialisations de ViewModels peuvent être ajoutées ici
    }
    
    /// Trouve le CardViewModel existant ou en crée un nouveau
    /// - Parameter container: Le conteneur de dépendances
    /// - Returns: Une instance de CardViewModel
    private func findOrCreateCardViewModel(container: DependencyContainer) -> CardViewModel {
        // Dans une vraie application, nous pourrions rechercher l'instance existante
        // Pour cette implémentation, nous créons simplement une nouvelle instance
        return CardViewModel(container: container)
    }
    
    /// Nettoie les caches au démarrage de l'application
    private func cleanupCaches() {
        guard let accessManager = accessManager else { return }
        
        // Nettoyer les entrées expirées
        accessManager.cleanupCache()
        
        // Adapter la taille du cache à la mémoire disponible
        accessManager.adaptCacheToMemory()
        
        logger.debug("Caches nettoyés au démarrage")
    }
    
    /// Réinitialise tous les services (utile pour les tests ou lors de la déconnexion)
    public func resetServices(completionHandler: @escaping (Bool) -> Void) {
        logger.debug("Réinitialisation des services...")
        
        // Vider les caches
        accessManager?.clearCache()
        
        // Réinitialiser l'état des services
        isInitialized = false
        
        // Réinitialiser les services
        initializeServices(completionHandler: completionHandler)
    }
    
    /// Obtient le gestionnaire d'accès unifié
    /// - Returns: Le gestionnaire d'accès unifié
    public func getAccessManager() -> UnifiedAccessManager? {
        return accessManager
    }
}

// MARK: - Extensions SwiftUI pour faciliter l'utilisation

extension View {
    /// Attend l'initialisation des services avant d'afficher le contenu
    /// - Parameter content: Vue à afficher pendant le chargement
    /// - Returns: Une vue modifiée qui attend l'initialisation des services
    public func withInitializedServices<Content: View>(loadingContent: @escaping () -> Content) -> some View {
        return self.modifier(ServicesInitializedModifier(loadingContent: loadingContent))
    }
}

/// Modificateur qui attend l'initialisation des services
struct ServicesInitializedModifier<LoadingContent: View>: ViewModifier {
    @ObservedObject private var appStartup = AppStartup.shared
    private let loadingContent: () -> LoadingContent
    
    init(loadingContent: @escaping () -> LoadingContent) {
        self.loadingContent = loadingContent
    }
    
    func body(content: Content) -> some View {
        if appStartup.isInitialized {
            content
        } else {
            loadingContent()
                .onAppear {
                    if !appStartup.isInitialized {
                        Task { @MainActor in
                            await MainActor.run {
                                appStartup.initializeServices { _ in }
                            }
                        }
                    }
                }
        }
    }
}
