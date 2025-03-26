# 🏗️ Architecture de Cards App

## 📋 Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture MVVM](#architecture-mvvm)
3. [Couches d'Architecture](#couches-darchitecture)
4. [Flux de Données](#flux-de-données)
5. [Gestion d'État](#gestion-détat)
6. [Communication entre Composants](#communication-entre-composants)
7. [Responsabilités des Composants](#responsabilités-des-composants)
8. [Diagrammes](#diagrammes)

## 🌟 Vue d'ensemble

Cards App est conçue selon l'architecture MVVM (Model-View-ViewModel) pour offrir une séparation claire des préoccupations, facilitant ainsi la maintenance, les tests et l'évolution de l'application.

L'application utilise:
- **SwiftUI** pour l'interface utilisateur
- **Combine** pour la réactivité et la liaison de données
- **CoreData** pour la persistance
- **CloudKit** pour la synchronisation iCloud

## 🏛️ Architecture MVVM

### Principes de Base

L'architecture MVVM sépare l'application en trois couches principales:

```
┌─────────┐    ┌─────────────┐    ┌─────────┐
│  Modèle  │◄───│  ViewModel  │◄───│   Vue   │
└─────────┘    └─────────────┘    └─────────┘
     ▲                ▲                ▲
     │                │                │
     └── Données ─────┴── Actions ─────┘
```

1. **Modèle (Model)** : Représente les données et la logique métier
2. **Vue (View)** : Interface utilisateur et présentation
3. **ViewModel** : Intermédiaire entre le Modèle et la Vue

### Avantages de MVVM dans Cards App

- **Testabilité** : Les ViewModels peuvent être testés indépendamment de l'UI
- **Réutilisabilité** : Les modèles et ViewModels peuvent être partagés entre différentes vues
- **Maintenabilité** : Séparation claire des responsabilités
- **Réactivité** : Intégration naturelle avec SwiftUI et Combine

## 🧱 Couches d'Architecture

### 📊 Modèle (Model)

Le modèle représente les données et la logique métier de l'application:

```swift
struct Card: Identifiable, Hashable, Codable {
    let id: UUID
    let question: String
    let answer: String
    // ...
}

struct Deck: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    // ...
}
```

#### 🔌 Entités CoreData

Les modèles sont persistés via CoreData avec des entités correspondantes:

```swift
class CardEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var question: String?
    // ...
}
```

#### 🔄 Conversion Modèles ↔ Entités

Des méthodes de conversion assurent la transition entre les modèles Swift et les entités CoreData:

```swift
extension Card {
    static func from(_ entity: CardEntity) -> Card { ... }
    func toEntity(in context: NSManagedObjectContext) -> CardEntity { ... }
}
```

### 📱 Vue (View)

Les vues sont implémentées avec SwiftUI et sont responsables uniquement de la présentation:

```swift
struct DeckListView: View {
    @EnvironmentObject var viewModel: DeckViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.decks) { deck in
                DeckRow(deck: deck)
            }
        }
        .onAppear { viewModel.loadDecks() }
    }
}
```

#### 📑 Hiérarchie des Vues

Les vues sont organisées en modules fonctionnels avec une hiérarchie claire:

- **Vues Principales** : Points d'entrée pour les fonctionnalités majeures (DeckListView, StudyView)
- **Sous-vues** : Composants spécifiques (DeckRow, CardView)
- **Composants partagés** : Éléments d'UI réutilisables (RatingButtons, RichTextEditor)

### 🧮 ViewModel

Les ViewModels servent d'intermédiaires entre les modèles et les vues:

```swift
class DeckViewModel: ObservableObject {
    @Published var decks: [Deck] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let cardService: CardServiceProtocol
    
    func loadDecks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            decks = try await cardService.fetchDecks()
        } catch {
            self.error = error
        }
    }
    
    // Autres méthodes...
}
```

#### 🧠 Responsabilités du ViewModel

- Exposer les données du modèle dans un format adapté à l'UI
- Gérer l'état de l'UI (chargement, erreurs)
- Traiter les actions utilisateur et les transmettre aux services
- Transformer les données pour l'affichage

### 🔧 Services

Les services encapsulent la logique métier et l'accès aux données:

```swift
class CardService: CardServiceProtocol {
    private let context: NSManagedObjectContext
    
    func fetchCards(for deck: Deck?) async throws -> [Card] {
        // Implémentation avec CoreData
    }
    
    func addCard(_ card: Card) async throws {
        // Implémentation
    }
    
    // Autres méthodes...
}
```

#### 🧰 Types de Services

- **CardService** : Gestion des cartes et paquets
- **CardScheduler** : Algorithme de répétition espacée
- **PersistenceController** : Gestion de CoreData
- **CloudSyncService** : Synchronisation iCloud
- **ImportExportService** : Import/export Anki et autres formats

## 🔄 Flux de Données

### Lecture des Données

```
┌─────────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│ CoreData/iCloud │→ │ CardService   │→ │ ViewModel     │→ │ View          │
└─────────────────┘  └───────────────┘  └───────────────┘  └───────────────┘
```

1. Le service récupère les données depuis CoreData
2. Les données sont transformées en modèles Swift
3. Le ViewModel traite et prépare les données pour l'affichage
4. La vue observe les changements via @Published et se met à jour

### Écriture des Données

```
┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌─────────────────┐
│ View          │→ │ ViewModel     │→ │ CardService   │→ │ CoreData/iCloud │
└───────────────┘  └───────────────┘  └───────────────┘  └─────────────────┘
```

1. L'utilisateur interagit avec la vue (ex: ajouter une carte)
2. La vue appelle une méthode du ViewModel
3. Le ViewModel délègue au service approprié
4. Le service persiste les changements dans CoreData
5. CoreData se synchronise avec iCloud (si activé)

## 📊 Gestion d'État

### État Local

- **@State** pour l'état local des vues
- **@Binding** pour partager l'état avec les sous-vues

### État Global

- **@EnvironmentObject** pour l'état partagé entre plusieurs vues
- **@Published** dans les ViewModels pour la réactivité

### État de l'Application

- **@AppStorage** pour les préférences utilisateur
- **@SceneStorage** pour l'état de l'interface

## 🔄 Communication entre Composants

### Vue → ViewModel

- Appels directs de méthodes
- Liaison bidirectionnelle via @Binding

### ViewModel → Service

- Appels de méthodes asynchrones (async/await)
- Injection de dépendances via constructeur

### Service → Persistance

- CoreData pour le stockage local
- CloudKit pour la synchronisation

### Notification des Changements

- Combine et @Published pour la réactivité
- NotificationCenter pour les événements système

## 👥 Responsabilités des Composants

### 📋 Vue

- **Responsabilités** : Présentation, Interactions utilisateur
- **Ne doit pas** : Contenir de la logique métier, Accéder directement aux données

### 🧮 ViewModel

- **Responsabilités** : Logique de présentation, Traitement des actions
- **Ne doit pas** : Contenir de la logique UI, Accéder directement à CoreData

### 🧠 Modèle

- **Responsabilités** : Structure des données, Logique métier
- **Ne doit pas** : Connaître l'UI, Dépendre des ViewModels

### 🔧 Service

- **Responsabilités** : Accès aux données, Logique métier complexe
- **Ne doit pas** : Contenir de la logique UI, Dépendre des ViewModels

## 📊 Diagrammes

### 🔄 Cycle de Vie d'une Carte

```
┌────────────┐    ┌────────────┐    ┌───────────┐    ┌───────────┐
│ Création   │ → │ Révision   │ → │ Mise à    │ → │ Archivage  │
│ de Carte   │    │ Périodique │    │ Jour      │    │ (Option)  │
└────────────┘    └────────────┘    └───────────┘    └───────────┘
       │                 ↑              │
       │                 │              │
       └─────────────────┘──────────────┘
```

### 📅 Algorithme de Répétition Espacée

```
┌────────────┐    ┌─────────────┐
│ Révision   │ → │ Évaluation  │
│ d'une Carte│    │ (Again/Hard/│
└────────────┘    │ Good/Easy)  │
                  └─────────────┘
                        │
                        ↓
┌────────────────────────────────────────────┐
│           Calcul du Prochain Intervalle    │
├────────────┬────────────┬──────────────────┤
│ Again      │ Hard       │     Good/Easy    │
│ (Court)    │ (Moyen)    │     (Long)       │
└────────────┴────────────┴──────────────────┘
                        │
                        ↓
┌────────────────────────────────────────────┐
│        Mise à Jour du Niveau de Maîtrise   │
├────────────┬────────────┬──────────────────┤
│ Régresser  │ Maintenir  │     Progresser   │
└────────────┴────────────┴──────────────────┘
```

### 🌐 Architecture Globale

```
┌───────────────────────────────────────────────────────────────┐
│                           SwiftUI                              │
├───────────┬───────────────┬────────────────┬──────────────────┤
│ Decks     │ Cards         │ Study          │ Statistics       │
│ Module    │ Module        │ Module         │ Module           │
└───────────┴───────────────┴────────────────┴──────────────────┘
                           │
┌───────────────────────────────────────────────────────────────┐
│                         ViewModels                             │
├───────────────┬──────────────────┬───────────────────────────┤
│ DeckViewModel │ CardViewModel    │ StudyViewModel            │
└───────────────┴──────────────────┴───────────────────────────┘
                           │
┌───────────────────────────────────────────────────────────────┐
│                          Services                              │
├───────────────┬──────────────────┬───────────────────────────┤
│ CardService   │ CardScheduler    │ ImportExportService       │
└───────────────┴──────────────────┴───────────────────────────┘
                           │
┌───────────────────────────────────────────────────────────────┐
│                        Persistence                             │
├───────────────────────────┬───────────────────────────────────┤
│       CoreData            │            CloudKit                │
└───────────────────────────┴───────────────────────────────────┘
```

---

Cette architecture MVVM fournit une base solide pour l'application Cards, permettant une séparation claire des responsabilités, une maintenance facilitée et une évolutivité optimale. Elle tire parti des caractéristiques modernes de Swift, SwiftUI et Combine pour créer une expérience utilisateur fluide et réactive. 

---

# 🏗️ Cards App Architecture

## 📋 Table of Contents

1. [Overview](#overview)
2. [MVVM Architecture](#mvvm-architecture)
3. [Architecture Layers](#architecture-layers)
4. [Data Flow](#data-flow)
5. [State Management](#state-management)
6. [Component Communication](#component-communication)
7. [Component Responsibilities](#component-responsibilities)
8. [Diagrams](#diagrams)

## 🌟 Overview {#overview}

Cards App is designed using the MVVM (Model-View-ViewModel) architecture to provide a clear separation of concerns, facilitating maintenance, testing, and evolution of the application.

The application uses:
- **SwiftUI** for the user interface
- **Combine** for reactivity and data binding
- **CoreData** for persistence
- **CloudKit** for iCloud synchronization

## 🏛️ MVVM Architecture {#mvvm-architecture}

### Basic Principles

The MVVM architecture separates the application into three main layers:

```
┌─────────┐    ┌─────────────┐    ┌─────────┐
│  Model   │◄───│  ViewModel  │◄───│  View   │
└─────────┘    └─────────────┘    └─────────┘
     ▲                ▲                ▲
     │                │                │
     └── Data ────────┴── Actions ─────┘
```

1. **Model**: Represents data and business logic
2. **View**: User interface and presentation
3. **ViewModel**: Intermediary between the Model and the View

### Benefits of MVVM in Cards App

- **Testability**: ViewModels can be tested independently of the UI
- **Reusability**: Models and ViewModels can be shared between different views
- **Maintainability**: Clear separation of responsibilities
- **Reactivity**: Natural integration with SwiftUI and Combine

## 🧱 Couches d'Architecture

### 📊 Modèle (Model)

Le modèle représente les données et la logique métier de l'application:

```swift
struct Card: Identifiable, Hashable, Codable {
    let id: UUID
    let question: String
    let answer: String
    // ...
}

struct Deck: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    // ...
}
```

#### 🔌 Entités CoreData

Les modèles sont persistés via CoreData avec des entités correspondantes:

```swift
class CardEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var question: String?
    // ...
}
```

#### 🔄 Conversion Modèles ↔ Entités

Des méthodes de conversion assurent la transition entre les modèles Swift et les entités CoreData:

```swift
extension Card {
    static func from(_ entity: CardEntity) -> Card { ... }
    func toEntity(in context: NSManagedObjectContext) -> CardEntity { ... }
}
```

### 📱 Vue (View)

Les vues sont implémentées avec SwiftUI et sont responsables uniquement de la présentation:

```swift
struct DeckListView: View {
    @EnvironmentObject var viewModel: DeckViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.decks) { deck in
                DeckRow(deck: deck)
            }
        }
        .onAppear { viewModel.loadDecks() }
    }
}
```

#### 📑 Hiérarchie des Vues

Les vues sont organisées en modules fonctionnels avec une hiérarchie claire:

- **Vues Principales** : Points d'entrée pour les fonctionnalités majeures (DeckListView, StudyView)
- **Sous-vues** : Composants spécifiques (DeckRow, CardView)
- **Composants partagés** : Éléments d'UI réutilisables (RatingButtons, RichTextEditor)

### 🧮 ViewModel

Les ViewModels servent d'intermédiaires entre les modèles et les vues:

```swift
class DeckViewModel: ObservableObject {
    @Published var decks: [Deck] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let cardService: CardServiceProtocol
    
    func loadDecks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            decks = try await cardService.fetchDecks()
        } catch {
            self.error = error
        }
    }
    
    // Autres méthodes...
}
```

#### 🧠 Responsabilités du ViewModel

- Exposer les données du modèle dans un format adapté à l'UI
- Gérer l'état de l'UI (chargement, erreurs)
- Traiter les actions utilisateur et les transmettre aux services
- Transformer les données pour l'affichage

### 🔧 Services

Les services encapsulent la logique métier et l'accès aux données:

```swift
class CardService: CardServiceProtocol {
    private let context: NSManagedObjectContext
    
    func fetchCards(for deck: Deck?) async throws -> [Card] {
        // Implémentation avec CoreData
    }
    
    func addCard(_ card: Card) async throws {
        // Implémentation
    }
    
    // Autres méthodes...
}
```

#### 🧰 Types de Services

- **CardService** : Gestion des cartes et paquets
- **CardScheduler** : Algorithme de répétition espacée
- **PersistenceController** : Gestion de CoreData
- **CloudSyncService** : Synchronisation iCloud
- **ImportExportService** : Import/export Anki et autres formats

## 🔄 Flux de Données

### Lecture des Données

```
┌─────────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│ CoreData/iCloud │→ │ CardService   │→ │ ViewModel     │→ │ View          │
└─────────────────┘  └───────────────┘  └───────────────┘  └───────────────┘
```

1. Le service récupère les données depuis CoreData
2. Les données sont transformées en modèles Swift
3. Le ViewModel traite et prépare les données pour l'affichage
4. La vue observe les changements via @Published et se met à jour

### Écriture des Données

```
┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌─────────────────┐
│ View          │→ │ ViewModel     │→ │ CardService   │→ │ CoreData/iCloud │
└───────────────┘  └───────────────┘  └───────────────┘  └─────────────────┘
```

1. L'utilisateur interagit avec la vue (ex: ajouter une carte)
2. La vue appelle une méthode du ViewModel
3. Le ViewModel délègue au service approprié
4. Le service persiste les changements dans CoreData
5. CoreData se synchronise avec iCloud (si activé)

## 📊 Gestion d'État

### État Local

- **@State** pour l'état local des vues
- **@Binding** pour partager l'état avec les sous-vues

### État Global

- **@EnvironmentObject** pour l'état partagé entre plusieurs vues
- **@Published** dans les ViewModels pour la réactivité

### État de l'Application

- **@AppStorage** pour les préférences utilisateur
- **@SceneStorage** pour l'état de l'interface

## 🔄 Communication entre Composants

### Vue → ViewModel

- Appels directs de méthodes
- Liaison bidirectionnelle via @Binding

### ViewModel → Service

- Appels de méthodes asynchrones (async/await)
- Injection de dépendances via constructeur

### Service → Persistance

- CoreData pour le stockage local
- CloudKit pour la synchronisation

### Notification des Changements

- Combine et @Published pour la réactivité
- NotificationCenter pour les événements système

## 👥 Responsabilités des Composants

### 📋 Vue

- **Responsabilités** : Présentation, Interactions utilisateur
- **Ne doit pas** : Contenir de la logique métier, Accéder directement aux données

### 🧮 ViewModel

- **Responsabilités** : Logique de présentation, Traitement des actions
- **Ne doit pas** : Contenir de la logique UI, Accéder directement à CoreData

### 🧠 Modèle

- **Responsabilités** : Structure des données, Logique métier
- **Ne doit pas** : Connaître l'UI, Dépendre des ViewModels

### 🔧 Service

- **Responsabilités** : Accès aux données, Logique métier complexe
- **Ne doit pas** : Contenir de la logique UI, Dépendre des ViewModels

## 📊 Diagrammes

### 🔄 Cycle de Vie d'une Carte

```
┌────────────┐    ┌────────────┐    ┌───────────┐    ┌───────────┐
│ Création   │ → │ Révision   │ → │ Mise à    │ → │ Archivage  │
│ de Carte   │    │ Périodique │    │ Jour      │    │ (Option)  │
└────────────┘    └────────────┘    └───────────┘    └───────────┘
       │                 ↑              │
       │                 │              │
       └─────────────────┘──────────────┘
```

### 📅 Algorithme de Répétition Espacée

```
┌────────────┐    ┌─────────────┐
│ Révision   │ → │ Évaluation  │
│ d'une Carte│    │ (Again/Hard/│
└────────────┘    │ Good/Easy)  │
                  └─────────────┘
                        │
                        ↓
┌────────────────────────────────────────────┐
│           Calcul du Prochain Intervalle    │
├────────────┬────────────┬──────────────────┤
│ Again      │ Hard       │     Good/Easy    │
│ (Court)    │ (Moyen)    │     (Long)       │
└────────────┴────────────┴──────────────────┘
                        │
                        ↓
┌────────────────────────────────────────────┐
│        Mise à Jour du Niveau de Maîtrise   │
├────────────┬────────────┬──────────────────┤
│ Régresser  │ Maintenir  │     Progresser   │
└────────────┴────────────┴──────────────────┘
```

### 🌐 Architecture Globale

```
┌───────────────────────────────────────────────────────────────┐
│                           SwiftUI                              │
├───────────┬───────────────┬────────────────┬──────────────────┤
│ Decks     │ Cards         │ Study          │ Statistics       │
│ Module    │ Module        │ Module         │ Module           │
└───────────┴───────────────┴────────────────┴──────────────────┘
                           │
┌───────────────────────────────────────────────────────────────┐
│                         ViewModels                             │
├───────────────┬──────────────────┬───────────────────────────┤
│ DeckViewModel │ CardViewModel    │ StudyViewModel            │
└───────────────┴──────────────────┴───────────────────────────┘
                           │
┌───────────────────────────────────────────────────────────────┐
│                          Services                              │
├───────────────┬──────────────────┬───────────────────────────┤
│ CardService   │ CardScheduler    │ ImportExportService       │
└───────────────┴──────────────────┴───────────────────────────┘
                           │
┌───────────────────────────────────────────────────────────────┐
│                        Persistence                             │
├───────────────────────────┬───────────────────────────────────┤
│       CoreData            │            CloudKit                │
└───────────────────────────┴───────────────────────────────────┘
```

---

Cette architecture MVVM fournit une base solide pour l'application Cards, permettant une séparation claire des responsabilités, une maintenance facilitée et une évolutivité optimale. Elle tire parti des caractéristiques modernes de Swift, SwiftUI et Combine pour créer une expérience utilisateur fluide et réactive. 