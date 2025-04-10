#!/bin/bash

# Script d'orchestration pour CardApp - Analyse et correction automatique
# Créé dans le cadre du débogage de l'application CardApp
# Ce script coordonne l'exécution de tous les outils d'analyse

set -e  # Arrêt en cas d'erreur

# Couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Chemins principaux
WORKSPACE_DIR="$(pwd)"
TOOLS_DIR="${WORKSPACE_DIR}/analysis_tools"
PYTHON_ANALYZER="${TOOLS_DIR}/python_static_analyzer"
SWIFT_DIAG="${TOOLS_DIR}/swift_coredata_diagnoser"
RUST_PERF="${TOOLS_DIR}/rust_performance_analyzer"
NODE_VIZ="${TOOLS_DIR}/node_visualizer"
REPORTS_DIR="${WORKSPACE_DIR}/diagnostic_reports"

# Création des dossiers nécessaires
mkdir -p "${REPORTS_DIR}"
mkdir -p "${TOOLS_DIR}"
mkdir -p "${PYTHON_ANALYZER}"
mkdir -p "${SWIFT_DIAG}"
mkdir -p "${RUST_PERF}"
mkdir -p "${NODE_VIZ}"

# Variables de configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${REPORTS_DIR}/power_debug_${TIMESTAMP}.log"
MASTER_REPORT="${REPORTS_DIR}/master_report_${TIMESTAMP}.html"
UNIFIED_STUDY_FILE=$(find "${WORKSPACE_DIR}" -name "UnifiedStudyService.swift" -type f | head -n 1)

# Options par défaut
ANALYZE_ALL=true
ANALYZE_UNIFIED_STUDY=false
ANALYZE_COREDATA=false
ANALYZE_MEMORY=false
ANALYZE_FAST=false
APPLY_FIXES=false

# Fonction d'aide
show_help() {
    echo -e "${BOLD}Outil de diagnostic et optimisation CardApp${NC}"
    echo
    echo "Utilisation: $0 [options]"
    echo
    echo "Options:"
    echo "  --help                Affiche ce message d'aide"
    echo "  --all                 Exécute toutes les analyses (par défaut)"
    echo "  --unified-study       Analyse uniquement UnifiedStudyService"
    echo "  --core-data           Analyse uniquement les problèmes CoreData"
    echo "  --memory              Analyse uniquement les problèmes de mémoire"
    echo "  --fast                Exécute une analyse rapide"
    echo "  --apply-fixes         Applique automatiquement les corrections"
    echo
    exit 0
}

# Traitement des options
for arg in "$@"; do
    case $arg in
        --help)
            show_help
            ;;
        --all)
            ANALYZE_ALL=true
            ;;
        --unified-study)
            ANALYZE_ALL=false
            ANALYZE_UNIFIED_STUDY=true
            ;;
        --core-data)
            ANALYZE_ALL=false
            ANALYZE_COREDATA=true
            ;;
        --memory)
            ANALYZE_ALL=false
            ANALYZE_MEMORY=true
            ;;
        --fast)
            ANALYZE_FAST=true
            ;;
        --apply-fixes)
            APPLY_FIXES=true
            ;;
        *)
            echo -e "${RED}Option non reconnue: $arg${NC}"
            show_help
            ;;
    esac
done

