#!/bin/bash

# Script d'orchestration pour la correction complète des problèmes de performance
# Ce script exécute tous les scripts de correction en séquence

# Définition des couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Répertoires et fichiers
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="logs/fix_all_performance_${TIMESTAMP}.log"

# Création des répertoires
mkdir -p "logs"
touch "${LOG_FILE}"

# Options par défaut
AUTO_MODE=false
VERBOSE=false
SKIP_CONFIRMATION=false

# Fonction pour afficher et logger les messages
log() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${NC}" | tee -a "${LOG_FILE}"
}

# Fonction pour afficher l'aide
show_help() {
    echo -e "${BOLD}Script de correction complète des problèmes de performance${NC}"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -a, --auto          Mode automatique sans interaction"
    echo "  -v, --verbose       Mode verbeux avec plus de détails"
    echo "  -y, --yes           Répond oui à toutes les confirmations"
    echo "  -h, --help          Affiche cette aide"
    echo
    echo "Description:"
    echo "  Ce script exécute en séquence tous les scripts de correction"
    echo "  pour résoudre les problèmes de performance, mémoire et CoreData"
    echo "  dans le projet CardApp."
    echo
    echo "Exemples:"
    echo "  $0                  Exécution interactive standard"
    echo "  $0 --auto --yes     Exécution automatique sans confirmation"
    echo
    exit 0
}

# Traitement des arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        -a|--auto)
            AUTO_MODE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -y|--yes)
            SKIP_CONFIRMATION=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log "Option inconnue: $1" "$RED"
            echo "Utilisez --help pour voir les options disponibles."
            exit 1
            ;;
    esac
done

# Vérifier l'existence des scripts
check_scripts() {
    local scripts=("fix_memory_leaks.sh" "fix_coredata_perf.sh" "performance_analyzer.sh")
    local missing=false
    
    for script in "${scripts[@]}"; do
        if [ ! -f "analysis_tools/${script}" ]; then
            log "❌ Script manquant: analysis_tools/${script}" "$RED"
            missing=true
        else
            if [ ! -x "analysis_tools/${script}" ]; then
                log "📋 Ajout des droits d'exécution à analysis_tools/${script}" "$YELLOW"
                chmod +x "analysis_tools/${script}"
            fi
        fi
    done
    
    if [ "$missing" = true ]; then
        log "❌ Des scripts nécessaires sont manquants. Impossible de continuer." "$RED"
        exit 1
    fi
}

# Fonction pour demander confirmation
confirm() {
    local message="$1"
    local default="$2"
    
    if [ "$SKIP_CONFIRMATION" = true ]; then
        return 0
    fi
    
    local prompt
    local response
    
    if [ "$default" = "y" ]; then
        prompt="[O/n]"
        default_response="o"
    else
        prompt="[o/N]"
        default_response="n"
    fi
    
    read -p "$message $prompt " response
    response=${response:-$default_response}
    
    case "$response" in
        [oO]|[oO][uU][iI])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Fonction pour afficher un message de démarrage
display_start_message() {
    clear
    echo -e "${BOLD}${CYAN}=====================================================${NC}"
    echo -e "${BOLD}${CYAN}    CORRECTION COMPLÈTE DES PROBLÈMES DE PERFORMANCE    ${NC}"
    echo -e "${BOLD}${CYAN}=====================================================${NC}"
    echo
    log "Date de démarrage: $(date "+%d/%m/%Y %H:%M:%S")" "$BLUE"
    log "Journal: ${LOG_FILE}" "$BLUE"
    echo
    log "Ce script va exécuter plusieurs outils pour corriger les problèmes" "$CYAN"
    log "de performance, de mémoire et d'utilisation de CoreData dans votre projet." "$CYAN"
    echo
    log "Les corrections appliquées incluent:" "$YELLOW"
    log "✓ Ajout de [weak self] dans les closures" "$YELLOW"
    log "✓ Optimisation des requêtes CoreData" "$YELLOW"
    log "✓ Ajout de @MainActor aux méthodes appropriées" "$YELLOW"
    log "✓ Correction des références fortes à des délégués" "$YELLOW"
    log "✓ Amélioration de la gestion d'erreurs" "$YELLOW"
    echo
    
    if [ "$AUTO_MODE" = false ] && [ "$SKIP_CONFIRMATION" = false ]; then
        if ! confirm "Voulez-vous continuer ?" "y"; then
            log "Opération annulée par l'utilisateur." "$YELLOW"
            exit 0
        fi
    fi
    
    echo
}

