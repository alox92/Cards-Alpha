#!/bin/bash

# Définition des couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Chemin vers le fichier UnifiedStudyService.swift
FILE_PATH="Core/Services/Unified/UnifiedStudyService.swift"

# Vérifier si le fichier existe
if [ ! -f "$FILE_PATH" ]; then
    echo -e "${RED}Erreur: Le fichier $FILE_PATH n'existe pas.${NC}"
    exit 1
fi

# Créer un répertoire de sauvegarde avec horodatage
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups_syntax_fixes_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Créer une copie de sauvegarde
cp "$FILE_PATH" "$BACKUP_DIR/UnifiedStudyService.swift"
echo -e "${GREEN}Sauvegarde créée dans $BACKUP_DIR/UnifiedStudyService.swift${NC}"

# Fonction pour corriger les déclarations incorrectes de fetchRequest
fix_fetch_request_declarations() {
    echo -e "${BLUE}Correction des déclarations incorrectes de fetchRequest...${NC}"
    
    # Correction des déclarations comme :
    # let fetchRequest: NSFetchRequest<StudySessionEntity>
    # fetchRequest.fetchBatchSize = 20; fetchRequest.fetchLimit = 50
    # fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
    sed -i '' 's/let fetchRequest: NSFetchRequest<\([^>]*\)>\nfetchRequest\.fetchBatchSize = 20; fetchRequest\.fetchLimit = 50\nfetchRequest\.fetchBatchSize = 20; = \([^(]*\)\.fetchRequest()/let fetchRequest: NSFetchRequest<\1> = \2.fetchRequest()\nfetchRequest.fetchBatchSize = 20\nfetchRequest.fetchLimit = 50/g' "$FILE_PATH"
    
    echo -e "${GREEN}Déclarations de fetchRequest corrigées.${NC}"
}

# Fonction pour supprimer les doublons de blocks try-catch
fix_duplicate_try_catch() {
    echo -e "${BLUE}Suppression des doublons de blocs try-catch...${NC}"
    
    # Cette partie est plus complexe, on utilise un fichier temporaire
    TMP_FILE=$(mktemp)
    
    # Lire le fichier ligne par ligne
    remove_duplicate=false
    while IFS= read -r line; do
        if [[ "$line" == *"do {"* && "$line" != *"// Sauvegarder le contexte"* ]]; then
            # On a trouvé un premier bloc "do {"
            if grep -A 5 -F "$line" "$FILE_PATH" | grep -q "do {"; then
                # Ce bloc est suivi d'un autre bloc "do {" dans les 5 lignes suivantes
                remove_duplicate=true
                echo "$line" >> "$TMP_FILE"
            else
                echo "$line" >> "$TMP_FILE"
            fi
        elif [[ "$line" == *"do {"* && "$remove_duplicate" == true ]]; then
            # On ignore ce bloc "do {" dupliqué
            remove_duplicate=false
        elif [[ "$line" == *"} catch {"* && "$remove_duplicate" == true ]]; then
            # On ignore ce bloc "} catch {" dupliqué
            :
        elif [[ "$line" == *"throw error"* && "$remove_duplicate" == true ]]; then
            # On ignore cette ligne "throw error" dupliquée
            :
        elif [[ "$line" == *"}"* && "$remove_duplicate" == true && $(grep -A 1 -F "$line" "$FILE_PATH" | grep -c "}") -ge 2 ]]; then
            # On ignore cette accolade fermante dupliquée
            remove_duplicate=false
        else
            echo "$line" >> "$TMP_FILE"
        fi
    done < "$FILE_PATH"
    
    # Remplacer le fichier original par le fichier temporaire
    mv "$TMP_FILE" "$FILE_PATH"
    
    echo -e "${GREEN}Doublons de blocs try-catch supprimés.${NC}"
}

# Fonction pour corriger les références à fetchRequest non définies
fix_undefined_fetchrequest_references() {
    echo -e "${BLUE}Correction des références à fetchRequest non définies...${NC}"
    
    # Corriger les lignes comme :
    # fetchRequest.fetchBatchSize = 20; sessionFetchRequest.fetchLimit = 1
    sed -i '' 's/fetchRequest\.fetchBatchSize = 20; \([a-zA-Z]*\)FetchRequest\.fetchLimit = \([0-9]*\)/\1FetchRequest.fetchBatchSize = 20; \1FetchRequest.fetchLimit = \2/g' "$FILE_PATH"
    
    # Corriger les lignes comme :
    # cardsFetchRequest.predicate = NSPredicate(format: "id IN %@", cardIDs)
    # fetchRequest.fetchBatchSize = 20;
    sed -i '' 's/\([a-zA-Z]*\)FetchRequest\.predicate = .*\nfetchRequest\.fetchBatchSize = 20;/\1FetchRequest.predicate = NSPredicate(format: "id IN %@", cardIDs)\n\1FetchRequest.fetchBatchSize = 20;/g' "$FILE_PATH"
    
    echo -e "${GREEN}Références à fetchRequest non définies corrigées.${NC}"
}

# Fonction pour corriger les fermetures Task
fix_task_syntax() {
    echo -e "${BLUE}Correction de la syntaxe des Task...${NC}"
    
    # Supprimer les doublons de Task { @MainActor [weak self] in
    sed -i '' 's/Task { @MainActor \[weak self\] in\n        guard let self = self else { return }\n        Task { @MainActor \[weak self\] in\n            guard let self = self else { return }/Task { @MainActor [weak self] in\n        guard let self = self else { return }/g' "$FILE_PATH"
    
    echo -e "${GREEN}Syntaxe des Task corrigée.${NC}"
}

# Fonction principale d'exécution
main() {
    echo -e "${BLUE}Démarrage des corrections de syntaxe pour $FILE_PATH...${NC}"
    
    # Appliquer toutes les corrections
    fix_fetch_request_declarations
    fix_duplicate_try_catch
    fix_undefined_fetchrequest_references
    fix_task_syntax
    
    echo -e "${GREEN}Corrections de syntaxe terminées.${NC}"
    echo -e "${YELLOW}Note: Certaines corrections peuvent nécessiter des ajustements manuels supplémentaires.${NC}"
    echo -e "${YELLOW}La version originale du fichier a été sauvegardée dans $BACKUP_DIR/UnifiedStudyService.swift${NC}"
}

# Exécution du script
main 