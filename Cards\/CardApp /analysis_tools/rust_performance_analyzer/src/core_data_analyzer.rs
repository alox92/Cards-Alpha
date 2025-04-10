use crate::models::{FileIssue, Severity, IssueType, AnalysisConfig};
use crate::types::{CoreDataIssueType, Recommendation, OptimizationRecommendation};
use regex::Regex;
use std::path::PathBuf;
use lazy_static::lazy_static;

lazy_static! {
    static ref FETCH_REQUEST_PATTERN: Regex = Regex::new(
        r"(?i)NSFetchRequest\s*<.*?>\s*\(.*?\)|\.fetchRequest\(\)|FetchRequest\s*\("
    ).unwrap();
    
    static ref PREDICATE_PATTERN: Regex = Regex::new(
        r"(?i)NSPredicate\s*\(format:\s*\"(.*?)\""
    ).unwrap();
    
    static ref SORT_DESCRIPTOR_PATTERN: Regex = Regex::new(
        r"(?i)NSSortDescriptor\s*\(.*?key:\s*\"(.*?)\".*?\)"
    ).unwrap();
    
    static ref SAVE_CONTEXT_PATTERN: Regex = Regex::new(
        r"(?i)(try\s*)?.*?\.save\(\)"
    ).unwrap();
    
    static ref MAIN_QUEUE_PATTERN: Regex = Regex::new(
        r"(?i)DispatchQueue\.main|@MainActor|viewContext"
    ).unwrap();
    
    static ref BACKGROUND_QUEUE_PATTERN: Regex = Regex::new(
        r"(?i)newBackgroundContext\(\)|performBackgroundTask|perform\(\{|\.perform|performAndWait"
    ).unwrap();
    
    static ref RELATIONSHIP_ACCESS_PATTERN: Regex = Regex::new(
        r"(?i)(\w+)\.(relationship|\w+s|\w+Set|\w+Array)"
    ).unwrap();
}

/// Structure principale pour l'analyse CoreData
pub struct CoreDataAnalyzer {
    config: AnalysisConfig,
}

impl CoreDataAnalyzer {
    pub fn new(config: AnalysisConfig) -> Self {
        CoreDataAnalyzer { config }
    }
    
    /// Analyser un fichier pour les problèmes potentiels de CoreData
    pub fn analyze(&self, file_path: &PathBuf, content: &str) -> Vec<FileIssue> {
        let mut issues = Vec::new();
        
        // Ignorer les fichiers qui ne contiennent pas de code CoreData
        if !content.contains("NSManagedObject") && 
           !content.contains("NSPersistentContainer") && 
           !content.contains("NSFetchRequest") && 
           !content.contains("@FetchRequest") &&
           !content.contains("CoreData") {
            return issues;
        }
        
        self.analyze_fetch_requests(file_path, content, &mut issues);
        self.analyze_context_usage(file_path, content, &mut issues);
        self.analyze_batch_operations(file_path, content, &mut issues);
        self.analyze_relationship_traversal(file_path, content, &mut issues);
        self.analyze_predicate_complexity(file_path, content, &mut issues);
        
        issues
    }
    
