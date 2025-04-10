#!/bin/bash

# Script de correction des types ambigus dans CardApp
# Auteur: Claude Agent
# Date: $(date +%Y-%m-%d)

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Bannière
echo -e "${BLUE}${BOLD}====================================================${NC}"
echo -e "${BLUE}${BOLD}  CORRECTION DES TYPES AMBIGUS DANS CARDAPP${NC}"
echo -e "${BLUE}${BOLD}====================================================${NC}\n"

# Création d'un répertoire de sauvegarde
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups_ambiguous_types_${TIMESTAMP}"
mkdir -p "$BACKUP_DIR"
echo -e "${GREEN}✓${NC} Répertoire de sauvegarde créé: $BACKUP_DIR"

# Configuration
PROJECT_ROOT="."

# Fonction pour la sauvegarde d'un fichier
backup_file() {
    local file="$1"
    local backup_path="$BACKUP_DIR/${file//\//_}"
    
    if [[ -f "$file" ]]; then
        mkdir -p "$(dirname "$backup_path")"
        cp "$file" "$backup_path"
        echo -e "${GREEN}✓${NC} Sauvegarde effectuée: $file"
        return 0
    else
        echo -e "${RED}✗${NC} Fichier introuvable: $file"
        return 1
    fi
}

# Phase 1: Localisation des fichiers de définition canoniques
echo -e "\n${BLUE}${BOLD}PHASE 1: IDENTIFICATION DES DÉFINITIONS CANONIQUES${NC}\n"

# Recherche des fichiers de définition canoniques
REVIEW_RATING_FILE="Core/Common/Types.swift"
MASTERY_LEVEL_FILE="Core/Models/Common/Enums.swift"

# Vérification de l'existence des fichiers
if [ -f "$REVIEW_RATING_FILE" ]; then
    echo -e "${GREEN}✓${NC} Fichier canonique pour ReviewRating trouvé: $REVIEW_RATING_FILE"
    HAS_REVIEW_RATING=true
else
    echo -e "${RED}✗${NC} Fichier canonique pour ReviewRating non trouvé"
    HAS_REVIEW_RATING=false
    
    # Recherche alternative
    REVIEW_RATING_FILES=$(grep -r "enum ReviewRating" --include="*.swift" "$PROJECT_ROOT" | cut -d: -f1)
    if [ -n "$REVIEW_RATING_FILES" ]; then
        echo -e "${YELLOW}!${NC} Définitions alternatives trouvées:"
        echo "$REVIEW_RATING_FILES" | sed 's/^/  - /'
        
        # Sélectionner le premier fichier comme canonique
        REVIEW_RATING_FILE=$(echo "$REVIEW_RATING_FILES" | head -1)
        echo -e "${YELLOW}!${NC} Utilisation de $REVIEW_RATING_FILE comme définition canonique"
        HAS_REVIEW_RATING=true
    fi
fi

if [ -f "$MASTERY_LEVEL_FILE" ]; then
    echo -e "${GREEN}✓${NC} Fichier canonique pour MasteryLevel trouvé: $MASTERY_LEVEL_FILE"
    HAS_MASTERY_LEVEL=true
else
    echo -e "${RED}✗${NC} Fichier canonique pour MasteryLevel non trouvé"
    HAS_MASTERY_LEVEL=false
    
    # Recherche alternative
    MASTERY_LEVEL_FILES=$(grep -r "enum MasteryLevel" --include="*.swift" "$PROJECT_ROOT" | cut -d: -f1)
    if [ -n "$MASTERY_LEVEL_FILES" ]; then
        echo -e "${YELLOW}!${NC} Définitions alternatives trouvées:"
        echo "$MASTERY_LEVEL_FILES" | sed 's/^/  - /'
        
        # Sélectionner le premier fichier comme canonique
        MASTERY_LEVEL_FILE=$(echo "$MASTERY_LEVEL_FILES" | head -1)
        echo -e "${YELLOW}!${NC} Utilisation de $MASTERY_LEVEL_FILE comme définition canonique"
        HAS_MASTERY_LEVEL=true
    fi
fi

# Phase 2: Extraction des définitions canoniques
echo -e "\n${BLUE}${BOLD}PHASE 2: EXTRACTION DES DÉFINITIONS CANONIQUES${NC}\n"

