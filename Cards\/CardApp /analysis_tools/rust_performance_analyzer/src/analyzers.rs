use crate::models::{AnalysisConfig, AnalysisResult, FileIssue, FileMetrics, IssueType, Severity};
use regex::{Regex, RegexBuilder};
use std::path::Path;
use std::fs;
use rayon::prelude::*;
use lazy_static::lazy_static;
use std::collections::HashMap;

/// Contexte partagé entre les différents analyseurs
#[derive(Clone)]
pub struct AnalysisContext {
    config: AnalysisConfig,
    // Compilation de regex utilisées fréquemment
    regex_cache: HashMap<String, Regex>,
}

impl AnalysisContext {
    pub fn new(config: AnalysisConfig) -> Self {
        Self {
            config,
            regex_cache: HashMap::new(),
        }
    }

    /// Retourne une regex depuis le cache, ou la compile si elle n'existe pas
    fn get_regex(&mut self, pattern: &str, case_insensitive: bool) -> &Regex {
        let key = if case_insensitive {
            format!("i:{}", pattern)
        } else {
            format!(":{}", pattern)
        };

        if !self.regex_cache.contains_key(&key) {
            let regex = RegexBuilder::new(pattern)
                .case_insensitive(case_insensitive)
                .multi_line(true)
                .build()
                .expect("Regex invalide");
            self.regex_cache.insert(key.clone(), regex);
        }

        self.regex_cache.get(&key).unwrap()
    }
}

/// Analyse un fichier Swift et retourne le résultat
pub fn analyze_file(path: &Path, context: &mut AnalysisContext) -> AnalysisResult {
    let content = match fs::read_to_string(path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Erreur lors de la lecture du fichier {}: {}", path.display(), e);
            return AnalysisResult {
                file_path: path.to_path_buf(),
                file_size: 0,
                line_count: 0,
                issues: vec![],
                metrics: FileMetrics::default(),
            };
        }
    };

    let metadata = fs::metadata(path).unwrap_or_else(|_| panic!("Impossible d'obtenir les métadonnées pour {}", path.display()));
    let file_size = metadata.len();
    let lines: Vec<&str> = content.lines().collect();
    let line_count = lines.len();
    
    let mut metrics = FileMetrics::default();
    let mut issues = Vec::new();

    // Exécuter toutes les analyses dans cet ordre
    analyze_cyclomatic_complexity(&content, &lines, &mut issues, &mut metrics, context);
    analyze_nesting_depth(&content, &lines, &mut issues, &mut metrics, context);
    analyze_closure_captures(&content, &lines, &mut issues, &mut metrics, context);
    analyze_core_data_operations(&content, &lines, &mut issues, &mut metrics, context);
    analyze_concurrency_issues(&content, &lines, &mut issues, &mut metrics, context);
    analyze_collection_operations(&content, &lines, &mut issues, &mut metrics, context);
    analyze_memory_management(&content, &lines, &mut issues, &mut metrics, context);

    // Filtrer les problèmes selon la sévérité minimale configurée
    issues.retain(|issue| issue.severity as u8 <= context.config.min_severity as u8);

    AnalysisResult {
        file_path: path.to_path_buf(),
        file_size,
        line_count,
        issues,
        metrics,
    }
}

