#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Analyse statique de code Swift pour CardApp
-------------------------------------------
Ce script analyse le code Swift à la recherche de problèmes courants:
- Cycles de référence potentiels (captures de self sans [weak self])
- Problèmes de gestion d'erreurs dans les opérations CoreData
- Problèmes de concurrence dans les opérations asynchrones
- Dépendances circulaires entre les modules

Auteur: Assistant IA
Date: 10/04/2025
"""

import os
import re
import sys
import json
import argparse
from pathlib import Path
import concurrent.futures
from dataclasses import dataclass, field, asdict
from typing import List, Dict, Set, Tuple, Optional, Any
import time
from datetime import datetime

# Couleurs pour la console
ROUGE = '\033[0;31m'
VERT = '\033[0;32m'
JAUNE = '\033[0;33m'
BLEU = '\033[0;34m'
MAGENTA = '\033[0;35m'
CYAN = '\033[0;36m'
RESET = '\033[0m'
GRAS = '\033[1m'

# Configuration
MAX_WORKERS = os.cpu_count() or 4
VERBOSE = False
SWIFT_EXTENSIONS = {'.swift'}
EXCLUDE_DIRS = {'Pods', '.git', 'build', 'DerivedData', 'Carthage'}
EXCLUDE_FILES = {'Package.swift'}

# Modèles de regex pour l'analyse
PATTERNS = {
    'import': re.compile(r'import\s+([A-Za-z0-9_.]+)'),
    'class_def': re.compile(r'(?:public |private |internal |fileprivate )*(?:final )?class\s+(\w+)'),
    'protocol_def': re.compile(r'(?:public |private |internal |fileprivate )*protocol\s+(\w+)'),
    'struct_def': re.compile(r'(?:public |private |internal |fileprivate )*struct\s+(\w+)'),
    'enum_def': re.compile(r'(?:public |private |internal |fileprivate )*enum\s+(\w+)'),
    'extension_def': re.compile(r'extension\s+(\w+)'),
    'weak_self': re.compile(r'\[\s*weak\s+self\s*\]'),
    'closure': re.compile(r'(?:\{(?:[^{}]|(?:\{(?:[^{}]|(?:\{(?:[^{}])*\}))*\}))*\})'),
    'closure_with_self': re.compile(r'\{.*?self\..*?\}', re.DOTALL),
    'core_data_save': re.compile(r'(\w+)\.save\(\)'),
    'core_data_fetch': re.compile(r'try\s+(\w+)\.fetch\('),
    'core_data_error': re.compile(r'try\s+\w+\.\w+\([^)]*\)(?!\s*catch)'),
    'async_call': re.compile(r'(?:async|await|Task|DispatchQueue)'),
    'mainactor': re.compile(r'@MainActor'),
    'task_run': re.compile(r'Task\s*\{'),
    'dispatch_main': re.compile(r'DispatchQueue\.main'),
}

@dataclass
class Issue:
    """Classe représentant un problème détecté dans le code"""
    file: str
    line: int
    type: str
    severity: str  # 'error', 'warning', 'info'
    message: str
    snippet: str = ''
    suggestion: str = ''

@dataclass
class FileInfo:
    """Informations sur un fichier Swift"""
    path: str
    imports: List[str] = field(default_factory=list)
    classes: List[str] = field(default_factory=list)
    protocols: List[str] = field(default_factory=list)
    structs: List[str] = field(default_factory=list)
    enums: List[str] = field(default_factory=list)
    extensions: List[str] = field(default_factory=list)
    issues: List[Issue] = field(default_factory=list)
    loc: int = 0

@dataclass
class AnalysisResult:
    """Résultat de l'analyse"""
    files_analyzed: int = 0
    total_issues: int = 0
    issues_by_type: Dict[str, int] = field(default_factory=dict)
    issues_by_severity: Dict[str, int] = field(default_factory=dict)
    issues: List[Issue] = field(default_factory=list)
    circular_dependencies: List[List[str]] = field(default_factory=list)
    file_infos: Dict[str, FileInfo] = field(default_factory=dict)
    execution_time: float = 0.0

def print_colored(text: str, color: str = RESET, bold: bool = False) -> None:
    """Imprime du texte coloré dans la console"""
    if bold:
        print(f"{GRAS}{color}{text}{RESET}")
    else:
        print(f"{color}{text}{RESET}")

def get_line_number(content: str, position: int) -> int:
    """Récupère le numéro de ligne correspondant à une position dans le texte"""
    return content[:position].count('\n') + 1

