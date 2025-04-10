import Foundation
@preconcurrency import UserNotifications
import os.log
import SwiftUI // Pour @MainActor

/// Service responsable de la gestion et de la planification des notifications locales.
@MainActor
public final class NotificationSchedulingService: NotificationSchedulingServiceProtocol, @unchecked Sendable {
    
    private let center: UNUserNotificationCenter
    private let logger = Logger(subsystem: "com.cardapp.core", category: "NotificationSchedulingService")
    
    /// Initialisation du service.
    /// - Parameter center: Le centre de notifications UNUserNotificationCenter à utiliser (par défaut .current()).
    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        logger.info("NotificationSchedulingService initialisé.")
    }
    
    // MARK: - NotificationSchedulingServiceProtocol Implementation
    
    public func requestAuthorization() async throws -> Bool {
        logger.debug("Demande d'autorisation pour les notifications...")
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            logger.error("Failed to request notification authorization: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    public func scheduleNotification(id: String, title: String, body: String, date: Date, options: NotificationOptions?) async throws {
        logger.info("Planification de la notification \"\(title)\" pour \(date)...")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        if let options = options {
            content.sound = options.sound ? .default : nil
            if let badge = options.badge {
                content.badge = NSNumber(value: badge)
            }
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            logger.info("Notification \"\(title)\" planifiée avec succès.")
        } catch {
            logger.error("Failed to schedule notification: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func scheduleRecurringNotification(id: String, title: String, body: String, firstDate: Date, interval: DateComponents, options: NotificationOptions?) async throws {
        logger.info("Planification de la notification récurrente \"\(id)\" commençant le \(firstDate)...")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        if let options = options {
            content.sound = options.sound ? .default : nil
            if let badge = options.badge {
                content.badge = NSNumber(value: badge)
            }
        }
        
        let firstTriggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: firstDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: firstTriggerComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            logger.info("Notification récurrente \"\(id)\" planifiée avec succès.")
        } catch {
            logger.error("Erreur lors de l'ajout de la notification récurrente \"\(id)\": \(error.localizedDescription)")
            throw NotificationError.schedulingFailed(error.localizedDescription)
        }
    }
    
    public func cancelNotification(id: String) async {
        logger.info("Annulation de la notification avec identifiant: \(id)...")
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
        logger.notice("Notification \"\(id)\" annulée (si elle existait).")
    }
    
    public func cancelAllNotifications() async {
        logger.info("Annulation de toutes les notifications planifiées...")
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        logger.notice("Toutes les notifications ont été annulées.")
    }
    
    public func getAllScheduledNotifications() async -> [ScheduledNotification] {
        logger.debug("Récupération de toutes les notifications planifiées...")
        
        let pendingRequests = await center.pendingNotificationRequests()
        let deliveredNotifications = await center.deliveredNotifications()
        
        var scheduledNotifications: [ScheduledNotification] = []
        
        for request in pendingRequests {
            var triggerDate: Date? = nil
            
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                triggerDate = nextTriggerDate
            } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                triggerDate = Date().addingTimeInterval(trigger.timeInterval)
            }
            
            if let date = triggerDate {
                let notification = ScheduledNotification(
                    id: request.identifier,
                    title: request.content.title,
                    body: request.content.body,
                    date: date,
                    isDelivered: false
                )
                scheduledNotifications.append(notification)
            }
        }
        
        for notification in deliveredNotifications {
            let deliveredNotification = ScheduledNotification(
                id: notification.request.identifier,
                title: notification.request.content.title,
                body: notification.request.content.body,
                date: notification.date,
                isDelivered: true
            )
            
            scheduledNotifications.append(deliveredNotification)
        }
        
        logger.info("Récupéré \(scheduledNotifications.count) notifications planifiées.")
        return scheduledNotifications
    }
    
    public func updateAppBadge(count: Int) async {
        logger.debug("Mise à jour du badge de l'application à \(count)...")
        let countToShow = max(0, count) // Assurer que le nombre n'est pas négatif
        
        #if os(iOS)
        // Sur iOS, on utilise UIApplication
        UIApplication.shared.applicationIconBadgeNumber = countToShow
        logger.info("Badge iOS mis à jour à \(countToShow).")
        
        #elseif os(macOS)
        // Sur macOS, on utilise NSApplication
        NSApplication.shared.dockTile.badgeLabel = countToShow > 0 ? "\(countToShow)" : nil
        logger.info("Badge macOS (Dock) mis à jour \(countToShow > 0 ? "à \(countToShow)" : "effacé").")
        #else
        // Plateforme non supportée pour le badge
        logger.warning("Mise à jour du badge non supportée sur cette plateforme.")
        #endif
    }
} 