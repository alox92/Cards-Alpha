#!/bin/bash

# ============================================================
# SCRIPT DE DÉBOGAGE RAPIDE POUR CARDAPP
# ============================================================
#
# Ce script se focalise sur les corrections rapides des problèmes critiques:
# 1. Problèmes de mémoire ([weak self], cycles de référence)
# 2. Problèmes CoreData (fetchBatchSize, try/catch)
#
# Auteur: Claude
# Version: 1.0

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Configuration
PROJECT_DIR=$(pwd)
SWIFT_FILES_LIST="$PROJECT_DIR/swift_files.txt"
LOG_FILE="$PROJECT_DIR/fast_debug.log"

# Vérifier si la liste des fichiers Swift existe
if [ ! -f "$SWIFT_FILES_LIST" ]; then
    echo -e "${BLUE}Génération de la liste des fichiers Swift...${RESET}"
    find "$PROJECT_DIR" -name "*.swift" > "$SWIFT_FILES_LIST"
fi

echo -e "${GREEN}=== DÉMARRAGE DU DÉBOGAGE RAPIDE CARDAPP ===${RESET}"
echo "Date: $(date)" | tee -a "$LOG_FILE"
echo "Projet: $PROJECT_DIR" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ÉTAPE 1: Vérification des weak delegates
echo -e "${BLUE}1. Vérification des délégués sans weak...${RESET}" | tee -a "$LOG_FILE"
DELEGATES_COUNT=0
FIXED_DELEGATES=0

while IFS= read -r file; do
    if grep -q "var.*[dD]elegate.*:" "$file" && ! grep -q "weak var.*[dD]elegate" "$file"; then
        delegate_lines=$(grep -n "var.*[dD]elegate.*:" "$file" | grep -v "weak var")
        DELEGATES_COUNT=$((DELEGATES_COUNT + $(echo "$delegate_lines" | wc -l)))
        
        echo "Fichier: $file" | tee -a "$LOG_FILE"
        echo "$delegate_lines" | tee -a "$LOG_FILE"
        
        # Correction automatique
        if [[ "$file" != *"/Protocols/"* ]]; then
            sed -i '' 's/var\s\+\(\w*[dD]elegate\)/weak var \1/g' "$file"
            FIXED_DELEGATES=$((FIXED_DELEGATES + $(echo "$delegate_lines" | wc -l)))
            echo "  ✅ Corrigé" | tee -a "$LOG_FILE"
        else
            echo "  ❌ Non corrigé (dans dossier Protocols)" | tee -a "$LOG_FILE"
        fi
        echo "" | tee -a "$LOG_FILE"
    fi
done < "$SWIFT_FILES_LIST"

echo "Délégués trouvés: $DELEGATES_COUNT, Corrigés: $FIXED_DELEGATES" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ÉTAPE 2: Vérification des [weak self]
echo -e "${BLUE}2. Vérification des closures sans [weak self]...${RESET}" | tee -a "$LOG_FILE"
CLOSURES_COUNT=0
FIXED_CLOSURES=0

while IFS= read -r file; do
    # Rechercher les closures qui utilisent self sans [weak self]
    if grep -q "self\." "$file" && grep -q "\{.*in" "$file"; then
        # Lignes avec des closures
        closure_start_lines=$(grep -n "\{.*in" "$file" | cut -d':' -f1)
        
        for line_num in $closure_start_lines; do
            # Extraire la closure et quelques lignes suivantes
            closure_content=$(tail -n +$line_num "$file" | head -n 20)
            
            # Vérifier si la closure utilise self mais n'a pas de [weak self]
            if echo "$closure_content" | grep -q "self\." && ! echo "$closure_content" | grep -q "\[\s*weak\s\+self\s*\]"; then
                CLOSURES_COUNT=$((CLOSURES_COUNT + 1))
                
                echo "Fichier: $file, Ligne: $line_num" | tee -a "$LOG_FILE"
                echo "$(echo "$closure_content" | head -n 3 | sed 's/^/  /')" | tee -a "$LOG_FILE"
                echo "  ... (utilise self sans [weak self])" | tee -a "$LOG_FILE"
                
                # Pour un ajout automatique, il faudrait un parsing plus sophistiqué
                # Nous le signalons seulement
                echo "  ⚠️ À corriger manuellement" | tee -a "$LOG_FILE"
                echo "" | tee -a "$LOG_FILE"
            fi
        done
    fi
done < "$SWIFT_FILES_LIST"

echo "Closures à corriger: $CLOSURES_COUNT" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ÉTAPE 3: Vérification des fetchBatchSize
echo -e "${BLUE}3. Vérification des NSFetchRequest sans fetchBatchSize...${RESET}" | tee -a "$LOG_FILE"
FETCH_COUNT=0
FIXED_FETCH=0

