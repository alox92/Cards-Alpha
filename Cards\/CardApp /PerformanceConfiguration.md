# Configuration des Tests de Performance dans le Pipeline CI/CD

Ce document détaille la configuration nécessaire pour intégrer les tests de performance de Cards App dans un pipeline d'intégration continue, afin de détecter automatiquement les régressions de performance sur macOS.

## Objectifs

- Exécuter automatiquement les tests de performance à chaque pull request
- Comparer les résultats aux références (baselines) établies
- Alerter l'équipe en cas de régression significative
- Générer des rapports de performance pour analyse

## Configuration du Pipeline

### 1. GitHub Actions (exemple)

Créez un fichier `.github/workflows/performance-tests.yml` avec le contenu suivant :

```yaml
name: Performance Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  # Exécution programmée hebdomadaire
  schedule:
    - cron: '0 2 * * 1'  # Tous les lundis à 2h du matin

jobs:
  performance-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable
          
      - name: Install dependencies
        run: |
          xcodebuild -resolvePackageDependencies
          
      - name: Build for testing
        run: |
          xcodebuild build-for-testing -scheme CardApp -destination 'platform=macOS'
          
      - name: Run performance tests
        run: |
          xcodebuild test -scheme CardApp -destination 'platform=macOS' -only-testing:CardAppTests/MacOSLargeCollectionTests -only-testing:CardAppTests/MemoryLeakTests
          
      - name: Process test results
        run: |
          # Script pour extraire et formater les résultats des tests de performance
          ./Scripts/process-performance-results.sh
          
      - name: Check for regressions
        run: |
          # Script pour comparer les résultats aux références
          ./Scripts/check-performance-regressions.sh
          
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: performance-test-results
          path: PerformanceReports/
```

### 2. Scripts Nécessaires

#### `Scripts/process-performance-results.sh`

```bash
#!/bin/bash
# Script pour traiter les résultats des tests de performance

# Créer le répertoire pour les rapports
mkdir -p PerformanceReports

# Extraire les résultats des tests de performance depuis les logs Xcode
xcrun xcresulttool get --path TestResults.xcresult --format json > PerformanceReports/raw_results.json

# Traiter les résultats pour extraire les métriques de performance
cat PerformanceReports/raw_results.json | jq '.metrics.tests[] | select(.name | contains("Performance"))' > PerformanceReports/performance_metrics.json

# Générer un rapport HTML
echo "<html><head><title>Performance Test Results</title></head><body>" > PerformanceReports/index.html
echo "<h1>Performance Test Results</h1>" >> PerformanceReports/index.html
echo "<table border='1'><tr><th>Test</th><th>Average</th><th>Baseline</th><th>Diff %</th></tr>" >> PerformanceReports/index.html

# Ajouter les résultats au rapport HTML (simplifiée pour l'exemple)
cat PerformanceReports/performance_metrics.json | jq -r '.name + "," + (.average | tostring) + "," + (.baseline | tostring)' | while IFS=, read -r name avg base; do
  diff=$(echo "scale=2; ($avg - $base) / $base * 100" | bc)
  echo "<tr><td>$name</td><td>$avg</td><td>$base</td><td>$diff%</td></tr>" >> PerformanceReports/index.html
done

echo "</table></body></html>" >> PerformanceReports/index.html

echo "Performance report generated at PerformanceReports/index.html"
```

#### `Scripts/check-performance-regressions.sh`

```bash
#!/bin/bash
# Script pour vérifier les régressions de performance

# Seuil de régression (en pourcentage)
THRESHOLD=10

# Vérifier les régressions
REGRESSIONS=$(cat PerformanceReports/performance_metrics.json | jq -r 'select(.average > .baseline * (1 + '$THRESHOLD'/100)) | .name')

if [ -n "$REGRESSIONS" ]; then
  echo "⚠️ Performance regressions detected:"
  echo "$REGRESSIONS"
  
  # Envoyer une notification Slack (exemple)
  if [ -n "$SLACK_WEBHOOK" ]; then
    curl -X POST -H 'Content-type: application/json' --data '{
      "text": "⚠️ Performance regression detected in Cards App!\n'"$REGRESSIONS"'"
    }' $SLACK_WEBHOOK
  fi
  
  # En option: faire échouer le build si des régressions sont détectées
  # exit 1
else
  echo "✅ No performance regressions detected"
fi
```

