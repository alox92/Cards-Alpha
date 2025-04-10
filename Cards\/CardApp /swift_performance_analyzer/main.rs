use std::fs;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};
use std::io::Write;
use regex::Regex;
use serde::{Serialize, Deserialize};
use rayon::prelude::*;
use clap::Parser;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    project_dir: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Issue {
    file: String,
    line: usize,
    message: String,
    severity: IssueSeverity,
    category: String,
    code: String,
    suggestion: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
enum IssueSeverity {
    Warning,
    Error,
    Critical,
}

#[derive(Debug, Serialize, Deserialize)]
struct AnalysisReport {
    timestamp: u64,
    project: String,
    files_analyzed: usize,
    total_issues: usize,
    issues: Vec<Issue>,
    categories: HashMap<String, usize>,
}

fn main() {
    println!("Swift Performance Analyzer - Analyse multi-thread rapide");
    
    let args = Args::parse();
    println!("Analyse du projet: {}", args.project_dir);
    
    // Collecter tous les fichiers Swift
    let swift_files = collect_swift_files(&args.project_dir);
    println!("Trouvé {} fichiers Swift à analyser", swift_files.len());
    
    // Analyser les fichiers en parallèle
    let issues = Arc::new(Mutex::new(Vec::new()));
    
    // Utilisation de rayon pour le parallélisme
    swift_files.par_iter().for_each(|file| {
        if let Ok(content) = fs::read_to_string(file) {
            let file_str = file.to_string_lossy().to_string();
            
            // Analyser les différents aspects
            analyze_memory_management(&file_str, &content, Arc::clone(&issues));
            analyze_concurrency(&file_str, &content, Arc::clone(&issues));
            analyze_coredata(&file_str, &content, Arc::clone(&issues));
            analyze_complexity(&file_str, &content, Arc::clone(&issues));
        }
    });
    
    // Extraire les problèmes et créer des statistiques
    let issues_vec = issues.lock().unwrap().clone();
    let mut categories = HashMap::new();
    
    for issue in &issues_vec {
        let count = categories.entry(issue.category.clone()).or_insert(0);
        *count += 1;
    }
    
    // Trier les problèmes par sévérité
    let mut sorted_issues = issues_vec.clone();
    sorted_issues.sort_by(|a, b| {
        let severity_order = |s: &IssueSeverity| match s {
            IssueSeverity::Critical => 0,
            IssueSeverity::Error => 1,
            IssueSeverity::Warning => 2,
        };
        
        let order_a = severity_order(&a.severity);
        let order_b = severity_order(&b.severity);
        order_a.cmp(&order_b)
    });
    
    // Créer le rapport
    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    
    let report = AnalysisReport {
        timestamp,
        project: args.project_dir.clone(),
        files_analyzed: swift_files.len(),
        total_issues: sorted_issues.len(),
        issues: sorted_issues,
        categories,
    };
    
    // Sauvegarder le rapport en JSON
    let json = serde_json::to_string_pretty(&report).unwrap();
    let report_path = "rapports_optimisation/performance_analysis.json";
    
    // Créer le répertoire s'il n'existe pas
    let report_dir = Path::new("rapports_optimisation");
    if !report_dir.exists() {
        fs::create_dir_all(report_dir).unwrap();
    }
    
    fs::write(report_path, &json).unwrap();
    println!("Rapport enregistré dans: {}", report_path);
    
    // Générer un script d'auto-correction
    generate_fix_report(&report.issues);
    
    // Afficher un résumé
    println!("\nRÉSUMÉ DE L'ANALYSE:");
    println!("Fichiers analysés: {}", report.files_analyzed);
    println!("Problèmes trouvés: {}", report.total_issues);
    println!("\nCatégories de problèmes:");
    
    for (category, count) in &report.categories {
        println!("  {}: {}", category, count);
    }
}

fn analyze_memory_management(file: &str, content: &str, issues: Arc<Mutex<Vec<Issue>>>) {
    // Patterns à rechercher
    let patterns = [
        (r"self\.([\w\.]+)\s*=\s*\{[^\}]*?self",
         "Cycle de référence potentiel (closures capturant self sans [weak self])",
         "Utilisez [weak self] dans la closure et 'guard let self = self' pour éviter un cycle de référence",
         IssueSeverity::Critical),
        
        (r"var\s+delegate\s*:",
         "Délégué déclaré sans 'weak'",
         "Marquez le délégué avec 'weak' pour éviter un cycle de référence: weak var delegate",
         IssueSeverity::Error),
        
        (r"\.append\(self\)",
         "Ajout de self à un tableau ou collection",
         "Utilisez [weak self] ou référence faible pour éviter une référence forte",
         IssueSeverity::Error),
        
        (r"\w+!",
         "Force unwrapping d'optionnel",
         "Remplacez par une méthode plus sûre comme 'if let', 'guard let' ou '?'",
         IssueSeverity::Warning)
    ];
    
    analyze_patterns(file, content, &patterns, "memory", issues);
}

fn analyze_concurrency(file: &str, content: &str, issues: Arc<Mutex<Vec<Issue>>>) {
    // Patterns de concurrence
    let patterns = [
        (r"DispatchQueue\.main\.async\s*\{(?!\s*\[weak\s+self\])[^\}]*?self",
         "Usage de self dans DispatchQueue sans [weak self]",
         "Utilisez [weak self] pour éviter les cycles de référence",
         IssueSeverity::Error),
         
        (r"Task\s*\{(?!\s*\[weak\s+self\])[^\}]*?self",
         "Usage de self dans Task sans [weak self]",
         "Utilisez [weak self] pour éviter les problèmes de cycle de vie",
         IssueSeverity::Error),
         
        (r"@MainActor\s+(?!func|class).*\s+viewContext",
         "viewContext utilisé sans @MainActor",
         "Placez le code qui utilise viewContext dans une méthode ou classe @MainActor",
         IssueSeverity::Critical),
         
        (r"\.performBackgroundTask\s*\{[^\}]*?\.viewContext",
         "Accès à viewContext depuis un thread background",
         "Utilisez le contexte fourni dans le bloc performBackgroundTask",
         IssueSeverity::Critical)
    ];
    
    analyze_patterns(file, content, &patterns, "concurrency", issues);
    
    // Analyse des accès simultanés aux propriétés partagées
    if content.contains("actor") && content.contains("nonisolated") {
        let nonisolated_re = Regex::new(r"nonisolated\s+(func|var)\s+(\w+)").unwrap();
        
        for cap in nonisolated_re.captures_iter(content) {
            let func_name = &cap[2];
            // Vérifier si la fonction nonisolated accède à des états partagés
            if content.contains(&format!("self.{}", func_name)) {
                let line = count_lines_until_position(content, cap.get(0).unwrap().start());
                
                issues.lock().unwrap().push(Issue {
                    file: file.to_string(),
                    line,
                    message: format!("Fonction nonisolated '{}' qui semble accéder à l'état partagé", func_name),
                    severity: IssueSeverity::Error,
                    category: "concurrency".to_string(),
                    code: extract_line_at_position(content, cap.get(0).unwrap().start()),
                    suggestion: "Retirez nonisolated ou n'accédez pas à l'état partagé dans cette fonction".to_string()
                });
            }
        }
    }
}

fn analyze_coredata(file: &str, content: &str, issues: Arc<Mutex<Vec<Issue>>>) {
    // Patterns CoreData
    let patterns = [
        (r"try\s+context\.(fetch|execute|save)\([^\)]*\)(?!\s*catch)",
         "Opération CoreData sans gestion d'erreur (try/catch)",
         "Entourez les opérations CoreData avec un bloc try/catch",
         IssueSeverity::Critical),
         
        (r"NSFetchRequest<[^>]+>[^\)]*\)(?!\s*\.fetchBatchSize)",
         "NSFetchRequest sans fetchBatchSize",
         "Définissez fetchBatchSize pour améliorer les performances de chargement",
         IssueSeverity::Warning),
         
        (r"\.viewContext\.perform\(",
         "Usage de .perform() sur viewContext",
         "viewContext est déjà sur le thread principal, pas besoin de .perform()",
         IssueSeverity::Warning),
         
        (r"NSPredicate\(format:\s*\"[^\"]*CONTAINS[^\"]*\"[^,]",
         "NSPredicate CONTAINS sans index sur l'attribut",
         "Assurez-vous que l'attribut utilisé avec CONTAINS est indexé",
         IssueSeverity::Warning)
    ];
    
    analyze_patterns(file, content, &patterns, "coredata", issues);
}

fn analyze_complexity(file: &str, content: &str, issues: Arc<Mutex<Vec<Issue>>>) {
    // Trouver les fonctions longues et complexes
    let func_re = Regex::new(r"func\s+(\w+)[^\{]*\{").unwrap();
    
    for cap in func_re.captures_iter(content) {
        let func_name = &cap[1];
        let start_pos = cap.get(0).unwrap().end() - 1;
        
        if let Some(func_content) = extract_function_content(content, start_pos) {
            let func_lines = func_content.lines().count();
            
            // Calculer la complexité cyclomatique approximative
            let if_count = func_content.matches("if ").count();
            let for_count = func_content.matches("for ").count();
            let while_count = func_content.matches("while ").count();
            let switch_count = func_content.matches("switch ").count();
            let guard_count = func_content.matches("guard ").count();
            
            let complexity = 1 + if_count + for_count + while_count + switch_count + guard_count;
            
            // Trouver les problèmes de complexité
            if func_lines > 50 {
                let line = count_lines_until_position(content, cap.get(0).unwrap().start());
                
                issues.lock().unwrap().push(Issue {
                    file: file.to_string(),
                    line,
                    message: format!("Fonction '{}' trop longue ({} lignes)", func_name, func_lines),
                    severity: IssueSeverity::Warning,
                    category: "complexity".to_string(),
                    code: format!("func {}... {{ /* {} lignes */ }}", func_name, func_lines),
                    suggestion: "Décomposez cette fonction en plusieurs méthodes plus petites".to_string()
                });
            }
            
            if complexity > 10 {
                let line = count_lines_until_position(content, cap.get(0).unwrap().start());
                
                issues.lock().unwrap().push(Issue {
                    file: file.to_string(),
                    line,
                    message: format!("Fonction '{}' trop complexe (complexité cyclomatique: {})", func_name, complexity),
                    severity: if complexity > 15 { IssueSeverity::Error } else { IssueSeverity::Warning },
                    category: "complexity".to_string(),
                    code: format!("func {}... {{ /* complexité: {} */ }}", func_name, complexity),
                    suggestion: "Simplifiez cette fonction en extrayant la logique en méthodes plus spécialisées".to_string()
                });
            }
        }
    }
}

fn analyze_patterns(file: &str, content: &str, patterns: &[(& str, & str, & str, IssueSeverity)], 
                  category: &str, issues: Arc<Mutex<Vec<Issue>>>) {
    for (pattern, message, suggestion, severity) in patterns {
        let re = Regex::new(pattern).unwrap();
        
        for cap in re.captures_iter(content) {
            let line = count_lines_until_position(content, cap.get(0).unwrap().start());
            let code = extract_line_at_position(content, cap.get(0).unwrap().start());
            
            issues.lock().unwrap().push(Issue {
                file: file.to_string(),
                line,
                message: message.to_string(),
                severity: severity.clone(),
                category: category.to_string(),
                code,
                suggestion: suggestion.to_string()
            });
        }
    }
}

fn count_lines_until_position(content: &str, pos: usize) -> usize {
    let sub_content = &content[..pos];
    sub_content.chars().filter(|&c| c == '\n').count() + 1
}

fn extract_function_content(content: &str, start_pos: usize) -> Option<String> {
    let mut balance = 1;
    let mut end_pos = start_pos + 1;
    let chars: Vec<char> = content.chars().collect();
    
    for i in start_pos + 1..chars.len() {
        match chars[i] {
            '{' => balance += 1,
            '}' => balance -= 1,
            _ => {}
        }
        
        if balance == 0 {
            end_pos = i + 1;
            break;
        }
    }
    
    if balance == 0 {
        Some(content[start_pos..end_pos].to_string())
    } else {
        None
    }
}

fn extract_line_at_position(content: &str, pos: usize) -> String {
    let start = content[..pos].rfind('\n').map_or(0, |p| p + 1);
    let end = content[pos..].find('\n').map_or(content.len(), |p| p + pos);
    content[start..end].trim().to_string()
}

fn collect_swift_files(dir: &str) -> Vec<PathBuf> {
    let mut files = Vec::new();
    
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.filter_map(|e| e.ok()) {
            let path = entry.path();
            
            if path.is_dir() && !path.to_string_lossy().contains("build") && !path.to_string_lossy().contains(".git") {
                files.append(&mut collect_swift_files(&path.to_string_lossy()));
            } else if path.is_file() && path.extension().map_or(false, |ext| ext == "swift") {
                files.push(path);
            }
        }
    }
    
    files
}

