#!/usr/bin/env swift

import Foundation
import CoreData

/**
 * CoreDataOptimizer - Utilitaire d'optimisation avancée pour CoreData
 * 
 * Fonctionnalités principales:
 * 1. Diagnostic de modèle CoreData (index manquants, relations redondantes)
 * 2. Optimisation automatique de requêtes (propositions de fetchBatchSize, prefetching)
 * 3. Analyse de performances pour les types d'entités les plus utilisés
 * 4. Réparation des problèmes courants (inconsistances, création d'index)
 * 5. Génération de code pour migrations
 *
 * Usage:
 *   let optimizer = CoreDataOptimizer(container: persistenceController.container)
 *   let rapport = optimizer.diagnostiquerModele()
 *   optimizer.optimiserRequetes()
 */

public class CoreDataOptimizer {
    
    // Niveau de gravité pour les problèmes détectés
    public enum Severite: Int, Comparable {
        case info = 0
        case avertissement = 1
        case erreur = 2
        case critique = 3
        
        public static func < (lhs: Severite, rhs: Severite) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    
    // Structure représentant un problème détecté
    public struct ProblemeModele: Identifiable {
        public let id = UUID()
        public let entite: String
        public let attribut: String?
        public let description: String
        public let severite: Severite
        public let solutionSuggestion: String
        public let codeCorrection: String?
    }
    
    // Résultat d'analyse de performance
    public struct ResultatPerformance {
        public let entite: String
        public let tempsChargement: TimeInterval
        public let nombreEntites: Int
        public let tailleMemoire: Int
        public let suggestionsOptimisation: [String]
    }
    
    private let persistentContainer: NSPersistentContainer
    
    // Initialisation avec un container existant
    public init(container: NSPersistentContainer) {
        self.persistentContainer = container
    }
    
    // MARK: - Diagnostics du modèle
    
