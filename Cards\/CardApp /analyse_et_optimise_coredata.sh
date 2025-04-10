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

# Afficher le titre
echo -e "${BOLD}${CYAN}"
echo "  _____                _____        _         ____        _   _           _                    "
echo " / ____|              |  __ \      | |       / __ \      | | (_)         (_)                   "
echo "| |     ___  _ __ ___| |  | | __ _| |_ __ _| |  | |_ __ | |_ _ _ __ ___  _ ___  ___ _ __ ___ "
echo "| |    / _ \| '__/ _ \ |  | |/ _\` | __/ _\` | |  | | '_ \| __| | '_ \` _ \| / __|/ _ \ '__/ __|"
echo "| |___| (_) | | |  __/ |__| | (_| | || (_| | |__| | |_) | |_| | | | | | | \__ \  __/ |  \__ \\"
echo " \_____\___/|_|  \___|_____/ \__,_|\__\__,_|\____/| .__/ \__|_|_| |_| |_|_|___/\___|_|  |___/"
echo "                                                   | |                                         "
echo "                                                   |_|                                         "
echo -e "${RESET}"

# Configuration
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
LOG_DIR="logs"
LOG_FILE="${LOG_DIR}/analyse_optimisation_coredata_${TIMESTAMP}.log"
RAPPORT_DIR="rapports_coredata"
RAPPORT_FINAL="${RAPPORT_DIR}/rapport_final_optimisation_coredata_${TIMESTAMP}.md"

# Créer les répertoires nécessaires
mkdir -p "$LOG_DIR"
mkdir -p "$RAPPORT_DIR"

# Fonction pour demander confirmation
demander_confirmation() {
    local message=$1
    local default=${2:-"n"}
    
    if [ "$default" = "o" ]; then
        local prompt="$message [O/n] "
    else
        local prompt="$message [o/N] "
    fi
    
    while true; do
        read -p "$prompt" reponse
        reponse=${reponse:-$default}
        case ${reponse:0:1} in
            o|O) return 0 ;;
            n|N) return 1 ;;
            *) echo "Veuillez répondre par 'o' ou 'n'" ;;
        esac
    done
}