while IFS= read -r file; do
    # Rechercher les NSFetchRequest
    if grep -q "NSFetchRequest<" "$file"; then
        fetch_lines=$(grep -n "NSFetchRequest<" "$file" | cut -d':' -f1)
        
        for line_num in $fetch_lines; do
            # Extraire les 5 lignes après la déclaration de NSFetchRequest
            fetch_context=$(tail -n +$line_num "$file" | head -n 5)
            
            # Vérifier si fetchBatchSize est défini
            if ! echo "$fetch_context" | grep -q "fetchBatchSize"; then
                FETCH_COUNT=$((FETCH_COUNT + 1))
                
                echo "Fichier: $file, Ligne: $line_num" | tee -a "$LOG_FILE"
                echo "$(echo "$fetch_context" | sed 's/^/  /')" | tee -a "$LOG_FILE"
                echo "  ⚠️ NSFetchRequest sans fetchBatchSize" | tee -a "$LOG_FILE"
                echo "" | tee -a "$LOG_FILE"
                
                # Insertion semi-automatique de fetchBatchSize
                if grep -q "let fetchRequest" "$file"; then
                    line_after=$((line_num + 1))
                    sed -i '' "${line_after}a\\
        fetchRequest.fetchBatchSize = 20" "$file"
                    FIXED_FETCH=$((FIXED_FETCH + 1))
                    echo "  ✅ Corrigé" | tee -a "$LOG_FILE"
                fi
            fi
        done
    fi
done < "$SWIFT_FILES_LIST"

echo "NSFetchRequest sans fetchBatchSize: $FETCH_COUNT, Corrigés: $FIXED_FETCH" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ÉTAPE 4: Vérification des save() sans try/catch
echo -e "${BLUE}4. Vérification des context.save() sans try/catch...${RESET}" | tee -a "$LOG_FILE"
SAVE_COUNT=0
FIXED_SAVE=0

while IFS= read -r file; do
    # Rechercher les context.save()
    if grep -q "\.save()" "$file"; then
        save_lines=$(grep -n "\.save()" "$file" | cut -d':' -f1)
        
        for line_num in $save_lines; do
            # Vérifier si save() est précédé de try
            line_content=$(sed -n "${line_num}p" "$file")
            
            if ! echo "$line_content" | grep -q "try"; then
                SAVE_COUNT=$((SAVE_COUNT + 1))
                
                echo "Fichier: $file, Ligne: $line_num" | tee -a "$LOG_FILE"
                echo "  $line_content" | tee -a "$LOG_FILE"
                echo "  ⚠️ save() sans try" | tee -a "$LOG_FILE"
                
                # Nous ne corrigeons pas automatiquement car cela nécessite d'envelopper dans un do/catch
                echo "  ⚠️ À corriger manuellement" | tee -a "$LOG_FILE"
                echo "" | tee -a "$LOG_FILE"
            fi
        done
    fi
done < "$SWIFT_FILES_LIST"

echo "save() sans try: $SAVE_COUNT" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ÉTAPE 5: Analyser UnifiedStudyService pour problèmes de concurrence
echo -e "${BLUE}5. Vérification des problèmes dans UnifiedStudyService...${RESET}" | tee -a "$LOG_FILE"

STUDY_SERVICE_FILES=$(grep -l "UnifiedStudyService" $(cat "$SWIFT_FILES_LIST"))

if [ -n "$STUDY_SERVICE_FILES" ]; then
    echo "Fichiers UnifiedStudyService trouvés:" | tee -a "$LOG_FILE"
    echo "$STUDY_SERVICE_FILES" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    for file in $STUDY_SERVICE_FILES; do
        echo "Analyse de $file:" | tee -a "$LOG_FILE"
        
        # Vérifier si viewContext est utilisé sans @MainActor
        if grep -q "viewContext" "$file" && ! grep -q "@MainActor" "$file"; then
            echo "  ⚠️ viewContext utilisé sans @MainActor" | tee -a "$LOG_FILE"
            echo "    Lignes:" | tee -a "$LOG_FILE"
            grep -n "viewContext" "$file" | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
        fi
        
        # Vérifier si perform/performAndWait est utilisé pour les opérations CoreData
        if grep -q "viewContext" "$file" && ! grep -q "perform\|performAndWait" "$file"; then
            echo "  ⚠️ Opérations CoreData sans perform/performAndWait" | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
        fi
    done
fi

# Rapport final
echo -e "${GREEN}=== RÉSUMÉ DU DÉBOGAGE RAPIDE ===${RESET}" | tee -a "$LOG_FILE"
echo "Délégués corrigés: $FIXED_DELEGATES / $DELEGATES_COUNT" | tee -a "$LOG_FILE"
echo "Closures à vérifier: $CLOSURES_COUNT" | tee -a "$LOG_FILE"
echo "NSFetchRequest corrigés: $FIXED_FETCH / $FETCH_COUNT" | tee -a "$LOG_FILE"
echo "Appels save() à corriger: $SAVE_COUNT" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Le rapport complet est disponible dans: $LOG_FILE" | tee -a "$LOG_FILE"
echo -e "${GREEN}====================================${RESET}"
