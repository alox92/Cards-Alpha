#!/bin/bash

# Couleurs pour la sortie
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}     INSTALLATION DES OUTILS POUR CARDAPP      ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Créer les répertoires nécessaires
echo -e "${YELLOW}Création des répertoires...${NC}"
mkdir -p analysis_tools/python_static_analyzer
mkdir -p analysis_tools/rust_performance_analyzer
mkdir -p analysis_tools/node_visualizer
mkdir -p docs
mkdir -p reports
mkdir -p logs

echo -e "${GREEN}✓ Répertoires créés${NC}"

# Rendre les scripts exécutables
echo -e "${YELLOW}Configuration des permissions...${NC}"
find analysis_tools -name "*.sh" -exec chmod +x {} \;
chmod +x *.sh
echo -e "${GREEN}✓ Scripts rendus exécutables${NC}"

# Vérification de Python
echo -e "${YELLOW}Vérification de Python...${NC}"
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✓ Python 3 est installé${NC}"
    
    # Création du fichier requirements.txt
    echo -e "${YELLOW}Création des dépendances Python...${NC}"
    cat > analysis_tools/python_static_analyzer/requirements.txt << EOF
regex==2023.8.8
colorama==0.4.6
jinja2==3.1.2
dataclasses==0.6
typing-extensions==4.7.1
EOF
    
    # Installation des dépendances Python
    echo -e "${YELLOW}Installation des dépendances Python...${NC}"
    pip3 install -r analysis_tools/python_static_analyzer/requirements.txt
    echo -e "${GREEN}✓ Dépendances Python installées${NC}"
else
    echo -e "${RED}✗ Python 3 n'est pas installé${NC}"
    echo -e "${YELLOW}Certaines fonctionnalités d'analyse ne seront pas disponibles${NC}"
fi

# Vérification de Node.js
echo -e "${YELLOW}Vérification de Node.js...${NC}"
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓ Node.js est installé${NC}"
    
    # Création du package.json
    echo -e "${YELLOW}Création des dépendances Node.js...${NC}"
    cat > analysis_tools/node_visualizer/package.json << EOF
{
  "name": "cardapp-analysis-visualizer",
  "version": "1.0.0",
  "description": "Visualiseur interactif pour les résultats d'analyse du projet CardApp",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js"
  },
  "dependencies": {
    "chalk": "^4.1.2",
    "commander": "^9.4.0",
    "express": "^4.18.1",
    "ejs": "^3.1.8",
    "fs-extra": "^10.1.0",
    "highlight.js": "^11.6.0"
  }
}
EOF
    
    # Création du répertoire src et fichier index.js minimaliste
    mkdir -p analysis_tools/node_visualizer/src
    cat > analysis_tools/node_visualizer/src/index.js << EOF
console.log('Visualiseur d\'analyse CardApp');
console.log('Pour utiliser cet outil, exécutez:');
console.log('node src/index.js --help');
EOF
    
    # Installation des dépendances Node.js
    echo -e "${YELLOW}Installation des dépendances Node.js...${NC}"
    (cd analysis_tools/node_visualizer && npm install)
    echo -e "${GREEN}✓ Dépendances Node.js installées${NC}"
else
    echo -e "${RED}✗ Node.js n'est pas installé${NC}"
    echo -e "${YELLOW}Les fonctionnalités de visualisation avancée ne seront pas disponibles${NC}"
fi

# Vérification de Rust
echo -e "${YELLOW}Vérification de Rust...${NC}"
if command -v cargo &> /dev/null; then
    echo -e "${GREEN}✓ Rust est installé${NC}"
    
    # Création du Cargo.toml
    echo -e "${YELLOW}Création des dépendances Rust...${NC}"
    cat > analysis_tools/rust_performance_analyzer/Cargo.toml << EOF
[package]
name = "swift_performance_analyzer"
version = "0.1.0"
edition = "2021"

[dependencies]
rayon = "1.8.0"
walkdir = "2.4.0"
regex = "1.9.5"
serde = { version = "1.0.188", features = ["derive"] }
serde_json = "1.0.107"
clap = { version = "4.4.6", features = ["derive"] }
EOF
    
    # Création de la structure src et un fichier main.rs minimaliste
    mkdir -p analysis_tools/rust_performance_analyzer/src
    cat > analysis_tools/rust_performance_analyzer/src/main.rs << EOF
fn main() {
    println!("Analyseur de performance Swift pour CardApp");
    println!("Pour compiler et utiliser cet outil:");
    println!("cd analysis_tools/rust_performance_analyzer && cargo build --release");
}
EOF
    
    # Compilation du projet Rust
    echo -e "${YELLOW}Compilation du projet Rust...${NC}"
    (cd analysis_tools/rust_performance_analyzer && cargo check)
    echo -e "${GREEN}✓ Configuration Rust terminée${NC}"
else
    echo -e "${RED}✗ Rust n'est pas installé${NC}"
    echo -e "${YELLOW}Les fonctionnalités d'analyse de performance avancée ne seront pas disponibles${NC}"
fi

# Création d'un script Python d'analyse minimaliste
echo -e "${YELLOW}Création d'un script Python d'analyse minimaliste...${NC}"
cat > analysis_tools/python_static_analyzer/swift_analyzer.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import re
import json
import argparse
from typing import List, Dict, Any, Optional, Tuple

