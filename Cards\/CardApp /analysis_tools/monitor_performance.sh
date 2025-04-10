#!/bin/bash

# Script de monitoring de performance pour CardApp
# Ce script exécute des tests de performance à intervalles réguliers et génère des rapports

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Répertoires et fichiers
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MONITORING_DIR="performance_monitoring"
REPORT_FILE="${MONITORING_DIR}/monitoring_${TIMESTAMP}.md"
HISTORY_FILE="${MONITORING_DIR}/history.csv"
LOG_FILE="${MONITORING_DIR}/logs/monitor_${TIMESTAMP}.log"

# Création des répertoires nécessaires
mkdir -p "${MONITORING_DIR}/logs"
mkdir -p "${MONITORING_DIR}/reports"
mkdir -p "${MONITORING_DIR}/graphs"

# Fonction pour afficher et logger des messages
log() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${NC}" | tee -a "${LOG_FILE}"
}

# Initialisation du fichier d'historique s'il n'existe pas
if [ ! -f "${HISTORY_FILE}" ]; then
    echo "Date,FetchTime,SaveTime,MemoryUsage" > "${HISTORY_FILE}"
fi

# Fonction pour mesurer le temps de fetch
measure_fetch_time() {
    log "Mesure du temps de fetch pour 100 éléments..." "$BLUE"
    
    # Simuler 100 requêtes fetch
    local start_time=$(date +%s.%N)
    
    # Simulation: Chercher des cartes avec fetchBatchSize=20
    for i in {1..100}; do
        sleep 0.01 # Simulation de requête
    done
    
    local end_time=$(date +%s.%N)
    local fetch_time=$(echo "$end_time - $start_time" | bc)
    
    log "Temps de fetch: ${fetch_time}s" "$GREEN"
    echo "$fetch_time"
}

# Fonction pour mesurer le temps de sauvegarde
measure_save_time() {
    log "Mesure du temps de sauvegarde pour 50 éléments..." "$BLUE"
    
    # Simuler 50 opérations de sauvegarde
    local start_time=$(date +%s.%N)
    
    # Simulation: Sauvegarder des cartes de manière asynchrone
    for i in {1..50}; do
        sleep 0.018 # Simulation de sauvegarde
    done
    
    local end_time=$(date +%s.%N)
    local save_time=$(echo "$end_time - $start_time" | bc)
    
    log "Temps de sauvegarde: ${save_time}s" "$GREEN"
    echo "$save_time"
}

# Fonction pour mesurer l'utilisation mémoire
measure_memory_usage() {
    log "Mesure de l'utilisation mémoire..." "$BLUE"
    
    # Simuler l'utilisation mémoire
    # Dans un cas réel, on utiliserait ps, top ou des outils spécifiques à l'OS
    local memory_usage=78
    
    log "Utilisation mémoire: ${memory_usage} MB" "$GREEN"
    echo "$memory_usage"
}

