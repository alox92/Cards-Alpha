#!/usr/bin/env swift

import Foundation

// MARK: - Models

struct CoreDataModelInfo {
    let entities: [EntityInfo]
    let relationships: [RelationshipInfo]
    let fetchRequests: [FetchRequestInfo]
    let configurations: [String]
}

struct EntityInfo {
    let name: String
    let attributes: [AttributeInfo]
    let relationships: [RelationshipInfo]
    let indexes: [IndexInfo]
    let isUsed: Bool
    let fetchRequests: [FetchRequestInfo]
}

struct AttributeInfo {
    let name: String
    let type: String
    let isOptional: Bool
    let isTransient: Bool
    let hasDefaultValue: Bool
    let isIndexed: Bool
}

struct RelationshipInfo {
    let name: String
    let sourceEntity: String
    let destinationEntity: String
    let isToMany: Bool
    let isOptional: Bool
    let inverseRelationship: String?
    let deleteRule: String
}

struct IndexInfo {
    let name: String
    let attributes: [String]
    let isUnique: Bool
}

struct FetchRequestInfo {
    let name: String
    let entity: String
    let predicate: String?
    let sortDescriptors: [String]?
}

enum DiagnosticSeverity: String {
    case critical = "CRITIQUE"
    case warning = "AVERTISSEMENT"
    case improvement = "AMÉLIORATION"
    case info = "INFO"
}

struct Diagnostic {
    let entity: String?
    let attribute: String?
    let relationship: String?
    let severity: DiagnosticSeverity
    let message: String
    let recommendation: String
}

// MARK: - CoreData Diagnostic Tool

class CoreDataDiagnosticTool {
    private let projectPath: String
    private let outputPath: String
    private let xcdatamodelURLs: [URL]
    private var allDiagnostics: [Diagnostic] = []
    
    init(projectPath: String, outputPath: String) {
        self.projectPath = projectPath
        self.outputPath = outputPath
        
        // Trouver tous les modèles CoreData (.xcdatamodeld)
        let fileManager = FileManager.default
        
        let modelURLs = try! fileManager.contentsOfDirectory(at: URL(fileURLWithPath: projectPath), 
                                               includingPropertiesForKeys: nil, 
                                               options: [.skipsHiddenFiles, .skipsPackageDescendants])
            .filter { $0.pathExtension == "xcdatamodeld" }
        
        // Trouver toutes les versions dans chaque modèle
        self.xcdatamodelURLs = modelURLs.flatMap { modelURL in
            (try? fileManager.contentsOfDirectory(at: modelURL, 
                                                includingPropertiesForKeys: nil, 
                                                options: [.skipsHiddenFiles]))?.filter { $0.pathExtension == "xcdatamodel" } ?? []
        }
        
        if self.xcdatamodelURLs.isEmpty {
            print("❌ ERREUR: Aucun modèle CoreData (.xcdatamodel) trouvé dans \(projectPath)")
            exit(1)
        }
    }
    
    // MARK: - Analyse principale
    
    func runDiagnostic() {
        print("🔍 Analyse des modèles CoreData dans \(projectPath)...")
        
        for modelURL in xcdatamodelURLs {
            analyzeModel(at: modelURL)
        }
        
        analyzeCodebase()
        
        // Générer un rapport
        generateReport()
        
        // Proposer des optimisations
        suggestOptimizations()
    }
    
    // MARK: - Analyse de modèle
    
    private func analyzeModel(at url: URL) {
        print("📊 Analyse du modèle: \(url.lastPathComponent)")
        
        // Lire le contenu du fichier de modèle
        guard let xmlData = try? Data(contentsOf: url.appendingPathComponent("contents"), options: .mappedIfSafe),
              let xmlString = String(data: xmlData, encoding: .utf8) else {
            print("❌ Impossible de lire le fichier de modèle: \(url.path)")
            return
        }
        
        // Analyser les entités et leurs attributs
        analyzeEntities(xmlString, modelName: url.deletingLastPathComponent().lastPathComponent)
        
        // Analyser les relations
        analyzeRelationships(xmlString)
        
        // Analyser les requêtes prédéfinies
        analyzeFetchRequests(xmlString)
        
        // Vérifier les index
        analyzeIndexes(xmlString)
    }
    
