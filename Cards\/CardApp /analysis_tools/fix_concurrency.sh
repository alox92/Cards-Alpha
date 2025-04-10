#!/bin/bash

# Couleurs pour les sorties
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Timestamp pour les logs et sauvegardes
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups_concurrency_$TIMESTAMP"
LOG_FILE="logs/concurrency_fix_$TIMESTAMP.log"

# Créer les répertoires nécessaires
mkdir -p "$BACKUP_DIR"
mkdir -p "logs"

echo "=== Correction des problèmes de Swift Concurrency ===" | tee -a "$LOG_FILE"
echo "Date: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Fonction pour afficher les messages
log_message() {
    echo -e "${2}$1${NC}" | tee -a "$LOG_FILE"
}

# Fonction pour sauvegarder un fichier
backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "$BACKUP_DIR/$(basename "$1")"
        log_message "Sauvegarde de $1 effectuée" "$BLUE"
    fi
}

# Liste des fichiers à corriger
FILES_TO_CHECK=(
    "Core/Services/Unified/UnifiedStudyService.swift"
    "Core/Services/Study/StudyService.swift"
    "Core/Persistence/PersistenceController.swift"
    "Core/Persistence/CoreDataMigration.swift"
    "Core/Tools/CoreDataOptimizer.swift"
)

# Recherche de fichiers supplémentaires avec des problèmes de concurrence
ADDITIONAL_FILES=$(grep -l --include="*.swift" -r -E "(@Sendable|asyncHandler|withCheckedThrowingContinuation|await|NonIsolated|@MainActor)" --exclude-dir="$BACKUP_DIR" .)
if [ ! -z "$ADDITIONAL_FILES" ]; then
    for file in $ADDITIONAL_FILES; do
        if [[ ! " ${FILES_TO_CHECK[@]} " =~ " ${file} " ]]; then
            FILES_TO_CHECK+=("$file")
        fi
    done
fi

log_message "Fichiers à vérifier: ${#FILES_TO_CHECK[@]}" "$YELLOW"

# Fonction pour corriger les problèmes de concurrence dans un fichier
fix_concurrency_issues() {
    local file=$1
    
    if [ ! -f "$file" ]; then
        log_message "Fichier $file non trouvé" "$RED"
        return
    fi
    
    backup_file "$file"
    log_message "Traitement de $file..." "$BLUE"
    
    # 1. Ajouter @MainActor aux fonctions qui utilisent viewContext
    if grep -q "viewContext" "$file" && ! grep -q "@MainActor" "$file"; then
        # Ajouter @MainActor au niveau de la classe
        sed -i '' 's/\(public\|final\|class\|struct\) \([^:]*\):/\1 @MainActor \2:/g' "$file"
        log_message "- @MainActor ajouté à la classe/struct" "$GREEN"
    fi
    
    # 2. Corriger les problèmes de capture de context NSManagedObjectContext
    if grep -q "context.*fetch" "$file"; then
        # Ajouter [weak context] dans les closures qui capturent context
        sed -i '' 's/{ \(.*\)context\.\(.*\)}/{ [weak context] \1guard let context = context else { return nil }\n            context.\2}/g' "$file"
        log_message "- Capture [weak context] ajoutée" "$GREEN"
    fi
    
    # 3. Corriger les NSMergeByPropertyObjectTrumpMergePolicy
    if grep -q "NSMergeByPropertyObjectTrumpMergePolicy" "$file"; then
        # Remplacer par NSMergePolicy.mergeByPropertyObjectTrump
        sed -i '' 's/NSMergeByPropertyObjectTrumpMergePolicy/NSMergePolicy.mergeByPropertyObjectTrump/g' "$file"
        log_message "- NSMergePolicy.mergeByPropertyObjectTrump corrigé" "$GREEN"
    fi
    
    # 4. Corriger model.entities pour type optionnel
    if grep -q "model\.entities" "$file"; then
        # Remplacer model.entities par model.entities?
        sed -i '' 's/guard let entities = model\.entities else/let entities = model.entities\n        guard let entities = entities else/g' "$file"
        log_message "- entities optionnel corrigé" "$GREEN"
    fi
    
    # 5. Corriger les Task dupliqués
    if grep -q "Task { @MainActor \[weak self\] in.*Task { @MainActor \[weak self\] in" "$file"; then
        sed -i '' 's/Task { @MainActor \[weak self\] in\n[^T]*Task { @MainActor \[weak self\] in/Task { @MainActor [weak self] in/g' "$file"
        log_message "- Task dupliqués corrigés" "$GREEN"
    fi
    
    # 6. Ajouter nonisolated aux fonctions qui ne devraient pas être isolées
    if grep -q "func.*-> [A-Za-z0-9]*" "$file" && ! grep -q "nonisolated func" "$file"; then
        # Trouver les fonctions qui retournent des valeurs simples
        sed -i '' 's/func \([a-zA-Z0-9_]*\)(\([^)]*\)) -> \(Bool\|String\|Int\|Double\|UUID\|Date\) {/nonisolated func \1(\2) -> \3 {/g' "$file"
        log_message "- nonisolated ajouté aux fonctions simples" "$GREEN"
    fi
    
    # 7. Corriger les captures de NSFetchRequest
    if grep -q "NSFetchRequest<.*> in" "$file"; then
        sed -i '' 's/\(fetchRequest.*NSFetchRequest<[^>]*>\) in/[fetchRequest = \1] in/g' "$file"
        log_message "- Capture de NSFetchRequest corrigée" "$GREEN"
    fi
    
    # 8. Corriger les problèmes d'import nonisolated
    if grep -q "import Core.Commonnonisolated" "$file"; then
        sed -i '' 's/import Core\.Commonnonisolated/import Core.Common\nnonisolated/g' "$file"
        log_message "- import Core.Commonnonisolated corrigé" "$GREEN"
    fi
    
    # 9. Corriger UUID?.uuidString
    if grep -q "UUID?\.uuidString" "$file" || grep -q "id?\.uuidString" "$file"; then
        sed -i '' 's/\(UUID\|id\)?\.uuidString/\1.uuidString/g' "$file"
        log_message "- UUID?.uuidString corrigé" "$GREEN"
    fi
}