# Extraire la définition de ReviewRating
if [ "$HAS_REVIEW_RATING" = true ]; then
    echo -e "${BLUE}ℹ${NC} Extraction de la définition de ReviewRating..."
    
    # Créer un fichier temporaire pour la définition
    REVIEW_RATING_DEF_FILE="$BACKUP_DIR/ReviewRating_def.swift"
    
    # Extraction de la définition complète (du début à la fin de l'enum)
    sed -n '/enum ReviewRating/,/^}/p' "$REVIEW_RATING_FILE" > "$REVIEW_RATING_DEF_FILE"
    
    echo -e "${GREEN}✓${NC} Définition de ReviewRating extraite dans $REVIEW_RATING_DEF_FILE"
    
    # Afficher la définition
    echo -e "${YELLOW}Définition extraite:${NC}"
    cat "$REVIEW_RATING_DEF_FILE" | sed 's/^/  /'
fi

# Extraire la définition de MasteryLevel
if [ "$HAS_MASTERY_LEVEL" = true ]; then
    echo -e "${BLUE}ℹ${NC} Extraction de la définition de MasteryLevel..."
    
    # Créer un fichier temporaire pour la définition
    MASTERY_LEVEL_DEF_FILE="$BACKUP_DIR/MasteryLevel_def.swift"
    
    # Extraction de la définition complète (du début à la fin de l'enum)
    sed -n '/enum MasteryLevel/,/^}/p' "$MASTERY_LEVEL_FILE" > "$MASTERY_LEVEL_DEF_FILE"
    
    echo -e "${GREEN}✓${NC} Définition de MasteryLevel extraite dans $MASTERY_LEVEL_DEF_FILE"
    
    # Afficher la définition
    echo -e "${YELLOW}Définition extraite:${NC}"
    cat "$MASTERY_LEVEL_DEF_FILE" | sed 's/^/  /'
fi

# Phase 3: Suppression des définitions dupliquées
echo -e "\n${BLUE}${BOLD}PHASE 3: SUPPRESSION DES DÉFINITIONS DUPLIQUÉES${NC}\n"

# Supprimer les définitions dupliquées de ReviewRating
if [ "$HAS_REVIEW_RATING" = true ]; then
    echo -e "${BLUE}ℹ${NC} Recherche des définitions dupliquées de ReviewRating..."
    
    # Trouver tous les fichiers contenant des définitions de ReviewRating (sauf le fichier canonique)
    DUPLICATE_REVIEW_RATING_FILES=$(grep -r "enum ReviewRating" --include="*.swift" "$PROJECT_ROOT" | grep -v "$REVIEW_RATING_FILE" | cut -d: -f1)
    
    if [ -n "$DUPLICATE_REVIEW_RATING_FILES" ]; then
        echo -e "${YELLOW}!${NC} Définitions dupliquées trouvées dans:"
        echo "$DUPLICATE_REVIEW_RATING_FILES" | sed 's/^/  - /'
        
        # Traitement de chaque fichier
        for file in $DUPLICATE_REVIEW_RATING_FILES; do
            echo -e "${BLUE}ℹ${NC} Traitement de $file..."
            
            # Sauvegarde du fichier
            backup_file "$file"
            
            # Suppression de la définition complète
            sed -i '' '/enum ReviewRating/,/^}/d' "$file"
            
            # Ajout de l'import Core si nécessaire
            if ! grep -q "import Core" "$file"; then
                sed -i '' '1a\\
import Core
' "$file"
                echo -e "${GREEN}✓${NC} Import Core ajouté à $file"
            fi
            
            echo -e "${GREEN}✓${NC} Définition dupliquée supprimée de $file"
        done
    else
        echo -e "${GREEN}✓${NC} Aucune définition dupliquée de ReviewRating trouvée"
    fi
fi

# Supprimer les définitions dupliquées de MasteryLevel
if [ "$HAS_MASTERY_LEVEL" = true ]; then
    echo -e "${BLUE}ℹ${NC} Recherche des définitions dupliquées de MasteryLevel..."
    
    # Trouver tous les fichiers contenant des définitions de MasteryLevel (sauf le fichier canonique)
    DUPLICATE_MASTERY_LEVEL_FILES=$(grep -r "enum MasteryLevel" --include="*.swift" "$PROJECT_ROOT" | grep -v "$MASTERY_LEVEL_FILE" | cut -d: -f1)
    
    if [ -n "$DUPLICATE_MASTERY_LEVEL_FILES" ]; then
        echo -e "${YELLOW}!${NC} Définitions dupliquées trouvées dans:"
        echo "$DUPLICATE_MASTERY_LEVEL_FILES" | sed 's/^/  - /'
        
        # Traitement de chaque fichier
        for file in $DUPLICATE_MASTERY_LEVEL_FILES; do
            echo -e "${BLUE}ℹ${NC} Traitement de $file..."
            
            # Sauvegarde du fichier
            backup_file "$file"
            
            # Suppression de la définition complète
            sed -i '' '/enum MasteryLevel/,/^}/d' "$file"
            
            # Ajout de l'import Core si nécessaire
            if ! grep -q "import Core" "$file"; then
                sed -i '' '1a\\
