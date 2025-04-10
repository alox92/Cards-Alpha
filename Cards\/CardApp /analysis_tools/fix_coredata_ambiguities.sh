#!/bin/bash

# Couleurs pour les sorties
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Timestamp pour les sauvegardes
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups_coredata_ambiguities_$TIMESTAMP"
LOG_FILE="reports/fix_coredata_ambiguities_$TIMESTAMP.log"

# Créer les répertoires nécessaires
mkdir -p "$BACKUP_DIR"
mkdir -p "reports"

echo -e "${BLUE}=== Correction des ambiguïtés de types CoreData dans le projet CardApp ===${NC}"
echo -e "${CYAN}Date: $(date)${NC}\n"

# Initialiser le fichier de log
echo "=== Correction des ambiguïtés de types CoreData ===" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Fonction pour sauvegarder un fichier avant modification
backup_file() {
    local file="$1"
    local base_name=$(basename "$file")
    local backup_path="$BACKUP_DIR/$base_name"
    
    if [ -f "$file" ]; then
        cp "$file" "$backup_path"
        echo -e "${GREEN}Sauvegarde effectuée: $backup_path${NC}"
        echo "Sauvegarde effectuée: $file -> $backup_path" >> "$LOG_FILE"
    else
        echo -e "${RED}Le fichier $file n'existe pas, impossible de sauvegarder${NC}"
        echo "ERREUR: Le fichier $file n'existe pas, impossible de sauvegarder" >> "$LOG_FILE"
    fi
}

# Fonction pour corriger les définitions ambiguës de ReviewRating
fix_review_rating_ambiguities() {
    echo -e "${BLUE}Correction des ambiguïtés pour ReviewRating...${NC}"
    echo "=== Correction des ambiguïtés pour ReviewRating ===" >> "$LOG_FILE"
    
    # 1. Vérifier et corriger les fichiers qui utilisent Core.Common.ReviewRating
    local files_using_reviewrating=$(grep -l --include="*.swift" "ReviewRating" --exclude-dir="$BACKUP_DIR" .)
    
    for file in $files_using_reviewrating; do
        echo -e "${CYAN}Vérification de $file...${NC}"
        echo "Vérification de $file..." >> "$LOG_FILE"
        
        # Vérifier si le fichier utilise ReviewRating sans qualification
        if grep -q "ReviewRating" "$file" && ! grep -q "Core\.Common\.ReviewRating" "$file" && ! grep -q "enum.*ReviewRating" "$file"; then
            backup_file "$file"
            
            # Ajouter l'import si nécessaire
            if ! grep -q "import Core" "$file"; then
                sed -i '' '1s/^/import Core\n/' "$file"
                echo "  Ajout de 'import Core'" >> "$LOG_FILE"
            fi
            
            # Remplacer les occurrences non qualifiées
            sed -i '' 's/\([^\.]\)ReviewRating/\1Core.Common.ReviewRating/g' "$file"
            echo "  Remplacement des occurrences non qualifiées de ReviewRating" >> "$LOG_FILE"
            
            echo -e "${GREEN}Corrections appliquées à $file${NC}"
        elif grep -q "enum.*ReviewRating" "$file"; then
            echo -e "${YELLOW}Le fichier $file contient une définition de ReviewRating${NC}"
            echo "  WARNING: Le fichier $file contient une définition de ReviewRating" >> "$LOG_FILE"
        fi
    done
}