# Traiter chaque fichier
for file in "${FILES_TO_CHECK[@]}"; do
    fix_concurrency_issues "$file"
done

# Correction spécifique pour UnifiedStudyService.swift
if [ -f "Core/Services/Unified/UnifiedStudyService.swift" ]; then
    log_message "Corrections spécifiques pour UnifiedStudyService.swift..." "$YELLOW"
    
    # Corriger les paramètres des méthodes
    sed -i '' 's/newCore\.Models\.Common\.MasteryLevel:/newMasteryLevel:/g' "Core/Services/Unified/UnifiedStudyService.swift"
    
    # Corriger les initialisations de CardReview
    if grep -q "CardReview(.*newMasteryLevel:" "Core/Services/Unified/UnifiedStudyService.swift"; then
        log_message "- Initialisations de CardReview corrigées" "$GREEN"
    fi
    
    # Corriger les définitions de protocole
    if grep -q "protocol.*CardSchedulerProtocolV2" "Core/Services/Unified/UnifiedStudyService.swift"; then
        sed -i '' 's/calculateNewCore\.Models\.Common\.MasteryLevel/calculateNewMasteryLevel/g' "Core/Services/Unified/UnifiedStudyService.swift"
        log_message "- Définitions de protocole corrigées" "$GREEN"
    fi
    
    # Faire un second passage pour les références à self qui pourraient causer des cycles
    grep -n "\bself\.[a-zA-Z]" "Core/Services/Unified/UnifiedStudyService.swift" | while read -r line; do
        line_num=$(echo "$line" | cut -d':' -f1)
        # Vérifier si cette ligne est dans une closure et n'a pas déjà [weak self]
        context_before=$(head -n "$line_num" "Core/Services/Unified/UnifiedStudyService.swift" | tail -n 5)
        if echo "$context_before" | grep -q "{" && ! echo "$context_before" | grep -q "\[weak self\]"; then
            log_message "- Ligne $line_num: Potentiel cycle de référence avec self" "$YELLOW"
        fi
    done
    
    log_message "Corrections pour UnifiedStudyService.swift terminées" "$GREEN"
fi

log_message "=== Corrections de concurrence terminées ===" "$GREEN"
log_message "Vérifiez la compilation du projet pour vous assurer que tous les problèmes de concurrence ont été résolus." "$YELLOW"
log_message "Si vous rencontrez toujours des problèmes, consultez les logs pour plus de détails: $LOG_FILE" "$YELLOW"
log_message "Les fichiers originaux ont été sauvegardés dans: $BACKUP_DIR" "$BLUE" 