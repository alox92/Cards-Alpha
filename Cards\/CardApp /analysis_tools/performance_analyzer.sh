#!/bin/bash

# Analyseur de Performance pour CardApp
# Ce script combine les outils d'analyse en Python, Rust, Swift et Node.js
# pour détecter et corriger les problèmes de performance.

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
REPORT_DIR="reports/performance_${TIMESTAMP}"
LOG_FILE="${REPORT_DIR}/performance_analysis.log"
SUMMARY_FILE="${REPORT_DIR}/summary.md"
HTML_REPORT="${REPORT_DIR}/rapport_performance.html"

# Création des répertoires
mkdir -p "${REPORT_DIR}"
touch "${LOG_FILE}"

# Fonction pour afficher et logger les messages
log() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${NC}" | tee -a "${LOG_FILE}"
}

# Fonction pour vérifier si un outil est disponible
check_tool() {
    local tool="$1"
    command -v "$tool" > /dev/null 2>&1 || { log "❌ $tool n'est pas installé" "$RED"; return 1; }
    return 0
}

# Fonction pour exécuter l'analyse Python
run_python_analysis() {
    log "\n${BOLD}🔍 Exécution de l'analyseur statique Python...${NC}" "$BLUE"
    
    if check_tool "python3"; then
        log "Analyse des problèmes de mémoire et concurrence..." "$CYAN"
        python3 analysis_tools/python_static_analyzer/swift_analyzer.py . \
            --output "${REPORT_DIR}/python_analysis.json" \
            --include-memory --include-concurrency --include-coredata
        
        if [ $? -eq 0 ]; then
            log "✅ Analyse Python terminée avec succès" "$GREEN"
            PYTHON_ISSUES=$(grep -c "issue" "${REPORT_DIR}/python_analysis.json" || echo "0")
            echo "## Analyse Python" >> "${SUMMARY_FILE}"
            echo "- **Problèmes détectés:** ${PYTHON_ISSUES}" >> "${SUMMARY_FILE}"
            echo "- **Rapport:** [python_analysis.json](python_analysis.json)" >> "${SUMMARY_FILE}"
            echo "" >> "${SUMMARY_FILE}"
        else
            log "❌ Échec de l'analyse Python" "$RED"
        fi
    else
        log "⚠️ L'analyse Python a été ignorée car Python n'est pas installé" "$YELLOW"
    fi
}

# Fonction pour exécuter l'analyse Rust
run_rust_analysis() {
    log "\n${BOLD}🔍 Exécution de l'analyseur de performance Rust...${NC}" "$BLUE"
    
    if [ -d "analysis_tools/rust_performance_analyzer" ]; then
        log "Analyse multi-thread des problèmes de performance..." "$CYAN"
        
        if check_tool "cargo"; then
            (cd analysis_tools/rust_performance_analyzer && \
             cargo run --release -- \
                --path "../.." \
                --output "${REPORT_DIR}/rust_analysis.json" \
                --complexity-threshold 10 \
                --nesting-threshold 3)
            
            if [ $? -eq 0 ]; then
                log "✅ Analyse Rust terminée avec succès" "$GREEN"
                echo "## Analyse Rust" >> "${SUMMARY_FILE}"
                echo "- **Rapport:** [rust_analysis.json](rust_analysis.json)" >> "${SUMMARY_FILE}"
                echo "" >> "${SUMMARY_FILE}"
            else
                log "❌ Échec de l'analyse Rust" "$RED"
            fi
        else
            log "⚠️ L'analyse Rust a été ignorée car Cargo n'est pas installé" "$YELLOW"
        fi
    else
        log "⚠️ Le répertoire de l'analyseur Rust n'existe pas" "$YELLOW"
    fi
}