# Fonction pour corriger les définitions ambiguës de MasteryLevel
fix_mastery_level_ambiguities() {
    echo -e "${BLUE}Correction des ambiguïtés pour MasteryLevel...${NC}"
    echo "=== Correction des ambiguïtés pour MasteryLevel ===" >> "$LOG_FILE"
    
    # 1. Vérifier et corriger les fichiers qui utilisent MasteryLevel
    local files_using_masterylevel=$(grep -l --include="*.swift" "MasteryLevel" --exclude-dir="$BACKUP_DIR" .)
    
    for file in $files_using_masterylevel; do
        echo -e "${CYAN}Vérification de $file...${NC}"
        echo "Vérification de $file..." >> "$LOG_FILE"
        
        # Vérifier si le fichier utilise MasteryLevel sans qualification
        if grep -q "MasteryLevel" "$file" && ! grep -q "Core\.Models\.Common\.MasteryLevel" "$file" && ! grep -q "enum.*MasteryLevel" "$file"; then
            backup_file "$file"
            
            # Ajouter l'import si nécessaire
            if ! grep -q "import Core" "$file"; then
                sed -i '' '1s/^/import Core\n/' "$file"
                echo "  Ajout de 'import Core'" >> "$LOG_FILE"
            fi
            
            # Remplacer les occurrences non qualifiées
            sed -i '' 's/\([^\.]\)MasteryLevel/\1Core.Models.Common.MasteryLevel/g' "$file"
            echo "  Remplacement des occurrences non qualifiées de MasteryLevel" >> "$LOG_FILE"
            
            echo -e "${GREEN}Corrections appliquées à $file${NC}"
        elif grep -q "enum.*MasteryLevel" "$file"; then
            echo -e "${YELLOW}Le fichier $file contient une définition de MasteryLevel${NC}"
            echo "  WARNING: Le fichier $file contient une définition de MasteryLevel" >> "$LOG_FILE"
        fi
    done
}

# Fonction pour corriger les problèmes d'initialisation CardReview
fix_card_review_init() {
    echo -e "${BLUE}Correction des problèmes d'initialisation CardReview...${NC}"
    echo "=== Correction des problèmes d'initialisation CardReview ===" >> "$LOG_FILE"
    
    # Fichiers pouvant contenir des initialisations de CardReview
    local card_review_files=$(grep -l --include="*.swift" "CardReview.*init" --exclude-dir="$BACKUP_DIR" .)
    
    for file in $card_review_files; do
        echo -e "${CYAN}Vérification de $file...${NC}"
        echo "Vérification de $file..." >> "$LOG_FILE"
        
        # Vérifier si le fichier contient des initialisations problématiques
        if grep -q "CardReview(\s*\n*\s*id: \([^,]*\),\s*\n*\s*cardID: \([^,]*\),\s*\n*\s*sessionID: \([^,]*\),\s*\n*\s*timestamp: \([^,]*\),\s*\n*\s*rating: \([^,]*\),\s*\n*\s*responseTime: \([^,]*\),\s*\n*\s*newInterval: \([^,]*\),\s*\n*\s*newEase: \([^,]*\),\s*\n*\s*newMasteryLevel: \([^,)]*\))/CardReview(from: \1, cardID: \2, sessionID: \3, timestamp: \4, rating: \5, responseTime: \6, newInterval: \7, newEase: \8, masteryLevel: \9)/g' "$file"
            
            echo "  Correction des initialisations de CardReview" >> "$LOG_FILE"
            echo -e "${GREEN}Corrections appliquées à $file${NC}"
        fi
    done
}

# Fonction pour corriger les initialisations depuis CoreData
fix_entity_to_model_conversions() {
    echo -e "${BLUE}Correction des conversions entité vers modèle...${NC}"
    echo "=== Correction des conversions entité vers modèle ===" >> "$LOG_FILE"
    
    # Rechercher les fichiers avec des conversions entité vers modèle
    local conversion_files=$(grep -l --include="*.swift" "from: \$0" --exclude-dir="$BACKUP_DIR" .)
    
    for file in $conversion_files; do
        echo -e "${CYAN}Vérification de $file...${NC}"
        echo "Vérification de $file..." >> "$LOG_FILE"
        
        # Vérifier si le fichier contient des conversions potentiellement problématiques
        if grep -q "return.*map.*{ .*(from: \$0) }" "$file"; then
            backup_file "$file"
            
            # Ajouter une gestion d'erreur pour éviter les crashes
            sed -i '' 's/return \(.*\)map { \(.*\)(from: \$0) }/return \1compactMap { entity -> \2? do\n            do {\n                return try \2(from: entity)\n            } catch {\n                print("Erreur lors de la conversion: \\\(error)")\n                return nil\n            }\n        }/g' "$file"
            
            echo "  Ajout de gestion d'erreur pour les conversions entité vers modèle" >> "$LOG_FILE"
            echo -e "${GREEN}Corrections appliquées à $file${NC}"
        fi
    done
}

