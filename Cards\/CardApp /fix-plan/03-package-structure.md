# Correction de la structure du projet pour Swift Package Manager

## Problèmes identifiés
1. Le projet utilise un script de compilation personnalisé au lieu de Swift Package Manager
2. Les structures de modules ne sont pas correctement organisées
3. Les importations entre modules sont incorrectes

## Structure de Package actuelle
```swift
let package = Package(
    name: "CardApp",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Core",
            type: .dynamic,
            targets: ["Core"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Core",
            dependencies: [],
            path: "Core",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "App",
            dependencies: ["Core"],
            path: "App",
            resources: [
                .process("../Resources")
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests"
        )
    ]
)
```

## Actions pour corriger la structure

### 1. Vérifier et corriger le fichier Package.swift
- S'assurer que les ressources et dépendances sont correctement définies
- Vérifier que les chemins de tous les targets sont corrects

### 2. Corriger les imports dans les fichiers source
- Dans les fichiers App/*.swift, utiliser `import Core` pour accéder aux types/fonctions du module Core
- S'assurer qu'il n'y a pas d'imports circulaires entre les modules

### 3. Organiser les fichiers dans la structure de répertoires correcte
- Core/
  - Models/
  - Services/
  - Protocols/
  - Common/
  - Resources/
- App/
  - Views/
  - ViewModels/
  - Resources/
- Tests/
  - CoreTests/

### 4. Remplacer le script de compilation par des commandes SPM
- Au lieu d'utiliser compile.sh, utiliser directement `swift build`
- Pour les tests, utiliser `swift test`
- Pour exécuter l'application, utiliser `swift run App`

## Étapes de mise en œuvre

1. Vérifier que Swift Package Manager est correctement installé et configuré:
```bash
swift --version
```

2. Tester la compilation du package avec SPM:
```bash
swift build
```

3. Analyser les erreurs produites par SPM et les corriger une par une:
   - Résoudre d'abord les problèmes d'importation
   - Puis résoudre les problèmes de structure de fichiers
   - Enfin, résoudre les problèmes de configuration du package

4. Une fois que le package compile correctement, mettre à jour les scripts de build:
```bash
echo '#!/bin/bash' > build-spm.sh
echo 'swift build $@' >> build-spm.sh
chmod +x build-spm.sh
```

5. Tester l'application compilée:
```bash
swift run App
``` 