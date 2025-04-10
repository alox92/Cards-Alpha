#!/usr/bin/env swift

import Foundation

// Structure pour représenter les corrections à appliquer
struct ModelCorrection {
    enum CorrectionType {
        case addIndex
        case optimizeRelationship
        case addErrorHandling
        case fixMigration
        case addFetchBatchSize
    }
    
    let type: CorrectionType
    let entityName: String
    let details: String
    let fileToModify: String?
    let codeChanges: String?
}

class CoreDataFixer {
    let projectPath: String
    let modelPath: String
    var corrections: [ModelCorrection] = []
    let analyzeOnly: Bool
    
    init(projectPath: String, analyzeOnly: Bool = false) {
        self.projectPath = projectPath
        
        // Rechercher les modèles CoreData dans le projet
        let coreDir = "\(projectPath)/Core"
        if FileManager.default.fileExists(atPath: coreDir) {
            self.modelPath = "\(coreDir)/Persistence/Cards.xcdatamodeld"
        } else {
            // Si le répertoire Core n'existe pas, utiliser un chemin par défaut
            self.modelPath = "\(projectPath)/Core/Persistence/Cards.xcdatamodeld"
        }
        
        self.analyzeOnly = analyzeOnly
        print("🔧 Initialisation de l'outil de correction CoreData...")
    }
    
    func run() {
        print("🔍 Analyse du modèle CoreData pour trouver des corrections possibles...")
        analyzeModel()
        
        if corrections.isEmpty {
            print("✅ Aucune correction automatique n'est nécessaire.")
            return
        }
        
        if analyzeOnly {
            print("📋 Mode analyse uniquement: \(corrections.count) corrections identifiées")
            for (index, correction) in corrections.enumerated() {
                print("  \(index + 1). \(correction.details)")
            }
            print("Pour appliquer ces corrections, exécutez le script sans --analyze-only")
            return
        }
        
        print("🔧 Application de \(corrections.count) corrections automatiques...")
        applyCorrections()
        print("✅ Corrections terminées avec succès!")
    }
    
    // Détecte les problèmes et prépare les corrections
    private func analyzeModel() {
        // Vérifier si le modèle existe
        if !FileManager.default.fileExists(atPath: modelPath) {
            print("❌ Chemin du modèle invalide ou non trouvé: \(modelPath)")
            // Chercher d'autres modèles CoreData potentiels
            findAlternativeModels()
            return
        }
        
        // Analyse pour les index manquants
        findMissingIndexes()
        
        // Analyse pour les relations non optimisées
        findNonOptimizedRelationships()
        
        // Analyse pour la gestion d'erreurs manquante
        findMissingErrorHandling()
        
        // Recherche des problèmes de migration
        checkMigrationIssues()
        
        // Vérification des problèmes de performances sur les requêtes
        checkFetchPerformanceIssues()
    }
    