    /// Analyser les requêtes de récupération de données
    fn analyze_fetch_requests(&self, file_path: &PathBuf, content: &str, issues: &mut Vec<FileIssue>) {
        let lines: Vec<&str> = content.lines().collect();
        
        // Vérifier les fetchRequest sans limit
        for (i, line) in lines.iter().enumerate() {
            if FETCH_REQUEST_PATTERN.is_match(line) && !line.contains(".fetchLimit") {
                let issue = FileIssue {
                    file: file_path.clone(),
                    line: i + 1,
                    column: line.find("FetchRequest").unwrap_or(0),
                    issue_type: IssueType::CoreDataPerformance,
                    severity: Severity::Medium,
                    message: "Requête FetchRequest sans limite de résultats - risque de surcharge mémoire".to_string(),
                    suggestion: Some("Ajouter .fetchLimit pour limiter le nombre de résultats".to_string()),
                    code_snippet: Some(line.to_string()),
                };
                issues.push(issue);
            }
            
            // Vérifier les fetchRequest sans batch size
            if FETCH_REQUEST_PATTERN.is_match(line) && !line.contains(".fetchBatchSize") {
                let issue = FileIssue {
                    file: file_path.clone(),
                    line: i + 1,
                    column: line.find("FetchRequest").unwrap_or(0),
                    issue_type: IssueType::CoreDataPerformance,
                    severity: Severity::Low,
                    message: "Requête FetchRequest sans taille de lot - performance sous-optimale".to_string(),
                    suggestion: Some("Ajouter .fetchBatchSize pour une meilleure performance avec de grands ensembles de données".to_string()),
                    code_snippet: Some(line.to_string()),
                };
                issues.push(issue);
            }
        }
        
        // Vérifier les fetchRequest complexes sans index
        for cap in PREDICATE_PATTERN.captures_iter(content) {
            if let Some(predicate) = cap.get(1) {
                let predicate_str = predicate.as_str();
                
                // Détecter les prédicats complexes qui bénéficieraient d'un index
                if (predicate_str.contains("BEGINSWITH") || 
                    predicate_str.contains("CONTAINS") || 
                    predicate_str.contains("LIKE")) && 
                   !content.contains("@Index") {
                    
                    let line_number = content[..cap.get(0).unwrap().start()]
                        .lines()
                        .count();
                    
                    let issue = FileIssue {
                        file: file_path.clone(),
                        line: line_number,
                        column: 0,
                        issue_type: IssueType::CoreDataPerformance,
                        severity: Severity::High,
                        message: format!("Prédicat complexe sans index: {}", predicate_str),
                        suggestion: Some("Ajouter @Index pour les propriétés utilisées dans les prédicats de recherche textuelle".to_string()),
                        code_snippet: Some(cap.get(0).unwrap().as_str().to_string()),
                    };
                    issues.push(issue);
                }
            }
        }
    }
    
    /// Analyser l'utilisation du contexte CoreData
    fn analyze_context_usage(&self, file_path: &PathBuf, content: &str, issues: &mut Vec<FileIssue>) {
        let lines: Vec<&str> = content.lines().collect();
        
        // Vérifier les opérations lourdes sur le thread principal
        for (i, line) in lines.iter().enumerate() {
            if MAIN_QUEUE_PATTERN.is_match(line) && 
               (FETCH_REQUEST_PATTERN.is_match(&lines[i..].join("\n")[..200]) || 
                line.contains("for") && line.contains("in") && 
                i + 3 < lines.len() && lines[i+1..i+3].join("\n").contains("fetch")) {
                
                let issue = FileIssue {
                    file: file_path.clone(),
                    line: i + 1,
                    column: 0,
                    issue_type: IssueType::CoreDataPerformance,
                    severity: Severity::High,
                    message: "Opération CoreData potentiellement lourde exécutée sur le thread principal".to_string(),
                    suggestion: Some("Déplacer les opérations fetch intensives sur un contexte d'arrière-plan".to_string()),
                    code_snippet: Some(line.to_string()),
                };
                issues.push(issue);
            }
            
            // Vérifier les sauvegardes fréquentes
            if SAVE_CONTEXT_PATTERN.is_match(line) && 
               i > 5 && SAVE_CONTEXT_PATTERN.is_match(&lines[i-5..i].join("\n")) {
                let issue = FileIssue {
                    file: file_path.clone(),
                    line: i + 1,
                    column: 0,
                    issue_type: IssueType::CoreDataPerformance,
                    severity: Severity::Medium,
                    message: "Sauvegardes contextuelles rapprochées détectées".to_string(),
                    suggestion: Some("Regrouper les modifications et réduire la fréquence des opérations save()".to_string()),
                    code_snippet: Some(line.to_string()),
                };
                issues.push(issue);
            }
        }
    }
    
