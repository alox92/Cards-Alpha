import Foundation
import SwiftUI
import CoreData

/// Visualiseur de problèmes de concurrence
@MainActor
public struct ConcurrencyVisualizer {
    /// Opérations asynchrones en cours
    private static var activeOperations: [UUID: (String, Date)] = [:]
    private static var operationLog: [(id: UUID, name: String, start: Date, end: Date?)] = []
    private static let lock = NSLock()
    
    /// Commence à suivre une opération asynchrone
    public static func trackOperation(_ name: String) -> UUID {
        let id = UUID()
        lock.lock()
        activeOperations[id] = (name, Date())
        lock.unlock()
        return id
    }
    
    /// Signale la fin d'une opération
    public static func endOperation(_ id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let (name, start) = activeOperations[id] else { return }
        activeOperations.removeValue(forKey: id)
        operationLog.append((id, name, start, Date()))
    }
    
    /// Génère un rapport visuel des opérations concurrentes
    public static func generateReport() -> String {
        lock.lock()
        defer { lock.unlock() }
        
        var report = "=== Rapport de Concurrence ===\n\n"
        
        // Analyser les chevauchements temporels
        var overlappingOps: [(String, String, TimeInterval)] = []
        
        for i in 0..<operationLog.count {
            let op1 = operationLog[i]
            guard let end1 = op1.end else { continue }
            
            for j in (i+1)..<operationLog.count {
                let op2 = operationLog[j]
                guard let end2 = op2.end else { continue }
                
                // Vérifier si les opérations se chevauchent
                if (op1.start < end2 && end1 > op2.start) {
                    let overlapStart = max(op1.start, op2.start)
                    let overlapEnd = min(end1, end2)
                    let overlap = overlapEnd.timeIntervalSince(overlapStart)
                    
                    if overlap > 0.01 { // Plus de 10ms de chevauchement
                        overlappingOps.append((op1.name, op2.name, overlap))
                    }
                }
            }
        }
        
        report += "Opérations concurrentes détectées: \(overlappingOps.count)\n\n"
        
        for (op1, op2, overlap) in overlappingOps {
            report += "• \"\(op1)\" et \"\(op2)\" se chevauchent pendant \(String(format: "%.2f", overlap * 1000))ms\n"
        }
        
        return report
    }
}
