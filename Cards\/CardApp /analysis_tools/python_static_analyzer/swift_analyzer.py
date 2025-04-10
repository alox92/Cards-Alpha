#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
CardApp - Analyseur Statique Swift
Ce script analyse le code Swift pour détecter les problèmes potentiels liés à:
- Cycles de référence manquants ([weak self])
- Dépendances circulaires
- Requêtes CoreData sans gestion d'erreur
- Problèmes de concurrence dans les opérations asynchrones
"""

import os
import re
import json
import sys
import argparse
from concurrent.futures import ProcessPoolExecutor
from typing import Dict, List, Set, Tuple, Any, Optional
import logging

# Configuration du logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('swift_analyzer')

# Types d'analyse
ANALYSIS_TYPES = {
    'memory': 'Analyse des problèmes de gestion mémoire',
    'concurrency': 'Analyse des problèmes de concurrence',
    'coredata': 'Analyse des problèmes liés à CoreData',
    'dependency': 'Analyse des dépendances circulaires',
    'all': 'Toutes les analyses'
}

# Niveaux de sévérité
class Severity:
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"

class Issue:
    """Classe représentant un problème détecté dans le code."""
    
    def __init__(self, file: str, line: int, issue_type: str, 
                 description: str, severity: str, auto_fixable: bool = False,
                 fix_suggestion: Optional[str] = None):
        self.file = file
        self.line = line
        self.type = issue_type
        self.description = description
        self.severity = severity
        self.auto_fixable = auto_fixable
        self.fix_suggestion = fix_suggestion
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertit l'issue en dictionnaire pour la sérialisation JSON."""
        return {
            'file': self.file,
            'line': self.line,
            'type': self.type,
            'description': self.description,
            'severity': self.severity,
            'autoFixable': self.auto_fixable,
            'fixSuggestion': self.fix_suggestion
        }

