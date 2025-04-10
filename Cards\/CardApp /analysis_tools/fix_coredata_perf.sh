#!/bin/bash

# Script de correction automatique des problèmes de performance CoreData
# Ce script corrige les problèmes de performance CoreData courants dans le projet CardApp

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
BACKUP_DIR="backups_coredata_perf_${TIMESTAMP}"
LOG_FILE="logs/coredata_perf_fixes_${TIMESTAMP}.log"

# Création des répertoires
mkdir -p "${BACKUP_DIR}"
mkdir -p "logs"
touch "${LOG_FILE}"

# Fonction pour afficher et logger les messages
log() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${NC}" | tee -a "${LOG_FILE}"
}

# Fonction pour créer une sauvegarde d'un fichier
backup_file() {
    local file="$1"
    local backup_path="${BACKUP_DIR}/$(basename "$file")"
    cp "$file" "$backup_path"
    log "Sauvegarde créée: $backup_path" "$BLUE"
}

# Fonction pour ajouter fetchBatchSize aux requêtes fetchRequest
fix_fetch_batch_size() {
    log "\n${BOLD}🔧 Ajout de fetchBatchSize aux requêtes...${NC}" "$BLUE"
    
    # Trouver tous les fichiers Swift contenant NSFetchRequest
    local files=$(grep -l "NSFetchRequest" --include="*.swift" -r . --exclude-dir="${BACKUP_DIR}")
    
    for file in $files; do
        log "Analyse de $file..." "$CYAN"
        
        # Vérifier si le fichier contient des requêtes sans fetchBatchSize
        if grep -q "NSFetchRequest" "$file" && ! grep -q "fetchBatchSize" "$file"; then
            backup_file "$file"
            
            # Ajouter fetchBatchSize après les déclarations de NSFetchRequest
            sed -i '' 's/\(let [a-zA-Z]*[fF]etchRequest.*= .*\)/\1\
        \1Request.fetchBatchSize = 20/g' "$file"
            
            # Ajouter fetchBatchSize après les affectations de prédicat
            sed -i '' 's/\([a-zA-Z]*[fF]etchRequest\)\.predicate = \(.*\)/\1.predicate = \2\
        \1.fetchBatchSize = 20/g' "$file"
            
            log "✅ Ajout de fetchBatchSize à $file" "$GREEN"
        else
            log "⏩ Fichier déjà optimisé ou ne contient pas de NSFetchRequest" "$YELLOW"
        fi
    done
}

# Fonction pour ajouter @MainActor aux méthodes utilisant viewContext
fix_main_actor() {
    log "\n${BOLD}🔧 Ajout de @MainActor aux méthodes utilisant viewContext...${NC}" "$BLUE"
    
    # Trouver tous les fichiers Swift contenant viewContext
    local files=$(grep -l "viewContext" --include="*.swift" -r . --exclude-dir="${BACKUP_DIR}")
    
    for file in $files; do
        log "Analyse de $file..." "$CYAN"
        
        # Vérifier si le fichier contient des références à viewContext sans @MainActor
        if grep -q "viewContext" "$file" && ! grep -q "@MainActor" "$file"; then
            backup_file "$file"
            
            # Ajouter @MainActor aux déclarations de classe
            sed -i '' 's/\(public \)\([a-zA-Z]\+\) class \([a-zA-Z]\+\)/\1@MainActor \2 class \3/g' "$file"
            
            # Ajouter @MainActor aux déclarations de fonction qui utilisent viewContext
            awk '
            BEGIN { in_func = 0; func_start = 0; uses_view_context = 0; }
            
            /func [a-zA-Z]+/ {
                in_func = 1;
                func_start = NR;
                uses_view_context = 0;
            }
            
            /viewContext/ && in_func {
                uses_view_context = 1;
            }
            
            /}/ && in_func {
                in_func = 0;
                if (uses_view_context && func_start > 0) {
                    system("sed -i \"\" \"" func_start "s/func /@MainActor func /\" \"" FILENAME "\"");
                }
            }
            
            { print }
            ' "$file" > /dev/null
            
            log "✅ Ajout de @MainActor à $file" "$GREEN"
        else
            log "⏩ Fichier déjà optimisé ou ne contient pas de viewContext" "$YELLOW"
        fi
    done
}

