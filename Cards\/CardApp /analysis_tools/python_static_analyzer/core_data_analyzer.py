#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Analyseur statique pour le code Swift, ciblant particulièrement les problèmes de CoreData et gestion mémoire.
"""

import os
import re
import json
import argparse
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass, field
from concurrent.futures import ProcessPoolExecutor
import time

# Définition des niveaux de sévérité
SEVERITY = {
    "CRITICAL": 4,
    "HIGH": 3,
    "MEDIUM": 2,
    "LOW": 1,
    "INFO": 0
}

# Définition des règles d'analyse
class AnalysisRule:
    def __init__(self, name: str, description: str, regex_pattern: str, severity: str, category: str):
        self.name = name
        self.description = description
        self.regex = re.compile(regex_pattern, re.MULTILINE | re.DOTALL)
        self.severity = severity
        self.category = category

# Règles pour CoreData
CORE_DATA_RULES = [
    AnalysisRule(
        "fetch_no_error_handling",
        "Requête CoreData sans gestion d'erreur",
        r"\.fetch\([^)]*\)(?!\s*\{|\s*try|\s*catch|\s*do)",
        "HIGH",
        "CoreData"
    ),
    AnalysisRule(
        "save_on_main_thread",
        "Sauvegarde CoreData sur le thread principal",
        r"(viewContext|viewContext\.save\(\)|\.save\(\)\s*\/\/\s*sur main)",
        "HIGH", 
        "CoreData"
    ),
    AnalysisRule(
        "fetch_without_predicate",
        "Requête fetch sans prédicat (potentiellement coûteuse)",
        r"NSFetchRequest<[^>]+>\(entityName:[^)]+\)(?!\s*\.predicate\s*=)",
        "MEDIUM",
        "CoreData"
    ),
    AnalysisRule(
        "missing_batch_insert",
        "Insertion d'entités sans utiliser les opérations batch",
        r"for\s+[^{]+\s*\{\s*[^}]*?NSEntityDescription\.insertNewObject\(",
        "MEDIUM",
        "CoreData"
    ),
    AnalysisRule(
        "heavy_core_data_operations",
        "Opérations CoreData potentiellement lourdes dans la boucle principale",
        r"func\s+body\b[^{]*\{[^}]*?(?:fetch|NSFetchRequest|NSManagedObject|viewContext\.save)",
        "HIGH",
        "CoreData"
    ),
]

# Règles pour la gestion mémoire
MEMORY_RULES = [
    AnalysisRule(
        "closure_retain_cycle",
        "Risque de cycle de rétention dans une closure (self non affaibli)",
        r"\{\s*(?!\[weak\s+self\]|\[unowned\s+self\]).*?self\.",
        "HIGH",
        "Memory"
    ),
    AnalysisRule(
        "delegate_not_weak",
        "Délégué non marqué comme weak",
        r"var\s+\w*delegate\w*\s*:\s*\w+(?!\?)\s*(?!\/\/\s*weak)(?!\s*\{\s*weak)",
        "HIGH",
        "Memory"
    ),
    AnalysisRule(
        "large_array_no_capacity",
        "Grand tableau sans capacité initiale",
        r"\[\w+\]()\s*=\s*\[\](?!\s*\/\/\s*with capacity)",
        "LOW",
        "Memory"
    ),
    AnalysisRule(
        "escaping_closure_no_weak_self",
        "Closure @escaping sans [weak self]",
        r"@escaping\s*(?!\[weak\s+self\]|\[unowned\s+self\])[^{]*\{[^}]*self\.",
        "HIGH",
        "Memory"
    ),
]

# Règles pour les problèmes de concurrence
CONCURRENCY_RULES = [
    AnalysisRule(
        "async_no_await",
        "Fonction async appelée sans await",
        r"(?<!await\s+)\b\w+Async\w*\([^)]*\)(?!\s*\.task)",
        "HIGH",
        "Concurrency"
    ),
    AnalysisRule(
        "non_atomic_shared_property",
        "Propriété partagée potentiellement non atomique",
        r"static\s+var\s+\w+\s*:[^{]*(?!(?:let|class)\b)(?!.*?=\s*\{)",
        "MEDIUM",
        "Concurrency"
    ),
    AnalysisRule(
        "unprotected_property_access",
        "Accès non protégé à propriété partagée",
        r"_\w+\s*=\s*(?!.*lock|.*queue|.*semaphore)",
        "MEDIUM",
        "Concurrency"
    ),
    AnalysisRule(
        "task_without_cancellation",
        "Tâche Task sans gestion d'annulation",
        r"Task\s*\{[^}]*?(?!\.cancel|isCancelled|Task\.checkCancellation)",
        "MEDIUM",
        "Concurrency"
    ),
]

# Toutes les règles combinées
ALL_RULES = CORE_DATA_RULES + MEMORY_RULES + CONCURRENCY_RULES

@dataclass
class Issue:
    rule_name: str
    description: str
    severity: str
    category: str 
    line_number: int
    line_text: str
    file_path: str

@dataclass
class FileMetrics:
    loc: int  # Lignes de code
    comment_lines: int
    function_count: int
    complexity: int
    class_count: int
    protocol_count: int
    extension_count: int
    

@dataclass
class AnalysisResult:
    file_path: str
    issues: List[Issue] = field(default_factory=list)
    metrics: Optional[FileMetrics] = None

class FileAnalyzer:
    def __init__(self, file_path: str):
        self.file_path = file_path
        self.content = ""
        self.lines = []
        self.load_file()
        
    def load_file(self):
        try:
            with open(self.file_path, 'r', encoding='utf-8') as f:
                self.content = f.read()
                self.lines = self.content.split('\n')
        except Exception as e:
            print(f"Erreur lors de la lecture de {self.file_path}: {str(e)}")
            
    def get_line_for_match(self, match_start: int) -> Tuple[int, str]:
        """Obtient le numéro de ligne et le texte pour une position donnée."""
        line_start = self.content.rfind('\n', 0, match_start) + 1
        line_end = self.content.find('\n', match_start)
        if line_end == -1:  # Dernière ligne
            line_end = len(self.content)
            
        line_text = self.content[line_start:line_end].strip()
        line_number = self.content.count('\n', 0, match_start) + 1
        
        return line_number, line_text
            
    def find_issues(self) -> List[Issue]:
        """Cherche des problèmes selon les règles définies."""
        if not self.content:
            return []
            
        issues = []
        
        for rule in ALL_RULES:
            for match in rule.regex.finditer(self.content):
                line_number, line_text = self.get_line_for_match(match.start())
                issues.append(Issue(
                    rule_name=rule.name,
                    description=rule.description,
                    severity=rule.severity,
                    category=rule.category,
                    line_number=line_number,
                    line_text=line_text,
                    file_path=self.file_path
                ))
                
        return issues
        
    def calculate_metrics(self) -> FileMetrics:
        """Calcule les métriques de code pour le fichier."""
        loc = len(self.lines)
        
        # Compter les lignes de commentaires
        comment_pattern = re.compile(r'^\s*(\/\/|\/\*|\*)')
        comment_lines = sum(1 for line in self.lines if comment_pattern.match(line))
        
        # Compter les fonctions
        function_pattern = re.compile(r'\bfunc\s+\w+')
        function_count = len(function_pattern.findall(self.content))
        
        # Compter les classes, protocols, extensions
        class_count = len(re.findall(r'\bclass\s+\w+', self.content))
        protocol_count = len(re.findall(r'\bprotocol\s+\w+', self.content))
        extension_count = len(re.findall(r'\bextension\s+\w+', self.content))
        
        # Calculer la complexité cyclomatique approximative
        decision_points = (
            len(re.findall(r'\bif\s+', self.content)) +
            len(re.findall(r'\belse\s+', self.content)) +
            len(re.findall(r'\bswitch\s+', self.content)) +
            len(re.findall(r'\bcase\s+', self.content)) +
            len(re.findall(r'\bfor\s+', self.content)) +
            len(re.findall(r'\bwhile\s+', self.content)) +
            len(re.findall(r'\bguard\s+', self.content)) +
            len(re.findall(r'\bcatch\s+', self.content))
        )
        complexity = 1 + decision_points
        
        return FileMetrics(
            loc=loc,
            comment_lines=comment_lines,
            function_count=function_count,
            complexity=complexity,
            class_count=class_count,
            protocol_count=protocol_count,
            extension_count=extension_count
        )
        
    def analyze(self) -> AnalysisResult:
        """Analyse complète du fichier."""
        if not os.path.exists(self.file_path) or not self.file_path.endswith('.swift'):
            return AnalysisResult(file_path=self.file_path)
            
        issues = self.find_issues()
        metrics = self.calculate_metrics() 
        
        return AnalysisResult(
            file_path=self.file_path,
            issues=issues,
            metrics=metrics
        )

class ProjectAnalyzer:
    def __init__(self, project_dir: str):
        self.project_dir = project_dir
        self.swift_files = []
        self.find_swift_files()
        
    def find_swift_files(self):
        """Trouve tous les fichiers Swift dans le projet."""
        for root, _, files in os.walk(self.project_dir):
            for file in files:
                if file.endswith('.swift'):
                    self.swift_files.append(os.path.join(root, file))
                    
    def analyze_file(self, file_path: str) -> AnalysisResult:
        """Analyse un seul fichier."""
        analyzer = FileAnalyzer(file_path)
        return analyzer.analyze()
        
    def analyze_project(self) -> List[AnalysisResult]:
        """Analyse tous les fichiers du projet en parallèle."""
        results = []
        
        with ProcessPoolExecutor() as executor:
            results = list(executor.map(self.analyze_file, self.swift_files))
            
        return results
        
    def get_summary(self, results: List[AnalysisResult]) -> Dict[str, Any]:
        """Génère un résumé des résultats d'analyse."""
        total_issues = 0
        issues_by_severity = {sev: 0 for sev in SEVERITY.keys()}
        issues_by_category = {}
        files_with_issues = 0
        total_files = len(results)
        
        for result in results:
            if result.issues:
                files_with_issues += 1
                total_issues += len(result.issues)
                
                for issue in result.issues:
                    issues_by_severity[issue.severity] += 1
                    
                    if issue.category not in issues_by_category:
                        issues_by_category[issue.category] = 0
                    issues_by_category[issue.category] += 1
        
        return {
            "total_files": total_files,
            "files_with_issues": files_with_issues,
            "total_issues": total_issues,
            "issues_by_severity": issues_by_severity,
            "issues_by_category": issues_by_category
        }
    
    def get_top_issues(self, results: List[AnalysisResult], limit: int = 10) -> List[Dict[str, Any]]:
        """Trouve les problèmes les plus critiques."""
        all_issues = []
        
        for result in results:
            for issue in result.issues:
                all_issues.append({
                    "file": os.path.relpath(issue.file_path, self.project_dir),
                    "line": issue.line_number,
                    "severity": issue.severity,
                    "category": issue.category,
                    "description": issue.description,
                    "code": issue.line_text
                })
                
        # Trier par sévérité (décroissante)
        all_issues.sort(key=lambda x: SEVERITY.get(x["severity"], 0), reverse=True)
        
        return all_issues[:limit]
                
    def analyze_and_report(self, output_file: Optional[str] = None) -> Dict[str, Any]:
        """Analyse le projet et génère un rapport complet."""
        start_time = time.time()
        print(f"Analyse de {len(self.swift_files)} fichiers Swift...")
        
        results = self.analyze_project()
        
        # Calculer les statistiques
        summary = self.get_summary(results)
        top_issues = self.get_top_issues(results, limit=20)
        
        # Collecter les issues par fichier
        issues_by_file = {}
        for result in results:
            if result.issues:
                rel_path = os.path.relpath(result.file_path, self.project_dir)
                issues_by_file[rel_path] = [
                    {
                        "description": issue.description,
                        "severity": issue.severity,
                        "category": issue.category,
                        "line": issue.line_number,
                        "code": issue.line_text
                    }
                    for issue in result.issues
                ]
                
        # Construire le rapport complet
        report = {
            "summary": summary,
            "top_issues": top_issues,
            "issues_by_file": issues_by_file,
            "analysis_time": time.time() - start_time
        }
        
        # Écrire le rapport dans un fichier si demandé
        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(report, f, indent=2)
            print(f"Rapport écrit dans {output_file}")
            
        return report

