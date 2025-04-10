#!/usr/bin/env swift

import Foundation
import CoreData

// MARK: - Modèles d'analyse

enum IssueSeverity: String, Codable {
    case critical = "CRITICAL"
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"
    
    var value: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

enum IssueType: String, Codable {
    case missingIndex = "missing_index"
    case inconsistentRelationship = "inconsistent_relationship"
    case inefficientFetch = "inefficient_fetch"
    case mainThreadOperation = "main_thread_operation"
    case missingBatchOperations = "missing_batch_operations"
    case suboptimalModelDesign = "suboptimal_model_design"
    case missingVersioning = "missing_versioning"
    case redundantAttributes = "redundant_attributes"
}

struct CoreDataIssue: Codable {
    let entity: String
    let attribute: String?
    let relationship: String?
    let issueType: IssueType
    let severity: IssueSeverity
    let message: String
    let suggestion: String
    let impact: String
    
    var toDictionary: [String: Any] {
        return [
            "entity": entity,
            "attribute": attribute as Any,
            "relationship": relationship as Any,
            "issue_type": issueType.rawValue,
            "severity": severity.rawValue,
            "severity_value": severity.value,
            "message": message,
            "suggestion": suggestion,
            "impact": impact
        ]
    }
}

struct CoreDataStats: Codable {
    let entityCount: Int
    let attributeCount: Int
    let relationshipCount: Int
    let indexCount: Int
    let fetchRequestCount: Int
    let compositeIndexCount: Int
    let derivedAttributeCount: Int
    let entitiesWithSubentities: Int
    
    var toDictionary: [String: Any] {
        return [
            "entity_count": entityCount,
            "attribute_count": attributeCount,
            "relationship_count": relationshipCount,
            "index_count": indexCount,
            "fetch_request_count": fetchRequestCount,
            "composite_index_count": compositeIndexCount,
            "derived_attribute_count": derivedAttributeCount,
            "entities_with_subentities": entitiesWithSubentities
        ]
    }
}

class CoreDataOptimizer {
    let modelURL: URL
    var issues: [CoreDataIssue] = []
    var stats: CoreDataStats?
    
    init(modelURL: URL) {
        self.modelURL = modelURL
    }
    
    // MARK: - Diagnostic principal
    
    func runDiagnostic() -> Bool {
        print("🔍 Exécution du diagnostic CoreData sur \(modelURL.lastPathComponent)...")
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("❌ Erreur: Impossible de charger le modèle CoreData à partir de \(modelURL.path)")
            return false
        }
        
        collectModelStats(model)
        analyzeEntityIndexes(model)
        analyzeRelationships(model)
        analyzeAttributeTypes(model)
        analyzeInheritance(model)
        analyzeFetchedProperties(model)
        suggestOptimizations(model)
        
        generateReport()
        return true
    }
    
    // MARK: - Collecte de statistiques
    
    func collectModelStats(_ model: NSManagedObjectModel) {
        var attributeCount = 0
        var relationshipCount = 0
        var indexCount = 0
        var fetchRequestCount = model.fetchRequestTemplates.count
        var compositeIndexCount = 0
        var derivedAttributeCount = 0
        var entitiesWithSubentities = 0
        
        for entity in model.entities {
            attributeCount += entity.properties.filter { $0 is NSAttributeDescription }.count
            relationshipCount += entity.properties.filter { $0 is NSRelationshipDescription }.count
            
            // Compter les index
            if let indices = entity.indices {
                indexCount += indices.count
                compositeIndexCount += indices.filter { $0.elements.count > 1 }.count
            }
            
            // Entités avec sous-entités
            if entity.subentities.count > 0 {
                entitiesWithSubentities += 1
            }
            
            // Attributs dérivés (approximation)
            for property in entity.properties {
                if let attribute = property as? NSAttributeDescription, 
                   attribute.isTransient && attribute.renamingIdentifier != nil {
                    derivedAttributeCount += 1
                }
            }
        }
        
        stats = CoreDataStats(
            entityCount: model.entities.count,
            attributeCount: attributeCount,
            relationshipCount: relationshipCount,
            indexCount: indexCount,
            fetchRequestCount: fetchRequestCount,
            compositeIndexCount: compositeIndexCount,
            derivedAttributeCount: derivedAttributeCount,
            entitiesWithSubentities: entitiesWithSubentities
        )
    }
    