import Core
' "$file"
                echo -e "${GREEN}✓${NC} Import Core ajouté à $file"
            fi
            
            echo -e "${GREEN}✓${NC} Définition dupliquée supprimée de $file"
        done
    else
        echo -e "${GREEN}✓${NC} Aucune définition dupliquée de MasteryLevel trouvée"
    fi
fi

# Phase 4: Correction des références non qualifiées
echo -e "\n${BLUE}${BOLD}PHASE 4: QUALIFICATION DES RÉFÉRENCES${NC}\n"

# Compter les références non qualifiées à traiter
REVIEW_RATING_REFS=$(grep -r "ReviewRating\." --include="*.swift" "$PROJECT_ROOT" | grep -v "Core\.Common\.ReviewRating\." | wc -l)
MASTERY_LEVEL_REFS=$(grep -r "MasteryLevel\." --include="*.swift" "$PROJECT_ROOT" | grep -v "Core\.Models\.Common\.MasteryLevel\." | wc -l)
ERROR_REFS=$(grep -r "StudyServiceError\." --include="*.swift" "$PROJECT_ROOT" | grep -v "Core\.Common\.StudyServiceError\." | wc -l)

echo -e "${BLUE}ℹ${NC} Références non qualifiées à corriger:"
echo -e "  - ReviewRating: $REVIEW_RATING_REFS"
echo -e "  - MasteryLevel: $MASTERY_LEVEL_REFS"
echo -e "  - StudyServiceError: $ERROR_REFS"

# Recherche des fichiers contenant des références à ReviewRating
if [ $REVIEW_RATING_REFS -gt 0 ]; then
    echo -e "${BLUE}ℹ${NC} Qualification des références à ReviewRating..."
    
    # Trouver tous les fichiers contenant des références à ReviewRating
    REVIEW_RATING_REF_FILES=$(grep -r -l "ReviewRating\." --include="*.swift" "$PROJECT_ROOT" | grep -v "Core\.Common\.ReviewRating\.")
    
    for file in $REVIEW_RATING_REF_FILES; do
        echo -e "${BLUE}ℹ${NC} Traitement de $file..."
        
        # Sauvegarde du fichier
        backup_file "$file"
        
        # Qualification des références
        sed -i '' 's/\([^.]\)ReviewRating\./\1Core.Common.ReviewRating./g' "$file"
        
        echo -e "${GREEN}✓${NC} Références qualifiées dans $file"
    done
fi

# Recherche des fichiers contenant des références à MasteryLevel
if [ $MASTERY_LEVEL_REFS -gt 0 ]; then
    echo -e "${BLUE}ℹ${NC} Qualification des références à MasteryLevel..."
    
    # Trouver tous les fichiers contenant des références à MasteryLevel
    MASTERY_LEVEL_REF_FILES=$(grep -r -l "MasteryLevel\." --include="*.swift" "$PROJECT_ROOT" | grep -v "Core\.Models\.Common\.MasteryLevel\.")
    
    for file in $MASTERY_LEVEL_REF_FILES; do
        echo -e "${BLUE}ℹ${NC} Traitement de $file..."
        
        # Sauvegarde du fichier
        backup_file "$file"
        
        # Qualification des références
        sed -i '' 's/\([^.]\)MasteryLevel\./\1Core.Models.Common.MasteryLevel./g' "$file"
        
        echo -e "${GREEN}✓${NC} Références qualifiées dans $file"
    done
fi

# Recherche des fichiers contenant des références à StudyServiceError
if [ $ERROR_REFS -gt 0 ]; then
    echo -e "${BLUE}ℹ${NC} Qualification des références à StudyServiceError..."
    
    # Trouver tous les fichiers contenant des références à StudyServiceError
    ERROR_REF_FILES=$(grep -r -l "StudyServiceError\." --include="*.swift" "$PROJECT_ROOT" | grep -v "Core\.Common\.StudyServiceError\.")
    
    for file in $ERROR_REF_FILES; do
        echo -e "${BLUE}ℹ${NC} Traitement de $file..."
        
        # Sauvegarde du fichier
        backup_file "$file"
        
        # Qualification des références
        sed -i '' 's/\([^.]\)StudyServiceError\./\1Core.Common.StudyServiceError./g' "$file"
        
        echo -e "${GREEN}✓${NC} Références qualifiées dans $file"
    done
