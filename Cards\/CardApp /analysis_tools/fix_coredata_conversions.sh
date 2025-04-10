#!/bin/bash

# Couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="backups_coredata_conversions_$(date +%Y%m%d_%H%M%S)"
UNIFIED_CARD_SERVICE="Core/Services/Unified/UnifiedCardService.swift"
UNIFIED_DECK_SERVICE="Core/Services/Unified/UnifiedDeckService.swift"
UNIFIED_STUDY_SERVICE="Core/Services/Unified/UnifiedStudyService.swift"

# Création du répertoire de sauvegarde
mkdir -p "$BACKUP_DIR"
echo -e "${GREEN}Répertoire de sauvegarde créé: $BACKUP_DIR${NC}"

# Fonction de sauvegarde des fichiers
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        echo -e "${GREEN}✓ Fichier sauvegardé: $file${NC}"
    else
        echo -e "${RED}✗ Fichier non trouvé: $file${NC}"
        return 1
    fi
}

# Fonction pour corriger les références qualifiées dans les conversions
fix_qualified_references() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ Impossible de corriger les références dans $file (fichier non trouvé)${NC}"
        return 1
    fi
    
    # Sauvegarde du fichier avant modification
    backup_file "$file"
    
    # Correction des références qualifiées dans les conversions
    echo -e "${YELLOW}Correction des références qualifiées dans $file${NC}"
    
    # Remplacer Core.Models.Common.MasteryLevel par MasteryLevel
    if grep -q "Core\.Models\.Common\.MasteryLevel" "$file"; then
        sed -i '' 's/Core\.Models\.Common\.MasteryLevel/MasteryLevel/g' "$file"
        echo -e "${GREEN}✓ Références à Core.Models.Common.MasteryLevel corrigées${NC}"
    fi
    
    # Remplacer Core.Models.Common.StudyServiceError par StudyServiceError
    if grep -q "Core\.Models\.Common\.StudyServiceError" "$file"; then
        sed -i '' 's/Core\.Models\.Common\.StudyServiceError/StudyServiceError/g' "$file"
        echo -e "${GREEN}✓ Références à Core.Models.Common.StudyServiceError corrigées${NC}"
    fi
    
    # Remplacer Core.Models.Common.ReviewRating par ReviewRating
    if grep -q "Core\.Models\.Common\.ReviewRating" "$file"; then
        sed -i '' 's/Core\.Models\.Common\.ReviewRating/ReviewRating/g' "$file"
        echo -e "${GREEN}✓ Références à Core.Models.Common.ReviewRating corrigées${NC}"
    fi
    
    # Ajouter des imports manquants si nécessaire
    if ! grep -q "import Core.Models.Common" "$file" && ! grep -q "import Core.Common" "$file"; then
        # Ajouter l'import après la ligne import Foundation
        sed -i '' '/import Foundation/a\
import Core.Common
' "$file"
        echo -e "${GREEN}✓ Import Core.Common ajouté${NC}"
    fi
    
    return 0
}

# Fonction pour corriger le mappage de noms de paramètres dans les conversions
fix_parameter_names() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ Impossible de corriger les noms de paramètres dans $file (fichier non trouvé)${NC}"
        return 1
    fi
    
    # Sauvegarde du fichier avant modification
    backup_file "$file"
    
    # Correction des noms de paramètres avec des chemins qualifiés
    echo -e "${YELLOW}Correction des noms de paramètres avec des chemins qualifiés dans $file${NC}"
    
    # Remplacer newCore.Models.Common.MasteryLevel par newMasteryLevel
    if grep -q "newCore\.Models\.Common\.MasteryLevel" "$file"; then
        sed -i '' 's/newCore\.Models\.Common\.MasteryLevel/newMasteryLevel/g' "$file"
        echo -e "${GREEN}✓ Noms de paramètres avec newCore.Models.Common.MasteryLevel corrigés${NC}"
    fi
    
    # Remplacer calculateNewCore.Models.Common.MasteryLevel par calculateNewMasteryLevel
    if grep -q "calculateNewCore\.Models\.Common\.MasteryLevel" "$file"; then
        sed -i '' 's/calculateNewCore\.Models\.Common\.MasteryLevel/calculateNewMasteryLevel/g' "$file"
        echo -e "${GREEN}✓ Méthodes avec calculateNewCore.Models.Common.MasteryLevel corrigées${NC}"
    fi
    
    return 0
}