    // MARK: - Analyse des entités et attributs
    
    func analyzeEntityIndexes(_ model: NSManagedObjectModel) {
        // Pour chaque entité dans le modèle
        for entity in model.entities {
            // 1. Vérifier les attributs qui devraient probablement être indexés
            let indexedAttributes = Set((entity.indices ?? []).flatMap { $0.elements.map { $0.name } })
            
            for property in entity.properties {
                guard let attribute = property as? NSAttributeDescription else { continue }
                
                let name = attribute.name
                let type = attribute.attributeType
                
                // Attributs courants qui bénéficient de l'indexation
                if !indexedAttributes.contains(name) {
                    if (name.hasSuffix("ID") || name.hasSuffix("Id") || name == "id" || name == "identifier") {
                        addIndexIssue(entity: entity.name ?? "Unknown", attribute: name)
                    }
                    else if (name.contains("date") || name.contains("Date") || name.contains("time") || name.contains("Time")) {
                        // Date/time fields often used in sorted fetch requests
                        addIndexIssue(entity: entity.name ?? "Unknown", attribute: name)
                    }
                }
            }
        }
    }
    
    func analyzeRelationships(_ model: NSManagedObjectModel) {
        for entity in model.entities {
            // Vérifier les relations inverses manquantes
            for property in entity.properties {
                guard let relationship = property as? NSRelationshipDescription else { continue }
                
                // 1. Vérifier si la relation inverse est définie
                if relationship.inverseRelationship == nil && !relationship.isTransient {
                    issues.append(CoreDataIssue(
                        entity: entity.name ?? "Unknown",
                        attribute: nil,
                        relationship: relationship.name,
                        issueType: .inconsistentRelationship,
                        severity: .medium,
                        message: "Relation sans inverse défini",
                        suggestion: "Définir une relation inverse pour maintenir la cohérence des données",
                        impact: "Les relations sans inverse peuvent causer des incohérences et des fuites mémoire"
                    ))
                }
                
                // 2. Vérifier la cohérence des règles de suppression
                if let inverse = relationship.inverseRelationship {
                    if relationship.isToMany && inverse.isToMany {
                        // Relation many-to-many
                        if relationship.deleteRule != .nullifyDeleteRule {
                            issues.append(CoreDataIssue(
                                entity: entity.name ?? "Unknown",
                                attribute: nil,
                                relationship: relationship.name,
                                issueType: .inconsistentRelationship,
                                severity: .medium,
                                message: "Règle de suppression non optimale pour relation many-to-many",
                                suggestion: "Utiliser .nullifyDeleteRule pour les relations many-to-many",
                                impact: "Peut causer des suppressions en cascade non intentionnelles"
                            ))
                        }
                    } else if relationship.isToMany && !inverse.isToMany {
                        // Relation one-to-many
                        if relationship.deleteRule == .cascadeDeleteRule && inverse.deleteRule == .cascadeDeleteRule {
                            issues.append(CoreDataIssue(
                                entity: entity.name ?? "Unknown",
                                attribute: nil,
                                relationship: relationship.name,
                                issueType: .inconsistentRelationship,
                                severity: .high,
                                message: "Règles de suppression en cascade des deux côtés d'une relation",
                                suggestion: "Utiliser cascade sur un seul côté de la relation",
                                impact: "Peut causer des boucles infinies ou des suppressions inattendues"
                            ))
                        }
                    }
                }
            }
        }
    }
    