fi

# Phase 5: Correction des types dans les paramètres et retours
echo -e "\n${BLUE}${BOLD}PHASE 5: QUALIFICATION DES TYPES DE PARAMÈTRES ET RETOURS${NC}\n"

# Trouver les fichiers avec des types non qualifiés dans les signatures
echo -e "${BLUE}ℹ${NC} Recherche des types non qualifiés dans les signatures..."

# Correction des types ReviewRating
REVIEW_RATING_TYPE_FILES=$(grep -r -l ": ReviewRating" --include="*.swift" "$PROJECT_ROOT")
REVIEW_RATING_TYPE_FILES+=" "$(grep -r -l "-> ReviewRating" --include="*.swift" "$PROJECT_ROOT")
REVIEW_RATING_TYPE_FILES=$(echo "$REVIEW_RATING_TYPE_FILES" | tr ' ' '\n' | sort | uniq)

if [ -n "$REVIEW_RATING_TYPE_FILES" ]; then
    echo -e "${BLUE}ℹ${NC} Fichiers avec ReviewRating non qualifié dans les signatures:"
    echo "$REVIEW_RATING_TYPE_FILES" | sed 's/^/  - /'
    
    for file in $REVIEW_RATING_TYPE_FILES; do
        echo -e "${BLUE}ℹ${NC} Traitement de $file..."
        
        # Sauvegarde du fichier
        backup_file "$file"
        
        # Qualification des types
        sed -i '' 's/: ReviewRating/: Core.Common.ReviewRating/g' "$file"
        sed -i '' 's/-> ReviewRating/-> Core.Common.ReviewRating/g' "$file"
        sed -i '' 's/\[ReviewRating\]/[Core.Common.ReviewRating]/g' "$file"
        
        echo -e "${GREEN}✓${NC} Types qualifiés dans $file"
    done
fi

# Correction des types MasteryLevel
MASTERY_LEVEL_TYPE_FILES=$(grep -r -l ": MasteryLevel" --include="*.swift" "$PROJECT_ROOT")
MASTERY_LEVEL_TYPE_FILES+=" "$(grep -r -l "-> MasteryLevel" --include="*.swift" "$PROJECT_ROOT")
MASTERY_LEVEL_TYPE_FILES=$(echo "$MASTERY_LEVEL_TYPE_FILES" | tr ' ' '\n' | sort | uniq)

if [ -n "$MASTERY_LEVEL_TYPE_FILES" ]; then
    echo -e "${BLUE}ℹ${NC} Fichiers avec MasteryLevel non qualifié dans les signatures:"
    echo "$MASTERY_LEVEL_TYPE_FILES" | sed 's/^/  - /'
    
    for file in $MASTERY_LEVEL_TYPE_FILES; do
        echo -e "${BLUE}ℹ${NC} Traitement de $file..."
        
        # Sauvegarde du fichier
        backup_file "$file"
        
        # Qualification des types
        sed -i '' 's/: MasteryLevel/: Core.Models.Common.MasteryLevel/g' "$file"
        sed -i '' 's/-> MasteryLevel/-> Core.Models.Common.MasteryLevel/g' "$file"
        sed -i '' 's/\[MasteryLevel\]/[Core.Models.Common.MasteryLevel]/g' "$file"
        
        echo -e "${GREEN}✓${NC} Types qualifiés dans $file"
    done
fi

# Phase 6: Vérification finale
echo -e "\n${BLUE}${BOLD}PHASE 6: VÉRIFICATION FINALE${NC}\n"

# Exécuter le script de vérification
echo -e "${BLUE}ℹ${NC} Exécution du script de vérification..."

./analysis_tools/verify_imports.sh

# Résumé
echo -e "\n${BLUE}${BOLD}====================================================${NC}"
echo -e "${GREEN}${BOLD}  CORRECTION DES TYPES AMBIGUS TERMINÉE${NC}"
echo -e "${BLUE}${BOLD}====================================================${NC}\n"

echo -e "${YELLOW}Les fichiers originaux ont été sauvegardés dans: $BACKUP_DIR${NC}"
echo -e "${YELLOW}Pour restaurer un fichier, utilisez:${NC}"
echo -e "${YELLOW}cp \"$BACKUP_DIR/chemin_fichier\" \"chemin_original\"${NC}\n"

echo -e "${BLUE}Pour vérifier que toutes les erreurs ont été résolues, compilez le projet.${NC}"
echo -e "${BLUE}Si des problèmes persistent, des ajustements manuels peuvent être nécessaires.${NC}"

exit 0 