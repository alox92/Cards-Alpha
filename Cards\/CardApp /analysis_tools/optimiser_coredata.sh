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

# Répertoire pour les rapports
RAPPORT_DIR="rapports_coredata"
DATE_FORMAT=$(date "+%Y%m%d_%H%M%S")
RAPPORT_GLOBAL="${RAPPORT_DIR}/rapport_global_coredata_${DATE_FORMAT}.md"

echo -e "${BOLD}${CYAN}=== ANALYSEUR ET OPTIMISEUR COREDATA POUR CARDAPP ===${RESET}\n"

# Créer le répertoire pour les rapports s'il n'existe pas
if [ ! -d "$RAPPORT_DIR" ]; then
    mkdir -p "$RAPPORT_DIR"
    echo -e "${GREEN}✅ Répertoire '$RAPPORT_DIR' créé pour les rapports${RESET}"
fi

# Initialiser le rapport global
echo "# Rapport d'analyse et d'optimisation CoreData - CardApp" > "$RAPPORT_GLOBAL"
echo "" >> "$RAPPORT_GLOBAL"
echo "Date d'exécution: $(date '+%Y-%m-%d %H:%M:%S')" >> "$RAPPORT_GLOBAL"
echo "" >> "$RAPPORT_GLOBAL"
echo "## Résumé des vérifications effectuées" >> "$RAPPORT_GLOBAL"
echo "" >> "$RAPPORT_GLOBAL"

# 1. Vérifier l'existence des fichiers d'optimisation
echo -e "${BOLD}${BLUE}1. Vérification des fichiers d'optimisation${RESET}"
echo "" >> "$RAPPORT_GLOBAL"
echo "### 1. Vérification des fichiers d'optimisation" >> "$RAPPORT_GLOBAL"
echo "" >> "$RAPPORT_GLOBAL"

files_to_check=(
    "./run_core_data_optimizer.swift"
    "./Core/Tools/CoreDataOptimizer.swift"
    "./CoreDataOptimizer.swift"
)

for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ Fichier '$file' trouvé${RESET}"
        echo "- ✅ Fichier '$file' trouvé" >> "$RAPPORT_GLOBAL"
    else
        echo -e "${YELLOW}⚠️ Fichier '$file' non trouvé${RESET}"
        echo "- ⚠️ Fichier '$file' non trouvé" >> "$RAPPORT_GLOBAL"
    fi
done

echo "" >> "$RAPPORT_GLOBAL"

# 2. Vérifier les modèles CoreData
echo -e "\n${BOLD}${BLUE}2. Vérification des modèles CoreData${RESET}"
echo "### 2. Vérification des modèles CoreData" >> "$RAPPORT_GLOBAL"
echo "" >> "$RAPPORT_GLOBAL"

coredata_models=(
    "./Core/Models/Data/Core.xcdatamodeld/Core.xcdatamodel/contents"
    "./Core/Persistence/CardApp.xcdatamodeld/CardApp.xcdatamodel/contents"
)

for model in "${coredata_models[@]}"; do
    if [ -f "$model" ]; then
        echo -e "${GREEN}✅ Modèle CoreData '$model' trouvé${RESET}"
        echo "- ✅ Modèle CoreData '$model' trouvé" >> "$RAPPORT_GLOBAL"
        
        # Compter les entités dans le modèle
        entity_count=$(grep -c "<entity name=" "$model")
        echo -e "   ${BLUE}ℹ️ $entity_count entités trouvées${RESET}"
        echo "  - $entity_count entités trouvées" >> "$RAPPORT_GLOBAL"
        
        # Vérifier les indexes
        index_count=$(grep -c "<fetchIndex name=" "$model")
        if [ $index_count -eq 0 ]; then
            echo -e "   ${YELLOW}⚠️ Aucun index défini dans ce modèle${RESET}"
            echo "  - ⚠️ Aucun index défini dans ce modèle" >> "$RAPPORT_GLOBAL"
        else
            echo -e "   ${GREEN}✅ $index_count index définis${RESET}"
            echo "  - ✅ $index_count index définis" >> "$RAPPORT_GLOBAL"
        fi
    else
        echo -e "${RED}❌ Modèle CoreData '$model' non trouvé${RESET}"
        echo "- ❌ Modèle CoreData '$model' non trouvé" >> "$RAPPORT_GLOBAL"
    fi