    /// Analyser les opportunités d'opérations par lot
    fn analyze_batch_operations(&self, file_path: &PathBuf, content: &str, issues: &mut Vec<FileIssue>) {
        if content.contains("for") && content.contains("in") && 
           content.contains("save") && !content.contains("batchInsert") && 
           !content.contains("NSBatchDeleteRequest") {
            
            // Rechercher des boucles contenant des opérations CoreData
            let lines: Vec<&str> = content.lines().collect();
            let mut in_loop = false;
            let mut loop_start = 0;
            let mut entity_operations = false;
            
            for (i, line) in lines.iter().enumerate() {
                if line.contains("for") && line.contains("in") {
                    in_loop = true;
                    loop_start = i;
                    entity_operations = false;
                } else if in_loop && (line.contains("insert") || line.contains("delete") || 
                                     line.contains("newEntity") || line.contains("entity.")) {
                    entity_operations = true;
                } else if line.contains("}") && in_loop && entity_operations && i - loop_start > 5 {
                    in_loop = false;
                    
                    let issue = FileIssue {
                        file: file_path.clone(),
                        line: loop_start + 1,
                        column: 0,
                        issue_type: IssueType::CoreDataPerformance,
                        severity: Severity::Medium,
                        message: "Opérations CoreData en boucle pouvant être optimisées".to_string(),
                        suggestion: Some("Utiliser NSBatchInsertRequest ou NSBatchDeleteRequest pour de meilleures performances".to_string()),
                        code_snippet: Some(format!("{}...", lines[loop_start])),
                    };
                    issues.push(issue);
                } else if line.contains("}") && in_loop {
                    in_loop = false;
                }
            }
        }
    }
    
    /// Analyser les traversées de relations
    fn analyze_relationship_traversal(&self, file_path: &PathBuf, content: &str, issues: &mut Vec<FileIssue>) {
        let lines: Vec<&str> = content.lines().collect();
        
        for (i, line) in lines.iter().enumerate() {
            // Détecter les accès à des relations à cardinalité multiple
            if let Some(cap) = RELATIONSHIP_ACCESS_PATTERN.captures(line) {
                if let Some(entity) = cap.get(1) {
                    let entity_name = entity.as_str();
                    // Vérifier si c'est dans une boucle (traversée potentiellement coûteuse)
                    let context = if i > 10 { &lines[i-10..i].join("\n") } else { "" };
                    
                    if context.contains("for") && context.contains("in") {
                        let issue = FileIssue {
                            file: file_path.clone(),
                            line: i + 1,
                            column: line.find(entity_name).unwrap_or(0),
                            issue_type: IssueType::CoreDataPerformance,
                            severity: Severity::Medium,
                            message: format!("Traversée potentiellement inefficace de relation pour {}", entity_name),
                            suggestion: Some("Envisager de précharger les relations avec des prefetch key paths".to_string()),
                            code_snippet: Some(line.to_string()),
                        };
                        issues.push(issue);
                    }
                }
            }
        }
    }
    
    /// Analyser la complexité des prédicats
    fn analyze_predicate_complexity(&self, file_path: &PathBuf, content: &str, issues: &mut Vec<FileIssue>) {
        for cap in PREDICATE_PATTERN.captures_iter(content) {
            if let Some(predicate) = cap.get(1) {
                let predicate_str = predicate.as_str();
                
                // Prédicats très complexes
                if predicate_str.matches("AND").count() > 3 || 
                   predicate_str.matches("OR").count() > 3 ||
                   predicate_str.contains("ANY") && predicate_str.contains("SUBQUERY") {
                    
                    let line_number = content[..cap.get(0).unwrap().start()]
                        .lines()
                        .count();
                    
                    let issue = FileIssue {
                        file: file_path.clone(),
                        line: line_number,
                        column: 0,
                        issue_type: IssueType::CoreDataPerformance,
                        severity: Severity::Medium,
                        message: "Prédicat complexe pouvant affecter les performances".to_string(),
                        suggestion: Some("Envisager de décomposer en requêtes plus simples ou d'optimiser la structure de données".to_string()),
                        code_snippet: Some(predicate_str.to_string()),
                    };
                    issues.push(issue);
                }
            }
        }
    }
    