# Fonction pour corriger l'utilisation des contextes d'arrière-plan
fix_background_contexts() {
    log "\n${BOLD}🔧 Optimisation des contextes d'arrière-plan...${NC}" "$BLUE"
    
    # Trouver tous les fichiers Swift contenant des opérations CoreData lourdes
    local files=$(grep -l -E "fetch\(|save\(|delete\(" --include="*.swift" -r . --exclude-dir="${BACKUP_DIR}")
    
    for file in $files; do
        log "Analyse de $file..." "$CYAN"
        
        # Vérifier si le fichier contient des opérations lourdes sur le thread principal
        if grep -q "viewContext" "$file" && grep -q -E "fetch\(|delete\(" "$file"; then
            backup_file "$file"
            
            # Examiner le contenu du fichier pour des modifications plus ciblées
            if grep -q "func.*async" "$file"; then
                # Le fichier a des fonctions async, nous pouvons améliorer l'utilisation des contextes
                
                # Convertir les opérations viewContext.fetch en opérations en arrière-plan
                sed -i '' 's/\(let [a-zA-Z]\+ = try \)viewContext\.fetch/\1await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[NSManagedObject], Error>) in\
            let context = persistenceController.container.newBackgroundContext()\
            context.perform {\
                do {\
                    let results = try context.fetch/g' "$file"
                
                # Fermer les blocs ouverts par la modification précédente
                sed -i '' 's/\(let [a-zA-Z]\+ = try await withCheckedThrowingContinuation.*fetch\)\(.*\)/\1\2\
                    continuation.resume(returning: results)\
                } catch {\
                    continuation.resume(throwing: error)\
                }\
            }\
        }/g' "$file"
                
                log "✅ Optimisation des contextes dans $file" "$GREEN"
            else
                log "⚠️ Des modifications manuelles plus complexes sont nécessaires pour $file" "$YELLOW"
            fi
        else
            log "⏩ Fichier déjà optimisé ou ne nécessite pas d'optimisation" "$YELLOW"
        fi
    done
}

# Fonction pour ajouter la gestion d'erreurs
fix_error_handling() {
    log "\n${BOLD}🔧 Ajout de la gestion d'erreurs pour les opérations CoreData...${NC}" "$BLUE"
    
    # Trouver tous les fichiers Swift contenant des opérations save() sans try-catch
    local files=$(grep -l "context\.save()" --include="*.swift" -r . --exclude-dir="${BACKUP_DIR}")
    
    for file in $files; do
        log "Analyse de $file..." "$CYAN"
        
        # Vérifier s'il y a des appels save() sans try-catch
        if grep -q "context\.save()" "$file" && ! grep -q "try context\.save()" "$file"; then
            backup_file "$file"
            
            # Remplacer les appels save() par des versions avec try-catch
            sed -i '' 's/context\.save()/do {\
                try context.save()\
            } catch {\
                print("Erreur lors de la sauvegarde: \\(error)")\
                throw error\
            }/g' "$file"
            
            log "✅ Ajout de la gestion d'erreurs à $file" "$GREEN"
        else
            log "⏩ Fichier déjà optimisé ou ne nécessite pas d'optimisation" "$YELLOW"
        fi
    done
}

# Fonction pour ajouter les weak self dans les blocs Task/closures
fix_weak_self() {
    log "\n${BOLD}🔧 Ajout de [weak self] dans les closures CoreData...${NC}" "$BLUE"
    
    # Trouver tous les fichiers Swift contenant des closures avec CoreData
    local files=$(grep -l -E "Task\s*{|DispatchQueue.*{|context.perform\s*{" --include="*.swift" -r . --exclude-dir="${BACKUP_DIR}")
    
    for file in $files; do
        log "Analyse de $file..." "$CYAN"
        
        # Vérifier s'il y a des closures sans [weak self]
        if grep -q -E "Task\s*{|DispatchQueue.*{|context.perform\s*{" "$file" && grep -q "self\." "$file" && ! grep -q "\[weak self\]" "$file"; then
            backup_file "$file"
            
            # Ajouter [weak self] aux closures Task
            sed -i '' 's/Task\s*{/Task { [weak self] in\
            guard let self = self else { return }/g' "$file"
            
            # Ajouter [weak self] aux closures DispatchQueue
            sed -i '' 's/DispatchQueue\.[a-z]*\.[a-z]*(\([^)]*\))\s*{/DispatchQueue.main.async(\1) { [weak self] in\
            guard let self = self else { return }/g' "$file"
            
            # Ajouter [weak self] aux closures context.perform
            sed -i '' 's/context\.perform\s*{/context.perform { [weak self] in\
            guard let self = self else { return }/g' "$file"
            
            log "✅ Ajout de [weak self] à $file" "$GREEN"
        else
            log "⏩ Fichier déjà optimisé ou ne nécessite pas d'optimisation" "$YELLOW"
        fi
    done
}

# Fonction principale d'exécution
main() {
    log "${BOLD}${CYAN}=== DÉMARRAGE DES CORRECTIONS DE PERFORMANCE COREDATA ===${NC}" "$BLUE"
    log "Date: $(date "+%d/%m/%Y %H:%M:%S")" "$CYAN"
    log "Répertoire de sauvegarde: ${BACKUP_DIR}" "$CYAN"
    echo
    
    # Exécuter toutes les corrections
    fix_fetch_batch_size
    fix_main_actor
    fix_background_contexts
    fix_error_handling
    fix_weak_self
    
    log "\n${BOLD}${GREEN}=== CORRECTIONS TERMINÉES ===${NC}" "$GREEN"
    log "✅ Toutes les corrections ont été appliquées" "$GREEN"
    log "📝 Journal des modifications: ${LOG_FILE}" "$CYAN"
    log "💾 Les fichiers originaux ont été sauvegardés dans: ${BACKUP_DIR}" "$CYAN"
    echo
    log "${YELLOW}Note: Certaines modifications complexes peuvent nécessiter une vérification manuelle.${NC}" "$YELLOW"
    log "${YELLOW}Nous vous recommandons de compiler et tester l'application après ces modifications.${NC}" "$YELLOW"
}

# Exécution du script
main

exit 0 