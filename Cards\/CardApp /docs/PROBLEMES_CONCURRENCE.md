# Analyse et Résolution des Problèmes de Concurrence dans CardApp

## Introduction

Ce document présente une analyse approfondie des problèmes de concurrence identifiés dans l'application CardApp, avec un focus particulier sur le service `UnifiedStudyService`. Ces problèmes peuvent entraîner des comportements imprévisibles, des blocages de l'interface utilisateur, des corruptions de données et des fuites de mémoire.

## Problèmes identifiés

### 1. Cycles de référence (Memory Leaks)

Les closures qui capturent `self` sans utiliser `[weak self]` peuvent créer des cycles de référence, empêchant la libération des objets en mémoire.

**Exemple problématique** :
```swift
Task {
    await self.fetchData()
    self.updateUI()
}
```

**Solution** :
```swift
Task { [weak self] in
    guard let self = self else { return }
    await self.fetchData()
    self.updateUI()
}
```

### 2. Opérations CoreData sur le thread principal

Les opérations CoreData, en particulier les requêtes et sauvegardes, peuvent bloquer le thread principal et geler l'interface utilisateur si elles ne sont pas exécutées correctement.

**Exemple problématique** :
```swift
// Exécution sur le thread principal
let results = try context.fetch(fetchRequest)
try context.save()
```

**Solution** :
```swift
// Utilisation de contexte d'arrière-plan
let backgroundContext = persistenceController.newBackgroundContext()
backgroundContext.perform {
    do {
        let results = try backgroundContext.fetch(fetchRequest)
        try backgroundContext.save()
    } catch {
        print("Erreur: \(error)")
    }
}
```

### 3. Manque d'isolation d'acteur (@MainActor)

Swift Concurrency requiert une isolation claire des acteurs pour garantir la sécurité des threads. Le manque d'annotation `@MainActor` peut conduire à des accès concurrents non sécurisés.

**Exemple problématique** :
```swift
public class UnifiedStudyService {
    private var currentSession: StudySession?
    
    func updateSession() {
        // Accès non sécurisé à currentSession
    }
}
```

**Solution** :
```swift
@MainActor
public class UnifiedStudyService {
    private var currentSession: StudySession?
    
    func updateSession() {
        // Maintenant sécurisé car isolé par MainActor
    }
}
```

### 4. Transfert de données non-Sendable entre acteurs

Le passage d'objets non conformes au protocole `Sendable` entre différents acteurs/contextes d'exécution peut entraîner des conditions de concurrence.

**Exemple problématique** :
```swift
// NSManagedObject n'est pas Sendable
Task {
    let entity = fetchEntity()
    await processEntity(entity)
}
```

**Solution** :
```swift
// Conversion en structure Sendable
Task {
    let entity = fetchEntity()
    let sendableData = SendableData(id: entity.id, name: entity.name)
    await processData(sendableData)
}
```

### 5. Utilisation incorrecte de Task et async/await

Des erreurs d'utilisation de la syntaxe `Task` et des fonctions asynchrones peuvent entraîner des conditions de course ou des deadlocks.

**Exemple problématique** :
```swift
func refreshCurrentSession() {
    Task {
        self.currentSession = try? await fetchCurrentSession()
    }
}
```

**Solution** :
```swift
func refreshCurrentSession() {
    Task { @MainActor [weak self] in
        guard let self = self else { return }
        self.currentSession = try? await fetchCurrentSession()
    }
}
```

## Problèmes spécifiques dans UnifiedStudyService

### Problème 1: Capture de contexte CoreData dans des closures @Sendable

Le fichier `UnifiedStudyService.swift` contient plusieurs instances où des objets `NSManagedObjectContext` non-Sendable sont capturés dans des closures `@Sendable`, ce qui est contraire aux règles de sécurité de concurrence de Swift.

**Correction** :
- Utiliser des structures Sendable pour transférer des données entre acteurs
- Confiner les opérations CoreData dans leurs contextes d'exécution
- Convertir les objets `NSManagedObject` en structures `Sendable` avant de les passer à d'autres acteurs

### Problème 2: Références ambiguës à fetchRequest

Plusieurs méthodes font référence à une variable `fetchRequest` non définie localement.

**Correction** :
- S'assurer que chaque requête est correctement définie et nommée localement
- Ajouter des limites et des tailles de lot (fetchLimit et fetchBatchSize) à toutes les requêtes

### Problème 3: Qualification incorrecte des types

Des références à des types comme `Core.Common.ReviewRating` et `Core.Models.Common.MasteryLevel` sont incorrectes.

**Correction** :
- Utiliser les chemins corrects pour les types importés
- Ajouter les imports nécessaires en haut du fichier

### Problème 4: Manque d'isolation acteur pour les méthodes

Certaines méthodes devant s'exécuter sur le thread principal ne sont pas marquées `@MainActor`.

**Correction** :
- Ajouter `@MainActor` aux méthodes qui modifient l'interface utilisateur ou les propriétés partagées
- Marquer explicitement les méthodes thread-safe comme `nonisolated`

## Solutions automatisées

Le script `fix_unified_study_service.sh` applique les corrections suivantes :

1. Ajout de `@MainActor` à la classe si nécessaire
2. Correction des qualifications de types (`Core.Common.ReviewRating` → `ReviewRating`)
3. Ajout de `[weak self]` dans les closures pour éviter les cycles de référence
4. Correction des références à `fetchRequest` non définies
5. Ajout d'optimisations aux requêtes CoreData (`fetchBatchSize`, `fetchLimit`)
6. Ajout de blocs try-catch autour des opérations `context.save()`
7. Correction des noms de paramètres avec qualifications incorrectes
8. Correction de la syntaxe des `Task`
9. Ajout de structures Sendable pour le transfert de données entre acteurs

## Bonnes pratiques pour la programmation concurrente avec CoreData

1. **Isoler les propriétés partagées** : Utiliser `@MainActor` pour protéger les propriétés partagées
2. **Contextes d'arrière-plan** : Créer des contextes d'arrière-plan pour les opérations longues
3. **Transfert de données sécurisé** : Utiliser des structures `Sendable` pour transférer des données entre acteurs
4. **Éviter les cycles de référence** : Toujours utiliser `[weak self]` dans les closures asynchrones
5. **Gestion des erreurs** : Entourer les opérations CoreData de blocs try-catch
6. **Optimisation des requêtes** : Utiliser `fetchLimit` et `fetchBatchSize` pour optimiser les performances

## Ressources supplémentaires

- [Documentation Apple sur Swift Concurrency](https://developer.apple.com/documentation/swift/concurrency)
- [Documentation Apple sur CoreData et Threads](https://developer.apple.com/documentation/coredata/using_core_data_in_the_background)
- [WWDC21 - Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133/)
- [WWDC21 - Meet async/await in Swift](https://developer.apple.com/videos/play/wwdc2021/10132/) 