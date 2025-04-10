import Foundation
import SwiftUI
import CoreData
import os.log
import UserNotifications

#if os(iOS)
import UIKit
typealias AppDelegateBaseClass = UIResponder
typealias AppDelegateProtocol = UIApplicationDelegate
#else
import AppKit
typealias AppDelegateBaseClass = NSObject
typealias AppDelegateProtocol = NSApplicationDelegate
#endif

/// Classe principale de délégation de l'application
@MainActor
class AppDelegate: AppDelegateBaseClass, AppDelegateProtocol, UNUserNotificationCenterDelegate {
    /// Logger pour l'AppDelegate
    private let logger = Logger(subsystem: "com.app.cardapp", category: "AppDelegate")
    
    /// Conteneur de dépendances principal
    var container = DependencyContainer.shared
    
    #if os(iOS)
    // MARK: - Méthodes UIApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        logger.info("Application démarrée sur iOS")
        configureNotifications()
        initializeServices()
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Sauvegarder les données de CoreData au besoin
        container.persistenceController.saveContextIfNeeded()
        logger.info("Application iOS en cours de fermeture")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Gestion des notifications push et du background fetch
        logger.debug("Notification push ou background fetch reçu")
        completionHandler(.noData)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Sauvegarder les données lors du passage en arrière-plan
        container.persistenceController.saveContextIfNeeded()
        logger.debug("Application passée en arrière-plan")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.debug("Application de retour au premier plan")
    }
    
    // MARK: - Notifications
    
    private func configureNotifications() {
        // Configuration du délégué pour les notifications
        UNUserNotificationCenter.current().delegate = self
        
        // Vérifier et demander les autorisations de notification si nécessaire
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.logger.debug("Autorisation de notification non encore déterminée")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Afficher la notification même si l'app est au premier plan
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Gestion de l'interaction avec une notification
        logger.debug("Interaction utilisateur avec une notification")
        completionHandler()
    }
    
    #else
    // MARK: - Méthodes NSApplicationDelegate
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application démarrée")
        
        // Configurer l'apparence de l'application
        configureAppearance()
        initializeServices()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application terminée")
        saveData()
    }
    
    #endif
    
    // MARK: - Méthodes privées
    
    /// Initialise les services principaux
    private func initializeServices() {
        // Tous les services sont déjà initialisés par le DependencyContainer lazy vars
        // Cette méthode est juste pour forcer l'initialisation explicite si nécessaire
        logger.info("Initialisation des services principaux")
        _ = container.cardService
        _ = container.deckService
        _ = container.tagService
        _ = container.studyService
        _ = container.importExportService
        logger.info("Services principaux initialisés avec succès")
    }
    
    /// Configurer l'apparence de l'application
    private func configureAppearance() {
        #if os(iOS)
        // Configurer l'apparence iOS
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        #else
        // Configurer l'apparence macOS
        // Rien à faire pour le moment
        #endif
    }
    
    /// Sauvegarder les données avant la fermeture de l'application
    private func saveData() {
        do {
            try container.persistenceController.container.viewContext.save()
            logger.info("Données sauvegardées avec succès")
        } catch {
            logger.error("Erreur lors de la sauvegarde des données: \(error.localizedDescription)")
        }
    }
} 