# Fonction pour corriger les problèmes d'ambiguïté avec PersistenceController
fix_persistence_controller_ambiguities() {
    echo -e "${BLUE}Correction des ambiguïtés avec PersistenceController...${NC}"
    echo "=== Correction des ambiguïtés avec PersistenceController ===" >> "$LOG_FILE"
    
    # Rechercher les fichiers qui utilisent PersistenceController
    local persistence_files=$(grep -l --include="*.swift" "PersistenceController" --exclude-dir="$BACKUP_DIR" .)
    
    for file in $persistence_files; do
        echo -e "${CYAN}Vérification de $file...${NC}"
        echo "Vérification de $file..." >> "$LOG_FILE"
        
        # Vérifier si le fichier est celui qui définit PersistenceController
        if grep -q "class PersistenceController" "$file"; then
            echo -e "${YELLOW}$file contient la définition de PersistenceController${NC}"
            echo "  INFO: $file contient la définition de PersistenceController" >> "$LOG_FILE"
            continue
        fi
        
        # Vérifier s'il y a des ambiguïtés
        if grep -q "'PersistenceController' is ambiguous" "$file" || grep -q "PersistenceController.*ambiguous" "$file"; then
            backup_file "$file"
            
            # Ajouter import si nécessaire
            if ! grep -q "import Core" "$file" && ! grep -q "import Core.Persistence" "$file"; then
                sed -i '' '1s/^/import Core.Persistence\n/' "$file"
                echo "  Ajout de 'import Core.Persistence'" >> "$LOG_FILE"
            fi
            
            # Qualifier PersistenceController
            sed -i '' 's/\([^\.]\)PersistenceController/\1Core.Persistence.PersistenceController/g' "$file"
            echo "  Qualification des occurrences de PersistenceController" >> "$LOG_FILE"
            
            echo -e "${GREEN}Corrections appliquées à $file${NC}"
        fi
    done
}

# Fonction pour corriger les problèmes avec le protocole CardSchedulerProtocolV2
fix_card_scheduler_protocol() {
    echo -e "${BLUE}Correction des problèmes avec CardSchedulerProtocolV2...${NC}"
    echo "=== Correction des problèmes avec CardSchedulerProtocolV2 ===" >> "$LOG_FILE"
    
    # Rechercher les fichiers qui utilisent le protocole
    local scheduler_files=$(grep -l --include="*.swift" "CardSchedulerProtocolV2" --exclude-dir="$BACKUP_DIR" .)
    
    for file in $scheduler_files; do
        echo -e "${CYAN}Vérification de $file...${NC}"
        echo "Vérification de $file..." >> "$LOG_FILE"
        
        # Vérifier s'il y a des méthodes problématiques
        if grep -q "calculateNewCore.Models.Common.MasteryLevel" "$file"; then
            backup_file "$file"
            
            # Corriger les déclarations de méthodes
            sed -i '' 's/calculateNewCore\.Models\.Common\.MasteryLevel/calculateNewMasteryLevel/g' "$file"
            echo "  Correction des déclarations de méthodes avec noms qualifiés mal formés" >> "$LOG_FILE"
            
            echo -e "${GREEN}Corrections appliquées à $file${NC}"
        fi
    done
}

# Exécution des corrections
fix_review_rating_ambiguities
fix_mastery_level_ambiguities
fix_card_review_init
fix_entity_to_model_conversions
fix_persistence_controller_ambiguities
fix_card_scheduler_protocol

echo -e "${GREEN}=== Corrections terminées ===${NC}"
echo -e "${CYAN}Journal des opérations enregistré dans: $LOG_FILE${NC}"
echo -e "${CYAN}Les sauvegardes ont été créées dans: $BACKUP_DIR${NC}"
echo -e "${YELLOW}IMPORTANT: Vérifiez que les corrections n'ont pas introduit de nouveaux problèmes.${NC}"
echo -e "${YELLOW}Il est recommandé de compiler le projet après ces modifications.${NC}" 