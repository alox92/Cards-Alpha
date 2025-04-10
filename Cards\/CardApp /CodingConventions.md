# Conventions de Codage - Cards App

## Introduction

Ce document définit les conventions de codage à suivre pour le développement et la maintenance de l'application Cards App. Ces conventions visent à garantir un code propre, performant et sans fuites mémoire, tout en maintenant une architecture cohérente.

## Table des Matières

1. [Structure du Projet](#1-structure-du-projet)
2. [Architecture MVVM](#2-architecture-mvvm)
3. [Gestion d'État](#3-gestion-détat)
4. [Injection de Dépendances](#4-injection-de-dépendances)
5. [Prévention des Fuites Mémoire](#5-prévention-des-fuites-mémoire)
6. [Programmation Asynchrone](#6-programmation-asynchrone)
7. [Gestion des Erreurs](#7-gestion-des-erreurs)
8. [Optimisations par Plateforme](#8-optimisations-par-plateforme)
9. [Tests et Qualité](#9-tests-et-qualité)

## 1. Structure du Projet

### 1.1 Organisation des Fichiers

- Tous les ViewModels doivent être placés dans le dossier `Features/[Module]`
- Les services partagés doivent être dans `Core/Services`
- Les modèles de données dans `Core/Models`
- Les utilitaires et extensions dans `Core/Utilities`

### 1.2 Modules Fonctionnels

Chaque module fonctionnel doit suivre cette structure:

```
Features/
  └── [Module]/
      ├── [Module]View.swift
      ├── [Module]ViewModel.swift
      └── Components/
          └── [Sous-composants].swift
```

### 1.3 Nommage des Fichiers

- Utiliser le PascalCase pour les noms de fichier: `DeckViewModel.swift`
- Les noms doivent clairement indiquer le rôle et le module: `CardDetailView.swift`

## 2. Architecture MVVM

### 2.1 Principe de Séparation

- Les vues (`View`) ne doivent contenir que la logique d'affichage
- Les ViewModels doivent contenir toute la logique métier et l'état
- Les modèles (`Model`) ne doivent contenir que les structures de données

### 2.2 Structure des ViewModels

Tous les ViewModels doivent suivre cette structure standard:

```swift
extension CardApp.Features.{ModuleName} {
    final class {Type}ViewModel: ObservableObject {
        // 1. État centralisé dans une structure
        struct {Type}ViewState {
            var isLoading: Bool = false
            var error: String? = nil
            // ...propriétés spécifiques
        }
        
        // 2. État publié avec contrôle d'accès
        @Published private(set) var state = {Type}ViewState()
        
        // 3. Dépendances privées injectées
        private let service: ServiceProtocol
        private let logger = Logger(...)
        private var cancellables = Set<AnyCancellable>()
        
        // 4. Initialisation avec injection de dépendances
        init(service: ServiceProtocol) {
            self.service = service
            setupBindings()
            
            #if os(macOS)
            // Configurations spécifiques à macOS
            #endif
        }
        
        // 5. API publique avec annotations MainActor
        @MainActor
        func fetchData() async {
            // Méthodes publiques
        }
        
        // 6. Méthodes privées
        @MainActor
        private func updateState(_ updates: (inout {Type}ViewState) -> Void) {
            var newState = state
            updates(&newState)
            state = newState
        }
    }
}
```

## 3. Gestion d'État

### 3.1 Structure d'État Immutable

- Chaque ViewModel doit définir une structure `ViewState` pour encapsuler son état
- Toutes les mises à jour d'état doivent passer par la méthode `updateState`

### 3.2 Atomicité des Mises à Jour

- Toujours effectuer les mises à jour d'état en une seule opération atomique
- Éviter les mises à jour partielles qui pourraient laisser l'état incohérent

```swift
// ✅ Correct
updateState { state in
    state.isLoading = false
    state.error = nil
    state.data = newData
}

// ❌ Incorrect
self.state.isLoading = false
self.state.error = nil
self.state.data = newData
```

### 3.3 Gestion des Propriétés Publiées

- Limiter l'accès en écriture aux propriétés publiées avec `private(set)`
- Utiliser des computed properties pour les valeurs dérivées

## 4. Injection de Dépendances

### 4.1 Container de Dépendances

- Utiliser le `DependencyContainer` central pour l'injection de dépendances
- Tous les services doivent être injectés via le constructeur

```swift
init(cardService: CardServiceProtocol, scheduler: CardSchedulerProtocol) {
    self.cardService = cardService
    self.scheduler = scheduler
}
```

### 4.2 Mocks pour Tests

- Toujours utiliser des protocoles pour les services afin de faciliter le mocking
- Fournir des implémentations de test dans le dossier `Tests/Mocks`

### 4.3 Lifetime des Dépendances

- Les dépendances injectées doivent correspondre au lifetime du ViewModel
- Éviter les singletons sauf pour les services globaux comme le logging

## 5. Prévention des Fuites Mémoire

### 5.1 Utilisation de `self` dans les Closures

- **Règle Cruciale**: Toujours utiliser `[weak self]` dans les closures asynchrones ou Combine

```swift
// ✅ Correct
Task { [weak self] in
    guard let self = self else { return }
    await self.fetchData()
}

// ❌ Incorrect
Task {
    await self.fetchData() // Risque de cycle de référence
}
```

### 5.2 Vérification de `self` après `[weak self]`

- Toujours vérifier si `self` est nil après `[weak self]`
- Utiliser la syntax avec guard pour sortir rapidement si `self` est nil

```swift
// ✅ Correct
Task { [weak self] in
    guard let self = self else { return }
    // Utiliser self...
}

// ❌ Incorrect
Task { [weak self] in
    // Risque de crash si self est nil
    self?.method() 
}
```

### 5.3 Gestion des Souscriptions Combine

- Stocker toutes les souscriptions Combine dans un `Set<AnyCancellable>`
- Annuler explicitement les souscriptions lorsqu'elles ne sont plus nécessaires

```swift
private var cancellables = Set<AnyCancellable>()

publisher
    .sink { [weak self] value in
        guard let self = self else { return }
        // Traitement...
    }
    .store(in: &cancellables)
```

### 5.4 Références Circulaires

- Éviter les références circulaires entre ViewModels
- Utiliser des références faibles pour les parents-enfants ou les observateurs

```swift
// Relation parent-enfant
class ParentViewModel {
    let childViewModel: ChildViewModel
}

class ChildViewModel {
    weak var parent: ParentViewModel? // Référence faible pour éviter le cycle
}
```

## 6. Programmation Asynchrone

### 6.1 Utilisation de `async/await`

- Préférer `async/await` à Combine pour les opérations asynchrones
- Annoter les méthodes asynchrones avec `@MainActor` si elles modifient l'UI

```swift
@MainActor
func fetchCards() async throws {
    updateState { state in
        state.isLoading = true
    }
    
    do {
        let cards = try await cardService.fetchCards()
        updateState { state in
            state.cards = cards
            state.isLoading = false
        }
    } catch {
        updateState { state in
            state.error = error.localizedDescription
            state.isLoading = false
        }
    }
}
```

### 6.2 Gestion des Tâches

- Utiliser `Task` pour exécuter du code asynchrone
- Annuler les tâches de longue durée lorsqu'elles ne sont plus nécessaires

```swift
private var currentTask: Task<Void, Never>?

func startOperation() {
    // Annuler toute tâche en cours
    currentTask?.cancel()
    
    currentTask = Task { [weak self] in
        guard let self = self else { return }
        // Opération longue...
        
        // Vérifier périodiquement si la tâche a été annulée
        if Task.isCancelled { return }
    }
}

func cleanup() {
    currentTask?.cancel()
}
```

### 6.3 Synchronisation de l'Interface Utilisateur

- Utiliser `@MainActor` pour les méthodes qui modifient l'état UI
- Éviter de mélanger `DispatchQueue.main` et `MainActor`

## 7. Gestion des Erreurs

### 7.1 Format Cohérent

- Utiliser un format d'erreur cohérent dans tous les ViewModels (`String?`)
- Centraliser les messages d'erreur pour une localisation facile

### 7.2 Traitement des Erreurs

- Toujours gérer les erreurs et mettre à jour l'état en conséquence
- Logger les erreurs pour le débogage avec un niveau approprié

```swift
do {
    try await operation()
} catch {
    updateState { state in
        state.error = "Description de l'erreur: \(error.localizedDescription)"
        state.isLoading = false
    }
    logger.error("Erreur lors de l'opération: \(error)")
}
```

### 7.3 Récupération après Erreur

- Toujours laisser l'application dans un état utilisable après une erreur
- Fournir des mécanismes de nouvelle tentative pour les opérations ayant échoué

## 8. Optimisations par Plateforme

### 8.1 Directives de Compilation Conditionnelle

- Utiliser des directives de compilation pour les optimisations spécifiques à une plateforme

```swift
#if os(macOS)
// Code spécifique à macOS
#elseif os(iOS)
// Code spécifique à iOS
#endif
```

### 8.2 Optimisations pour macOS

- Augmenter les tailles de page pour tirer parti des écrans plus grands
- Optimiser pour les sessions d'utilisation prolongées
- Supporter les raccourcis clavier avancés

### 8.3 Optimisations pour iOS

- Optimiser pour une utilisation avec une seule main
- Gérer les interruptions (appels, notifications)
- Adapter l'interface pour différentes tailles d'écran

## 9. Tests et Qualité

### 9.1 Tests Unitaires

- Tous les ViewModels doivent avoir des tests unitaires
- Tester les cas d'erreur et les cas limites

### 9.2 Tests de Fuites Mémoire

- Inclure des tests de fuite mémoire pour tous les ViewModels
- Utiliser des références faibles et `autoreleasepool` pour les tests

```swift
func testViewModelMemoryLeak() {
    autoreleasepool {
        weak var weakViewModel: MyViewModel?
        
        autoreleasepool {
            let viewModel = MyViewModel(...)
            // Utiliser le ViewModel...
            weakViewModel = viewModel
        }
        
        XCTAssertNil(weakViewModel, "Le ViewModel n'a pas été correctement libéré")
    }
}
```

### 9.3 Tests de Performance

- Inclure des tests de performance pour les opérations critiques
- Définir des budgets de performance et surveiller les régressions

## Conclusion

Ces conventions de codage sont conçues pour prévenir les problèmes courants et maintenir un code de haute qualité dans l'application Cards App. Tous les développeurs doivent adhérer à ces conventions et signaler tout problème ou suggestion d'amélioration. 