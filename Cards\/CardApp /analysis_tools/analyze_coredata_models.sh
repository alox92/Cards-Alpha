#!/bin/bash

# Couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPORT_DIR="coredata_analysis_reports"
REPORT_FILE="$REPORT_DIR/coredata_analysis_$(date +%Y%m%d_%H%M%S).md"
COREAPP_MODEL="Core/Models/Data/Core.xcdatamodeld/Core.xcdatamodel/contents"
CARDAPP_MODEL="Core/Persistence/CardApp.xcdatamodeld/CardApp.xcdatamodel/contents"
PERSISTENCE_CONTROLLER="Core/Persistence/PersistenceController.swift"
COREDATA_MANAGER="Core/Managers/CoreDataManager.swift"

# Création du répertoire pour les rapports
mkdir -p "$REPORT_DIR"
echo -e "${GREEN}Répertoire de rapports créé: $REPORT_DIR${NC}"

# Fonction pour vérifier l'existence d'un fichier
check_file_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ Fichier trouvé: $file${NC}"
        return 0
    else
        echo -e "${RED}✗ Fichier non trouvé: $file${NC}"
        return 1
    fi
}

# Fonction pour extraire les entités d'un modèle CoreData
extract_entities() {
    local model_file="$1"
    if [ ! -f "$model_file" ]; then
        echo ""
        return 1
    fi
    
    grep -o '<entity name="[^"]*"' "$model_file" | sed 's/<entity name="\(.*\)"/\1/'
}

# Fonction pour extraire les attributs d'une entité spécifique
extract_attributes() {
    local model_file="$1"
    local entity="$2"
    
    if [ ! -f "$model_file" ]; then
        echo ""
        return 1
    fi
    
    # Extraire la section de l'entité et ses attributs
    local entity_section=$(sed -n "/<entity name=\"$entity\"/,/<\/entity>/p" "$model_file")
    echo "$entity_section" | grep -o '<attribute name="[^"]*"' | sed 's/<attribute name="\(.*\)"/\1/'
}

# Fonction pour extraire les relations d'une entité spécifique
extract_relationships() {
    local model_file="$1"
    local entity="$2"
    
    if [ ! -f "$model_file" ]; then
        echo ""
        return 1
    fi
    
    # Extraire la section de l'entité et ses relations
    local entity_section=$(sed -n "/<entity name=\"$entity\"/,/<\/entity>/p" "$model_file")
    echo "$entity_section" | grep -o '<relationship name="[^"]*"' | sed 's/<relationship name="\(.*\)"/\1/'
}

# Fonction pour comparer deux listes et trouver les éléments uniques à chacune
compare_lists() {
    local list1="$1"
    local list2="$2"
    
    # Éléments uniques à la liste 1
    local unique_to_1=$(comm -23 <(echo "$list1" | sort) <(echo "$list2" | sort))
    
    # Éléments uniques à la liste 2
    local unique_to_2=$(comm -13 <(echo "$list1" | sort) <(echo "$list2" | sort))
    
    # Éléments communs aux deux listes
    local common=$(comm -12 <(echo "$list1" | sort) <(echo "$list2" | sort))
    
    echo "Unique à liste 1:$unique_to_1"
    echo "Unique à liste 2:$unique_to_2"
    echo "Commun:$common"
}

# Fonction pour trouver les références au modèle dans le code
find_model_references() {
    local model_name="$1"
    echo -e "${BLUE}Références au modèle '$model_name' dans le code:${NC}"
    grep -r --include="*.swift" "NSPersistentContainer(name: \"$model_name\")" --exclude-dir="$REPORT_DIR" . | sed 's/^/- /'
}