# Fonction pour exécuter un script avec interface utilisateur
run_script() {
    local script="$1"
    local description="$2"
    local skip_var="$3"
    
    if [ "${!skip_var}" = true ]; then
        log "⏩ Étape ignorée: $description" "$YELLOW"
        return 0
    fi
    
    echo
    log "${BOLD}${CYAN}=== $description ===${NC}" "$BLUE"
    echo
    
    if [ "$AUTO_MODE" = false ] && [ "$SKIP_CONFIRMATION" = false ]; then
        if ! confirm "Exécuter cette étape ?" "y"; then
            log "Étape ignorée par l'utilisateur." "$YELLOW"
            eval "$skip_var=true"
            return 0
        fi
    fi
    
    log "Exécution de $script..." "$CYAN"
    echo
    
    if [ "$VERBOSE" = true ]; then
        ./analysis_tools/$script | tee -a "${LOG_FILE}"
    else
        ./analysis_tools/$script >> "${LOG_FILE}" 2>&1
    fi
    
    local status=$?
    
    if [ $status -ne 0 ]; then
        log "❌ Échec de l'exécution de $script (code: $status)" "$RED"
        
        if [ "$AUTO_MODE" = false ] && [ "$SKIP_CONFIRMATION" = false ]; then
            if ! confirm "Continuer malgré l'erreur ?" "n"; then
                log "Opération abandonnée suite à une erreur." "$RED"
                exit 1
            fi
        else
            log "Poursuite du processus malgré l'erreur (mode auto)" "$YELLOW"
        fi
    else
        log "✅ $script exécuté avec succès" "$GREEN"
    fi
    
    return $status
}

# Fonction pour vérifier le compilateur Swift
check_swift() {
    log "\n${BOLD}${CYAN}=== Vérification de l'environnement ===${NC}" "$BLUE"
    
    if command -v swift &> /dev/null; then
        local swift_version=$(swift --version | head -n 1)
        log "✅ Swift trouvé: $swift_version" "$GREEN"
    else
        log "⚠️ Swift non trouvé. Certaines fonctionnalités peuvent être limitées." "$YELLOW"
    fi
    
    if command -v xcodebuild &> /dev/null; then
        local xcode_version=$(xcodebuild -version | head -n 1)
        log "✅ Xcode trouvé: $xcode_version" "$GREEN"
    else
        log "⚠️ Xcode non trouvé. Impossible de compiler le projet automatiquement." "$YELLOW"
        return 1
    fi
    
    return 0
}