/// Analyse la complexité cyclomatique
fn analyze_cyclomatic_complexity(
    content: &str,
    lines: &[&str],
    issues: &mut Vec<FileIssue>,
    metrics: &mut FileMetrics,
    context: &mut AnalysisContext,
) {
    lazy_static! {
        static ref FUNCTION_REGEX: Regex = Regex::new(
            r"(?m)^\s*(?:func|var|let)\s+(\w+).*\{$"
        ).unwrap();
        
        static ref COMPLEXITY_INCREASING: Regex = Regex::new(
            r"\b(if|while|for|switch|case\s+.*:|guard|&&|\|\|)\b"
        ).unwrap();
    }

    let mut max_complexity = 0;
    let mut total_complexity = 0;
    let mut function_count = 0;
    
    // Trouver toutes les fonctions
    for func_match in FUNCTION_REGEX.captures_iter(content) {
        function_count += 1;
        
        if let Some(func_name) = func_match.get(1) {
            let func_start_line = content[..func_match.get(0).unwrap().start()]
                .chars().filter(|&c| c == '\n').count();
            
            // Trouver la fin de la fonction en comptant les accolades
            let mut brace_count = 1;
            let mut func_end_line = func_start_line;
            let mut func_content = String::new();
            
            for (i, line) in lines.iter().enumerate().skip(func_start_line) {
                brace_count += line.chars().filter(|&c| c == '{').count();
                brace_count -= line.chars().filter(|&c| c == '}').count();
                func_content.push_str(line);
                func_content.push('\n');
                func_end_line = i;
                
                if brace_count == 0 {
                    break;
                }
            }
            
            // Calculer la complexité en comptant les points de décision
            let complexity = 1 + COMPLEXITY_INCREASING.find_iter(&func_content).count() as u32;
            total_complexity += complexity;
            max_complexity = max_complexity.max(complexity);
            
            // Ajouter un problème si la complexité dépasse le seuil
            if complexity > context.config.cyclomatic_complexity_threshold {
                let severity = if complexity > context.config.cyclomatic_complexity_threshold * 2 {
                    Severity::Critical
                } else if complexity > context.config.cyclomatic_complexity_threshold + 5 {
                    Severity::High
                } else {
                    Severity::Medium
                };
                
                issues.push(FileIssue {
                    issue_type: IssueType::CyclomaticComplexity,
                    severity,
                    line: func_start_line + 1,
                    column: None,
                    message: format!(
                        "La fonction '{}' a une complexité cyclomatique de {}, supérieure au seuil de {}",
                        func_name.as_str(), 
                        complexity, 
                        context.config.cyclomatic_complexity_threshold
                    ),
                    suggestion: Some(format!(
                        "Refactorisez la fonction '{}' en plus petites fonctions ou méthodes",
                        func_name.as_str()
                    )),
                    code_snippet: Some(lines[func_start_line].to_string()),
                    metrics: Some(serde_json::json!({
                        "complexity": complexity,
                        "threshold": context.config.cyclomatic_complexity_threshold
                    })),
                });
            }
        }
    }
    
    metrics.function_count = function_count;
    metrics.max_cyclomatic_complexity = max_complexity as f64;
    metrics.avg_cyclomatic_complexity = if function_count > 0 {
        total_complexity as f64 / function_count as f64
    } else {
        0.0
    };
}

/// Analyse la profondeur d'imbrication
fn analyze_nesting_depth(
    content: &str,
    lines: &[&str],
    issues: &mut Vec<FileIssue>,
    metrics: &mut FileMetrics,
    context: &mut AnalysisContext,
) {
    let mut max_depth = 0;
    let mut current_line = 1;
    
    for line in lines {
        let indent_level = line.chars().take_while(|c| c.is_whitespace()).count() / 4; // Assuming 4 spaces = 1 level
        max_depth = max_depth.max(indent_level);
        
        if indent_level > context.config.nesting_depth_threshold as usize 
           && (line.contains("if ") || line.contains("for ") || line.contains("while ") || line.contains("switch ")) {
            issues.push(FileIssue {
                issue_type: IssueType::NestingComplexity,
                severity: Severity::Medium,
                line: current_line,
                column: None,
                message: format!(
                    "Profondeur d'imbrication excessive ({}) détectée", 
                    indent_level
                ),
                suggestion: Some("Extrayez ce code dans une fonction séparée ou utilisez la programmation fonctionnelle".to_string()),
                code_snippet: Some(line.to_string()),
                metrics: Some(serde_json::json!({
                    "depth": indent_level,
                    "threshold": context.config.nesting_depth_threshold
                })),
            });
        }
        
        current_line += 1;
    }
    
    metrics.max_nesting_depth = max_depth;
}

/// Analyse les captures de closures
fn analyze_closure_captures(
    content: &str,
    lines: &[&str],
    issues: &mut Vec<FileIssue>,
    metrics: &mut FileMetrics,
    context: &mut AnalysisContext,
) {
    if !context.config.analyze_closure_captures {
        return;
    }
    
    let self_capture_regex = context.get_regex(r"(\{\s*(\[weak\s+self\]|\[unowned\s+self\]|\[self\])|\{\s*\[\s*)", false);
    let missing_weak_self_regex = context.get_regex(r"\{\s*(?!\[weak\s+self\]|\[unowned\s+self\]).*\bself\.", false);
    
    let mut self_capture_count = 0;
    let mut current_line = 1;
    
    for line in lines {
        if self_capture_regex.is_match(line) {
            self_capture_count += 1;
        }
        
        if missing_weak_self_regex.is_match(line) && line.contains("self.") {
            issues.push(FileIssue {
                issue_type: IssueType::ReferenceRetentionCycle,
                severity: Severity::High,
                line: current_line,
                column: None,
                message: "Utilisation potentielle de 'self' sans capture [weak self] dans une closure".to_string(),
                suggestion: Some("Utilisez [weak self] ou [unowned self] pour éviter les cycles de rétention".to_string()),
                code_snippet: Some(line.to_string()),
                metrics: None,
            });
        }
        
        current_line += 1;
    }
    
    metrics.self_capture_count = self_capture_count;
}

