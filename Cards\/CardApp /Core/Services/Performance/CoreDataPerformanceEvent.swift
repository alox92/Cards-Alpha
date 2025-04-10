import Foundation

/// Événements de performance liés à CoreData
/// Utilisé pour suivre les différents types d'événements de performance
public enum CoreDataPerformanceEvent {
    /// Une requête a été optimisée
    case requestOptimized(entityName: String, optimizationTime: TimeInterval)
    
    /// Une requête a été exécutée
    case queryExecuted(entityName: String, resultCount: Int, executionTime: TimeInterval)
    
    /// Une requête lente a été détectée
    case slowQueryDetected(entityName: String, executionTime: TimeInterval, predicate: String?)
    
    /// Une opération par lots a été complétée
    case batchOperationCompleted(entityName: String, objectCount: Int, executionTime: TimeInterval)
    
    /// Un contexte a été sauvegardé
    case contextSaved(insertedCount: Int, updatedCount: Int, deletedCount: Int, saveTime: TimeInterval)
    
    /// L'empreinte mémoire a été réduite
    case memoryFootprintReduced
    
    /// Description lisible de l'événement
    public var description: String {
        switch self {
        case .requestOptimized(let entityName, let time):
            return "Requête optimisée pour \(entityName) en \(String(format: "%.2f", time * 1000)) ms"
        case .queryExecuted(let entityName, let count, let time):
            return "Requête exécutée: \(count) résultats de \(entityName) en \(String(format: "%.2f", time * 1000)) ms"
        case .slowQueryDetected(let entityName, let time, let predicate):
            return "REQUÊTE LENTE: \(entityName) (\(String(format: "%.2f", time * 1000)) ms) - Prédicat: \(predicate ?? "aucun")"
        case .batchOperationCompleted(let entityName, let count, let time):
            return "Opération par lots: \(count) objets \(entityName) traités en \(String(format: "%.2f", time * 1000)) ms"
        case .contextSaved(let inserted, let updated, let deleted, let time):
            return "Contexte sauvegardé: +\(inserted) Δ\(updated) -\(deleted) en \(String(format: "%.2f", time * 1000)) ms"
        case .memoryFootprintReduced:
            return "Empreinte mémoire réduite"
        }
    }
} 