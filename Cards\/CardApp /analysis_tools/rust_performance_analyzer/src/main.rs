use clap::Parser;
use colored::*;
use indicatif::{MultiProgress, ProgressBar, ProgressStyle};
use rayon::prelude::*;
use regex::Regex;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::time::Instant;
use walkdir::WalkDir;
use structopt::StructOpt;

mod analyzer;
mod models;
mod reports;
mod rules;

use analyzer::{analyze_file, AnalysisContext, AnalysisResult};
use models::{FileIssue, IssueType, PerformanceReport, Severity, AnalysisConfig, ProjectStats, HotspotFile};
use reports::generate_report;
use analyzers::{AnalysisContext, analyze_file};
use reporters::{json, html};

/// Analyseur de performance multi-thread pour code Swift
#[derive(Debug, StructOpt)]
#[structopt(name = "swift-analyzer", about = "Analyseur multi-thread de performances Swift")]
struct Opt {
    /// Chemin du projet Swift à analyser
    #[structopt(parse(from_os_str))]
    path: PathBuf,

    /// Types de fichiers à analyser (par défaut: .swift)
    #[structopt(short, long, default_value = "swift")]
    extensions: Vec<String>,

    /// Nombre maximum de threads à utiliser
    #[structopt(short, long, default_value = "0")]
    threads: usize,

    /// Format de sortie (json, html, console)
    #[structopt(short, long, default_value = "console")]
    output: String,

    /// Chemin du fichier de sortie (si json ou html est sélectionné)
    #[structopt(short, long)]
    report_path: Option<PathBuf>,

    /// Seuil de complexité cyclomatique pour signaler des problèmes
    #[structopt(long, default_value = "10")]
    complexity_threshold: u32,

    /// Seuil de profondeur d'imbrication pour signaler des problèmes
    #[structopt(long, default_value = "3")]
    nesting_threshold: u32,

    /// Sévérité minimale pour afficher (Critical, High, Medium, Low)
    #[structopt(long, default_value = "Low")]
    min_severity: String,

    /// Désactiver l'analyse de capture de closure
    #[structopt(long)]
    no_closure_capture_analysis: bool,

    /// Désactiver l'analyse CoreData
    #[structopt(long)]
    no_coredata_analysis: bool,

    /// Désactiver l'analyse de concurrence
    #[structopt(long)]
    no_concurrency_analysis: bool,
}