# Fonction pour vérifier les prérequis
check_dependencies() {
    echo -e "${BLUE}Vérification des dépendances...${NC}"
    
    # Vérifier Python
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Python 3 n'est pas installé. Veuillez l'installer.${NC}"
        exit 1
    fi
    
    # Vérifier Rust/Cargo si besoin
    if [ "$ANALYZE_ALL" = true ] || [ "$ANALYZE_FAST" = false ]; then
        if ! command -v cargo &> /dev/null; then
            echo -e "${YELLOW}Cargo n'est pas installé. Installation de l'outil Rust désactivée.${NC}"
        fi
    fi
    
    # Vérifier Node.js si besoin
    if [ "$ANALYZE_ALL" = true ] || [ "$ANALYZE_FAST" = false ]; then
        if ! command -v node &> /dev/null; then
            echo -e "${YELLOW}Node.js n'est pas installé. Visualisation interactive désactivée.${NC}"
        fi
    fi
    
    # Vérifier Swift si besoin
    if [ "$ANALYZE_ALL" = true ] || [ "$ANALYZE_COREDATA" = true ]; then
        if ! command -v swift &> /dev/null; then
            echo -e "${YELLOW}Swift n'est pas installé. Diagnostic CoreData avancé désactivé.${NC}"
        fi
    fi
    
    echo -e "${GREEN}Vérification des dépendances terminée.${NC}"
}

# Fonction pour installer l'analyseur Python
setup_python_analyzer() {
    echo -e "${BLUE}Configuration de l'analyseur Python...${NC}"
    
    # Copier swift_analyzer.py vers le dossier d'outils Python
    cp "${TOOLS_DIR}/swift_analyzer.py" "${PYTHON_ANALYZER}/swift_analyzer.py"
    chmod +x "${PYTHON_ANALYZER}/swift_analyzer.py"
    
    # Créer un requirements.txt minimal
    cat > "${PYTHON_ANALYZER}/requirements.txt" << EOF
dataclasses
typing
PyYAML
EOF
    
    # Installer les dépendances
    python3 -m pip install -r "${PYTHON_ANALYZER}/requirements.txt" >> "${LOG_FILE}" 2>&1 || true
    
    echo -e "${GREEN}Analyseur Python configuré.${NC}"
}

# Fonction pour configurer l'analyseur Rust si disponible
setup_rust_analyzer() {
    if command -v cargo &> /dev/null; then
        echo -e "${BLUE}Configuration de l'analyseur Rust...${NC}"
        
        # Copier les fichiers Rust vers le dossier d'outils Rust si disponibles
        if [ -d "${TOOLS_DIR}/rust_performance_analyzer" ]; then
            cd "${RUST_PERF}"
            cargo build --release >> "${LOG_FILE}" 2>&1 || true
        fi
        
        echo -e "${GREEN}Analyseur Rust configuré.${NC}"
    fi
}

# Fonction pour configurer l'outil de visualisation Node.js
setup_node_visualizer() {
    if command -v node &> /dev/null; then
        echo -e "${BLUE}Configuration de l'outil de visualisation...${NC}"
        
        # Configurer l'outil de visualisation
        if [ -f "${TOOLS_DIR}/js_visualization_tool/package.json" ]; then
            cd "${NODE_VIZ}"
            npm install >> "${LOG_FILE}" 2>&1 || true
        fi
        
        echo -e "${GREEN}Outil de visualisation configuré.${NC}"
    fi
}

# Fonction pour exécuter l'analyse Python
run_python_analyzer() {
    echo -e "${BLUE}Exécution de l'analyse statique Python...${NC}"
    
    # Exécuter l'analyseur Python
    cd "${WORKSPACE_DIR}"
    python3 "${PYTHON_ANALYZER}/swift_analyzer.py" --path "${WORKSPACE_DIR}" > "${REPORTS_DIR}/python_analysis_${TIMESTAMP}.txt"
    
    echo -e "${GREEN}Analyse Python terminée.${NC}"
}

# Fonction pour exécuter l'analyse Rust si disponible
run_rust_analyzer() {
    if command -v cargo &> /dev/null && [ -d "${RUST_PERF}" ]; then
        echo -e "${BLUE}Exécution de l'analyse de performance Rust...${NC}"
        
        # Exécuter l'analyseur Rust
        cd "${WORKSPACE_DIR}"
        "${RUST_PERF}/target/release/swift_performance_analyzer" "${WORKSPACE_DIR}" \
            --output json --report-path "${REPORTS_DIR}/rust_analysis_${TIMESTAMP}.json" >> "${LOG_FILE}" 2>&1 || true
        
        echo -e "${GREEN}Analyse Rust terminée.${NC}"
    fi
}

