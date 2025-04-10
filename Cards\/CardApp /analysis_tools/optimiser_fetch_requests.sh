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
BACKUP_DIR="backups_optimisation_fetchrequest_${TIMESTAMP}"
LOG_FILE="logs/optimisation_fetchrequest_${TIMESTAMP}.log"
FETCH_BATCH_SIZE="20"

# Créer les répertoires nécessaires
mkdir -p "$BACKUP_DIR"
mkdir -p "logs"

echo -e "${BOLD}${CYAN}=== ANALYSE ET OPTIMISATION DES FETCHREQUESTS ===${RESET}" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Log initial
echo "Date d'exécution: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "Répertoire de sauvegarde: $BACKUP_DIR" | tee -a "$LOG_FILE"
echo "Taille de lot par défaut: $FETCH_BATCH_SIZE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Fonction pour optimiser un fichier Swift
optimize_file() {
    local file=$1
    local file_content=$(cat "$file")
    local original_file_content="$file_content"
    local modified=false
    local batch_size_added=0
    local fetch_limit_added=0
    
    # 1. Rechercher les NSFetchRequest sans fetchBatchSize
    if grep -q "NSFetchRequest" "$file" && ! grep -q "fetchBatchSize" "$file"; then
        echo -e "${YELLOW}⚠️ FetchRequest sans fetchBatchSize dans $file${RESET}" | tee -a "$LOG_FILE"
        
        # Pattern pour la création de fetchRequest
        local patterns=(
            "let [a-zA-Z0-9_]* = NSFetchRequest<[a-zA-Z0-9_]*>\(entityName:"
            "let [a-zA-Z0-9_]*: NSFetchRequest<[a-zA-Z0-9_]*> = NSFetchRequest\(entityName:"
            "let [a-zA-Z0-9_]* = [a-zA-Z0-9_]*\.fetchRequest\("
            "[a-zA-Z0-9_]*\.fetchRequest\("
        )
        
        for pattern in "${patterns[@]}"; do
            # Trouver toutes les occurrences du pattern
            while read -r line_number line_content; do
                if [[ -n "$line_number" && -n "$line_content" ]]; then
                    # Vérifier si la ligne contient déjà fetchBatchSize
                    if [[ ! "$line_content" =~ "fetchBatchSize" && ! "$line_content" =~ "//.*fetchBatchSize" ]]; then
                        # Vérifier les lignes suivantes pour fetchBatchSize
                        local has_batch_size=false
                        local end_line=$((line_number + 5))
                        for ((i=line_number+1; i<=end_line; i++)); do
                            local next_line=$(sed -n "${i}p" "$file")
                            if [[ "$next_line" =~ "fetchBatchSize" ]]; then
                                has_batch_size=true
                                break
                            fi
                            # Si on trouve la fin du bloc ou une autre instruction, on arrête la recherche
                            if [[ "$next_line" =~ "return" || "$next_line" =~ "}" || "$next_line" =~ "let" || "$next_line" =~ "var" ]]; then
                                break
                            fi
                        done
                        
                        if [ "$has_batch_size" = false ]; then
                            # Trouver une ligne appropriée pour insérer fetchBatchSize
                            local insert_line=$((line_number + 1))
                            local indent=$(echo "$line_content" | sed -E 's/^([[:space:]]*).*/\1/')
                            
                            # Construire la ligne à insérer
                            local insert_content="${indent}request.fetchBatchSize = $FETCH_BATCH_SIZE"
                            
                            # Insérer la ligne
                            file_content=$(echo "$file_content" | awk -v n="$insert_line" -v s="$insert_content" 'NR==n{print s}1')
                            modified=true
                            ((batch_size_added++))
                            
                            echo -e "${GREEN}✅ Ajout de fetchBatchSize ligne $insert_line dans $file${RESET}" | tee -a "$LOG_FILE"
                        fi
                    fi
                fi
            done < <(grep -n -E "$pattern" "$file" | sed -E 's/([0-9]+):.*/\1 &/')
        done
    fi
    
    # 2. Rechercher les fetchRequests qui devraient avoir un fetchLimit
    if grep -q "NSFetchRequest" "$file"; then
        # Rechercher des indices qu'un fetchLimit pourrait être approprié
        local patterns=(
            "request.predicate = NSPredicate\(format:.*== %@"
            "request.predicate = NSPredicate\(format:.*= %@"
            "fetchOne"
            "first"
            "getOrCreate"
            "findOne"
        )
        
        for pattern in "${patterns[@]}"; do
            # Trouver toutes les occurrences du pattern
            while read -r line_number line_content; do
                if [[ -n "$line_number" && -n "$line_content" ]]; then
                    # Vérifier si la ligne ou les lignes suivantes contiennent déjà fetchLimit
                    local has_fetch_limit=false
                    local context_start=$((line_number - 5))
                    local context_end=$((line_number + 5))
                    [[ $context_start -lt 1 ]] && context_start=1
                    
                    for ((i=context_start; i<=context_end; i++)); do
                        local check_line=$(sed -n "${i}p" "$file")
                        if [[ "$check_line" =~ "fetchLimit" ]]; then
                            has_fetch_limit=true
                            break
                        fi
                    done
                    
                    # Vérifier si le contexte indique qu'on ne veut qu'un seul résultat
                    local single_result=false
                    for ((i=context_start; i<=context_end; i++)); do
                        local check_line=$(sed -n "${i}p" "$file")
                        if [[ "$check_line" =~ "first" || "$check_line" =~ "findOne" || "$check_line" =~ "getOrCreate" ]]; then
                            single_result=true
                            break
                        fi
                    done
                    
                    if [ "$has_fetch_limit" = false ] && [ "$single_result" = true ]; then
                        # Trouver la ligne d'origine du NSFetchRequest
                        local request_line=0
                        for ((i=line_number-5; i<=line_number; i++)); do
                            local check_line=$(sed -n "${i}p" "$file")
                            if [[ "$check_line" =~ "NSFetchRequest" || "$check_line" =~ "fetchRequest" ]]; then
                                request_line=$i
                                break
                            fi
                        done
                        
                        if [ $request_line -gt 0 ]; then
                            # Trouver un bon endroit pour insérer fetchLimit (après predicate si possible)
                            local insert_line=$((line_number + 1))
                            local indent=$(echo "$line_content" | sed -E 's/^([[:space:]]*).*/\1/')
                            
                            # Construire la ligne à insérer
                            local insert_content="${indent}request.fetchLimit = 1"
                            
                            # Insérer la ligne
                            file_content=$(echo "$file_content" | awk -v n="$insert_line" -v s="$insert_content" 'NR==n{print s}1')
                            modified=true
                            ((fetch_limit_added++))
                            
                            echo -e "${GREEN}✅ Ajout de fetchLimit ligne $insert_line dans $file${RESET}" | tee -a "$LOG_FILE"
                        fi
                    fi
                fi
            done < <(grep -n -E "$pattern" "$file" | sed -E 's/([0-9]+):.*/\1 &/')
        done
    fi
    
    # 3. Si des modifications ont été faites, sauvegarder et mettre à jour le fichier
    if [ "$modified" = true ]; then
        # Sauvegarder le fichier original
        cp "$file" "${BACKUP_DIR}/$(basename "$file")"
        
        # Écrire le contenu modifié
        echo "$file_content" > "$file"
        
        echo -e "${GREEN}✅ Optimisation complète pour $file ($batch_size_added fetchBatchSize, $fetch_limit_added fetchLimit ajoutés)${RESET}" | tee -a "$LOG_FILE"
    fi
}

