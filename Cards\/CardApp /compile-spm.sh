#!/bin/bash

# Configuration
LOG_FILE="build.log"
ERROR_FILE="build_errors.log"

# Fonction pour logger
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Fonction pour logger les erreurs
log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERREUR: $1" | tee -a "$ERROR_FILE" "$LOG_FILE"
}

# Nettoyer les fichiers précédents
log "Nettoyage..."
rm -f "$LOG_FILE" "$ERROR_FILE"

# Compiler avec Swift Package Manager
log "Démarrage de la compilation avec Swift Package Manager..."
swift build 2>> "$ERROR_FILE"

# Vérification du résultat
status=$?
if [ $status -eq 0 ]; then
    log "Compilation réussie!"
    log "L'application a été compilée dans .build/debug/App"
    exit 0
else
    log_error "Échec de la compilation. Voir $ERROR_FILE pour plus de détails."
    
    # Afficher les erreurs
    if [ -f "$ERROR_FILE" ]; then
        log "Dernières erreurs :"
        cat "$ERROR_FILE"
    fi
    
    exit 1
fi 