# Fonction pour exécuter l'analyse Swift CoreData
run_swift_coredata_analysis() {
    log "\n${BOLD}🔍 Exécution du diagnostic CoreData Swift...${NC}" "$BLUE"
    
    if [ -f "analysis_tools/swift_coredata_diagnostics/CoreDataDiagnostic.swift" ]; then
        log "Analyse du modèle CoreData et optimisations..." "$CYAN"
        
        if check_tool "swift"; then
            swift analysis_tools/swift_coredata_diagnostics/CoreDataDiagnostic.swift \
                --output "${REPORT_DIR}/coredata_diagnostics.json" \
                --model-path "Core/Models/Data/Core.xcdatamodeld" \
                --check-fetch-performance
            
            if [ $? -eq 0 ]; then
                log "✅ Diagnostic CoreData terminé avec succès" "$GREEN"
                echo "## Diagnostic CoreData" >> "${SUMMARY_FILE}"
                echo "- **Rapport:** [coredata_diagnostics.json](coredata_diagnostics.json)" >> "${SUMMARY_FILE}"
                echo "" >> "${SUMMARY_FILE}"
            else
                log "❌ Échec du diagnostic CoreData" "$RED"
            fi
        else
            log "⚠️ Le diagnostic CoreData a été ignoré car Swift n'est pas installé" "$YELLOW"
        fi
    else
        log "⚠️ Le fichier de diagnostic CoreData n'existe pas" "$YELLOW"
    fi
}

# Fonction pour exécuter l'analyse des fuites mémoire
run_memory_leak_analysis() {
    log "\n${BOLD}🔍 Analyse des fuites mémoire...${NC}" "$BLUE"
    
    log "Recherche des cycles de référence potentiels..." "$CYAN"
    
    # Analyse des cycles de référence avec grep
    grep -n "\{.*self\." --include="*.swift" -r . \
        | grep -v "\[weak self\]" \
        | grep -v "\[unowned self\]" \
        > "${REPORT_DIR}/memory_leaks.txt"
    
    if [ -s "${REPORT_DIR}/memory_leaks.txt" ]; then
        LEAKS_COUNT=$(wc -l < "${REPORT_DIR}/memory_leaks.txt")
        log "⚠️ Détecté ${LEAKS_COUNT} fuites mémoire potentielles" "$YELLOW"
    else
        log "✅ Aucune fuite mémoire potentielle détectée" "$GREEN"
        LEAKS_COUNT=0
    fi
    
    echo "## Analyse des Fuites Mémoire" >> "${SUMMARY_FILE}"
    echo "- **Cycles de référence potentiels:** ${LEAKS_COUNT}" >> "${SUMMARY_FILE}"
    echo "- **Rapport:** [memory_leaks.txt](memory_leaks.txt)" >> "${SUMMARY_FILE}"
    echo "" >> "${SUMMARY_FILE}"
}

# Fonction pour exécuter l'analyse CoreData
run_coredata_performance_analysis() {
    log "\n${BOLD}🔍 Analyse de performance CoreData...${NC}" "$BLUE"
    
    log "Recherche des requêtes non optimisées..." "$CYAN"
    
    # Analyse des fetchRequest sans fetchBatchSize
    grep -n "NSFetchRequest" --include="*.swift" -r . \
        | grep -v "fetchBatchSize" \
        > "${REPORT_DIR}/fetch_without_batchsize.txt"
    
    # Analyse des requêtes sur le thread principal sans @MainActor
    grep -n "viewContext" --include="*.swift" -r . \
        | grep -v "@MainActor" \
        > "${REPORT_DIR}/main_thread_fetches.txt"
    
    BATCH_ISSUES=$(wc -l < "${REPORT_DIR}/fetch_without_batchsize.txt")
    THREAD_ISSUES=$(wc -l < "${REPORT_DIR}/main_thread_fetches.txt")
    
    log "⚠️ Détecté ${BATCH_ISSUES} requêtes sans fetchBatchSize" "$YELLOW"
    log "⚠️ Détecté ${THREAD_ISSUES} opérations viewContext sans @MainActor" "$YELLOW"
    
    echo "## Analyse Performance CoreData" >> "${SUMMARY_FILE}"
    echo "- **Requêtes sans fetchBatchSize:** ${BATCH_ISSUES}" >> "${SUMMARY_FILE}"
    echo "- **Opérations viewContext sans @MainActor:** ${THREAD_ISSUES}" >> "${SUMMARY_FILE}"
    echo "" >> "${SUMMARY_FILE}"
}

