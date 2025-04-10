use std::{
    collections::HashMap,
    fs::{self, File},
    io::{self, Write},
    path::Path,
    time::Instant,
};
use walkdir::WalkDir;

#[derive(Debug)]
struct PerformanceIssue {
    file: String,
    line: usize,
    issue_type: String,
    description: String,
    severity: String,
}

#[derive(Debug)]
struct FileMetrics {
    complexity: usize,
    method_count: usize,
    async_calls: usize,
    core_data_calls: usize,
}

fn main() -> io::Result<()> {
    let start_time = Instant::now();
    let mut issues = Vec::new();
    let mut metrics = HashMap::new();

    // Analyse des fichiers Swift
    for entry in WalkDir::new(".")
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().map_or(false, |ext| ext == "swift"))
    {
        let path = entry.path();
        let content = fs::read_to_string(path)?;
        let file_metrics = analyze_file(&content);
        metrics.insert(path.to_string_lossy().to_string(), file_metrics);
        
        // Détection des problèmes de performance
        detect_performance_issues(&content, path, &mut issues);
    }

    // Génération du rapport
    generate_report(&issues, &metrics, start_time)?;

    Ok(())
}

fn analyze_file(content: &str) -> FileMetrics {
    let mut metrics = FileMetrics {
        complexity: 0,
        method_count: 0,
        async_calls: 0,
        core_data_calls: 0,
    };

    for line in content.lines() {
        // Analyse de la complexité
        if line.contains("if ") || line.contains("for ") || line.contains("while ") {
            metrics.complexity += 1;
        }

        // Comptage des méthodes
        if line.contains("func ") {
            metrics.method_count += 1;
        }

        // Détection des appels asynchrones
        if line.contains("async") || line.contains("await") {
            metrics.async_calls += 1;
        }

        // Détection des appels CoreData
        if line.contains("NSFetchRequest") || line.contains("context.save()") {
            metrics.core_data_calls += 1;
        }
    }

    metrics
}

fn detect_performance_issues(content: &str, path: &Path, issues: &mut Vec<PerformanceIssue>) {
    for (i, line) in content.lines().enumerate() {
        // Détection des boucles potentiellement coûteuses
        if line.contains("for ") && line.contains("in ") && !line.contains("fetchBatchSize") {
            issues.push(PerformanceIssue {
                file: path.to_string_lossy().to_string(),
                line: i + 1,
                issue_type: "Loop Performance".to_string(),
                description: "Boucle sans limite de taille de lot".to_string(),
                severity: "Warning".to_string(),
            });
        }

        // Détection des appels CoreData synchrones
        if line.contains("context.save()") && !line.contains("try") {
            issues.push(PerformanceIssue {
                file: path.to_string_lossy().to_string(),
                line: i + 1,
                issue_type: "CoreData Performance".to_string(),
                description: "Sauvegarde CoreData synchrone détectée".to_string(),
                severity: "Error".to_string(),
            });
        }

        // Détection des opérations coûteuses sur le thread principal
        if line.contains("DispatchQueue.main.async") && line.contains("context.save()") {
            issues.push(PerformanceIssue {
                file: path.to_string_lossy().to_string(),
                line: i + 1,
                issue_type: "Thread Safety".to_string(),
                description: "Opération CoreData sur le thread principal".to_string(),
                severity: "Error".to_string(),
            });
        }
    }
}

fn generate_report(
    issues: &[PerformanceIssue],
    metrics: &HashMap<String, FileMetrics>,
    start_time: Instant,
) -> io::Result<()> {
    let mut report = File::create("performance_analysis_report.md")?;
    
    writeln!(report, "# Rapport d'Analyse de Performance")?;
    writeln!(report, "\n## Métriques Globales")?;
    writeln!(report, "- Temps d'analyse: {:?}", start_time.elapsed())?;
    writeln!(report, "- Nombre de fichiers analysés: {}", metrics.len())?;
    
    writeln!(report, "\n## Problèmes de Performance")?;
    for issue in issues {
        writeln!(
            report,
            "### {} ({}): {}",
            issue.file, issue.line, issue.issue_type
        )?;
        writeln!(report, "- Description: {}", issue.description)?;
        writeln!(report, "- Sévérité: {}", issue.severity)?;
    }
    
    writeln!(report, "\n## Métriques par Fichier")?;
    for (file, metric) in metrics {
        writeln!(report, "### {}", file)?;
        writeln!(report, "- Complexité: {}", metric.complexity)?;
        writeln!(report, "- Nombre de méthodes: {}", metric.method_count)?;
        writeln!(report, "- Appels asynchrones: {}", metric.async_calls)?;
        writeln!(report, "- Appels CoreData: {}", metric.core_data_calls)?;
    }

    Ok(())
} 