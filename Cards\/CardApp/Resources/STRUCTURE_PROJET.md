# 🌳 Structure du Projet Cards App

## 📋 Aperçu Général

L'application Cards est organisée selon l'architecture MVVM (Model-View-ViewModel) avec une séparation claire des responsabilités entre les différentes couches.

```
📦 Cards
┣ 📂 CardApp                # Dossier principal de l'application
┃ ┣ 📄 CardsApp.swift       # 🚀 Point d'entrée de l'application
┃ ┣ 📄 ContentView.swift    # 📱 Vue principale avec TabView
┃ ┣ 📂 Features             # 🧩 Modules fonctionnels
┃ ┣ 📂 Core                 # 🧠 Composants de base
┃ ┣ 📂 ViewModels           # 🧮 ViewModels globaux
┃ ┣ 📂 Resources            # 🗂️ Ressources statiques
┃ ┗ 📄 Assets.xcassets      # 🖼️ Catalogue d'actifs
┣ 📂 CardApp.xcodeproj      # 📦 Fichier de projet Xcode
┣ 📄 README.md              # 📝 Documentation principale
┣ 📄 LICENSE                # ⚖️ Licence MIT
┗ 📄 .gitignore             # 🙈 Configuration Git
```

## 🔍 Structure Détaillée

### 📂 Features (Modules fonctionnels)
```
📂 Features
┣ 📂 Decks                  # 📚 Gestion des paquets
┃ ┣ 📄 DeckListView.swift   # 📋 Liste des paquets
┃ ┣ 📄 DeckDetailView.swift # 📖 Détail d'un paquet
┃ ┣ 📄 AddDeckView.swift    # ➕ Ajout d'un paquet
┃ ┗ 📄 EditDeckView.swift   # ✏️ Édition d'un paquet
┣ 📂 Cards                  # 🃏 Gestion des cartes
┃ ┣ 📄 CardListView.swift   # 📋 Liste des cartes
┃ ┣ 📄 CardDetailView.swift # 📖 Détail d'une carte
┃ ┣ 📄 AddCardView.swift    # ➕ Ajout d'une carte
┃ ┗ 📄 EditCardView.swift   # ✏️ Édition d'une carte
┣ 📂 Study                  # 📝 Fonctionnalité d'étude
┃ ┣ 📄 StudyDashboardView.swift # 📊 Tableau de bord d'étude
┃ ┣ 📄 StudyView.swift      # 🎓 Vue d'étude principale
┃ ┣ 📄 ReviewView.swift     # 🔄 Vue de révision
┃ ┗ 📄 ResultsView.swift    # 🏆 Résultats de session
┣ 📂 Statistics             # 📊 Visualisation des statistiques
┃ ┣ 📄 StatisticsView.swift # 📈 Vue générale des statistiques
┃ ┣ 📄 DeckStatsView.swift  # 📊 Stats par paquet
┃ ┗ 📄 LearningGraphsView.swift # 📉 Graphiques d'apprentissage
┗ 📂 Settings               # ⚙️ Paramètres de l'application
  ┣ 📄 SettingsView.swift   # ⚙️ Vue principale des réglages
  ┣ 📄 AppearanceSettings.swift # 🎨 Réglages d'apparence
  ┣ 📄 StudySettings.swift  # 📚 Réglages d'étude
  ┗ 📄 SyncSettings.swift   # 🔄 Réglages de synchronisation
```

