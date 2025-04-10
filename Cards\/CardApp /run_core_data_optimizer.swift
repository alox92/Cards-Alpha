#!/usr/bin/swift

import Foundation
import CoreData
@testable import CardApp

/**
 * Script d'exécution pour CoreDataOptimizer
 * 
 * Ce script analyse le modèle CoreData de CardApp et génère un rapport détaillé
 * des problèmes et optimisations possibles.
 * 
 * Utilisation:
 *   ./run_core_data_optimizer.swift
 * 
 * Assurez-vous que le script est exécutable:
 *   chmod +x run_core_data_optimizer.swift
 */

// Configuration des couleurs pour la sortie console
struct ANSIColors {
    static let reset = "\u{001B}[0m"
    static let red = "\u{001B}[31m"
    static let green = "\u{001B}[32m"
    static let yellow = "\u{001B}[33m"
    static let blue = "\u{001B}[34m"
    static let magenta = "\u{001B}[35m"
    static let cyan = "\u{001B}[36m"
    static let white = "\u{001B}[37m"
    static let bold = "\u{001B}[1m"
}

// Classe pour le logging
class Logger {
    static func info(_ message: String) {
        print("\(ANSIColors.blue)ℹ️ INFO: \(message)\(ANSIColors.reset)")
    }
    
    static func warning(_ message: String) {
        print("\(ANSIColors.yellow)⚠️ ATTENTION: \(message)\(ANSIColors.reset)")
    }
    
    static func error(_ message: String) {
        print("\(ANSIColors.red)❌ ERREUR: \(message)\(ANSIColors.reset)")
    }
    
    static func success(_ message: String) {
        print("\(ANSIColors.green)✅ SUCCÈS: \(message)\(ANSIColors.reset)")
    }
    
    static func title(_ message: String) {
        print("\n\(ANSIColors.bold)\(ANSIColors.cyan)=== \(message) ===\(ANSIColors.reset)\n")
    }
    
    static func separator() {
        print("\(ANSIColors.white)----------------------------------------\(ANSIColors.reset)")
    }
}