done

echo "" >> "$RAPPORT_GLOBAL"

# 3. Vérifier les permissions d'exécution du script d'optimisation
echo -e "\n${BOLD}${BLUE}3. Vérification des permissions d'exécution${RESET}"
echo "### 3. Vérification des permissions d'exécution" >> "$RAPPORT_GLOBAL"
echo "" >> "$RAPPORT_GLOBAL"

if [ -f "./run_core_data_optimizer.swift" ]; then
    if [ -x "./run_core_data_optimizer.swift" ]; then
        echo -e "${GREEN}✅ Le script run_core_data_optimizer.swift est exécutable${RESET}"
        echo "- ✅ Le script run_core_data_optimizer.swift est exécutable" >> "$RAPPORT_GLOBAL"
    else
        echo -e "${YELLOW}⚠️ Le script run_core_data_optimizer.swift n'est pas exécutable, ajout des permissions...${RESET}"
        chmod +x ./run_core_data_optimizer.swift
        echo -e "${GREEN}✅ Permissions d'exécution ajoutées${RESET}"
        echo "- ✅ Permissions d'exécution ajoutées au script run_core_data_optimizer.swift" >> "$RAPPORT_GLOBAL"
    fi
else
    echo -e "${RED}❌ Impossible de vérifier les permissions, le script n'existe pas${RESET}"
    echo "- ❌ Impossible de vérifier les permissions, le script n'existe pas" >> "$RAPPORT_GLOBAL"
fi

echo "" >> "$RAPPORT_GLOBAL"

# 4. Rechercher des problèmes courants de CoreData dans le code
echo -e "\n${BOLD}${BLUE}4. Recherche de problèmes courants dans le code${RESET}"
echo "### 4. Recherche de problèmes courants dans le code" >> "$RAPPORT_GLOBAL"
echo "" >> "$RAPPORT_GLOBAL"

patterns=(
    "try! context.save()"
    "NSFetchRequest<NSFetchRequestResult>"
    "performBackgroundTask"
    "viewContext.perform"
    "@NSManaged var"
)

echo "#### Problèmes potentiels identifiés:" >> "$RAPPORT_GLOBAL"
echo "" >> "$RAPPORT_GLOBAL"

for pattern in "${patterns[@]}"; do
    echo -e "${BOLD}Recherche de: ${pattern}${RESET}"
    echo "##### Recherche de: \`${pattern}\`" >> "$RAPPORT_GLOBAL"
    echo "" >> "$RAPPORT_GLOBAL"
    
    results=$(grep -r --include="*.swift" "$pattern" . 2>/dev/null || echo "Aucune correspondance")
    
    if [ "$results" == "Aucune correspondance" ]; then
        echo -e "${GREEN}✅ Aucune correspondance trouvée${RESET}"
        echo "Aucune correspondance trouvée" >> "$RAPPORT_GLOBAL"
    else
        echo -e "${YELLOW}⚠️ Correspondances trouvées:${RESET}"
        echo "\`\`\`" >> "$RAPPORT_GLOBAL"
        echo "$results" | head -n 10
        echo "$results" | head -n 10 >> "$RAPPORT_GLOBAL"
        
        count=$(echo "$results" | wc -l)
        if [ $count -gt 10 ]; then
            echo -e "${YELLOW}... et $(($count - 10)) autres correspondances${RESET}"
            echo "... et $(($count - 10)) autres correspondances" >> "$RAPPORT_GLOBAL"
        fi
        echo "\`\`\`" >> "$RAPPORT_GLOBAL"
    fi
    echo "" >> "$RAPPORT_GLOBAL"
done