# Fonction pour corriger la syntaxe de Task et DispatchQueue
fix_task_syntax() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ Impossible de corriger la syntaxe de Task dans $file (fichier non trouvé)${NC}"
        return 1
    fi
    
    # Sauvegarde du fichier avant modification
    backup_file "$file"
    
    # Correction de la syntaxe de Task sans @MainActor
    echo -e "${YELLOW}Correction de la syntaxe de Task dans $file${NC}"
    
    # Remplacer Task { ... } par Task { @MainActor [weak self] in ... }
    if grep -q "Task {" "$file" && ! grep -q "Task { @MainActor \[weak self\] in" "$file"; then
        sed -i '' 's/Task {/Task { @MainActor [weak self] in/g' "$file"
        echo -e "${GREEN}✓ Syntaxe de Task corrigée avec @MainActor et [weak self]${NC}"
    fi
    
    # Remplacer DispatchQueue.main.async { ... } par DispatchQueue.main.async { [weak self] in ... }
    if grep -q "DispatchQueue\.main\.async {" "$file" && ! grep -q "DispatchQueue\.main\.async { \[weak self\] in" "$file"; then
        sed -i '' 's/DispatchQueue\.main\.async {/DispatchQueue\.main\.async { [weak self] in/g' "$file"
        echo -e "${GREEN}✓ Syntaxe de DispatchQueue.main.async corrigée avec [weak self]${NC}"
    fi
    
    return 0
}

# Fonction principale pour corriger les conversions CoreData
main() {
    echo -e "${BLUE}=== Correction des conversions CoreData vers modèles ===${NC}"
    
    # Correction des références qualifiées
    echo -e "${BLUE}Correction des références qualifiées dans les services...${NC}"
    fix_qualified_references "$UNIFIED_CARD_SERVICE"
    fix_qualified_references "$UNIFIED_DECK_SERVICE"
    fix_qualified_references "$UNIFIED_STUDY_SERVICE"
    
    # Correction des noms de paramètres
    echo -e "\n${BLUE}Correction des noms de paramètres dans les services...${NC}"
    fix_parameter_names "$UNIFIED_CARD_SERVICE"
    fix_parameter_names "$UNIFIED_DECK_SERVICE"
    fix_parameter_names "$UNIFIED_STUDY_SERVICE"
    
    # Correction de la syntaxe de Task
    echo -e "\n${BLUE}Correction de la syntaxe de Task dans les services...${NC}"
    fix_task_syntax "$UNIFIED_CARD_SERVICE"
    fix_task_syntax "$UNIFIED_DECK_SERVICE"
    fix_task_syntax "$UNIFIED_STUDY_SERVICE"
    
    # Recherche d'autres fichiers avec des conversions CoreData
    echo -e "\n${BLUE}Recherche d'autres fichiers avec des conversions CoreData...${NC}"
    
    # Recherche de fichiers avec mapEntityToModel ou similaire
    other_files=$(grep -r --include="*.swift" "mapEntityToModel\|mapCardEntityToModel\|mapDeckEntityToModel\|mapSessionEntityToModel" --exclude-dir="$BACKUP_DIR" . | grep -v "$UNIFIED_CARD_SERVICE" | grep -v "$UNIFIED_DECK_SERVICE" | grep -v "$UNIFIED_STUDY_SERVICE" | awk -F ':' '{print $1}' | sort | uniq)
    
    if [ -n "$other_files" ]; then
        echo -e "${YELLOW}Autres fichiers avec des conversions d'entités:${NC}"
        echo "$other_files" | while read -r file; do
            fix_qualified_references "$file"
            fix_parameter_names "$file"
            fix_task_syntax "$file"
        done
    else
        echo -e "${GREEN}✓ Aucun autre fichier avec des conversions d'entités trouvé${NC}"
    fi
    
    echo -e "\n${GREEN}=== Correction des conversions CoreData terminée ===${NC}"
    echo -e "${YELLOW}Toutes les modifications ont été sauvegardées dans $BACKUP_DIR${NC}"
    echo -e "${YELLOW}Il est recommandé de compiler le projet pour vérifier que toutes les corrections sont valides.${NC}"
}

# Exécution de la fonction principale
main 