def main():
    parser = argparse.ArgumentParser(description="Analyseur statique pour code Swift")
    parser.add_argument("project_dir", help="Chemin du répertoire du projet")
    parser.add_argument("-o", "--output", help="Chemin du fichier de sortie JSON")
    args = parser.parse_args()
    
    analyzer = ProjectAnalyzer(args.project_dir)
    report = analyzer.analyze_and_report(args.output)
    
    # Afficher un résumé des résultats
    print(f"\nRésumé de l'analyse:")
    print(f"  Fichiers analysés: {report['summary']['total_files']}")
    print(f"  Fichiers avec problèmes: {report['summary']['files_with_issues']}")
    print(f"  Problèmes détectés: {report['summary']['total_issues']}")
    
    print("\nProblèmes par sévérité:")
    for sev, count in report['summary']['issues_by_severity'].items():
        if count > 0:
            print(f"  {sev}: {count}")
            
    print("\nProblèmes par catégorie:")
    for cat, count in report['summary']['issues_by_category'].items():
        if count > 0:
            print(f"  {cat}: {count}")
            
    print("\nTop 5 problèmes critiques:")
    for i, issue in enumerate(report['top_issues'][:5], 1):
        print(f"  {i}. [{issue['severity']}] {issue['description']} - {issue['file']}:{issue['line']}")
    
if __name__ == "__main__":
    main() 