    /**
     * Analyse le modèle CoreData pour détecter des problèmes potentiels
     * - Identifie les attributs qui devraient être indexés
     * - Détecte les relations problématiques
     * - Vérifie la configuration pour optimiser les performances
     */
    public func diagnostiquerModele() -> [ProblemeModele] {
        let model = persistentContainer.managedObjectModel
        var problemes: [ProblemeModele] = []
        
        for entity in model.entities {
            // Vérification des index manquants pour les attributs souvent filtrés
            for property in entity.properties {
                if let attribute = property as? NSAttributeDescription {
                    // Vérification des attributs qui pourraient bénéficier d'un index
                    if !attribute.isIndexed && 
                       (attribute.name.lowercased().contains("id") || 
                        attribute.name.lowercased().contains("date") ||
                        attribute.name.lowercased().contains("name") ||
                        attribute.name.lowercased().contains("uuid")) {
                           
                        problemes.append(ProblemeModele(
                            entite: entity.name ?? "Inconnue",
                            attribut: attribute.name,
                            description: "Attribut \(attribute.name) pourrait bénéficier d'un index",
                            severite: .avertissement,
                            solutionSuggestion: "Ajouter un index pour améliorer les performances des requêtes",
                            codeCorrection: """
                            // Dans votre NSManagedObject subclass
                            @NSManaged public var \(attribute.name): \(attributeTypeString(attribute))
                            
                            // Dans CoreDataModel editor:
                            // 1. Sélectionnez l'attribut \(attribute.name)
                            // 2. Dans l'inspecteur Data Model, cochez 'Indexed'
                            """
                        ))
                    }
                    
                    // Vérification du type d'attribut pour UUID
                    if attribute.name.lowercased().contains("uuid") && attribute.attributeType != .UUIDAttributeType {
                        problemes.append(ProblemeModele(
                            entite: entity.name ?? "Inconnue",
                            attribut: attribute.name,
                            description: "Attribut UUID devrait utiliser le type UUID natif",
                            severite: .avertissement,
                            solutionSuggestion: "Changer le type d'attribut en UUID",
                            codeCorrection: nil
                        ))
                    }
                }
                
                // Analyse de relations pour détecter des problèmes potentiels
                if let relationship = property as? NSRelationshipDescription {
                    // Vérification des relations to-many sans inverse
                    if relationship.isToMany && relationship.inverseRelationship == nil {
                        problemes.append(ProblemeModele(
                            entite: entity.name ?? "Inconnue",
                            attribut: relationship.name,
                            description: "Relation to-many sans relation inverse",
                            severite: .erreur,
                            solutionSuggestion: "Définir une relation inverse pour éviter des problèmes de mémoire et de cohérence",
                            codeCorrection: nil
                        ))
                    }
                    
                    // Vérification des règles de suppression cascade appropriées
                    if relationship.isToMany && relationship.deleteRule == .nullifyDeleteRule {
                        problemes.append(ProblemeModele(
                            entite: entity.name ?? "Inconnue",
                            attribut: relationship.name,
                            description: "Relation to-many avec règle de suppression 'Nullify'",
                            severite: .avertissement,
                            solutionSuggestion: "Envisager une règle 'Cascade' ou 'No Action' selon la logique métier",
                            codeCorrection: nil
                        ))
                    }
                }
            }
            
            // Vérification d'entités lourdes sans fetchBatchSize par défaut
            if entity.properties.count > 8 {
                problemes.append(ProblemeModele(
                    entite: entity.name ?? "Inconnue",
                    attribut: nil,
                    description: "Entité avec beaucoup d'attributs (\(entity.properties.count))",
                    severite: .info,
                    solutionSuggestion: "Utilisez fetchBatchSize pour les requêtes sur cette entité",
                    codeCorrection: """
                    // Exemple de requête optimisée pour \(entity.name ?? "Entity")
                    let request = NSFetchRequest<\(entity.name ?? "Entity")>(entityName: "\(entity.name ?? "Entity")")
                    request.fetchBatchSize = 20
                    """
                ))
            }
        }
        
        // Vérification de l'utilisation du type de modèle CoreData
        let storeType = persistentContainer.persistentStoreDescriptions.first?.type
        if storeType == NSSQLiteStoreType {
            let storeOptions = persistentContainer.persistentStoreDescriptions.first?.options
            if storeOptions?[NSPersistentHistoryTrackingKey] as? Bool != true {
                problemes.append(ProblemeModele(
                    entite: "PersistentContainer",
                    attribut: nil,
                    description: "Suivi de l'historique non activé",
                    severite: .info,
                    solutionSuggestion: "Activer le suivi de l'historique pour de meilleures performances dans les contextes multi-threading",
                    codeCorrection: """
                    // Dans la configuration du container
                    let description = NSPersistentStoreDescription()
                    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                    container.persistentStoreDescriptions = [description]
                    """
                ))
            }
        }
        
        return problemes
    }
    
    // MARK: - Analyse de performance
    
