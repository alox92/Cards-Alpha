#!/bin/bash

# Script de correction automatique des fuites mémoire potentielles
# Ce script détecte et corrige les cycles de référence dans les closures

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
BACKUP_DIR="backups_memory_leaks_${TIMESTAMP}"
LOG_FILE="logs/memory_leak_fixes_${TIMESTAMP}.log"
LEAK_REPORT="${BACKUP_DIR}/memory_leaks_report.md"

# Création des répertoires
mkdir -p "${BACKUP_DIR}"
mkdir -p "logs"
touch "${LOG_FILE}"
touch "${LEAK_REPORT}"

# Statistiques
TOTAL_FILES=0
FIXED_FILES=0
TOTAL_LEAKS=0
FIXED_LEAKS=0

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

# Fonction pour ajouter un entête au rapport
initialize_report() {
    cat > "${LEAK_REPORT}" << EOF
# Rapport de Correction des Fuites Mémoire

Date: $(date "+%d/%m/%Y %H:%M:%S")

Ce rapport détaille les fuites mémoire potentielles détectées et corrigées dans le projet CardApp.

## Types de fuites mémoire corrigées

1. **Cycles de référence dans les closures** : Ajout de \`[weak self]\` dans les closures
2. **Références fortes à des délégués** : Conversion en références faibles
3. **Captures non nécessaires** : Optimisation des captures dans les closures

## Fichiers corrigés

EOF
}

# Fonction pour mettre à jour le rapport avec un fichier corrigé
update_report() {
    local file="$1"
    local leaks="$2"
    local fixes="$3"
    
    cat >> "${LEAK_REPORT}" << EOF
### $(basename "$file")

- **Fuites potentielles détectées** : $leaks
- **Corrections appliquées** : $fixes

\`\`\`swift
$(cat "$file" | grep -A 2 -B 2 "\[weak self\]" | head -15)
...
\`\`\`

EOF
}

# Fonction pour corriger les closures sans [weak self]
fix_closures() {
    log "\n${BOLD}🔍 Analyse des closures sans [weak self]...${NC}" "$BLUE"
    
    # Patterns de closures à corriger
    CLOSURE_PATTERNS=(
        "Task\s*{"
        "DispatchQueue\..*async.*{"
        "\.sink\s*\("
        "\.onReceive\s*\("
        "\.onChange\s*\("
        "completion:\s*{"
        "success:\s*{"
        "failure:\s*{"
        "\.perform\s*{"
    )
    
    # Construire la chaîne de recherche
    SEARCH_PATTERN=$(IFS="|"; echo "${CLOSURE_PATTERNS[*]}")
    
    # Trouver tous les fichiers Swift contenant des closures
    local files=$(grep -l -E "$SEARCH_PATTERN" --include="*.swift" -r . --exclude-dir="${BACKUP_DIR}")
    
    TOTAL_FILES=$(echo "$files" | wc -l)
    
    for file in $files; do
        log "Analyse de $file..." "$CYAN"
        
        # Vérifier s'il y a des closures sans [weak self] mais utilisant self
        local leaks=$(grep -n -E "$SEARCH_PATTERN" "$file" | 
                     grep -v "\[weak self\]" | 
                     grep -v "\[unowned self\]" | 
                     grep -B 5 -A 5 "self\." | 
                     wc -l)
        
        TOTAL_LEAKS=$((TOTAL_LEAKS + leaks))
        
        if [ "$leaks" -gt 0 ]; then
            backup_file "$file"
            local fixes=0
            
            # Corriger les closures Task
            if grep -q "Task\s*{" "$file" && grep -q "self\." "$file"; then
                sed -i '' 's/Task\s*{/Task { [weak self] in\
            guard let self = self else { return }/g' "$file"
                fixes=$((fixes + $(grep -c "Task { \[weak self\]" "$file")))
            fi
            
            # Corriger les closures DispatchQueue
            if grep -q "DispatchQueue" "$file" && grep -q "self\." "$file"; then
                sed -i '' 's/DispatchQueue\.\([a-z]*\)\.\([a-z]*\)(\([^)]*\))\s*{/DispatchQueue.\1.\2(\3) { [weak self] in\
            guard let self = self else { return }/g' "$file"
                fixes=$((fixes + $(grep -c "DispatchQueue.*{ \[weak self\]" "$file")))
            fi
            
            # Corriger les closures sink
            if grep -q "\.sink" "$file" && grep -q "self\." "$file"; then
                sed -i '' 's/\.sink(receiveValue:\s*{/\.sink(receiveValue: { [weak self] in\
            guard let self = self else { return }/g' "$file"
                sed -i '' 's/\.sink(receiveCompletion:\s*{/\.sink(receiveCompletion: { [weak self] in\
            guard let self = self else { return }/g' "$file"
                fixes=$((fixes + $(grep -c "\.sink.*{ \[weak self\]" "$file")))
            fi
            
            # Corriger les closures onReceive
            if grep -q "\.onReceive" "$file" && grep -q "self\." "$file"; then
                sed -i '' 's/\.onReceive(\([^)]*\))\s*{/\.onReceive(\1) { [weak self] in\
            guard let self = self else { return }/g' "$file"
                fixes=$((fixes + $(grep -c "\.onReceive.*{ \[weak self\]" "$file")))
            fi
            
            # Corriger les closures onChange
            if grep -q "\.onChange" "$file" && grep -q "self\." "$file"; then
                sed -i '' 's/\.onChange(of:\s*\([^)]*\))\s*{/\.onChange(of: \1) { [weak self] in\
            guard let self = self else { return }/g' "$file"
                fixes=$((fixes + $(grep -c "\.onChange.*{ \[weak self\]" "$file")))
            fi
            
            # Corriger les closures completion
            if grep -q "completion:" "$file" && grep -q "self\." "$file"; then
                sed -i '' 's/completion:\s*{/completion: { [weak self] in\
            guard let self = self else { return }/g' "$file"
                fixes=$((fixes + $(grep -c "completion: { \[weak self\]" "$file")))
            fi
            
            # Corriger les closures success/failure
            if grep -q "success:" "$file" && grep -q "self\." "$file"; then
                sed -i '' 's/success:\s*{/success: { [weak self] in\
            guard let self = self else { return }/g' "$file"
                fixes=$((fixes + $(grep -c "success: { \[weak self\]" "$file")))
            fi
            
            if grep -q "failure:" "$file" && grep -q "self\." "$file"; then
                sed -i '' 's/failure:\s*{/failure: { [weak self] in\
            guard let self = self else { return }/g' "$file"
                fixes=$((fixes + $(grep -c "failure: { \[weak self\]" "$file")))
            fi
            
            # Corriger les closures perform
            if grep -q "\.perform" "$file" && grep -q "self\." "$file"; then
                sed -i '' 's/\.perform\s*{/\.perform { [weak self] in\
            guard let self = self else { return }/g' "$file"
                fixes=$((fixes + $(grep -c "\.perform { \[weak self\]" "$file")))
            fi
            
            FIXED_LEAKS=$((FIXED_LEAKS + fixes))
            FIXED_FILES=$((FIXED_FILES + 1))
            
            log "✅ Corrigé $fixes/$leaks fuites potentielles dans $file" "$GREEN"
            update_report "$file" "$leaks" "$fixes"
        else
            log "✓ Aucune fuite potentielle détectée dans $file" "$GREEN"
        fi
    done
}

# Fonction pour corriger les délégués sans weak
fix_delegates() {
    log "\n${BOLD}🔍 Analyse des délégués sans weak...${NC}" "$BLUE"
    
    # Trouver tous les fichiers Swift contenant des délégués
    local files=$(grep -l -E "var\s+\w+Delegate|var\s+\w+DataSource" --include="*.swift" -r . --exclude-dir="${BACKUP_DIR}")
    
    for file in $files; do
        log "Analyse de $file..." "$CYAN"
        
        # Vérifier s'il y a des délégués sans weak
        if grep -q -E "var\s+\w+Delegate|var\s+\w+DataSource" "$file" && ! grep -q -E "weak\s+var\s+\w+Delegate|weak\s+var\s+\w+DataSource" "$file"; then
            backup_file "$file"
            
            # Corriger les délégués
            sed -i '' 's/var\s\+\(\w\+Delegate\)/weak var \1/g' "$file"
            sed -i '' 's/var\s\+\(\w\+DataSource\)/weak var \1/g' "$file"
            
            local fixes=$(grep -c -E "weak\s+var\s+\w+Delegate|weak\s+var\s+\w+DataSource" "$file")
            FIXED_LEAKS=$((FIXED_LEAKS + fixes))
            FIXED_FILES=$((FIXED_FILES + 1))
            
            log "✅ Ajout de weak à $fixes délégués dans $file" "$GREEN"
            update_report "$file" "$fixes" "$fixes"
        else
            log "✓ Délégués déjà correctement déclarés dans $file" "$GREEN"
        fi
    done
}

# Fonction pour finaliser le rapport
finalize_report() {
    cat >> "${LEAK_REPORT}" << EOF

## Résumé

- **Fichiers analysés** : $TOTAL_FILES
- **Fichiers corrigés** : $FIXED_FILES
- **Fuites potentielles détectées** : $TOTAL_LEAKS
- **Corrections appliquées** : $FIXED_LEAKS

## Recommandations

1. **Utiliser systématiquement \`[weak self]\`** dans les closures qui capturent \`self\`
2. **Déclarer les délégués comme \`weak var\`** pour éviter les cycles de référence
3. **Éviter les captures fortes inutiles** dans les closures
4. **Considérer l'utilisation de types valeurs** (struct) quand c'est possible
5. **Vérifier les graphs d'objets complexes** pour détecter d'autres cycles de référence

## Notes

Les corrections appliquées par ce script sont des solutions génériques. 
Dans certains cas, des optimisations supplémentaires spécifiques au contexte peuvent être nécessaires.

Pour vérifier l'efficacité des corrections, utilisez l'Instrument "Leaks" de Xcode.
EOF
}

# Fonction principale d'exécution
main() {
    log "${BOLD}${CYAN}=== DÉMARRAGE DES CORRECTIONS DE FUITES MÉMOIRE ===${NC}" "$BLUE"
    log "Date: $(date "+%d/%m/%Y %H:%M:%S")" "$CYAN"
    log "Répertoire de sauvegarde: ${BACKUP_DIR}" "$CYAN"
    echo
    
    # Initialiser le rapport
    initialize_report
    
    # Exécuter les corrections
    fix_closures
    fix_delegates
    
    # Finaliser le rapport
    finalize_report
    
    log "\n${BOLD}${GREEN}=== CORRECTIONS TERMINÉES ===${NC}" "$GREEN"
    log "✅ ${FIXED_LEAKS}/${TOTAL_LEAKS} fuites potentielles corrigées dans ${FIXED_FILES}/${TOTAL_FILES} fichiers" "$GREEN"
    log "📝 Journal des modifications: ${LOG_FILE}" "$CYAN"
    log "📊 Rapport détaillé: ${LEAK_REPORT}" "$CYAN"
    log "💾 Les fichiers originaux ont été sauvegardés dans: ${BACKUP_DIR}" "$CYAN"
    echo
    log "${YELLOW}Note: Certaines modifications complexes peuvent nécessiter une vérification manuelle.${NC}" "$YELLOW"
    log "${YELLOW}Nous vous recommandons de compiler et tester l'application après ces modifications.${NC}" "$YELLOW"
}

# Exécution du script
main

exit 0 