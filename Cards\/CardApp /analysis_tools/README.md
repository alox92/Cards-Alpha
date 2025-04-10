# Outils d'Analyse et de Correction pour CardApp

> Date: Mai 2025

Ce répertoire contient une suite d'outils complets pour analyser, diagnostiquer et corriger les problèmes dans le projet CardApp. Les outils sont conçus pour être utilisés ensemble ou séparément selon les besoins.

## Vue d'ensemble

Les outils sont organisés en plusieurs catégories :

1. **Outils d'analyse** - Détection des problèmes
2. **Outils de correction** - Résolution automatique des problèmes
3. **Outils de documentation** - Génération de rapports et guides
4. **Outils d'orchestration** - Exécution coordonnée de plusieurs outils

## Installation

La plupart des scripts sont écrits en Bash et sont prêts à être exécutés. Pour les outils plus avancés, des dépendances supplémentaires peuvent être nécessaires.

```bash
# Rendre tous les scripts exécutables
chmod +x *.sh

# Installation des dépendances Python (si nécessaire)
pip3 install -r python_static_analyzer/requirements.txt

# Installation des dépendances Rust (si disponible)
cd rust_performance_analyzer && cargo build --release && cd ..

# Installation des dépendances Node.js (si disponible)
cd node_visualizer && npm install && cd ..
```

## Outils Principaux

### Analyse et diagnostic

| Script | Description |
|--------|-------------|
| `verify_imports.sh` | Vérifie les problèmes d'imports et les références non qualifiées |
| `analyze_coredata_types.sh` | Analyse les types et références dans le contexte CoreData |
| `python_static_analyzer/swift_analyzer.py` | Analyse statique complète du code Swift |
| `rust_performance_analyzer` | Analyse multi-thread des problèmes de performance |

### Correction automatique

| Script | Description |
|--------|-------------|
| `fix_module_imports.sh` | Corrige les imports problématiques |
| `fix_coredata_models.sh` | Unifie les modèles CoreData en un seul modèle |
| `fix_ambiguous_types.sh` | Résout les ambiguïtés de types |
| `fix_unified_study_service.sh` | Corrige les problèmes dans UnifiedStudyService |
| `fix_syntax_errors.sh` | Corrige les erreurs de syntaxe |
| `optimize_coredata_performance.sh` | Optimise les requêtes CoreData et ajoute des index |

### Orchestration et rapport

| Script | Description |
|--------|-------------|
| `power_debug.sh` | Script principal qui coordonne tous les outils |
| `node_visualizer` | Interface web pour visualiser les résultats d'analyse |

## Guide d'utilisation rapide

### 1. Analyse complète

Pour une analyse complète du projet avec un rapport détaillé :

```bash
./power_debug.sh
```

Ce script interactif vous guidera à travers l'analyse et proposera des corrections automatiques.

### 2. Corrections spécifiques

Si vous connaissez déjà le problème que vous souhaitez corriger :

```bash
# Problèmes d'imports
./fix_module_imports.sh

# Problèmes de modèle CoreData
./fix_coredata_models.sh

# Problèmes d'ambiguïté de types
./fix_ambiguous_types.sh

# Problèmes de performance CoreData
./optimize_coredata_performance.sh
```

### 3. Analyse avancée (avec dépendances supplémentaires)

Pour une analyse plus approfondie avec les outils spécialisés :

```bash
# Analyse Python
python3 python_static_analyzer/swift_analyzer.py -p .. -o reports/python_analysis.json

# Analyse Rust (si disponible)
cd rust_performance_analyzer && cargo run --release -- --path ../../ --output json

# Visualisation (si Node.js est disponible)
cd node_visualizer && node src/cli.js --reports ../../reports/
```

## Bonnes pratiques

1. **Toujours créer une sauvegarde** avant d'exécuter les scripts de correction automatique.
2. **Vérifier la compilation** du projet après chaque correction.
3. **Examiner les rapports** générés pour comprendre les problèmes et les corrections.
4. **Commencer par `power_debug.sh`** pour une évaluation initiale avant d'utiliser des outils spécifiques.

## Dossiers et fichiers générés

- `reports/` - Rapports d'analyse au format JSON, Markdown et HTML
- `backups_*` - Sauvegardes des fichiers avant modifications
- `docs/` - Documentation et guides générés

## Résolution de problèmes

Si vous rencontrez des problèmes avec les outils :

1. Vérifiez que tous les scripts sont exécutables (`chmod +x *.sh`)
2. Assurez-vous que les dépendances nécessaires sont installées
3. Consultez les logs générés dans `logs/` pour plus de détails
4. Pour les erreurs spécifiques, référez-vous à la documentation individuelle de chaque outil

## Développement et extension

Ces outils sont conçus pour être facilement extensibles. Pour ajouter de nouvelles fonctionnalités :

1. Suivez les conventions de nommage et de structure existantes
2. Documentez clairement les nouvelles fonctionnalités
3. Assurez-vous que les nouveaux outils créent des sauvegardes avant de modifier des fichiers
4. Intégrez les nouveaux outils dans le script principal `power_debug.sh`

## Licence

Ces outils sont développés pour un usage interne dans le projet CardApp et ne sont pas destinés à être distribués.

## Contact

Pour toute question ou suggestion d'amélioration de ces outils, contactez l'équipe de développement CardApp. 