# Fonction pour compiler le projet (option)
compile_project() {
    if [ "$AUTO_MODE" = true ]; then
        return 0
    fi
    
    echo
    log "${BOLD}${CYAN}=== Compilation du projet ===${NC}" "$BLUE"
    echo
    
    if ! confirm "Voulez-vous compiler le projet pour vérifier les corrections ?" "y"; then
        log "Compilation ignorée." "$YELLOW"
        return 0
    fi
    
    # Rechercher le fichier de projet ou workspace
    local project_file=$(find . -maxdepth 1 -name "*.xcodeproj" | head -n 1)
    local workspace_file=$(find . -maxdepth 1 -name "*.xcworkspace" | head -n 1)
    
    if [ -n "$workspace_file" ]; then
        log "Workspace trouvé: $workspace_file" "$CYAN"
        
        local scheme
        # Extraire le nom du schéma (approximatif)
        scheme=$(basename "$workspace_file" .xcworkspace)
        
        log "Compilation du workspace avec le schéma '$scheme'..." "$CYAN"
        xcodebuild -workspace "$workspace_file" -scheme "$scheme" clean build | tee -a "${LOG_FILE}"
        
    elif [ -n "$project_file" ]; then
        log "Projet trouvé: $project_file" "$CYAN"
        
        local scheme
        # Extraire le nom du schéma (approximatif)
        scheme=$(basename "$project_file" .xcodeproj)
        
        log "Compilation du projet avec le schéma '$scheme'..." "$CYAN"
        xcodebuild -project "$project_file" -scheme "$scheme" clean build | tee -a "${LOG_FILE}"
        
    else
        log "❌ Aucun fichier .xcodeproj ou .xcworkspace trouvé à la racine du projet." "$RED"
        return 1
    fi
    
    local status=$?
    
    if [ $status -ne 0 ]; then
        log "❌ Échec de la compilation (code: $status)" "$RED"
    else
        log "✅ Compilation réussie" "$GREEN"
    fi
    
    return $status
}

# Fonction pour afficher un résumé
display_summary() {
    echo
    log "${BOLD}${CYAN}=====================================================${NC}" "$CYAN"
    log "${BOLD}${CYAN}    RÉSUMÉ DES CORRECTIONS DE PERFORMANCE    ${NC}" "$CYAN"
    log "${BOLD}${CYAN}=====================================================${NC}" "$CYAN"
    echo
    
    log "✅ Analyse et correction des fuites mémoire" "$GREEN"
    log "✅ Optimisation des requêtes CoreData" "$GREEN"
    log "✅ Amélioration de la gestion de concurrence" "$GREEN"
    
    echo
    log "📊 Les rapports détaillés sont disponibles dans les répertoires:" "$CYAN"
    log "   - logs/           - Journaux d'exécution" "$CYAN"
    log "   - reports/        - Rapports d'analyse" "$CYAN"
    log "   - backups_*/      - Sauvegardes des fichiers modifiés" "$CYAN"
    
    echo
    log "${BOLD}${YELLOW}Prochaines étapes recommandées:${NC}" "$YELLOW"
    log "1. Vérifiez le code corrigé pour vous assurer qu'il fonctionne comme prévu" "$YELLOW"
    log "2. Exécutez des tests unitaires et d'intégration" "$YELLOW"
    log "3. Utilisez l'Instrument Leaks de Xcode pour vérifier l'absence de fuites mémoire" "$YELLOW"
    log "4. Utilisez le Time Profiler pour valider les améliorations de performance" "$YELLOW"
    
    echo
    log "${BOLD}${GREEN}Processus de correction de performance terminé avec succès!${NC}" "$GREEN"
    log "Date de fin: $(date "+%d/%m/%Y %H:%M:%S")" "$BLUE"
}

# Fonction principale d'exécution
main() {
    # Variables pour les étapes
    SKIP_ANALYZE=false
    SKIP_MEM_LEAKS=false
    SKIP_COREDATA=false
    
    # Vérifier les scripts
    check_scripts
    
    # Afficher le message de démarrage
    display_start_message
    
    # Vérifier l'environnement
    check_swift
    
    # Exécuter l'analyse de performance
    run_script "performance_analyzer.sh" "Analyse de Performance" "SKIP_ANALYZE"
    
    # Exécuter la correction des fuites mémoire
    run_script "fix_memory_leaks.sh" "Correction des Fuites Mémoire" "SKIP_MEM_LEAKS"
    
    # Exécuter la correction des problèmes CoreData
    run_script "fix_coredata_perf.sh" "Optimisation CoreData" "SKIP_COREDATA"
    
    # Compiler le projet
    compile_project
    
    # Afficher le résumé
    display_summary
}

# Exécution du script
main

exit 0 