# Fonction pour exécuter le diagnostic CoreData
run_coredata_diagnostic() {
    echo -e "${BLUE}Exécution du diagnostic CoreData...${NC}"
    
    # Si l'outil spécifique existe, l'utiliser
    if [ -f "${SWIFT_DIAG}/run_core_data_optimizer.swift" ]; then
        cd "${WORKSPACE_DIR}"
        swift "${SWIFT_DIAG}/run_core_data_optimizer.swift" > "${REPORTS_DIR}/coredata_diagnostic_${TIMESTAMP}.txt"
    else
        # Sinon, utiliser l'outil intégré à l'application si disponible
        if [ -f "${WORKSPACE_DIR}/Core/Tools/CoreDataOptimizer.swift" ]; then
            echo "// Script de diagnostic CoreData" > "${SWIFT_DIAG}/coredata_diagnostic.swift"
            echo "import Foundation" >> "${SWIFT_DIAG}/coredata_diagnostic.swift"
            echo "import CoreData" >> "${SWIFT_DIAG}/coredata_diagnostic.swift"
            
            # Ajouter du code pour initialiser et exécuter le CoreDataOptimizer
            cat >> "${SWIFT_DIAG}/coredata_diagnostic.swift" << EOF
// Script d'analyse CoreData
print("Démarrage du diagnostic CoreData...")

// Obtenir le PersistenceController
guard let persistenceController = try? PersistenceController.shared else {
    print("Erreur: Impossible d'accéder au PersistenceController")
    exit(1)
}

// Créer un optimiseur
let optimizer = persistenceController.createOptimizer()

// Analyser le schéma
let schemaIssues = optimizer.analyzeSchema()
print("\\nProblèmes de schéma détectés:")
if schemaIssues.isEmpty {
    print("Aucun problème de schéma détecté.")
} else {
    for (index, issue) in schemaIssues.enumerated() {
        print("\\(index + 1). \\(issue)")
    }
}

// Exécuter l'optimisation et générer un rapport
optimizer.optimize { stats in
    print("\\nRésultats de l'optimisation:")
    print("* Index ajoutés: \\(stats.indexesAdded)")
    print("* Relations réparées: \\(stats.relationshipsFixed)")
    print("* Données orphelines supprimées: \\(stats.orphanedDataRemoved)")
    print("* Requêtes optimisées: \\(stats.queriesOptimized)")
    print("\\nTotal des optimisations: \\(stats.totalOptimizations)")
}

print("\\nDiagnostic CoreData terminé.")
EOF
            
            # Exécuter le script
            cd "${WORKSPACE_DIR}"
            swift "${SWIFT_DIAG}/coredata_diagnostic.swift" > "${REPORTS_DIR}/coredata_diagnostic_${TIMESTAMP}.txt" 2>&1 || true
        else
            echo -e "${YELLOW}Outil CoreDataOptimizer non trouvé. Diagnostic CoreData ignoré.${NC}"
        fi
    fi
    
    echo -e "${GREEN}Diagnostic CoreData terminé.${NC}"
}