    private func analyzeEntities(_ xmlString: String, modelName: String) {
        // Implémentation simplifiée: utilisation d'expressions régulières pour analyser le XML
        // Dans une implémentation réelle, il serait préférable d'utiliser un parser XML complet
        
        // Récupérer toutes les entités
        let entityRegex = try! NSRegularExpression(pattern: "<entity name=\"([^\"]+)\"[^>]*>", options: [])
        let matches = entityRegex.matches(in: xmlString, options: [], range: NSRange(location: 0, length: xmlString.count))
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: xmlString) {
                let entityName = String(xmlString[range])
                diagnoseEntity(entityName, modelName: modelName, xmlString: xmlString)
            }
        }
    }
    
    private func diagnoseEntity(_ entityName: String, modelName: String, xmlString: String) {
        // Vérifier si l'entité a un attribut d'ID explicite
        let idAttributeRegex = try! NSRegularExpression(pattern: "<entity name=\"\(entityName)\"[^>]*>[\\s\\S]*?<attribute name=\"id\"[^>]*>", options: [])
        let hasIdAttribute = idAttributeRegex.firstMatch(in: xmlString, options: [], range: NSRange(location: 0, length: xmlString.count)) != nil
        
        if !hasIdAttribute {
            allDiagnostics.append(Diagnostic(
                entity: entityName,
                attribute: nil,
                relationship: nil,
                severity: .improvement,
                message: "L'entité \(entityName) n'a pas d'attribut 'id' explicite",
                recommendation: "Considérez l'ajout d'un attribut UUID 'id' pour faciliter l'identification unique et les opérations de fusion"
            ))
        }
        
        // Vérifier les attributs
        let attributeRegex = try! NSRegularExpression(pattern: "<entity name=\"\(entityName)\"[^>]*>[\\s\\S]*?<attribute name=\"([^\"]+)\"[^>]*type=\"([^\"]+)\"[^>]*?>", options: [])
        let attributeMatches = attributeRegex.matches(in: xmlString, options: [], range: NSRange(location: 0, length: xmlString.count))
        
        var attributeCount = 0
        for match in attributeMatches {
            attributeCount += 1
            
            if let nameRange = Range(match.range(at: 1), in: xmlString),
               let typeRange = Range(match.range(at: 2), in: xmlString) {
                let attributeName = String(xmlString[nameRange])
                let attributeType = String(xmlString[typeRange])
                
                diagnoseAttribute(attributeName, type: attributeType, entityName: entityName)
            }
        }
        
        if attributeCount > 15 {
            allDiagnostics.append(Diagnostic(
                entity: entityName,
                attribute: nil,
                relationship: nil,
                severity: .warning,
                message: "L'entité \(entityName) a \(attributeCount) attributs, ce qui est élevé",
                recommendation: "Envisagez de décomposer cette entité en plusieurs entités plus petites pour améliorer les performances"
            ))
        }
    }
    
    private func diagnoseAttribute(_ attributeName: String, type: String, entityName: String) {
        // Vérifier les types d'attributs problématiques
        if type == "Binary" {
            allDiagnostics.append(Diagnostic(
                entity: entityName,
                attribute: attributeName,
                relationship: nil,
                severity: .warning,
                message: "L'attribut \(attributeName) est de type Binary",
                recommendation: "Envisagez de stocker les données binaires volumineuses sur le système de fichiers et de ne conserver qu'une référence dans CoreData"
            ))
        }
        
        if type == "Transformable" {
            allDiagnostics.append(Diagnostic(
                entity: entityName,
                attribute: attributeName,
                relationship: nil,
                severity: .warning,
                message: "L'attribut \(attributeName) est de type Transformable",
                recommendation: "Assurez-vous d'utiliser une classe NSSecureUnarchiveFromData pour la transformation. Les anciens NSKeyedUnarchiveFromData présentent des risques de sécurité"
            ))
        }
    }
    
    private func analyzeRelationships(_ xmlString: String) {
        // Implémenter l'analyse des relations
        let relationshipRegex = try! NSRegularExpression(pattern: "<relationship name=\"([^\"]+)\"[^>]*destinationEntity=\"([^\"]+)\"[^>]*toMany=\"(YES|NO)\"[^>]*deleteRule=\"([^\"]+)\"[^>]*>", options: [])
        let matches = relationshipRegex.matches(in: xmlString, options: [], range: NSRange(location: 0, length: xmlString.count))
        
        for match in matches {
            if let nameRange = Range(match.range(at: 1), in: xmlString),
               let destRange = Range(match.range(at: 2), in: xmlString),
               let toManyRange = Range(match.range(at: 3), in: xmlString),
               let deleteRuleRange = Range(match.range(at: 4), in: xmlString) {
                
                let name = String(xmlString[nameRange])
                let destination = String(xmlString[destRange])
                let isToMany = xmlString[toManyRange] == "YES"
                let deleteRule = String(xmlString[deleteRuleRange])
                
                // Vérifier les règles de suppression
                if isToMany && deleteRule == "Cascade" {
                    allDiagnostics.append(Diagnostic(
                        entity: nil,
                        attribute: nil,
                        relationship: name,
                        severity: .warning,
                        message: "La relation to-many '\(name)' vers '\(destination)' utilise la règle de suppression Cascade",
                        recommendation: "Pour les relations to-many, considérez plutôt Nullify pour éviter la suppression involontaire de nombreux objets"
                    ))
                }
                
                if deleteRule == "No Action" {
                    allDiagnostics.append(Diagnostic(
                        entity: nil,
                        attribute: nil,
                        relationship: name,
                        severity: .improvement,
                        message: "La relation '\(name)' utilise la règle de suppression 'No Action'",
                        recommendation: "Spécifiez une règle de suppression explicite (Nullify, Cascade, ou Deny) pour assurer l'intégrité des données"
                    ))
                }
            }
        }
    }
    
    private func analyzeIndexes(_ xmlString: String) {
        // Rechercher des attributs fréquemment utilisés dans les requêtes mais non indexés
        let elementRegex = try! NSRegularExpression(pattern: "<fetchRequest name=\"([^\"]+)\"[^>]*entity=\"([^\"]+)\"[^>]*>([\\s\\S]*?)</fetchRequest>", options: [])
        let matches = elementRegex.matches(in: xmlString, options: [], range: NSRange(location: 0, length: xmlString.count))
        
        var predicateAttributes: [String: Int] = [:]
        
        for match in matches {
            if let contentRange = Range(match.range(at: 3), in: xmlString) {
                let content = String(xmlString[contentRange])
                
                // Chercher les attributs dans les prédicats
                let attributeRegex = try! NSRegularExpression(pattern: "key=\"([^\"]+)\"", options: [])
                let attributeMatches = attributeRegex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
                
                for attrMatch in attributeMatches {
                    if let attrRange = Range(attrMatch.range(at: 1), in: content) {
                        let attribute = String(content[attrRange])
                        predicateAttributes[attribute, default: 0] += 1
                    }
                }
            }
        }
        
        // Vérifier si les attributs fréquemment utilisés sont indexés
        for (attribute, count) in predicateAttributes where count > 2 {
            // Vérifier si cet attribut est indexé
            let indexedRegex = try! NSRegularExpression(pattern: "<attribute name=\"\(attribute)\"[^>]*indexed=\"YES\"", options: [])
            let isIndexed = indexedRegex.firstMatch(in: xmlString, options: [], range: NSRange(location: 0, length: xmlString.count)) != nil
            
            if !isIndexed {
                allDiagnostics.append(Diagnostic(
                    entity: nil,
                    attribute: attribute,
                    relationship: nil,
                    severity: .improvement,
                    message: "L'attribut '\(attribute)' est utilisé dans \(count) prédicats mais n'est pas indexé",
                    recommendation: "Envisagez d'indexer cet attribut pour améliorer les performances des requêtes"
                ))
            }
        }
    }
    
    private func analyzeFetchRequests(_ xmlString: String) {
        // Analyser les requêtes prédéfinies pour détecter des problèmes potentiels
        let fetchRequestRegex = try! NSRegularExpression(pattern: "<fetchRequest name=\"([^\"]+)\"[^>]*entity=\"([^\"]+)\"[^>]*>([\\s\\S]*?)</fetchRequest>", options: [])
        let fetchRequestRegex = try! NSRegularExpression(pattern: "<fetchRequest name=\"([^\"]+)\"[^>]*entity=\"([^\"]+)\"[^>]*>([\\s\\S]*?)</fetchRequest>", options: [])Request.fetchBatchSize = 20
        let matches = fetchRequestRegex.matches(in: xmlString, options: [], range: NSRange(location: 0, length: xmlString.count))
        
        for match in matches {
            if let nameRange = Range(match.range(at: 1), in: xmlString),
               let entityRange = Range(match.range(at: 2), in: xmlString),
               let contentRange = Range(match.range(at: 3), in: xmlString) {
                
                let name = String(xmlString[nameRange])
                let entity = String(xmlString[entityRange])
                let content = String(xmlString[contentRange])
                
                // Vérifier si la requête contient un tri
                let hasSortDescriptors = content.contains("<sortDescriptor")
                
                if !hasSortDescriptors {
                    allDiagnostics.append(Diagnostic(
                        entity: entity,
                        attribute: nil,
                        relationship: nil,
                        severity: .improvement,
                        message: "La requête '\(name)' pour l'entité '\(entity)' n'a pas de descripteurs de tri",
                        recommendation: "Ajoutez des descripteurs de tri à cette requête pour garantir un ordre de résultats cohérent"
                    ))
                }
                
                // Vérifier si la requête contient un prédicat
                let hasPredicate = content.contains("<predicateString")
                
                if !hasPredicate && content.contains("fetchLimit=\"0\"") {
                    allDiagnostics.append(Diagnostic(
                        entity: entity,
                        attribute: nil,
                        relationship: nil,
                        severity: .warning,
                        message: "La requête '\(name)' récupère toutes les instances de '\(entity)' sans prédicat ni limite",
                        recommendation: "Ajoutez un prédicat ou une limite à cette requête pour éviter de charger un nombre excessif d'objets"
                    ))
                }
            }
        }
    }
    
    // MARK: - Analyse du code source
    
    private func analyzeCodebase() {
        print("📝 Analyse du code source pour les usages CoreData...")
        
        // Chercher tous les fichiers Swift
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(atPath: projectPath)
        
        var swiftFiles: [String] = []
        while let file = enumerator?.nextObject() as? String {
            if file.hasSuffix(".swift") {
                swiftFiles.append(file)
            }
        }
        
        // Analyser chaque fichier Swift
        for file in swiftFiles {
            analyzeSwiftFile(atPath: "\(projectPath)/\(file)")
        }
    }
    
    private func analyzeSwiftFile(atPath path: String) {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return
        }
        
        // Vérifier les problèmes de concurrence CoreData
        checkConcurrencyIssues(in: content, file: path)
        
        // Vérifier la gestion des erreurs dans les requêtes
        checkErrorHandling(in: content, file: path)
        
        // Vérifier l'utilisation de contextes
        checkContextUsage(in: content, file: path)
        
        // Vérifier les performances des requêtes
        checkFetchPerformance(in: content, file: path)
    }
    
    private @MainActor func checkConcurrencyIssues(in content: String, file: String) {
        // Détection du contexte principal utilisé dans des tâches d'arrière-plan
        if content.contains("viewContext") && 
           (content.contains("DispatchQueue.global") || content.contains("Task") || content.contains("async")) {
            
            allDiagnostics.append(Diagnostic(
                entity: nil,
                attribute: nil,
                relationship: nil,
                severity: .critical,
                message: "Utilisation potentielle du viewContext dans un thread d'arrière-plan dans \(file)",
                recommendation: "Utilisez newBackgroundContext() pour les opérations en arrière-plan, et viewContext uniquement sur le thread principal"
            ))
        }
        
        // Détection de contextes sans performAndWait
        if content.contains("context.save()") && !content.contains("performAndWait") && !content.contains("performBlock") {
            allDiagnostics.append(Diagnostic(
                entity: nil,
                attribute: nil,
                relationship: nil,
                severity: .warning,
                message: "Sauvegarde de contexte sans performAndWait/performBlock dans \(file)",
                recommendation: "Utilisez context.performAndWait { try? context.save() } pour garantir une exécution sur le thread approprié"
            ))
        }
    }
    
    private func checkErrorHandling(in content: String, file: String) {
        // Détecter les fetch sans try/catch
        if content.contains("fetch(") && !content.contains("try") {
            allDiagnostics.append(Diagnostic(
                entity: nil,
                attribute: nil,
                relationship: nil,
                severity: .warning,
                message: "Opération fetch() sans gestion d'erreur dans \(file)",
                recommendation: "Utilisez try/catch pour gérer les erreurs de fetch()"
            ))
        }
        
        // Détecter les save sans try/catch
        if content.contains("context.save()") && !content.contains("try context.save()") {
            allDiagnostics.append(Diagnostic(
                entity: nil,
                attribute: nil,
                relationship: nil,
                severity: .warning,
                message: "Sauvegarde de contexte sans gestion d'erreur dans \(file)",
                recommendation: "Utilisez try/catch pour gérer les erreurs de save()"
            ))
        }
    }
    
    private func checkContextUsage(in content: String, file: String) {
        // Vérifier si le même contexte est utilisé dans plusieurs closures asynchrones
        if (content.contains("let context = ") || content.contains("var context = ")) && 
           (content.contains("async") || content.contains("DispatchQueue")) &&
           content.contains("completion(") {
            
            allDiagnostics.append(Diagnostic(
                entity: nil,
                attribute: nil,
                relationship: nil,
                severity: .warning,
                message: "Possible utilisation du même contexte CoreData dans plusieurs closures asynchrones dans \(file)",
                recommendation: "Créez un nouveau contexte pour chaque opération asynchrone avec newBackgroundContext()"
            ))
        }
    }
    
    private func checkFetchPerformance(in content: String, file: String) {
        // Vérifier l'utilisation de propertiesToFetch et propertiesToGroupBy
        if content.contains("NSFetchRequest") && 
           !content.contains("propertiesToFetch") && 
           !content.contains("propertiesToGroupBy") {
            
            allDiagnostics.append(Diagnostic(
                entity: nil,
                attribute: nil,
                relationship: nil,
                severity: .improvement,
                message: "Les requêtes dans \(file) pourraient bénéficier de propertiesToFetch/propertiesToGroupBy",
                recommendation: "Utilisez propertiesToFetch pour limiter les attributs récupérés et améliorer les performances"
            ))
        }
        
        // Vérifier l'utilisation de batchDeleteRequest
        if content.contains("delete(") && content.contains("fetch(") && 
           !content.contains("batchDeleteRequest") {
            
            allDiagnostics.append(Diagnostic(
                entity: nil,
                attribute: nil,
                relationship: nil,
                severity: .improvement,
                message: "Suppression d'objets un par un dans \(file)",
                recommendation: "Utilisez NSBatchDeleteRequest pour des suppressions plus efficaces de nombreux objets"
            ))
        }
    }
    
    // MARK: - Génération de rapport
    
    private func generateReport() {
        // Trier les diagnostics par sévérité
        let sortedDiagnostics = allDiagnostics.sorted {
            let severityOrder: [DiagnosticSeverity] = [.critical, .warning, .improvement, .info]
            let order1 = severityOrder.firstIndex(of: $0.severity) ?? 0
            let order2 = severityOrder.firstIndex(of: $1.severity) ?? 0
            return order1 < order2
        }
        
        // Créer le rapport en JSON
        var reportDict: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "project": projectPath,
            "modelCount": xcdatamodelURLs.count,
            "diagnosticCount": sortedDiagnostics.count,
            "diagnostics": sortedDiagnostics.map { diagnostic in
                var dict: [String: Any] = [
                    "severity": diagnostic.severity.rawValue,
                    "message": diagnostic.message,
                    "recommendation": diagnostic.recommendation
                ]
                
                if let entity = diagnostic.entity {
                    dict["entity"] = entity
                }
                
                if let attribute = diagnostic.attribute {
                    dict["attribute"] = attribute
                }
                
                if let relationship = diagnostic.relationship {
                    dict["relationship"] = relationship
                }
                
                return dict
            }
        ]
        
        // Ajouter des statistiques
        let criticalCount = sortedDiagnostics.filter { $0.severity == .critical }.count
        let warningCount = sortedDiagnostics.filter { $0.severity == .warning }.count
        let improvementCount = sortedDiagnostics.filter { $0.severity == .improvement }.count
        let infoCount = sortedDiagnostics.filter { $0.severity == .info }.count
        
        reportDict["statistics"] = [
            "critical": criticalCount,
            "warning": warningCount,
            "improvement": improvementCount,
            "info": infoCount
        ]
        
        // Convertir en JSON
        let jsonData = try! JSONSerialization.data(withJSONObject: reportDict, options: [.prettyPrinted])
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Enregistrer dans un fichier
        try? jsonString.write(toFile: outputPath, atomically: true, encoding: .utf8)
        
        // Afficher un résumé
        print("\n📊 Résumé du diagnostic CoreData:")
        print("-----------------------------")
        print("🔴 Critiques: \(criticalCount)")
        print("🟠 Avertissements: \(warningCount)")
        print("🟡 Améliorations: \(improvementCount)")
        print("🔵 Infos: \(infoCount)")
        print("-----------------------------")
        print("Rapport enregistré dans: \(outputPath)")
    }
    
    // MARK: - Suggestions d'optimisation
    
    private func suggestOptimizations() {
        print("\n🚀 Suggestions d'optimisations pour CoreData:")
        
        // Suggestion 1: Migration vers NSPersistentCloudKitContainer si approprié
        print("\n1. Évaluer la migration vers NSPersistentCloudKitContainer")
        print("   - Permet la synchronisation iCloud pour le stockage CoreData")
        print("   - Facilite le partage de données entre appareils")
        
        // Suggestion 2: Utilisation de NSBatchInsertRequest
        print("\n2. Utiliser NSBatchInsertRequest pour les insertions massives")
        print("   - Jusqu'à 10x plus rapide pour insérer de grandes quantités de données")
        print("   - Réduit considérablement l'utilisation de la mémoire")
        
        // Suggestion 3: Profiling avec Instruments
        print("\n3. Profiler l'application avec Instruments")
        print("   - Utilisez Core Data Instrument pour identifier les goulots d'étranglement")
        print("   - Surveillez les fuites de mémoire liées aux objets CoreData")
        
        // Suggestion 4: Optimisation du modèle pour les performances
        print("\n4. Optimiser la conception du modèle")
        print("   - Décomposer les entités volumineuses")
        print("   - Externaliser les données binaires")
        print("   - Utiliser des index pour les attributs fréquemment interrogés")
        
        // Suggestion 5: Optimisation des requêtes
        print("\n5. Optimiser les requêtes")
        print("   - Limiter les propriétés récupérées avec propertiesToFetch")
        print("   - Utiliser des prédicats composés avec NSCompoundPredicate")
        print("   - Considérer l'utilisation de NSExpression pour les agrégations")
    }
}

// MARK: - Point d'entrée principal

func main() {
    // Analyser les arguments de ligne de commande
    let arguments = CommandLine.arguments
    
    guard arguments.count >= 2 else {
        print("Usage: \(arguments[0]) <chemin_du_projet> [chemin_de_sortie]")
        print("  <chemin_du_projet>: Chemin vers le dossier racine du projet Swift")
        print("  [chemin_de_sortie]: Chemin pour enregistrer le rapport JSON (par défaut: ./coredata_diagnostic.json)")
        exit(1)
    }
    
    let projectPath = arguments[1]
    let outputPath = arguments.count > 2 ? arguments[2] : "./coredata_diagnostic.json"
    
    // Vérifier le chemin du projet
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    
    guard fileManager.fileExists(atPath: projectPath, isDirectory: &isDirectory) && isDirectory.boolValue else {
        print("❌ ERREUR: Le chemin du projet n'existe pas ou n'est pas un dossier: \(projectPath)")
        exit(1)
    }
    
    // Exécuter l'outil de diagnostic
    let tool = CoreDataDiagnosticTool(projectPath: projectPath, outputPath: outputPath)
    tool.runDiagnostic()
}

// Démarrer l'exécution
main() 