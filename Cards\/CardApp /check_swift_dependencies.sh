#!/bin/bash

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Vérification des dépendances Swift...${NC}"

# Vérification des frameworks requis
REQUIRED_FRAMEWORKS=("Foundation" "SwiftUI" "Combine" "CoreData")
for framework in "${REQUIRED_FRAMEWORKS[@]}"; do
    if swiftc -framework "$framework" -v 2>&1 | grep -q "error"; then
        echo -e "${RED}Erreur: Framework $framework non trouvé${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Framework $framework disponible${NC}"
    fi
done

# Vérification des modules Swift
REQUIRED_MODULES=("SwiftUI" "Combine" "CoreData")
for module in "${REQUIRED_MODULES[@]}"; do
    echo -e "${YELLOW}Vérification du module $module...${NC}"
    if ! swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -import-objc-header - -v 2>&1 | grep -q "$module"; then
        echo -e "${RED}Erreur: Module $module non disponible${NC}"
        echo -e "${RED}Commande exécutée: swiftc -import-objc-header - -v 2>&1 | grep -q \"$module\"${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Module $module disponible${NC}"
    fi
    echo -e "${YELLOW}Fin de la vérification du module $module${NC}"
done

# Vérification des outils Swift
REQUIRED_TOOLS=("swiftc" "swift" "swift-build" "swift-package")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}Erreur: Outil $tool non installé${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Outil $tool disponible${NC}"
    fi
done

# Vérification des permissions des répertoires
REQUIRED_DIRS=("App" "Core" "Features" "UI" "Resources")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -w "$dir" ]; then
        echo -e "${RED}Erreur: Pas d'accès en écriture sur $dir${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Accès en écriture sur $dir${NC}"
    fi
done

# Vérification de la configuration Swift
if [ ! -f "Package.swift" ]; then
    echo -e "${YELLOW}Attention: Package.swift non trouvé${NC}"
    echo -e "${YELLOW}Création d'un fichier Package.swift minimal...${NC}"
    cat > Package.swift << EOF
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "CardApp",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "CardApp", targets: ["CardApp"])
    ],
    targets: [
        .executableTarget(
            name: "CardApp",
            dependencies: [],
            path: "."
        )
    ]
)
EOF
    echo -e "${GREEN}✓ Package.swift créé${NC}"
fi

echo -e "${GREEN}Vérification des dépendances Swift terminée!${NC}" 