class Issue:
    def __init__(self, file: str, line: int, issue_type: str, 
                 description: str, severity: str, fix_suggestion: Optional[str] = None):
        self.file = file
        self.line = line
        self.issue_type = issue_type
        self.description = description
        self.severity = severity
        self.fix_suggestion = fix_suggestion
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "file": self.file,
            "line": self.line,
            "issue_type": self.issue_type,
            "description": self.description,
            "severity": self.severity,
            "fix_suggestion": self.fix_suggestion
        }

class SwiftAnalyzer:
    def __init__(self, project_path: str, output_file: str):
        self.project_path = project_path
        self.output_file = output_file
        self.issues = []
    
    def find_swift_files(self) -> List[str]:
        swift_files = []
        for root, _, files in os.walk(self.project_path):
            for file in files:
                if file.endswith(".swift"):
                    swift_files.append(os.path.join(root, file))
        return swift_files
    
    def analyze_file(self, file_path: str) -> List[Issue]:
        file_issues = []
        
        # Lire le contenu du fichier
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Vérifier les problèmes de mémoire
        file_issues.extend(self.analyze_memory_issues(content, file_path))
        
        # Vérifier les problèmes de concurrence
        file_issues.extend(self.analyze_concurrency_issues(content, file_path))
            
        return file_issues
    
    def analyze_memory_issues(self, content: str, file_path: str) -> List[Issue]:
        issues = []
        
        # Rechercher des closures sans [weak self]
        pattern = r'Task\s*{[^{]*?self\.'
        for match in re.finditer(pattern, content):
            line = content[:match.start()].count('\n') + 1
            if '[weak self]' not in match.group(0):
                issues.append(Issue(
                    file=file_path,
                    line=line,
                    issue_type="memory_leak",
                    description="Cycle de référence potentiel: closure capturant 'self' sans [weak self]",
                    severity="high",
                    fix_suggestion="Utilisez [weak self] et vérifiez si self est nil"
                ))
        
        return issues
    
    def analyze_concurrency_issues(self, content: str, file_path: str) -> List[Issue]:
        issues = []
        
        # Rechercher l'utilisation de viewContext sans @MainActor
        if 'viewContext' in content and '@MainActor' not in content:
            line = content.find('viewContext')
            line = content[:line].count('\n') + 1
            issues.append(Issue(
                file=file_path,
                line=line,
                issue_type="concurrency_violation",
                description="Utilisation de viewContext sans annotation @MainActor",
                severity="high",
                fix_suggestion="Ajoutez @MainActor à la classe ou méthode utilisant viewContext"
            ))
        
        return issues
    
    def run_analysis(self) -> Dict[str, Any]:
        swift_files = self.find_swift_files()
        print(f"Analyse de {len(swift_files)} fichiers Swift...")
        
        for file_path in swift_files:
            file_issues = self.analyze_file(file_path)
            self.issues.extend(file_issues)
        
        result = {
            "total_files_analyzed": len(swift_files),
            "total_issues": len(self.issues),
            "issues": [issue.to_dict() for issue in self.issues]
        }
        
        # Écrire le résultat dans un fichier JSON
        if self.output_file:
            with open(self.output_file, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2)
            print(f"Rapport d'analyse enregistré dans {self.output_file}")
        
        return result

def main():
    parser = argparse.ArgumentParser(description='Analyseur statique Swift pour CardApp')
    parser.add_argument('-p', '--project', required=True, help='Chemin vers le projet Swift')
    parser.add_argument('-o', '--output', help='Fichier de sortie pour le rapport JSON')
    
    args = parser.parse_args()
    
    analyzer = SwiftAnalyzer(args.project, args.output)
    results = analyzer.run_analysis()
    
    print(f"Analyse terminée. {results['total_issues']} problèmes détectés.")

if __name__ == "__main__":
    main()
EOF

echo -e "${GREEN}✓ Script Python d'analyse créé${NC}"

# Création du README principal
echo -e "${YELLOW}Création du README principal...${NC}"
cat > README.md << 'EOF'
# CardApp - Outils d'Analyse et de Correction

Ce dépôt contient une suite d'outils pour analyser, diagnostiquer et corriger les problèmes dans le projet CardApp.

## Démarrage Rapide

```bash
# Installer et configurer les outils
./setup_tools.sh

# Exécuter l'analyse globale
./analysis_tools/power_debug.sh
```

## Structure du projet

- `analysis_tools/` - Scripts et outils d'analyse
  - `python_static_analyzer/` - Analyseur statique en Python
  - `rust_performance_analyzer/` - Analyseur de performance en Rust
  - `node_visualizer/` - Visualiseur de résultats en Node.js
- `docs/` - Documentation et guides
- `reports/` - Rapports d'analyse générés
- `logs/` - Journaux d'exécution

## Documentation

Consultez les documents suivants pour plus d'informations :

- [Guide d'utilisation des outils](analysis_tools/README.md)
- [Rapport final des correctifs](docs/RAPPORT_FINAL.md)
- [Guide des optimisations CoreData](docs/OPTIMISATIONS_COREDATA.md)

## Outils Principaux

- `power_debug.sh` - Analyse globale et corrections automatiques
- `compare_performance.sh` - Mesure les améliorations de performance
- `optimize_coredata_performance.sh` - Optimise les requêtes CoreData
- `fix_unified_study_service.sh` - Corrige les problèmes dans UnifiedStudyService
EOF

echo -e "${GREEN}✓ README principal créé${NC}"

echo -e "${BLUE}===============================================${NC}"
echo -e "${GREEN}Installation des outils terminée avec succès !${NC}"
echo -e "${BLUE}===============================================${NC}"
echo -e "${YELLOW}Pour commencer, exécutez:${NC}"
echo -e "${BLUE}./analysis_tools/power_debug.sh${NC}" 