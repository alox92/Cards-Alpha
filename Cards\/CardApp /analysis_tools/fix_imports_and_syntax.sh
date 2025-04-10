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
BACKUP_DIR="backups_fixes_${TIMESTAMP}"
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

# Fonction pour corriger les erreurs de syntaxe "consecutive statements"
fix_consecutive_statements() {
    local file="$1"
    
    if check_file_exists "$file"; then
        # Sauvegarde du fichier original
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        echo -e "${GREEN}Sauvegarde créée dans $BACKUP_DIR/$(basename "$file")${NC}"
        
        # Corriger les déclarations consécutives sans point-virgule
        sed -i '' 's/fetchBatchSize = 20        /fetchBatchSize = 20; /g' "$file"
        sed -i '' 's/fetchBatchSize = 20        fetchRequest/fetchBatchSize = 20; fetchRequest/g' "$file"
        sed -i '' 's/fetchBatchSize = 20        return/fetchBatchSize = 20; return/g' "$file"
        
        echo -e "${GREEN}Erreurs de syntaxe 'consecutive statements' corrigées dans $file${NC}"
    fi
}

# Fonction pour corriger les ambiguïtés dans CoreDataOptimizer.swift
fix_coredata_optimizer() {
    local file="Core/Tools/CoreDataOptimizer.swift"
    
    if check_file_exists "$file"; then
        # Sauvegarde du fichier original
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        echo -e "${GREEN}Sauvegarde créée dans $BACKUP_DIR/$(basename "$file")${NC}"
        
        # Ajouter les imports nécessaires
        # Note: Core.Persistence n'est probablement pas le bon module si "PersistenceController" est ambigu
        # Nous allons plutôt qualifier directement PersistenceController
        
        # Corriger les références ambiguës à PersistenceController - Utiliser le nom complet
        sed -i '' 's/private let persistenceController: PersistenceController/private let persistenceController: Core.PersistenceController/g' "$file"
        sed -i '' 's/public init(persistenceController: PersistenceController)/public init(persistenceController: Core.PersistenceController)/g' "$file"
        sed -i '' 's/extension PersistenceController/extension Core.PersistenceController/g' "$file"
        
        echo -e "${GREEN}Références à PersistenceController corrigées dans CoreDataOptimizer.swift${NC}"
    fi
}

# Fonction pour corriger CardReviewEntity.swift
fix_card_review_entity() {
    local file="Core/Models/Data/CardReviewEntity.swift"
    
    if check_file_exists "$file"; then
        # Sauvegarde du fichier original
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        echo -e "${GREEN}Sauvegarde créée dans $BACKUP_DIR/$(basename "$file")${NC}"
        
        # Si le fichier fait partie du module Core, nous ne devrions pas importer Core (provoque un warning)
        # Supprimer l'import de Core
        sed -i '' '/^import Core$/d' "$file"
        
        # Remplacer l'import de Core.Common par la définition directe de ReviewRating
        sed -i '' '/^import Core.Common$/d' "$file"
        
        # Modifier directement le fichier pour définir ReviewRating
        cat > "$BACKUP_DIR/review_rating_block.txt" << EOF

// MARK: - Type local pour remplacer l'import externe
enum ReviewRating: Int, Codable, CaseIterable {
    case again = 0
    case hard = 1
    case good = 2
    case easy = 3
}
EOF
        
        # Insérer le bloc après l'extension CardReviewEntity
        line_number=$(grep -n "extension CardReviewEntity {" "$file" | cut -d: -f1)
        if [ -n "$line_number" ]; then
            sed -i '' "${line_number}r $BACKUP_DIR/review_rating_block.txt" "$file"
            echo -e "${GREEN}ReviewRating ajouté localement dans CardReviewEntity.swift${NC}"
        else
            echo -e "${YELLOW}Extension CardReviewEntity non trouvée, ReviewRating non ajouté${NC}"
        fi
        
        echo -e "${GREEN}Correction des imports dans CardReviewEntity.swift${NC}"
    fi
}