# Fonction pour analyser les différences entre deux attributs
analyze_attribute_differences() {
    local model1="$1"
    local model2="$2"
    local entity="$3"
    
    echo "## Différences d'attributs pour l'entité $entity" >> "$REPORT_FILE"
    
    local attrs1=$(extract_attributes "$model1" "$entity")
    local attrs2=$(extract_attributes "$model2" "$entity")
    
    local comparison=$(compare_lists "$attrs1" "$attrs2")
    
    local unique_to_1=$(echo "$comparison" | grep "Unique à liste 1:" | sed 's/Unique à liste 1://')
    local unique_to_2=$(echo "$comparison" | grep "Unique à liste 2:" | sed 's/Unique à liste 2://')
    local common=$(echo "$comparison" | grep "Commun:" | sed 's/Commun://')
    
    echo "### Attributs uniquement dans Core.xcdatamodel:" >> "$REPORT_FILE"
    if [ -z "$unique_to_1" ]; then
        echo "- *Aucun*" >> "$REPORT_FILE"
    else
        echo "$unique_to_1" | sed '/^$/d' | sed 's/^/- /' >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    echo "### Attributs uniquement dans CardApp.xcdatamodel:" >> "$REPORT_FILE"
    if [ -z "$unique_to_2" ]; then
        echo "- *Aucun*" >> "$REPORT_FILE"
    else
        echo "$unique_to_2" | sed '/^$/d' | sed 's/^/- /' >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    echo "### Attributs communs aux deux modèles:" >> "$REPORT_FILE"
    if [ -z "$common" ]; then
        echo "- *Aucun*" >> "$REPORT_FILE"
    else
        echo "$common" | sed '/^$/d' | sed 's/^/- /' >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Fonction pour analyser les différences entre deux relations
analyze_relationship_differences() {
    local model1="$1"
    local model2="$2"
    local entity="$3"
    
    echo "## Différences de relations pour l'entité $entity" >> "$REPORT_FILE"
    
    local rels1=$(extract_relationships "$model1" "$entity")
    local rels2=$(extract_relationships "$model2" "$entity")
    
    local comparison=$(compare_lists "$rels1" "$rels2")
    
    local unique_to_1=$(echo "$comparison" | grep "Unique à liste 1:" | sed 's/Unique à liste 1://')
    local unique_to_2=$(echo "$comparison" | grep "Unique à liste 2:" | sed 's/Unique à liste 2://')
    local common=$(echo "$comparison" | grep "Commun:" | sed 's/Commun://')
    
    echo "### Relations uniquement dans Core.xcdatamodel:" >> "$REPORT_FILE"
    if [ -z "$unique_to_1" ]; then
        echo "- *Aucun*" >> "$REPORT_FILE"
    else
        echo "$unique_to_1" | sed '/^$/d' | sed 's/^/- /' >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    echo "### Relations uniquement dans CardApp.xcdatamodel:" >> "$REPORT_FILE"
    if [ -z "$unique_to_2" ]; then
        echo "- *Aucun*" >> "$REPORT_FILE"
    else
        echo "$unique_to_2" | sed '/^$/d' | sed 's/^/- /' >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    echo "### Relations communes aux deux modèles:" >> "$REPORT_FILE"
    if [ -z "$common" ]; then
        echo "- *Aucun*" >> "$REPORT_FILE"
    else
        echo "$common" | sed '/^$/d' | sed 's/^/- /' >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Fonction pour analyser les migrations potentielles nécessaires
analyze_migration_needs() {
    local model1="$1"
    local model2="$2"
    
    echo "# Analyse des besoins de migration" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Compter les différences totales
    local entities1=$(extract_entities "$model1")
    local entities2=$(extract_entities "$model2")
    
    local entities_comparison=$(compare_lists "$entities1" "$entities2")
    local unique_entities_1=$(echo "$entities_comparison" | grep "Unique à liste 1:" | sed 's/Unique à liste 1://' | sed '/^$/d' | wc -l | tr -d ' ')
    local unique_entities_2=$(echo "$entities_comparison" | grep "Unique à liste 2:" | sed 's/Unique à liste 2://' | sed '/^$/d' | wc -l | tr -d ' ')
    
    local total_attribute_diffs=0
    local total_relationship_diffs=0
    
    for entity in $(echo "$entities1" && echo "$entities2" | sort | uniq); do
        local attrs1=$(extract_attributes "$model1" "$entity")
        local attrs2=$(extract_attributes "$model2" "$entity")
        
        local attrs_comparison=$(compare_lists "$attrs1" "$attrs2")
        local unique_attrs_1=$(echo "$attrs_comparison" | grep "Unique à liste 1:" | sed 's/Unique à liste 1://' | sed '/^$/d' | wc -l | tr -d ' ')
        local unique_attrs_2=$(echo "$attrs_comparison" | grep "Unique à liste 2:" | sed 's/Unique à liste 2://' | sed '/^$/d' | wc -l | tr -d ' ')
        
        total_attribute_diffs=$((total_attribute_diffs + unique_attrs_1 + unique_attrs_2))
        
        local rels1=$(extract_relationships "$model1" "$entity")
        local rels2=$(extract_relationships "$model2" "$entity")
        
        local rels_comparison=$(compare_lists "$rels1" "$rels2")
        local unique_rels_1=$(echo "$rels_comparison" | grep "Unique à liste 1:" | sed 's/Unique à liste 1://' | sed '/^$/d' | wc -l | tr -d ' ')
        local unique_rels_2=$(echo "$rels_comparison" | grep "Unique à liste 2:" | sed 's/Unique à liste 2://' | sed '/^$/d' | wc -l | tr -d ' ')
        
        total_relationship_diffs=$((total_relationship_diffs + unique_rels_1 + unique_rels_2))
    done
    
    local total_diffs=$((unique_entities_1 + unique_entities_2 + total_attribute_diffs + total_relationship_diffs))
    
    echo "## Résumé des différences" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "- **Entités différentes:** $((unique_entities_1 + unique_entities_2))" >> "$REPORT_FILE"
    echo "- **Attributs différents:** $total_attribute_diffs" >> "$REPORT_FILE"
    echo "- **Relations différentes:** $total_relationship_diffs" >> "$REPORT_FILE"
    echo "- **Total des différences:** $total_diffs" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## Évaluation de la complexité de migration" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    if [ "$total_diffs" -eq 0 ]; then
        echo "**Aucune migration nécessaire** - Les modèles sont identiques." >> "$REPORT_FILE"
    elif [ "$total_diffs" -lt 5 ]; then
        echo "**Migration simple** - Peu de différences, la migration automatique devrait fonctionner." >> "$REPORT_FILE"
    elif [ "$total_diffs" -lt 15 ]; then
        echo "**Migration modérée** - Des différences notables existent, mais la migration automatique pourrait fonctionner avec quelques ajustements manuels." >> "$REPORT_FILE"
    else
        echo "**Migration complexe** - De nombreuses différences, une migration manuelle ou par étapes pourrait être nécessaire." >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Fonction pour analyser les fichiers utilisant CoreData et leur modèle
analyze_coredata_usage() {
    echo "# Analyse de l'utilisation de CoreData" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## Fichiers utilisant CoreData" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    local coredata_files=$(grep -r --include="*.swift" "import CoreData" --exclude-dir="$REPORT_DIR" . | awk -F ':' '{print $1}' | sort | uniq)
    
    echo "$coredata_files" | while read -r file; do
        local model_ref=$(grep -o 'NSPersistentContainer(name: "[^"]*")' "$file" | sed 's/NSPersistentContainer(name: "\(.*\)")/\1/' | head -1)
        
        if [ -n "$model_ref" ]; then
            echo "- **$file** - Utilise le modèle **$model_ref**" >> "$REPORT_FILE"
        else
            local has_entities=$(grep -l "NSManagedObject\|NSFetchRequest" "$file")
            if [ -n "$has_entities" ]; then
                echo "- **$file** - Utilise CoreData (sans référence directe à un modèle)" >> "$REPORT_FILE"
            else
                echo "- **$file** - Importe CoreData mais ne semble pas l'utiliser directement" >> "$REPORT_FILE"
            fi
        fi
    done
    
    echo "" >> "$REPORT_FILE"
}

# Fonction pour vérifier la cohérence de nommage entre les entités CoreData et les fichiers Swift
analyze_entity_class_mapping() {
    local model1="$1"
    local model2="$2"
    
    echo "# Analyse de la cohérence entre entités CoreData et classes Swift" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Extraire toutes les entités (combinées des deux modèles)
    local all_entities=$(extract_entities "$model1" && extract_entities "$model2" | sort | uniq)
    
    echo "## Mappage entités CoreData vers classes Swift" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    for entity in $all_entities; do
        local matching_files=$(find . -type f -name "${entity}.swift" -o -name "${entity}+*.swift" 2>/dev/null)
        
        echo "### Entité: $entity" >> "$REPORT_FILE"
        
        if [ -n "$matching_files" ]; then
            echo "#### Classes/Extensions associées:" >> "$REPORT_FILE"
            echo "$matching_files" | sed 's/^\.\//- /' >> "$REPORT_FILE"
            
            # Vérifier si l'entité a une classe personnalisée définie dans le modèle
            local has_class_name=0
            for model in "$model1" "$model2"; do
                if grep -q "<entity name=\"$entity\".*customClass" "$model"; then
                    has_class_name=1
                    local class_name=$(grep -o "<entity name=\"$entity\".*customClass=\"[^\"]*\"" "$model" | sed "s/.*customClass=\"\([^\"]*\)\".*/\1/")
                    echo "#### Classe personnalisée définie dans le modèle: \`$class_name\`" >> "$REPORT_FILE"
                fi
            done
            
            if [ "$has_class_name" -eq 0 ]; then
                echo "#### Aucune classe personnalisée définie dans le modèle" >> "$REPORT_FILE"
                echo "**⚠️ Attention:** Cette entité n'a pas de classe personnalisée définie dans le modèle CoreData." >> "$REPORT_FILE"
            fi
        else
            echo "**❌ Erreur: Aucun fichier Swift correspondant trouvé pour cette entité**" >> "$REPORT_FILE"
        fi
        
        echo "" >> "$REPORT_FILE"
    done
}

# Fonction pour recommander un plan d'action basé sur l'analyse
generate_recommendations() {
    echo "# Recommandations" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Vérifier quel modèle est utilisé dans PersistenceController
    local persistence_model=""
    if [ -f "$PERSISTENCE_CONTROLLER" ]; then
        persistence_model=$(grep -o 'NSPersistentContainer(name: "[^"]*")' "$PERSISTENCE_CONTROLLER" | sed 's/NSPersistentContainer(name: "\(.*\)")/\1/' | head -1)
    fi
    
    echo "## Plan d'unification des modèles CoreData" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    if [ -n "$persistence_model" ]; then
        echo "Le contrôleur de persistance utilise actuellement le modèle **$persistence_model**." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        echo "### Actions recommandées:" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "1. **Utiliser le modèle \`$persistence_model\` comme modèle unifié**" >> "$REPORT_FILE"
        echo "   - Ce modèle est déjà utilisé par le contrôleur de persistance principal." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "2. **Fusionner les entités manquantes de l'autre modèle**" >> "$REPORT_FILE"
        echo "   - Ajouter manuellement les entités, attributs et relations manquants dans le modèle unifié." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "3. **Mettre à jour toutes les références aux modèles CoreData**" >> "$REPORT_FILE"
        echo "   - Utiliser le script \`fix_coredata_models.sh\` pour automatiser cette tâche." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "4. **Vérifier la migration des données existantes**" >> "$REPORT_FILE"
        echo "   - Créer un mapping de migration si nécessaire pour préserver les données." >> "$REPORT_FILE"
    else
        echo "**❌ Erreur: Impossible de déterminer le modèle utilisé par le contrôleur de persistance**" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "### Actions recommandées:" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "1. **Choisir un modèle principal**" >> "$REPORT_FILE"
        echo "   - CardApp.xcdatamodeld est recommandé car il semble plus complet." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "2. **Mettre à jour le PersistenceController**" >> "$REPORT_FILE"
        echo "   - Modifier le nom du modèle utilisé dans NSPersistentContainer." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "3. **Mettre à jour toutes les références aux modèles CoreData**" >> "$REPORT_FILE"
        echo "   - Utiliser le script \`fix_coredata_models.sh\` pour automatiser cette tâche." >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Fonction principale pour analyser les modèles CoreData
main() {
    echo -e "${BLUE}=== Analyse des modèles CoreData ===${NC}"
    
    # Vérification de l'existence des fichiers nécessaires
    check_file_exists "$COREAPP_MODEL"
    check_file_exists "$CARDAPP_MODEL"
    check_file_exists "$PERSISTENCE_CONTROLLER"
    check_file_exists "$COREDATA_MANAGER"
    
    # Créer l'en-tête du rapport
    echo "# Rapport d'analyse des modèles CoreData" > "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Analyser les entités dans les deux modèles
    echo -e "${BLUE}Analyse des entités dans les deux modèles...${NC}"
    echo "# Comparaison des modèles CoreData" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    local entities1=$(extract_entities "$COREAPP_MODEL")
    local entities2=$(extract_entities "$CARDAPP_MODEL")
    
    echo "## Entités dans Core.xcdatamodel" >> "$REPORT_FILE"
    echo "$entities1" | sed 's/^/- /' >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## Entités dans CardApp.xcdatamodel" >> "$REPORT_FILE"
    echo "$entities2" | sed 's/^/- /' >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Analyser les différences d'entités
    echo -e "${BLUE}Analyse des différences d'entités...${NC}"
    echo "## Comparaison des entités" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    local entities_comparison=$(compare_lists "$entities1" "$entities2")
    
    local unique_to_core=$(echo "$entities_comparison" | grep "Unique à liste 1:" | sed 's/Unique à liste 1://')
    local unique_to_cardapp=$(echo "$entities_comparison" | grep "Unique à liste 2:" | sed 's/Unique à liste 2://')
    local common_entities=$(echo "$entities_comparison" | grep "Commun:" | sed 's/Commun://')
    
    echo "### Entités uniquement dans Core.xcdatamodel:" >> "$REPORT_FILE"
    if [ -z "$unique_to_core" ]; then
        echo "- *Aucun*" >> "$REPORT_FILE"
    else
        echo "$unique_to_core" | sed '/^$/d' | sed 's/^/- /' >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    echo "### Entités uniquement dans CardApp.xcdatamodel:" >> "$REPORT_FILE"
    if [ -z "$unique_to_cardapp" ]; then
        echo "- *Aucun*" >> "$REPORT_FILE"
    else
        echo "$unique_to_cardapp" | sed '/^$/d' | sed 's/^/- /' >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    echo "### Entités communes aux deux modèles:" >> "$REPORT_FILE"
    if [ -z "$common_entities" ]; then
        echo "- *Aucun*" >> "$REPORT_FILE"
    else
        echo "$common_entities" | sed '/^$/d' | sed 's/^/- /' >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    
    # Analyser les différences d'attributs et de relations pour chaque entité commune
    echo -e "${BLUE}Analyse des différences d'attributs et de relations...${NC}"
    echo "# Analyse détaillée des entités communes" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    if [ -n "$common_entities" ]; then
        for entity in $common_entities; do
            echo "# Analyse de l'entité $entity" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            
            analyze_attribute_differences "$COREAPP_MODEL" "$CARDAPP_MODEL" "$entity"
            analyze_relationship_differences "$COREAPP_MODEL" "$CARDAPP_MODEL" "$entity"
        done
    else
        echo "Aucune entité commune entre les deux modèles." >> "$REPORT_FILE"
    fi
    
    # Analyser les références aux modèles dans le code
    echo -e "${BLUE}Analyse des références aux modèles dans le code...${NC}"
    echo "# Utilisation des modèles CoreData" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## Références au modèle 'Core'" >> "$REPORT_FILE"
    local core_refs=$(find_model_references "Core")
    echo "$core_refs" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## Références au modèle 'CardApp'" >> "$REPORT_FILE"
    local cardapp_refs=$(find_model_references "CardApp")
    echo "$cardapp_refs" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Analyser les besoins de migration
    echo -e "${BLUE}Analyse des besoins de migration...${NC}"
    analyze_migration_needs "$COREAPP_MODEL" "$CARDAPP_MODEL"
    
    # Analyser l'utilisation de CoreData
    echo -e "${BLUE}Analyse de l'utilisation de CoreData...${NC}"
    analyze_coredata_usage
    
    # Analyser le mappage entités/classes
    echo -e "${BLUE}Analyse du mappage entités/classes...${NC}"
    analyze_entity_class_mapping "$COREAPP_MODEL" "$CARDAPP_MODEL"
    
    # Générer des recommandations
    echo -e "${BLUE}Génération des recommandations...${NC}"
    generate_recommendations
    
    echo -e "${GREEN}=== Analyse des modèles CoreData terminée ===${NC}"
    echo -e "${GREEN}Rapport généré: $REPORT_FILE${NC}"
}

# Exécution de la fonction principale
main 