fn generate_fix_report(issues: &[Issue]) {
    let mut fixes = String::new();
    
    fixes.push_str("#!/bin/bash\n\n");
    fixes.push_str("# Script de correction automatique généré par Swift Performance Analyzer\n");
    fixes.push_str("# Date: ");
    fixes.push_str(&format!("{}\n\n", SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs()));
    
    fixes.push_str("echo 'Application des corrections automatiques...'\n\n");
    
    // Trier par fichier pour grouper les modifications
    let mut issues_by_file: HashMap<String, Vec<&Issue>> = HashMap::new();
    
    for issue in issues {
        issues_by_file.entry(issue.file.clone()).or_default().push(issue);
    }
    
    for (file, file_issues) in issues_by_file {
        fixes.push_str(&format!("echo 'Traitement du fichier: {}'\n", file));
        
        for issue in file_issues {
            fixes.push_str(&format!("# Ligne {}: {}\n", issue.line, issue.message));
            
            if issue.message.contains("weak self") {
                fixes.push_str(&format!("# Ajoutez [weak self] au début de la closure ligne {}\n\n", issue.line));
            }
            else if issue.message.contains("complexité") || issue.message.contains("longue") {
                fixes.push_str(&format!("# Refactorisez la fonction à la ligne {}\n\n", issue.line));
            }
            else {
                fixes.push_str(&format!("# Suggestion: {}\n\n", issue.suggestion));
            }
        }
    }
    
    fixes.push_str("echo 'Corrections automatiques terminées.'\n");
    
    if let Ok(mut file) = fs::File::create("swift_auto_fix.sh") {
        let _ = file.write_all(fixes.as_bytes());
        let _ = fs::set_permissions("swift_auto_fix.sh", fs::Permissions::from_mode(0o755));
        println!("Script de correction généré: swift_auto_fix.sh");
    }
}
