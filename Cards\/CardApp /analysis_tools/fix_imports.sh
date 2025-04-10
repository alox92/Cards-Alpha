#!/bin/bash

# Couleurs pour la sortie terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Vérifier si le fichier existe
check_file_exists() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo -e "${RED}Erreur: Le fichier $file n'existe pas.${NC}"
        return 1
    fi
    return 0
}

# Création d'un répertoire de sauvegarde avec horodatage
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups_imports_${TIMESTAMP}"
mkdir -p "$BACKUP_DIR"

# Fonction pour ajouter un import s'il n'existe pas déjà
add_import() {
    local import_line="$1"
    local file="$2"
    
    if ! grep -q "^$import_line$" "$file"; then
        # Trouver la dernière ligne d'import
        local last_import_line=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
        
        # Ajouter le nouvel import après la dernière ligne d'import
        sed -i '' "${last_import_line}a\\
$import_line" "$file"
        
        echo -e "${GREEN}Ajout de l'import: $import_line dans $file${NC}"
    else
        echo -e "${YELLOW}L'import $import_line existe déjà dans $file${NC}"
    fi
}

# Fonction pour remplacer les références ambiguës
fix_ambiguous_references() {
    local file="$1"
    
    # Remplacer MasteryLevel par le chemin complet dans tout le fichier
    sed -i '' 's/MasteryLevel\./Core.Models.Common.MasteryLevel./g' "$file"
    sed -i '' 's/: MasteryLevel/: Core.Models.Common.MasteryLevel/g' "$file"
    sed -i '' 's/-> MasteryLevel/-> Core.Models.Common.MasteryLevel/g' "$file"
    
    # Remplacer CardReview par le chemin complet
    sed -i '' 's/CardReview\./Core.Models.Study.CardReview./g' "$file"
    sed -i '' 's/: CardReview/: Core.Models.Study.CardReview/g' "$file"
    sed -i '' 's/-> CardReview/-> Core.Models.Study.CardReview/g' "$file"
    sed -i '' 's/\[CardReview\]/[Core.Models.Study.CardReview]/g' "$file"
    
    # Remplacer StudyServiceError par le chemin complet
    sed -i '' 's/StudyServiceError\./Core.Common.StudyServiceError./g' "$file"
    sed -i '' 's/: StudyServiceError/: Core.Common.StudyServiceError/g' "$file"
    sed -i '' 's/-> StudyServiceError/-> Core.Common.StudyServiceError/g' "$file"
    
    # Remplacer ReviewRating par le chemin complet
    sed -i '' 's/ReviewRating\./Core.Common.ReviewRating./g' "$file"
    sed -i '' 's/: ReviewRating/: Core.Common.ReviewRating/g' "$file"
    sed -i '' 's/-> ReviewRating/-> Core.Common.ReviewRating/g' "$file"
    
    echo -e "${GREEN}Les références ambiguës ont été qualifiées avec leur chemin complet dans $file${NC}"
}

# Fonction pour corriger les ambiguïtés dans CoreDataOptimizer.swift
fix_coredata_optimizer() {
    local file="Core/Tools/CoreDataOptimizer.swift"
    
    if check_file_exists "$file"; then
        # Sauvegarde du fichier original
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        echo -e "${GREEN}Sauvegarde créée dans $BACKUP_DIR/$(basename "$file")${NC}"
        
        # Ajouter les imports nécessaires
        add_import "import Core.Persistence" "$file"
        
        # Corriger les références ambiguës à PersistenceController
        sed -i '' 's/persistenceController: PersistenceController/persistenceController: Core.Persistence.PersistenceController/g' "$file"
        sed -i '' 's/extension PersistenceController/extension Core.Persistence.PersistenceController/g' "$file"
        
        echo -e "${GREEN}Références à PersistenceController corrigées dans CoreDataOptimizer.swift${NC}"
    fi
}

# Traiter UnifiedStudyService.swift
fix_unified_study_service() {
    local file="Core/Services/Unified/UnifiedStudyService.swift"
    
    if check_file_exists "$file"; then
        # Sauvegarde du fichier original
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        echo -e "${GREEN}Sauvegarde créée dans $BACKUP_DIR/$(basename "$file")${NC}"
        
        # Ajout des imports manquants
        add_import "import Core.Models.Common" "$file"
        add_import "import Core.Models.Study" "$file"
        add_import "import Core.Common" "$file"
        
        # Correction des références ambiguës
        fix_ambiguous_references "$file"
        
        echo -e "${GREEN}Imports et références corrigés dans UnifiedStudyService.swift${NC}"
    fi
}

# Traiter CardReviewEntity.swift
fix_card_review_entity() {
    local file="Core/Models/Data/CardReviewEntity.swift"
    
    if check_file_exists "$file"; then
        # Sauvegarde du fichier original
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        echo -e "${GREEN}Sauvegarde créée dans $BACKUP_DIR/$(basename "$file")${NC}"
        
        # Ajouter l'import de Common pour ReviewRating
        add_import "import Core.Common" "$file"
        
        echo -e "${GREEN}Imports corrigés dans CardReviewEntity.swift${NC}"
    fi
}

# Appliquer les corrections
echo -e "${BLUE}=== Correction des problèmes d'importation et d'ambiguïtés ===${NC}"

# Corriger les fichiers problématiques
fix_unified_study_service
fix_coredata_optimizer
fix_card_review_entity

echo -e "${BLUE}=========================================================${NC}"
echo -e "${GREEN}Corrections des imports terminées${NC}"
echo -e "${YELLOW}Pour restaurer les versions originales, utilisez:${NC}"
echo -e "${YELLOW}cp \"$BACKUP_DIR/[nom_du_fichier]\" \"[chemin_original]\"${NC}"
echo -e "${BLUE}=========================================================${NC}"

# Vérification de Swift Build
echo -e "${BLUE}Vérification de la compilation...${NC}"
if command -v swift &> /dev/null; then
    if swift build; then
        echo -e "${GREEN}Compilation réussie!${NC}"
    else
        echo -e "${RED}Erreur de compilation. Vérifiez les modifications et ajustez si nécessaire.${NC}"
    fi
else
    echo -e "${YELLOW}La commande swift n'est pas disponible. Vérifiez manuellement la compilation.${NC}"
fi 