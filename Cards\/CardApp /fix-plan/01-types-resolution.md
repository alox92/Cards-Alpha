# Résolution des duplications de types

## Types à résoudre

### 1. Card
- Garder la définition dans `Core/Models/Card.swift`
- Supprimer les définitions dans:
  - `Core/Models/BaseModels.swift`

### 2. Deck
- Garder la définition dans `Core/Models/Deck.swift`
- Supprimer les définitions dans:
  - `Core/Models/BaseModels.swift`

### 3. CardFilterOptions
- Garder la définition dans `Core/Common/Types.swift`
- Supprimer ou renommer la définition dans:
  - `Core/Models/CardFilterOptions.swift` -> Renommer en `ExtendedCardFilterOptions`

### 4. ReviewRating
- Garder la définition dans `Core/Common/Types.swift` (avec type de base `Int`)
- Supprimer les définitions dans:
  - `Core/Models/BaseModels.swift` (avec type de base `String`)

### 5. DeckStudyStats
- Garder la définition dans `Core/Models/Study/DeckStudyStats.swift`
- Supprimer les définitions dans:
  - `Core/Models/BaseModels.swift`
  - `Core/Services/Unified/UnifiedStudyService.swift` -> Renommer en `UnifiedDeckStudyStats`

### 6. CardStudyStats
- Garder la définition dans `Core/Models/Study/DeckStudyStats.swift`
- Supprimer les définitions dans:
  - `Core/Models/BaseModels.swift`
  - `Core/Services/Unified/UnifiedStudyService.swift` -> Renommer en `UnifiedCardStudyStats`

## Étapes de mise en œuvre

1. Créer des liens symboliques temporaires pour préserver les références
```bash
# Exemple pour Card
ln -sf Core/Models/Card.swift Core/Models/Card.swift.canonical
```

2. Modifier les fichiers pour supprimer ou renommer les définitions dupliquées

3. Rechercher et remplacer les importations qui pourraient être affectées:
```bash
grep -r "import.*BaseModels" --include="*.swift" .
```

4. Supprimer les liens symboliques une fois les modifications terminées

5. Tester la compilation après chaque ensemble de changements pour identifier et corriger les problèmes introduits 