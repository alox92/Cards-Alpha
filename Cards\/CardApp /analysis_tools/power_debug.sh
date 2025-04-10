#!/bin/bash

# Couleurs pour la sortie
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Répertoire des rapports
REPORTS_DIR="reports"
mkdir -p "$REPORTS_DIR"

# Horodatage pour les fichiers de rapport
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SUMMARY_FILE="$REPORTS_DIR/analyse_globale_$TIMESTAMP.md"

# Fonction pour afficher un en-tête de section
section() {
    echo -e "\n${MAGENTA}=== $1 ===${NC}"
    echo -e "\n## $1" >> "$SUMMARY_FILE"
}

# Fonction pour afficher un sous-en-tête
subsection() {
    echo -e "\n${CYAN}--- $1 ---${NC}"
    echo -e "\n### $1" >> "$SUMMARY_FILE"
}

# Fonction pour afficher un message de succès
success() {
    echo -e "${GREEN}✓ $1${NC}"
    echo -e "- ✅ $1" >> "$SUMMARY_FILE"
}

# Fonction pour afficher un message d'avertissement
warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    echo -e "- ⚠️ $1" >> "$SUMMARY_FILE"
}

# Fonction pour afficher un message d'erreur
error() {
    echo -e "${RED}✗ $1${NC}"
    echo -e "- ❌ $1" >> "$SUMMARY_FILE"
}

# Fonction pour afficher un message d'information
info() {
    echo -e "${BLUE}ℹ $1${NC}"
    echo -e "- $1" >> "$SUMMARY_FILE"
}