### 📂 Core (Composants de base)
```
📂 Core
┣ 📂 Models                 # 📊 Modèles de données
┃ ┣ 📄 CardModels.swift     # 🃏 Modèle de carte
┃ ┣ 📄 DeckModels.swift     # 📚 Modèle de paquet
┃ ┣ 📄 StudyModels.swift    # 📝 Modèles d'étude
┃ ┣ 📄 ReviewRating.swift   # ⭐ Évaluations de révision
┃ ┗ 📄 Enums.swift          # 🔢 Énumérations partagées
┣ 📂 Services               # 🔧 Services
┃ ┣ 📄 CardService.swift    # 🃏 Service de gestion des cartes
┃ ┣ 📄 CardScheduler.swift  # 📅 Planificateur de révision
┃ ┣ 📄 PersistenceController.swift # 💾 Contrôleur de persistance
┃ ┣ 📄 CloudSyncService.swift # ☁️ Service de synchronisation
┃ ┣ 📄 ImportExportService.swift # 📤 Service d'import/export
┃ ┗ 📂 CoreData             # 💽 Modèles CoreData
┃   ┗ 📄 CardsDataModel.xcdatamodeld # 📋 Modèle de données
┣ 📂 Extensions             # 🔌 Extensions Swift
┃ ┣ 📄 ColorExtensions.swift # 🎨 Extensions de couleur
┃ ┣ 📄 DateExtensions.swift # 📅 Extensions de date
┃ ┣ 📄 StringExtensions.swift # 📝 Extensions de chaîne
┃ ┗ 📄 ViewExtensions.swift # 📱 Extensions de vue
┣ 📂 UI                     # 🎨 Composants UI génériques
┃ ┣ 📄 Button.swift         # 🔘 Boutons personnalisés
┃ ┣ 📄 TextField.swift      # ✏️ Champs de texte personnalisés
┃ ┣ 📄 EmptyStateView.swift # 🤷 Vue d'état vide
┃ ┗ 📄 LoadingView.swift    # ⏳ Vue de chargement
┗ 📂 Components             # 🧱 Composants spécifiques
  ┣ 📄 CardView.swift       # 🃏 Vue de carte
  ┣ 📄 DeckCard.swift       # 📚 Carte de paquet
  ┣ 📄 RatingButtons.swift  # ⭐ Boutons d'évaluation
  ┣ 📄 RichTextEditor.swift # 📝 Éditeur de texte riche
  ┗ 📄 MediaPlayer.swift    # 🎵 Lecteur de médias
```

### 📂 ViewModels (ViewModels globaux)
```
📂 ViewModels
┣ 📄 CardViewModel.swift    # 🃏 ViewModel de cartes
┣ 📄 DeckViewModel.swift    # 📚 ViewModel de paquets
┗ 📄 StudyViewModel.swift   # 📝 ViewModel d'étude
```

### 📂 Resources (Ressources statiques)
```
📂 Resources
┣ 📄 README.md              # 📄 Description des ressources
┣ 📄 Documentation.md       # 📚 Documentation technique
┣ 📄 GUIDE_UTILISATEUR.md   # 📘 Guide d'utilisation
┣ 📄 STRUCTURE_PROJET.md    # 🌳 Structure du projet (ce fichier)
┣ 📄 DEVELOPPEMENT.md       # 👨‍💻 Guide de développement
┗ 📂 assets                 # 🖼️ Ressources statiques
  ┣ 📂 images               # 🖼️ Images
  ┣ 📂 fonts                # 🔤 Polices
  ┗ 📂 sounds               # 🔊 Sons
```

## 🔄 Flux de Données

```
👤 Utilisateur
   ↓
📱 Vue (SwiftUI)
   ↓ ↑
🧮 ViewModel (ObservableObject)
   ↓ ↑
🔧 Service
   ↓ ↑
💾 Persistance (CoreData)
   ↕
☁️ Synchronisation (CloudKit)
```

## 🏗️ Conception MVVM

```
📊 Model       - Structures de données et logique métier
📱 View        - Interface utilisateur SwiftUI
🧮 ViewModel   - Logique de présentation et état
🔧 Service     - Accès aux données et opérations
```

## 🔍 Flux d'Utilisation Principaux

### 📚 Gestion des Paquets
```
DeckListView → AddDeckView → DeckDetailView → EditDeckView
```

### 🃏 Gestion des Cartes
```
CardListView → AddCardView → CardDetailView → EditCardView
```

### 🎓 Étude
```
StudyDashboardView → DeckSelectionView → StudyView → ResultsView
```

