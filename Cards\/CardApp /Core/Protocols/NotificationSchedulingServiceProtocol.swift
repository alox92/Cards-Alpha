import Foundation
import UserNotifications

/// Erreurs spécifiques au service de notifications
public enum NotificationError: LocalizedError {
    case schedulingFailed(String)
    case serviceDeallocated
    
    public var errorDescription: String? {
        switch self {
        case .schedulingFailed(let message):
            return "Échec de la planification de la notification : \(message)"
        case .serviceDeallocated:
            return "Le service de notifications a été désalloué"
        }
    }
}

/// Représente une notification planifiée
public struct ScheduledNotification: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let body: String
    public let date: Date
    public let isDelivered: Bool
    
    public init(id: String, title: String, body: String, date: Date, isDelivered: Bool = false) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.isDelivered = isDelivered
    }
}

/// Options pour programmer une notification
public struct NotificationOptions: Sendable {
    public let sound: Bool
    public let badge: Int?
    
    public init(sound: Bool = true, badge: Int? = nil) {
        self.sound = sound
        self.badge = badge
    }
}

/// Protocole pour le service de planification des notifications
@MainActor
public protocol NotificationSchedulingServiceProtocol: Sendable {
    /// Demande l'autorisation d'envoyer des notifications
    func requestAuthorization() async throws -> Bool
    
    /// Vérifie si les notifications sont autorisées
    func checkAuthorizationStatus() async -> UNAuthorizationStatus
    
    /// Planifie une notification à une date spécifique
    func scheduleNotification(id: String, title: String, body: String, date: Date, options: NotificationOptions?) async throws
    
    /// Planifie une notification récurrente
    func scheduleRecurringNotification(id: String, title: String, body: String, firstDate: Date, interval: DateComponents, options: NotificationOptions?) async throws
    
    /// Annule une notification spécifique
    func cancelNotification(id: String) async
    
    /// Annule toutes les notifications
    func cancelAllNotifications() async
    
    /// Récupère toutes les notifications planifiées
    func getAllScheduledNotifications() async -> [ScheduledNotification]
    
    /// Met à jour le badge de l'application
    func updateAppBadge(count: Int) async
} 