    /**
     * Analyse les performances de requêtes pour chaque entité
     * et suggère des optimisations
     */
    public @MainActor func analyserPerformanceRequetes() -> [ResultatPerformance] {
        let context = persistentContainer.viewContext
        let model = persistentContainer.managedObjectModel
        var resultats: [ResultatPerformance] = []
        
        for entity in model.entities {
            guard let entityName = entity.name else { continue }
            
            // Mesurer le temps de chargement
            let startTime = CFAbsoluteTimeGetCurrent()
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.fetchLimit = 100 // Limiter pour ne pas surcharger la mémoire
            
            do {
                let objects = try context.fetch(request)
                let endTime = CFAbsoluteTimeGetCurrent()
                let loadTime = endTime - startTime
                
                var suggestions: [String] = []
                
                // Analyser le temps de chargement et faire des suggestions
                if loadTime > 0.1 && objects.count > 0 {
                    suggestions.append("Utiliser fetchBatchSize = \(min(20, objects.count))")
                }
                
                // Vérifier les attributs qui pourraient bénéficier du prefetching
                let toManyRelationships = entity.properties.compactMap { $0 as? NSRelationshipDescription }
                    .filter { $0.isToMany }
                
                if !toManyRelationships.isEmpty {
                    let relationshipNames = toManyRelationships.compactMap { $0.name }.joined(separator: ", ")
                    suggestions.append("Considérer relationshipKeyPathsForPrefetching: [\(relationshipNames)]")
                }
                
                // Estimer la taille mémoire (approximative)
                let memorySize = estimerTailleMemoire(objects: objects)
                
                resultats.append(ResultatPerformance(
                    entite: entityName,
                    tempsChargement: loadTime,
                    nombreEntites: objects.count,
                    tailleMemoire: memorySize,
                    suggestionsOptimisation: suggestions
                ))
            } catch {
                print("Erreur lors de l'analyse de \(entityName): \(error)")
            }
        }
        
        return resultats.sorted { $0.tempsChargement > $1.tempsChargement }
    }
    
    // MARK: - Optimisation
    
    /**
     * Applique automatiquement des optimisations au modèle CoreData
     * - Ajoute des index aux attributs souvent utilisés dans les requêtes
     * - Retourne les corrections appliquées
     */
    public func optimiserModele() -> [String] {
        let problemes = diagnostiquerModele()
        var corrections: [String] = []
        
        for probleme in problemes.filter({ $0.severite >= .avertissement }) {
            switch probleme.description {
            case let desc where desc.contains("pourrait bénéficier d'un index"):
                if let attribute = findAttribute(entityName: probleme.entite, attributeName: probleme.attribut ?? "") {
                    // Ajouter un index à l'attribut
                    attribute.isIndexed = true
                    corrections.append("Index ajouté à \(probleme.entite).\(probleme.attribut ?? "")")
                }
            default:
                break
            }
        }
        
        return corrections
    }
    
    /**
     * Génère un script de migration pour les modifications du modèle
     */
    public func genererScriptMigration() -> String {
        let model = persistentContainer.managedObjectModel
        var script = "// Script de migration généré le \(Date())\n\n"
        script += "import CoreData\n\n"
        script += "class MigrationManager {\n"
        script += "    static func performMigration(container: NSPersistentContainer, completion: @escaping (Error?) -> Void) {\n"
        script += "        let migrationPolicyDirectoryURL = URL(fileURLWithPath: \"MigrationPolicies\", isDirectory: true)\n"
        script += "        NSMigrationManager.migrationManagerClass = ExtendedMigrationManager.self\n\n"
        
        // Ajouter des politiques de migration personnalisées pour chaque entité
        for entity in model.entities {
            if let entityName = entity.name {
                script += "        // Politique de migration pour \(entityName)\n"
                script += "        NSEntityMigrationPolicy.registerMigrationPolicy(CustomMigrationPolicy.self, forEntityName: \"\(entityName)\")\n"
            }
        }
        
        script += "\n        // Exécuter la migration\n"
        script += "        container.loadPersistentStores { storeDescription, error in\n"
        script += "            completion(error)\n"
        script += "        }\n"
        script += "    }\n"
        script += "}\n\n"
        
        // Ajouter une classe de politique de migration personnalisée de base
        script += "class CustomMigrationPolicy: NSEntityMigrationPolicy {\n"
        script += "    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {\n"
        script += "        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)\n"
        script += "        // Personnaliser ici les migrations d'attributs\n"
        script += "    }\n"
        script += "}\n\n"
        
        // Ajouter une classe de gestionnaire de migration étendue
        script += "class ExtendedMigrationManager: NSMigrationManager {\n"
        script += "    override func sourceEntity(forEntityName entityName: String, in mapping: NSEntityMapping) -> NSEntityDescription? {\n"
        script += "        // Gérer ici les cas particuliers de renommage d'entités\n"
        script += "        return super.sourceEntity(forEntityName: entityName, in: mapping)\n"
        script += "    }\n"
        script += "}\n"
        
        return script
    }
    
