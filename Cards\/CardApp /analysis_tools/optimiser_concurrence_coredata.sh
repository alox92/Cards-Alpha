#!/bin/bash

# Couleurs pour le terminal
RESET="\033[0m"
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"

# Configuration
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
BACKUP_DIR="backups_concurrence_coredata_${TIMESTAMP}"
LOG_FILE="logs/concurrence_coredata_${TIMESTAMP}.log"

# Créer les répertoires nécessaires
mkdir -p "$BACKUP_DIR"
mkdir -p "logs"

echo -e "${BOLD}${CYAN}=== OPTIMISATION DE LA CONCURRENCE POUR COREDATA ===${RESET}" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Log initial
echo "Date d'exécution: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "Répertoire de sauvegarde: $BACKUP_DIR" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Fonction pour ajouter @MainActor aux méthodes utilisant viewContext
optimize_main_actor() {
    local file=$1
    local file_content=$(cat "$file")
    local original_file_content="$file_content"
    local modified=false
    local main_actor_added=0
    
    # Rechercher les méthodes qui utilisent viewContext sans @MainActor
    if grep -q "viewContext" "$file"; then
        echo -e "${YELLOW}⚠️ Utilisation de viewContext détectée dans $file${RESET}" | tee -a "$LOG_FILE"
        
        # Analyser le fichier ligne par ligne pour trouver les méthodes
        local line_number=0
        local in_method=false
        local method_start=0
        local method_name=""
        local method_lines=""
        local methods_to_annotate=()
        
        while IFS= read -r line; do
            ((line_number++))
            
            # Détecter le début d'une méthode
            if [[ "$line" =~ func[[:space:]]+([a-zA-Z0-9_]+)[[:space:]]*\( && ! "$line" =~ "@MainActor" && ! "$in_method" ]]; then
                in_method=true
                method_start=$line_number
                method_name=$(echo "$line" | sed -n 's/.*func[[:space:]]\+\([a-zA-Z0-9_]\+\).*/\1/p')
                method_lines="$line"
            elif [[ "$in_method" == true ]]; then
                method_lines="$method_lines\n$line"
                
                # Détecter l'utilisation de viewContext dans la méthode
                if [[ "$line" =~ viewContext && ! "$line" =~ "DispatchQueue.main" ]]; then
                    methods_to_annotate+=("$method_start:$method_name")
                fi
                
                # Détecter la fin de la méthode
                if [[ "$line" =~ ^[[:space:]]*}[[:space:]]*$ ]]; then
                    in_method=false
                fi
            fi
        done < "$file"
        
        # Ajouter @MainActor aux méthodes identifiées
        for method_info in "${methods_to_annotate[@]}"; do
            local start_line=$(echo "$method_info" | cut -d: -f1)
            local method=$(echo "$method_info" | cut -d: -f2)
            
            # Vérifier que la méthode n'est pas déjà annotée
            local prev_line=$(sed -n "$((start_line-1))p" "$file")
            if [[ ! "$prev_line" =~ "@MainActor" ]]; then
                # Trouver l'indentation de la ligne de début de méthode
                local current_line=$(sed -n "${start_line}p" "$file")
                local indent=$(echo "$current_line" | sed -E 's/^([[:space:]]*).*/\1/')
                
                # Construire la ligne d'annotation
                local annotation="${indent}@MainActor"
                
                # Insérer l'annotation
                file_content=$(echo "$file_content" | awk -v n="$start_line" -v s="$annotation" 'NR==n{print s}1')
                modified=true
                ((main_actor_added++))
                
                echo -e "${GREEN}✅ Ajout de @MainActor à la méthode $method dans $file${RESET}" | tee -a "$LOG_FILE"
            fi
        done
    fi
    
    # Si des modifications ont été faites, sauvegarder le fichier
    if [ "$modified" = true ]; then
        cp "$file" "${BACKUP_DIR}/$(basename "$file")"
        echo "$file_content" > "$file"
        echo -e "${GREEN}✅ Optimisation de @MainActor complète pour $file ($main_actor_added annotations ajoutées)${RESET}" | tee -a "$LOG_FILE"
    fi
}