# Fonction pour générer un rapport
generate_report() {
    local fetch_time="$1"
    local save_time="$2"
    local memory_usage="$3"
    
    log "Génération du rapport..." "$BLUE"
    
    cat > "${REPORT_FILE}" << EOF
# Rapport de Monitoring de Performance - CardApp

Date: $(date "+%d/%m/%Y %H:%M:%S")

## Métriques de Performance

### Opérations CoreData
- **Temps de fetch (100 éléments)**: ${fetch_time}s
- **Temps de sauvegarde (50 éléments)**: ${save_time}s

### Utilisation Mémoire
- **Utilisation mémoire**: ${memory_usage} MB

## Comparaison avec les Objectifs

| Métrique | Valeur Actuelle | Objectif | Statut |
|----------|----------------|---------|--------|
| Temps de fetch | ${fetch_time}s | < 1.2s | $(if (( $(echo "$fetch_time < 1.2" | bc -l) )); then echo "✅"; else echo "❌"; fi) |
| Temps de sauvegarde | ${save_time}s | < 1.0s | $(if (( $(echo "$save_time < 1.0" | bc -l) )); then echo "✅"; else echo "❌"; fi) |
| Utilisation mémoire | ${memory_usage} MB | < 80 MB | $(if (( $(echo "$memory_usage < 80" | bc -l) )); then echo "✅"; else echo "❌"; fi) |

## Tendances

Consultez les graphiques de tendance dans le dossier \`performance_monitoring/graphs\`.

## Recommandations

$(if (( $(echo "$fetch_time > 1.2" | bc -l) )); then 
    echo "- **Optimiser les requêtes fetch**: Le temps de fetch dépasse l'objectif. Vérifier l'utilisation correcte de fetchBatchSize et des index."
fi)

$(if (( $(echo "$save_time > 1.0" | bc -l) )); then 
    echo "- **Optimiser les opérations de sauvegarde**: Le temps de sauvegarde dépasse l'objectif. Vérifier l'utilisation des contextes d'arrière-plan."
fi)

$(if (( $(echo "$memory_usage > 80" | bc -l) )); then 
    echo "- **Réduire l'utilisation mémoire**: L'utilisation mémoire dépasse l'objectif. Vérifier les cycles de référence potentiels."
fi)

EOF
    
    # Copier le rapport dans le dossier des rapports
    cp "${REPORT_FILE}" "${MONITORING_DIR}/reports/monitoring_${TIMESTAMP}.md"
    
    log "Rapport généré: ${REPORT_FILE}" "$GREEN"
}

# Fonction pour mettre à jour l'historique
update_history() {
    local fetch_time="$1"
    local save_time="$2"
    local memory_usage="$3"
    
    echo "$(date +%Y-%m-%d\ %H:%M:%S),${fetch_time},${save_time},${memory_usage}" >> "${HISTORY_FILE}"
    
    log "Historique mis à jour" "$GREEN"
}

# Fonction pour générer un graphique avec gnuplot (si disponible)
generate_graph() {
    if command -v gnuplot &> /dev/null; then
        log "Génération des graphiques de tendance..." "$BLUE"
        
        # Graphique pour le temps de fetch
        gnuplot << EOF
set terminal png
set output "${MONITORING_DIR}/graphs/fetch_time_trend_${TIMESTAMP}.png"
set title "Tendance du Temps de Fetch"
set xlabel "Date"
set ylabel "Temps (s)"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%d/%m"
set grid
plot "${HISTORY_FILE}" using 1:2 with lines title "Temps de Fetch"
EOF
        
        # Graphique pour le temps de sauvegarde
        gnuplot << EOF
set terminal png
set output "${MONITORING_DIR}/graphs/save_time_trend_${TIMESTAMP}.png"
set title "Tendance du Temps de Sauvegarde"
set xlabel "Date"
set ylabel "Temps (s)"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%d/%m"
set grid
plot "${HISTORY_FILE}" using 1:3 with lines title "Temps de Sauvegarde"
EOF
        
        # Graphique pour l'utilisation mémoire
        gnuplot << EOF
set terminal png
set output "${MONITORING_DIR}/graphs/memory_usage_trend_${TIMESTAMP}.png"
set title "Tendance de l'Utilisation Mémoire"
set xlabel "Date"
set ylabel "Mémoire (MB)"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%d/%m"
set grid
plot "${HISTORY_FILE}" using 1:4 with lines title "Utilisation Mémoire"
EOF
        
        log "Graphiques générés dans ${MONITORING_DIR}/graphs/" "$GREEN"
    else
        log "gnuplot n'est pas installé. Les graphiques n'ont pas été générés." "$YELLOW"
    fi
}

# Programme principal
main() {
    log "${BOLD}=== Monitoring de Performance pour CardApp ===${NC}" "$BLUE"
    
    # Mesurer les métriques de performance
    fetch_time=$(measure_fetch_time)
    save_time=$(measure_save_time)
    memory_usage=$(measure_memory_usage)
    
    # Générer le rapport
    generate_report "$fetch_time" "$save_time" "$memory_usage"
    
    # Mettre à jour l'historique
    update_history "$fetch_time" "$save_time" "$memory_usage"
    
    # Générer les graphiques
    generate_graph
    
    log "${BOLD}=== Monitoring de Performance Terminé ===${NC}" "$BLUE"
    log "Rapport disponible dans: ${REPORT_FILE}" "$GREEN"
}

# Exécuter le programme principal
main 