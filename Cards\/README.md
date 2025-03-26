# Cards App

Application macOS moderne pour la création et la révision de cartes mémoire, inspirée par Anki mais avec une interface native SwiftUI.

## 🚀 Caractéristiques

- ✅ Création de paquets et cartes mémoire
- ✅ Algorithme de répétition espacée
- ✅ Support du format riche pour les cartes (texte, images, audio)
- ✅ Support de pièces jointes médias
- ✅ Interface utilisateur native SwiftUI pour macOS
- ✅ Mode sombre/clair
- ✅ Statistiques d'apprentissage détaillées
- ✅ Import/Export de paquets
- ✅ Synchronisation iCloud entre appareils
- ✅ Sauvegarde et restauration

## 🛠️ Technologies

- Swift 6.0
- SwiftUI
- Core Data
- CloudKit
- Combine

## 📊 Architecture

L'application suit l'architecture MVVM (Model-View-ViewModel) avec une structure organisée en modules :

- **Core** : Modèles, services et composants réutilisables
- **Features** : Fonctionnalités spécifiques (paquets, cartes, étude, statistiques)
- **UI** : Composants d'interface utilisateur génériques
- **Resources** : Ressources statiques comme les images et configurations

## 🧩 Structure de code

```
Cards/
├── CardApp/              # Code source principal
│   ├── CardsApp.swift    # Point d'entrée de l'application
│   ├── ContentView.swift # Vue principale de l'application
│   ├── Features/         # Modules fonctionnels
│   │   ├── Cards/        # Gestion des cartes
│   │   ├── Decks/        # Gestion des paquets
│   │   ├── Study/        # Fonctionnalité d'étude
│   │   ├── Statistics/   # Visualisation des statistiques
│   │   └── Settings/     # Paramètres de l'application
│   ├── Core/             # Composants de base
│   │   ├── Models/       # Modèles de données
│   │   ├── Services/     # Services (persistance, sync, etc)
│   │   │   └── CoreData/ # Modèles CoreData
│   │   ├── Extensions/   # Extensions Swift
│   │   ├── UI/           # Composants UI réutilisables
│   │   └── Components/   # Composants métier réutilisables
│   ├── ViewModels/       # ViewModels globaux
│   ├── Resources/        # Ressources statiques
│   └── Assets.xcassets   # Catalogue d'actifs
└── CardApp.xcodeproj/    # Fichier de projet Xcode
```

## 🚀 Démarrage

### Prérequis

- macOS 14.0 (Sonoma) ou plus récent
- Xcode 16.0 ou plus récent

### Installation

1. Cloner le dépôt
   ```bash
   git clone https://github.com/votre-nom/cards.git
   ```

2. Ouvrir le projet dans Xcode
   ```bash
   cd cards
   open CardApp.xcodeproj
   ```

3. Compiler et lancer l'application

## 📝 License

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails. 