# 5. Exécuter l'optimiseur CoreData si disponible
echo -e "\n${BOLD}${BLUE}5. Exécution de l'optimiseur CoreData${RESET}"
echo "### 5. Exécution de l'optimiseur CoreData" >> "$RAPPORT_GLOBAL"
echo "" >> "$RAPPORT_GLOBAL"

if [ -x "./run_core_data_optimizer.swift" ]; then
    echo -e "${CYAN}Lancement de l'optimiseur CoreData...${RESET}"
    echo "Exécution de l'optimiseur CoreData..." >> "$RAPPORT_GLOBAL"
    echo "" >> "$RAPPORT_GLOBAL"
    
    # Rediriger la sortie vers le rapport
    echo "\`\`\`" >> "$RAPPORT_GLOBAL"
    ./run_core_data_optimizer.swift 2>&1 | tee -a "$RAPPORT_GLOBAL"
    echo "\`\`\`" >> "$RAPPORT_GLOBAL"
    
    echo -e "\n${GREEN}✅ Exécution de l'optimiseur terminée${RESET}"
else
    echo -e "${RED}❌ Impossible d'exécuter l'optimiseur, le script n'est pas disponible ou pas exécutable${RESET}"
    echo "❌ Impossible d'exécuter l'optimiseur, le script n'est pas disponible ou pas exécutable" >> "$RAPPORT_GLOBAL"
fi

echo "" >> "$RAPPORT_GLOBAL"

# 6. Recommandations
echo -e "\n${BOLD}${BLUE}6. Recommandations pour l'optimisation de CoreData${RESET}"
echo "### 6. Recommandations pour l'optimisation de CoreData" >> "$RAPPORT_GLOBAL"
echo "" >> "$RAPPORT_GLOBAL"

cat << EOT >> "$RAPPORT_GLOBAL"
#### Recommandations générales:

1. **Indexation des attributs fréquemment recherchés**
   - Ajouter des index pour tous les attributs utilisés dans des prédicats de recherche fréquents
   - Important pour les attributs comme \`id\`, \`createdAt\`, \`updatedAt\`

2. **Optimisation des fetch requests**
   - Toujours définir \`fetchBatchSize\` (généralement entre 20 et 100)
   - Utiliser \`relationshipKeyPathsForPrefetching\` pour les relations fréquemment accédées
   - Limiter les résultats avec \`fetchLimit\` quand approprié

3. **Gestion des contextes et concurrence**
   - Utiliser \`@MainActor\` pour les méthodes qui accèdent à \`viewContext\`
   - Exécuter les opérations lourdes avec \`performBackgroundTask\`
   - Toujours entourer \`try context.save()\` avec un bloc try/catch

4. **Normalisation du modèle de données**
   - Unifier les modèles Core.xcdatamodeld et CardApp.xcdatamodeld
   - Éviter les relations many-to-many directes, utiliser des entités intermédiaires
   - Limiter la profondeur des relations (éviter les cascades de relations)

5. **Amélioration des performances UI**
   - Utiliser \`NSFetchedResultsController\` pour les listes dans l'UI
   - Implémenter le chargement différé pour les attributs volumineux (images, texte long)
   - Mettre en cache les résultats de requêtes fréquentes mais peu modifiées
EOT

echo -e "${GREEN}✅ Recommandations ajoutées au rapport${RESET}"

# 7. Conclusion
echo -e "\n${BOLD}${BLUE}7. Conclusion${RESET}"
echo "### 7. Conclusion" >> "$RAPPORT_GLOBAL"
echo "" >> "$RAPPORT_GLOBAL"
echo "L'analyse et l'optimisation de CoreData ont été complétées. Veuillez consulter le rapport complet pour voir tous les problèmes identifiés et les recommandations." >> "$RAPPORT_GLOBAL"
echo "" >> "$RAPPORT_GLOBAL"
echo "Rapport généré automatiquement par l'outil d'analyse CoreData de CardApp." >> "$RAPPORT_GLOBAL"

echo -e "\n${BOLD}${GREEN}=== ANALYSE TERMINÉE ===${RESET}"
echo -e "${GREEN}✅ Rapport complet généré: ${RAPPORT_GLOBAL}${RESET}" 