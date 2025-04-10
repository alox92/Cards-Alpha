# CardApp - Application de Cartes Mémoire

CardApp est une application de cartes mémoire pour macOS et iOS qui permet aux utilisateurs de créer et d'étudier des cartes selon la méthode de répétition espacée.

## Structure du Projet

Le projet est organisé selon une architecture modulaire et évolutive:

### Modules Principaux

- **App**: Point d'entrée de l'application
  - `AppMain.swift`: Structure principale `@main`
  
- **Core**: Éléments fondamentaux de l'application
  - **DI**: Injection de dépendances
    - `DependencyContainer.swift`: Conteneur de services centralisé
  - **Models**: Modèles de données centraux
  - **Persistence**: Gestion de CoreData
  - **Services**: Services métier unifiés
    - **Cards**: `UnifiedCardService`
    - **Decks**: `UnifiedDeckService`
    - **Study**: `UnifiedStudyService`
    - **ImportExport**: `ImportExportService`
    - **Tags**: `TagService`
  - **Utilities**: Utilitaires divers

- **Features**: Modules fonctionnels
  - **Cards**: Gestion des cartes
    - **ViewModels**: `CardViewModel`
    - **Views**: Vues liées aux cartes
  - **Decks**: Gestion des paquets
  - **Study**: Fonctionnalités d'étude
  - **ImportExport**: Import/export de données
  - **Tags**: Gestion des tags
  
- **UI**: Composants UI réutilisables
  - **Components**: `RichTextEditor`, etc.
  
- **Platform**: Code spécifique aux plateformes
  - **macOS**: Code spécifique à macOS
  - **iOS**: Code spécifique à iOS
  - **Shared**: Code partagé entre plateformes

- **Resources**: Ressources visuelles, localisations, etc.

- **Tests**: Tests unitaires et d'intégration

## Patterns Architecturaux

Le projet utilise plusieurs patterns:

1. **MVVM** (Model-View-ViewModel): Séparation des vues (SwiftUI) et de la logique métier (ViewModels)
2. **Service Locator**: Utilisé via le `DependencyContainer` pour l'injection de dépendances
3. **Repository**: Encapsulation des accès aux données via les services
4. **Strategy**: Utilisé pour les algorithmes de répétition espacée
5. **Adapter**: Pour l'intégration de systèmes externes

## Compilation et Exécution

### Prérequis

- Xcode 14.0 ou supérieur
- macOS 12 ou supérieur (pour le développement)
- Swift 5.7 ou supérieur

### Compilation

1. Ouvrez le projet dans Xcode:
   ```
   open CardApp.xcodeproj
   ```

2. Sélectionnez le schéma cible (macOS ou iOS)

3. Compilez le projet (⌘B) ou lancez-le (⌘R)

### Tests

Pour exécuter les tests unitaires:

1. Naviguez vers le navigateur de tests dans Xcode (⌘6)
2. Cliquez sur l'icône de lecture à côté de la cible "CardAppTests"

## Caractéristiques Principales

- Création et gestion de cartes avec prise en charge du texte riche
- Organisation en paquets et tags
- Algorithme de répétition espacée pour optimiser l'apprentissage
- Import/export dans divers formats (CSV, JSON, Anki)
- Interface adaptative pour macOS et iOS
- Sauvegarde et synchronisation des données

## Contribuer

Pour contribuer au projet:

1. Suivez les conventions de codage Swift
2. Ajoutez des tests unitaires pour les nouvelles fonctionnalités
3. Assurez-vous que tous les tests existants passent
4. Soumettez une pull request avec une description claire des changements

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails. 