# Fonction pour ajouter [weak self] aux closures
optimize_weak_self() {
    local file=$1
    local file_content=$(cat "$file")
    local original_file_content="$file_content"
    local modified=false
    local weak_self_added=0
    
    # Rechercher les closures qui utilisent self sans [weak self]
    if grep -q "self\." "$file"; then
        local patterns=(
            "DispatchQueue.main.async[[:space:]]*{"
            "Task[[:space:]]*{"
            "\.async[[:space:]]*{"
            "\.sink[[:space:]]*{"
            "performBackgroundTask[[:space:]]*{"
            "\.perform[[:space:]]*{"
            "\.setCompletionHandler[[:space:]]*{"
            "completion:[[:space:]]*{"
        )
        
        for pattern in "${patterns[@]}"; do
            # Trouver toutes les occurrences du pattern
            while read -r line_number line_content; do
                if [[ -n "$line_number" && -n "$line_content" ]]; then
                    # Vérifier si la ligne contient déjà [weak self]
                    if [[ ! "$line_content" =~ "\[weak self\]" ]]; then
                        # Vérifier si self est utilisé dans les lignes suivantes
                        local self_used=false
                        local end_line=$((line_number + 20))  # Vérifier jusqu'à 20 lignes après
                        local brace_count=1
                        
                        for ((i=line_number+1; i<=end_line; i++)); do
                            if [ $brace_count -eq 0 ]; then
                                break
                            fi
                            
                            local next_line=$(sed -n "${i}p" "$file")
                            
                            # Compter les accolades pour déterminer la fin de la closure
                            if [[ "$next_line" =~ "{" ]]; then
                                ((brace_count++))
                            fi
                            if [[ "$next_line" =~ "}" ]]; then
                                ((brace_count--))
                            fi
                            
                            if [[ "$next_line" =~ "self\." ]]; then
                                self_used=true
                            fi
                        done
                        
                        if [ "$self_used" = true ]; then
                            # Trouver l'accolade d'ouverture
                            local opening_brace_pos=$(echo "$line_content" | grep -o "{" | tail -1)
                            if [ -n "$opening_brace_pos" ]; then
                                # Construire la ligne modifiée
                                local modified_line=$(echo "$line_content" | sed 's/{/ { [weak self] in/')
                                
                                # Remplacer la ligne dans le contenu du fichier
                                file_content=$(echo "$file_content" | sed "${line_number}s|${line_content}|${modified_line}|")
                                
                                # Vérifier s'il faut ajouter le guard
                                local has_guard=false
                                for ((i=line_number+1; i<=end_line; i++)); do
                                    local next_line=$(sed -n "${i}p" "$file")
                                    if [[ "$next_line" =~ "guard let self = self" ]]; then
                                        has_guard=true
                                        break
                                    fi
                                done
                                
                                if [ "$has_guard" = false ]; then
                                    # Déterminer l'indentation à utiliser
                                    local indent=$(echo "$line_content" | sed -E 's/^([[:space:]]*).*/\1/')
                                    local inner_indent="${indent}    "
                                    
                                    # Construire la ligne de guard
                                    local guard_line="${inner_indent}guard let self = self else { return }"
                                    
                                    # Insérer le guard après l'accolade d'ouverture
                                    file_content=$(echo "$file_content" | awk -v n="$((line_number+1))" -v s="$guard_line" 'NR==n{print s}1')
                                fi
                                
                                modified=true
                                ((weak_self_added++))
                                
                                echo -e "${GREEN}✅ Ajout de [weak self] à une closure à la ligne $line_number dans $file${RESET}" | tee -a "$LOG_FILE"
                            fi
                        fi
                    fi
                fi
            done < <(grep -n -E "$pattern" "$file" | sed -E 's/([0-9]+):.*/\1 &/')
        done
    fi
    
    # Si des modifications ont été faites, sauvegarder le fichier
    if [ "$modified" = true ]; then
        [ ! -f "${BACKUP_DIR}/$(basename "$file")" ] && cp "$file" "${BACKUP_DIR}/$(basename "$file")"
        echo "$file_content" > "$file"
        echo -e "${GREEN}✅ Optimisation de [weak self] complète pour $file ($weak_self_added closures optimisées)${RESET}" | tee -a "$LOG_FILE"
    fi
}

