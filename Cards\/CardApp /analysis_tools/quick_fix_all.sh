#!/bin/bash

# Couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups_quick_fix_$TIMESTAMP"
SUMMARY_FILE="$BACKUP_DIR/summary.txt"

# Création du répertoire de sauvegarde
mkdir -p "$BACKUP_DIR"
echo -e "${GREEN}Répertoire de sauvegarde créé: $BACKUP_DIR${NC}"

# Fonction pour afficher la durée
duration() {
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    echo -e "${BLUE}Durée: ${minutes}m ${seconds}s${NC}"
}

# Fonction pour afficher un titre de section
section() {
    echo -e "\n${YELLOW}===================================================${NC}"
    echo -e "${YELLOW}== $1${NC}"
    echo -e "${YELLOW}===================================================${NC}"
    echo -e "== $1" >> "$SUMMARY_FILE"
}

# Fonction pour exécuter un script avec gestion d'erreur
run_script() {
    local script="$1"
    local description="$2"
    
    section "$description"
    echo "Exécution de $script..."
    echo "Exécution de $script..." >> "$SUMMARY_FILE"
    
    if [ -x "$script" ]; then
        local start_time=$(date +%s)
        if bash "$script" | tee -a "$SUMMARY_FILE"; then
            echo -e "${GREEN}✓ $script exécuté avec succès${NC}"
            echo "✓ $script exécuté avec succès" >> "$SUMMARY_FILE"
            duration
        else
            echo -e "${RED}✗ Erreur lors de l'exécution de $script${NC}"
            echo "✗ Erreur lors de l'exécution de $script" >> "$SUMMARY_FILE"
            duration
            return 1
        fi
    else
        echo -e "${RED}✗ Le script $script n'existe pas ou n'est pas exécutable${NC}"
        echo "✗ Le script $script n'existe pas ou n'est pas exécutable" >> "$SUMMARY_FILE"
        return 1
    fi
    
    return 0
}

# Sauvegarde des fichiers importants avant modification
backup_important_files() {
    section "Sauvegarde des fichiers importants"
    echo "Sauvegarde des fichiers importants dans $BACKUP_DIR..."
    
    # Sauvegarde du fichier PersistenceController
    if [ -f "Core/Persistence/PersistenceController.swift" ]; then
        cp "Core/Persistence/PersistenceController.swift" "$BACKUP_DIR/"
        echo -e "${GREEN}✓ PersistenceController.swift sauvegardé${NC}"
    fi
    
    # Sauvegarde de UnifiedStudyService
    if [ -f "Core/Services/Unified/UnifiedStudyService.swift" ]; then
        cp "Core/Services/Unified/UnifiedStudyService.swift" "$BACKUP_DIR/"
        echo -e "${GREEN}✓ UnifiedStudyService.swift sauvegardé${NC}"
    fi
    
    # Sauvegarde de StudyService
    if [ -f "Core/Services/Study/StudyService.swift" ]; then
        cp "Core/Services/Study/StudyService.swift" "$BACKUP_DIR/"
        echo -e "${GREEN}✓ StudyService.swift sauvegardé${NC}"
    fi
    
    # Sauvegarde de CardReviewEntity
    if [ -f "Core/Models/Data/CardReviewEntity.swift" ]; then
        cp "Core/Models/Data/CardReviewEntity.swift" "$BACKUP_DIR/"
        echo -e "${GREEN}✓ CardReviewEntity.swift sauvegardé${NC}"
    fi
    
    echo -e "${GREEN}✓ Sauvegarde des fichiers importants terminée${NC}"
    echo "✓ Sauvegarde des fichiers importants terminée" >> "$SUMMARY_FILE"
}

# Corrections manuelles connues
apply_manual_fixes() {
    section "Application des corrections manuelles connues"
    
    # Correction du PersistenceController
    if [ -f "Core/Persistence/PersistenceController.swift" ]; then
        echo "Correction de PersistenceController.swift..."
        sed -i '' 's/container = NSPersistentContainer(name: "[^"]*")/container = NSPersistentContainer(name: "CardApp")/' "Core/Persistence/PersistenceController.swift"
        echo -e "${GREEN}✓ PersistenceController.swift corrigé${NC}"
    fi
    
    echo -e "${GREEN}✓ Corrections manuelles terminées${NC}"
    echo "✓ Corrections manuelles terminées" >> "$SUMMARY_FILE"
}

# Nettoyage après les corrections
clean_up() {
    section "Nettoyage et vérifications finales"
    
    # Nettoyage des fichiers temporaires
    echo "Suppression des fichiers temporaires..."
    find . -name "*.temp" -type f -delete
    
    # Nettoyage de la compilation
    echo "Nettoyage des fichiers de compilation..."
    if [ -d "build" ]; then
        rm -rf build
        echo -e "${GREEN}✓ Dossier build supprimé${NC}"
    fi
    
    echo -e "${GREEN}✓ Nettoyage terminé${NC}"
    echo "✓ Nettoyage terminé" >> "$SUMMARY_FILE"
}

# Exécution des scripts de correction
main() {
    section "DÉBUT DU PROCESSUS DE CORRECTION AUTOMATIQUE"
    echo "Date: $(date)" >> "$SUMMARY_FILE"
    
    # Sauvegarde des fichiers importants
    backup_important_files
    
    # Corrections manuelles connues
    apply_manual_fixes
    
    # Exécution des scripts de correction dans l'ordre
    run_script "analysis_tools/fix_coredata_models.sh" "Correction des modèles CoreData"
    run_script "analysis_tools/fix_coredata_conversions.sh" "Correction des conversions CoreData"
    run_script "analysis_tools/fix_imports.sh" "Correction des imports problématiques"
    run_script "analysis_tools/fix_unified_study_service.sh" "Correction du UnifiedStudyService"
    
    # Nettoyage après correction
    clean_up
    
    section "FIN DU PROCESSUS DE CORRECTION AUTOMATIQUE"
    echo -e "\n${GREEN}Toutes les corrections ont été appliquées.${NC}"
    echo -e "${YELLOW}Les backups sont disponibles dans: $BACKUP_DIR${NC}"
    echo -e "${YELLOW}Consultez $SUMMARY_FILE pour un résumé des opérations effectuées.${NC}"
    echo -e "\nIl est fortement recommandé de compiler le projet pour vérifier que toutes les corrections sont valides."
}

# Exécution de la fonction principale
main 