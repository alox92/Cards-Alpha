use std::collections::HashMap;
use std::path::{Path, PathBuf};
use serde::{Serialize, Deserialize};

/// Niveau de sévérité d'un problème
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
pub enum Severity {
    Critical,
    High,
    Medium,
    Low,
}

/// Type de problème détecté
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum IssueType {
    HighComplexity,
    DeepNesting,
    UnsafeClosure,
    CoreDataMainThread,
    MissingErrorHandling,
    PotentialDataRace,
    InefficientCollection,
    MemoryLeak,
    ResourceLeak,
    HighCoupling,
    ExcessiveComputation,
}

/// Configuration pour l'analyse
#[derive(Debug, Clone)]
pub struct AnalysisConfig {
    pub cyclomatic_complexity_threshold: u32,
    pub nesting_depth_threshold: u32,
    pub min_severity: Severity,
    pub analyze_closure_captures: bool,
    pub analyze_core_data: bool,
    pub analyze_concurrency: bool,
}

/// Métadonnées et métriques d'un fichier
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileMetrics {
    pub functions_count: usize,
    pub classes_count: usize,
    pub max_function_size: usize,
    pub max_class_size: usize,
    pub max_cyclomatic_complexity: f64,
    pub avg_cyclomatic_complexity: f64,
    pub max_nesting_depth: u32,
    pub avg_nesting_depth: f64,
}

impl Default for FileMetrics {
    fn default() -> Self {
        FileMetrics {
            functions_count: 0,
            classes_count: 0,
            max_function_size: 0,
            max_class_size: 0,
            max_cyclomatic_complexity: 0.0,
            avg_cyclomatic_complexity: 0.0,
            max_nesting_depth: 0,
            avg_nesting_depth: 0.0,
        }
    }
}

/// Problème détecté dans un fichier
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileIssue {
    pub issue_type: IssueType,
    pub severity: Severity,
    pub line: usize,
    pub column: Option<usize>,
    pub message: String,
    pub suggestion: Option<String>,
    pub code_snippet: Option<String>,
}

/// Résultat d'analyse d'un fichier
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnalysisResult {
    pub file_path: PathBuf,
    pub file_size: u64,
    pub line_count: usize,
    pub metrics: FileMetrics,
    pub issues: Vec<FileIssue>,
}

/// Structure pour représenter un fichier problématique
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HotspotFile {
    pub file_path: PathBuf,
    pub issue_count: usize,
    pub criticality_score: f64,
}

/// Statistiques globales du projet
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProjectStats {
    pub total_files: usize,
    pub problematic_files: usize,
    pub total_lines: usize,
    pub health_score: f64,
}

/// Rapport complet de l'analyse de performance
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceReport {
    pub files_analyzed: Vec<AnalysisResult>,
    pub issue_count_by_type: HashMap<IssueType, usize>,
    pub issue_count_by_severity: HashMap<Severity, usize>,
    pub hotspots: Vec<HotspotFile>,
    pub project_stats: ProjectStats,
} 