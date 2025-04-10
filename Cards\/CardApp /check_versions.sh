#!/bin/bash

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Vérification des versions des dépendances...${NC}"

# Vérification de la version de Swift
SWIFT_VERSION=$(swift --version | head -n 1)
if [[ $SWIFT_VERSION == *"5."* ]]; then
    echo -e "${GREEN}✓ Version Swift compatible: $SWIFT_VERSION${NC}"
else
    echo -e "${RED}Erreur: Version Swift incompatible: $SWIFT_VERSION${NC}"
    echo -e "${YELLOW}Version requise: Swift 5.x${NC}"
    exit 1
fi

# Vérification de la version de Xcode
XCODE_VERSION=$(xcodebuild -version | head -n 1)
if [[ $XCODE_VERSION == *"Xcode"* ]]; then
    echo -e "${GREEN}✓ Xcode installé: $XCODE_VERSION${NC}"
else
    echo -e "${RED}Erreur: Xcode non détecté${NC}"
    exit 1
fi

# Vérification de la version de macOS
MACOS_VERSION=$(sw_vers -productVersion)
if [[ $MACOS_VERSION == 12.* || $MACOS_VERSION == 13.* ]]; then
    echo -e "${GREEN}✓ Version macOS compatible: $MACOS_VERSION${NC}"
else
    echo -e "${YELLOW}Attention: Version macOS non optimale: $MACOS_VERSION${NC}"
    echo -e "${YELLOW}Versions recommandées: macOS 12.x ou 13.x${NC}"
fi

# Vérification de l'architecture
ARCH=$(uname -m)
if [[ $ARCH == "arm64" ]]; then
    echo -e "${GREEN}✓ Architecture compatible: $ARCH${NC}"
else
    echo -e "${YELLOW}Attention: Architecture non optimale: $ARCH${NC}"
    echo -e "${YELLOW}Architecture recommandée: arm64${NC}"
fi

# Vérification de l'espace disque
DISK_SPACE=$(df -h . | awk 'NR==2 {print $4}')
echo -e "${GREEN}✓ Espace disque disponible: $DISK_SPACE${NC}"

# Vérification de la mémoire disponible
MEMORY=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
MEMORY_GB=$(echo "scale=2; $MEMORY * 4096 / 1024 / 1024 / 1024" | bc)
if (( $(echo "$MEMORY_GB > 4" | bc -l) )); then
    echo -e "${GREEN}✓ Mémoire disponible suffisante: ${MEMORY_GB}GB${NC}"
else
    echo -e "${YELLOW}Attention: Mémoire disponible faible: ${MEMORY_GB}GB${NC}"
fi

echo -e "${GREEN}Vérification des versions terminée!${NC}"

echo "Vérification des versions Swift et SDK..."
swift --version
xcrun --show-sdk-path
xcrun --show-sdk-version
echo "Version du SDK: $(xcrun --show-sdk-platform-version)"
echo "Dépendances:"
cat Package.resolved

# Vérifier les avertissements de compilation
echo "Essai de compilation avec plus de détails sur les erreurs..."
swift build -v 2> build_errors.log
echo "Erreurs de compilation enregistrées dans build_errors.log"