## 3. Baselines de Performance

Pour établir des baselines de performance:

1. Exécutez manuellement les tests de performance sur un environnement de référence:

```bash
xcodebuild test -scheme CardApp -destination 'platform=macOS' -only-testing:CardAppTests/MacOSLargeCollectionTests
```

2. Exportez les métriques de base:

```bash
xcrun xcresulttool get --path TestResults.xcresult --format json > performance_baselines.json
```

3. Mettez à jour le fichier de configuration des tests:

```swift
// Dans MacOSLargeCollectionTests.swift
class MacOSLargeCollectionTests: XCTestCase {
    // ...
    
    // Définir les baselines de performance
    override class var defaultPerformanceMetrics: [XCTPerformanceMetric] {
        return [.wallClockTime]
    }
    
    override class var defaultPerformanceMetricsReportingFrequency: Int {
        return 5
    }
    
    // Configurer les attentes de performance
    override func measure(metrics: [XCTMetric] = defaultPerformanceMetrics, 
                        options: XCTMeasureOptions = defaultMeasureOptions, 
                        block: () -> Void) {
        options.iterationCount = 10
        super.measure(metrics: metrics, options: options, block: block)
    }
    // ...
}
```

## 4. Mesures Spécifiques à macOS

Pour les tests sur macOS, ajoutez ces métriques supplémentaires:

```swift
// Métriques spécifiques à macOS
let macOSMetrics: [XCTMetric] = [
    XCTMemoryMetric(),
    XCTStorageMetric(),
    XCTCPUMetric()
]

func testLargeCollectionScrollingPerformance() throws {
    // Utiliser des métriques spécifiques à macOS
    measureMetrics(macOSMetrics, automaticallyStartMeasuring: false) {
        // Configuration du test
        startMeasuring() // Commencer la mesure
        
        // Code à mesurer
        
        stopMeasuring() // Arrêter la mesure
    }
}
```

## 5. Notifications et Rapports

### Intégration Slack

Ajoutez un webhook Slack en tant que secret GitHub (`SLACK_WEBHOOK`) et utilisez-le dans le script de vérification des régressions.

### Rapport HTML

Le rapport HTML généré sera disponible en tant qu'artefact de build et peut être publié sur une page GitHub Pages pour un suivi historique.

### Tableau de Bord Performance

Pour un suivi plus avancé, considérez l'intégration avec:
- **Grafana** pour la visualisation des tendances de performance
- **InfluxDB** pour stocker l'historique des métriques
- **Prometheus** pour la surveillance en temps réel

## 6. Tests de Performance Complets

Les tests suivants doivent être inclus dans le pipeline CI:

1. **Tests de Performance de Chargement**
   - Chargement de grands decks (5000+ cartes)
   - Filtrage et recherche
   
2. **Tests de Mémoire**
   - Vérification des fuites mémoire
   - Utilisation mémoire pendant les opérations intensives
   
3. **Tests d'UI**
   - Performance du défilement
   - Temps de rendu des vues
   
4. **Tests CoreData**
   - Performance des requêtes optimisées
   - Migration de données

## Notes Finales

- Exécuter les tests sur des machines avec des spécifications matérielles constantes
- Isoler les tests de performance pour éviter les interférences
- Mettre à jour régulièrement les baselines (tous les trimestres)
- Analyser les tendances à long terme, pas seulement les résultats individuels
- Automatiser la création de tickets pour les régressions détectées

Ce pipeline CI garantira que les optimisations macOS sont maintenues et permettra de détecter rapidement toute régression de performance. 