    // MARK: - Utilitaires
    
    private func attributeTypeString(_ attribute: NSAttributeDescription) -> String {
        switch attribute.attributeType {
        case .stringAttributeType: return "String"
        case .integer16AttributeType, .integer32AttributeType, .integer64AttributeType: return "Int"
        case .doubleAttributeType: return "Double"
        case .floatAttributeType: return "Float"
        case .booleanAttributeType: return "Bool"
        case .dateAttributeType: return "Date"
        case .binaryDataAttributeType: return "Data"
        case .UUIDAttributeType: return "UUID"
        case .URIAttributeType: return "URL"
        default: return "Any"
        }
    }
    
    private func findAttribute(entityName: String, attributeName: String) -> NSAttributeDescription? {
        guard let entity = persistentContainer.managedObjectModel.entitiesByName[entityName],
              let attribute = entity.propertiesByName[attributeName] as? NSAttributeDescription else {
            return nil
        }
        return attribute
    }
    
    private func estimerTailleMemoire(objects: [NSManagedObject]) -> Int {
        guard !objects.isEmpty else { return 0 }
        
        // Calcul approximatif basé sur les types d'attributs
        let entity = objects[0].entity
        var baseSize = 0
        
        for property in entity.properties {
            if let attribute = property as? NSAttributeDescription {
                switch attribute.attributeType {
                case .stringAttributeType:
                    baseSize += 24  // Taille moyenne pour une chaîne
                case .integer16AttributeType:
                    baseSize += 2
                case .integer32AttributeType:
                    baseSize += 4
                case .integer64AttributeType:
                    baseSize += 8
                case .doubleAttributeType:
                    baseSize += 8
                case .floatAttributeType:
                    baseSize += 4
                case .booleanAttributeType:
                    baseSize += 1
                case .dateAttributeType:
                    baseSize += 8
                case .binaryDataAttributeType:
                    baseSize += 32  // Approximation pour un petit blob
                case .UUIDAttributeType:
                    baseSize += 16
                default:
                    baseSize += 8
                }
            }
        }
        
        return baseSize * objects.count
    }
    
    // MARK: - Analyse des requêtes pour détecter les problèmes courants
    
    /**
     * Analyse le code source pour détecter les problèmes courants dans les requêtes CoreData
     * - Mise en œuvre simplifiée ici, car l'analyse complète de code source nécessiterait un parser
     */
    public @MainActor func simulerAnalyseRequetes() -> [String] {
        return [
            "NSFetchRequest sans fetchBatchSize",
            "Utilisation de NSPredicate avec CONTAINS sans index",
            "NSFetchRequest sans try/catch",
            "try context.save() sans try/catch",
            "viewContext utilisé en dehors du thread principal",
            "NSBatchUpdateRequest sans try/catch"
        ]
    }
}

// Exemple d'utilisation:
//
// let container = NSPersistentContainer(name: "CardApp")
// let optimizer = CoreDataOptimizer(container: container)
// 
// let problemes = optimizer.diagnostiquerModele()
// problemes.forEach { probleme in
//     print("\(probleme.severite): \(probleme.entite).\(probleme.attribut ?? "") - \(probleme.description)")
//     print("Solution: \(probleme.solutionSuggestion)")
// }
// 
// let resultatsPerformance = optimizer.analyserPerformanceRequetes()
// resultatsPerformance.forEach { resultat in
//     print("\(resultat.entite): \(resultat.tempsChargement)s pour \(resultat.nombreEntites) objets")
//     resultat.suggestionsOptimisation.forEach { print("- \($0)") }
// }
// 
// let corrections = optimizer.optimiserModele()
// corrections.forEach { print("Correction appliquée: \($0)") }
// 
// let scriptMigration = optimizer.genererScriptMigration()
// print(scriptMigration) 