# Fonction pour optimiser les contextes d'arrière-plan
optimize_background_contexts() {
    local file=$1
    local file_content=$(cat "$file")
    local original_file_content="$file_content"
    local modified=false
    local background_contexts_added=0
    
    # Rechercher les opérations lourdes avec CoreData sans contexte d'arrière-plan
    if grep -q "NSFetchRequest" "$file" && ! grep -q "performBackgroundTask" "$file"; then
        # Rechercher des indices d'opérations potentiellement lourdes
        local patterns=(
            "fetch\(.*\)[[:space:]]*{"
            "for[[:space:]]+.*[[:space:]]+in[[:space:]]+.*results"
            "context\.save"
            "\.batchDelete"
            "\.execute"
        )
        
        for pattern in "${patterns[@]}"; do
            # Trouver toutes les occurrences du pattern
            while read -r line_number line_content; do
                if [[ -n "$line_number" && -n "$line_content" ]]; then
                    # Vérifier si l'opération est déjà dans un contexte d'arrière-plan
                    local in_background=false
                    local context_start=$((line_number - 15))
                    local context_end=$((line_number + 5))
                    [[ $context_start -lt 1 ]] && context_start=1
                    
                    for ((i=context_start; i<=context_end; i++)); do
                        local check_line=$(sed -n "${i}p" "$file")
                        if [[ "$check_line" =~ "performBackgroundTask" || "$check_line" =~ "DispatchQueue.global" || "$check_line" =~ "@background" ]]; then
                            in_background=true
                            break
                        fi
                    done
                    
                    # Si on n'est pas dans un contexte d'arrière-plan et qu'on est dans une méthode sans @MainActor
                    if [ "$in_background" = false ]; then
                        # Trouver la méthode englobante
                        local method_start=0
                        local method_name=""
                        for ((i=line_number; i>=1; i--)); do
                            local check_line=$(sed -n "${i}p" "$file")
                            if [[ "$check_line" =~ func[[:space:]]+([a-zA-Z0-9_]+) ]]; then
                                method_start=$i
                                method_name=$(echo "$check_line" | sed -n 's/.*func[[:space:]]\+\([a-zA-Z0-9_]\+\).*/\1/p')
                                break
                            fi
                        done
                        
                        if [ $method_start -gt 0 ]; then
                            # Vérifier si la méthode est déjà annotée avec @MainActor
                            local prev_line=$(sed -n "$((method_start-1))p" "$file")
                            if [[ ! "$prev_line" =~ "@MainActor" ]]; then
                                # Ajouter un commentaire suggérant une optimisation
                                local indent=$(echo "$line_content" | sed -E 's/^([[:space:]]*).*/\1/')
                                local comment="${indent}// TODO: Considérer d'utiliser performBackgroundTask pour cette opération potentiellement lourde"
                                
                                file_content=$(echo "$file_content" | awk -v n="$line_number" -v s="$comment" 'NR==n{print s}1')
                                modified=true
                                ((background_contexts_added++))
                                
                                echo -e "${YELLOW}⚠️ Suggestion d'optimisation pour l'opération à la ligne $line_number dans $file${RESET}" | tee -a "$LOG_FILE"
                            fi
                        fi
                    fi
                fi
            done < <(grep -n -E "$pattern" "$file" | sed -E 's/([0-9]+):.*/\1 &/')
        done
    fi
    
    # Si des modifications ont été faites, sauvegarder le fichier
    if [ "$modified" = true ]; then
        [ ! -f "${BACKUP_DIR}/$(basename "$file")" ] && cp "$file" "${BACKUP_DIR}/$(basename "$file")"
        echo "$file_content" > "$file"
        echo -e "${GREEN}✅ Optimisation des contextes d'arrière-plan complète pour $file ($background_contexts_added suggestions ajoutées)${RESET}" | tee -a "$LOG_FILE"
    fi
}

# Fonction principale qui optimise un fichier
optimize_file() {
    local file=$1
    
    # 1. Optimiser l'utilisation de @MainActor
    optimize_main_actor "$file"
    
    # 2. Optimiser les closures avec [weak self]
    optimize_weak_self "$file"
    
    # 3. Optimiser les contextes d'arrière-plan
    optimize_background_contexts "$file"
}

# Rechercher tous les fichiers Swift qui utilisent CoreData
echo -e "${BOLD}${BLUE}Recherche des fichiers utilisant CoreData...${RESET}" | tee -a "$LOG_FILE"
FILES=$(grep -l -E "viewContext|NSFetchRequest|NSManagedObject|CoreData" --include="*.swift" -r .)

# Variables pour le rapport
TOTAL_FILES=0
MODIFIED_FILES=0
MAIN_ACTOR_ADDED_TOTAL=0
WEAK_SELF_ADDED_TOTAL=0
BACKGROUND_OPTIMIZATIONS_TOTAL=0