# Rechercher tous les fichiers Swift qui utilisent NSFetchRequest
echo -e "${BOLD}${BLUE}Recherche des fichiers contenant des NSFetchRequest...${RESET}" | tee -a "$LOG_FILE"
FILES=$(grep -l "NSFetchRequest" --include="*.swift" -r .)

# Variables pour le rapport
TOTAL_FILES=0
MODIFIED_FILES=0
BATCH_SIZE_ADDED_TOTAL=0
FETCH_LIMIT_ADDED_TOTAL=0

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
        local batch_added=$(diff -y --suppress-common-lines "$file" "${BACKUP_DIR}/$(basename "$file")" | grep -c "fetchBatchSize")
        local limit_added=$(diff -y --suppress-common-lines "$file" "${BACKUP_DIR}/$(basename "$file")" | grep -c "fetchLimit")
        
        ((BATCH_SIZE_ADDED_TOTAL += batch_added))
        ((FETCH_LIMIT_ADDED_TOTAL += limit_added))
    fi
done

# Résumé
echo -e "\n${BOLD}${CYAN}=== RÉSUMÉ DES OPTIMISATIONS ===${RESET}" | tee -a "$LOG_FILE"
echo -e "${BLUE}Fichiers analysés: $TOTAL_FILES${RESET}" | tee -a "$LOG_FILE"
echo -e "${BLUE}Fichiers modifiés: $MODIFIED_FILES${RESET}" | tee -a "$LOG_FILE"
echo -e "${BLUE}FetchBatchSize ajoutés: $BATCH_SIZE_ADDED_TOTAL${RESET}" | tee -a "$LOG_FILE"
echo -e "${BLUE}FetchLimit ajoutés: $FETCH_LIMIT_ADDED_TOTAL${RESET}" | tee -a "$LOG_FILE"