# Fonction pour analyser spécifiquement UnifiedStudyService
analyze_unified_study() {
    if [ -n "${UNIFIED_STUDY_FILE}" ]; then
        echo -e "${BLUE}Analyse spécifique de UnifiedStudyService...${NC}"
        
        # Utiliser un script spécifique pour analyser UnifiedStudyService
        cat > "${TOOLS_DIR}/analyze_unified_study.sh" << EOF
#!/bin/bash
# Script d'analyse spécifique pour UnifiedStudyService

FILE="\$1"
OUTPUT="\$2"

echo "Analyse de UnifiedStudyService" > "\$OUTPUT"
echo "================================" >> "\$OUTPUT"
echo >> "\$OUTPUT"

# 1. Vérifier l'annotation @MainActor
if ! grep -q "@MainActor" "\$FILE"; then
    echo "PROBLÈME CRITIQUE: Classe sans annotation @MainActor" >> "\$OUTPUT"
    echo "  La classe devrait être annotée avec @MainActor pour garantir l'exécution sur le thread principal." >> "\$OUTPUT"
    echo "  Solution: Ajouter @MainActor avant la déclaration de classe." >> "\$OUTPUT"
    echo >> "\$OUTPUT"
fi

# 2. Vérifier les closures sans [weak self]
CLOSURES_WITHOUT_WEAK=\$(grep -n "\\(Task\\|DispatchQueue\\|sink\\|onReceive\\).*{" "\$FILE" | grep -v "\\[weak self\\]" | wc -l)
if [ \$CLOSURES_WITHOUT_WEAK -gt 0 ]; then
    echo "PROBLÈME CRITIQUE: \$CLOSURES_WITHOUT_WEAK closures sans [weak self]" >> "\$OUTPUT"
    echo "  Les closures asynchrones doivent utiliser [weak self] pour éviter les cycles de référence." >> "\$OUTPUT"
    echo "  Solution: Ajouter [weak self] et guard let self = self aux closures." >> "\$OUTPUT"
    echo >> "\$OUTPUT"
    
    # Lister quelques exemples
    echo "Exemples de closures sans [weak self]:" >> "\$OUTPUT"
    grep -n "\\(Task\\|DispatchQueue\\|sink\\|onReceive\\).*{" "\$FILE" | grep -v "\\[weak self\\]" | head -5 >> "\$OUTPUT"
    echo >> "\$OUTPUT"
fi

# 3. Vérifier les opérations CoreData sans fetchBatchSize
FETCH_WITHOUT_BATCH=\$(grep -n "fetch(" "\$FILE" | grep -v "fetchBatchSize" | wc -l)
if [ \$FETCH_WITHOUT_BATCH -gt 0 ]; then
    echo "PROBLÈME DE PERFORMANCE: \$FETCH_WITHOUT_BATCH requêtes sans fetchBatchSize" >> "\$OUTPUT"
    echo "  Les requêtes CoreData devraient utiliser fetchBatchSize pour optimiser les performances." >> "\$OUTPUT"
    echo "  Solution: Ajouter request.fetchBatchSize = 20 aux requêtes." >> "\$OUTPUT"
    echo >> "\$OUTPUT"
fi

# 4. Vérifier les opérations CoreData sur le thread principal
MAIN_THREAD_OPERATIONS=\$(grep -n "viewContext" "\$FILE" | grep -v "@MainActor" | wc -l)
if [ \$MAIN_THREAD_OPERATIONS -gt 0 ]; then
    echo "PROBLÈME DE CONCURRENCE: Opérations viewContext sans @MainActor" >> "\$OUTPUT"
    echo "  Les opérations utilisant viewContext doivent être annotées avec @MainActor." >> "\$OUTPUT"
    echo "  Solution: Ajouter @MainActor aux méthodes concernées ou utiliser un contexte d'arrière-plan." >> "\$OUTPUT"
    echo >> "\$OUTPUT"
fi

# 5. Vérifier la gestion d'erreurs
ERROR_HANDLING=\$(grep -n "try" "\$FILE" | grep -v "catch" | wc -l)
if [ \$ERROR_HANDLING -gt 0 ]; then
    echo "PROBLÈME DE ROBUSTESSE: Opérations try sans catch" >> "\$OUTPUT"
    echo "  Les opérations pouvant échouer doivent être enveloppées dans des blocs do-catch." >> "\$OUTPUT"
    echo "  Solution: Envelopper les opérations try dans des blocs do-catch." >> "\$OUTPUT"
    echo >> "\$OUTPUT"
fi

echo "Analyse terminée. Un script de correction est disponible avec ./fix_unified_study_service.sh" >> "\$OUTPUT"
EOF
        
        chmod +x "${TOOLS_DIR}/analyze_unified_study.sh"
        "${TOOLS_DIR}/analyze_unified_study.sh" "${UNIFIED_STUDY_FILE}" "${REPORTS_DIR}/unified_study_service_analysis_${TIMESTAMP}.txt"
        
        echo -e "${GREEN}Analyse de UnifiedStudyService terminée.${NC}"
    else
        echo -e "${YELLOW}Fichier UnifiedStudyService.swift non trouvé. Analyse ignorée.${NC}"
    fi
}

