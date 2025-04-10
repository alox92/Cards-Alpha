# Outils d'Analyse et d'Optimisation de Performance

Ce répertoire contient une suite d'outils pour analyser et corriger les problèmes de performance dans le projet CardApp.

## Aperçu des Outils

Les outils d'analyse et de correction de performance sont organisés comme suit :

1. **Analyse de Performance** - Détection des problèmes de performance, mémoire et concurrence
2. **Correction des Fuites Mémoire** - Correction automatique des cycles de référence et autres fuites
3. **Optimisation CoreData** - Amélioration des performances des requêtes et des contextes CoreData
4. **Script d'Orchestration** - Exécution séquentielle de tous les outils avec interface interactive

## Outils Disponibles

### 1. Analyse de Performance

#### `performance_analyzer.sh`

Script principal d'analyse qui combine plusieurs techniques pour détecter les problèmes de performance.

```bash
./analysis_tools/performance_analyzer.sh
```

Fonctionnalités:
- Analyse des fuites mémoire potentielles
- Détection des requêtes CoreData non optimisées
- Identification des opérations inappropriées sur le thread principal
- Génération de rapports détaillés au format HTML et Markdown

### 2. Correction des Fuites Mémoire

#### `fix_memory_leaks.sh`

Corrige automatiquement les cycles de référence dans les closures.

```bash
./analysis_tools/fix_memory_leaks.sh
```

Corrections appliquées:
- Ajout de `[weak self]` dans les closures (`Task`, `DispatchQueue`, etc.)
- Conversion des délégués en références faibles (`weak var delegate`)
- Suppression des captures fortes inutiles

### 3. Optimisation CoreData

#### `fix_coredata_perf.sh`

Optimise l'utilisation de CoreData pour de meilleures performances.

```bash
./analysis_tools/fix_coredata_perf.sh
```

Optimisations appliquées:
- Ajout de `fetchBatchSize` aux requêtes CoreData
- Ajout de `@MainActor` aux méthodes utilisant `viewContext`
- Conversion des opérations lourdes vers des contextes d'arrière-plan
- Amélioration de la gestion d'erreurs avec `try-catch`

### 4. Script d'Orchestration

#### `fix_all_performance.sh`

Script interactif qui guide l'utilisateur à travers le processus complet d'analyse et de correction.

```bash
./analysis_tools/fix_all_performance.sh
```

Options:
- `--auto` : Mode automatique sans interaction
- `--verbose` : Mode verbeux avec plus de détails
- `--yes` : Répond oui à toutes les confirmations
- `--help` : Affiche l'aide

## Utilisation Recommandée

Pour une optimisation complète de votre projet, nous recommandons la séquence suivante:

1. **Analyse préliminaire**:
   ```bash
   ./analysis_tools/performance_analyzer.sh
   ```
   Consultez les rapports générés dans `reports/` pour comprendre les problèmes détectés.

2. **Correction des problèmes de mémoire**:
   ```bash
   ./analysis_tools/fix_memory_leaks.sh
   ```
   Résout les cycles de référence et autres fuites mémoire.

3. **Optimisation de CoreData**:
   ```bash
   ./analysis_tools/fix_coredata_perf.sh
   ```
   Améliore les performances des requêtes et contextes CoreData.

4. **Vérification de la compilation**:
   Compilez le projet pour vous assurer que les corrections n'ont pas introduit d'erreurs.

5. **Documentation des changements**:
   Consultez les rapports générés et documentez les changements effectués.

## Structure des Rapports

Les rapports sont générés dans le répertoire `reports/` avec la structure suivante:

```
reports/
├── performance_TIMESTAMP/
│   ├── performance_analysis.log   # Journal détaillé de l'analyse
│   ├── summary.md                 # Résumé des problèmes détectés
│   ├── memory_leaks.txt           # Liste des fuites mémoire potentielles
│   ├── fetch_without_batchsize.txt # Requêtes sans fetchBatchSize
│   ├── main_thread_fetches.txt    # Opérations sur le thread principal
│   └── rapport_performance.html   # Rapport visuel interactif
└── ...
```

Les sauvegardes des fichiers modifiés sont stockées dans des répertoires nommés selon le pattern `backups_*_TIMESTAMP/`.

## Limitations et Avertissements

- Ces scripts appliquent des corrections génériques qui peuvent ne pas être adaptées à tous les contextes
- Certaines corrections complexes peuvent nécessiter une intervention manuelle
- Il est recommandé de compiler et tester l'application après chaque étape de correction
- Utilisez toujours une version sous contrôle de version (git) avant d'appliquer des corrections automatiques

## Développement et Extension

Ces outils sont conçus pour être extensibles. Vous pouvez ajouter vos propres règles d'analyse et de correction en modifiant les scripts existants.

### Ajout de Nouvelles Règles d'Analyse

Modifiez `performance_analyzer.sh` pour ajouter de nouvelles règles d'analyse. Par exemple, pour détecter un nouveau pattern problématique:

```bash
# Analyse d'un nouveau pattern
grep -n "nouveau_pattern" --include="*.swift" -r . \
   > "${REPORT_DIR}/nouveau_pattern.txt"
```

### Ajout de Nouvelles Règles de Correction

Ajoutez de nouvelles fonctions dans les scripts de correction pour traiter des cas spécifiques. Par exemple, dans `fix_memory_leaks.sh`:

```bash
# Nouvelle fonction de correction
fix_nouveau_probleme() {
    log "\n${BOLD}🔍 Analyse du nouveau problème...${NC}" "$BLUE"
    # Logique de détection et correction
}

# Ajouter l'appel à la fonction principale
main() {
    # ...
    fix_nouveau_probleme
    # ...
}
```

## Aide et Support

Pour obtenir de l'aide sur l'utilisation de ces outils, consultez la documentation complète dans `docs/RAPPORT_PERFORMANCE.md` ou exécutez:

```bash
./analysis_tools/fix_all_performance.sh --help
```

## Crédits

Ces outils ont été développés par l'équipe d'optimisation de performance de CardApp en Mai 2025. 