# Créer un rapport de résultats
REPORT_FILE="rapports_coredata/optimisation_fetchrequest_${TIMESTAMP}.md"
mkdir -p "rapports_coredata"

cat > "$REPORT_FILE" << EOT
# Rapport d'Optimisation des FetchRequests

Date: $(date '+%Y-%m-%d %H:%M:%S')

## Résumé

- **Fichiers analysés:** $TOTAL_FILES
- **Fichiers optimisés:** $MODIFIED_FILES
- **FetchBatchSize ajoutés:** $BATCH_SIZE_ADDED_TOTAL
- **FetchLimit ajoutés:** $FETCH_LIMIT_ADDED_TOTAL

## Détails des modifications

Les modifications suivantes ont été appliquées automatiquement:

1. **Ajout de fetchBatchSize = $FETCH_BATCH_SIZE** à tous les NSFetchRequest qui n'en avaient pas
2. **Ajout de fetchLimit = 1** aux requêtes qui récupèrent un seul élément

## Impact attendu

Ces optimisations permettront:

- **Réduction de la consommation mémoire** en chargeant les résultats par lots
- **Amélioration des performances** en limitant le nombre de résultats récupérés
- **Optimisation des requêtes** en réduisant la charge sur CoreData

## Fichiers modifiés

$(for file in $(find "$BACKUP_DIR" -type f); do
    relative_file=${file#"$BACKUP_DIR/"}
    echo "- \`${relative_file}\`"
done)

## Recommandations supplémentaires

1. **Précharger les relations fréquemment accédées** avec \`relationshipKeyPathsForPrefetching\`
2. **Utiliser les contextes d'arrière-plan** pour les opérations lourdes
3. **Mettre en place des tests de performance** pour mesurer l'impact des optimisations

## Conclusion

Les optimisations automatiques ont été appliquées avec succès. Les fichiers originaux ont été sauvegardés dans \`$BACKUP_DIR\`.
Pour des optimisations plus spécifiques, une analyse manuelle peut être nécessaire.
EOT

echo -e "${GREEN}✅ Rapport d'optimisation généré: $REPORT_FILE${RESET}" | tee -a "$LOG_FILE"

echo -e "\n${BOLD}${GREEN}=== OPTIMISATION DES FETCHREQUESTS TERMINÉE ===${RESET}" | tee -a "$LOG_FILE"
echo -e "${GREEN}✅ Journal des opérations sauvegardé dans $LOG_FILE${RESET}"
echo -e "${GREEN}✅ Fichiers originaux sauvegardés dans $BACKUP_DIR${RESET}" 