# Fonction pour générer le rapport visuel
generate_visual_report() {
    if command -v node &> /dev/null && [ -d "${NODE_VIZ}" ]; then
        echo -e "${BLUE}Génération du rapport visuel...${NC}"
        
        node "${NODE_VIZ}/index.js" \
            --python-report "${REPORTS_DIR}/python_analysis_${TIMESTAMP}.txt" \
            --rust-report "${REPORTS_DIR}/rust_analysis_${TIMESTAMP}.json" \
            --coredata-report "${REPORTS_DIR}/coredata_diagnostic_${TIMESTAMP}.txt" \
            --unified-study-report "${REPORTS_DIR}/unified_study_service_analysis_${TIMESTAMP}.txt" \
            --output "${MASTER_REPORT}" >> "${LOG_FILE}" 2>&1 || true
        
        echo -e "${GREEN}Rapport visuel généré: ${MASTER_REPORT}${NC}"
    else
        echo -e "${YELLOW}Node.js non disponible ou outil de visualisation non configuré. Rapport visuel ignoré.${NC}"
    fi
}

# Fonction pour générer un script de correction
generate_fix_script() {
    echo -e "${BLUE}Génération du script de correction...${NC}"
    
    # Créer le script de correction pour UnifiedStudyService
    cat > "${WORKSPACE_DIR}/fix_unified_study_service.sh" << EOF
#!/bin/bash

# Script de correction pour UnifiedStudyService
# Généré automatiquement par power_debug.sh

FILE="${UNIFIED_STUDY_FILE}"
BACKUP="${UNIFIED_STUDY_FILE}.backup"

# Faire une sauvegarde
cp "\$FILE" "\$BACKUP"
echo "Sauvegarde créée: \$BACKUP"

# 1. Ajouter @MainActor si nécessaire
if ! grep -q "@MainActor" "\$FILE"; then
    sed -i.tmp 's/public final class UnifiedStudyService/@MainActor public final class UnifiedStudyService/' "\$FILE"
    echo "Ajout de @MainActor à la classe"
fi

# 2. Ajouter [weak self] aux closures
sed -i.tmp 's/Task {\\([^[]\\)/Task { [weak self] in\\1\\n        guard let self = self else { return }/' "\$FILE"
sed -i.tmp 's/DispatchQueue[^{]*{\\([^[]\\)/DispatchQueue.main.async { [weak self] in\\1\\n        guard let self = self else { return }/' "\$FILE"
echo "Ajout de [weak self] aux closures"

# 3. Ajouter fetchBatchSize aux requêtes
sed -i.tmp '/let request = NSFetchRequest/a\\        request.fetchBatchSize = 20' "\$FILE"
echo "Ajout de fetchBatchSize aux requêtes"

# 4. Envelopper les opérations try dans des blocs do-catch
# Cela nécessite une analyse plus complexe, à faire manuellement

# Nettoyer les fichiers temporaires
rm -f "\${FILE}.tmp"

echo "Corrections appliquées. Vérifiez le fichier pour vous assurer de la validité des modifications."
echo "Pour revenir à la version originale: cp \$BACKUP \$FILE"
EOF
    
    chmod +x "${WORKSPACE_DIR}/fix_unified_study_service.sh"
    
    # Créer un script de vérification des corrections
    cat > "${WORKSPACE_DIR}/verify_corrections.sh" << EOF
#!/bin/bash

# Script de vérification des corrections
# Teste la compilation du projet après l'application des corrections

# Essayer de compiler le projet
if [ -f "Package.swift" ]; then
    echo "Compilation du package Swift..."
    swift build
elif [ -f "*.xcodeproj/project.pbxproj" ]; then
    echo "Compilation du projet Xcode..."
    xcodebuild -project *.xcodeproj -scheme "CardApp" build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
else
    echo "Aucun projet Swift reconnu trouvé."
    exit 1
fi

# Vérifier le résultat
if [ \$? -eq 0 ]; then
    echo "✅ Compilation réussie! Les corrections semblent valides."
else
    echo "❌ La compilation a échoué. Les corrections peuvent être invalides."
fi
EOF
    
    chmod +x "${WORKSPACE_DIR}/verify_corrections.sh"
    
    echo -e "${GREEN}Scripts de correction générés:${NC}"
    echo -e "  - ${WORKSPACE_DIR}/fix_unified_study_service.sh"
    echo -e "  - ${WORKSPACE_DIR}/verify_corrections.sh"
}