def get_snippet(content: str, position: int, window: int = 1) -> str:
    """Extrait un extrait de code autour d'une position"""
    lines = content.splitlines()
    line_no = get_line_number(content, position)
    
    start = max(0, line_no - window - 1)
    end = min(len(lines), line_no + window)
    
    snippet_lines = lines[start:end]
    return '\n'.join(snippet_lines)

def find_swift_files(root_dir: str) -> List[str]:
    """Trouve tous les fichiers Swift dans un répertoire"""
    swift_files = []
    root_path = Path(root_dir).resolve()
    
    print_colored(f"Recherche de fichiers Swift dans {root_path}...", BLEU)
    
    for path in root_path.rglob('*'):
        if path.is_file() and path.suffix in SWIFT_EXTENSIONS and path.name not in EXCLUDE_FILES:
            # Vérifier si le fichier est dans un répertoire exclu
            if not any(excluded in path.parts for excluded in EXCLUDE_DIRS):
                swift_files.append(str(path))
    
    print_colored(f"Trouvé {len(swift_files)} fichiers Swift à analyser.", VERT)
    return swift_files

def analyze_file(file_path: str) -> FileInfo:
    """Analyse un fichier Swift pour détecter des problèmes"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        file_info = FileInfo(path=file_path, loc=len(content.splitlines()))
        
        # Analyser les imports
        for match in PATTERNS['import'].finditer(content):
            file_info.imports.append(match.group(1))
        
        # Analyser les définitions
        for match in PATTERNS['class_def'].finditer(content):
            file_info.classes.append(match.group(1))
        
        for match in PATTERNS['protocol_def'].finditer(content):
            file_info.protocols.append(match.group(1))
        
        for match in PATTERNS['struct_def'].finditer(content):
            file_info.structs.append(match.group(1))
        
        for match in PATTERNS['enum_def'].finditer(content):
            file_info.enums.append(match.group(1))
        
        for match in PATTERNS['extension_def'].finditer(content):
            file_info.extensions.append(match.group(1))
        
        # Détecter les problèmes
        detect_memory_issues(file_path, content, file_info)
        detect_coredata_issues(file_path, content, file_info)
        detect_concurrency_issues(file_path, content, file_info)
        
        if VERBOSE:
            print_colored(f"Analysé: {file_path} - {len(file_info.issues)} problèmes trouvés", CYAN)
        
        return file_info
    
    except Exception as e:
        print_colored(f"Erreur lors de l'analyse de {file_path}: {str(e)}", ROUGE)
        return FileInfo(path=file_path, issues=[
            Issue(file=file_path, line=0, type='error', severity='error', 
                  message=f"Erreur d'analyse: {str(e)}")
        ])

def detect_memory_issues(file_path: str, content: str, file_info: FileInfo) -> None:
    """Détecte les problèmes potentiels de gestion mémoire"""
    # Chercher les closures qui utilisent self sans [weak self]
    closures_with_self = list(PATTERNS['closure_with_self'].finditer(content))
    
    for match in closures_with_self:
        closure_content = match.group(0)
        if 'self.' in closure_content and not PATTERNS['weak_self'].search(closure_content):
            position = match.start()
            line_no = get_line_number(content, position)
            snippet = get_snippet(content, position)
            
            # Vérifier si c'est dans un Task ou un DispatchQueue
            if any(pattern.search(closure_content) for pattern in 
                  [PATTERNS['task_run'], PATTERNS['dispatch_main']]):
                severity = 'error'
            else:
                severity = 'warning'
            
            issue = Issue(
                file=file_path,
                line=line_no,
                type='memory',
                severity=severity,
                message="Utilisation de 'self' sans capture faible [weak self] - risque de cycle de référence",
                snippet=snippet,
                suggestion="Ajoutez [weak self] au début de la closure et utilisez self? ou guard"
            )
            file_info.issues.append(issue)

def detect_coredata_issues(file_path: str, content: str, file_info: FileInfo) -> None:
    """Détecte les problèmes potentiels avec CoreData"""
    # Rechercher les appels à save() sans gestion d'erreur
    for match in PATTERNS['core_data_save'].finditer(content):
        context_var = match.group(1)
        position = match.start()
        line_no = get_line_number(content, position)
        
        # Vérifier si l'appel est entouré de try/catch
        line_start = content.rfind('\n', 0, position) + 1
        line_end = content.find('\n', position)
        line_content = content[line_start:line_end]
        
        if 'try' not in line_content or 'catch' not in content[position:position+200]:
            snippet = get_snippet(content, position)
            issue = Issue(
                file=file_path,
                line=line_no,
                type='coredata',
                severity='error',
                message=f"Appel à {context_var}.save() sans gestion d'erreur (try/catch)",
                snippet=snippet,
                suggestion="Entourez l'appel avec try/catch pour gérer les erreurs potentielles"
            )
            file_info.issues.append(issue)
    
    # Rechercher les appels à fetch sans batch size
    for match in PATTERNS['core_data_fetch'].finditer(content):
        position = match.start()
        context = content[position-100:position+100]
        
        if 'fetchBatchSize' not in context:
            line_no = get_line_number(content, position)
            snippet = get_snippet(content, position)
            issue = Issue(
                file=file_path,
                line=line_no,
                type='performance',
                severity='warning',
                message="Requête fetch sans fetchBatchSize - risque de performance",
                snippet=snippet,
                suggestion="Ajoutez fetchRequest.fetchBatchSize = 20 (ou une valeur appropriée)"
            )
            file_info.issues.append(issue)

def detect_concurrency_issues(file_path: str, content: str, file_info: FileInfo) -> None:
    """Détecte les problèmes potentiels de concurrence"""
    # Vérifier les méthodes asynchrones sans @MainActor pour des méthodes qui pourraient en avoir besoin
    lines = content.splitlines()
    
    for i, line in enumerate(lines):
        if PATTERNS['async_call'].search(line):
            # Vérifier si la méthode ou classe contenant cette ligne a @MainActor
            has_main_actor = False
            for j in range(max(0, i-10), i):
                if PATTERNS['mainactor'].search(lines[j]):
                    has_main_actor = True
                    break
            
            # Si on manipule l'UI mais sans @MainActor
            if (not has_main_actor and 
                ('UI' in line or 'view' in line.lower() or 'button' in line.lower() or 
                 'label' in line.lower() or 'update' in line.lower())):
                issue = Issue(
                    file=file_path,
                    line=i+1,
                    type='concurrency',
                    severity='warning',
                    message="Opération asynchrone potentiellement sur UI sans @MainActor",
                    snippet=get_snippet(content, content.find(line)),
                    suggestion="Ajoutez @MainActor à la méthode ou utilisez Task { @MainActor in ... }"
                )
                file_info.issues.append(issue)

def detect_circular_dependencies(file_infos: Dict[str, FileInfo]) -> List[List[str]]:
    """Détecte les dépendances circulaires entre les modules"""
    # Construire un graphe de dépendances
    dependency_graph = {}
    
    for file_path, info in file_infos.items():
        # Extraire le nom du module à partir du chemin
        module_parts = Path(file_path).parts
        if 'Core' in module_parts:
            module_idx = module_parts.index('Core')
            if module_idx + 1 < len(module_parts):
                module = f"Core.{module_parts[module_idx+1]}"
            else:
                module = 'Core'
        else:
            module = Path(file_path).stem
        
        if module not in dependency_graph:
            dependency_graph[module] = set()
        
        # Ajouter les dépendances
        for imported in info.imports:
            if imported != module:  # Éviter les auto-dépendances
                dependency_graph[module].add(imported)
    
    # Rechercher les cycles
    def find_cycles(node, path, visited):
        if node in path:
            # Cycle détecté
            cycle_start = path.index(node)
            return [path[cycle_start:] + [node]]
        if node in visited:
            return []
        
        visited.add(node)
        path.append(node)
        
        cycles = []
        if node in dependency_graph:
            for neighbor in dependency_graph[node]:
                cycles.extend(find_cycles(neighbor, path.copy(), visited))
        
        return cycles
    
    cycles = []
    visited = set()
    for node in dependency_graph:
        cycles.extend(find_cycles(node, [], visited))
    
    return cycles

def analyze_codebase(root_dir: str) -> AnalysisResult:
    """Analyse l'ensemble de la base de code Swift"""
    start_time = time.time()
    result = AnalysisResult()
    
    # Trouver tous les fichiers Swift
    swift_files = find_swift_files(root_dir)
    result.files_analyzed = len(swift_files)
    
    # Analyser les fichiers en parallèle
    print_colored(f"Analyse de {len(swift_files)} fichiers avec {MAX_WORKERS} workers...", MAGENTA, True)
    
    with concurrent.futures.ProcessPoolExecutor(max_workers=MAX_WORKERS) as executor:
        file_infos = list(executor.map(analyze_file, swift_files))
    
    # Collecter les résultats
    for file_info in file_infos:
        result.file_infos[file_info.path] = file_info
        result.issues.extend(file_info.issues)
    
    # Compter les problèmes par type et sévérité
    for issue in result.issues:
        result.issues_by_type[issue.type] = result.issues_by_type.get(issue.type, 0) + 1
        result.issues_by_severity[issue.severity] = result.issues_by_severity.get(issue.severity, 0) + 1
    
    result.total_issues = len(result.issues)
    
    # Détecter les dépendances circulaires
    result.circular_dependencies = detect_circular_dependencies(result.file_infos)
    
    # Calculer le temps d'exécution
    result.execution_time = time.time() - start_time
    
    return result