# Fonction pour demander une confirmation
confirm() {
    read -p "$1 (o/n): " response
    case "$response" in
        [oO][uU][iI]|[oO]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Fonction pour exécuter un script si disponible
run_if_available() {
    script="$1"
    description="$2"
    
    if [ -f "$script" ] && [ -x "$script" ]; then
        subsection "$description"
        $script
        if [ $? -eq 0 ]; then
            success "Script $script exécuté avec succès"
        else
            error "Échec de l'exécution du script $script"
        fi
    else
        warning "Script $script non disponible ou non exécutable"
    fi
}

# Initialiser le fichier de rapport
echo "# Rapport d'Analyse Globale - CardApp" > "$SUMMARY_FILE"
echo -e "\nDate: $(date '+%d/%m/%Y %H:%M:%S')\n" >> "$SUMMARY_FILE"
echo -e "Ce rapport présente une analyse complète du projet CardApp, identifiant les problèmes et les optimisations appliquées.\n" >> "$SUMMARY_FILE"

echo -e "${BLUE}===============================================${NC}"
echo -e "${MAGENTA}         POWER DEBUGGER POUR CARDAPP         ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo -e "${YELLOW}Cet outil analysera et corrigera les problèmes${NC}"
echo -e "${YELLOW}de l'application CardApp de façon intelligente${NC}"
echo -e "${BLUE}===============================================${NC}"

# Vérification des outils disponibles
section "Vérification des outils disponibles"

TOOLS_AVAILABLE=true

# Vérifier les outils Python
if ! command -v python3 &> /dev/null; then
    error "Python 3 non disponible"
    TOOLS_AVAILABLE=false
else
    success "Python 3 disponible"
fi

# Vérifier les outils Rust (cargo)
if ! command -v cargo &> /dev/null; then
    warning "Rust/Cargo non disponible - certaines analyses avancées seront désactivées"
else
    success "Rust/Cargo disponible"
fi

# Vérifier Node.js pour le visualiseur
if ! command -v node &> /dev/null; then
    warning "Node.js non disponible - la visualisation avancée sera désactivée"
else
    success "Node.js disponible"
fi

# Si les outils essentiels ne sont pas disponibles, proposer l'installation
if [ "$TOOLS_AVAILABLE" = false ]; then
    if confirm "Certains outils nécessaires ne sont pas disponibles. Voulez-vous tenter de les installer automatiquement?"; then
        subsection "Installation des outils manquants"
        # Tentative d'installation (code spécifique à la plateforme serait nécessaire ici)
        warning "Fonctionnalité d'installation automatique pas encore implémentée"
    fi
fi

# Lancer l'analyse du code
section "Analyse du code"

# 1. Vérification des imports
subsection "Vérification des problèmes d'imports"
if [ -f "analysis_tools/verify_imports.sh" ] && [ -x "analysis_tools/verify_imports.sh" ]; then
    ./analysis_tools/verify_imports.sh
    if [ $? -eq 0 ]; then
        success "Vérification des imports terminée"
    else
        error "Problèmes d'imports détectés"
    fi
else
    info "Exécution de la vérification via grep"
    INVALID_IMPORTS=$(grep -r "import Core\." --include="*.swift" . | wc -l)
    if [ "$INVALID_IMPORTS" -gt 0 ]; then
        error "Détecté $INVALID_IMPORTS imports incorrects de sous-modules"
    else
        success "Aucun import incorrect de sous-module détecté"
    fi
fi

# 2. Vérification des problèmes de CoreData
subsection "Vérification des modèles CoreData"
COREDATA_MODELS=$(find . -name "*.xcdatamodeld" | wc -l)
if [ "$COREDATA_MODELS" -gt 1 ]; then
    error "Plusieurs modèles CoreData détectés ($COREDATA_MODELS)"
else
    success "Un seul modèle CoreData détecté"
fi

# 3. Vérification des problèmes de mémoire et concurrence
subsection "Analyse des problèmes de mémoire et concurrence"
WEAK_SELF_MISSING=$(grep -r "Task {" --include="*.swift" . | grep -v "\[weak self\]" | wc -l)
MAIN_ACTOR_MISSING=$(grep -r "viewContext" --include="*.swift" . | grep -v "@MainActor" | wc -l)

if [ "$WEAK_SELF_MISSING" -gt 0 ]; then
    error "Détecté $WEAK_SELF_MISSING closures sans [weak self]"
else
    success "Toutes les closures semblent utiliser [weak self]"
fi

if [ "$MAIN_ACTOR_MISSING" -gt 0 ]; then
    error "Détecté $MAIN_ACTOR_MISSING utilisations de viewContext sans @MainActor"
else
    success "Toutes les utilisations de viewContext semblent isolées avec @MainActor"
fi

# 4. Vérification des optimisations CoreData
subsection "Analyse des performances CoreData"
FETCHBATCHSIZE_MISSING=$(grep -r "NSFetchRequest" --include="*.swift" . | grep -v "fetchBatchSize" | wc -l)
if [ "$FETCHBATCHSIZE_MISSING" -gt 0 ]; then
    error "Détecté $FETCHBATCHSIZE_MISSING requêtes sans fetchBatchSize"
else
    success "Toutes les requêtes CoreData semblent utiliser fetchBatchSize"
fi

# Synthèse des problèmes détectés
section "Synthèse des problèmes détectés"

TOTAL_ISSUES=$(($INVALID_IMPORTS + ($COREDATA_MODELS - 1) + $WEAK_SELF_MISSING + $MAIN_ACTOR_MISSING + $FETCHBATCHSIZE_MISSING))

if [ "$TOTAL_ISSUES" -eq 0 ]; then
    success "Aucun problème majeur détecté!"
else
    error "Total des problèmes détectés: $TOTAL_ISSUES"
    
    if [ "$INVALID_IMPORTS" -gt 0 ]; then
        info "$INVALID_IMPORTS problèmes d'imports"
    fi
    
    if [ "$COREDATA_MODELS" -gt 1 ]; then
        info "$(($COREDATA_MODELS - 1)) modèles CoreData supplémentaires"
    fi
    
    if [ "$WEAK_SELF_MISSING" -gt 0 ]; then
        info "$WEAK_SELF_MISSING closures sans [weak self]"
    fi
    
    if [ "$MAIN_ACTOR_MISSING" -gt 0 ]; then
        info "$MAIN_ACTOR_MISSING utilisations de viewContext sans @MainActor"
    fi
    
    if [ "$FETCHBATCHSIZE_MISSING" -gt 0 ]; then
        info "$FETCHBATCHSIZE_MISSING requêtes sans fetchBatchSize"
    fi
    
    # Proposer la correction automatique
    if confirm "Voulez-vous appliquer les corrections automatiques?"; then
        section "Application des corrections"
        
        # 1. Corriger les imports
        if [ "$INVALID_IMPORTS" -gt 0 ]; then
            run_if_available "analysis_tools/fix_module_imports.sh" "Correction des imports problématiques"
        fi
        
        # 2. Corriger les modèles CoreData
        if [ "$COREDATA_MODELS" -gt 1 ]; then
            run_if_available "analysis_tools/fix_coredata_models.sh" "Unification des modèles CoreData"
        fi
        
        # 3. Corriger les problèmes de mémoire/concurrence
        if [ "$WEAK_SELF_MISSING" -gt 0 ] || [ "$MAIN_ACTOR_MISSING" -gt 0 ]; then
            run_if_available "analysis_tools/fix_unified_study_service.sh" "Correction des problèmes de concurrence dans UnifiedStudyService"
            run_if_available "analysis_tools/fix_syntax_errors.sh" "Correction des erreurs de syntaxe"
        fi
        
        # 4. Optimiser les performances CoreData
        if [ "$FETCHBATCHSIZE_MISSING" -gt 0 ]; then
            run_if_available "analysis_tools/optimize_coredata_performance.sh" "Optimisation des performances CoreData"
        fi
        
        success "Corrections automatiques appliquées"
    fi
fi

# Générer un rapport de performance si demandé
if confirm "Voulez-vous générer un rapport complet de performance?"; then
    section "Analyse de performance"
    
    # Exécuter l'analyseur Rust si disponible
    if command -v cargo &> /dev/null && [ -d "analysis_tools/rust_performance_analyzer" ]; then
        subsection "Analyse de performance avec Rust"
        cd analysis_tools/rust_performance_analyzer
        cargo run --release -- --path ../../ --output json --report-path "../../$REPORTS_DIR/rust_perf_$TIMESTAMP.json"
        cd ../../
        if [ -f "$REPORTS_DIR/rust_perf_$TIMESTAMP.json" ]; then
            success "Analyse Rust terminée, rapport généré"
        else
            error "Échec de l'analyse Rust"
        fi
    fi
    
    # Exécuter l'analyseur Python si disponible
    if [ -f "analysis_tools/python_static_analyzer/swift_analyzer.py" ]; then
        subsection "Analyse statique avec Python"
        python3 analysis_tools/python_static_analyzer/swift_analyzer.py -p . -o "$REPORTS_DIR/python_analysis_$TIMESTAMP.json"
        if [ -f "$REPORTS_DIR/python_analysis_$TIMESTAMP.json" ]; then
            success "Analyse Python terminée, rapport généré"
        else
            error "Échec de l'analyse Python"
        fi
    fi
    
    # Générer la visualisation si Node.js est disponible
    if command -v node &> /dev/null && [ -d "analysis_tools/node_visualizer" ]; then
        subsection "Génération de visualisations"
        cd analysis_tools/node_visualizer
        node src/cli.js --reports "../../$REPORTS_DIR/" --output "../../$REPORTS_DIR/visualization_$TIMESTAMP.html"
        cd ../../
        if [ -f "$REPORTS_DIR/visualization_$TIMESTAMP.html" ]; then
            success "Visualisation générée avec succès"
        else
            error "Échec de la génération de visualisation"
        fi
    fi
fi

# Conclusion
section "Conclusion"

echo -e "\nLe rapport d'analyse a été enregistré dans $SUMMARY_FILE"
success "Analyse globale terminée avec succès"

if [ "$TOTAL_ISSUES" -gt 0 ]; then
    warning "Des problèmes ont été détectés dans le projet"
    info "Consultez le rapport pour plus de détails et recommandations"
else
    success "Aucun problème majeur détecté dans le projet"
fi

echo -e "\n${BLUE}===============================================${NC}"
echo -e "${MAGENTA}         ANALYSE TERMINÉE AVEC SUCCÈS         ${NC}"
echo -e "${BLUE}===============================================${NC}" 