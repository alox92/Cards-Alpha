#!/bin/bash

# Script d'analyse et correction des problèmes d'imports de modules dans CardApp
# Auteur: Claude Agent
# Date: $(date +%Y-%m-%d)

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Fonction pour l'affichage d'information
info() {
    echo -e "${BLUE}ℹ${NC} ${BOLD}$1${NC}"
}

# Fonction pour l'affichage de succès
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Fonction pour l'affichage d'avertissement
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Fonction pour l'affichage d'erreur
error() {
    echo -e "${RED}✗${NC} $1"
}

# Fonction pour l'affichage de section
section() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
}

# Création d'un répertoire de sauvegarde
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups_module_imports_${TIMESTAMP}"
mkdir -p "$BACKUP_DIR"
success "Répertoire de sauvegarde créé: $BACKUP_DIR"

# Configuration
PROJECT_ROOT="."

# Fonction pour la sauvegarde d'un fichier avant modification
backup_file() {
    local file="$1"
    local backup_path="$BACKUP_DIR/${file//\//_}"
    
    if [[ -f "$file" ]]; then
        mkdir -p "$(dirname "$backup_path")"
        cp "$file" "$backup_path"
        return 0
    else
        return 1
    fi
}

# Phase 1: Analyse des problèmes d'imports
section "PHASE 1: ANALYSE DES PROBLÈMES D'IMPORTS"

# Recherche des imports problématiques
info "Recherche des imports problématiques 'Core.Common'..."
COMMON_IMPORTS=$(grep -r "import Core.Common" --include="*.swift" "$PROJECT_ROOT" | wc -l)
info "Recherche des imports problématiques 'Core.Models.Common'..."
MODELS_COMMON_IMPORTS=$(grep -r "import Core.Models.Common" --include="*.swift" "$PROJECT_ROOT" | wc -l)

# Affichage des résultats
info "Nombre d'imports 'Core.Common' trouvés: $COMMON_IMPORTS"
info "Nombre d'imports 'Core.Models.Common' trouvés: $MODELS_COMMON_IMPORTS"

# Recherche des types ambigus
section "RECHERCHE DES TYPES AMBIGUS"

info "Recherche des types ReviewRating ambigus..."
REVIEW_RATING_AMBIGUITIES=$(grep -r -l "ReviewRating" --include="*.swift" "$PROJECT_ROOT" | wc -l)
info "Nombre de fichiers avec ReviewRating: $REVIEW_RATING_AMBIGUITIES"

info "Recherche des types MasteryLevel ambigus..."
MASTERY_LEVEL_AMBIGUITIES=$(grep -r -l "MasteryLevel" --include="*.swift" "$PROJECT_ROOT" | wc -l)
info "Nombre de fichiers avec MasteryLevel: $MASTERY_LEVEL_AMBIGUITIES"

info "Recherche des types PersistenceController ambigus..."
PERSISTENCE_CONTROLLER_AMBIGUITIES=$(grep -r -l "PersistenceController" --include="*.swift" "$PROJECT_ROOT" | wc -l)
info "Nombre de fichiers avec PersistenceController: $PERSISTENCE_CONTROLLER_AMBIGUITIES"

# Phase 2: Correction des imports
section "PHASE 2: CORRECTION DES IMPORTS"

# Fonction pour corriger les imports dans un fichier
fix_file_imports() {
    local file="$1"
    local filename=$(basename "$file")
    
    info "Traitement de $file..."
    
    # Sauvegarde du fichier
    if backup_file "$file"; then
        success "Sauvegarde effectuée"
    else
        error "Échec de la sauvegarde"
        return 1
    fi
    
    # Correction des imports problématiques
    local content=$(cat "$file")
    local modified=false
    
    # 1. Correction des imports non valides Core.Common et Core.Models.Common
    if echo "$content" | grep -q "import Core.Common"; then
        info "Correction de 'import Core.Common'..."
        content=$(echo "$content" | sed 's/import Core.Common/import Core\nimport Core.Common.Errors/g')
        modified=true
    fi
    
    if echo "$content" | grep -q "import Core.Models.Common"; then
        info "Correction de 'import Core.Models.Common'..."
        content=$(echo "$content" | sed 's/import Core.Models.Common/import Core\nimport Core.Models/g')
        modified=true
    fi
    
    # 2. Correction des types ambigus
    if echo "$content" | grep -q "ReviewRating" && ! echo "$filename" | grep -q "Types.swift"; then
        info "Qualification des références à ReviewRating..."
        content=$(echo "$content" | sed 's/\([^.]\)ReviewRating/\1Core.Common.ReviewRating/g')
        content=$(echo "$content" | sed 's/^ReviewRating/Core.Common.ReviewRating/g')
        modified=true
    fi
    
    if echo "$content" | grep -q "MasteryLevel" && ! echo "$filename" | grep -q "Enums.swift"; then
        info "Qualification des références à MasteryLevel..."
        content=$(echo "$content" | sed 's/\([^.]\)MasteryLevel/\1Core.Models.Common.MasteryLevel/g')
        content=$(echo "$content" | sed 's/^MasteryLevel/Core.Models.Common.MasteryLevel/g')
        modified=true
    fi
    
    if echo "$content" | grep -q "PersistenceController" && echo "$filename" | grep -q "CoreDataOptimizer.swift"; then
        info "Qualification des références à PersistenceController..."
        content=$(echo "$content" | sed 's/\([^.]\)PersistenceController/\1Core.Persistence.PersistenceController/g')
        content=$(echo "$content" | sed 's/^PersistenceController/Core.Persistence.PersistenceController/g')
        modified=true
    fi
    
    # Si des modifications ont été faites, écrire le nouveau contenu
    if [ "$modified" = true ]; then
        echo "$content" > "$file"
        success "Modifications appliquées à $file"
    else
        info "Aucune modification nécessaire pour $file"
    fi
}

