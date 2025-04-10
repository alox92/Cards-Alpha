#!/bin/bash

# Configuration
BUILD_DIR="build"
SWIFT_FILES="swift_files.txt"
TARGET="arm64-apple-macosx12.0"
SDK_PATH=$(xcrun --show-sdk-path --sdk macosx)
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
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
rm -f "$LOG_FILE" "$ERROR_FILE"

# Générer la liste des fichiers Swift
log "Génération de la liste des fichiers Swift..."
./files.sh

# Vérification des fichiers
if [ ! -f "$SWIFT_FILES" ]; then
    log_error "$SWIFT_FILES n'existe pas"
    exit 1
fi

# Compilation simplifiée
log "Démarrage de la compilation..."
files_to_compile=$(cat "$SWIFT_FILES")
file_count=$(echo "$files_to_compile" | wc -l)
log "Compilation de $file_count fichiers..."

# Compilation avec gestion des erreurs détaillée
swiftc -swift-version 5 \
    -target "$TARGET" \
    -sdk "$SDK_PATH" \
    -F "$(xcrun --show-sdk-path)/System/Library/Frameworks" \
    -I . \
    -parse-as-library \
    -o "$BUILD_DIR/CardApp" \
    $files_to_compile 2>> "$ERROR_FILE"

# Vérification du résultat
status=$?
if [ $status -eq 0 ]; then
    log "Compilation réussie!"
    log "L'application a été compilée dans $BUILD_DIR/CardApp"
    
    # Rendre l'application exécutable
    chmod +x "$BUILD_DIR/CardApp"
    log "Permissions d'exécution ajoutées"
    
    exit 0
else
    log_error "Échec de la compilation. Voir $ERROR_FILE pour plus de détails."
    
    # Afficher les erreurs
    if [ -f "$ERROR_FILE" ]; then
        log "Dernières erreurs :"
        tail -n 20 "$ERROR_FILE"
    fi
    
    exit 1
fi
