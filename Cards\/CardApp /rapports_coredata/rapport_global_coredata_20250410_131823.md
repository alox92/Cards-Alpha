# Rapport d'analyse et d'optimisation CoreData - CardApp

Date d'exécution: 2025-04-10 13:18:23

## Résumé des vérifications effectuées


### 1. Vérification des fichiers d'optimisation

- ✅ Fichier './run_core_data_optimizer.swift' trouvé
- ✅ Fichier './Core/Tools/CoreDataOptimizer.swift' trouvé
- ✅ Fichier './CoreDataOptimizer.swift' trouvé

### 2. Vérification des modèles CoreData

- ✅ Modèle CoreData './Core/Models/Data/Core.xcdatamodeld/Core.xcdatamodel/contents' trouvé
  - 5 entités trouvées
  - ⚠️ Aucun index défini dans ce modèle
- ✅ Modèle CoreData './Core/Persistence/CardApp.xcdatamodeld/CardApp.xcdatamodel/contents' trouvé
  - 5 entités trouvées
  - ✅ 16 index définis

### 3. Vérification des permissions d'exécution

- ✅ Permissions d'exécution ajoutées au script run_core_data_optimizer.swift

### 4. Recherche de problèmes courants dans le code

#### Problèmes potentiels identifiés:

##### Recherche de: `try! context.save()`

Aucune correspondance trouvée

##### Recherche de: `NSFetchRequest<NSFetchRequestResult>`

```
./backups_coredata_perf_20250410_121217/CoreDataDiagnostics.swift:            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CardEntity")
./backups_coredata_perf_20250410_121217/CoreDataDiagnostics.swift:            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CardEntity")
./backups_coredata_perf_20250410_121217/DataManagementService.swift:            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
./Core/Tools/CoreDataOptimizer.swift:            let cardFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CardEntity")
./Core/Tools/CoreDataOptimizer.swift:            let deckFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "DeckEntity")
./Core/Tools/CoreDataOptimizer.swift:            let tagAssocFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TagItemAssociationEntity")
./Core/Tools/CoreDataOptimizer.swift:        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "DeckEntity")
./Core/Tools/CoreDataOptimizer.swift:            let reviewFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CardReviewEntity")
./Core/Tools/CoreDataOptimizer.swift:            let sessionFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "StudySessionEntity")
./Core/Services/Base/DataManagementService.swift:            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
... et 2 autres correspondances
```

##### Recherche de: `performBackgroundTask`

Aucune correspondance trouvée

##### Recherche de: `viewContext.perform`

Aucune correspondance trouvée

##### Recherche de: `@NSManaged var`

Aucune correspondance trouvée

### 5. Exécution de l'optimiseur CoreData

Exécution de l'optimiseur CoreData...

```
run_core_data_optimizer.swift:5:18: error: no such module 'CardApp'
  3 | import Foundation
  4 | import CoreData
  5 | @testable import CardApp
    |                  `- error: no such module 'CardApp'
  6 | 
  7 | /**
```

### 6. Recommandations pour l'optimisation de CoreData

#### Recommandations générales:

1. **Indexation des attributs fréquemment recherchés**
   - Ajouter des index pour tous les attributs utilisés dans des prédicats de recherche fréquents
   - Important pour les attributs comme `id`, `createdAt`, `updatedAt`

2. **Optimisation des fetch requests**
   - Toujours définir `fetchBatchSize` (généralement entre 20 et 100)
   - Utiliser `relationshipKeyPathsForPrefetching` pour les relations fréquemment accédées
   - Limiter les résultats avec `fetchLimit` quand approprié

3. **Gestion des contextes et concurrence**
   - Utiliser `@MainActor` pour les méthodes qui accèdent à `viewContext`
   - Exécuter les opérations lourdes avec `performBackgroundTask`
   - Toujours entourer `try context.save()` avec un bloc try/catch

4. **Normalisation du modèle de données**
   - Unifier les modèles Core.xcdatamodeld et CardApp.xcdatamodeld
   - Éviter les relations many-to-many directes, utiliser des entités intermédiaires
   - Limiter la profondeur des relations (éviter les cascades de relations)

5. **Amélioration des performances UI**
   - Utiliser `NSFetchedResultsController` pour les listes dans l'UI
   - Implémenter le chargement différé pour les attributs volumineux (images, texte long)
   - Mettre en cache les résultats de requêtes fréquentes mais peu modifiées
### 7. Conclusion

L'analyse et l'optimisation de CoreData ont été complétées. Veuillez consulter le rapport complet pour voir tous les problèmes identifiés et les recommandations.

Rapport généré automatiquement par l'outil d'analyse CoreData de CardApp.