### 📊 Statistiques
```
StatisticsView → DeckStatsView → LearningGraphsView
```

## 📱 Interface Utilisateur

L'interface principale est organisée en cinq onglets :
```
📚 Paquets      - Gestion des paquets de cartes
🃏 Cartes       - Visualisation et édition des cartes
📝 Étudier      - Sessions d'étude et révision
📊 Statistiques - Suivi des progrès d'apprentissage
⚙️ Réglages     - Configuration de l'application
```

---

# 🌳 Project Structure - Cards App

## 📋 General Overview

The Cards application is organized according to the MVVM (Model-View-ViewModel) architecture with a clear separation of responsibilities between different layers.

```
📦 Cards
┣ 📂 CardApp                # Main application folder
┃ ┣ 📄 CardsApp.swift       # 🚀 Application entry point
┃ ┣ 📄 ContentView.swift    # 📱 Main view with TabView
┃ ┣ 📂 Features             # 🧩 Functional modules
┃ ┣ 📂 Core                 # 🧠 Core components
┃ ┣ 📂 ViewModels           # 🧮 Global ViewModels
┃ ┣ 📂 Resources            # 🗂️ Static resources
┃ ┗ 📄 Assets.xcassets      # 🖼️ Asset catalog
┣ 📂 CardApp.xcodeproj      # 📦 Xcode project file
┣ 📄 README.md              # 📝 Main documentation
┣ 📄 LICENSE                # ⚖️ MIT License
┗ 📄 .gitignore             # 🙈 Git configuration
```

## 🔍 Detailed Structure

### 📂 Features (Functional modules)
```
📂 Features
┣ 📂 Decks                  # 📚 Deck management
┃ ┣ 📄 DeckListView.swift   # 📋 Deck list
┃ ┣ 📄 DeckDetailView.swift # 📖 Deck detail
┃ ┣ 📄 AddDeckView.swift    # ➕ Add deck
┃ ┗ 📄 EditDeckView.swift   # ✏️ Edit deck
┣ 📂 Cards                  # 🃏 Card management
┃ ┣ 📄 CardListView.swift   # 📋 Card list
┃ ┣ 📄 CardDetailView.swift # 📖 Card detail
┃ ┣ 📄 AddCardView.swift    # ➕ Add card
┃ ┗ 📄 EditCardView.swift   # ✏️ Edit card
┣ 📂 Study                  # 📝 Study functionality
┃ ┣ 📄 StudyDashboardView.swift # 📊 Study dashboard
┃ ┣ 📄 StudyView.swift      # 🎓 Main study view
┃ ┣ 📄 ReviewView.swift     # 🔄 Review view
┃ ┗ 📄 ResultsView.swift    # 🏆 Session results
┣ 📂 Statistics             # 📊 Statistics visualization
┃ ┣ 📄 StatisticsView.swift # 📈 General statistics view
┃ ┣ 📄 DeckStatsView.swift  # 📊 Deck stats
┃ ┗ 📄 LearningGraphsView.swift # 📉 Learning graphs
┗ 📂 Settings               # ⚙️ Application settings
  ┣ 📄 SettingsView.swift   # ⚙️ Main settings view
  ┣ 📄 AppearanceSettings.swift # 🎨 Appearance settings
  ┣ 📄 StudySettings.swift  # 📚 Study settings
  ┗ 📄 SyncSettings.swift   # 🔄 Sync settings
```