    func analyzeAttributeTypes(_ model: NSManagedObjectModel) {
        for entity in model.entities {
            for property in entity.properties {
                guard let attribute = property as? NSAttributeDescription else { continue }
                
                // 1. Vérifier les types d'attributs inefficaces
                if attribute.attributeType == .binaryDataAttributeType && !attribute.allowsExternalBinaryDataStorage {
                    issues.append(CoreDataIssue(
                        entity: entity.name ?? "Unknown",
                        attribute: attribute.name,
                        relationship: nil,
                        issueType: .suboptimalModelDesign,
                        severity: .medium,
                        message: "Données binaires stockées sans stockage externe",
                        suggestion: "Activer allowsExternalBinaryDataStorage pour les données binaires volumineuses",
                        impact: "Peut causer des problèmes de performance et de consommation mémoire"
                    ))
                }
                
                // 2. Vérifier les attributs transformables sans transformer personnalisé
                if attribute.attributeType == .transformableAttributeType && attribute.valueTransformerName == nil {
                    issues.append(CoreDataIssue(
                        entity: entity.name ?? "Unknown",
                        attribute: attribute.name,
                        relationship: nil,
                        issueType: .suboptimalModelDesign,
                        severity: .low,
                        message: "Attribut transformable sans transformateur personnalisé spécifié",
                        suggestion: "Spécifier un transformateur personnalisé ou utiliser Codable",
                        impact: "Peut causer des problèmes de compatibilité ou de performance"
                    ))
                }
            }
        }
    }
    
    func analyzeInheritance(_ model: NSManagedObjectModel) {
        for entity in model.entities {
            // Vérifier la profondeur de l'héritage
            var depth = 0
            var currentEntity: NSEntityDescription? = entity
            
            while let parent = currentEntity?.superentity {
                depth += 1
                currentEntity = parent
            }
            
            if depth > 2 {
                issues.append(CoreDataIssue(
                    entity: entity.name ?? "Unknown",
                    attribute: nil,
                    relationship: nil,
                    issueType: .suboptimalModelDesign,
                    severity: .medium,
                    message: "Hiérarchie d'héritage profonde (profondeur: \(depth))",
                    suggestion: "Limiter la profondeur d'héritage à 1-2 niveaux pour de meilleures performances",
                    impact: "Les hiérarchies profondes peuvent affecter les performances de requête"
                ))
            }
        }
    }
    
    func analyzeFetchedProperties(_ model: NSManagedObjectModel) {
        for entity in model.entities {
            for property in entity.properties {
                if property is NSFetchedPropertyDescription {
                    issues.append(CoreDataIssue(
                        entity: entity.name ?? "Unknown",
                        attribute: property.name,
                        relationship: nil,
                        issueType: .inefficientFetch,
                        severity: .low,
                        message: "Utilisation de propriété fetch qui peut être inefficace",
                        suggestion: "Envisager de remplacer par des relations standard ou des requêtes explicites",
                        impact: "Les propriétés fetch peuvent avoir un impact sur la performance"
                    ))
                }
            }
        }
    }
    
    // MARK: - Suggestions d'optimisation
    
    func suggestOptimizations(_ model: NSManagedObjectModel) {
        // Suggérer des index composites pour les entités avec plusieurs attributs indexés
        for entity in model.entities {
            let indexedAttributes = (entity.indices ?? []).flatMap { $0.elements.map { $0.name } }
            let attributeSet = Set(indexedAttributes)
            
            if attributeSet.count > 1 && entity.indices?.filter({ $0.elements.count > 1 }).isEmpty ?? true {
                // Si plusieurs attributs sont indexés individuellement mais pas ensemble
                issues.append(CoreDataIssue(
                    entity: entity.name ?? "Unknown",
                    attribute: nil,
                    relationship: nil,
                    issueType: .suboptimalModelDesign,
                    severity: .low,
                    message: "Plusieurs attributs indexés individuellement",
                    suggestion: "Envisager d'ajouter un index composite si ces attributs sont souvent utilisés ensemble dans les requêtes",
                    impact: "Les index composites peuvent améliorer la performance des requêtes complexes"
                ))
            }
        }
        
        // Vérifier si le modèle a un versionnage
        if !modelHasVersionInfo(model) {
            issues.append(CoreDataIssue(
                entity: "Model",
                attribute: nil,
                relationship: nil,
                issueType: .missingVersioning,
                severity: .high,
                message: "Le modèle ne semble pas avoir d'informations de versionnage",
                suggestion: "Ajouter des informations de versionnage et un mappage de modèle pour les migrations futures",
                impact: "Les mises à jour d'applications peuvent échouer sans gestion appropriée des versions de modèle"
            ))
        }
    }
    
    // MARK: - Utilitaires
    
    func modelHasVersionInfo(_ model: NSManagedObjectModel) -> Bool {
        return model.versionIdentifiers.count > 0
    }
    
