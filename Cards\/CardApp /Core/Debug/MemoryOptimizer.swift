import Foundation
import CoreData

/// Outil d'optimisation automatique de la mémoire
public final class MemoryOptimizer {
    private let lowMemoryThreshold: UInt64 = 50_000_000  // 50 MB
    
    /// Optimise automatiquement l'utilisation de la mémoire
    public func optimize(cacheManager: ExtendedCacheManager, context: NSManagedObjectContext) {
        let currentMemoryUsage = getMemoryUsage()
        
        if currentMemoryUsage > lowMemoryThreshold {
            // Stratégie progressive d'optimisation
            var optimizationLevel = 1
            var newUsage = currentMemoryUsage
            
            while newUsage > lowMemoryThreshold && optimizationLevel <= 3 {
                applyOptimization(level: optimizationLevel, cacheManager: cacheManager, context: context)
                optimizationLevel += 1
                newUsage = getMemoryUsage()
            }
        }
    }
    
    /// Applique un niveau spécifique d'optimisation
    private func applyOptimization(level: Int, cacheManager: ExtendedCacheManager, context: NSManagedObjectContext) {
        switch level {
        case 1:
            // Niveau 1: Réduire le cache
            cacheManager.adaptCacheSizeToAvailableMemory()
            
        case 2:
            // Niveau 2: Libérer le contexte CoreData
            context.refreshAllObjects()
            
        case 3:
            // Niveau 3: Effacer les caches
            cacheManager.clearAllCaches()
            
        default:
            break
        }
    }
    
    /// Obtient l'utilisation mémoire actuelle en octets
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
}