### 📂 Core (Core components)
```
📂 Core
┣ 📂 Models                 # 📊 Data models
┃ ┣ 📄 CardModels.swift     # 🃏 Card model
┃ ┣ 📄 DeckModels.swift     # 📚 Deck model
┃ ┣ 📄 StudyModels.swift    # 📝 Study models
┃ ┣ 📄 ReviewRating.swift   # ⭐ Review ratings
┃ ┗ 📄 Enums.swift          # 🔢 Shared enumerations
┣ 📂 Services               # 🔧 Services
┃ ┣ 📄 CardService.swift    # 🃏 Card management service
┃ ┣ 📄 CardScheduler.swift  # 📅 Review scheduler
┃ ┣ 📄 PersistenceController.swift # 💾 Persistence controller
┃ ┣ 📄 CloudSyncService.swift # ☁️ Synchronization service
┃ ┣ 📄 ImportExportService.swift # 📤 Import/export service
┃ ┗ 📂 CoreData             # 💽 CoreData models
┃   ┗ 📄 CardsDataModel.xcdatamodeld # 📋 Data model
┣ 📂 Extensions             # 🔌 Swift extensions
┃ ┣ 📄 ColorExtensions.swift # 🎨 Color extensions
┃ ┣ 📄 DateExtensions.swift # 📅 Date extensions
┃ ┣ 📄 StringExtensions.swift # 📝 String extensions
┃ ┗ 📄 ViewExtensions.swift # 📱 View extensions
┣ 📂 UI                     # 🎨 Generic UI components
┃ ┣ 📄 Button.swift         # 🔘 Custom buttons
┃ ┣ 📄 TextField.swift      # ✏️ Custom text fields
┃ ┣ 📄 EmptyStateView.swift # 🤷 Empty state view
┃ ┗ 📄 LoadingView.swift    # ⏳ Loading view
┗ 📂 Components             # 🧱 Specific components
  ┣ 📄 CardView.swift       # 🃏 Card view
  ┣ 📄 DeckCard.swift       # 📚 Deck card
  ┣ 📄 RatingButtons.swift  # ⭐ Rating buttons
  ┣ 📄 RichTextEditor.swift # 📝 Rich text editor
  ┗ 📄 MediaPlayer.swift    # 🎵 Media player
```

### 📂 ViewModels (Global ViewModels)
```
📂 ViewModels
┣ 📄 CardViewModel.swift    # 🃏 Card ViewModel
┣ 📄 DeckViewModel.swift    # 📚 Deck ViewModel
┗ 📄 StudyViewModel.swift   # 📝 Study ViewModel
```

### 📂 Resources (Static resources)
```
📂 Resources
┣ 📄 README.md              # 📄 Resources description
┣ 📄 Documentation.md       # 📚 Technical documentation
┣ 📄 GUIDE_UTILISATEUR.md   # 📘 User guide
┣ 📄 STRUCTURE_PROJET.md    # 🌳 Project structure (this file)
┣ 📄 DEVELOPPEMENT.md       # 👨‍💻 Development guide
┗ 📂 assets                 # 🖼️ Static assets
  ┣ 📂 images               # 🖼️ Images
  ┣ 📂 fonts                # 🔤 Fonts
  ┗ 📂 sounds               # 🔊 Sounds
```

## 🔄 Data Flow

```
👤 User
   ↓
📱 View (SwiftUI)
   ↓ ↑
🧮 ViewModel (ObservableObject)
   ↓ ↑
🔧 Service
   ↓ ↑
💾 Persistence (CoreData)
   ↕
☁️ Synchronization (CloudKit)
```

## 🏗️ MVVM Design

```
📊 Model       - Data structures and business logic
📱 View        - User interface (SwiftUI)
🧮 ViewModel   - Presentation logic and state
🔧 Service     - Data access and operations
```

## 🔍 Main Usage Flows

### 📚 Deck Management
```
DeckListView → AddDeckView → DeckDetailView → EditDeckView
```

### 🃏 Card Management
```
CardListView → AddCardView → CardDetailView → EditCardView
```

### 🎓 Study
```
StudyDashboardView → DeckSelectionView → StudyView → ResultsView
```

### 📊 Statistics
```
StatisticsView → DeckStatsView → LearningGraphsView
```

## 📱 User Interface

The main interface is organized into five tabs:
```
📚 Decks        - Deck management
🃏 Cards        - Card visualization and editing
📝 Study        - Study sessions and review
📊 Statistics   - Learning progress tracking
⚙️ Settings     - Application configuration
``` 