class SwiftAnalyzer:
    """Analyseur statique pour le code Swift."""
    
    def __init__(self, project_path: str, output_file: str, analysis_types: List[str]):
        self.project_path = os.path.abspath(project_path)
        self.output_file = output_file
        self.analysis_types = analysis_types if 'all' not in analysis_types else ['memory', 'concurrency', 'coredata', 'dependency']
        self.issues: List[Issue] = []
        self.files_analyzed = 0
        self.class_dependencies: Dict[str, Set[str]] = {}
        self.swift_files: List[str] = []
        
    def find_swift_files(self) -> List[str]:
        """Trouve tous les fichiers Swift dans le projet."""
        swift_files = []
        for root, _, files in os.walk(self.project_path):
            for file in files:
                if file.endswith('.swift'):
                    swift_files.append(os.path.join(root, file))
        return swift_files
    
    def analyze_file(self, file_path: str) -> List[Issue]:
        """Analyse un fichier Swift et retourne les problèmes détectés."""
        file_issues = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            relative_path = os.path.relpath(file_path, self.project_path)
            
            # Appliquer les différentes analyses selon les types demandés
            if 'memory' in self.analysis_types:
                file_issues.extend(self.analyze_memory_issues(content, relative_path))
            
            if 'concurrency' in self.analysis_types:
                file_issues.extend(self.analyze_concurrency_issues(content, relative_path))
            
            if 'coredata' in self.analysis_types:
                file_issues.extend(self.analyze_coredata_issues(content, relative_path))
            
            if 'dependency' in self.analysis_types:
                self.extract_class_dependencies(content, relative_path)
                
        except Exception as e:
            logger.error(f"Erreur lors de l'analyse du fichier {file_path}: {e}")
            
        return file_issues
    
    def analyze_memory_issues(self, content: str, file_path: str) -> List[Issue]:
        """Analyse les problèmes de gestion mémoire."""
        issues = []
        
        # Détecter les closures sans [weak self]
        closure_pattern = r'(\{.*?self\.[a-zA-Z0-9_]+.*?\})'
        weak_self_pattern = r'\[\s*weak\s+self\s*\]'
        
        closure_matches = re.finditer(closure_pattern, content, re.DOTALL)
        for match in closure_matches:
            closure_text = match.group(1)
            closure_start = content[:match.start()].count('\n') + 1
            
            # Si "self" est utilisé mais pas [weak self]
            if "self." in closure_text and not re.search(weak_self_pattern, closure_text):
                # Vérifier si c'est dans un contexte @escaping
                preceding_code = content[:match.start()]
                # Si on trouve "escaping" ou "completionHandler" ou certains mots clés comme "async"
                if "@escaping" in preceding_code[-100:] or "completionHandler" in preceding_code[-100:] or "async" in preceding_code[-100:]:
                    issues.append(Issue(
                        file=file_path,
                        line=closure_start,
                        issue_type="MissingWeakSelf",
                        description="Utilisation de 'self' dans une closure sans [weak self], risque de cycle de référence",
                        severity=Severity.HIGH,
                        auto_fixable=True,
                        fix_suggestion="Ajouter [weak self] au début de la closure et vérifier si self est nil"
                    ))
        
        # Détecter les propriétés à fort risque de cycle de référence
        strong_delegate_pattern = r'var\s+(\w+)(?:\s*:\s*\w+Delegate|\s*:\s*\w+DataSource)'
        for match in re.finditer(strong_delegate_pattern, content):
            line = content[:match.start()].count('\n') + 1
            prop_name = match.group(1)
            
            # Vérifier si le mot-clé "weak" n'est pas présent
            if not re.search(r'weak\s+var\s+' + prop_name, content):
                issues.append(Issue(
                    file=file_path,
                    line=line,
                    issue_type="StrongDelegateReference",
                    description=f"La propriété delegate '{prop_name}' devrait être marquée comme weak pour éviter les cycles de référence",
                    severity=Severity.HIGH,
                    auto_fixable=True,
                    fix_suggestion=f"Changer 'var {prop_name}' en 'weak var {prop_name}'"
                ))
        
        return issues
    
    def analyze_concurrency_issues(self, content: str, file_path: str) -> List[Issue]:
        """Analyse les problèmes de concurrence."""
        issues = []
        
        # Détecter les propriétés partagées sans protection de concurrence
        shared_property_pattern = r'static\s+(let|var)\s+shared\s*=\s*[^(]*?\([^)]*?\)'
        for match in re.finditer(shared_property_pattern, content):
            line = content[:match.start()].count('\n') + 1
            var_type = match.group(1)
            
            # Si c'est une var (mutable) et qu'il n'y a pas de protection apparente
            if var_type == 'var' and not re.search(r'DispatchQueue|NSLock|os_unfair_lock|@Sendable', content):
                issues.append(Issue(
                    file=file_path,
                    line=line,
                    issue_type="UnsynchronizedSharedInstance",
                    description="Instance partagée mutable sans synchronisation apparente, risque de data race",
                    severity=Severity.CRITICAL,
                    auto_fixable=False,
                    fix_suggestion="Utiliser DispatchQueue, NSLock ou marquer les propriétés comme @Sendable"
                ))
        
        # Détecter les opérations CoreData sur le thread principal
        main_thread_coredata_pattern = r'(viewContext|NSManagedObjectContext\(\))\.(?:fetch|execute|save)(?!.*DispatchQueue\.global)'
        for match in re.finditer(main_thread_coredata_pattern, content):
            line = content[:match.start()].count('\n') + 1
            context_type = match.group(1)
            
            issues.append(Issue(
                file=file_path,
                line=line,
                issue_type="MainThreadCoreData",
                description="Opération CoreData potentiellement lourde exécutée sur le thread principal",
                severity=Severity.MEDIUM,
                auto_fixable=False,
                fix_suggestion="Déplacer l'opération dans un background context: PersistenceController.shared.newBackgroundContext()"
            ))
        
        # Détecter les async sans Task
        async_without_task_pattern = r'func\s+\w+\s*\([^)]*\)\s*async[^{]*\{(?!.*\bTask\b)'
        for match in re.finditer(async_without_task_pattern, content):
            preceding_lines = content[:match.start()].split('\n')
            if len(preceding_lines) > 3:
                # Vérifier si la fonction contient @MainActor dans les 3 lignes précédentes
                has_main_actor = False
                for i in range(1, min(4, len(preceding_lines) + 1)):
                    if '@MainActor' in preceding_lines[-i]:
                        has_main_actor = True
                        break
                        
                if not has_main_actor:
                    line = len(preceding_lines)
                    issues.append(Issue(
                        file=file_path,
                        line=line,
                        issue_type="AsyncWithoutTaskOrMainActor",
                        description="Fonction async sans utilisation de Task ou @MainActor, peut causer des problèmes de séquencement",
                        severity=Severity.LOW,
                        auto_fixable=False,
                        fix_suggestion="Ajouter @MainActor ou utiliser Task pour contrôler le contexte d'exécution"
                    ))
        
        return issues
    
    def analyze_coredata_issues(self, content: str, file_path: str) -> List[Issue]:
        """Analyse les problèmes liés à CoreData."""
        issues = []
        
        # Détecter les requêtes CoreData sans try/catch
        fetch_without_try_pattern = r'\.fetch\([^)]+\)(?![^.{]*catch)'
        execute_without_try_pattern = r'\.execute\([^)]+\)(?![^.{]*catch)'
        
        # Rechercher les fetch sans try
        for match in re.finditer(fetch_without_try_pattern, content):
            line = content[:match.start()].count('\n') + 1
            preceding_code = content[:match.start()].split('\n')[-5:]  # 5 lignes précédentes
            preceding_text = '\n'.join(preceding_code)
            
            # Si "try" n'est pas dans les 5 lignes précédentes
            if not re.search(r'\btry\b', preceding_text):
                issues.append(Issue(
                    file=file_path,
                    line=line,
                    issue_type="FetchRequestWithoutErrorHandling",
                    description="Requête fetch() CoreData sans gestion d'erreur (try/catch)",
                    severity=Severity.HIGH,
                    auto_fixable=False,
                    fix_suggestion="Ajouter try/catch autour de la requête fetch()"
                ))
        
        # Rechercher les execute sans try
        for match in re.finditer(execute_without_try_pattern, content):
            line = content[:match.start()].count('\n') + 1
            preceding_code = content[:match.start()].split('\n')[-5:]  # 5 lignes précédentes
            preceding_text = '\n'.join(preceding_code)
            
            # Si "try" n'est pas dans les 5 lignes précédentes
            if not re.search(r'\btry\b', preceding_text):
                issues.append(Issue(
                    file=file_path,
                    line=line,
                    issue_type="ExecuteRequestWithoutErrorHandling",
                    description="Requête execute() CoreData sans gestion d'erreur (try/catch)",
                    severity=Severity.HIGH,
                    auto_fixable=False,
                    fix_suggestion="Ajouter try/catch autour de la requête execute()"
                ))
        
        # Détecter les fetchRequest sans NSSortDescriptor
        fetch_request_without_sort = r'NSFetchRequest<[^>]+>\(entityName:[^)]+\)(?![^;]*sortDescriptors)'
        for match in re.finditer(fetch_request_without_sort, content):
            line = content[:match.start()].count('\n') + 1
            issues.append(Issue(
                file=file_path,
                line=line,
                issue_type="FetchRequestWithoutSorting",
                description="NSFetchRequest sans spécification de sortDescriptors",
                severity=Severity.MEDIUM,
                auto_fixable=True,
                fix_suggestion="Ajouter request.sortDescriptors = [NSSortDescriptor(...)]"
            ))
        
        return issues
    
    def extract_class_dependencies(self, content: str, file_path: str) -> None:
        """Extrait les dépendances entre classes pour l'analyse ultérieure."""
        # Trouver le nom de la classe
        class_match = re.search(r'class\s+(\w+)', content)
        if not class_match:
            return
        
        class_name = class_match.group(1)
        
        # Trouver toutes les classes importées ou utilisées
        dependencies = set()
        
        # Chercher les imports explicites
        import_pattern = r'import\s+(\w+)'
        for match in re.finditer(import_pattern, content):
            dependencies.add(match.group(1))
        
        # Chercher les types explicites
        type_pattern = r':\s*(\w+)'
        for match in re.finditer(type_pattern, content):
            dependency = match.group(1)
            # Exclure les types primitifs et génériques courants
            if dependency not in ['Int', 'String', 'Bool', 'Double', 'Float', 'Any', 'Void', 'Element', 'T', 'U']:
                dependencies.add(dependency)
        
        # Enregistrer les dépendances
        self.class_dependencies[class_name] = dependencies
    
    def detect_circular_dependencies(self) -> List[Issue]:
        """Détecte les dépendances circulaires entre les classes."""
        issues = []
        
        def find_path(start: str, end: str, path: List[str] = None) -> List[str]:
            """Recherche récursive d'un chemin entre start et end."""
            if path is None:
                path = []
            
            # Éviter les boucles infinies
            if start in path:
                return []
            
            path = path + [start]
            
            if start == end:
                return path
            
            if start not in self.class_dependencies:
                return []
            
            for dependent in self.class_dependencies[start]:
                if dependent in self.class_dependencies:
                    new_path = find_path(dependent, end, path)
                    if new_path:
                        return new_path
            
            return []
        
        # Pour chaque classe, chercher un chemin circulaire
        for class_name in self.class_dependencies:
            # Pour chaque dépendance directe
            for dependency in self.class_dependencies[class_name]:
                if dependency in self.class_dependencies:
                    # Chercher un chemin de retour vers la classe d'origine
                    circular_path = find_path(dependency, class_name)
                    if circular_path:
                        # Trouver le fichier source de la classe
                        class_file = self.find_class_file(class_name)
                        if class_file:
                            cycle = " -> ".join([class_name] + circular_path)
                            issues.append(Issue(
                                file=class_file,
                                line=1,  # Ligne approximative
                                issue_type="CircularDependency",
                                description=f"Dépendance circulaire détectée: {cycle}",
                                severity=Severity.HIGH,
                                auto_fixable=False,
                                fix_suggestion="Utiliser un pattern de design tel que Dependency Injection, Protocol Delegation ou une architecture MVVM plus stricte."
                            ))
        
        return issues
    
    def find_class_file(self, class_name: str) -> Optional[str]:
        """Trouve le fichier source d'une classe."""
        possible_files = [
            f"{class_name}.swift",
            f"{class_name}ViewModel.swift",
            f"{class_name}Service.swift",
            f"{class_name}Controller.swift",
            f"{class_name}View.swift"
        ]
        
        for file_path in self.swift_files:
            file_name = os.path.basename(file_path)
            if file_name in possible_files:
                return os.path.relpath(file_path, self.project_path)
        
        return None
    
    def run_analysis(self) -> Dict[str, Any]:
        """Exécute l'analyse complète du projet."""
        logger.info(f"Démarrage de l'analyse du projet: {self.project_path}")
        
        # Trouver tous les fichiers Swift
        self.swift_files = self.find_swift_files()
        logger.info(f"Trouvé {len(self.swift_files)} fichiers Swift à analyser")
        
        # Analyser chaque fichier en parallèle
        with ProcessPoolExecutor() as executor:
            file_issues = list(executor.map(self.analyze_file, self.swift_files))
        
        # Aplatir la liste des problèmes
        for issues in file_issues:
            self.issues.extend(issues)
        
        # Exécuter l'analyse des dépendances circulaires si demandé
        if 'dependency' in self.analysis_types:
            self.issues.extend(self.detect_circular_dependencies())
        
        # Générer le rapport
        report = {
            'projectPath': self.project_path,
            'filesAnalyzed': len(self.swift_files),
            'totalIssues': len(self.issues),
            'issuesBySeverity': {
                Severity.CRITICAL: sum(1 for i in self.issues if i.severity == Severity.CRITICAL),
                Severity.HIGH: sum(1 for i in self.issues if i.severity == Severity.HIGH),
                Severity.MEDIUM: sum(1 for i in self.issues if i.severity == Severity.MEDIUM),
                Severity.LOW: sum(1 for i in self.issues if i.severity == Severity.LOW)
            },
            'issuesByType': {},
            'issues': [issue.to_dict() for issue in self.issues]
        }
        
        # Regrouper par type
        for issue in self.issues:
            if issue.type not in report['issuesByType']:
                report['issuesByType'][issue.type] = 0
            report['issuesByType'][issue.type] += 1
        
        # Écrire le rapport dans un fichier JSON
        with open(self.output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2)
        
        logger.info(f"Analyse terminée. {len(self.issues)} problèmes détectés. Rapport écrit dans {self.output_file}")
        
        return report