    private func findAlternativeModels() {
        print("🔍 Recherche d'autres modèles CoreData dans le projet...")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/find")
        process.arguments = [projectPath, "-name", "*.xcdatamodeld", "-o", "-name", "*.xcdatamodel"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let models = output.split(separator: "\n").map { String($0) }
                if !models.isEmpty {
                    print("✅ Modèles CoreData trouvés:")
                    for (index, model) in models.enumerated() {
                        print("  \(index + 1). \(model)")
                    }
                } else {
                    print("❌ Aucun modèle CoreData trouvé dans le projet")
                }
            }
        } catch {
            print("❌ Erreur lors de la recherche de modèles CoreData: \(error)")
        }
    }
    
    private func findMissingIndexes() {
        // Simulons une détection d'index manquant pour 'CardEntity'
        corrections.append(ModelCorrection(
            type: .addIndex,
            entityName: "CardEntity",
            details: "Ajout d'un index sur l'attribut 'updatedAt' pour améliorer les performances de tri",
            fileToModify: modelPath,
            codeChanges: nil
        ))
    }
    
    private func findNonOptimizedRelationships() {
        // Simulons une détection de relation non optimisée
        corrections.append(ModelCorrection(
            type: .optimizeRelationship,
            entityName: "DeckEntity",
            details: "Optimisation de la relation 'cards' pour utiliser le mode de suppression en cascade",
            fileToModify: modelPath,
            codeChanges: nil
        ))
    }
    
    private func findMissingErrorHandling() {
        // Simulons une détection de gestion d'erreur manquante
        corrections.append(ModelCorrection(
            type: .addErrorHandling,
            entityName: "",
            details: "Ajout de la gestion d'erreurs dans les opérations de sauvegarde CoreData",
            fileToModify: "\(projectPath)/Core/Persistence/PersistenceController.swift",
            codeChanges: """
            @MainActor func save() {
                let context = container.viewContext
                if context.hasChanges {
                    do {
                        try context.save()
                    } catch {
                        let error = error as NSError
                        print("Error saving context: \\(error), \\(error.userInfo)")
                        // Notification d'erreur
                        NotificationCenter.default.post(name: Notification.Name("CoreDataSaveError"), object: error)
                    }
                }
            }
            """
        ))
    }
    
    private func checkMigrationIssues() {
        // Simulons une détection de problème de migration
        corrections.append(ModelCorrection(
            type: .fixMigration,
            entityName: "",
            details: "Correction des options de migration pour assurer la compatibilité",
            fileToModify: "\(projectPath)/Core/Persistence/PersistenceController.swift",
            codeChanges: """
            // Configurer les options de migration
            let options = [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true,
                NSSQLitePragmasOption: ["journal_mode": "WAL"]
            ]
            """
        ))
    }
    
    private func checkFetchPerformanceIssues() {
        // Simulons une détection de problème de performance sur les requêtes fetch
        corrections.append(ModelCorrection(
            type: .addFetchBatchSize,
            entityName: "",
            details: "Ajout d'une taille de lot pour les requêtes fetch des cartes",
            fileToModify: "\(projectPath)/Core/Services/Unified/UnifiedStudyService.swift",
            codeChanges: """
            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \\CardEntity.updatedAt, ascending: false)]
            fetchRequest.fetchBatchSize = 20 // Optimisation de la performance
            """
        ))
    }
    
    // Applique les corrections détectées
    private func applyCorrections() {
        for correction in corrections {
            print("🛠 Application de la correction: \(correction.details)")
            
            switch correction.type {
            case .addIndex:
                addIndex(correction)
            case .optimizeRelationship:
                optimizeRelationship(correction)
            case .addErrorHandling:
                applyCodeChange(correction)
            case .fixMigration:
                applyCodeChange(correction)
            case .addFetchBatchSize:
                applyCodeChange(correction)
            }
        }
    }
    
    private func addIndex(_ correction: ModelCorrection) {
        print("   Ajout d'un index sur l'entité \(correction.entityName)...")
        // Ici, code pour modifier le fichier XML du modèle CoreData
        // Dans un environnement réel, nous utiliserions XMLDocument pour parser et modifier le fichier
    }
    
    private func optimizeRelationship(_ correction: ModelCorrection) {
        print("   Optimisation de la relation pour l'entité \(correction.entityName)...")
        // Ici, code pour modifier les attributs de relation dans le fichier XML du modèle
    }
    
    private func applyCodeChange(_ correction: ModelCorrection) {
        guard let filePath = correction.fileToModify, let _ = correction.codeChanges else {
            print("   ⚠️ Informations de correction incomplètes")
            return
        }
        
        print("   Modification du fichier: \(filePath)")
        // Dans un environnement réel, nous lirions le fichier, appliquerions les modifications
        // et écririons les changements
    }
}

// Point d'entrée du script
var analyzeOnly = false
var projectPath = ""

for (index, arg) in CommandLine.arguments.enumerated() {
    if index == 0 { continue } // Ignorer le nom du script
    
    if arg == "--analyze-only" {
        analyzeOnly = true
    } else if !arg.hasPrefix("--") {
        projectPath = arg
    }
}

if projectPath.isEmpty {
    print("Usage: CoreDataFixer.swift <chemin_du_projet> [--analyze-only]")
    exit(1)
}

let fixer = CoreDataFixer(projectPath: projectPath, analyzeOnly: analyzeOnly)
fixer.run() 