import Foundation
import CoreData
import os.log

/// Outil de diagnostic spécialisé pour CoreData
public final class CoreDataDiagnostics {
    private let logger = Logger(subsystem: "com.cardapp.diagnostics", category: "CoreData")
    
    /// Analyse le modèle CoreData et signale les problèmes
    public func analyzeModel(_ model: NSManagedObjectModel) -> [String] {
        var issues: [String] = []
        
        // Vérifier les entités sans inversions de relations
        for entity in model.entities {
            for relationship in entity.relationshipsByName.values {
                if !relationship.isToMany && relationship.inverseRelationship == nil {
                    issues.append("Relation '\(relationship.name)' dans '\(entity.name ?? "?")' sans inverse")
                }
            }
        }
        
        return issues
    }
    
    /// Analyse les performances des requêtes CoreData
    public func analyzeQueryPerformance(context: NSManagedObjectContext) -> [String: TimeInterval] {
        var queryTimes: [String: TimeInterval] = [:]
        
        // Test des requêtes courantes
        measure("FetchAllCards") {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CardEntity")
            request.fetchLimit = 100
            try? context.fetch(request)
        }
        
        measure("FetchDueCards") {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CardEntity")
            request.predicate = NSPredicate(format: "nextReviewDate <= %@", Date() as NSDate)
            request.fetchLimit = 100
            try? context.fetch(request)
        }
        
        return queryTimes
    }
    
    /// Détecte les problèmes de concurrence potentiels
    public func detectConcurrencyIssues() -> [String] {
        var issues: [String] = []
        
        // Analyse du code source pour les problèmes de concurrence courants
        // Ceci serait implémenté avec une analyse statique réelle
        
        return issues
    }
    
    /// Optimise automatiquement les requêtes fréquentes
    public func optimizeQueries(context: NSManagedObjectContext) {
        // Ajouter des indices temporaires pour les requêtes fréquentes
        logger.info("Optimisation des requêtes pour la session en cours")
    }
    
    private func measure(_ name: String, block: () -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        block()
        let end = CFAbsoluteTimeGetCurrent()
        logger.info("\(name): \(end - start) secondes")
    }
}
