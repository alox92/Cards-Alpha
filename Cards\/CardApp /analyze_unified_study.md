# Guide d'analyse de concurrence pour UnifiedStudyService

Ce guide explique comment analyser et corriger les problèmes de concurrence spécifiques à `UnifiedStudyService` dans le projet CardApp.

## Contexte du problème

Le service `UnifiedStudyService` est un composant critique de l'application qui gère les sessions d'étude et les statistiques. Il présente plusieurs problèmes de concurrence potentiels :

1. Accès au `viewContext` de CoreData depuis plusieurs threads
2. Closures qui créent des cycles de référence (memory leaks)
3. Opérations CoreData lourdes sur le thread principal
4. Absence d'isolation d'acteur pour les propriétés partagées

Ces problèmes peuvent conduire à des incohérences de données, des blocages de l'interface utilisateur et des fuites de mémoire.

## Comment utiliser l'outil d'analyse

### Méthode 1 : Mode autonome

Pour une analyse rapide ciblée sur `UnifiedStudyService` uniquement :

```bash
./power_debug.sh --unified-study
```

Cette commande :
- Localise le fichier `UnifiedStudyService.swift` dans le projet
- Analyse les problèmes de concurrence potentiels
- Génère un rapport détaillé avec des recommandations spécifiques
- Affiche un résumé des problèmes trouvés

Le rapport sera enregistré dans le dossier `reports/` avec un nom comme `unified_study_service_analysis_20250409_190011.txt`.

### Méthode 2 : Dans une analyse complète

L'analyse d'`UnifiedStudyService` est également incluse dans l'analyse complète du projet :

```bash
./power_debug.sh
```

## Comment interpréter les résultats

Le rapport d'analyse comprend plusieurs sections :

1. **Propriétés partagées sans protection de concurrence**  
   Liste des propriétés qui pourraient être accédées simultanément depuis plusieurs threads.

2. **Utilisation de viewContext sans @MainActor**  
   Identifie les endroits où `viewContext` est utilisé sans l'annotation `@MainActor`.

3. **Closures sans [weak self]**  
   Détecte les closures qui pourraient créer des cycles de référence.

4. **Opérations CoreData sans contexte d'arrière-plan approprié**  
   Identifie les opérations CoreData qui pourraient bloquer le thread principal.

## Corrections recommandées

Le rapport inclut des exemples de code corrigé pour les problèmes courants :

### 1. Utilisation correcte de @MainActor

```swift
@MainActor
func fetchCurrentSession() async throws -> StudySession? {
    let request = NSFetchRequest<StudySessionEntity>(entityName: "StudySessionEntity")
    request.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: true))
    request.fetchLimit = 1
    
    let results = try persistenceController.viewContext.fetch(request)
    return results.first.flatMap(StudySession.init)
}
```

### 2. Utilisation de contexte d'arrière-plan

```swift
func updateSessionInBackground(id: UUID, duration: TimeInterval) async throws {
    return try await withCheckedThrowingContinuation { continuation in
        persistenceController.container.performBackgroundTask { context in
            do {
                let request = NSFetchRequest<StudySessionEntity>(entityName: "StudySessionEntity")
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                request.fetchLimit = 1
                
                let results = try context.fetch(request)
                if let session = results.first {
                    session.duration = duration
                    try context.save()
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: StudyError.sessionNotFound)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
```

## Ressources additionnelles

- [Documentation Apple sur Concurrency](https://developer.apple.com/documentation/swift/concurrency)
- [Documentation Apple sur @MainActor](https://developer.apple.com/documentation/swift/mainactor)
- [WWDC21 - Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133/)
- [Documentation Apple sur CoreData et threads](https://developer.apple.com/documentation/coredata/using_core_data_in_the_background)

## Besoin d'aide supplémentaire ?

Si vous avez besoin d'aide pour appliquer ces corrections, vous pouvez exécuter :

```bash
./power_debug.sh
```

et répondre "o" à la question concernant l'application des corrections automatiques. Notez que certaines corrections complexes nécessiteront toujours une intervention manuelle. 