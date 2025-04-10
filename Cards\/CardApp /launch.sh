#!/bin/bash

# Configuration
APP_NAME="CardApp"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/$APP_NAME"
LOG_FILE="launch.log"
ERROR_FILE="launch_errors.log"
CRASH_REPORT_DIR="crash_reports"

# Fonction pour logger
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Fonction pour logger les erreurs
log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERREUR: $1" | tee -a "$ERROR_FILE" "$LOG_FILE"
}

# Fonction pour créer un rapport de crash
create_crash_report() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local crash_file="$CRASH_REPORT_DIR/crash_$timestamp.log"
    
    mkdir -p "$CRASH_REPORT_DIR"
    
    echo "=== Rapport de Crash ===" > "$crash_file"
    echo "Date: $(date)" >> "$crash_file"
    echo "Application: $APP_NAME" >> "$crash_file"
    echo "Version: $(swift --version)" >> "$crash_file"
    echo "Système: $(sw_vers)" >> "$crash_file"
    echo "=== Logs ===" >> "$crash_file"
    cat "$LOG_FILE" >> "$crash_file"
    echo "=== Erreurs ===" >> "$crash_file"
    cat "$ERROR_FILE" >> "$crash_file"
    
    log "Rapport de crash créé: $crash_file"
}

# Fonction pour vérifier l'application
check_application() {
    log "Vérification de l'application..."
    
    if [ ! -f "$APP_PATH" ]; then
        log "L'application n'existe pas. Tentative de compilation..."
        if ! ./compile.sh; then
            log_error "Échec de la compilation"
            return 1
        fi
    fi
    
    if ! file "$APP_PATH" | grep -q "Mach-O"; then
        log_error "Le binaire n'est pas valide"
        return 1
    fi
    
    # Vérification des permissions
    if [ ! -x "$APP_PATH" ]; then
        log "Ajout des permissions d'exécution..."
        chmod +x "$APP_PATH"
    fi
    
    # Vérification des dépendances dynamiques
    if ! otool -L "$APP_PATH" &> /dev/null; then
        log_error "Erreur lors de la vérification des dépendances dynamiques"
        return 1
    fi
    
    return 0
}

# Fonction pour vérifier l'environnement
check_environment() {
    log "Vérification de l'environnement..."
    
    # Vérification de la mémoire disponible
    MEMORY=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    MEMORY_GB=$(echo "scale=2; $MEMORY * 4096 / 1024 / 1024 / 1024" | bc)
    if (( $(echo "$MEMORY_GB < 2" | bc -l) )); then
        log "Attention: Mémoire disponible faible: ${MEMORY_GB}GB"
    fi
    
    # Vérification de l'espace disque
    DISK_SPACE=$(df -h . | awk 'NR==2 {print $4}')
    log "Espace disque disponible: $DISK_SPACE"
    
    # Vérification des variables d'environnement
    if [ -z "$HOME" ]; then
        log_error "Variable HOME non définie"
        return 1
    fi
    
    return 0
}

# Fonction pour lancer l'application
launch_application() {
    log "Lancement de l'application..."
    
    # Vérification de l'application
    if ! check_application; then
        log_error "Impossible de lancer l'application"
        return 1
    fi
    
    # Vérification de l'environnement
    if ! check_environment; then
        log_error "Problèmes détectés dans l'environnement"
    fi
    
    # Lancement de l'application avec gestion des signaux
    trap 'handle_crash' SIGSEGV SIGABRT SIGILL SIGFPE
    "$APP_PATH" 2>> "$ERROR_FILE" | tee -a "$LOG_FILE"
    local status=$?
    trap - SIGSEGV SIGABRT SIGILL SIGFPE
    
    if [ $status -ne 0 ]; then
        log_error "L'application s'est terminée avec le code $status"
        create_crash_report
        return 1
    fi
    
    return 0
}

# Fonction pour gérer les crashes
handle_crash() {
    log_error "Crash détecté"
    create_crash_report
    exit 1
}

# Point d'entrée principal
main() {
    # Initialisation
    rm -f "$LOG_FILE" "$ERROR_FILE"
    mkdir -p "$CRASH_REPORT_DIR"
    
    # Lancement
    if ! launch_application; then
        log_error "Échec du lancement de l'application"
        exit 1
    fi
    
    log "Application terminée"
}

# Exécution
main 