/// Analyse les opérations CoreData
fn analyze_core_data_operations(
    content: &str,
    lines: &[&str],
    issues: &mut Vec<FileIssue>,
    metrics: &mut FileMetrics,
    context: &mut AnalysisContext,
) {
    if !context.config.analyze_core_data {
        return;
    }
    
    let core_data_regex = context.get_regex(r"\b(NSManagedObjectContext|NSFetchRequest|NSPredicate|NSFetchedResultsController|NSBatchDeleteRequest|NSPersistentContainer)\b", false);
    let background_context_regex = context.get_regex(r"\.perform\(\{|\bperformBackgroundTask\b", false);
    let main_thread_regex = context.get_regex(r"\.viewContext\b|\bmainContext\b", false);
    
    let mut core_data_count = 0;
    let mut current_line = 1;
    
    for line in lines {
        if core_data_regex.is_match(line) {
            core_data_count += 1;
            
            // Vérifier l'utilisation du contexte principal pour des opérations lourdes
            if main_thread_regex.is_match(line) && 
               (line.contains("fetch") || line.contains("save") || line.contains("delete")) {
                issues.push(FileIssue {
                    issue_type: IssueType::CoreDataPerformance,
                    severity: Severity::High,
                    line: current_line,
                    column: None,
                    message: "Opération CoreData potentiellement lourde sur le thread principal".to_string(),
                    suggestion: Some("Utilisez performBackgroundTask pour les opérations lourdes de CoreData".to_string()),
                    code_snippet: Some(line.to_string()),
                    metrics: None,
                });
            }
            
            // Rechercher des requêtes sans gestion d'erreurs
            if line.contains("fetch") && !line.contains("try") && !line.contains("catch") {
                issues.push(FileIssue {
                    issue_type: IssueType::CoreDataConcurrency,
                    severity: Severity::Medium,
                    line: current_line,
                    column: None,
                    message: "Requête CoreData sans gestion d'erreur".to_string(),
                    suggestion: Some("Utilisez try/catch pour gérer les erreurs de fetch CoreData".to_string()),
                    code_snippet: Some(line.to_string()),
                    metrics: None,
                });
            }
        }
        
        current_line += 1;
    }
    
    metrics.core_data_operation_count = core_data_count;
}

/// Analyse les problèmes de concurrence
fn analyze_concurrency_issues(
    content: &str,
    lines: &[&str],
    issues: &mut Vec<FileIssue>,
    metrics: &mut FileMetrics,
    context: &mut AnalysisContext,
) {
    if !context.config.analyze_concurrency {
        return;
    }
    
    let async_regex = context.get_regex(r"\basync\b|\bawait\b|\bcompletionHandler\b|\b(DispatchQueue|Task|TaskGroup)\b", false);
    let race_condition_regex = context.get_regex(r"\bDispatchQueue\.main\b.*\basync\b", false);
    let thread_unsafe_regex = context.get_regex(r"(?<!weak |unowned )var\s+\w+\s*:\s*(Array|Dictionary|Set)<", false);
    
    let mut async_count = 0;
    let mut concurrency_primitives = 0;
    let mut current_line = 1;
    
    for line in lines {
        if async_regex.is_match(line) {
            async_count += 1;
            
            if line.contains("DispatchQueue") || line.contains("Task") || line.contains("Thread") {
                concurrency_primitives += 1;
            }
            
            // Vérifier les conditions de concurrence potentielles
            if race_condition_regex.is_match(line) {
                issues.push(FileIssue {
                    issue_type: IssueType::DataRaceRisk,
                    severity: Severity::High,
                    line: current_line,
                    column: None,
                    message: "Risque de condition de concurrence avec l'utilisation de DispatchQueue et async".to_string(),
                    suggestion: Some("Utilisez des mécanismes de synchronisation comme les acteurs ou les isolations".to_string()),
                    code_snippet: Some(line.to_string()),
                    metrics: None,
                });
            }
        }
        
        // Détecter les variables potentiellement non thread-safe
        if thread_unsafe_regex.is_match(line) && async_count > 0 {
            issues.push(FileIssue {
                issue_type: IssueType::ThreadSafety,
                severity: Severity::Medium,
                line: current_line,
                column: None,
                message: "Variable mutable potentiellement partagée entre threads".to_string(),
                suggestion: Some("Utilisez @MainActor, des acteurs, ou des garanties explicites de synchronisation".to_string()),
                code_snippet: Some(line.to_string()),
                metrics: None,
            });
        }
        
        current_line += 1;
    }
    
    metrics.async_operation_count = async_count;
    metrics.concurrency_primitive_count = concurrency_primitives;
}

