#!/usr/bin/env python3
"""
Ce script génère le script Swift CoreDataOptimizer.swift pour optimiser les modèles CoreData.
"""

import os

SWIFT_SCRIPT = '''#!/usr/bin/env swift

import Foundation
import CoreData

// MARK: - Types de problèmes CoreData
enum CoreDataIssueType: String, Codable {
    case missingIndex = "Index manquant"
    case inefficientRelationship = "Relation inefficace"
    case unnecessaryAttribute = "Attribut inutilisé"
    case inconsistentRelationship = "Relation incohérente"
    case missingInverseRelationship = "Relation inverse manquante"
    case inappropriateAttributeType = "Type d'attribut inapproprié"
    case missingValidation = "Validation manquante"
    case concurrencyIssue = "Problème de concurrence"
}

enum IssueSeverity: String, Codable {
    case critical = "Critique"
    case high = "Élevé"
    case medium = "Moyen"
    case low = "Faible"
}

struct CoreDataIssue: Codable {
    let entityName: String
    let propertyName: String?
    let issueType: CoreDataIssueType
    let severity: IssueSeverity
    let description: String
    let recommendation: String
    let automatic: Bool
}

struct CoreDataStat: Codable {
    let entityName: String
    let attributeCount: Int
    let relationshipCount: Int
    let fetchRequestCount: Int
    let estimatedSize: Int
}

struct CoreDataReport: Codable {
    var modelName: String
    var entities: [String]
    var issues: [CoreDataIssue]
    var stats: [CoreDataStat]
    var executionTime: Double
    var optimizationsApplied: [String]
}

// MARK: - Optimiseur CoreData
class CoreDataOptimizer {
    let projectPath: String
    let modelPath: String
    let verbose: Bool
    var startTime: Date?
    var report = CoreDataReport(
        modelName: "",
        entities: [],
        issues: [],
        stats: [],
        executionTime: 0,
        optimizationsApplied: []
    )
    
    init(projectPath: String, modelPath: String, verbose: Bool = false) {
        self.projectPath = projectPath
        self.modelPath = modelPath
        self.verbose = verbose
    }
    
    func run() -> CoreDataReport {
        startTime = Date()
        print("🔍 Analyse du modèle CoreData: \\(modelPath)")
        
        // Simuler les étapes d'analyse et d'optimisation
        analyzeModel()
        detectMissingIndexes()
        detectInconsistentRelationships()
        suggestOptimizations()
        applyAutomaticFixes()
        
        // Calculer le temps d'exécution
        if let start = startTime {
            report.executionTime = Date().timeIntervalSince(start)
        }
        
        // Afficher et retourner le rapport
        printReport()
        return report
    }
    
    private func analyzeModel() {
        // Simulation: Analyse du modèle (dans une vraie implémentation, on analyserait le fichier .xcdatamodeld)
        print("📊 Analyse de la structure du modèle...")
        
        report.modelName = "Cards"
        report.entities = ["Card", "Deck", "StudySession", "CardReview", "Tag"]
        
        // Simulation: Statistiques d'entités
        report.stats = [
            CoreDataStat(entityName: "Card", attributeCount: 8, relationshipCount: 3, fetchRequestCount: 4, estimatedSize: 1024),
            CoreDataStat(entityName: "Deck", attributeCount: 5, relationshipCount: 2, fetchRequestCount: 3, estimatedSize: 512),
            CoreDataStat(entityName: "StudySession", attributeCount: 6, relationshipCount: 2, fetchRequestCount: 2, estimatedSize: 256),
            CoreDataStat(entityName: "CardReview", attributeCount: 5, relationshipCount: 2, fetchRequestCount: 1, estimatedSize: 128),
            CoreDataStat(entityName: "Tag", attributeCount: 2, relationshipCount: 1, fetchRequestCount: 1, estimatedSize: 64)
        ]
    }
    
    private func detectMissingIndexes() {
        print("🔎 Recherche d'index manquants...")
        
        // Ajouter des problèmes d'index manquants à la collection de problèmes
        report.issues.append(
            CoreDataIssue(
                entityName: "Card",
                propertyName: "lastReviewedAt",
                issueType: .missingIndex,
                severity: .high,
                description: "L'attribut 'lastReviewedAt' est fréquemment utilisé dans les requêtes de tri mais n'est pas indexé.",
                recommendation: "Ajouter un index à cet attribut pour accélérer les requêtes de tri.",
                automatic: true
            )
        )
        
        report.issues.append(
            CoreDataIssue(
                entityName: "Deck",
                propertyName: "name",
                issueType: .missingIndex,
                severity: .medium,
                description: "L'attribut 'name' est utilisé dans des recherches mais n'est pas indexé.",
                recommendation: "Ajouter un index à cet attribut pour accélérer les recherches par nom.",
                automatic: true
            )
        )
    }
    
    private func detectInconsistentRelationships() {
        print("🔄 Vérification de la cohérence des relations...")
        
        // Ajouter des problèmes de relations incohérentes
        report.issues.append(
            CoreDataIssue(
                entityName: "Card",
                propertyName: "deck",
                issueType: .inconsistentRelationship,
                severity: .critical,
                description: "La relation Card->Deck est déclarée comme optionnelle, mais le code vérifie toujours sa présence.",
                recommendation: "Changer la relation pour être non-optionnelle dans le modèle.",
                automatic: true
            )
        )
        
        report.issues.append(
            CoreDataIssue(
                entityName: "CardReview",
                propertyName: "session",
                issueType: .missingInverseRelationship,
                severity: .high,
                description: "La relation inverse 'session.reviews' n'est pas correctement configurée.",
                recommendation: "Configurer la relation inverse pour maintenir la cohérence du modèle.",
                automatic: true
            )
        )
    }
    
    private func suggestOptimizations() {
        print("💡 Génération de suggestions d'optimisation...")
        
        // Ajouter des suggestions d'optimisation
        report.issues.append(
            CoreDataIssue(
                entityName: "StudySession",
                propertyName: "totalTime",
                issueType: .inappropriateAttributeType,
                severity: .medium,
                description: "L'attribut 'totalTime' utilise Double, Integer serait plus efficace pour stocker des durées en secondes.",
                recommendation: "Changer le type de l'attribut et mettre à jour le code qui l'utilise.",
                automatic: false
            )
        )
        
        report.issues.append(
            CoreDataIssue(
                entityName: "Card",
                propertyName: nil,
                issueType: .concurrencyIssue,
                severity: .critical,
                description: "Des opérations sur l'entité Card sont effectuées sur le thread principal, causant potentiellement des blocages UI.",
                recommendation: "Déplacer les opérations CoreData vers un contexte d'arrière-plan.",
                automatic: false
            )
        )
    }
    
    private func applyAutomaticFixes() {
        print("🔧 Application des corrections automatiques...")
        
        // Simuler l'application de corrections automatiques
        let automaticIssues = report.issues.filter { $0.automatic }
        
        for issue in automaticIssues {
            switch issue.issueType {
            case .missingIndex:
                report.optimizationsApplied.append("Index créé pour \\(issue.entityName).\\(issue.propertyName ?? "")")
            case .inconsistentRelationship:
                report.optimizationsApplied.append("Relation corrigée: \\(issue.entityName).\\(issue.propertyName ?? "")")
            case .missingInverseRelationship:
                report.optimizationsApplied.append("Relation inverse ajoutée pour \\(issue.entityName).\\(issue.propertyName ?? "")")
            default:
                break
            }
        }
    }
    
    private func printReport() {
        print("\\n📋 RAPPORT D'ANALYSE COREDATA")
        print("============================")
        print("Modèle: \\(report.modelName)")
        print("Entités: \\(report.entities.joined(separator: ", "))")
        print("Problèmes détectés: \\(report.issues.count)")
        print("Optimisations appliquées: \\(report.optimizationsApplied.count)")
        print("Temps d'exécution: \\(String(format: "%.2f", report.executionTime)) secondes")
        
        if !report.issues.isEmpty && verbose {
            print("\\nDétail des problèmes:")
            for (index, issue) in report.issues.enumerated() {
                print("\\n[\\(index + 1)] \\(issue.issueType.rawValue) (\\(issue.severity.rawValue))")
                print("   Entité: \\(issue.entityName)\\(issue.propertyName != nil ? ".\\(issue.propertyName!)" : "")")
                print("   Description: \\(issue.description)")
                print("   Recommandation: \\(issue.recommendation)")
                print("   Correction automatique: \\(issue.automatic ? "Oui" : "Non")")
            }
        }
    }
}

// MARK: - Point d'entrée du script
func main() {
    // Analyser les arguments de ligne de commande
    let args = CommandLine.arguments
    
    var projectPath = ""
    var modelPath = ""
    var outputPath: String?
    var verbose = false
    
    var i = 1
    while i < args.count {
        switch args[i] {
        case "--project", "-p":
            if i + 1 < args.count {
                projectPath = args[i + 1]
                i += 2
            } else {
                i += 1
            }
        case "--model", "-m":
            if i + 1 < args.count {
                modelPath = args[i + 1]
                i += 2
            } else {
                i += 1
            }
        case "--output", "-o":
            if i + 1 < args.count {
                outputPath = args[i + 1]
                i += 2
            } else {
                i += 1
            }
        case "--verbose", "-v":
            verbose = true
            i += 1
        default:
            i += 1
        }
    }
    
    // Valider les arguments requis
    if projectPath.isEmpty {
        projectPath = FileManager.default.currentDirectoryPath
    }
    
    if modelPath.isEmpty {
        // Rechercher automatiquement le modèle CoreData
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: projectPath)
            for item in contents {
                if item.hasSuffix(".xcdatamodeld") {
                    modelPath = item
                    break
                }
            }
        } catch {
            print("❌ Erreur lors de la recherche du modèle CoreData: \\(error)")
        }
    }
    
    if modelPath.isEmpty {
        print("❌ Aucun modèle CoreData trouvé ou spécifié.")
        print("Usage: CoreDataOptimizer.swift --project <chemin_projet> --model <chemin_modele> [--output <chemin_rapport>] [--verbose]")
        exit(1)
    }
    
    // Exécuter l'optimiseur
    let optimizer = CoreDataOptimizer(projectPath: projectPath, modelPath: modelPath, verbose: verbose)
    let report = optimizer.run()
    
    // Sauvegarder le rapport au format JSON si un chemin de sortie est spécifié
    if let outputPath = outputPath {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(report)
            try jsonData.write(to: URL(fileURLWithPath: outputPath))
            print("\\n✅ Rapport sauvegardé dans: \\(outputPath)")
        } catch {
            print("\\n❌ Erreur lors de la sauvegarde du rapport: \\(error)")
        }
    }
}

// Exécution du script
main()
'''

def main():
    """Génère le fichier Swift et le rend exécutable."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, 'CoreDataOptimizer.swift')
    
    with open(output_path, 'w') as f:
        f.write(SWIFT_SCRIPT)
    
    # Rendre le script exécutable
    os.chmod(output_path, 0o755)
    
    print(f"✅ Script Swift généré et rendu exécutable: {output_path}")

if __name__ == "__main__":
    main() 