fn main() {
    let opt = Opt::from_args();
    
    // Définir le nombre de threads si spécifié
    if opt.threads > 0 {
        rayon::ThreadPoolBuilder::new()
            .num_threads(opt.threads)
            .build_global()
            .unwrap();
    }
    
    let now = Instant::now();
    println!("{}", "🔍 Analyse de performances Swift multi-thread".bold().green());
    println!("Chemin du projet: {}", opt.path.display().to_string().cyan());
    
    // Créer la configuration d'analyse
    let min_severity = match opt.min_severity.to_lowercase().as_str() {
        "critical" => models::Severity::Critical,
        "high" => models::Severity::High,
        "medium" => models::Severity::Medium,
        _ => models::Severity::Low,
    };
    
    let config = AnalysisConfig {
        cyclomatic_complexity_threshold: opt.complexity_threshold,
        nesting_depth_threshold: opt.nesting_threshold,
        min_severity,
        analyze_closure_captures: !opt.no_closure_capture_analysis,
        analyze_core_data: !opt.no_coredata_analysis,
        analyze_concurrency: !opt.no_concurrency_analysis,
    };
    
    // Collecter tous les fichiers Swift récursivement
    let mut swift_files = Vec::new();
    let extensions: Vec<String> = opt.extensions.iter().map(|e| format!(".{}", e)).collect();
    
    for entry in WalkDir::new(&opt.path).into_iter().filter_map(|e| e.ok()) {
        let path = entry.path();
        if path.is_file() {
            if let Some(ext) = path.extension() {
                if let Some(ext_str) = ext.to_str() {
                    if extensions.iter().any(|e| e.ends_with(&format!(".{}", ext_str))) {
                        swift_files.push(path.to_path_buf());
                    }
                }
            }
        }
    }
    
    println!("Fichiers trouvés pour l'analyse: {}", swift_files.len());
    
    // Créer une barre de progression
    let pb = ProgressBar::new(swift_files.len() as u64);
    pb.set_style(ProgressStyle::default_bar()
        .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} ({eta})")
        .unwrap()
        .progress_chars("#>-"));
    
    // Créer un rapport partagé
    let report = Arc::new(Mutex::new(PerformanceReport {
        files_analyzed: Vec::new(),
        issue_count_by_type: std::collections::HashMap::new(),
        issue_count_by_severity: std::collections::HashMap::new(),
        hotspots: Vec::new(),
        project_stats: ProjectStats {
            total_files: swift_files.len(),
            problematic_files: 0,
            total_lines: 0,
            health_score: 100.0,
        },
    }));
    
    // Analyser chaque fichier en parallèle
    swift_files.par_iter().for_each(|file_path| {
        let mut context = AnalysisContext::new(config.clone());
        let result = analyze_file(file_path, &mut context);
        
        // Mettre à jour le rapport avec les résultats
        let mut report = report.lock().unwrap();
        
        // Mettre à jour les compteurs de problèmes
        for issue in &result.issues {
            *report.issue_count_by_type.entry(issue.issue_type).or_insert(0) += 1;
            *report.issue_count_by_severity.entry(issue.severity).or_insert(0) += 1;
        }
        
        // Mettre à jour les statistiques du projet
        report.project_stats.total_lines += result.line_count;
        if !result.issues.is_empty() {
            report.project_stats.problematic_files += 1;
        }
        
        // Calculer le score de criticité du fichier
        let criticality_score = calculate_criticality_score(&result);
        
        // Ajouter aux hotspots si nécessaire
        if criticality_score > 0.0 {
            report.hotspots.push(HotspotFile {
                file_path: file_path.clone(),
                issue_count: result.issues.len(),
                criticality_score,
            });
        }
        
        // Ajouter le résultat au rapport
        report.files_analyzed.push(result);
        
        // Avancer la barre de progression
        pb.inc(1);
    });
    
    pb.finish_with_message("Analyse terminée!");
    
    // Finaliser et trier les hotspots
    let mut report = report.lock().unwrap();
    report.hotspots.sort_by(|a, b| b.criticality_score.partial_cmp(&a.criticality_score).unwrap());
    report.hotspots.truncate(10); // Garder seulement les 10 fichiers les plus problématiques
    
    // Calculer le score de santé du projet
    calculate_health_score(&mut report);
    
    // Afficher le rapport selon le format demandé
    match opt.output.as_str() {
        "json" => {
            if let Some(path) = &opt.report_path {
                json::generate_report(&report, path);
                println!("Rapport JSON généré: {}", path.display());
            } else {
                println!("{}", serde_json::to_string_pretty(&report).unwrap());
            }
        },
        "html" => {
            if let Some(path) = &opt.report_path {
                html::generate_report(&report, path);
                println!("Rapport HTML généré: {}", path.display());
            } else {
                println!("Chemin de rapport HTML non spécifié");
            }
        },
        _ => {
            print_console_report(&report);
        }
    }
    
    println!("Analyse complète en {:.2} secondes", now.elapsed().as_secs_f32());
}

/// Calcule le score de criticité d'un fichier basé sur ses problèmes
fn calculate_criticality_score(result: &models::AnalysisResult) -> f64 {
    let mut score = 0.0;
    
    for issue in &result.issues {
        score += match issue.severity {
            models::Severity::Critical => 10.0,
            models::Severity::High => 5.0,
            models::Severity::Medium => 2.0,
            models::Severity::Low => 0.5,
        };
    }
    
    // Ajouter un facteur basé sur la complexité
    score += result.metrics.max_cyclomatic_complexity * 0.5;
    score += result.metrics.max_nesting_depth as f64 * 0.3;
    
    // Normaliser par rapport à la taille du fichier
    if result.line_count > 0 {
        score = score * (1.0 + (result.line_count as f64 / 500.0).min(1.0));
    }
    
    score
}

