#!/bin/bash

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Vérification des dépendances et configurations...${NC}"

# Vérification de Swift
if ! command -v swift &> /dev/null; then
    echo -e "${RED}Erreur: Swift n'est pas installé${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Swift est installé${NC}"
fi

# Vérification de Xcode
if ! xcode-select -p &> /dev/null; then
    echo -e "${RED}Erreur: Xcode n'est pas installé${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Xcode est installé${NC}"
fi

# Vérification des fichiers essentiels
ESSENTIAL_FILES=("Info.plist" "CardApp.entitlements" "swift_files.txt")
for file in "${ESSENTIAL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}Erreur: $file n'existe pas${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ $file existe${NC}"
    fi
done

# Vérification des répertoires essentiels
ESSENTIAL_DIRS=("App" "Core" "Features" "UI" "Resources")
for dir in "${ESSENTIAL_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo -e "${RED}Erreur: Le répertoire $dir n'existe pas${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Le répertoire $dir existe${NC}"
    fi
done

# Vérification des permissions
if [ ! -x "compile.sh" ]; then
    echo -e "${YELLOW}Attention: Le script compile.sh n'est pas exécutable${NC}"
    chmod +x compile.sh
    echo -e "${GREEN}✓ Permissions corrigées pour compile.sh${NC}"
fi

echo -e "${GREEN}Toutes les vérifications sont terminées avec succès!${NC}" 