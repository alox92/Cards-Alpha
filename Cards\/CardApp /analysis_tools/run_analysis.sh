#!/bin/bash

# Couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration du projet
# Utilisez le chemin absolu pour éviter les problèmes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANALYSIS_DIR="$SCRIPT_DIR"
REPORTS_DIR="$ANALYSIS_DIR/reports"
FINAL_REPORT="$REPORTS_DIR/rapport_final.html"

# Vérifier l'existence du répertoire du projet
if [ ! -d "$PROJECT_ROOT" ]; then
    echo -e "${RED}Erreur : Le répertoire du projet n'existe pas : $PROJECT_ROOT${NC}"
    exit 1
fi

# Créer le répertoire des rapports s'il n'existe pas
mkdir -p "$REPORTS_DIR"

# Fonction pour mesurer le temps écoulé
start_time=$(date +%s)
function elapsed_time() {
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    echo "${elapsed}s"
}

# Fonction pour afficher des en-têtes de section
function section_header() {
    echo -e "\n${BLUE}=======================================${NC}"
    echo -e "${BLUE}= $1${NC}"
    echo -e "${BLUE}=======================================${NC}"
    echo "Démarrage : $(date)"
}

# Fonction pour exécuter une commande avec gestion d'erreur
function run_command() {
    local cmd="$1"
    local description="$2"
    local output_file="$3"
    
    echo -e "${YELLOW}Exécution : ${CYAN}$description${NC}"
    echo -e "${PURPLE}$ $cmd${NC}"
    
    if [ -n "$output_file" ]; then
        eval "$cmd" | tee "$output_file"
        exit_status=${PIPESTATUS[0]}
    else
        eval "$cmd"
        exit_status=$?
    fi
    
    if [ $exit_status -ne 0 ]; then
        echo -e "${RED}❌ Erreur lors de l'exécution de la commande (code $exit_status)${NC}"
        return $exit_status
    else
        echo -e "${GREEN}✅ Commande exécutée avec succès${NC}"
        return 0
    fi
}

# Vérifier l'existence du modèle CoreData
COREDATA_MODEL=$(find "$PROJECT_ROOT" -name "*.xcdatamodeld" -not -path "*/.build/*" | head -n 1)
if [ -z "$COREDATA_MODEL" ]; then
    echo -e "${YELLOW}⚠️ Aucun modèle CoreData trouvé dans le projet.${NC}"
else
    echo -e "${GREEN}✅ Modèle CoreData trouvé : $COREDATA_MODEL${NC}"
fi

# Vérifier l'existence des outils d'analyse
if [ ! -d "$ANALYSIS_DIR/python_static_analyzer" ]; then
    echo -e "${YELLOW}⚠️ Analyseur statique Python non trouvé. Certaines analyses seront ignorées.${NC}"
    mkdir -p "$ANALYSIS_DIR/python_static_analyzer"
fi

if [ ! -d "$ANALYSIS_DIR/swift_coredata_diagnostics" ]; then
    echo -e "${YELLOW}⚠️ Diagnostics CoreData Swift non trouvés. Certaines analyses seront ignorées.${NC}"
fi

if [ ! -d "$ANALYSIS_DIR/rust_performance_analyzer" ]; then
    echo -e "${YELLOW}⚠️ Analyseur de performance Rust non trouvé. Certaines analyses seront ignorées.${NC}"
    mkdir -p "$ANALYSIS_DIR/rust_performance_analyzer"
fi

if [ ! -d "$ANALYSIS_DIR/nodejs_visualizer" ]; then
    echo -e "${YELLOW}⚠️ Visualiseur Node.js non trouvé. Le rapport final sera simplifié.${NC}"
    mkdir -p "$ANALYSIS_DIR/nodejs_visualizer"
fi

# Nettoyer le répertoire de build
section_header "NETTOYAGE DE L'ENVIRONNEMENT"
run_command "rm -rf $PROJECT_ROOT/.build" "Nettoyage du répertoire de build"