/// Calcule le score de santé global du projet
fn calculate_health_score(report: &mut PerformanceReport) {
    let total_files = report.project_stats.total_files;
    if total_files == 0 {
        report.project_stats.health_score = 100.0;
        return;
    }
    
    let problematic_files = report.project_stats.problematic_files;
    let problem_ratio = problematic_files as f64 / total_files as f64;
    
    // Calculer le score en fonction du nombre de problèmes de chaque sévérité
    let mut severity_score = 0.0;
    let critical_issues = *report.issue_count_by_severity.get(&models::Severity::Critical).unwrap_or(&0) as f64;
    let high_issues = *report.issue_count_by_severity.get(&models::Severity::High).unwrap_or(&0) as f64;
    let medium_issues = *report.issue_count_by_severity.get(&models::Severity::Medium).unwrap_or(&0) as f64;
    let low_issues = *report.issue_count_by_severity.get(&models::Severity::Low).unwrap_or(&0) as f64;
    
    // Les problèmes critiques ont plus d'impact
    severity_score += critical_issues * 5.0;
    severity_score += high_issues * 2.0;
    severity_score += medium_issues * 0.5;
    severity_score += low_issues * 0.1;
    
    // Normaliser par le nombre total de lignes
    if report.project_stats.total_lines > 0 {
        severity_score = severity_score * 1000.0 / report.project_stats.total_lines as f64;
    }
    
    // Combiner les scores
    let health_score = 100.0 - (problem_ratio * 50.0 + severity_score.min(50.0));
    
    report.project_stats.health_score = health_score.max(0.0).min(100.0);
}

/// Affiche un rapport dans la console
fn print_console_report(report: &PerformanceReport) {
    println!("\n{}", "📊 RÉSUMÉ DE L'ANALYSE".bold().yellow());
    println!("---------------------------------------------------");
    println!("Score de santé du projet: {:.1}%", report.project_stats.health_score);
    println!("Fichiers analysés: {}", report.project_stats.total_files);
    println!("Fichiers avec problèmes: {} ({:.1}%)", 
             report.project_stats.problematic_files,
             (report.project_stats.problematic_files as f64 / report.project_stats.total_files as f64) * 100.0);
    println!("Lignes de code analysées: {}", report.project_stats.total_lines);
    
    // Résumé des problèmes par sévérité
    println!("\n{}", "PROBLÈMES PAR SÉVÉRITÉ".bold());
    for (severity, count) in &report.issue_count_by_severity {
        let color = match severity {
            models::Severity::Critical => "red",
            models::Severity::High => "yellow",
            models::Severity::Medium => "cyan",
            models::Severity::Low => "green",
        };
        println!("{}: {}", format!("{:?}", severity).color(color), count);
    }
    
    // Résumé des problèmes par type
    println!("\n{}", "PROBLÈMES PAR TYPE".bold());
    for (issue_type, count) in &report.issue_count_by_type {
        println!("{:?}: {}", issue_type, count);
    }
    
    // Points chauds (fichiers les plus problématiques)
    println!("\n{}", "POINTS CHAUDS (TOP 10)".bold().red());
    println!("---------------------------------------------------");
    for (i, hotspot) in report.hotspots.iter().enumerate() {
        let path = hotspot.file_path.display();
        println!("{}. {} - {} problèmes (score: {:.1})", 
                 i+1, 
                 path.to_string().yellow(), 
                 hotspot.issue_count, 
                 hotspot.criticality_score);
    }
    
    // Afficher les 20 problèmes les plus critiques
    println!("\n{}", "PROBLÈMES CRITIQUES".bold().red());
    println!("---------------------------------------------------");
    
    let mut all_issues: Vec<(&Path, &models::FileIssue)> = Vec::new();
    for result in &report.files_analyzed {
        for issue in &result.issues {
            if issue.severity == models::Severity::Critical || issue.severity == models::Severity::High {
                all_issues.push((&result.file_path, issue));
            }
        }
    }
    
    // Trier par sévérité
    all_issues.sort_by(|a, b| b.1.severity.cmp(&a.1.severity));
    all_issues.truncate(20);
    
    for (file_path, issue) in all_issues {
        let severity_str = match issue.severity {
            models::Severity::Critical => "CRITIQUE".red().bold(),
            models::Severity::High => "ELEVÉ".yellow().bold(),
            _ => "".normal(),
        };
        
        println!("{} {} à {}:{}:", 
                 severity_str,
                 format!("{:?}", issue.issue_type).cyan(),
                 file_path.display(),
                 issue.line);
        println!("   {} {}", "➤".yellow(), issue.message);
        if let Some(suggestion) = &issue.suggestion {
            println!("   {} {}", "✓".green(), suggestion);
        }
        if let Some(snippet) = &issue.code_snippet {
            println!("   {}", snippet.trim());
        }
        println!();
    }
} 