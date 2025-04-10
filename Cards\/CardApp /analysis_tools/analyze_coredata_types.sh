#!/bin/bash

# Couleurs pour les sorties
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Timestamp pour les sauvegardes
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups_coredata_types_$TIMESTAMP"
REPORT_FILE="reports/coredata_types_analysis_$TIMESTAMP.md"

# Créer les répertoires nécessaires
mkdir -p "$BACKUP_DIR"
mkdir -p "reports"

echo -e "${BLUE}=== Analyse des types et ambiguïtés CoreData dans le projet CardApp ===${NC}"
echo -e "${CYAN}Date: $(date)${NC}\n"

# Écrire l'en-tête du rapport
cat > "$REPORT_FILE" << EOF
# Analyse des Types et Ambiguïtés CoreData
> Rapport généré le $(date)

## Résumé

Ce rapport analyse les problèmes d'ambiguïté des types dans le contexte CoreData du projet CardApp.

EOF

# Fonction pour trouver les définitions de classes NSManagedObject
find_managed_object_classes() {
    echo -e "${BLUE}Recherche des classes NSManagedObject...${NC}"
    grep -r --include="*.swift" "NSManagedObject" --exclude-dir="$BACKUP_DIR" . | grep "class" | sort
    
    echo -e "\n${BLUE}Classes étendant NSManagedObject:${NC}" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    grep -r --include="*.swift" "NSManagedObject" --exclude-dir="$BACKUP_DIR" . | grep "class" | sort >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
}

# Fonction pour trouver les représentations modèles de classes CoreData
find_model_representations() {
    echo -e "${BLUE}Recherche des représentations modèles des entités CoreData...${NC}"
    grep -r --include="*.swift" "init(from.*Entity" --exclude-dir="$BACKUP_DIR" . | sort
    
    echo -e "\n${BLUE}Représentations modèles des entités CoreData:${NC}" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    grep -r --include="*.swift" "init(from.*Entity" --exclude-dir="$BACKUP_DIR" . | sort >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
}

# Fonction pour trouver les extensions d'entités
find_entity_extensions() {
    echo -e "${BLUE}Recherche des extensions d'entités CoreData...${NC}"
    grep -r --include="*.swift" "extension.*Entity" --exclude-dir="$BACKUP_DIR" . | sort
    
    echo -e "\n${BLUE}Extensions d'entités CoreData:${NC}" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    grep -r --include="*.swift" "extension.*Entity" --exclude-dir="$BACKUP_DIR" . | sort >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
}

# Fonction pour trouver les définitions de fetchRequest
find_fetch_requests() {
    echo -e "${BLUE}Recherche des définitions de fetchRequest...${NC}"
    grep -r --include="*.swift" "fetchRequest()" --exclude-dir="$BACKUP_DIR" . | sort
    
    echo -e "\n${BLUE}Définitions de fetchRequest:${NC}" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    grep -r --include="*.swift" "fetchRequest()" --exclude-dir="$BACKUP_DIR" . | sort >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
}

# Fonction pour trouver les utilisations d'attributs @NSManaged
find_nsmanaged_attributes() {
    echo -e "${BLUE}Recherche des attributs @NSManaged...${NC}"
    grep -r --include="*.swift" "@NSManaged" --exclude-dir="$BACKUP_DIR" . | sort
    
    echo -e "\n${BLUE}Attributs @NSManaged:${NC}" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    grep -r --include="*.swift" "@NSManaged" --exclude-dir="$BACKUP_DIR" . | sort >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
}

# Fonction pour trouver les conversions d'entités vers modèles
find_entity_to_model_conversions() {
    echo -e "${BLUE}Recherche des conversions entité vers modèle...${NC}"
    grep -r --include="*.swift" "from: \$0" --exclude-dir="$BACKUP_DIR" . | sort
    
    echo -e "\n${BLUE}Conversions d'entités vers modèles:${NC}" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    grep -r --include="*.swift" "from: \$0" --exclude-dir="$BACKUP_DIR" . | sort >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
}

# Fonction pour trouver les enum utilisés dans le contexte CoreData
find_enums_in_coredata() {
    echo -e "${BLUE}Recherche des enum utilisés avec CoreData...${NC}"
    
    # Rechercher les enum
    ENUM_FILES=$(grep -l --include="*.swift" "enum.*:.*String" --exclude-dir="$BACKUP_DIR" .)
    
    for file in $ENUM_FILES; do
        echo -e "${CYAN}Enum trouvés dans $file:${NC}"
        grep -n "enum.*:.*String" "$file"
    done
    
    echo -e "\n${BLUE}Enum utilisés avec CoreData:${NC}" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    for file in $ENUM_FILES; do
        echo "Dans $file:" >> "$REPORT_FILE"
        grep -n "enum.*:.*String" "$file" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    done
    echo "\`\`\`" >> "$REPORT_FILE"
}