def create_md_report(result: AnalysisResult, output_file: str) -> None:
    """Crée un rapport au format Markdown"""
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(f"# Rapport d'Analyse Swift - CardApp\n\n")
        f.write(f"Date: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}\n\n")
        
        f.write(f"## Résumé\n\n")
        f.write(f"- **Fichiers analysés**: {result.files_analyzed}\n")
        f.write(f"- **Problèmes détectés**: {result.total_issues}\n")
        f.write(f"- **Temps d'exécution**: {result.execution_time:.2f} secondes\n\n")
        
        f.write(f"### Problèmes par type\n\n")
        for type_name, count in result.issues_by_type.items():
            f.write(f"- **{type_name}**: {count}\n")
        
        f.write(f"\n### Problèmes par sévérité\n\n")
        for severity, count in result.issues_by_severity.items():
            f.write(f"- **{severity}**: {count}\n")
        
        if result.circular_dependencies:
            f.write(f"\n## Dépendances Circulaires\n\n")
            for i, cycle in enumerate(result.circular_dependencies):
                f.write(f"### Cycle {i+1}\n\n")
                f.write(" → ".join(cycle) + "\n\n")
                f.write("Ce cycle crée un couplage fort entre les modules qui peut causer des problèmes de compilation, de chargement et de maintenance.\n\n")
        
        f.write(f"\n## Problèmes Détectés\n\n")
        
        # Trier par sévérité (error, warning, info)
        severity_order = {"error": 0, "warning": 1, "info": 2}
        sorted_issues = sorted(result.issues, key=lambda x: (severity_order.get(x.severity, 3), x.file, x.line))
        
        current_file = None
        for issue in sorted_issues:
            if current_file != issue.file:
                current_file = issue.file
                rel_path = os.path.relpath(current_file, start=os.getcwd())
                f.write(f"\n### {rel_path}\n\n")
            
            f.write(f"**[{issue.severity.upper()}] Ligne {issue.line}**: {issue.message}\n\n")
            
            if issue.snippet:
                f.write("```swift\n")
                f.write(issue.snippet)
                f.write("\n```\n\n")
            
            if issue.suggestion:
                f.write(f"**Suggestion**: {issue.suggestion}\n\n")
        
        f.write(f"\n## Recommandations\n\n")
        
        if result.issues_by_type.get('memory', 0) > 0:
            f.write("### Gestion Mémoire\n\n")
            f.write("1. Utilisez systématiquement `[weak self]` dans les closures qui capturent `self`\n")
            f.write("2. Préférez `guard let self = self else { return }` après la capture faible\n")
            f.write("3. Évitez les cycles de référence en utilisant des délégués faibles (`weak var delegate`)\n\n")
        
        if result.issues_by_type.get('coredata', 0) > 0 or result.issues_by_type.get('performance', 0) > 0:
            f.write("### CoreData\n\n")
            f.write("1. Toujours utiliser `try/catch` autour des opérations CoreData qui peuvent échouer\n")
            f.write("2. Définir `fetchBatchSize` pour toutes les requêtes (typiquement 20-50 éléments)\n")
            f.write("3. Utiliser `fetchLimit` lorsque vous avez besoin d'un nombre limité de résultats\n")
            f.write("4. Effectuer les opérations lourdes dans un contexte d'arrière-plan\n\n")
        
        if result.issues_by_type.get('concurrency', 0) > 0:
            f.write("### Concurrence\n\n")
            f.write("1. Utiliser `@MainActor` pour les classes/méthodes qui manipulent l'UI\n")
            f.write("2. Préférer `Task { @MainActor in ... }` pour les blocs individuels nécessitant l'UI\n")
            f.write("3. Éviter d'utiliser `DispatchQueue.main.async` dans le nouveau modèle de concurrence\n\n")
        
        if result.circular_dependencies:
            f.write("### Dépendances\n\n")
            f.write("1. Réorganiser l'architecture pour éliminer les dépendances circulaires\n")
            f.write("2. Utiliser des interfaces (protocols) pour inverser les dépendances\n")
            f.write("3. Considérer l'utilisation de modèles de conception comme l'injection de dépendances\n\n")