    func addIndexIssue(entity: String, attribute: String) {
        issues.append(CoreDataIssue(
            entity: entity,
            attribute: attribute,
            relationship: nil,
            issueType: .missingIndex,
            severity: .medium,
            message: "Attribut non indexé qui pourrait bénéficier d'un index",
            suggestion: "Ajouter un index pour améliorer les performances de recherche et de tri",
            impact: "Peut ralentir les requêtes qui filtrent ou trient par cet attribut"
        ))
    }
    
    // MARK: - Génération de rapport
    
    func generateReport() {
        guard let stats = stats else { return }
        
        // Afficher un résumé des problèmes
        print("\n📊 Résumé du diagnostic CoreData:")
        print("- Entités: \(stats.entityCount)")
        print("- Attributs: \(stats.attributeCount)")
        print("- Relations: \(stats.relationshipCount)")
        print("- Index: \(stats.indexCount)")
        print("- Problèmes trouvés: \(issues.count)")
        
        if !issues.isEmpty {
            print("\n⚠️ Problèmes détectés:")
            let criticalIssues = issues.filter { $0.severity == .critical }
            let highIssues = issues.filter { $0.severity == .high }
            let mediumIssues = issues.filter { $0.severity == .medium }
            
            if !criticalIssues.isEmpty {
                print("🔴 \(criticalIssues.count) problèmes critiques")
            }
            
            if !highIssues.isEmpty {
                print("🟠 \(highIssues.count) problèmes élevés")
            }
            
            if !mediumIssues.isEmpty {
                print("🟡 \(mediumIssues.count) problèmes moyens")
            }
        }
        
        // Générer le rapport JSON
        generateJsonReport()
    }
    
    func generateJsonReport() {
        var report: [String: Any] = [:]
        
        // Métadonnées du rapport
        report["model_path"] = modelURL.path
        report["model_name"] = modelURL.deletingPathExtension().lastPathComponent
        report["timestamp"] = ISO8601DateFormatter().string(from: Date())
        
        // Statistiques
        if let stats = stats {
            report["stats"] = stats.toDictionary
        }
        
        // Problèmes
        let issuesDict = issues.map { $0.toDictionary }
        report["issues"] = issuesDict
        report["issues_count"] = issues.count
        report["issues_by_severity"] = [
            "critical": issues.filter { $0.severity == .critical }.count,
            "high": issues.filter { $0.severity == .high }.count,
            "medium": issues.filter { $0.severity == .medium }.count,
            "low": issues.filter { $0.severity == .low }.count
        ]
        report["issues_by_type"] = IssueType.allCases.reduce(into: [String: Int]()) { result, type in
            result[type.rawValue] = issues.filter { $0.issueType == type }.count
        }
        
        // Écrire dans un fichier
        let outputPath = "coredata_diagnostic_report.json"
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: report, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            do {
                try jsonString.write(toFile: outputPath, atomically: true, encoding: .utf8)
                print("\n✅ Rapport écrit dans \(outputPath)")
            } catch {
                print("❌ Erreur lors de l'écriture du rapport: \(error)")
            }
        } else {
            print("❌ Erreur lors de la sérialisation du rapport en JSON")
        }
    }
}

// MARK: - Programme principal

// Vérifier les arguments
if CommandLine.arguments.count < 2 {
    print("Usage: \(CommandLine.arguments[0]) <chemin-du-modele-coredata.xcdatamodeld>")
    print("Exemple: \(CommandLine.arguments[0]) /chemin/vers/MonProjet.xcdatamodeld")
    exit(1)
}

// Obtenir le chemin du modèle
let modelPath = CommandLine.arguments[1]
let modelURL = URL(fileURLWithPath: modelPath)

// Vérifier si le fichier existe
if !FileManager.default.fileExists(atPath: modelPath) {
    print("❌ Erreur: Le fichier \(modelPath) n'existe pas")
    exit(1)
}

// Extension pour IssueType
extension IssueType: CaseIterable {}

// Exécuter le diagnostic
let optimizer = CoreDataOptimizer(modelURL: modelURL)
if !optimizer.runDiagnostic() {
    print("❌ Échec du diagnostic")
    exit(1)
}

print("✅ Diagnostic terminé avec succès") 