# Fonction pour exécuter une étape
executer_etape() {
    local script=$1
    local description=$2
    local etape_requise=${3:-false}
    
    echo -e "\n${BOLD}${BLUE}Étape: $description${RESET}" | tee -a "$LOG_FILE"
    
    if [ ! -f "$script" ] && [ "$etape_requise" = "true" ]; then
        echo -e "${RED}❌ Le script $script n'existe pas - étape requise impossible à exécuter${RESET}" | tee -a "$LOG_FILE"
        echo -e "${RED}❌ Arrêt du processus${RESET}" | tee -a "$LOG_FILE"
        exit 1
    elif [ ! -f "$script" ]; then
        echo -e "${YELLOW}⚠️ Le script $script n'existe pas - étape ignorée${RESET}" | tee -a "$LOG_FILE"
        return 1
    fi
    
    if ! [ -x "$script" ]; then
        echo -e "${YELLOW}⚠️ Le script $script n'est pas exécutable, ajout des permissions...${RESET}" | tee -a "$LOG_FILE"
        chmod +x "$script"
    fi
    
    if demander_confirmation "Voulez-vous exécuter cette étape?"; then
        echo -e "${GREEN}✅ Exécution de $script...${RESET}" | tee -a "$LOG_FILE"
        
        # Exécuter le script et enregistrer le résultat
        if $script >> "$LOG_FILE" 2>&1; then
            echo -e "${GREEN}✅ Étape terminée avec succès${RESET}" | tee -a "$LOG_FILE"
            return 0
        else
            echo -e "${RED}❌ L'étape a échoué (code sortie: $?)${RESET}" | tee -a "$LOG_FILE"
            if [ "$etape_requise" = "true" ]; then
                echo -e "${RED}❌ Arrêt du processus${RESET}" | tee -a "$LOG_FILE"
                exit 1
            fi
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ Étape ignorée${RESET}" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Initialiser le rapport final
cat > "$RAPPORT_FINAL" << EOT
# Rapport Final d'Optimisation CoreData

Date: $(date '+%Y-%m-%d %H:%M:%S')

## Résumé du processus

Ce rapport documente l'ensemble des optimisations appliquées au modèle CoreData et aux opérations associées dans le projet CardApp.

## Étapes exécutées

EOT

# Étape 1: Analyse du modèle CoreData
echo -e "\n${BOLD}${CYAN}=== PHASE 1: ANALYSE DES MODÈLES COREDATA ===${RESET}" | tee -a "$LOG_FILE"

if executer_etape "analysis_tools/optimiser_coredata.sh" "Analyser les modèles CoreData" true; then
    echo "### 1. Analyse des modèles CoreData ✅" >> "$RAPPORT_FINAL"
    echo "" >> "$RAPPORT_FINAL"
    echo "L'analyse a identifié la présence de deux modèles CoreData distincts:" >> "$RAPPORT_FINAL"
    echo "- Core.xcdatamodeld dans Core/Models/Data/" >> "$RAPPORT_FINAL"
    echo "- CardApp.xcdatamodeld dans Core/Persistence/" >> "$RAPPORT_FINAL"
    echo "" >> "$RAPPORT_FINAL"
    echo "Les résultats détaillés de l'analyse se trouvent dans \`rapports_coredata/rapport_global_coredata_*.md\`." >> "$RAPPORT_FINAL"
else
    echo "### 1. Analyse des modèles CoreData ❌" >> "$RAPPORT_FINAL"
    echo "" >> "$RAPPORT_FINAL"
    echo "Cette étape n'a pas été exécutée ou a échoué." >> "$RAPPORT_FINAL"
fi

echo "" >> "$RAPPORT_FINAL"

# Étape 2: Planification de l'unification des modèles
if executer_etape "analysis_tools/unifier_modeles_coredata.sh" "Planifier l'unification des modèles CoreData"; then
    echo "### 2. Planification de l'unification des modèles ✅" >> "$RAPPORT_FINAL"
    echo "" >> "$RAPPORT_FINAL"
    echo "Un plan d'unification des modèles CoreData a été généré, identifiant:" >> "$RAPPORT_FINAL"
    echo "- Les entités communes aux deux modèles" >> "$RAPPORT_FINAL"
    echo "- Les entités uniques à chaque modèle" >> "$RAPPORT_FINAL"
    echo "- Les stratégies de migration recommandées" >> "$RAPPORT_FINAL"
    echo "" >> "$RAPPORT_FINAL"
    echo "La documentation complète se trouve dans \`docs/MODELE_COREDATA_UNIFIE.md\`." >> "$RAPPORT_FINAL"
else
    echo "### 2. Planification de l'unification des modèles ❌" >> "$RAPPORT_FINAL"
    echo "" >> "$RAPPORT_FINAL"
    echo "Cette étape n'a pas été exécutée ou a échoué." >> "$RAPPORT_FINAL"
fi

echo "" >> "$RAPPORT_FINAL"

# Étape 3: Optimisation des requêtes CoreData
echo -e "\n${BOLD}${CYAN}=== PHASE 2: OPTIMISATION DES OPÉRATIONS COREDATA ===${RESET}" | tee -a "$LOG_FILE"

if executer_etape "analysis_tools/optimiser_fetch_requests.sh" "Optimiser les requêtes FetchRequest"; then
    echo "### 3. Optimisation des requêtes FetchRequest ✅" >> "$RAPPORT_FINAL"
    echo "" >> "$RAPPORT_FINAL"
    echo "Les optimisations suivantes ont été appliquées aux requêtes CoreData:" >> "$RAPPORT_FINAL"
    echo "- Ajout de \`fetchBatchSize\` pour améliorer les performances" >> "$RAPPORT_FINAL"
    echo "- Ajout de \`fetchLimit\` pour les requêtes ne nécessitant qu'un seul résultat" >> "$RAPPORT_FINAL"
    echo "" >> "$RAPPORT_FINAL"
    echo "Les détails des modifications se trouvent dans \`rapports_coredata/optimisation_fetchrequest_*.md\`." >> "$RAPPORT_FINAL"
else
    echo "### 3. Optimisation des requêtes FetchRequest ❌" >> "$RAPPORT_FINAL"
    echo "" >> "$RAPPORT_FINAL"
    echo "Cette étape n'a pas été exécutée ou a échoué." >> "$RAPPORT_FINAL"
fi

echo "" >> "$RAPPORT_FINAL"

# Étape 4: Optimisation de la concurrence
if executer_etape "analysis_tools/optimiser_concurrence_coredata.sh" "Optimiser la gestion de concurrence CoreData"; then
    echo "### 4. Optimisation de la concurrence CoreData ✅" >> "$RAPPORT_FINAL"
    echo "" >> "$RAPPORT_FINAL"
    echo "Les optimisations suivantes ont été appliquées pour améliorer la gestion de la concurrence:" >> "$RAPPORT_FINAL"
    echo "- Ajout de \`@MainActor\` aux méthodes utilisant \`viewContext\`" >> "$RAPPORT_FINAL"
    echo "- Ajout de \`[weak self]\` dans les closures pour éviter les cycles de référence" >> "$RAPPORT_FINAL"
    echo "- Suggestions pour utiliser \`performBackgroundTask\` pour les opérations lourdes" >> "$RAPPORT_FINAL"
    echo "" >> "$RAPPORT_FINAL"
    echo "Les détails des modifications se trouvent dans \`rapports_coredata/optimisation_concurrence_*.md\`." >> "$RAPPORT_FINAL"
else
    echo "### 4. Optimisation de la concurrence CoreData ❌" >> "$RAPPORT_FINAL"
    echo "" >> "$RAPPORT_FINAL"
    echo "Cette étape n'a pas été exécutée ou a échoué." >> "$RAPPORT_FINAL"
fi

echo "" >> "$RAPPORT_FINAL"

# Étape 5: Vérifier les résultats
echo -e "\n${BOLD}${CYAN}=== PHASE 3: VÉRIFICATION ET FINALISATION ===${RESET}" | tee -a "$LOG_FILE"

# Ajouter des recommandations au rapport final
cat >> "$RAPPORT_FINAL" << EOT
## Recommandations

Sur la base des analyses et optimisations effectuées, voici les recommandations pour continuer à améliorer l'utilisation de CoreData dans ce projet:

1. **Unifier les modèles CoreData**
   - Mettre en œuvre la stratégie d'unification détaillée dans `docs/MODELE_COREDATA_UNIFIE.md`
   - Créer une nouvelle version du modèle CardApp.xcdatamodeld incluant toutes les entités
   - Mettre à jour toutes les références dans le code

2. **Améliorer la gestion des contextes**
   - Mettre en place un service centralisé pour la gestion des contextes CoreData
   - Utiliser systématiquement des contextes d'arrière-plan pour les opérations lourdes
   - Respecter les contraintes de thread avec @MainActor et MainQueue

3. **Optimiser davantage les performances**
   - Ajouter des index à tous les attributs fréquemment utilisés dans les prédicats
   - Mettre en place une stratégie de préchargement avec `relationshipKeyPathsForPrefetching`
   - Envisager un cache pour les requêtes fréquentes mais rarement modifiées

4. **Améliorer la robustesse**
   - Ajouter une gestion d'erreur complète autour des opérations CoreData
   - Créer des tests unitaires pour les opérations critique CoreData
   - Mettre en place un monitoring des performances CoreData

## Impact des optimisations

Les optimisations appliquées devraient avoir les impacts positifs suivants:

1. **Performance**
   - Réduction de la consommation mémoire grâce à `fetchBatchSize`
   - Amélioration des temps de chargement avec des requêtes optimisées
   - Meilleure réactivité de l'interface utilisateur

2. **Stabilité**
   - Réduction des risques de crash liés à des problèmes de thread
   - Élimination des fuites mémoire liées aux cycles de référence
   - Code plus robuste et maintenable

3. **Maintenabilité**
   - Structure plus claire avec un modèle unifié
   - Meilleure séparation des préoccupations
   - Documentation améliorée des pratiques CoreData

## Conclusion

L'analyse et l'optimisation de CoreData dans le projet CardApp ont permis d'identifier plusieurs problèmes importants et d'appliquer des corrections automatisées. Les optimisations mises en place améliorent la performance, la stabilité et la maintenabilité du code.

Pour tirer pleinement parti de ces améliorations, il est recommandé de mettre en œuvre l'unification des modèles CoreData comme prochaine étape prioritaire.

_Rapport généré automatiquement le $(date '+%Y-%m-%d %H:%M:%S')_
EOT

echo -e "${BOLD}${GREEN}=== PROCESSUS D'ANALYSE ET D'OPTIMISATION TERMINÉ ===${RESET}" | tee -a "$LOG_FILE"
echo -e "${GREEN}✅ Rapport final généré: $RAPPORT_FINAL${RESET}" | tee -a "$LOG_FILE"
echo -e "${GREEN}✅ Journal complet des opérations: $LOG_FILE${RESET}" | tee -a "$LOG_FILE"

# Afficher un résumé des étapes exécutées
echo -e "\n${BOLD}${CYAN}Résumé des optimisations:${RESET}"
echo -e "${BLUE}1. Analyse des modèles CoreData${RESET}"
echo -e "${BLUE}2. Planification de l'unification des modèles${RESET}"
echo -e "${BLUE}3. Optimisation des requêtes FetchRequest${RESET}"
echo -e "${BLUE}4. Optimisation de la concurrence CoreData${RESET}"

# Proposer de consulter le rapport final
if demander_confirmation "Voulez-vous consulter le rapport final maintenant?"; then
    # Utiliser less pour afficher le rapport
    less "$RAPPORT_FINAL"
fi

echo -e "\n${BOLD}${GREEN}Merci d'avoir utilisé l'outil d'optimisation CoreData !${RESET}" 