# Analyse statique avec Python
section_header "ANALYSE STATIQUE SWIFT (PYTHON)"
if [ -d "$ANALYSIS_DIR/python_static_analyzer" ] && [ -f "$ANALYSIS_DIR/python_static_analyzer/swift_analyzer.py" ]; then
    run_command "cd \"$ANALYSIS_DIR/python_static_analyzer\" && python3 swift_analyzer.py --source \"$PROJECT_ROOT\" --output \"$REPORTS_DIR/static_analysis.json\"" "Exécution de l'analyseur statique Python" "$REPORTS_DIR/static_analysis_log.txt"
else
    echo -e "${YELLOW}⚠️ Analyse statique Python ignorée (outil swift_analyzer.py non trouvé)${NC}"
    # Créer un fichier de résultat vide pour qu'il puisse être référencé plus tard
    echo "{}" > "$REPORTS_DIR/static_analysis.json"
fi

# Diagnostic CoreData avec Swift
section_header "DIAGNOSTIC COREDATA (SWIFT)"
if [ -d "$ANALYSIS_DIR/swift_coredata_diagnostics" ] && [ -f "$ANALYSIS_DIR/swift_coredata_diagnostics/CoreDataOptimizer.swift" ] && [ -n "$COREDATA_MODEL" ]; then
    run_command "\"$ANALYSIS_DIR/swift_coredata_diagnostics/CoreDataOptimizer.swift\" --model \"$COREDATA_MODEL\" --output \"$REPORTS_DIR/coredata_analysis.json\" --verbose" "Exécution du diagnostic CoreData Swift" "$REPORTS_DIR/coredata_analysis_log.txt"
else
    echo -e "${YELLOW}⚠️ Diagnostic CoreData ignoré (outil CoreDataOptimizer.swift non disponible ou modèle non trouvé)${NC}"
    # Créer un fichier de résultat vide pour qu'il puisse être référencé plus tard
    echo "{}" > "$REPORTS_DIR/coredata_analysis.json"
fi

# Analyse de performance avec Rust
section_header "ANALYSE DE PERFORMANCE (RUST)"
if [ -d "$ANALYSIS_DIR/rust_performance_analyzer" ] && [ -f "$ANALYSIS_DIR/rust_performance_analyzer/Cargo.toml" ]; then
    run_command "cd \"$ANALYSIS_DIR/rust_performance_analyzer\" && cargo run --release -- --source \"$PROJECT_ROOT\" --output \"$REPORTS_DIR/performance_analysis.json\"" "Exécution de l'analyseur de performance Rust" "$REPORTS_DIR/performance_analysis_log.txt"
else
    echo -e "${YELLOW}⚠️ Analyse de performance Rust ignorée (projet Cargo non disponible)${NC}"
    # Créer un fichier de résultat vide pour qu'il puisse être référencé plus tard
    echo "{}" > "$REPORTS_DIR/performance_analysis.json"
fi

# Génération du rapport avec Node.js
section_header "GÉNÉRATION DU RAPPORT (NODE.JS)"
if [ -d "$ANALYSIS_DIR/nodejs_visualizer" ] && [ -f "$ANALYSIS_DIR/nodejs_visualizer/visualizer.js" ]; then
    run_command "cd \"$ANALYSIS_DIR/nodejs_visualizer\" && node visualizer.js --static \"$REPORTS_DIR/static_analysis.json\" --coredata \"$REPORTS_DIR/coredata_analysis.json\" --performance \"$REPORTS_DIR/performance_analysis.json\" --output \"$FINAL_REPORT\"" "Génération du rapport visuel avec Node.js" "$REPORTS_DIR/report_generation_log.txt"