    /// Générer des recommandations d'optimisation
    pub fn generate_recommendations(&self, file_path: &PathBuf, issues: &[FileIssue]) -> Vec<Recommendation> {
        let mut recommendations = Vec::new();
        
        for issue in issues {
            match issue.issue_type {
                IssueType::CoreDataPerformance => {
                    let recommendation_type = if issue.message.contains("index") {
                        OptimizationRecommendation::IndexCreation
                    } else if issue.message.contains("lot") || issue.message.contains("batch") {
                        OptimizationRecommendation::BatchProcessing
                    } else if issue.message.contains("thread") {
                        OptimizationRecommendation::AsyncOperation
                    } else {
                        OptimizationRecommendation::CodeRefactoring
                    };
                    
                    let mut code_example = None;
                    
                    // Exemples de code pour les recommandations communes
                    if issue.message.contains("index") {
                        code_example = Some(
                            "// Dans votre modèle Core Data (fichier .xcdatamodeld)\n\
                            // Sélectionner l'attribut et cocher la case 'Indexed'\n\n\
                            // Ou en code:\n\
                            @Entity(name: \"MyEntity\")\n\
                            class MyEntity: NSManagedObject {\n\
                                @Attribute(.indexed)\n\
                                var searchableProperty: String\n\
                            }".to_string()
                        );
                    } else if issue.message.contains("lot") || issue.message.contains("batch") {
                        code_example = Some(
                            "// Au lieu de boucler et sauvegarder:\n\
                            let batchInsert = NSBatchInsertRequest(entity: MyEntity.entity(),\n\
                                objects: itemsToInsert.map { [\"property\": $0.value] })\n\
                            batchInsert.resultType = .objectIDs\n\
                            let result = try context.execute(batchInsert) as! NSBatchInsertResult\n\
                            let insertedIDs = result.result as! [NSManagedObjectID]".to_string()
                        );
                    } else if issue.message.contains("thread") {
                        code_example = Some(
                            "persistentContainer.performBackgroundTask { context in\n\
                                // Opérations CoreData lourdes ici\n\
                                let request = NSFetchRequest<MyEntity>(entityName: \"MyEntity\")\n\
                                // Configure la requête\n\
                                let results = try context.fetch(request)\n\
                                // Traitement des résultats\n\
                                try context.save()\n\
                                \n\
                                // Mise à jour de l'UI sur le thread principal\n\
                                DispatchQueue.main.async {\n\
                                    // Mettre à jour l'UI ici\n\
                                }\n\
                            }".to_string()
                        );
                    }
                    
                    let recommendation = Recommendation {
                        recommendation_type,
                        file_path: file_path.clone(),
                        line: Some(issue.line),
                        description: issue.message.clone(),
                        expected_improvement: "Amélioration significative des performances de requête et réduction de la consommation mémoire".to_string(),
                        code_example,
                        difficulty: match issue.severity {
                            Severity::Low => 2,
                            Severity::Medium => 5,
                            Severity::High => 7,
                            Severity::Critical => 9,
                        },
                        priority: issue.severity,
                    };
                    
                    recommendations.push(recommendation);
                },
                _ => {}
            }
        }
        
        recommendations
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;
    
    #[test]
    fn test_detect_fetch_without_limit() {
        let analyzer = CoreDataAnalyzer::new(AnalysisConfig {
            min_severity: Severity::Low,
            min_cyclomatic_complexity: 10,
            min_nesting_depth: 5,
            min_file_size: 1000,
        });
        
        let file_path = PathBuf::from("test/Example.swift");
        let content = "let fetchRequest = NSFetchRequest<Card>(entityName: \"Card\")\ntry context.fetch(fetchRequest)";
        
        let issues = analyzer.analyze(&file_path, content);
        
        assert!(!issues.is_empty());
        assert!(issues.iter().any(|i| i.message.contains("limite")));
    }
    
    #[test]
    fn test_detect_main_thread_operations() {
        let analyzer = CoreDataAnalyzer::new(AnalysisConfig {
            min_severity: Severity::Low,
            min_cyclomatic_complexity: 10,
            min_nesting_depth: 5,
            min_file_size: 1000,
        });
        
        let file_path = PathBuf::from("test/Example.swift");
        let content = "DispatchQueue.main.async {\n  let fetchRequest = NSFetchRequest<Card>(entityName: \"Card\")\n  let results = try! context.fetch(fetchRequest)\n}";
        
        let issues = analyzer.analyze(&file_path, content);
        
        assert!(!issues.is_empty());
        assert!(issues.iter().any(|i| i.message.contains("thread principal")));
    }
} 