/// Analyse les opérations sur les collections
fn analyze_collection_operations(
    content: &str,
    lines: &[&str],
    issues: &mut Vec<FileIssue>,
    metrics: &mut FileMetrics,
    context: &mut AnalysisContext,
) {
    let inefficient_loop_regex = context.get_regex(r"for\s+.*\s+in\s+.*\s*\{\s*if\s+.*\s*\{\s*.*\s*\}", false);
    let collection_in_loop_regex = context.get_regex(r"for\s+.*\s+in\s+.*\s*\{\s*.*\.append\(|for\s+.*\s+in\s+.*\s*\{\s*.*\[\w+\]\s*=", false);
    
    let mut current_line = 1;
    
    for line in lines {
        // Détecter des boucles inefficaces (pourrait utiliser filter/map/etc.)
        if inefficient_loop_regex.is_match(line) {
            issues.push(FileIssue {
                issue_type: IssueType::UnoptimizedCollectionOperation,
                severity: Severity::Low,
                line: current_line,
                column: None,
                message: "Boucle et condition qui pourraient être remplacées par filter/compactMap/etc.".to_string(),
                suggestion: Some("Utilisez les méthodes fonctionnelles comme filter, map, reduce pour un code plus concis et efficace".to_string()),
                code_snippet: Some(line.to_string()),
                metrics: None,
            });
        }
        
        // Détecter la construction de collection dans des boucles
        if collection_in_loop_regex.is_match(line) {
            issues.push(FileIssue {
                issue_type: IssueType::UnoptimizedCollectionOperation,
                severity: Severity::Medium,
                line: current_line,
                column: None,
                message: "Construction de collection inefficace dans une boucle".to_string(),
                suggestion: Some("Préallouez la collection ou utilisez des méthodes comme map, filter ou reduce".to_string()),
                code_snippet: Some(line.to_string()),
                metrics: None,
            });
        }
        
        current_line += 1;
    }
}

/// Analyse la gestion mémoire
fn analyze_memory_management(
    content: &str,
    lines: &[&str],
    issues: &mut Vec<FileIssue>,
    metrics: &mut FileMetrics,
    context: &mut AnalysisContext,
) {
    let memory_leak_regex = context.get_regex(r"(?<!weak |unowned )var\s+\w+\s*:\s*.*\bdelegate\b", false);
    let large_object_regex = context.get_regex(r"var\s+\w+\s*:\s*\[.*\]\s*=\s*\[\]", false);
    
    let mut current_line = 1;
    
    for line in lines {
        // Détecter les délégués qui pourraient créer des cycles de rétention
        if memory_leak_regex.is_match(line) {
            issues.push(FileIssue {
                issue_type: IssueType::MemoryLeak,
                severity: Severity::High,
                line: current_line,
                column: None,
                message: "Délégué potentiellement fort pouvant causer un cycle de rétention".to_string(),
                suggestion: Some("Utilisez 'weak var' pour les propriétés de type délégué".to_string()),
                code_snippet: Some(line.to_string()),
                metrics: None,
            });
        }
        
        // Détecter les grandes collections sans allocation initiale
        if large_object_regex.is_match(line) {
            issues.push(FileIssue {
                issue_type: IssueType::RedundantComputation,
                severity: Severity::Low,
                line: current_line,
                column: None,
                message: "Collection potentiellement grande sans capacité initiale".to_string(),
                suggestion: Some("Préallouez une capacité pour les grandes collections si la taille est connue à l'avance".to_string()),
                code_snippet: Some(line.to_string()),
                metrics: None,
            });
        }
        
        current_line += 1;
    }
} 