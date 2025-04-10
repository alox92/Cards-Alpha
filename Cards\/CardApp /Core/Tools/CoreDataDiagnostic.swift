import Foundation
import CoreData
import os.log

@MainActor
public class CoreDataDiagnostic {
    private let logger = Logger(subsystem: "com.cardapp.coredata", category: "diagnostic")
    
    public init() {}
    
    private func checkConcurrencyIssues(in content: String, file: String) {
        // Détection du contexte principal utilisé dans des tâches d'arrière-plan
        if content.contains("viewContext") && 
           (content.contains("DispatchQueue.global") || content.contains("Task") || content.contains("async")) {
            logger.warning("⚠️ Utilisation potentiellement dangereuse de viewContext dans un contexte asynchrone dans \(file)")
        }
    }
    
    private func analyzePredefinedQueries() throws {
        // Analyser les requêtes prédéfinies pour détecter des problèmes potentiels
        let fetchRequestRegex = try NSRegularExpression(
            pattern: "<fetchRequest name=\"([^\"]+)\"[^>]*entity=\"([^\"]+)\"[^>]*>([\\s\\S]*?)</fetchRequest>",
            options: []
        )
        
        let matches = fetchRequestRegex.matches(
            in: xmlString,
            options: [],
            range: NSRange(location: 0, length: xmlString.count)
        )
        
        for match in matches {
            // Traitement des correspondances
            if let nameRange = Range(match.range(at: 1), in: xmlString),
               let entityRange = Range(match.range(at: 2), in: xmlString) {
                let name = String(xmlString[nameRange])
                let entity = String(xmlString[entityRange])
                logger.info("📝 Requête prédéfinie trouvée: \(name) pour l'entité \(entity)")
            }
        }
    }
} 