def main():
    """Fonction principale"""
    global VERBOSE
    
    parser = argparse.ArgumentParser(description="Analyseur de code Swift pour détecter les problèmes courants")
    parser.add_argument("--dir", type=str, default=".", help="Répertoire racine à analyser")
    parser.add_argument("--output", type=str, help="Fichier de sortie pour le rapport (JSON ou MD)")
    parser.add_argument("--output-format", type=str, choices=["json", "md"], default="md", help="Format du rapport (json ou md)")
    parser.add_argument("--verbose", action="store_true", help="Afficher des informations détaillées pendant l'analyse")
    
    args = parser.parse_args()
    VERBOSE = args.verbose
    
    print_colored("=" * 80, MAGENTA, True)
    print_colored("ANALYSEUR DE CODE SWIFT POUR CARDAPP", MAGENTA, True)
    print_colored("=" * 80, MAGENTA, True)
    print()
    
    # Analyser la base de code
    result = analyze_codebase(args.dir)
    
    # Afficher un résumé
    print()
    print_colored("=" * 80, CYAN)
    print_colored(f"RÉSUMÉ DE L'ANALYSE", CYAN, True)
    print_colored("=" * 80, CYAN)
    print()
    print_colored(f"Fichiers analysés: {result.files_analyzed}", RESET)
    print_colored(f"Problèmes détectés: {result.total_issues}", RESET)
    print_colored(f"Temps d'exécution: {result.execution_time:.2f} secondes", RESET)
    print()
    
    print_colored("Problèmes par type:", CYAN)
    for type_name, count in result.issues_by_type.items():
        print_colored(f"  {type_name}: {count}", RESET)
    
    print()
    print_colored("Problèmes par sévérité:", CYAN)
    for severity, count in result.issues_by_severity.items():
        color = ROUGE if severity == 'error' else JAUNE if severity == 'warning' else VERT
        print_colored(f"  {severity}: {count}", color)
    
    print()
    if result.circular_dependencies:
        print_colored(f"Dépendances circulaires: {len(result.circular_dependencies)}", ROUGE, True)
        for i, cycle in enumerate(result.circular_dependencies[:3]):  # Afficher max 3 cycles
            print_colored(f"  Cycle {i+1}: {' → '.join(cycle)}", ROUGE)
        if len(result.circular_dependencies) > 3:
            print_colored(f"  ... et {len(result.circular_dependencies) - 3} autres cycles", ROUGE)
    else:
        print_colored("Aucune dépendance circulaire détectée", VERT)
    
    # Générer le rapport
    if args.output:
        if args.output_format == 'json':
            # Convertir les dataclasses en dictionnaires pour JSON
            result_dict = {
                'files_analyzed': result.files_analyzed,
                'total_issues': result.total_issues,
                'issues_by_type': result.issues_by_type,
                'issues_by_severity': result.issues_by_severity,
                'circular_dependencies': result.circular_dependencies,
                'execution_time': result.execution_time,
                'issues': [asdict(issue) for issue in result.issues],
            }
            
            with open(args.output, 'w', encoding='utf-8') as f:
                json.dump(result_dict, f, indent=2)
            
            print_colored(f"\nRapport JSON généré: {args.output}", VERT)
        else:
            # Rapport Markdown
            md_output = args.output if args.output.endswith('.md') else f"{args.output}.md"
            create_md_report(result, md_output)
            print_colored(f"\nRapport Markdown généré: {md_output}", VERT)
    
    # Retourner un code de sortie non-zéro s'il y a des erreurs
    if result.issues_by_severity.get('error', 0) > 0:
        print_colored("\nDes erreurs ont été détectées. Consultez le rapport pour plus de détails.", ROUGE, True)
        return 1
    
    print_colored("\nAnalyse terminée.", VERT, True)
    return 0

if __name__ == "__main__":
    sys.exit(main()) 