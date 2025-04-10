import Foundation
import Combine
import SwiftUI

/// Moniteur de performance vide qui ne fait rien
/// Utilisé comme fallback quand aucun moniteur de performance réel n'est disponible
public class EmptyPerformanceMonitor: ObservableObject, PerformanceMonitorProtocol {
    // MARK: - États et métriques
    
    public var performanceState: PerformanceState = .optimal
    
    public var metrics: PerformanceMetrics = PerformanceMetrics()
    
    public var activeAlerts: [PerformanceAlert] = []
    
    public var optimizationTips: [String] = []
    
    public var isMonitoringActive: Bool = false
    
    // MARK: - Publishers
    
    private let eventSubject = PassthroughSubject<PerformanceEvent, Never>()
    
    public var performanceEventPublisher: AnyPublisher<PerformanceEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }
    
    public var performancePublisher: AnyPublisher<PerformanceEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialisation
    
    public init() {
        // Rien à initialiser
    }
    
    // MARK: - Contrôle du monitoring
    
    public func startMonitoring() {
        // Ne fait rien
    }
    
    public func stopMonitoring() {
        // Ne fait rien
    }
    
    public func resetMetrics() {
        // Ne fait rien
    }
    
    // MARK: - Suivi des opérations
    
    public func startTracking(operation: String, category: OperationCategory, metadata: [String: String]?) -> UUID {
        return UUID()
    }
    
    public func startTracking(operation: String) -> UUID {
        return UUID()
    }
    
    public func endTracking(token: UUID, success: Bool) {
        // Ne fait rien
    }
    
    public func endTracking(token: UUID, error: Error?, additionalMetadata: [String: String]?) {
        // Ne fait rien
    }
    
    public func reportPerformance(operation: String, duration: TimeInterval, metadata: [String: Any]?) {
        // Ne fait rien
    }
    
    public func reportPerformance(operation: String, duration: TimeInterval) {
        // Ne fait rien
    }
    
    public func startTiming(for operation: String, metadata: [String: Any]?) -> PerformanceTrackingToken {
        return UUID()
    }
    
    public func endTiming(for token: PerformanceTrackingToken) {
        // Ne fait rien
    }
    
    public func recordError(_ error: Error, forOperation operation: String) {
        // Ne fait rien
    }
    
    public func beginOperation(_ operation: String, metadata: [String: Any]?) -> UUID {
        return UUID()
    }
    
    public func endOperation(_ operationId: UUID) {
        // Ne fait rien
    }
    
    // MARK: - Mesure des ressources
    
    public func recordMemoryUsage(for operation: String, stage: MeasurementStage) {
        // Ne fait rien
    }
    
    public func logMemoryUsage(context: String) {
        // Ne fait rien
    }
    
    public func getMemoryUsage() -> UInt64 {
        return 0
    }
    
    public func logCPUUsage(context: String) {
        // Ne fait rien
    }
    
    public func getCPUUsage() -> Double {
        return 0.0
    }
    
    // MARK: - Rapports et analyse
    
    public func generatePerformanceReport() -> Data? {
        return nil
    }
    
    public func detectPerformanceIssues() -> [PerformanceIssue] {
        return []
    }
    
    public func getAllMetrics() -> [Date: PerformanceMetrics] {
        return [:]
    }
    
    public func getSummary() -> PerformanceSummary {
        return PerformanceSummary(
            totalOperations: 0,
            averageDuration: 0,
            errorCount: 0,
            peakMemoryUsage: 0,
            averageMemoryUsage: 0
        )
    }
} 