# Recherche et correction des fichiers avec imports problématiques
FILES_WITH_COMMON_IMPORTS=$(grep -r -l "import Core.Common" --include="*.swift" "$PROJECT_ROOT")
FILES_WITH_MODELS_COMMON_IMPORTS=$(grep -r -l "import Core.Models.Common" --include="*.swift" "$PROJECT_ROOT")

# Fusionner les listes de fichiers (en éliminant les doublons)
FILES_TO_FIX=$(echo "$FILES_WITH_COMMON_IMPORTS"$'\n'"$FILES_WITH_MODELS_COMMON_IMPORTS" | sort | uniq)

# Traiter chaque fichier
if [ -n "$FILES_TO_FIX" ]; then
    for file in $FILES_TO_FIX; do
        fix_file_imports "$file"
    done
else
    info "Aucun fichier à corriger pour les imports."
fi

# Phase 3: Correction des fichiers spécifiques problématiques
section "PHASE 3: CORRECTION DES FICHIERS SPÉCIFIQUES"

# Correction de CoreDataOptimizer.swift
OPTIMIZER_FILE="Core/Tools/CoreDataOptimizer.swift"
if [ -f "$OPTIMIZER_FILE" ]; then
    info "Correction de CoreDataOptimizer.swift..."
    fix_file_imports "$OPTIMIZER_FILE"
    
    # Ajout d'imports spécifiques
    if ! grep -q "import Core.Persistence" "$OPTIMIZER_FILE"; then
        sed -i '' '1a\
import Core.Persistence
' "$OPTIMIZER_FILE"
        success "Import Core.Persistence ajouté à CoreDataOptimizer.swift"
    fi
else
    warning "CoreDataOptimizer.swift non trouvé"
fi

# Correction de CardReviewEntity.swift
REVIEW_ENTITY_FILE="Core/Models/Data/CardReviewEntity.swift"
if [ -f "$REVIEW_ENTITY_FILE" ]; then
    info "Correction de CardReviewEntity.swift..."
    fix_file_imports "$REVIEW_ENTITY_FILE"
    
    # Remplacement de l'enum ReviewRating local par une référence
    if grep -q "enum ReviewRating: Int, Codable, CaseIterable" "$REVIEW_ENTITY_FILE"; then
        sed -i '' '/enum ReviewRating: Int, Codable, CaseIterable/,/^}/d' "$REVIEW_ENTITY_FILE"
        
        # S'assurer que l'import de Core est présent
        if ! grep -q "import Core" "$REVIEW_ENTITY_FILE"; then
            sed -i '' '1a\
import Core
' "$REVIEW_ENTITY_FILE"
            success "Import Core ajouté à CardReviewEntity.swift"
        fi
        
        success "Enum ReviewRating local supprimé de CardReviewEntity.swift"
    fi
else
    warning "CardReviewEntity.swift non trouvé"
fi

# Correction de UnifiedStudyService.swift
STUDY_SERVICE_FILE="Core/Services/Unified/UnifiedStudyService.swift"
if [ -f "$STUDY_SERVICE_FILE" ]; then
    info "Correction de UnifiedStudyService.swift..."
    fix_file_imports "$STUDY_SERVICE_FILE"
    
    # Correction d'une possible erreur d'import malformé
    if grep -q "import Core.Commonnonisolated" "$STUDY_SERVICE_FILE"; then
        sed -i '' 's/import Core.Commonnonisolated/import Core\nnonisolated/g' "$STUDY_SERVICE_FILE"
        success "Import malformé corrigé dans UnifiedStudyService.swift"
    fi
else
    warning "UnifiedStudyService.swift non trouvé"
fi

# Phase 4: Vérification des corrections
section "PHASE 4: VÉRIFICATION DES CORRECTIONS"

# Recherche des imports problématiques après correction
info "Recherche des imports problématiques après correction..."
COMMON_IMPORTS_AFTER=$(grep -r "import Core.Common" --include="*.swift" "$PROJECT_ROOT" | wc -l)
MODELS_COMMON_IMPORTS_AFTER=$(grep -r "import Core.Models.Common" --include="*.swift" "$PROJECT_ROOT" | wc -l)

# Affichage des résultats
success "Imports 'Core.Common' avant: $COMMON_IMPORTS, après: $COMMON_IMPORTS_AFTER"
success "Imports 'Core.Models.Common' avant: $MODELS_COMMON_IMPORTS, après: $MODELS_COMMON_IMPORTS_AFTER"

section "RÉSUMÉ DES CORRECTIONS"

info "Nombre total de fichiers traités: $(echo "$FILES_TO_FIX" | wc -l)"
info "Les fichiers originaux ont été sauvegardés dans: $BACKUP_DIR"
info "Pour restaurer un fichier, utilisez: cp \"$BACKUP_DIR/chemin_fichier\" \"chemin_fichier\""

echo -e "\n${GREEN}${BOLD}Correction des imports de modules terminée!${NC}\n"
echo -e "${YELLOW}Note: Veuillez compiler le projet pour vérifier que toutes les erreurs ont été résolues.${NC}"
echo -e "${BLUE}Si des problèmes persistent, des ajustements manuels peuvent être nécessaires.${NC}\n"

# Rendre le script exécutable
chmod +x verify_imports.sh 2>/dev/null || true

exit 0 