# Fonction pour corriger UnifiedStudyService.swift
fix_unified_study_service() {
    local file="Core/Services/Unified/UnifiedStudyService.swift"
    
    if check_file_exists "$file"; then
        # Sauvegarde du fichier original
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        echo -e "${GREEN}Sauvegarde créée dans $BACKUP_DIR/$(basename "$file")${NC}"
        
        # Correction des fetchBatchSize sans point-virgule
        sed -i '' 's/fetchBatchSize = 20        /fetchBatchSize = 20; /g' "$file"
        sed -i '' 's/fetchBatchSize = 20if/fetchBatchSize = 20; if/g' "$file"
        
        # Créer le bloc de types dans un fichier temporaire
        cat > "$BACKUP_DIR/types_block.txt" << EOF

// MARK: - Types locaux pour éviter les ambiguïtés
enum ReviewRating: Int, Codable, CaseIterable, Sendable {
    case again = 0
    case hard = 1
    case good = 2
    case easy = 3
}

enum MasteryLevel: Int, Codable, CaseIterable, Sendable {
    case novice = 0
    case beginner = 1
    case intermediate = 2
    case advanced = 3
    case expert = 4
}

enum StudyServiceError: Error {
    case sessionAlreadyStarted
    case sessionNotFound
    case cardNotFound
    case invalidData
}
EOF
        
        # Insérer le bloc après le dernier import
        last_import_line=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
        if [ -n "$last_import_line" ]; then
            sed -i '' "${last_import_line}r $BACKUP_DIR/types_block.txt" "$file"
            echo -e "${GREEN}Types locaux ajoutés dans UnifiedStudyService.swift${NC}"
        else
            echo -e "${YELLOW}Ligne d'import non trouvée, types locaux non ajoutés${NC}"
        fi
        
        echo -e "${GREEN}UnifiedStudyService.swift corrigé avec succès${NC}"
    fi
}

# Fonction pour corriger CoreDataManager.swift
fix_coredata_manager() {
    local file="Core/Managers/CoreDataManager.swift"
    
    if check_file_exists "$file"; then
        # Sauvegarde du fichier original
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        echo -e "${GREEN}Sauvegarde créée dans $BACKUP_DIR/$(basename "$file")${NC}"
        
        # Corriger les déclarations consécutives sans point-virgule
        sed -i '' 's/fetchBatchSize = 20        /fetchBatchSize = 20; /g' "$file"
        sed -i '' 's/fetchBatchSize = 20        return/fetchBatchSize = 20; return/g' "$file"
        
        echo -e "${GREEN}Erreurs de syntaxe dans CoreDataManager.swift corrigées${NC}"
    fi
}

# Vérifier tous les fichiers Swift pour ce problème
fix_all_consecutive_statements() {
    echo -e "${BLUE}Recherche de tous les fichiers Swift contenant des erreurs de syntaxe...${NC}"
    
    # Trouver tous les fichiers Swift
    find . -name "*.swift" -type f | while read -r file; do
        # Vérifier si le fichier contient des erreurs potentielles
        if grep -q "fetchBatchSize = 20        " "$file"; then
            echo -e "${YELLOW}Correction des erreurs de syntaxe dans $file${NC}"
            fix_consecutive_statements "$file"
        fi
    done
}

# Appliquer les corrections
echo -e "${BLUE}=== Correction des problèmes d'importation, d'ambiguïtés et de syntaxe ===${NC}"

# Corriger les fichiers problématiques
fix_card_review_entity
fix_unified_study_service
fix_coredata_optimizer
fix_coredata_manager
fix_all_consecutive_statements

echo -e "${BLUE}=========================================================${NC}"
echo -e "${GREEN}Corrections terminées${NC}"
echo -e "${YELLOW}Pour restaurer les versions originales, utilisez:${NC}"
echo -e "${YELLOW}cp \"$BACKUP_DIR/[nom_du_fichier]\" \"[chemin_original]\"${NC}"
echo -e "${BLUE}=========================================================${NC}"

# Vérification finale
echo -e "${BLUE}Vérification des fichiers corrigés...${NC}"
find "$BACKUP_DIR" -type f | while read -r file; do
    original_file="${file#$BACKUP_DIR/}"
    echo -e "${YELLOW}Fichier corrigé: $original_file${NC}"
done

echo -e "${GREEN}Script terminé. Veuillez vérifier la compilation du projet.${NC}" 