# Outils de Diagnostic et d'Optimisation pour CardApp

Ce dossier contient une suite complète d'outils d'analyse, de diagnostic et d'optimisation pour le projet CardApp. Ces outils permettent d'identifier et de résoudre rapidement les problèmes de performance, de mémoire, de concurrence et de CoreData.

## Architecture des outils

Notre approche utilise une combinaison de technologies pour maximiser l'efficacité du diagnostic :

1. **Swift** : Analyse et optimisation spécifiques de CoreData
2. **Python** : Analyse statique rapide du code Swift
3. **Rust** : Analyse multi-thread haute performance pour les problèmes complexes
4. **Node.js** : Visualisation interactive des résultats d'analyse
5. **Bash** : Scripts d'orchestration pour exécuter les outils de manière coordonnée

## Structure des dossiers

```
CardApp/
├── analysis_tools/                   # Outils d'analyse principaux
│   ├── swift_analyzer.py             # Analyseur statique Python
│   ├── apply_fixes.sh                # Script de correction automatique
│   ├── rust_performance_analyzer/    # Analyseur multi-thread en Rust
│   │   ├── src/
│   │   │   ├── main.rs               # Point d'entrée
│   │   │   ├── analyzers.rs          # Logique d'analyse
│   │   │   ├── core_data_analyzer.rs # Analyseur spécifique CoreData
│   │   │   ├── models.rs             # Modèles de données
│   │   │   └── types.rs              # Types supplémentaires
│   │   └── Cargo.toml                # Configuration Rust
│   └── run_core_data_optimizer.swift # Diagnostic et optimisation CoreData
├── reports/                          # Rapports générés
├── power_debug.sh                    # Script d'orchestration principal
├── fast_debug.sh                     # Script de débogage rapide
├── run_core_data_optimizer.swift     # Optimiseur CoreData
└── analyze_unified_study.md          # Guide d'analyse spécifique
```

## Scripts principaux

### 1. power_debug.sh

Script d'orchestration principal qui exécute une analyse complète du projet en utilisant tous les outils disponibles.

```bash
./power_debug.sh [OPTIONS]
```

Options :
- `--fast` : Mode rapide, exécute uniquement les analyses essentielles
- `--unified-study` : Analyse spécifique des problèmes dans UnifiedStudyService
- `--help` : Affiche l'aide

Fonctionnalités :
- Vérification de l'environnement
- Préparation et compilation des outils
- Exécution de l'analyse statique Python
- Exécution de l'analyse de performance multi-thread Rust
- Diagnostic et optimisation CoreData
- Analyse spécifique d'UnifiedStudyService
- Application des corrections recommandées
- Génération d'un rapport visuel interactif

### 2. fast_debug.sh

Script de débogage rapide pour les corrections urgentes, se concentre sur les problèmes critiques les plus courants.

```bash
./fast_debug.sh
```

Fonctionnalités :
- Vérification des délégués sans `weak`
- Identification des closures sans `[weak self]`
- Vérification des NSFetchRequest sans fetchBatchSize
- Vérification des context.save() sans try/catch
- Analyse des problèmes dans UnifiedStudyService

### 3. run_core_data_optimizer.swift

Script Swift qui analyse en profondeur le modèle CoreData et génère des recommandations d'optimisation.

```bash
swift run_core_data_optimizer.swift
```

Fonctionnalités :
- Diagnostic du modèle CoreData
- Analyse des performances des requêtes
- Optimisations automatiques du modèle
- Génération d'un script de migration
- Analyse des problèmes courants dans les requêtes

## Analyseurs

### Analyseur Python (swift_analyzer.py)

Outil d'analyse statique qui détecte rapidement les problèmes courants :
- Cycles de référence manquants (`[weak self]`)
- Problèmes de concurrence
- Problèmes CoreData
- Dépendances circulaires

### Analyseur Rust (rust_performance_analyzer)

Outil d'analyse multi-thread haute performance qui se concentre sur :
- Complexité cyclomatique des fonctions
- Profondeur d'imbrication excessive
- Problèmes de concurrence avancés
- Opérations CoreData inefficaces
- Gestion de la mémoire

### Analyseur spécifique CoreData (core_data_analyzer.rs)

Module Rust spécialisé dans l'analyse des problèmes CoreData :
- Requêtes sans limite ou taille de lot
- Prédicats complexes sans index
- Opérations lourdes sur le thread principal
- Sauvegardes contextuelles fréquentes
- Opérations en boucle non optimisées
- Traversées de relations inefficaces

## Utilisation recommandée

1. Pour un diagnostic complet :
   ```bash
   ./power_debug.sh
   ```

2. Pour un débogage rapide :
   ```bash
   ./power_debug.sh --fast
   ```

3. Pour analyser spécifiquement UnifiedStudyService :
   ```bash
   ./power_debug.sh --unified-study
   ```

4. Pour optimiser CoreData uniquement :
   ```bash
   swift run_core_data_optimizer.swift
   ```

## Rapports générés

Tous les rapports sont enregistrés dans le dossier `reports/` avec un horodatage pour faciliter le suivi :

- `python_analysis_YYYYMMDD_HHMMSS.txt` : Résultats de l'analyse Python
- `rust_analysis_YYYYMMDD_HHMMSS.json` : Résultats détaillés de l'analyse Rust
- `coredata_diagnostic_YYYYMMDD_HHMMSS.txt` : Diagnostics et recommandations CoreData
- `unified_study_service_analysis_YYYYMMDD_HHMMSS.txt` : Analyse spécifique
- `visual_report_YYYYMMDD_HHMMSS.html` : Rapport visuel interactif
- `power_debug_YYYYMMDD_HHMMSS.log` : Journal complet de l'exécution

## Maintenance des outils

Ces outils sont conçus pour évoluer avec le projet. Si vous ajoutez de nouvelles fonctionnalités ou modifiez l'architecture, pensez à mettre à jour les analyseurs pour maintenir leur efficacité.

### Mise à jour de l'analyseur Rust :

```bash
cd analysis_tools/rust_performance_analyzer
cargo build --release
```

### Mise à jour des dépendances Python :

```bash
pip3 install -r requirements.txt
```

## Crédits

Ces outils ont été développés par l'équipe CardApp pour accélérer le débogage et l'optimisation du projet.

## Contact

Pour toute question concernant ces outils, contactez l'équipe de développement CardApp. 