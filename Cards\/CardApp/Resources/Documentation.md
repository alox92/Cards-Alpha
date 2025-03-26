# 📚 Documentation Complète de Cards App

## 📋 Table des Matières

1. [Introduction](#introduction)
2. [Fonctionnalités Implémentées](#fonctionnalités-implémentées)
3. [Architecture](#architecture)
4. [Structure des Fichiers](#structure-des-fichiers)
5. [Flux de Données](#flux-de-données)
6. [Modèles de Données](#modèles-de-données)
7. [Services](#services)
8. [ViewModels](#viewmodels)
9. [Vues](#vues)
10. [Implémentation du Rich Text](#implémentation-du-rich-text)
11. [Algorithme de Répétition Espacée](#algorithme-de-répétition-espacée)
12. [Synchronisation et Persistance](#synchronisation-et-persistance)
13. [Arborescence Détaillée](#arborescence-détaillée)

## 🌟 Introduction

Cards App est une application macOS moderne conçue pour la création et la révision de cartes mémoire, s'inspirant d'Anki mais avec une interface native SwiftUI. Cette application utilise un algorithme de répétition espacée pour optimiser l'apprentissage, et offre une expérience utilisateur riche avec prise en charge de différents formats de médias.

L'application est construite avec Swift et SwiftUI, en utilisant une architecture MVVM (Model-View-ViewModel) pour une séparation claire des responsabilités. Elle utilise CoreData pour la persistance locale et CloudKit pour la synchronisation entre appareils.

## ✨ Fonctionnalités Implémentées

### 📝 Gestion des Paquets et Cartes
- **Création de paquets** : Les utilisateurs peuvent créer des paquets de cartes avec un nom, une description et une couleur personnalisée.
- **Édition de paquets** : Modification des propriétés des paquets existants.
- **Suppression de paquets** : Suppression complète d'un paquet et de toutes ses cartes.
- **Création de cartes** : Ajout de nouvelles cartes avec question et réponse.
- **Édition de cartes** : Modification du contenu des cartes existantes.
- **Déplacement de cartes** : Transfert de cartes entre différents paquets.
- **Organisation par tags** : Ajout de tags aux cartes pour une organisation améliorée.
- **Signalement de cartes** : Fonctionnalité de marquage pour identifier les cartes importantes.

### 📊 Système d'Étude
- **Algorithme de répétition espacée** : Planification intelligente des révisions basée sur la difficulté perçue.
- **Niveaux de maîtrise** : Classification des cartes en quatre niveaux (Nouveau, Apprentissage, Révision, Maîtrisé).
- **Sessions d'étude** : Interface dédiée pour réviser les cartes dues.
- **Système de notation** : Évaluation des cartes (À revoir, Difficile, Bien, Facile).
- **Statistiques de session** : Suivi des performances pendant une session d'étude.
- **Planification adaptative** : Ajustement des intervalles de révision selon les performances.

### 📈 Statistiques et Suivi
- **Suivi global** : Visualisation des progrès d'apprentissage globaux.
- **Statistiques par paquet** : Analyse détaillée par paquet.
- **Suivi des révisions** : Historique des sessions d'étude.
- **Indicateurs de performance** : Taux de réussite, temps moyen de réponse, etc.
- **Visualisations graphiques** : Représentations visuelles des données d'apprentissage.

### 🔄 Import/Export
- **Format .apkg (Anki)** : Compatibilité avec le format Anki pour l'import et l'export.
- **Format texte/CSV** : Support d'import/export basique en texte.
- **Gestion des médias** : Extraction et importation des médias associés aux cartes.

### ⚙️ Paramètres et Personnalisation
- **Mode sombre/clair** : Adaptation au thème du système ou choix manuel.
- **Options d'affichage** : Personnalisation de l'interface utilisateur.
- **Préférences d'étude** : Configuration des algorithmes d'apprentissage.
- **Raccourcis clavier** : Support des raccourcis pour une utilisation efficace.

### 🔄 Synchronisation et Sauvegarde
- **Synchronisation iCloud** : Synchronisation des données entre appareils Apple.
- **Sauvegarde/Restauration** : Fonctionnalités de sauvegarde et de restauration des données.

## 🏗️ Architecture

L'application suit l'architecture MVVM (Model-View-ViewModel) avec une séparation claire des responsabilités :

### 🔹 Model (Modèle)
- Définition des structures de données (Card, Deck, StudySession, etc.)
- Représentation de l'état de l'application
- Implémenté dans `/Core/Models/`

### 🔹 View (Vue)
- Interface utilisateur en SwiftUI
- Affichage des données et interactions utilisateur
- Implémenté dans `/Features/` pour les écrans principaux et `/Core/UI/` pour les composants réutilisables

### 🔹 ViewModel (Modèle de Vue)
- Logique de présentation et traitement des événements
- Transformation des données du modèle pour la vue
- Gestion des états de l'UI
- Implémenté dans `/ViewModels/` et dans chaque module fonctionnel

### 🔹 Services
- Logique métier et opérations de données
- Communication avec les API externes et la persistance
- Implémenté dans `/Core/Services/`

## 📁 Structure des Fichiers

### 📌 Fichiers Principaux

#### 🔸 Points d'Entrée
- **CardsApp.swift** : Point d'entrée de l'application, définit la structure de scène et les commandes macOS.
- **ContentView.swift** : Vue racine de l'application qui contient la TabView principale.

#### 🔸 Modèles de Données
- **CardModels.swift** : Définit les structures de carte, options de filtrage et extensions.
- **DeckModels.swift** : Définit les structures de paquet et options de tri.
- **StudyModels.swift** : Définit les structures pour les sessions d'étude et les révisions.
- **Enums.swift** : Contient les énumérations globales comme MasteryLevel, ReviewRating, etc.

#### 🔸 Services
- **CardService.swift** : Service central pour la gestion des cartes et des paquets.
- **CardScheduler.swift** : Service pour calculer les dates de révision et niveaux de maîtrise.
- **PersistenceController.swift** : Gestion de CoreData et du stockage persistant.
- **CloudSyncService.swift** : Synchronisation avec iCloud via CloudKit.
- **ImportExportService.swift** : Import/export de paquets dans différents formats.

#### 🔸 ViewModels
- **CardViewModel.swift** : Gestion de l'affichage et de la manipulation des cartes.
- **DeckViewModel.swift** : Gestion de l'affichage et de la manipulation des paquets.
- **StudyViewModel.swift** : Gestion des sessions d'étude et des révisions.

### 📌 Fonctionnalités (Features)

#### 🔸 Paquets (Decks)
- **DeckListView.swift** : Vue principale listant tous les paquets.
- **DeckDetailView.swift** : Vue détaillée d'un paquet spécifique.
- **AddDeckView.swift** : Formulaire de création de paquet.
- **DeckViewModel.swift** : ViewModel spécifique aux paquets (dans ce dossier).

#### 🔸 Cartes (Cards)
- **CardListView.swift** : Vue principale listant toutes les cartes.
- **CardDetailView.swift** : Vue détaillée d'une carte spécifique.
- **AddCardView.swift** : Formulaire de création de carte.
- **CardViewModel.swift** : ViewModel spécifique aux cartes (dans ce dossier).

#### 🔸 Étude (Study)
- **StudyDashboardView.swift** : Tableau de bord pour commencer les sessions d'étude.
- **StudyView.swift** : Interface principale de révision des cartes.
- **DeckSelectionView.swift** : Sélection de paquet pour l'étude.
- **StudyViewModel.swift** : ViewModel pour la logique d'étude.

#### 🔸 Statistiques (Statistics)
- **StatisticsView.swift** : Vue principale des statistiques.
- **DeckStatsView.swift** : Statistiques détaillées par paquet.
- **ProgressCharts.swift** : Visualisations graphiques des progrès.

#### 🔸 Paramètres (Settings)
- **SettingsView.swift** : Vue des paramètres de l'application.
- **AppearanceSettings.swift** : Paramètres d'apparence.
- **StudySettings.swift** : Configuration de l'algorithme d'étude.

### 📌 Composants Core

#### 🔸 UI
- **CardView.swift** : Composant pour afficher une carte.
- **DeckCard.swift** : Composant pour afficher un paquet.
- **EmptyStateView.swift** : Affichage d'état vide.
- **RatingButtons.swift** : Boutons pour évaluer les cartes pendant l'étude.

#### 🔸 Extensions
- **ColorExtensions.swift** : Extensions pour la gestion des couleurs.
- **AccessibilityExtensions.swift** : Extensions pour l'accessibilité.

#### 🔸 CoreData
- **CoreDataModel.swift** : Définition des entités CoreData.

## 🔄 Flux de Données

Le flux de données dans l'application suit un modèle unidirectionnel :

1. **Interaction Utilisateur** : L'utilisateur interagit avec une Vue.
2. **Traitement par le ViewModel** : Le ViewModel traite l'événement et appelle les Services nécessaires.
3. **Opérations de Données** : Les Services effectuent les opérations de données via CoreData ou autres sources.
4. **Mise à Jour du Modèle** : Les données du modèle sont mises à jour.
5. **Notification du ViewModel** : Le ViewModel est notifié des changements (via Combine).
6. **Rafraîchissement de la Vue** : La Vue se met à jour automatiquement grâce à la liaison de données SwiftUI (@Published, @ObservedObject, etc.).

Ce flux garantit une séparation claire des responsabilités et une maintenance facilitée du code.

## 📊 Modèles de Données

### 🔹 Card (Carte)
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
    
    // Propriétés calculées et méthodes
}
```

### 🔹 Deck (Paquet)
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
    
    // Propriétés calculées et méthodes
}
```

### 🔹 StudySession (Session d'Étude)
```swift
struct StudySession: Identifiable, Codable {
    let id: UUID
    let deckId: UUID
    let startTime: Date
    var endTime: Date?
    var reviews: [CardReview] = []
    
    // Propriétés calculées et méthodes
}
```

### 🔹 CardReview (Révision de Carte)
```swift
struct CardReview: Identifiable, Codable {
    let id: UUID
    let cardID: UUID
    let timestamp: Date
    let rating: ReviewRating
    let timeSpent: TimeInterval
    
    // Propriétés calculées
}
```

### 🔹 Énumérations Principales
```swift
enum MasteryLevel: String, Codable, CaseIterable, Identifiable {
    case new, learning, reviewing, mastered
}

enum ReviewRating: String, CaseIterable, Identifiable, Codable {
    case again, hard, good, easy
}

enum CardFilterOption {
    case all, new, learning, reviewing, mastered, due, flagged, difficult
}

enum DeckSortOption: String, CaseIterable, Identifiable {
    case alphabetical, dateCreated, dateModified, cardCount, dueCardCount
}
```

## 🛠️ Services

### 🔹 CardService
Service principal qui gère l'interaction avec les cartes et les paquets :
- Création, lecture, mise à jour et suppression (CRUD) des cartes
- CRUD des paquets
- Récupération des cartes filtrées
- Déplacement des cartes entre paquets
- Mise à jour des données de révision

```swift
class CardService {
    // Méthodes pour les cartes
    func fetchCards(for deck: Deck? = nil) async throws -> [Card]
    func createCard(...) async throws -> Card
    func updateCard(...) async throws -> Card
    func deleteCard(...) async throws
    func moveCard(...) async throws -> Card
    func updateReviewForCard(...) async throws
    
    // Méthodes pour les paquets
    func fetchDecks() async throws -> [Deck]
    func createDeck(...) async throws -> Deck
    func updateDeck(...) async throws -> Deck
    func deleteDeck(...) async throws
    
    // Méthodes pour l'import/export
    func importDeck(from url: URL) async throws -> Deck
    func exportDeck(_ deck: Deck, to url: URL) async throws
    
    // Méthodes pour les sessions d'étude
    func saveStudySession(_ session: StudySession) async throws
}
```

### 🔹 CardScheduler
Service gérant l'algorithme de répétition espacée :
- Calcul des prochaines dates de révision
- Détermination des nouveaux niveaux de maîtrise
- Application des facteurs de difficulté

```swift
class CardScheduler {
    func calculateNextReview(currentLevel: MasteryLevel, rating: ReviewRating, lastReview: Date) -> Date
    func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel
}
```

### 🔹 PersistenceController
Gestion de la persistance des données via CoreData :
- Configuration du conteneur CoreData
- Chargement des données persistantes
- Création du contexte de visualisation

```swift
class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false)
    func saveContext() throws
}
```

### 🔹 CloudSyncService
Gestion de la synchronisation iCloud :
- Configuration de CloudKit
- Synchronisation des modifications
- Résolution des conflits
- Vérification de l'état de synchronisation

```swift
class CloudSyncService {
    static let shared = CloudSyncService()
    
    func checkCloudStatus()
    func forceSynchronization()
    func setupNotifications()
}
```

### 🔹 ImportExportService
Service d'import/export dans différents formats :
- Gestion du format Anki (.apkg)
- Import/export CSV et texte
- Extraction et gestion des médias

```swift
class ImportExportService {
    enum FileFormat { case txt, csv, anki, xml, opml }
    
    func exportDeck(_ deck: Deck, format: FileFormat, to url: URL) throws
    func importDeck(from url: URL, format: FileFormat) throws -> (Deck, [Card])
    func exportToAnki(deck: Deck, cards: [Card], to fileURL: URL, tempDir: URL) throws
    func importFromAnki(url: URL, into context: NSManagedObjectContext) throws -> (Deck, [Card])
}
```

## 📱 ViewModels

### 🔹 CardViewModel
```swift
class CardViewModel: ObservableObject {
    // État publié
    @Published var cards: [Card] = []
    @Published var filteredCards: [Card] = []
    @Published var selectedCard: Card?
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    @Published var filterOption: CardFilterOption = .all
    @Published var searchText: String = ""
    @Published var isAddingCard: Bool = false
    
    // Méthodes
    func fetchCards(for deck: Deck? = nil)
    func addCard(...) async throws
    func updateCard(...) async throws
    func deleteCard(_ card: Card) async throws
    func moveCard(_ card: Card, to deck: Deck) async throws
    private func filterCards(searchText: String, option: CardFilterOption)
    func clearError()
}
```

### 🔹 DeckViewModel
```swift
class DeckViewModel: ObservableObject {
    // État publié
    @Published var decks: [Deck] = []
    @Published var selectedDeck: Deck?
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    @Published var searchText: String = ""
    @Published var isAddingDeck: Bool = false
    @Published var filteredDecks: [Deck] = []
    @Published var sortOption: DeckSortOption = .alphabetical
    
    // Liens avec d'autres ViewModels
    var cardViewModel: CardViewModel?
    
    // Méthodes
    func fetchDecks()
    func addDeck(...) async throws
    func updateDeck(...) async throws
    func deleteDeck(_ deck: Deck) async throws
    func selectDeck(_ deck: Deck?)
    func importDeck(from url: URL) async throws
    func exportDeck(_ deck: Deck, to url: URL) async throws
    private func filterAndSortDecks(...)
    func clearError()
}
```

### 🔹 StudyViewModel
```swift
class StudyViewModel: ObservableObject {
    // État publié
    @Published var currentSession: StudySession?
    @Published var isStudying: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentDeck: Deck?
    @Published var cardsToStudy: [Card] = []
    @Published var currentCardIndex: Int = 0
    @Published var error: StudyError?
    @Published var reviewStartTime: Date?
    @Published var showDeckSelection: Bool = false
    @Published var sessionStats: SessionStats = SessionStats()
    
    // Propriétés calculées
    var currentCard: Card?
    var progress: Double
    var remainingCards: Int
    
    // Méthodes
    func startSession(deckId: UUID)
    func startCardReview()
    func recordReview(rating: ReviewRating)
    func advanceToNextCard()
    func endSession()
    func getStudiedCardsToday() -> [Card]
    func resetError()
    private func setupSession(deckId: UUID, cards: [Card])
}
```

## 🖼️ Vues

### 🔹 ContentView
Vue principale contenant la TabView avec les onglets principaux :
- Paquets (DeckListView)
- Cartes (CardListView)
- Étudier (StudyDashboardView)
- Statistiques (StatisticsView)
- Réglages (SettingsView)

### 🔹 Vues des Paquets
- **DeckListView** : Affiche la liste des paquets avec filtrage et tri.
- **DeckDetailView** : Affiche les détails d'un paquet et ses cartes.
- **AddDeckView** : Formulaire pour créer/modifier un paquet.

### 🔹 Vues des Cartes
- **CardListView** : Affiche la liste des cartes avec filtrage.
- **CardDetailView** : Affiche et permet de modifier les détails d'une carte.
- **AddCardView** : Formulaire pour créer/modifier une carte.

### 🔹 Vues d'Étude
- **StudyDashboardView** : Tableau de bord pour démarrer les sessions d'étude.
- **StudyView** : Interface principale pour réviser les cartes.
- **DeckSelectionView** : Permet de choisir un paquet pour l'étude.

### 🔹 Vues des Statistiques
- **StatisticsView** : Vue principale des statistiques globales.
- **DeckStatsView** : Statistiques détaillées pour un paquet spécifique.

### 🔹 Vues des Paramètres
- **SettingsView** : Vue principale des paramètres de l'application.
- **AppearanceSettings** : Paramètres d'apparence (mode sombre, etc.).
- **StudySettings** : Configuration de l'algorithme d'étude.

## 📝 Implémentation du Rich Text

L'application prend en charge le texte enrichi (rich text) pour les questions et réponses des cartes, permettant aux utilisateurs de créer des contenus plus expressifs et informatifs.

### 🔹 Formats Supportés
- **Texte formaté** : Gras, italique, souligné, barré
- **Listes** : Numérotées et à puces
- **Images** : Intégrées dans le texte
- **Audio** : Clips audio embarqués
- **Vidéo** : Clips vidéo embarqués
- **Tableaux** : Organisation tabulaire des données
- **Code** : Blocs de code avec coloration syntaxique
- **Formules mathématiques** : Notation mathématique via LaTeX

### 🔹 Implémentation
Le rich text est géré principalement via les composants suivants :

#### 🔸 MediaItem
```swift
struct MediaItem: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let type: MediaType
    
    enum MediaType: String {
        case image, audio, video
    }
}
```

#### 🔸 Stockage
- Les médias sont stockés comme des fichiers séparés dans le système de fichiers
- Les références aux médias sont stockées dans le texte avec une syntaxe spéciale
- Le texte formaté est stocké en HTML ou en Markdown (selon la configuration)

#### 🔸 Éditeur
L'application utilise un éditeur de texte riche personnalisé basé sur la combinaison de :
- TextEditor de SwiftUI pour l'édition de base
- Des extensions pour le support de la mise en forme avancée
- Des boutons d'action pour l'insertion de médias et la mise en forme

#### 🔸 Rendu
Le rendu du texte enrichi est géré par :
- Un parser HTML/Markdown personnalisé
- Des composants SwiftUI pour afficher les différents types de contenu
- Des lecteurs médias intégrés pour l'audio et la vidéo

#### 🔸 Import/Export
Le texte enrichi est correctement géré lors de l'import/export :
- Les médias sont extraits/importés avec les cartes
- Les références sont mises à jour pour pointer vers les nouveaux emplacements des médias
- La mise en forme est préservée dans les formats qui la supportent

## ⏱️ Algorithme de Répétition Espacée

L'application utilise un algorithme de répétition espacée sophistiqué pour optimiser l'apprentissage, inspiré par l'algorithme SM-2 utilisé dans Anki.

### 🔹 Niveaux de Maîtrise
Les cartes progressent à travers quatre niveaux de maîtrise :
- **Nouveau** : Cartes jamais étudiées
- **Apprentissage** : Cartes en cours d'apprentissage initial
- **Révision** : Cartes connues nécessitant des révisions périodiques
- **Maîtrisé** : Cartes bien mémorisées avec des intervalles longs

### 🔹 Notations de Révision
À chaque révision, l'utilisateur évalue sa connaissance de la carte :
- **À revoir** : N'a pas pu se souvenir (échec)
- **Difficile** : S'est souvenu avec difficulté
- **Bien** : S'est souvenu correctement après un effort modéré
- **Facile** : S'est souvenu parfaitement sans effort

### 🔹 Calcul des Intervalles
```swift
func calculateNextReview(currentLevel: MasteryLevel, rating: ReviewRating, lastReview: Date) -> Date {
    let baseInterval = baseIntervals[currentLevel] ?? 1.0
    let intervalMultiplier = rating.intervalMultiplier
    let intervalDays = baseInterval * intervalMultiplier
    
    if rating == .again {
        return Date().addingTimeInterval(60 * 10) // 10 minutes
    }
    
    let intervalSeconds = max(0.25, intervalDays) * 24 * 60 * 60
    return Date().addingTimeInterval(intervalSeconds)
}
```

### 🔹 Progression des Niveaux
```swift
func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel {
    switch rating {
    case .again:
        // Régresser si échec
        if currentLevel == .learning { return .new }
        else if currentLevel == .reviewing { return .learning }
        else if currentLevel == .mastered { return .reviewing }
        return .new
        
    case .hard:
        // Maintenir le niveau actuel
        return currentLevel
        
    case .good:
        // Progresser d'un niveau
        if currentLevel == .new { return .learning }
        else if currentLevel == .learning { return .reviewing }
        else if currentLevel == .reviewing { return .mastered }
        return currentLevel
        
    case .easy:
        // Progresser potentiellement de deux niveaux
        if currentLevel == .new { return .reviewing }
        else if currentLevel == .learning || currentLevel == .reviewing { return .mastered }
        return .mastered
    }
}
```

## 🔄 Synchronisation et Persistance

### 🔹 Persistance Locale (CoreData)
L'application utilise CoreData pour la persistance locale des données :

#### 🔸 Entités
- **CardEntity** : Stockage persistant des cartes
- **DeckEntity** : Stockage persistant des paquets
- **StudySessionEntity** : Enregistrement des sessions d'étude

#### 🔸 Configuration
```swift
class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CardsDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Erreur de chargement du CoreData : \(error)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
```

### 🔹 Synchronisation iCloud (CloudKit)
La synchronisation avec iCloud est gérée par CloudKit :

#### 🔸 Configuration
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
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Erreur de chargement CloudKit: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
```

## 🌳 Arborescence Détaillée

```
📂 Cards
│
├── 📄 README.md              # Documentation principale du projet
├── 📄 LICENSE                # Licence MIT
├── 📄 .gitignore             # Configuration Git
│
├── 📂 CardApp               # Dossier principal de l'application
│   │
│   ├── 📄 CardsApp.swift     # 🚀 Point d'entrée de l'application
│   ├── 📄 ContentView.swift  # 📱 Vue principale avec TabView
│   │
│   ├── 📂 Features          # 🧩 Modules fonctionnels
│   │   │
│   │   ├── 📂 Decks         # 📚 Gestion des paquets
│   │   │   ├── 📄 DeckListView.swift
│   │   │   ├── 📄 DeckDetailView.swift
│   │   │   ├── 📄 AddDeckView.swift
│   │   │   └── 📄 DeckViewModel.swift
│   │   │
│   │   ├── 📂 Cards         # 🃏 Gestion des cartes
│   │   │   ├── 📄 CardListView.swift
│   │   │   ├── 📄 CardDetailView.swift
│   │   │   ├── 📄 AddCardView.swift
│   │   │   └── 📄 CardViewModel.swift
│   │   │
│   │   ├── 📂 Study         # 📝 Fonctionnalité d'étude
│   │   │   ├── 📄 StudyDashboardView.swift
│   │   │   ├── 📄 StudyView.swift
│   │   │   ├── 📄 DeckSelectionView.swift
│   │   │   └── 📄 StudyViewModel.swift
│   │   │
│   │   ├── 📂 Statistics    # 📊 Visualisation des statistiques
│   │   │   ├── 📄 StatisticsView.swift
│   │   │   └── 📄 DeckStatsView.swift
│   │   │
│   │   └── 📂 Settings      # ⚙️ Paramètres de l'application
│   │       ├── 📄 SettingsView.swift
│   │       └── 📄 StudySettings.swift
│   │
│   ├── 📂 Core              # 🧠 Composants de base
│   │   │
│   │   ├── 📂 Models        # 📊 Modèles de données
│   │   │   ├── 📄 CardModels.swift
│   │   │   ├── 📄 DeckModels.swift
│   │   │   ├── 📄 StudyModels.swift
│   │   │   ├── 📄 Enums.swift
│   │   │   ├── 📄 ReviewRating.swift
│   │   │   └── 📄 DeckExport.swift
│   │   │
│   │   ├── 📂 Services      # 🔧 Services
│   │   │   ├── 📄 CardService.swift
│   │   │   ├── 📄 CardScheduler.swift
│   │   │   ├── 📄 PersistenceController.swift
│   │   │   ├── 📄 CloudSyncService.swift
│   │   │   ├── 📄 ImportExportService.swift
│   │   │   │
│   │   │   └── 📂 CoreData  # 💾 Modèles CoreData
│   │   │       └── 📄 CoreDataModel.swift
│   │   │
│   │   ├── 📂 Extensions    # 🔌 Extensions Swift
│   │   │   ├── 📄 ColorExtensions.swift
│   │   │   └── 📄 AccessibilityExtensions.swift
│   │   │
│   │   ├── 📂 UI            # 🎨 Composants UI réutilisables
│   │   │   ├── 📄 CardView.swift
│   │   │   ├── 📄 DeckCard.swift
│   │   │   └── 📄 EmptyStateView.swift
│   │   │
│   │   └── 📂 Components    # 🧱 Composants métier réutilisables
│   │       ├── 📄 RatingButtons.swift
│   │       └── 📄 MediaPlayer.swift
│   │
│   ├── 📂 ViewModels        # 🧮 ViewModels globaux
│   │   ├── 📄 CardViewModel.swift
│   │   ├── 📄 DeckViewModel.swift
│   │   └── 📄 StudyViewModel.swift
│   │
│   ├── 📂 Resources         # 🗂️ Ressources statiques
│   │   ├── 📄 README.md
│   │   └── 📄 Documentation.md
│   │
│   ├── 📄 Assets.xcassets     # 🖼️ Catalogue d'actifs
│   └── 📄 CardApp.entitlements # 🔑 Configuration des droits
│
└── 📂 CardApp.xcodeproj     # 📦 Fichier de projet Xcode
```

Cette documentation offre une vision complète de l'application Cards, de son architecture, de ses fonctionnalités et de sa structure. Elle est conçue pour servir de référence aux développeurs qui travaillent sur le projet, ainsi qu'aux nouveaux contributeurs qui souhaitent comprendre rapidement l'organisation et le fonctionnement de l'application. 