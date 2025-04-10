#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Analyseur de code Swift pour CardApp
====================================

Cet outil analyse les fichiers Swift à la recherche de problèmes courants:
- Cycles de référence potentiels (absences de [weak self])
- Problèmes de concurrence dans les opérations asynchrones
- Problèmes de CoreData (requêtes sans gestion d'erreur)
- Dépendances circulaires entre composants

Usage:
    python3 swift_analyzer.py [chemin_du_projet]

Si aucun chemin n'est spécifié, le répertoire courant est utilisé.
"""

import os
import re
import sys
import glob
import json
import argparse
import concurrent.futures
from dataclasses import dataclass
from typing import List, Dict, Set, Tuple, Optional
from collections import defaultdict
import time

# Couleurs pour la sortie console
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

@dataclass
class Probleme:
    fichier: str
    ligne: int
    type: str
    severite: str  # 'critical', 'error', 'warning', 'info'
    message: str
    suggestion: str
    code: Optional[str] = None

@dataclass
class Fichier:
    chemin: str
    contenu: List[str]
    imports: Set[str] = None
    classes: List[str] = None
    structs: List[str] = None
    functions: List[str] = None

class SwiftAnalyzer:
    def __init__(self, chemin_projet):
        self.chemin_projet = os.path.abspath(chemin_projet)
        self.fichiers: List[Fichier] = []
        self.problemes: List[Probleme] = []
        self.dependances: Dict[str, Set[str]] = defaultdict(set)
        self.patterns = {
            'cycle_reference': re.compile(r'self\.([\w\.]+)\s*=\s*{.*?(?!\[weak\s+self\]).*?self', re.DOTALL),
            'async_call': re.compile(r'(Task|DispatchQueue)\.[\w\.]+\s*\{(?!.*\[weak\s+self\].*self).*?self', re.DOTALL),
            'core_data_fetch': re.compile(r'try\s+(?!.*catch).*?(fetch|execute|save)\('),
            'main_thread_access': re.compile(r'(?<!@MainActor).*?\.viewContext.*?'),
            'background_context': re.compile(r'newBackgroundContext\(\).*?\.perform'),
            'core_data_batch': re.compile(r'fetch\([^)]*\)(?!.*?fetchBatchSize)'),
            'core_data_predicate': re.compile(r'NSPredicate\(format:\s*"([^"]*)"'),
            'enum_raw_value': re.compile(r'enum\s+\w+\s*:(?!\s*String|\s*Int)'),
            'multiple_optionals': re.compile(r'if\s+let\s+\w+\s*=.*?,.*?let\s+\w+\s*='),
            'force_unwrap': re.compile(r'\w+!'),
        }
        
    def charger_fichiers(self):
        """Charge tous les fichiers Swift du projet."""
        print(f"{Colors.BLUE}Chargement des fichiers Swift...{Colors.ENDC}")
        fichiers_swift = glob.glob(f"{self.chemin_projet}/**/*.swift", recursive=True)
        
        # Filtrer les fichiers générés et les tests
        fichiers_swift = [f for f in fichiers_swift if not ('Generated' in f or 'Tests' in f)]
        
        print(f"{Colors.GREEN}Trouvé {len(fichiers_swift)} fichiers Swift à analyser.{Colors.ENDC}")
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count()) as executor:
            self.fichiers = list(executor.map(self._charger_fichier, fichiers_swift))
    
    def _charger_fichier(self, chemin: str) -> Fichier:
        """Charge un fichier Swift et extrait les informations de base."""
        with open(chemin, 'r', encoding='utf-8', errors='ignore') as f:
            contenu = f.read().splitlines()
        
        fichier = Fichier(chemin=chemin, contenu=contenu)
        
        # Extraire les imports
        fichier.imports = set(re.findall(r'import\s+(\w+)', '\n'.join(contenu)))
        
        # Extraire les classes, structs et fonctions
        fichier.classes = re.findall(r'class\s+(\w+)', '\n'.join(contenu))
        fichier.structs = re.findall(r'struct\s+(\w+)', '\n'.join(contenu))
        fichier.functions = re.findall(r'func\s+(\w+)', '\n'.join(contenu))
        
        # Construire le graphe de dépendances
        nom_fichier = os.path.basename(chemin).replace('.swift', '')
        
        for imp in fichier.imports:
            if imp not in ['Foundation', 'SwiftUI', 'Combine', 'CoreData', 'UIKit']:
                self.dependances[nom_fichier].add(imp)
        
        return fichier
    
    def analyser(self):
        """Analyse tous les fichiers chargés."""
        print(f"{Colors.BLUE}Démarrage de l'analyse...{Colors.ENDC}")
        
        debut = time.time()
        with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count()) as executor:
            resultats = list(executor.map(self._analyser_fichier, self.fichiers))
        
        # Combiner les problèmes de tous les fichiers
        for problemes_fichier in resultats:
            self.problemes.extend(problemes_fichier)
        
        # Détecter les dépendances circulaires
        self._detecter_dependances_circulaires()
        
        fin = time.time()
        print(f"{Colors.GREEN}Analyse terminée en {fin - debut:.2f} secondes.{Colors.ENDC}")
        print(f"{Colors.BOLD}Total des problèmes détectés: {len(self.problemes)}{Colors.ENDC}")
    
    def _analyser_fichier(self, fichier: Fichier) -> List[Probleme]:
        """Analyse un fichier à la recherche de problèmes."""
        problemes = []
        contenu_str = '\n'.join(fichier.contenu)
        
        # 1. Recherche des cycles de référence
        for match in self.patterns['cycle_reference'].finditer(contenu_str):
            ligne = contenu_str[:match.start()].count('\n') + 1
            problemes.append(Probleme(
                fichier=fichier.chemin,
                ligne=ligne,
                type='memory_leak',
                severite='error',
                message=f"Cycle de référence potentiel dans une closure avec '{match.group(1)}'",
                suggestion="Utilisez [weak self] dans la closure pour éviter un cycle de référence",
                code=f"self.{match.group(1)} = {{ [weak self] in\n    guard let self = self else { return }\n    // votre code ici\n}}"
            ))
        
        # 2. Recherche des problèmes de concurrence
        for match in self.patterns['async_call'].finditer(contenu_str):
            ligne = contenu_str[:match.start()].count('\n') + 1
            problemes.append(Probleme(
                fichier=fichier.chemin,
                ligne=ligne,
                type='concurrency',
                severite='warning',
                message="Utilisation de 'self' dans un bloc asynchrone sans [weak self]",
                suggestion="Utilisez [weak self] pour éviter les cycles de référence et les problèmes de concurrence",
                code="Task {\n    [weak self] in\n    guard let self = self else { return }\n    // votre code ici\n}"
            ))
        
        # 3. Recherche des problèmes CoreData
        for match in self.patterns['core_data_fetch'].finditer(contenu_str):
            ligne = contenu_str[:match.start()].count('\n') + 1
            problemes.append(Probleme(
                fichier=fichier.chemin,
                ligne=ligne,
                type='core_data',
                severite='critical',
                message=f"Opération CoreData 'try {match.group(1)}' sans bloc catch",
                suggestion="Entourez toujours les opérations CoreData avec try/catch pour gérer les erreurs",
                code=f"do {{\n    try context.{match.group(1)}()\n}} catch {{\n    print(\"Erreur CoreData: \\(error)\")\n}}"
            ))
        
        # 4. Vérifier l'accès au viewContext depuis le thread principal
        for match in self.patterns['main_thread_access'].finditer(contenu_str):
            ligne = contenu_str[:match.start()].count('\n') + 1
            problemes.append(Probleme(
                fichier=fichier.chemin,
                ligne=ligne,
                type='concurrency',
                severite='warning',
                message="Accès à viewContext sans annotation @MainActor",
                suggestion="Marquez la fonction avec @MainActor pour garantir l'exécution sur le thread principal",
                code="@MainActor\nfunc votreFonction() {\n    // accès à viewContext\n}"
            ))
        
        # 5. Vérifier l'utilisation optimale de fetchBatchSize
        for match in self.patterns['core_data_batch'].finditer(contenu_str):
            ligne = contenu_str[:match.start()].count('\n') + 1
            problemes.append(Probleme(
                fichier=fichier.chemin,
                ligne=ligne,
                type='performance',
                severite='info',
                message="Requête fetch sans fetchBatchSize défini",
                suggestion="Définissez fetchBatchSize pour les grandes collections pour améliorer les performances",
                code="let request = NSFetchRequest<Entity>(entityName: \"Entity\")\nrequest.fetchBatchSize = 20"
            ))
        
        # 6. Vérifier les NSPredicate pour les risques d'injection
        for match in self.patterns['core_data_predicate'].finditer(contenu_str):
            if '%@' not in match.group(1) and any(op in match.group(1) for op in ['=', 'LIKE', 'CONTAINS']):
                ligne = contenu_str[:match.start()].count('\n') + 1
                problemes.append(Probleme(
                    fichier=fichier.chemin,
                    ligne=ligne,
                    type='security',
                    severite='error',
                    message="NSPredicate avec format de chaîne littérale susceptible aux injections",
                    suggestion="Utilisez des placeholders %@ avec des arguments pour éviter les injections",
                    code="NSPredicate(format: \"name CONTAINS %@\", searchTerm)"
                ))
        
        # 7. Vérifier la présence de force unwrap (!)
        for match in self.patterns['force_unwrap'].finditer(contenu_str):
            ligne = contenu_str[:match.start()].count('\n') + 1
            problemes.append(Probleme(
                fichier=fichier.chemin,
                ligne=ligne,
                type='safety',
                severite='warning',
                message="Force unwrapping d'optionnel trouvé",
                suggestion="Utilisez 'if let', 'guard let' ou '??' pour un unwrapping sécurisé",
                code="if let value = optionalValue {\n    // utiliser value\n}"
            ))
        
        return problemes
    
    def _detecter_dependances_circulaires(self):
        """Détecte les dépendances circulaires entre les composants."""
        def dfs(node, visited, stack):
            visited[node] = True
            stack[node] = True
            
            for voisin in self.dependances.get(node, []):
                if voisin not in visited:
                    if dfs(voisin, visited, stack):
                        return True, [node, voisin]
                elif stack[voisin]:
                    return True, [node, voisin]
            
            stack[node] = False
            return False, []
        
        print(f"{Colors.BLUE}Recherche des dépendances circulaires...{Colors.ENDC}")
        
        visited = {node: False for node in self.dependances}
        stack = {node: False for node in self.dependances}
        
        for node in self.dependances:
            if not visited[node]:
                has_cycle, cycle_nodes = dfs(node, visited, stack)
                if has_cycle:
                    # Trouver un fichier qui contient le nœud en question
                    fichier_path = None
                    for fichier in self.fichiers:
                        if os.path.basename(fichier.chemin).replace('.swift', '') == cycle_nodes[0]:
                            fichier_path = fichier.chemin
                            break
                    
                    if fichier_path:
                        self.problemes.append(Probleme(
                            fichier=fichier_path,
                            ligne=1,  # Ligne générique
                            type='architecture',
                            severite='critical',
                            message=f"Dépendance circulaire détectée entre {cycle_nodes[0]} et {cycle_nodes[1]}",
                            suggestion="Utilisez le pattern d'injection de dépendance ou un protocole pour briser la dépendance circulaire",
                            code=f"// Solution: créer un protocole\nprotocol {cycle_nodes[1]}Protocol {{\n    // méthodes requises\n}}\n\n// Dans {cycle_nodes[0]}, utiliser le protocole au lieu de la classe concrète"
                        ))
    
    def generer_rapport(self):
        """Génère un rapport d'analyse formaté."""
        if not self.problemes:
            print(f"{Colors.GREEN}Aucun problème détecté!{Colors.ENDC}")
            return
        
        # Grouper les problèmes par fichier
        problemes_par_fichier = defaultdict(list)
        for probleme in self.problemes:
            problemes_par_fichier[probleme.fichier].append(probleme)
        
        # Grouper par sévérité pour les statistiques
        par_severite = defaultdict(int)
        par_type = defaultdict(int)
        
        for probleme in self.problemes:
            par_severite[probleme.severite] += 1
            par_type[probleme.type] += 1
        
        # Afficher les statistiques
        print(f"\n{Colors.BOLD}{Colors.HEADER}=== Rapport d'analyse de code Swift ==={Colors.ENDC}")
        print(f"{Colors.BOLD}Fichiers analysés: {len(self.fichiers)}{Colors.ENDC}")
        print(f"{Colors.BOLD}Problèmes détectés: {len(self.problemes)}{Colors.ENDC}\n")
        
        print(f"{Colors.BOLD}Répartition par sévérité:{Colors.ENDC}")
        for sev, count in sorted(par_severite.items(), key=lambda x: {'critical': 0, 'error': 1, 'warning': 2, 'info': 3}.get(x[0], 4)):
            color = {
                'critical': Colors.RED,
                'error': Colors.RED,
                'warning': Colors.WARNING,
                'info': Colors.BLUE
            }.get(sev, Colors.ENDC)
            print(f"  {color}{sev.capitalize()}: {count}{Colors.ENDC}")
        
        print(f"\n{Colors.BOLD}Répartition par type:{Colors.ENDC}")
        for typ, count in sorted(par_type.items(), key=lambda x: x[1], reverse=True):
            print(f"  {typ.replace('_', ' ').capitalize()}: {count}")
        
        # Afficher les problèmes critiques et les erreurs en premier
        print(f"\n{Colors.BOLD}{Colors.RED}=== Problèmes critiques et erreurs ==={Colors.ENDC}")
        critiques_errors = [p for p in self.problemes if p.severite in ['critical', 'error']]
        
        if not critiques_errors:
            print(f"{Colors.GREEN}Aucun problème critique ou erreur détecté.{Colors.ENDC}")
        else:
            for probleme in critiques_errors:
                fichier_rel = os.path.relpath(probleme.fichier, self.chemin_projet)
                print(f"{Colors.BOLD}{fichier_rel}:{probleme.ligne}{Colors.ENDC}")
                print(f"  {Colors.RED}{probleme.message}{Colors.ENDC}")
                print(f"  {Colors.BLUE}Suggestion: {probleme.suggestion}{Colors.ENDC}")
                if probleme.code:
                    print(f"  Code suggéré:")
                    print(f"  {Colors.CYAN}{probleme.code}{Colors.ENDC}")
                print()
        
        # Écrire le rapport JSON
        rapport = {
            "sommaire": {
                "fichiers_analyses": len(self.fichiers),
                "problemes_detectes": len(self.problemes),
                "par_severite": par_severite,
                "par_type": par_type
            },
            "problemes": [
                {
                    "fichier": os.path.relpath(p.fichier, self.chemin_projet),
                    "ligne": p.ligne,
                    "type": p.type,
                    "severite": p.severite,
                    "message": p.message,
                    "suggestion": p.suggestion,
                    "code": p.code
                }
                for p in self.problemes
            ]
        }
        
        os.makedirs("rapports_optimisation", exist_ok=True)
        timestamp = time.strftime("%Y-%m-%d_%H-%M-%S")
        with open(f"rapports_optimisation/swift_analyze_{timestamp}.json", 'w', encoding='utf-8') as f:
            json.dump(rapport, f, indent=2, ensure_ascii=False)
        
        print(f"{Colors.GREEN}Rapport complet enregistré dans 'rapports_optimisation/swift_analyze_{timestamp}.json'{Colors.ENDC}")
        
        # Générer aussi un rapport Markdown
        with open(f"rapports_optimisation/swift_analyze_{timestamp}.md", 'w', encoding='utf-8') as f:
            f.write(f"# Rapport d'analyse de code Swift pour CardApp\n\n")
            f.write(f"Date: {time.strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            f.write(f"## Résumé\n\n")
            f.write(f"- **Fichiers analysés**: {len(self.fichiers)}\n")
            f.write(f"- **Problèmes détectés**: {len(self.problemes)}\n\n")
            
            f.write(f"### Répartition par sévérité\n\n")
            for sev, count in sorted(par_severite.items(), key=lambda x: {'critical': 0, 'error': 1, 'warning': 2, 'info': 3}.get(x[0], 4)):
                f.write(f"- **{sev.capitalize()}**: {count}\n")
            
            f.write(f"\n### Répartition par type\n\n")
            for typ, count in sorted(par_type.items(), key=lambda x: x[1], reverse=True):
                f.write(f"- **{typ.replace('_', ' ').capitalize()}**: {count}\n")
            
            f.write(f"\n## Problèmes critiques et erreurs\n\n")
            if not critiques_errors:
                f.write(f"Aucun problème critique ou erreur détecté.\n")
            else:
                for probleme in critiques_errors:
                    fichier_rel = os.path.relpath(probleme.fichier, self.chemin_projet)
                    f.write(f"### {fichier_rel}:{probleme.ligne}\n\n")
                    f.write(f"**{probleme.message}**\n\n")
                    f.write(f"**Suggestion**: {probleme.suggestion}\n\n")
                    if probleme.code:
                        f.write(f"```swift\n{probleme.code}\n```\n\n")
            
            f.write(f"\n## Tous les problèmes\n\n")
            
            # Grouper par fichier pour le rapport Markdown
            for fichier, probs in problemes_par_fichier.items():
                fichier_rel = os.path.relpath(fichier, self.chemin_projet)
                f.write(f"### {fichier_rel}\n\n")
                
                for p in sorted(probs, key=lambda x: x.ligne):
                    sev_emoji = {
                        'critical': '🔴',
                        'error': '❌',
                        'warning': '⚠️',
                        'info': 'ℹ️'
                    }.get(p.severite, '')
                    
                    f.write(f"#### {sev_emoji} Ligne {p.ligne}: {p.message}\n\n")
                    f.write(f"- **Type**: {p.type.replace('_', ' ').capitalize()}\n")
                    f.write(f"- **Sévérité**: {p.severite.capitalize()}\n")
                    f.write(f"- **Suggestion**: {p.suggestion}\n\n")
                    
                    if p.code:
                        f.write(f"```swift\n{p.code}\n```\n\n")
        
        print(f"{Colors.GREEN}Rapport Markdown généré dans 'rapports_optimisation/swift_analyze_{timestamp}.md'{Colors.ENDC}")

def main():
    parser = argparse.ArgumentParser(description='Analyseur de code Swift pour détecter les problèmes courants')
    parser.add_argument('chemin', nargs='?', default=os.getcwd(),
                        help='Chemin du projet à analyser (par défaut: répertoire courant)')
    args = parser.parse_args()
    
    print(f"{Colors.BOLD}{Colors.HEADER}=== Analyseur de code Swift pour CardApp ==={Colors.ENDC}")
    print(f"{Colors.BLUE}Chemin du projet: {args.chemin}{Colors.ENDC}")
    
    analyzer = SwiftAnalyzer(args.chemin)
    analyzer.charger_fichiers()
    analyzer.analyser()
    analyzer.generer_rapport()

if __name__ == "__main__":
    main()