# Fonction pour afficher le résumé des analyses
show_summary() {
    echo
    echo -e "${BOLD}====== RÉSUMÉ DE L'ANALYSE ======${NC}"
    echo
    
    # Compter les problèmes trouvés par l'analyseur Python
    if [ -f "${REPORTS_DIR}/python_analysis_${TIMESTAMP}.txt" ]; then
        PYTHON_CRITICAL=$(grep -c "\[CRITICAL\]" "${REPORTS_DIR}/python_analysis_${TIMESTAMP}.txt")
        PYTHON_ERROR=$(grep -c "\[ERROR\]" "${REPORTS_DIR}/python_analysis_${TIMESTAMP}.txt")
        PYTHON_WARNING=$(grep -c "\[WARNING\]" "${REPORTS_DIR}/python_analysis_${TIMESTAMP}.txt")
        PYTHON_INFO=$(grep -c "\[INFO\]" "${REPORTS_DIR}/python_analysis_${TIMESTAMP}.txt")
        
        echo -e "${BOLD}Analyse Python:${NC}"
        echo -e "  - Problèmes critiques: ${RED}${PYTHON_CRITICAL}${NC}"
        echo -e "  - Erreurs: ${RED}${PYTHON_ERROR}${NC}"
        echo -e "  - Avertissements: ${YELLOW}${PYTHON_WARNING}${NC}"
        echo -e "  - Informations: ${BLUE}${PYTHON_INFO}${NC}"
    fi
    
    # Si l'analyse de UnifiedStudyService a été effectuée
    if [ -f "${REPORTS_DIR}/unified_study_service_analysis_${TIMESTAMP}.txt" ]; then
        UNIFIED_CRITICAL=$(grep -c "PROBLÈME CRITIQUE" "${REPORTS_DIR}/unified_study_service_analysis_${TIMESTAMP}.txt")
        UNIFIED_PERFORMANCE=$(grep -c "PROBLÈME DE PERFORMANCE" "${REPORTS_DIR}/unified_study_service_analysis_${TIMESTAMP}.txt")
        UNIFIED_CONCURRENCY=$(grep -c "PROBLÈME DE CONCURRENCE" "${REPORTS_DIR}/unified_study_service_analysis_${TIMESTAMP}.txt")
        
        echo -e "${BOLD}Analyse de UnifiedStudyService:${NC}"
        echo -e "  - Problèmes critiques: ${RED}${UNIFIED_CRITICAL}${NC}"
        echo -e "  - Problèmes de performance: ${YELLOW}${UNIFIED_PERFORMANCE}${NC}"
        echo -e "  - Problèmes de concurrence: ${YELLOW}${UNIFIED_CONCURRENCY}${NC}"
    fi
    
    # Si l'analyse CoreData a été effectuée
    if [ -f "${REPORTS_DIR}/coredata_diagnostic_${TIMESTAMP}.txt" ]; then
        COREDATA_OPTIMIZATIONS=$(grep -c "optimisation" "${REPORTS_DIR}/coredata_diagnostic_${TIMESTAMP}.txt")
        
        echo -e "${BOLD}Diagnostic CoreData:${NC}"
        echo -e "  - Optimisations suggérées: ${YELLOW}${COREDATA_OPTIMIZATIONS}${NC}"
    fi
    
    echo
    echo -e "${BOLD}Rapports générés:${NC}"
    echo -e "  - ${REPORTS_DIR}/python_analysis_${TIMESTAMP}.txt"
    [ -f "${REPORTS_DIR}/rust_analysis_${TIMESTAMP}.json" ] && echo -e "  - ${REPORTS_DIR}/rust_analysis_${TIMESTAMP}.json"
    [ -f "${REPORTS_DIR}/coredata_diagnostic_${TIMESTAMP}.txt" ] && echo -e "  - ${REPORTS_DIR}/coredata_diagnostic_${TIMESTAMP}.txt"
    [ -f "${REPORTS_DIR}/unified_study_service_analysis_${TIMESTAMP}.txt" ] && echo -e "  - ${REPORTS_DIR}/unified_study_service_analysis_${TIMESTAMP}.txt"
    [ -f "${MASTER_REPORT}" ] && echo -e "  - ${MASTER_REPORT}"
    
    echo
    echo -e "${BOLD}Script de correction disponible:${NC}"
    echo -e "  - ${WORKSPACE_DIR}/fix_unified_study_service.sh"
    
    echo
    if [ "$APPLY_FIXES" = true ]; then
        echo -e "${YELLOW}Pour appliquer les corrections automatiquement:${NC}"
        echo -e "  $> ./fix_unified_study_service.sh"
        echo
        echo -e "${YELLOW}Pour vérifier que les corrections n'ont pas introduit d'erreurs:${NC}"
        echo -e "  $> ./verify_corrections.sh"
    else
        echo -e "${YELLOW}Pour appliquer les corrections, exécutez à nouveau avec l'option --apply-fixes${NC}"
    fi
    
    echo
    echo -e "${GREEN}Analyse terminée. Consultez les rapports pour plus de détails.${NC}"
}

