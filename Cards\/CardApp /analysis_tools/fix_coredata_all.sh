#!/bin/bash

# Couleurs pour les sorties
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Date et heure pour les logs
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/fix_coredata_all_$TIMESTAMP.log"

# Créer les répertoires nécessaires
mkdir -p "$LOG_DIR"

# Fonction pour afficher les messages dans le terminal et les enregistrer dans le log
log_message() {
    local level="$1"
    local message="$2"
    local color="$NC"
    
    case "$level" in
        "INFO") color="$BLUE" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARNING") color="$YELLOW" ;;
        "ERROR") color="$RED" ;;
        *) color="$NC" ;;
    esac
    
    echo -e "${color}[$level] $message${NC}" | tee -a "$LOG_FILE"
}

# Fonction pour afficher le temps écoulé
function show_elapsed_time() {
    local start_time=$1
    local end_time=$2
    local elapsed=$((end_time - start_time))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))
    
    log_message "INFO" "Temps écoulé: ${minutes}m ${seconds}s"
}

# Fonction pour vérifier l'état d'exécution d'une commande
check_exit_status() {
    local exit_status=$1
    local command_name=$2
    
    if [ $exit_status -eq 0 ]; then
        log_message "SUCCESS" "$command_name terminé avec succès"
    else
        log_message "ERROR" "$command_name a échoué avec le code d'erreur $exit_status"
    fi
    
    return $exit_status
}

# Fonction pour demander confirmation avant d'exécuter une action
confirm_action() {
    local action="$1"
    local default_response="${2:-n}"
    
    local prompt
    if [[ "$default_response" == "o" ]]; then
        prompt="[O/n]"
    else
        prompt="[o/N]"
    fi
    
    while true; do
        echo -e "${YELLOW}"
        read -p "$action $prompt: " response
        echo -e "${NC}"
        
        case "$response" in
            [Oo]* ) return 0 ;;
            [Nn]* ) return 1 ;;
            "" )
                if [[ "$default_response" == "o" ]]; then
                    return 0
                else
                    return 1
                fi
                ;;
            * ) echo "Veuillez répondre par 'o' ou 'n'" ;;
        esac
    done
}

# Débuter l'enregistrement des logs
echo "=== Journal de correction des problèmes CoreData ===" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "Répertoire de travail: $(pwd)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

log_message "INFO" "Démarrage du processus de correction des problèmes CoreData"

# Étape 0: Vérifier que les scripts sont présents et exécutables
log_message "INFO" "Vérification des scripts nécessaires..."

SCRIPTS=(
    "analyze_coredata_types.sh"
    "fix_coredata_models.sh"
    "fix_coredata_ambiguities.sh"
)

scripts_ok=true
for script in "${SCRIPTS[@]}"; do
    if [ ! -f "analysis_tools/$script" ]; then
        log_message "ERROR" "Le script $script n'existe pas"
        scripts_ok=false
    elif [ ! -x "analysis_tools/$script" ]; then
        log_message "WARNING" "Le script $script n'est pas exécutable, correction en cours..."
        chmod +x "analysis_tools/$script"
        check_exit_status $? "Modification des permissions de $script"
    fi
done

if [ "$scripts_ok" = false ]; then
    log_message "ERROR" "Un ou plusieurs scripts sont manquants. Processus interrompu."
    exit 1
fi

log_message "SUCCESS" "Tous les scripts nécessaires sont présents et exécutables"

# Étape 1: Analyse des problèmes CoreData
if confirm_action "Voulez-vous analyser les problèmes de types CoreData" "o"; then
    log_message "INFO" "Démarrage de l'analyse des types CoreData..."
    start_time=$(date +%s)
    
    ./analysis_tools/analyze_coredata_types.sh | tee -a "$LOG_FILE"
    check_exit_status $? "Analyse des types CoreData"
    
    end_time=$(date +%s)
    show_elapsed_time $start_time $end_time
    
    log_message "SUCCESS" "Analyse des types CoreData terminée"
    log_message "INFO" "Un rapport détaillé a été généré dans le répertoire 'reports'"
else
    log_message "INFO" "Analyse des types CoreData ignorée"
fi

# Étape 2: Unification des modèles CoreData
if confirm_action "Voulez-vous unifier les modèles CoreData" "o"; then
    log_message "INFO" "Démarrage de l'unification des modèles CoreData..."
    start_time=$(date +%s)
    
    ./analysis_tools/fix_coredata_models.sh | tee -a "$LOG_FILE"
    check_exit_status $? "Unification des modèles CoreData"
    
    end_time=$(date +%s)
    show_elapsed_time $start_time $end_time
    
    log_message "SUCCESS" "Unification des modèles CoreData terminée"
else
    log_message "INFO" "Unification des modèles CoreData ignorée"
fi

# Étape 3: Correction des ambiguïtés de types
if confirm_action "Voulez-vous corriger les ambiguïtés de types" "o"; then
    log_message "INFO" "Démarrage de la correction des ambiguïtés de types..."
    start_time=$(date +%s)
    
    ./analysis_tools/fix_coredata_ambiguities.sh | tee -a "$LOG_FILE"
    check_exit_status $? "Correction des ambiguïtés de types"
    
    end_time=$(date +%s)
    show_elapsed_time $start_time $end_time
    
    log_message "SUCCESS" "Correction des ambiguïtés de types terminée"
else
    log_message "INFO" "Correction des ambiguïtés de types ignorée"
fi

# Étape 4: Vérification de la compilation
if confirm_action "Voulez-vous vérifier la compilation du projet" "o"; then
    log_message "INFO" "Vérification de la compilation du projet..."
    log_message "WARNING" "Cette étape peut prendre plusieurs minutes"
    
    start_time=$(date +%s)
    
    # Utiliser xcodebuild pour compiler le projet
    DEVELOPER_DIR=$(xcode-select -p)
    if [ -z "$DEVELOPER_DIR" ]; then
        log_message "ERROR" "Impossible de trouver le répertoire Xcode"
    else
        # Rechercher un fichier .xcodeproj dans le répertoire courant
        PROJECT_FILE=$(find . -maxdepth 1 -name "*.xcodeproj" | head -n 1)
        
        if [ -z "$PROJECT_FILE" ]; then
            log_message "WARNING" "Aucun fichier .xcodeproj trouvé dans le répertoire courant"
            log_message "INFO" "Tentative de compilation générique Swift..."
            
            # Compilation générique Swift
            find . -name "*.swift" | xargs swiftc -sdk $(xcrun --show-sdk-path --sdk iphonesimulator) -target arm64-apple-ios16.0-simulator -emit-module
            check_exit_status $? "Compilation générique Swift"
        else
            log_message "INFO" "Utilisation du projet $PROJECT_FILE pour la compilation"
            
            # Compilation avec xcodebuild
            xcodebuild -project "$PROJECT_FILE" -scheme "CardApp" -sdk iphonesimulator -destination "platform=iOS Simulator,name=iPhone 14" build
            check_exit_status $? "Compilation avec xcodebuild"
        fi
    fi
    
    end_time=$(date +%s)
    show_elapsed_time $start_time $end_time
    
    log_message "SUCCESS" "Vérification de la compilation terminée"
else
    log_message "INFO" "Vérification de la compilation ignorée"
fi

# Fin du script
log_message "SUCCESS" "Processus de correction des problèmes CoreData terminé"
log_message "INFO" "Consultez le journal des opérations dans $LOG_FILE"
log_message "INFO" "Consultez le guide GUIDE_COREDATA.md pour plus d'informations sur les corrections effectuées" 