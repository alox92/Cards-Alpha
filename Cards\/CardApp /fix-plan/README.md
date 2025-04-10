# Plan de correction pour l'application CardApp

## Problèmes identifiés

1. **Duplications de définitions de types**:
   - Plusieurs définitions pour `Card`, `Deck`, `CardFilterOptions`, `ReviewRating`, `DeckStudyStats`, et `CardStudyStats` dans différents fichiers.
   - Fichiers concernés: 
     - `Core/Models/BaseModels.swift`
     - `Core/Models/Card.swift`
     - `Core/Models/Deck.swift`
     - `Core/Common/Types.swift`
     - `Core/Models/CardFilterOptions.swift`
     - `Core/Models/Study/DeckStudyStats.swift`
     - `Core/Services/Unified/UnifiedStudyService.swift`

2. **Redéclarations de protocoles**:
   - Plusieurs définitions pour `CardServiceProtocol`, `DeckServiceProtocol`, `StudyServiceProtocol`, `TagServiceProtocol` et `PersistenceControllerProtocol`.
   - Fichiers concernés:
     - `Core/Models/Common/ServiceProtocols.swift`
     - `Core/Protocols/Services/CardServiceProtocol.swift`
     - `Core/Protocols/Services/DeckServiceProtocol.swift`
     - `Core/Protocols/Services/StudyServiceProtocol.swift`
     - `Core/Protocols/Services/TagServiceProtocol.swift`
     - `Core/Services/Unified/UnifiedCardService.swift`
     - `Core/Services/Unified/UnifiedDeckService.swift`
     - `Core/Services/Unified/UnifiedTagService.swift`
     - `Core/Services/Unified/UnifiedStudyService.swift`
     - `Core/Persistence/PersistenceController.swift`

3. **Problème de structure de projet**:
   - Le projet ne suit pas correctement la structure d'un package Swift
   - Le script de compilation ne tient pas compte de la structure modulaire définie dans `Package.swift`

## Plan de correction

1. **Résoudre les duplications de types**:
   - Conserver une seule définition de chaque type et supprimer ou renommer les autres.
   - Pour chaque type duplicaté:
     - Garder la définition la plus complète/à jour
     - Supprimer les autres définitions
     - Mettre à jour les imports dans les fichiers qui utilisent ces types

2. **Résoudre les redéclarations de protocoles**:
   - Conserver une seule définition de chaque protocole
   - Centraliser les définitions des protocoles dans `Core/Protocols/`
   - Supprimer les définitions duplicaées
   - Mettre à jour les imports

3. **Corriger la structure de projet**:
   - Utiliser Swift Package Manager pour la compilation au lieu du script personnalisé
   - S'assurer que le fichier `Package.swift` est correctement configuré
   - Corriger les importations entre les modules
   - Réorganiser les fichiers si nécessaire pour suivre la structure du package

## Exécution du plan

Pour chaque étape:

1. Identifier les fichiers à modifier/supprimer
2. Faire les modifications nécessaires
3. Tester la compilation avec Swift Package Manager
4. Itérer jusqu'à ce que la compilation réussisse

## Étapes spécifiques

1. Commencer par simplifier le projet en résolvant les définitions dupliquées de types
2. Ensuite, centraliser les définitions de protocoles
3. Enfin, corriger la structure du projet pour qu'elle suive le design du package 