def main():
    """Point d'entrée principal du programme."""
    parser = argparse.ArgumentParser(description='Analyseur statique pour code Swift')
    parser.add_argument('project_path', help='Chemin vers le projet Swift à analyser')
    parser.add_argument('-o', '--output', default='python_analysis.json', help='Fichier de sortie JSON (défaut: python_analysis.json)')
    parser.add_argument('-t', '--types', nargs='+', choices=list(ANALYSIS_TYPES.keys()), default=['all'], 
                        help='Types d\'analyse à effectuer (défaut: all)')
    parser.add_argument('-v', '--verbose', action='store_true', help='Mode verbeux')
    
    args = parser.parse_args()
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    analyzer = SwiftAnalyzer(args.project_path, args.output, args.types)
    report = analyzer.run_analysis()
    
    # Afficher un résumé
    print("\n==== Résumé de l'analyse ====")
    print(f"Fichiers analysés: {report['filesAnalyzed']}")
    print(f"Problèmes détectés: {report['totalIssues']}")
    print("\nProblèmes par sévérité:")
    for severity, count in report['issuesBySeverity'].items():
        print(f"  {severity}: {count}")
    print("\nProblèmes par type:")
    for issue_type, count in report['issuesByType'].items():
        print(f"  {issue_type}: {count}")
    
    print(f"\nRapport détaillé écrit dans: {args.output}")
    
    # Sortir avec un code d'erreur si des problèmes critiques ont été trouvés
    if report['issuesBySeverity'][Severity.CRITICAL] > 0:
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 