else
    echo -e "${YELLOW}⚠️ Génération du rapport visuel ignorée (outil visualizer.js non disponible)${NC}"
    echo -e "${CYAN}ℹ️ Création d'un rapport HTML simplifié${NC}"
    
    # Créer un rapport HTML simplifié si le visualiseur Node.js n'est pas disponible
    cat > "$FINAL_REPORT" << EOL
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'analyse - CardApp</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; color: #333; }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        h2 { color: #2980b9; margin-top: 30px; }
        h3 { color: #3498db; }
        .container { max-width: 1200px; margin: 0 auto; }
        .summary { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .report-section { margin-bottom: 30px; }
        .info { color: #17a2b8; }
        .warning { color: #ffc107; }
        .error { color: #dc3545; }
        .success { color: #28a745; }
        pre { background-color: #f8f9fa; padding: 10px; border-radius: 5px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport d'analyse - CardApp</h1>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p>Analyse effectuée le $(date)</p>
            <p>Temps d'exécution total: $(elapsed_time)</p>
        </div>

        <div class="report-section">
            <h2>Analyses effectuées</h2>
            <ul>
EOL

    if [ -f "$REPORTS_DIR/static_analysis.json" ]; then
        echo "<li class=\"success\">Analyse statique (Python) - Complétée</li>" >> "$FINAL_REPORT"
    else
        echo "<li class=\"warning\">Analyse statique (Python) - Non exécutée</li>" >> "$FINAL_REPORT"
    fi

    if [ -f "$REPORTS_DIR/coredata_analysis.json" ]; then
        echo "<li class=\"success\">Diagnostic CoreData (Swift) - Complété</li>" >> "$FINAL_REPORT"
    else
        echo "<li class=\"warning\">Diagnostic CoreData (Swift) - Non exécuté</li>" >> "$FINAL_REPORT"
    fi

    if [ -f "$REPORTS_DIR/performance_analysis.json" ]; then
        echo "<li class=\"success\">Analyse de performance (Rust) - Complétée</li>" >> "$FINAL_REPORT"
    else
        echo "<li class=\"warning\">Analyse de performance (Rust) - Non exécutée</li>" >> "$FINAL_REPORT"
    fi

    cat >> "$FINAL_REPORT" << EOL
            </ul>
        </div>

        <div class="report-section">
            <h2>Résultats</h2>
            <p class="info">Pour des résultats détaillés, veuillez consulter les fichiers JSON dans le répertoire des rapports.</p>
            <p><strong>Répertoire des rapports:</strong> $REPORTS_DIR</p>
            
            <h3>Problèmes CoreData détectés</h3>
EOL

    # Si le fichier coredata_analysis.json existe et n'est pas vide
    if [ -f "$REPORTS_DIR/coredata_analysis.json" ] && [ -s "$REPORTS_DIR/coredata_analysis.json" ]; then
        # Inclure le contenu du rapport CoreData si disponible
        if [ -f "$REPORTS_DIR/coredata_analysis_log.txt" ]; then
            echo "<pre>" >> "$FINAL_REPORT"
            cat "$REPORTS_DIR/coredata_analysis_log.txt" >> "$FINAL_REPORT"
            echo "</pre>" >> "$FINAL_REPORT"
        else
            echo "<p class=\"warning\">Le rapport détaillé CoreData n'est pas disponible.</p>" >> "$FINAL_REPORT"
        fi
    else
        echo "<p class=\"warning\">Aucune analyse CoreData n'a été effectuée.</p>" >> "$FINAL_REPORT"
    fi

    cat >> "$FINAL_REPORT" << EOL
        </div>
    </div>
</body>
</html>
EOL

    echo -e "${GREEN}✅ Rapport HTML simplifié créé : $FINAL_REPORT${NC}"
fi

# Afficher le résumé
total_time=$(elapsed_time)
section_header "RÉSUMÉ DE L'ANALYSE"
echo -e "${GREEN}✅ Analyse terminée en $total_time${NC}"
echo -e "${CYAN}ℹ️ Rapport final disponible : $FINAL_REPORT${NC}"

if [ -f "$FINAL_REPORT" ]; then
    echo -e "${YELLOW}Pour visualiser le rapport : ouvrez $FINAL_REPORT dans un navigateur${NC}"
fi

echo -e "\n${GREEN}=== Analyse terminée avec succès ===${NC}"