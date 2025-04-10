# Guide des Imports et Modules dans CardApp

## Problématique

Le projet CardApp utilise une architecture modulaire avec plusieurs sous-modules et namespaces. Les problèmes d'imports et de références aux types sont parmi les causes les plus fréquentes d'erreurs de compilation et d'ambiguïtés.

Ce guide explique la structure des modules, les bonnes pratiques d'import, et comment résoudre les problèmes courants.

## Structure des Modules

CardApp est organisé selon la structure suivante :

```
Core
├── Common/              # Types et définitions communs
│   ├── Types.swift      # Définition de ReviewRating, etc.
│   ├── Errors.swift     # Définition de StudyServiceError, etc.
│   └── ...
├── Models/              # Modèles de données
│   ├── Common/          # Types communs pour les modèles
│   │   ├── Enums.swift  # Définition de MasteryLevel, etc.
│   │   └── ...
│   └── ...
├── Persistence/         # Couche de persistance
│   ├── PersistenceController.swift
│   └── ...
└── ...
```

## Règles d'Importation Correctes

### 1. Importation du Module Principal

Pour accéder aux namespaces principaux :

```swift
import Core
```

Cette importation vous donne accès aux namespaces `Core.Models`, `Core.Common`, etc., mais pas directement aux types contenus dans ces namespaces.

### 2. Accès aux Types Spécifiques

Pour accéder à des types spécifiques, utilisez la qualification complète :

```swift
// Correct
let rating: Core.Common.ReviewRating = .good
let level: Core.Models.Common.MasteryLevel = .expert
```

### 3. Éviter les Imports Directs vers les Sous-modules

Évitez les imports directs vers les sous-modules qui ne sont pas correctement exportés :

```swift
// À ÉVITER
import Core.Common           // ❌ Import problématique
import Core.Models.Common    // ❌ Import problématique

// PRÉFÉRER
import Core                  // ✅ Import correct
```

## Problèmes Courants et Solutions

### 1. Erreur "No such module 'Core.Common'"

**Problème :** 
```swift
import Core.Common  // Erreur: No such module 'Core.Common'
```

**Solution :**
```swift
import Core  // Import du module principal

// Puis utiliser la qualification complète
let error: Core.Common.StudyServiceError = .sessionNotFound
```

### 2. Ambiguïté avec 'ReviewRating'

**Problème :** 
```
'ReviewRating' is ambiguous for type lookup in this context
```

**Solution :**
1. Utiliser la qualification complète :
```swift
let rating: Core.Common.ReviewRating = .good
```

2. Éviter de redéclarer le type dans plusieurs fichiers.

### 3. Ambiguïté avec 'PersistenceController'

**Problème :**
```
'PersistenceController' is ambiguous for type lookup in this context
```

**Solution :**
```swift
// Utiliser la qualification complète
let controller: Core.Persistence.PersistenceController = ...
```

## Outils de Diagnostic et Correction

Le projet CardApp inclut des outils pour diagnostiquer et corriger les problèmes d'imports :

### 1. Vérification des Imports

```bash
./analysis_tools/verify_imports.sh
```

Ce script analyse le projet et génère un rapport détaillé des problèmes d'imports.

### 2. Correction Automatique des Imports

```bash
./analysis_tools/fix_module_imports.sh
```

Ce script tente de corriger automatiquement les problèmes d'imports courants.

## Bonnes Pratiques

1. **Évitez les redéfinitions de types :** Ne définissez pas le même type (enum, struct, class) à plusieurs endroits.

2. **Préférez les qualifications complètes :** Utilisez toujours le chemin complet pour les types ambigus.

3. **Structurez clairement vos imports :** Groupez les imports par catégorie et maintenez une cohérence.

4. **Vérifiez régulièrement les imports :** Utilisez les outils de diagnostic pour détecter les problèmes potentiels.

5. **Documentation :** Commentez les imports complexes pour clarifier leur utilité.

## Cas Particulier : Modules Swift et Sous-modules

Swift ne prend pas en charge nativement les sous-modules. Les expressions comme `Core.Common` dans un `import` sont en fait une convention de nommage et non une hiérarchie de modules réelle.

Pour que les imports fonctionnent correctement, il faut que la structure du projet (comme définie dans le fichier de projet Xcode ou le Package.swift) corresponde à la convention de nommage utilisée dans les imports.

## Ressources Additionnelles

- [Documentation Swift sur les imports](https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html)
- [Swift Evolution: Improving Import Declarations](https://forums.swift.org/t/improving-import-declarations/21620)
- [Managing Module Dependencies in Swift](https://swift.org/package-manager) 