# Traiter chaque fichier
for file in $FILES; do
    ((TOTAL_FILES++))
    echo -e "\n${BOLD}${BLUE}Analyse de $file...${RESET}" | tee -a "$LOG_FILE"
    
    # Vérifier si le fichier existe
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Le fichier $file n'existe pas${RESET}" | tee -a "$LOG_FILE"
        continue
    fi
    
    # Optimiser le fichier
    optimize_file "$file"
    
    # Compter le nombre de fichiers modifiés
    if [ -f "${BACKUP_DIR}/$(basename "$file")" ]; then
        ((MODIFIED_FILES++))
        
        # Compter les ajouts
        local main_actor_added=$(diff "$file" "${BACKUP_DIR}/$(basename "$file")" | grep -c "@MainActor")
        local weak_self_added=$(diff "$file" "${BACKUP_DIR}/$(basename "$file")" | grep -c "\[weak self\]")
        local background_optimizations=$(diff "$file" "${BACKUP_DIR}/$(basename "$file")" | grep -c "TODO: Considérer d'utiliser performBackgroundTask")
        
        ((MAIN_ACTOR_ADDED_TOTAL += main_actor_added))
        ((WEAK_SELF_ADDED_TOTAL += weak_self_added))
        ((BACKGROUND_OPTIMIZATIONS_TOTAL += background_optimizations))
    fi
done

# Résumé
echo -e "\n${BOLD}${CYAN}=== RÉSUMÉ DES OPTIMISATIONS DE CONCURRENCE ===${RESET}" | tee -a "$LOG_FILE"
echo -e "${BLUE}Fichiers analysés: $TOTAL_FILES${RESET}" | tee -a "$LOG_FILE"
echo -e "${BLUE}Fichiers modifiés: $MODIFIED_FILES${RESET}" | tee -a "$LOG_FILE"
echo -e "${BLUE}@MainActor ajoutés: $MAIN_ACTOR_ADDED_TOTAL${RESET}" | tee -a "$LOG_FILE"
echo -e "${BLUE}[weak self] ajoutés: $WEAK_SELF_ADDED_TOTAL${RESET}" | tee -a "$LOG_FILE"
echo -e "${BLUE}Suggestions d'optimisation de contexte: $BACKGROUND_OPTIMIZATIONS_TOTAL${RESET}" | tee -a "$LOG_FILE"

# Créer un rapport de résultats
REPORT_FILE="rapports_coredata/optimisation_concurrence_${TIMESTAMP}.md"
mkdir -p "rapports_coredata"

cat > "$REPORT_FILE" << EOT
# Rapport d'Optimisation de la Concurrence CoreData

Date: $(date '+%Y-%m-%d %H:%M:%S')

## Résumé

- **Fichiers analysés:** $TOTAL_FILES
- **Fichiers optimisés:** $MODIFIED_FILES
- **@MainActor ajoutés:** $MAIN_ACTOR_ADDED_TOTAL
- **[weak self] ajoutés:** $WEAK_SELF_ADDED_TOTAL
- **Suggestions d'optimisation de contexte:** $BACKGROUND_OPTIMIZATIONS_TOTAL

## Détails des modifications

Les modifications suivantes ont été appliquées automatiquement:

1. **Ajout de @MainActor** aux méthodes qui utilisent \`viewContext\`
2. **Ajout de [weak self]** aux closures qui capturent \`self\`
3. **Suggestions d'optimisation** pour les opérations potentiellement lourdes

## Impact attendu

Ces optimisations permettront:

- **Réduction des fuites mémoire** en évitant les cycles de référence
- **Amélioration de la réactivité de l'UI** en séparant les opérations lourdes
- **Sécurisation de l'accès à CoreData** en respectant les contraintes de thread

## Fichiers modifiés

$(for file in $(find "$BACKUP_DIR" -type f); do
    relative_file=${file#"$BACKUP_DIR/"}
    echo "- \`${relative_file}\`"
done)

## Recommandations supplémentaires

1. **Utiliser Task.detached** pour les opérations qui ne nécessitent pas d'accès à l'UI
2. **Implémenter un modèle Actor** pour encapsuler l'accès à CoreData
3. **Tester rigoureusement** les modifications pour s'assurer qu'elles n'introduisent pas de bugs

## Conclusion

Les optimisations de concurrence ont été appliquées avec succès. Les fichiers originaux ont été sauvegardés dans \`$BACKUP_DIR\`.
Pour des optimisations plus avancées, une analyse manuelle et une restructuration plus profonde peuvent être nécessaires.
EOT

echo -e "${GREEN}✅ Rapport d'optimisation généré: $REPORT_FILE${RESET}" | tee -a "$LOG_FILE"

echo -e "\n${BOLD}${GREEN}=== OPTIMISATION DE LA CONCURRENCE TERMINÉE ===${RESET}" | tee -a "$LOG_FILE"
echo -e "${GREEN}✅ Journal des opérations sauvegardé dans $LOG_FILE${RESET}"
echo -e "${GREEN}✅ Fichiers originaux sauvegardés dans $BACKUP_DIR${RESET}" 