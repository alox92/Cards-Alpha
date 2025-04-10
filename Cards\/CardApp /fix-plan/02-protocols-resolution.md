# Résolution des redéclarations de protocoles

## Protocoles à résoudre

### 1. CardServiceProtocol
- Garder la définition dans `Core/Protocols/Services/CardServiceProtocol.swift`
- Supprimer les définitions dans:
  - `Core/Models/Common/ServiceProtocols.swift`
  - `Core/Services/Unified/UnifiedCardService.swift`

### 2. DeckServiceProtocol
- Garder la définition dans `Core/Protocols/Services/DeckServiceProtocol.swift`
- Supprimer les définitions dans:
  - `Core/Models/Common/ServiceProtocols.swift`
  - `Core/Services/Unified/UnifiedDeckService.swift`

### 3. StudyServiceProtocol
- Garder la définition dans `Core/Protocols/Services/StudyServiceProtocol.swift`
- Supprimer les définitions dans:
  - `Core/Services/Unified/UnifiedStudyService.swift`

### 4. TagServiceProtocol
- Garder la définition dans `Core/Protocols/Services/TagServiceProtocol.swift`
- Supprimer les définitions dans:
  - `Core/Models/Common/ServiceProtocols.swift`
  - `Core/Services/Unified/UnifiedTagService.swift`

### 5. PersistenceControllerProtocol
- Garder la définition dans `Core/Persistence/PersistenceController.swift`
- Supprimer les définitions dans:
  - `Core/Models/Common/ServiceProtocols.swift`
  - `Core/Models/BaseModels.swift`

## Actions supplémentaires
- Vérifier et mettre à jour les imports pour tous les fichiers qui utilisent ces protocoles
- S'assurer que les classes d'implémentation suivent toujours les protocoles après ces changements

## Étapes de mise en œuvre

1. Pour chaque protocole, vérifier les différences entre les implémentations:
```bash
diff Core/Protocols/Services/CardServiceProtocol.swift Core/Models/Common/ServiceProtocols.swift
```

2. Identifier si des méthodes/propriétés doivent être ajoutées au protocole canonique pour préserver la fonctionnalité

3. Supprimer les définitions dupliquées

4. Rechercher les fichiers qui utilisent ces protocoles:
```bash
grep -r "import.*ServiceProtocols" --include="*.swift" .
grep -r "CardServiceProtocol" --include="*.swift" .
```

5. Mettre à jour les imports et les références dans ces fichiers

6. Tester la compilation après chaque ensemble de changements 