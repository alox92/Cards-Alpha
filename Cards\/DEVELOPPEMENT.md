# 🧠 Guide de Développement - Cards App

## 📋 Table des Matières

1. [Introduction](#introduction)
2. [Configuration de l'Environnement](#configuration-de-lenvironnement)
3. [Architecture du Projet](#architecture-du-projet)
4. [Structure du Code](#structure-du-code)
5. [Modèles de Données](#modèles-de-données)
6. [Persistance et CoreData](#persistance-et-coredata)
7. [UI et SwiftUI](#ui-et-swiftui)
8. [Tests](#tests)
9. [Lignes Directrices de Contribution](#lignes-directrices-de-contribution)
10. [Processus de Revue du Code](#processus-de-revue-du-code)
11. [Release et Déploiement](#release-et-déploiement)
12. [Ressources Additionnelles](#ressources-additionnelles)

## 🌟 Introduction

Ce document est conçu pour les développeurs qui souhaitent comprendre, modifier ou contribuer au code source de Cards App. Vous y trouverez des informations détaillées sur l'architecture, les conventions de codage et les processus de développement.

Cards App est une application macOS moderne écrite en Swift et SwiftUI, suivant l'architecture MVVM (Model-View-ViewModel). Elle utilise CoreData pour la persistance locale et CloudKit pour la synchronisation entre appareils.

## 💻 Configuration de l'Environnement

### Prérequis
- macOS 13.0 (Ventura) ou supérieur
- Xcode 15.0 ou supérieur
- Git
- CocoaPods (optionnel, pour certaines dépendances)

### Mise en Place
1. Clonez le dépôt :
   ```bash
   git clone https://github.com/votre-organisation/cards-app.git
   cd cards-app
   ```

2. Ouvrez le projet dans Xcode :
   ```bash
   open CardApp.xcodeproj
   ```

3. Installation des dépendances (si nécessaire) :
   ```bash
   pod install
   # Puis ouvrez CardApp.xcworkspace au lieu de .xcodeproj
   ```

4. Configuration de développement :
   - Sélectionnez le schéma "CardApp (Development)"
   - Choisissez un simulateur macOS ou votre Mac comme cible

### Génération des Certificats (pour les contributeurs approuvés)
Pour les développeurs ayant accès au compte développeur Apple de l'organisation :
1. Dans Xcode, allez dans "Signing & Capabilities"
2. Connectez-vous avec votre compte développeur Apple
3. Sélectionnez l'équipe appropriée
4. Laissez Xcode gérer les certificats automatiquement

## 🏗️ Architecture du Projet

Cards App suit une architecture MVVM (Model-View-ViewModel) stricte avec les principes suivants :

### Composants Principaux
- **Model** : Définition des structures de données et logique métier
- **View** : Interfaces utilisateur SwiftUI
- **ViewModel** : Couche de présentation et logique d'état
- **Services** : Couche d'accès aux données et opérations externes

### Flux de Données
1. L'utilisateur interagit avec une **Vue**
2. La Vue transmet l'action au **ViewModel**
3. Le ViewModel demande des données ou des modifications via des **Services**
4. Les Services mettent à jour les **Modèles** et notifient le ViewModel
5. Le ViewModel met à jour son état
6. La Vue réagit aux changements d'état du ViewModel via `@Published` et `ObservableObject`

### Principes de Design
- **Séparation des préoccupations** : Chaque composant a une responsabilité unique et claire
- **Immutabilité** : Privilégiez les types valeur (struct) aux types référence (class) quand possible
- **Programmation Réactive** : Utilisez Combine pour les flux de données asynchrones
- **Injection de Dépendances** : Les dépendances sont injectées plutôt que créées dans les composants

## 📁 Structure du Code

### Organisation des Dossiers
```
CardApp/
├── Features/         # Modules fonctionnels
│   ├── Decks/        # Fonctionnalité de gestion des paquets
│   ├── Cards/        # Fonctionnalité de gestion des cartes
│   ├── Study/        # Fonctionnalité d'étude
│   ├── Statistics/   # Visualisation des statistiques
│   └── Settings/     # Paramètres de l'application
├── Core/             # Composants de base
│   ├── Models/       # Modèles de données
│   ├── Services/     # Services et utilitaires
│   │   └── CoreData/ # Modèles CoreData
│   ├── Extensions/   # Extensions Swift
│   ├── UI/           # Composants UI réutilisables
│   └── Components/   # Composants métier réutilisables
├── ViewModels/       # ViewModels globaux
├── Resources/        # Ressources statiques
└── Supporting/       # Fichiers de support (Info.plist, etc.)
```

### Convention de Nommage

#### Fichiers
- **Modèles** : Nom singulier, suffixe spécifique (`Card.swift`, `DeckModels.swift`)
- **Vues** : Suffixe "View" (`DeckListView.swift`, `CardDetailView.swift`)
- **ViewModels** : Suffixe "ViewModel" (`CardViewModel.swift`)
- **Services** : Suffixe "Service" ou "Controller" (`CardService.swift`, `PersistenceController.swift`)

#### Types et Variables
- Classes/Structs/Enums : PascalCase (`Card`, `ReviewRating`)
- Variables/Propriétés : camelCase (`cardCount`, `isLoading`)
- Fonctions : camelCase, verbes d'action (`fetchCards()`, `updateDeck()`)
- Constantes globales : camelCase avec préfixe k (`kMaxCardLimit`)

### Règles de Style
- Indentation : 4 espaces
- Longueur de ligne maximale : 120 caractères
- Accolades : même ligne pour l'ouverture, nouvelle ligne pour la fermeture
- Documentation : [Format HeaderDoc](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/)

## 📊 Modèles de Données

### Entités Principales

#### Card
Représente une carte mémoire individuelle :
```swift
struct Card: Identifiable, Hashable, Codable {
    let id: UUID
    let question: String
    let answer: String
    let additionalInfo: String?
    let deckID: UUID?
    let createdAt: Date
    let updatedAt: Date
    let masteryLevel: MasteryLevel
    let reviewCount: Int
    let lastReviewedAt: Date?
    let nextReviewDate: Date?
    let tags: [String]
    let isFlagged: Bool
    let correctCount: Int
    let incorrectCount: Int
}
```

#### Deck
Représente un paquet de cartes :
```swift
struct Deck: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let description: String
    let createdAt: Date
    let updatedAt: Date
    let colorHex: String
    var cardCount: Int
    var dueCardCount: Int
}
```

#### StudySession
Représente une session d'étude :
```swift
struct StudySession: Identifiable, Codable {
    let id: UUID
    let deckId: UUID
    let startTime: Date
    var endTime: Date?
    var reviews: [CardReview]
}
```

### Énumérations Importantes

#### MasteryLevel
```swift
enum MasteryLevel: String, Codable, CaseIterable, Identifiable {
    case new, learning, reviewing, mastered
}
```

#### ReviewRating
```swift
enum ReviewRating: String, CaseIterable, Identifiable, Codable {
    case again, hard, good, easy
}
```

### Relations Entre Modèles
- Une **Card** appartient à un **Deck** (via `deckID`)
- Un **Deck** contient plusieurs **Card**s
- Une **StudySession** concerne un **Deck** spécifique (via `deckId`)
- Une **StudySession** contient plusieurs **CardReview**s
- Chaque **CardReview** fait référence à une **Card** (via `cardID`)

## 💾 Persistance et CoreData

### Schéma CoreData
Cards App utilise CoreData pour la persistance des données. Le modèle comprend trois entités principales :

#### CardEntity
```swift
class CardEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var question: String?
    @NSManaged public var answer: String?
    @NSManaged public var additionalInfo: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastReviewedAt: Date?
    @NSManaged public var reviewCount: Int16
    @NSManaged public var correctCount: Int16
    @NSManaged public var incorrectCount: Int16
    @NSManaged public var nextReviewDate: Date?
    @NSManaged public var masteryLevel: String?
    @NSManaged public var tags: String?
    @NSManaged public var isFlagged: Bool
    @NSManaged public var deck: DeckEntity?
}
```

#### DeckEntity
```swift
class DeckEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String?
    @NSManaged public var description: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var cards: NSSet?
}
```

#### StudySessionEntity
```swift
class StudySessionEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var deckID: UUID
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var reviewsData: Data?
}
```

### Gestion de la Persistance
Le service `PersistenceController` gère l'initialisation et la configuration de CoreData :

```swift
class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CardsDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Erreur de chargement CoreData: \(error)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
```

### Synchronisation CloudKit
La synchronisation avec iCloud utilise `NSPersistentCloudKitContainer` :

```swift
class CloudSyncService {
    static let shared = CloudSyncService()
    private let container: NSPersistentCloudKitContainer
    
    private init() {
        container = NSPersistentCloudKitContainer(name: "CardsDataModel")
        
        let description = container.persistentStoreDescriptions.first!
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.votreapp.cartes"
        )
        
        // Configuration pour la synchronisation
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, 
                             forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Chargement
        container.loadPersistentStores { ... }
    }
}
```

## 🎨 UI et SwiftUI

### Principes d'UI
- **Design Adaptatif** : L'interface s'adapte à différentes tailles d'écran
- **Accessibilité** : Support des fonctionnalités d'accessibilité macOS
- **Mode Sombre/Clair** : Support des deux thèmes système
- **Animations** : Animations fluides et discrètes pour améliorer l'UX

### Composants UI Réutilisables
Dans le dossier `Core/UI` :

#### CardView
Affiche une carte avec support pour le retournement et le rich text :
```swift
struct CardView: View {
    let card: Card
    @Binding var isShowingAnswer: Bool
    
    var body: some View {
        VStack {
            // Contenu
        }
        .rotation3DEffect(isShowingAnswer ? Angle(degrees: 180) : .zero, axis: (x: 0, y: 1, z: 0))
        .cardBackground()
    }
}
```

#### DeckCard
Affiche un paquet avec sa couleur et ses statistiques :
```swift
struct DeckCard: View {
    let deck: Deck
    
    var body: some View {
        VStack {
            // Contenu
        }
        .background(deck.color.opacity(0.2))
        .cornerRadius(12)
    }
}
```

### Navigation
L'application utilise une `TabView` comme navigation principale avec cinq onglets :
- **Paquets** : `DeckListView`
- **Cartes** : `CardListView`
- **Étudier** : `StudyDashboardView`
- **Statistiques** : `StatisticsView`
- **Réglages** : `SettingsView`

Les vues de détail utilisent une navigation standard, avec des vues modales pour les ajouts/modifications.

### Extensions SwiftUI
Des extensions utiles pour améliorer SwiftUI :

```swift
extension View {
    func cardBackground() -> some View {
        self
            .padding()
            .background(Color(.textBackgroundColor))
            .cornerRadius(16)
            .shadow(radius: 2)
    }
    
    func adaptiveFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: size, weight: weight))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}
```

## 🧪 Tests

### Types de Tests
- **Tests Unitaires** : pour la logique métier et les fonctions de base
- **Tests d'Intégration** : pour les interactions entre composants
- **Tests UI** : pour les flux utilisateur de base

### Structure des Tests
```
CardAppTests/
├── ModelTests/        # Tests des modèles
├── ViewModelTests/    # Tests des ViewModels
├── ServiceTests/      # Tests des services
│   └── MockData/      # Données de test
└── UITests/           # Tests d'interface
```

### Exemple de Test Unitaire
Test pour le calcul du prochain intervalle de révision :

```swift
class CardSchedulerTests: XCTestCase {
    var scheduler: CardScheduler!
    
    override func setUp() {
        super.setUp()
        scheduler = CardScheduler()
    }
    
    func testCalculateNextReviewForEasyRating() {
        let currentLevel = MasteryLevel.learning
        let currentDate = Date()
        
        let nextDate = scheduler.calculateNextReview(
            currentLevel: currentLevel,
            rating: .easy,
            lastReview: currentDate
        )
        
        // Vérifier que l'intervalle est correct (environ 4.5 jours pour learning + easy)
        let interval = nextDate.timeIntervalSince(currentDate)
        let expectedInterval = 3.0 * 1.5 * 24 * 3600 // ~4.5 jours en secondes
        
        XCTAssertEqual(interval, expectedInterval, accuracy: 10) // Tolérance de 10 secondes
    }
}
```

### Mocks et Stubs
Pour les tests de ViewModels et Services :

```swift
class MockCardService: CardServiceProtocol {
    var mockedCards: [Card] = []
    var mockedDecks: [Deck] = []
    var shouldFailFetch = false
    
    func fetchCards(for deck: Deck?) async throws -> [Card] {
        if shouldFailFetch {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        return mockedCards
    }
    
    // Autres méthodes du protocole...
}
```

## 📝 Lignes Directrices de Contribution

### Processus de Contribution

1. **Fork** du dépôt sur GitHub
2. **Clone** de votre fork localement
3. Créez une **branche** pour votre fonctionnalité ou correction
   ```bash
   git checkout -b feature/ma-fonctionnalite
   ```
4. Effectuez vos **modifications** avec des commits atomiques
5. **Testez** vos modifications
6. **Poussez** vos modifications vers votre fork
7. Soumettez une **Pull Request** vers la branche principale

### Conventions de Commit
Format des messages de commit :
```
type(scope): description concise

Corps optionnel plus détaillé expliquant les changements.
```

Types communs :
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `docs`: Modifications de la documentation
- `style`: Formatage (espaces, indentation, etc.) sans changement de code
- `refactor`: Refactorisation de code sans changement de fonctionnalité
- `test`: Ajout ou correction de tests
- `chore`: Changements divers (build, dépendances, etc.)

### Règles de Pull Request
- Une PR ne doit concerner qu'une seule fonctionnalité ou correction
- Le titre doit être clair et descriptif
- La description doit résumer les changements et référencer les issues liées
- Les tests doivent passer et la couverture ne doit pas diminuer
- Le code doit suivre les conventions de style du projet

## 🔎 Processus de Revue du Code

### Critères de Revue
Tous les changements sont évalués selon ces critères :
- **Fonctionnalité** : Le code fait-il ce qu'il est censé faire ?
- **Lisibilité** : Le code est-il clair et bien documenté ?
- **Maintenabilité** : Le code est-il facile à modifier et à étendre ?
- **Performance** : Le code est-il efficace ?
- **Tests** : Le code est-il bien testé ?

### Processus
1. L'auteur soumet une Pull Request
2. Les reviewers assignés examinent le code
3. Les commentaires et suggestions sont fournis dans la PR
4. L'auteur répond aux commentaires et effectue les modifications nécessaires
5. Une fois que tous les problèmes sont résolus, un maintainer approuve la PR
6. La PR est fusionnée dans la branche principale

## 🚀 Release et Déploiement

### Processus de Release
1. Création d'une branche de release : `release/vX.Y.Z`
2. Derniers tests et corrections sur cette branche
3. Finalisation du changelog et de la documentation
4. Fusion dans `main` et création d'un tag de version
5. Build et signature via CI/CD

### Versionnement
Cards App suit le [versionnement sémantique](https://semver.org/) :
- **MAJEUR** : Changements incompatibles avec les versions précédentes
- **MINEUR** : Ajout de fonctionnalités rétrocompatibles
- **CORRECTIF** : Corrections de bugs rétrocompatibles

### CI/CD
Le projet utilise GitHub Actions pour :
- **Intégration Continue** : Exécution des tests à chaque push
- **Livraison Continue** : Génération d'un build testable pour chaque PR
- **Déploiement Continu** : Publication automatique des releases sur l'App Store

## 📚 Ressources Additionnelles

### Documentation Officielle
- [Documentation SwiftUI](https://developer.apple.com/documentation/swiftui)
- [Documentation CoreData](https://developer.apple.com/documentation/coredata)
- [Documentation CloudKit](https://developer.apple.com/documentation/cloudkit)

### Bibliothèques et Outils
- [Swift Package Manager](https://www.swift.org/package-manager/)
- [SwiftLint](https://github.com/realm/SwiftLint) pour l'analyse statique du code
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) pour le formatage du code

### Ressources d'Apprentissage
- [Stanford CS193p](https://cs193p.sites.stanford.edu/) - Cours sur SwiftUI
- [Hacking with Swift](https://www.hackingwithswift.com/plus/ultimate-portfolio-app) - Construction d'applications Swift complètes
- [Swift by Sundell](https://www.swiftbysundell.com/) - Articles sur Swift et SwiftUI

---

# 🧠 Development Guide - Cards App

## 📋 Table of Contents

1. [Introduction](#introduction-en)
2. [Environment Setup](#environment-setup)
3. [Project Architecture](#project-architecture)
4. [Code Structure](#code-structure)
5. [Data Models](#data-models)
6. [Persistence and CoreData](#persistence-and-coredata)
7. [UI and SwiftUI](#ui-and-swiftui)
8. [Testing](#testing)
9. [Contribution Guidelines](#contribution-guidelines)
10. [Code Review Process](#code-review-process)
11. [Release and Deployment](#release-and-deployment)
12. [Additional Resources](#additional-resources)

## 🌟 Introduction {#introduction-en}

This document is designed for developers who want to understand, modify, or contribute to the Cards App source code. You will find detailed information about the architecture, coding conventions, and development processes.

Cards App is a modern macOS application written in Swift and SwiftUI, following the MVVM (Model-View-ViewModel) architecture. It uses CoreData for local persistence and CloudKit for synchronization between devices.

## 💻 Environment Setup

### Prerequisites
- macOS 13.0 (Ventura) or higher
- Xcode 15.0 or higher
- Git
- CocoaPods (optional, for certain dependencies)

### Mise en Place
1. Clonez le dépôt :
   ```bash
   git clone https://github.com/votre-organisation/cards-app.git
   cd cards-app
   ```

2. Ouvrez le projet dans Xcode :
   ```bash
   open CardApp.xcodeproj
   ```

3. Installation des dépendances (si nécessaire) :
   ```bash
   pod install
   # Puis ouvrez CardApp.xcworkspace au lieu de .xcodeproj
   ```

4. Configuration de développement :
   - Sélectionnez le schéma "CardApp (Development)"
   - Choisissez un simulateur macOS ou votre Mac comme cible

### Génération des Certificats (pour les contributeurs approuvés)
Pour les développeurs ayant accès au compte développeur Apple de l'organisation :
1. Dans Xcode, allez dans "Signing & Capabilities"
2. Connectez-vous avec votre compte développeur Apple
3. Sélectionnez l'équipe appropriée
4. Laissez Xcode gérer les certificats automatiquement

## 🏗️ Architecture du Projet

Cards App suit une architecture MVVM (Model-View-ViewModel) stricte avec les principes suivants :

### Composants Principaux
- **Model** : Définition des structures de données et logique métier
- **View** : Interfaces utilisateur SwiftUI
- **ViewModel** : Couche de présentation et logique d'état
- **Services** : Couche d'accès aux données et opérations externes

### Flux de Données
1. L'utilisateur interagit avec une **Vue**
2. La Vue transmet l'action au **ViewModel**
3. Le ViewModel demande des données ou des modifications via des **Services**
4. Les Services mettent à jour les **Modèles** et notifient le ViewModel
5. Le ViewModel met à jour son état
6. La Vue réagit aux changements d'état du ViewModel via `@Published` et `ObservableObject`

### Principes de Design
- **Séparation des préoccupations** : Chaque composant a une responsabilité unique et claire
- **Immutabilité** : Privilégiez les types valeur (struct) aux types référence (class) quand possible
- **Programmation Réactive** : Utilisez Combine pour les flux de données asynchrones
- **Injection de Dépendances** : Les dépendances sont injectées plutôt que créées dans les composants

## 📁 Structure du Code

### Organisation des Dossiers
```
CardApp/
├── Features/         # Modules fonctionnels
│   ├── Decks/        # Fonctionnalité de gestion des paquets
│   ├── Cards/        # Fonctionnalité de gestion des cartes
│   ├── Study/        # Fonctionnalité d'étude
│   ├── Statistics/   # Visualisation des statistiques
│   └── Settings/     # Paramètres de l'application
├── Core/             # Composants de base
│   ├── Models/       # Modèles de données
│   ├── Services/     # Services et utilitaires
│   │   └── CoreData/ # Modèles CoreData
│   ├── Extensions/   # Extensions Swift
│   ├── UI/           # Composants UI réutilisables
│   └── Components/   # Composants métier réutilisables
├── ViewModels/       # ViewModels globaux
├── Resources/        # Ressources statiques
└── Supporting/       # Fichiers de support (Info.plist, etc.)
```

### Convention de Nommage

#### Fichiers
- **Modèles** : Nom singulier, suffixe spécifique (`Card.swift`, `DeckModels.swift`)
- **Vues** : Suffixe "View" (`DeckListView.swift`, `CardDetailView.swift`)
- **ViewModels** : Suffixe "ViewModel" (`CardViewModel.swift`)
- **Services** : Suffixe "Service" ou "Controller" (`CardService.swift`, `PersistenceController.swift`)

#### Types et Variables
- Classes/Structs/Enums : PascalCase (`Card`, `ReviewRating`)
- Variables/Propriétés : camelCase (`cardCount`, `isLoading`)
- Fonctions : camelCase, verbes d'action (`fetchCards()`, `updateDeck()`)
- Constantes globales : camelCase avec préfixe k (`kMaxCardLimit`)

### Règles de Style
- Indentation : 4 espaces
- Longueur de ligne maximale : 120 caractères
- Accolades : même ligne pour l'ouverture, nouvelle ligne pour la fermeture
- Documentation : [Format HeaderDoc](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/)

## 📊 Modèles de Données

### Entités Principales

#### Card
Représente une carte mémoire individuelle :
```swift
struct Card: Identifiable, Hashable, Codable {
    let id: UUID
    let question: String
    let answer: String
    let additionalInfo: String?
    let deckID: UUID?
    let createdAt: Date
    let updatedAt: Date
    let masteryLevel: MasteryLevel
    let reviewCount: Int
    let lastReviewedAt: Date?
    let nextReviewDate: Date?
    let tags: [String]
    let isFlagged: Bool
    let correctCount: Int
    let incorrectCount: Int
}
```

#### Deck
Représente un paquet de cartes :
```swift
struct Deck: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let description: String
    let createdAt: Date
    let updatedAt: Date
    let colorHex: String
    var cardCount: Int
    var dueCardCount: Int
}
```

#### StudySession
Représente une session d'étude :
```swift
struct StudySession: Identifiable, Codable {
    let id: UUID
    let deckId: UUID
    let startTime: Date
    var endTime: Date?
    var reviews: [CardReview]
}
```

### Énumérations Importantes

#### MasteryLevel
```swift
enum MasteryLevel: String, Codable, CaseIterable, Identifiable {
    case new, learning, reviewing, mastered
}
```

#### ReviewRating
```swift
enum ReviewRating: String, CaseIterable, Identifiable, Codable {
    case again, hard, good, easy
}
```

### Relations Entre Modèles
- Une **Card** appartient à un **Deck** (via `deckID`)
- Un **Deck** contient plusieurs **Card**s
- Une **StudySession** concerne un **Deck** spécifique (via `deckId`)
- Une **StudySession** contient plusieurs **CardReview**s
- Chaque **CardReview** fait référence à une **Card** (via `cardID`)

## 💾 Persistance et CoreData

### Schéma CoreData
Cards App utilise CoreData pour la persistance des données. Le modèle comprend trois entités principales :

#### CardEntity
```swift
class CardEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var question: String?
    @NSManaged public var answer: String?
    @NSManaged public var additionalInfo: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastReviewedAt: Date?
    @NSManaged public var reviewCount: Int16
    @NSManaged public var correctCount: Int16
    @NSManaged public var incorrectCount: Int16
    @NSManaged public var nextReviewDate: Date?
    @NSManaged public var masteryLevel: String?
    @NSManaged public var tags: String?
    @NSManaged public var isFlagged: Bool
    @NSManaged public var deck: DeckEntity?
}
```

#### DeckEntity
```swift
class DeckEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String?
    @NSManaged public var description: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var cards: NSSet?
}
```

#### StudySessionEntity
```swift
class StudySessionEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var deckID: UUID
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var reviewsData: Data?
}
```

### Gestion de la Persistance
Le service `PersistenceController` gère l'initialisation et la configuration de CoreData :

```swift
class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CardsDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Erreur de chargement CoreData: \(error)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
```

### Synchronisation CloudKit
La synchronisation avec iCloud utilise `NSPersistentCloudKitContainer` :

```swift
class CloudSyncService {
    static let shared = CloudSyncService()
    private let container: NSPersistentCloudKitContainer
    
    private init() {
        container = NSPersistentCloudKitContainer(name: "CardsDataModel")
        
        let description = container.persistentStoreDescriptions.first!
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.votreapp.cartes"
        )
        
        // Configuration pour la synchronisation
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, 
                             forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Chargement
        container.loadPersistentStores { ... }
    }
}
```

## 🎨 UI et SwiftUI

### Principes d'UI
- **Design Adaptatif** : L'interface s'adapte à différentes tailles d'écran
- **Accessibilité** : Support des fonctionnalités d'accessibilité macOS
- **Mode Sombre/Clair** : Support des deux thèmes système
- **Animations** : Animations fluides et discrètes pour améliorer l'UX

### Composants UI Réutilisables
Dans le dossier `Core/UI` :

#### CardView
Affiche une carte avec support pour le retournement et le rich text :
```swift
struct CardView: View {
    let card: Card
    @Binding var isShowingAnswer: Bool
    
    var body: some View {
        VStack {
            // Contenu
        }
        .rotation3DEffect(isShowingAnswer ? Angle(degrees: 180) : .zero, axis: (x: 0, y: 1, z: 0))
        .cardBackground()
    }
}
```

#### DeckCard
Affiche un paquet avec sa couleur et ses statistiques :
```swift
struct DeckCard: View {
    let deck: Deck
    
    var body: some View {
        VStack {
            // Contenu
        }
        .background(deck.color.opacity(0.2))
        .cornerRadius(12)
    }
}
```

### Navigation
L'application utilise une `TabView` comme navigation principale avec cinq onglets :
- **Paquets** : `DeckListView`
- **Cartes** : `CardListView`
- **Étudier** : `StudyDashboardView`
- **Statistiques** : `StatisticsView`
- **Réglages** : `SettingsView`

Les vues de détail utilisent une navigation standard, avec des vues modales pour les ajouts/modifications.

### Extensions SwiftUI
Des extensions utiles pour améliorer SwiftUI :

```swift
extension View {
    func cardBackground() -> some View {
        self
            .padding()
            .background(Color(.textBackgroundColor))
            .cornerRadius(16)
            .shadow(radius: 2)
    }
    
    func adaptiveFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: size, weight: weight))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}
```

## 🧪 Tests

### Types de Tests
- **Tests Unitaires** : pour la logique métier et les fonctions de base
- **Tests d'Intégration** : pour les interactions entre composants
- **Tests UI** : pour les flux utilisateur de base

### Structure des Tests
```
CardAppTests/
├── ModelTests/        # Tests des modèles
├── ViewModelTests/    # Tests des ViewModels
├── ServiceTests/      # Tests des services
│   └── MockData/      # Données de test
└── UITests/           # Tests d'interface
```

### Exemple de Test Unitaire
Test pour le calcul du prochain intervalle de révision :

```swift
class CardSchedulerTests: XCTestCase {
    var scheduler: CardScheduler!
    
    override func setUp() {
        super.setUp()
        scheduler = CardScheduler()
    }
    
    func testCalculateNextReviewForEasyRating() {
        let currentLevel = MasteryLevel.learning
        let currentDate = Date()
        
        let nextDate = scheduler.calculateNextReview(
            currentLevel: currentLevel,
            rating: .easy,
            lastReview: currentDate
        )
        
        // Vérifier que l'intervalle est correct (environ 4.5 jours pour learning + easy)
        let interval = nextDate.timeIntervalSince(currentDate)
        let expectedInterval = 3.0 * 1.5 * 24 * 3600 // ~4.5 jours en secondes
        
        XCTAssertEqual(interval, expectedInterval, accuracy: 10) // Tolérance de 10 secondes
    }
}
```

### Mocks et Stubs
Pour les tests de ViewModels et Services :

```swift
class MockCardService: CardServiceProtocol {
    var mockedCards: [Card] = []
    var mockedDecks: [Deck] = []
    var shouldFailFetch = false
    
    func fetchCards(for deck: Deck?) async throws -> [Card] {
        if shouldFailFetch {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        return mockedCards
    }
    
    // Autres méthodes du protocole...
}
```

## 📝 Lignes Directrices de Contribution

### Processus de Contribution

1. **Fork** du dépôt sur GitHub
2. **Clone** de votre fork localement
3. Créez une **branche** pour votre fonctionnalité ou correction
   ```bash
   git checkout -b feature/ma-fonctionnalite
   ```
4. Effectuez vos **modifications** avec des commits atomiques
5. **Testez** vos modifications
6. **Poussez** vos modifications vers votre fork
7. Soumettez une **Pull Request** vers la branche principale

### Conventions de Commit
Format des messages de commit :
```
type(scope): description concise

Corps optionnel plus détaillé expliquant les changements.
```

Types communs :
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `docs`: Modifications de la documentation
- `style`: Formatage (espaces, indentation, etc.) sans changement de code
- `refactor`: Refactorisation de code sans changement de fonctionnalité
- `test`: Ajout ou correction de tests
- `chore`: Changements divers (build, dépendances, etc.)

### Règles de Pull Request
- Une PR ne doit concerner qu'une seule fonctionnalité ou correction
- Le titre doit être clair et descriptif
- La description doit résumer les changements et référencer les issues liées
- Les tests doivent passer et la couverture ne doit pas diminuer
- Le code doit suivre les conventions de style du projet

## 🔎 Processus de Revue du Code

### Critères de Revue
Tous les changements sont évalués selon ces critères :
- **Fonctionnalité** : Le code fait-il ce qu'il est censé faire ?
- **Lisibilité** : Le code est-il clair et bien documenté ?
- **Maintenabilité** : Le code est-il facile à modifier et à étendre ?
- **Performance** : Le code est-il efficace ?
- **Tests** : Le code est-il bien testé ?

### Processus
1. L'auteur soumet une Pull Request
2. Les reviewers assignés examinent le code
3. Les commentaires et suggestions sont fournis dans la PR
4. L'auteur répond aux commentaires et effectue les modifications nécessaires
5. Une fois que tous les problèmes sont résolus, un maintainer approuve la PR
6. La PR est fusionnée dans la branche principale

## 🚀 Release et Déploiement

### Processus de Release
1. Création d'une branche de release : `release/vX.Y.Z`
2. Derniers tests et corrections sur cette branche
3. Finalisation du changelog et de la documentation
4. Fusion dans `main` et création d'un tag de version
5. Build et signature via CI/CD

### Versionnement
Cards App suit le [versionnement sémantique](https://semver.org/) :
- **MAJEUR** : Changements incompatibles avec les versions précédentes
- **MINEUR** : Ajout de fonctionnalités rétrocompatibles
- **CORRECTIF** : Corrections de bugs rétrocompatibles

### CI/CD
Le projet utilise GitHub Actions pour :
- **Intégration Continue** : Exécution des tests à chaque push
- **Livraison Continue** : Génération d'un build testable pour chaque PR
- **Déploiement Continu** : Publication automatique des releases sur l'App Store

## 📚 Ressources Additionnelles

### Documentation Officielle
- [Documentation SwiftUI](https://developer.apple.com/documentation/swiftui)
- [Documentation CoreData](https://developer.apple.com/documentation/coredata)
- [Documentation CloudKit](https://developer.apple.com/documentation/cloudkit)

### Bibliothèques et Outils
- [Swift Package Manager](https://www.swift.org/package-manager/)
- [SwiftLint](https://github.com/realm/SwiftLint) pour l'analyse statique du code
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) pour le formatage du code

### Ressources d'Apprentissage
- [Stanford CS193p](https://cs193p.sites.stanford.edu/) - Cours sur SwiftUI
- [Hacking with Swift](https://www.hackingwithswift.com/plus/ultimate-portfolio-app) - Construction d'applications Swift complètes
- [Swift by Sundell](https://www.swiftbysundell.com/) - Articles sur Swift et SwiftUI

---

Ce guide de développement est un document vivant qui évoluera avec le projet. Si vous avez des questions, des suggestions ou des commentaires, n'hésitez pas à ouvrir une issue dans le dépôt GitHub ou à contacter l'équipe de développement. 