# Fonction pour générer un rapport HTML
generate_html_report() {
    log "\n${BOLD}📊 Génération du rapport HTML...${NC}" "$BLUE"
    
    if check_tool "node"; then
        if [ -d "analysis_tools/node_visualizer" ]; then
            log "Création du rapport visuel..." "$CYAN"
            
            (cd analysis_tools/node_visualizer && \
             npm run start -- \
                --reports "${REPORT_DIR}/*.json" \
                --output "${HTML_REPORT}" \
                --format html)
            
            if [ $? -eq 0 ]; then
                log "✅ Rapport HTML généré avec succès: ${HTML_REPORT}" "$GREEN"
            else
                log "❌ Échec de la génération du rapport HTML" "$RED"
            fi
        else
            log "⚠️ Le visualiseur Node.js n'existe pas" "$YELLOW"
        fi
    else
        log "⚠️ Le rapport HTML a été ignoré car Node.js n'est pas installé" "$YELLOW"
    fi
}

# Fonction pour générer le rapport de synthèse
generate_summary() {
    log "\n${BOLD}📝 Génération du rapport de synthèse...${NC}" "$BLUE"
    
    cat > "${SUMMARY_FILE}" << EOF
# Rapport d'Analyse de Performance - CardApp

Date: $(date "+%d/%m/%Y %H:%M:%S")

## Résumé

Cette analyse a identifié plusieurs problèmes de performance dans l'application CardApp.
Les sections ci-dessous détaillent les résultats de chaque type d'analyse.

EOF
    
    # Les rapports spécifiques sont ajoutés par chaque fonction d'analyse
    
    # Ajouter les recommandations globales
    cat >> "${SUMMARY_FILE}" << EOF
## Recommandations Globales

1. **Fuites mémoire** : Ajouter systématiquement \`[weak self]\` dans les closures
2. **Performance CoreData** : Utiliser \`fetchBatchSize\` et \`fetchLimit\` pour toutes les requêtes
3. **Concurrence** : Ajouter \`@MainActor\` aux méthodes utilisant \`viewContext\`
4. **Optimisation des modèles** : Créer des index pour les attributs fréquemment recherchés
5. **Contextes** : Utiliser des contextes d'arrière-plan pour les opérations lourdes

## Actions Recommandées

Exécutez les scripts de correction automatique pour résoudre ces problèmes :

\`\`\`bash
./analysis_tools/fix_memory_leaks.sh    # Corrige les cycles de référence
./analysis_tools/fix_coredata_perf.sh   # Optimise les requêtes CoreData
\`\`\`

Pour une correction complète de tous les problèmes identifiés :

\`\`\`bash
./analysis_tools/fix_all_performance.sh
\`\`\`
EOF
    
    log "✅ Rapport de synthèse généré: ${SUMMARY_FILE}" "$GREEN"
    
    # Afficher un résumé à l'écran
    echo
    echo -e "${BOLD}${CYAN}=== RÉSUMÉ DE L'ANALYSE DE PERFORMANCE ===${NC}"
    echo
    cat "${SUMMARY_FILE}" | grep -v "^#" | grep -v "^-"
    echo
    log "📝 Rapports complets disponibles dans: ${REPORT_DIR}" "$BLUE"
}

# Fonction pour exécuter toutes les analyses
run_all_analyses() {
    log "${BOLD}${CYAN}=== DÉMARRAGE DE L'ANALYSE DE PERFORMANCE GLOBALE ===${NC}" "$BLUE"
    log "Date: $(date "+%d/%m/%Y %H:%M:%S")" "$CYAN"
    log "Projet: $(pwd)" "$CYAN"
    log "Rapports: ${REPORT_DIR}" "$CYAN"
    echo
    
    # Initialiser le rapport de synthèse
    mkdir -p "${REPORT_DIR}"
    
    # Exécuter les analyses
    run_memory_leak_analysis
    run_coredata_performance_analysis
    run_python_analysis
    run_rust_analysis
    run_swift_coredata_analysis
    
    # Générer les rapports
    generate_summary
    generate_html_report
    
    log "${BOLD}${GREEN}=== ANALYSE DE PERFORMANCE TERMINÉE ===${NC}" "$GREEN"
    log "📊 Consultez les rapports dans: ${REPORT_DIR}" "$CYAN"
}

# Script principal
run_all_analyses

exit 0 