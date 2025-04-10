import Foundation
import Combine
import SwiftUI

/// Jeton d'identification pour le suivi des performances d'une opération
public typealias PerformanceTrackingToken = UUID

/// Étapes de mesure des performances
public enum MeasurementStage {
    case start
    case end
}

/// Événement de performance
public struct PerformanceEvent {
    public let type: EventType
    
    public enum EventType {
        case memoryUsage
        case operationPerformance
    }
}

/// Problème de performance identifié
public struct PerformanceIssue {
    public let description: String
    public let severity: Severity
    public let timestamp: Date
    public let relatedOperation: String?
    
    public enum Severity {
        case low
        case medium
        case high
        case critical
    }
}

/// Résumé des métriques de performance
public struct PerformanceSummary {
    public let totalOperations: Int
    public let averageDuration: TimeInterval
    public let errorCount: Int
    public let peakMemoryUsage: UInt64
    public let averageMemoryUsage: UInt64
}

/// Métriques de performance détaillées
public struct PerformanceMetrics {
    public let cpuUsage: Double
    public let memoryUsage: UInt64
    public let diskOperations: Int
    public let networkOperations: Int
    public let operationCount: Int
    public let errors: [Error]
    
    public init(
        cpuUsage: Double = 0.0,
        memoryUsage: UInt64 = 0,
        diskOperations: Int = 0,
        networkOperations: Int = 0,
        operationCount: Int = 0,
        errors: [Error] = []
    ) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskOperations = diskOperations
        self.networkOperations = networkOperations
        self.operationCount = operationCount
        self.errors = errors
    }
}

/// Catégories d'opérations pour le monitoring
public enum OperationCategory: String {
    case database
    case network
    case rendering
    case fileSystem
    case computation
    case userInterface
    case background
    case other
}

/// État général de performance
public enum PerformanceState {
    case optimal
    case normal
    case warning
    case critical
}

/// Alerte de performance
public struct PerformanceAlert {
    public let message: String
    public let severity: PerformanceIssue.Severity
    public let relatedMetric: String
    public let timestamp: Date
}

/// Protocole unifié définissant un moniteur de performance
public protocol PerformanceMonitorProtocol: ObservableObject {
    // MARK: - États et métriques
    
    /// L'état général de performance actuel
    var performanceState: PerformanceState { get }
    
    /// Les métriques de performance en temps réel
    var metrics: PerformanceMetrics { get }
    
    /// Les alertes de performance actives
    var activeAlerts: [PerformanceAlert] { get }
    
    /// Conseils d'optimisation basés sur les métriques actuelles
    var optimizationTips: [String] { get }
    
    /// Indique si le monitoring est actuellement actif
    var isMonitoringActive: Bool { get }
    
    // MARK: - Publishers
    
    /// Publisher pour les événements de performance
    var performanceEventPublisher: AnyPublisher<PerformanceEvent, Never> { get }
    
    /// Publisher émettant des événements de performance en temps réel
    var performancePublisher: AnyPublisher<PerformanceEvent, Never> { get }
    
    // MARK: - Contrôle du monitoring
    
    /// Démarrer le monitoring
    func startMonitoring()
    
    /// Arrêter le monitoring
    func stopMonitoring()
    
    /// Réinitialiser les métriques accumulées
    func resetMetrics()
    
    // MARK: - Suivi des opérations
    
    /// Commence le suivi d'une opération spécifique
    func startTracking(operation: String, category: OperationCategory, metadata: [String: String]?) -> UUID
    
    /// Version simplifiée pour la compatibilité
    func startTracking(operation: String) -> UUID
    
    /// Termine le suivi d'une opération
    func endTracking(token: UUID, success: Bool)
    
    /// Termine le suivi avec plus de détails
    func endTracking(token: UUID, error: Error?, additionalMetadata: [String: String]?)
    
    /// Rapporte la performance d'une opération
    func reportPerformance(operation: String, duration: TimeInterval, metadata: [String: Any]?)
    
    /// Rapporte la performance d'une opération sans métadonnées
    func reportPerformance(operation: String, duration: TimeInterval)
    
    /// Démarre le chronomètre pour une opération
    func startTiming(for operation: String, metadata: [String: Any]?) -> PerformanceTrackingToken
    
    /// Termine le chronométrage d'une opération
    func endTiming(for token: PerformanceTrackingToken)
    
    /// Enregistre une erreur pour une opération
    func recordError(_ error: Error, forOperation operation: String)
    
    /// Démarre une opération
    func beginOperation(_ operation: String, metadata: [String: Any]?) -> UUID
    
    /// Termine une opération
    func endOperation(_ operationId: UUID)
    
    // MARK: - Mesure des ressources
    
    /// Enregistre l'utilisation mémoire pour une opération
    func recordMemoryUsage(for operation: String, stage: MeasurementStage)
    
    /// Journalise l'utilisation mémoire avec un contexte
    func logMemoryUsage(context: String)
    
    /// Obtient l'utilisation mémoire actuelle
    func getMemoryUsage() -> UInt64
    
    /// Journalise l'utilisation CPU avec un contexte
    func logCPUUsage(context: String)
    
    /// Obtient l'utilisation CPU actuelle
    func getCPUUsage() -> Double
    
    // MARK: - Rapports et analyse
    
    /// Génère un rapport de performance complet
    func generatePerformanceReport() -> Data?
    
    /// Détecte les problèmes potentiels de performance
    func detectPerformanceIssues() -> [PerformanceIssue]
    
    /// Récupère toutes les métriques
    func getAllMetrics() -> [Date: PerformanceMetrics]
    
    /// Obtient un résumé des performances
    func getSummary() -> PerformanceSummary
}

// MARK: - Implémentation par défaut de certaines méthodes

extension PerformanceMonitorProtocol {
    // Implémentations par défaut pour faciliter l'adoption du protocole
    
    public func startTracking(operation: String) -> UUID {
        return startTracking(operation: operation, category: .other, metadata: nil)
    }
    
    public func endTracking(token: UUID, success: Bool = true) {
        endTracking(token: token, error: success ? nil : NSError(domain: "PerformanceMonitor", code: -1, userInfo: nil), additionalMetadata: nil)
    }
    
    // Autres implémentations par défaut au besoin
} 