# Fonction pour analyser les ambiguïtés de types
analyze_type_ambiguities() {
    echo -e "${BLUE}Analyse des ambiguïtés de types...${NC}"
    
    # Rechercher MasteryLevel
    echo -e "${CYAN}Recherche des références à MasteryLevel:${NC}"
    grep -r --include="*.swift" "MasteryLevel" --exclude-dir="$BACKUP_DIR" . | sort
    
    # Rechercher ReviewRating
    echo -e "${CYAN}Recherche des références à ReviewRating:${NC}"
    grep -r --include="*.swift" "ReviewRating" --exclude-dir="$BACKUP_DIR" . | sort
    
    echo -e "\n${BLUE}Analyse des ambiguïtés de types:${NC}" >> "$REPORT_FILE"
    echo -e "### MasteryLevel" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    grep -r --include="*.swift" "MasteryLevel" --exclude-dir="$BACKUP_DIR" . | sort >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    
    echo -e "### ReviewRating" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    grep -r --include="*.swift" "ReviewRating" --exclude-dir="$BACKUP_DIR" . | sort >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
}

# Fonction pour analyser les problèmes d'ambiguïté avec Core.Common
analyze_core_common_ambiguities() {
    echo -e "${BLUE}Analyse des ambiguïtés avec Core.Common...${NC}"
    
    # Rechercher Core.Common
    echo -e "${CYAN}Recherche des références à Core.Common:${NC}"
    grep -r --include="*.swift" "Core\.Common" --exclude-dir="$BACKUP_DIR" . | sort
    
    # Rechercher Core.Models.Common
    echo -e "${CYAN}Recherche des références à Core.Models.Common:${NC}"
    grep -r --include="*.swift" "Core\.Models\.Common" --exclude-dir="$BACKUP_DIR" . | sort
    
    echo -e "\n${BLUE}Analyse des ambiguïtés avec Core.Common:${NC}" >> "$REPORT_FILE"
    echo -e "### Core.Common" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    grep -r --include="*.swift" "Core\.Common" --exclude-dir="$BACKUP_DIR" . | sort >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    
    echo -e "### Core.Models.Common" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    grep -r --include="*.swift" "Core\.Models\.Common" --exclude-dir="$BACKUP_DIR" . | sort >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
}

# Fonction pour analyser les problèmes de PersistenceController
analyze_persistence_controller_ambiguities() {
    echo -e "${BLUE}Analyse des ambiguïtés avec PersistenceController...${NC}"
    
    # Rechercher PersistenceController
    echo -e "${CYAN}Recherche des références à PersistenceController:${NC}"
    grep -r --include="*.swift" "PersistenceController" --exclude-dir="$BACKUP_DIR" . | sort
    
    echo -e "\n${BLUE}Analyse des ambiguïtés avec PersistenceController:${NC}" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    grep -r --include="*.swift" "PersistenceController" --exclude-dir="$BACKUP_DIR" . | sort >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
}

# Fonction pour générer des recommandations
generate_recommendations() {
    echo -e "${BLUE}Génération des recommandations...${NC}"
    
    cat >> "$REPORT_FILE" << EOF

## Recommandations

Sur la base de l'analyse, voici les recommandations pour résoudre les ambiguïtés de types CoreData:

1. **Unification des modèles CoreData**
   - Utiliser un seul modèle CoreData nommé "CardApp" au lieu des deux modèles actuels
   - Mettre à jour toutes les références à NSPersistentContainer pour utiliser ce nom unifié

2. **Normalisation des types communs**
   - Définir les types comme MasteryLevel et ReviewRating dans un seul emplacement
   - Utiliser des imports qualifiés pour ces types partout ailleurs

3. **Résolution des problèmes d'ambiguïté**
   - Utiliser des qualificateurs complets pour les types ambigus (ex: Core.Common.ReviewRating)
   - Ajouter des imports clairs au début des fichiers

4. **Nettoyage des conversions entité-modèle**
   - Normaliser les initializers des modèles à partir des entités
   - S'assurer que toutes les conversions gèrent correctement les valeurs optionnelles

5. **Refactoring du PersistenceController**
   - S'assurer que PersistenceController n'est défini qu'à un seul endroit
   - Utiliser une qualification complète pour toutes les références

## Plan d'action

1. Exécuter le script \`fix_coredata_models.sh\` pour unifier les modèles CoreData
2. Exécuter le script \`fix_ambiguous_types.sh\` pour corriger les références ambiguës
3. Vérifier et corriger manuellement les problèmes restants
4. Mettre en place des directives pour éviter ces problèmes à l'avenir

EOF
}

# Exécution des analyses
find_managed_object_classes
find_model_representations
find_entity_extensions
find_fetch_requests
find_nsmanaged_attributes
find_entity_to_model_conversions
find_enums_in_coredata
analyze_type_ambiguities
analyze_core_common_ambiguities
analyze_persistence_controller_ambiguities

# Génération des recommandations
generate_recommendations

echo -e "${GREEN}=== Analyse terminée ===${NC}"
echo -e "${CYAN}Rapport généré dans: $REPORT_FILE${NC}"
echo -e "${CYAN}Les sauvegardes ont été créées dans: $BACKUP_DIR${NC}" 