// Fonction pour écrire le rapport dans un fichier
func ecrireRapport(_ contenu: String, nomFichier: String) {
    let fileManager = FileManager.default
    let rapportDir = "rapports_optimisation"
    
    // Créer le répertoire s'il n'existe pas
    if !fileManager.fileExists(atPath: rapportDir) {
        do {
            try fileManager.createDirectory(atPath: rapportDir, withIntermediateDirectories: true)
        } catch {
            Logger.error("Impossible de créer le répertoire de rapports: \(error)")
            return
        }
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let dateStr = dateFormatter.string(from: Date())
    
    let cheminComplet = "\(rapportDir)/\(nomFichier)_\(dateStr).txt"
    
    do {
        try contenu.write(toFile: cheminComplet, atomically: true, encoding: .utf8)
        Logger.success("Rapport enregistré dans: \(cheminComplet)")
    } catch {
        Logger.error("Erreur lors de l'écriture du rapport: \(error)")
    }
}

// Fonction principale
func main() {
    Logger.title("Lancement de l'optimiseur CoreData pour CardApp")
    Logger.info("Initialisation de l'environnement...")
    
    // Création d'un container temporaire pour l'analyse
    let container = NSPersistentContainer(name: "CardApp")
    
    // Configuration du store en mémoire pour éviter de modifier la base de données réelle
    let storeDescription = NSPersistentStoreDescription()
    storeDescription.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [storeDescription]
    
    container.loadPersistentStores { description, error in
        if let error = error {
            Logger.error("Échec du chargement du modèle CoreData: \(error)")
            exit(1)
        }
        
        Logger.success("Modèle CoreData chargé avec succès")
        
        // Création de l'optimiseur
        let optimizer = CoreDataOptimizer(container: container)
        var rapportComplet = "RAPPORT D'OPTIMISATION COREDATA POUR CARDAPP\n"
        rapportComplet += "Date: \(Date())\n\n"
        
        // 1. Analyse du modèle
        Logger.title("Diagnostic du modèle CoreData")
        let problemes = optimizer.diagnostiquerModele()
        
        if problemes.isEmpty {
            Logger.success("Aucun problème trouvé dans le modèle CoreData!")
        } else {
            Logger.warning("Problèmes détectés dans le modèle CoreData:")
            
            rapportComplet += "PROBLÈMES DU MODÈLE:\n"
            
            // Trier les problèmes par sévérité
            let problemesTries = problemes.sorted { $0.severite > $1.severite }
            
            for probleme in problemesTries {
                let severiteStr: String
                switch probleme.severite {
                case .critique:
                    severiteStr = "\(ANSIColors.red)CRITIQUE\(ANSIColors.reset)"
                case .erreur:
                    severiteStr = "\(ANSIColors.red)ERREUR\(ANSIColors.reset)"
                case .avertissement:
                    severiteStr = "\(ANSIColors.yellow)AVERTISSEMENT\(ANSIColors.reset)"
                case .info:
                    severiteStr = "\(ANSIColors.blue)INFO\(ANSIColors.reset)"
                }
                
                print(" - [\(severiteStr)] \(probleme.entite)\(probleme.attribut != nil ? ".\(probleme.attribut!)" : ""): \(probleme.description)")
                print("   Solution: \(probleme.solutionSuggestion)")
                if let code = probleme.codeCorrection {
                    print("   Code: \n\(code)")
                }
                print("")
                
                // Ajouter au rapport
                rapportComplet += "[\(probleme.severite)] \(probleme.entite)\(probleme.attribut != nil ? ".\(probleme.attribut!)" : ""): \(probleme.description)\n"
                rapportComplet += "Solution: \(probleme.solutionSuggestion)\n"
                if let code = probleme.codeCorrection {
                    rapportComplet += "Code: \n\(code)\n"
                }
                rapportComplet += "\n"
            }
        }
        
        Logger.separator()
        
        // 2. Analyse des performances
        Logger.title("Analyse des performances")
        let resultatsPerformance = optimizer.analyserPerformanceRequetes()
        
        rapportComplet += "\nANALYSE DE PERFORMANCE:\n"
        
        if resultatsPerformance.isEmpty {
            Logger.info("Aucune entité trouvée pour l'analyse de performance.")
        } else {
            for resultat in resultatsPerformance {
                let performanceLevel: String
                if resultat.tempsChargement > 0.5 {
                    performanceLevel = "\(ANSIColors.red)Lent\(ANSIColors.reset)"
                } else if resultat.tempsChargement > 0.1 {
                    performanceLevel = "\(ANSIColors.yellow)Moyen\(ANSIColors.reset)"
                } else {
                    performanceLevel = "\(ANSIColors.green)Rapide\(ANSIColors.reset)"
                }
                
                print(" - [\(performanceLevel)] \(resultat.entite): \(String(format: "%.4f", resultat.tempsChargement))s pour \(resultat.nombreEntites) objets (\(resultat.tailleMemoire) bytes)")
                
                if !resultat.suggestionsOptimisation.isEmpty {
                    print("   Suggestions:")
                    for suggestion in resultat.suggestionsOptimisation {
                        print("   - \(suggestion)")
                    }
                }
                print("")
                
                // Ajouter au rapport
                rapportComplet += "\(resultat.entite): \(String(format: "%.4f", resultat.tempsChargement))s pour \(resultat.nombreEntites) objets (\(resultat.tailleMemoire) bytes)\n"
                if !resultat.suggestionsOptimisation.isEmpty {
                    rapportComplet += "Suggestions:\n"
                    for suggestion in resultat.suggestionsOptimisation {
                        rapportComplet += "- \(suggestion)\n"
                    }
                }
                rapportComplet += "\n"
            }
        }
        
        Logger.separator()
        
        // 3. Application des optimisations
        Logger.title("Optimisations automatiques")
        let corrections = optimizer.optimiserModele()
        
        rapportComplet += "\nOPTIMISATIONS APPLIQUÉES:\n"
        
        if corrections.isEmpty {
            Logger.info("Aucune optimisation automatique appliquée.")
            rapportComplet += "Aucune optimisation automatique appliquée.\n"
        } else {
            Logger.success("Optimisations appliquées:")
            for correction in corrections {
                print(" - \(correction)")
                rapportComplet += "- \(correction)\n"
            }
        }
        
        Logger.separator()
        
        // 4. Génération du script de migration
        Logger.title("Génération du script de migration")
        let scriptMigration = optimizer.genererScriptMigration()
        
        // Écrire le script de migration dans un fichier
        do {
            try scriptMigration.write(toFile: "MigrationManager.swift", atomically: true, encoding: .utf8)
            Logger.success("Script de migration généré: MigrationManager.swift")
        } catch {
            Logger.error("Erreur lors de l'écriture du script de migration: \(error)")
        }
        
        rapportComplet += "\nSCRIPT DE MIGRATION:\n"
        rapportComplet += "Un script de migration a été généré dans 'MigrationManager.swift'\n"
        
        // 5. Analyse des requêtes courantes
        Logger.title("Analyse des problèmes courants dans les requêtes CoreData")
        let problemesRequetes = optimizer.simulerAnalyseRequetes()
        
        rapportComplet += "\nPROBLÈMES COURANTS DANS LES REQUÊTES:\n"
        
        Logger.warning("Recherchez ces problèmes dans votre code:")
        for probleme in problemesRequetes {
            print(" - \(probleme)")
            rapportComplet += "- \(probleme)\n"
        }
        
        Logger.separator()
        
        // Écrire le rapport complet
        ecrireRapport(rapportComplet, nomFichier: "rapport_coredata")
        
        Logger.title("Suggestions d'optimisation globales")
        print("""
        1. Utilisez toujours 'fetchBatchSize' pour les requêtes qui retournent beaucoup d'objets
        2. Placez des index sur les attributs utilisés fréquemment dans les filtres (NSPredicate)
        3. Assurez-vous que 'try context.save()' est toujours entouré de try/catch
        4. Utilisez 'perform' et 'performAndWait' pour les opérations CoreData sur des threads secondaires
        5. Réduisez le nombre de relations to-many et envisagez l'utilisation de NSFetchedResultsController
        6. Placez '@MainActor' sur les méthodes qui accèdent à viewContext
        7. Pensez à utiliser 'relationshipKeyPathsForPrefetching' pour les relations fréquemment accédées
        """)
        
        Logger.title("Analyse terminée")
        Logger.success("L'analyse du modèle CoreData est terminée. Consultez le rapport pour plus de détails.")
    }
    
    // Boucle principale pour attendre que l'analyse soit terminée
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 2))
}

// Exécution
main() 