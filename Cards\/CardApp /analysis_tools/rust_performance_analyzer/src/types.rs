use std::path::PathBuf;
use serde::{Serialize, Deserialize};
use crate::models::{FileIssue, Severity, IssueType, FileMetrics};

/// Types de problèmes spécifiques à SwiftUI
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum SwiftUIIssueType {
    ExcessiveViewUpdates,
    InefficientBinding,
    MissingViewModifier,
    RedundantViewModifier,
    HeavyViewComputation,
}

/// Types de problèmes spécifiques à CoreData
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum CoreDataIssueType {
    MissingIndex,
    InefficientFetch,
    BatchingOpportunity,
    RedundantSaves,
    ThreadingViolation,
    MissingFetchedResultsController,
}

/// Information sur la complexité d'une fonction
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionComplexity {
    pub name: String,
    pub line_start: usize,
    pub line_end: usize,
    pub cyclomatic_complexity: f64,
    pub nesting_depth: u32,
    pub parameter_count: usize,
    pub length: usize,
}

/// Résultat d'analyse d'un cycle de référence
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReferenceCycleAnalysis {
    pub has_potential_cycle: bool,
    pub capture_line: usize,
    pub capture_description: String,
    pub suggestion: String,
}

/// Résultat d'analyse de concurrence
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConcurrencyAnalysis {
    pub has_race_condition: bool,
    pub affected_variables: Vec<String>,
    pub problematic_lines: Vec<usize>,
    pub suggestion: String,
}

/// Statistique de performance mémoire
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemoryStats {
    pub potential_leaks: usize,
    pub large_allocations: usize,
    pub unmanaged_resources: usize,
}

/// Contexte d'analyse complet pour un fichier
#[derive(Debug, Clone)]
pub struct FileAnalysisContext {
    pub file_path: PathBuf,
    pub content: String,
    pub lines: Vec<String>,
    pub metrics: FileMetrics,
    pub issues: Vec<FileIssue>,
    pub function_complexities: Vec<FunctionComplexity>,
    pub memory_stats: MemoryStats,
}

/// Type de recommandation d'optimisation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum OptimizationRecommendation {
    CodeRefactoring,
    AlgorithmImprovement,
    CachingStrategy,
    AsyncOperation,
    IndexCreation,
    BatchProcessing,
    MemoryManagement,
    ThreadSafety,
}

/// Recommandation détaillée
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Recommendation {
    pub recommendation_type: OptimizationRecommendation,
    pub file_path: PathBuf,
    pub line: Option<usize>,
    pub description: String,
    pub expected_improvement: String,
    pub code_example: Option<String>,
    pub difficulty: u8, // 1-10 scale
    pub priority: Severity,
}

/// Résultat complet d'analyse avec recommandations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtendedAnalysisResult {
    pub file_path: PathBuf,
    pub metrics: FileMetrics,
    pub issues: Vec<FileIssue>,
    pub function_complexities: Vec<FunctionComplexity>,
    pub recommendations: Vec<Recommendation>,
} 