# Fonction principale
main() {
    echo -e "${BOLD}====== OUTIL DE DIAGNOSTIC ET OPTIMISATION CARDAPP ======${NC}"
    echo "Date: $(date)"
    echo "Dossier de travail: ${WORKSPACE_DIR}"
    echo "Rapports: ${REPORTS_DIR}"
    echo "Log: ${LOG_FILE}"
    echo
    
    # Vérifier les dépendances
    check_dependencies
    
    # Configurer les outils
    setup_python_analyzer
    [ "$ANALYZE_ALL" = true ] && setup_rust_analyzer
    [ "$ANALYZE_ALL" = true ] && setup_node_visualizer
    
    # Exécuter les analyses en fonction des options
    run_python_analyzer
    
    if [ "$ANALYZE_ALL" = true ] || [ "$ANALYZE_COREDATA" = true ]; then
        run_coredata_diagnostic
    fi
    
    if [ "$ANALYZE_ALL" = true ] && [ "$ANALYZE_FAST" = false ]; then
        run_rust_analyzer
    fi
    
    if [ "$ANALYZE_ALL" = true ] || [ "$ANALYZE_UNIFIED_STUDY" = true ]; then
        analyze_unified_study
    fi
    
    # Générer les rapports et scripts
    [ "$ANALYZE_ALL" = true ] && [ "$ANALYZE_FAST" = false ] && generate_visual_report
    generate_fix_script
    
    # Appliquer les corrections si demandé
    if [ "$APPLY_FIXES" = true ]; then
        echo -e "${BLUE}Application automatique des corrections...${NC}"
        bash "${WORKSPACE_DIR}/fix_unified_study_service.sh"
        echo -e "${GREEN}Corrections appliquées.${NC}"
    fi
    
    # Afficher le résumé
    show_summary
}

# Exécuter la fonction principale
main "$@"
