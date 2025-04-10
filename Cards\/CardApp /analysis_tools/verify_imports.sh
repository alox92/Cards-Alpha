#!/bin/bash

# Script de vérification des imports et références dans CardApp
# Auteur: Claude Agent
# Date: $(date +%Y-%m-%d)

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Fonction pour afficher un en-tête de section
header() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
}

# Configuration
PROJECT_ROOT="."
REPORT_FILE="verification_imports_$(date +%Y%m%d_%H%M%S).txt"

# Démarrer la création du rapport
echo "RAPPORT DE VÉRIFICATION DES IMPORTS DE CARDAPP" > "$REPORT_FILE"
echo "Date: $(date)" >> "$REPORT_FILE"
echo "----------------------------------------------" >> "$REPORT_FILE"

# 1. Vérification des imports problématiques
header "IMPORTS PROBLÉMATIQUES"

echo -e "${BLUE}Recherche des imports 'Core.Common'...${NC}"
CORE_COMMON_FILES=$(grep -r -l "import Core.Common" --include="*.swift" "$PROJECT_ROOT")
CORE_COMMON_COUNT=$(echo "$CORE_COMMON_FILES" | grep -v "^$" | wc -l)

echo -e "${BLUE}Recherche des imports 'Core.Models.Common'...${NC}"
MODELS_COMMON_FILES=$(grep -r -l "import Core.Models.Common" --include="*.swift" "$PROJECT_ROOT")
MODELS_COMMON_COUNT=$(echo "$MODELS_COMMON_FILES" | grep -v "^$" | wc -l)

echo -e "${BLUE}Recherche des imports 'Core.Commonnonisolated'...${NC}"
MALFORMED_IMPORTS=$(grep -r -l "import Core.Commonnonisolated" --include="*.swift" "$PROJECT_ROOT")
MALFORMED_COUNT=$(echo "$MALFORMED_IMPORTS" | grep -v "^$" | wc -l)

echo "1. IMPORTS PROBLÉMATIQUES" >> "$REPORT_FILE"
echo "Fichiers avec 'import Core.Common': $CORE_COMMON_COUNT" >> "$REPORT_FILE"
if [ $CORE_COMMON_COUNT -gt 0 ]; then
    echo "Fichiers concernés:" >> "$REPORT_FILE"
    echo "$CORE_COMMON_FILES" | grep -v "^$" | sed 's/^/- /' >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "Fichiers avec 'import Core.Models.Common': $MODELS_COMMON_COUNT" >> "$REPORT_FILE"
if [ $MODELS_COMMON_COUNT -gt 0 ]; then
    echo "Fichiers concernés:" >> "$REPORT_FILE"
    echo "$MODELS_COMMON_FILES" | grep -v "^$" | sed 's/^/- /' >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "Fichiers avec imports malformés: $MALFORMED_COUNT" >> "$REPORT_FILE"
if [ $MALFORMED_COUNT -gt 0 ]; then
    echo "Fichiers concernés:" >> "$REPORT_FILE"
    echo "$MALFORMED_IMPORTS" | grep -v "^$" | sed 's/^/- /' >> "$REPORT_FILE"
fi

# Affichage dans le terminal
echo -e "${YELLOW}Imports 'Core.Common': ${BOLD}$CORE_COMMON_COUNT${NC}"
echo -e "${YELLOW}Imports 'Core.Models.Common': ${BOLD}$MODELS_COMMON_COUNT${NC}"
echo -e "${YELLOW}Imports malformés: ${BOLD}$MALFORMED_COUNT${NC}"

# 2. Vérification des types ambigus
header "RÉFÉRENCES AUX TYPES AMBIGUS"

echo -e "${BLUE}Recherche des références non qualifiées à ReviewRating...${NC}"
REVIEW_RATING_REFS=$(grep -r "ReviewRating\." --include="*.swift" "$PROJECT_ROOT" | grep -v "Core\.Common\.ReviewRating\." | wc -l)

echo -e "${BLUE}Recherche des références non qualifiées à MasteryLevel...${NC}"
MASTERY_LEVEL_REFS=$(grep -r "MasteryLevel\." --include="*.swift" "$PROJECT_ROOT" | grep -v "Core\.Models\.Common\.MasteryLevel\." | wc -l)

echo -e "${BLUE}Recherche des références non qualifiées à StudyServiceError...${NC}"
ERROR_REFS=$(grep -r "StudyServiceError\." --include="*.swift" "$PROJECT_ROOT" | grep -v "Core\.Common\.StudyServiceError\." | wc -l)

echo "2. RÉFÉRENCES AUX TYPES AMBIGUS" >> "$REPORT_FILE"
echo "Références non qualifiées à ReviewRating: $REVIEW_RATING_REFS" >> "$REPORT_FILE"
echo "Références non qualifiées à MasteryLevel: $MASTERY_LEVEL_REFS" >> "$REPORT_FILE"
echo "Références non qualifiées à StudyServiceError: $ERROR_REFS" >> "$REPORT_FILE"

# Affichage dans le terminal
echo -e "${YELLOW}Références non qualifiées à ReviewRating: ${BOLD}$REVIEW_RATING_REFS${NC}"
echo -e "${YELLOW}Références non qualifiées à MasteryLevel: ${BOLD}$MASTERY_LEVEL_REFS${NC}"
echo -e "${YELLOW}Références non qualifiées à StudyServiceError: ${BOLD}$ERROR_REFS${NC}"

# 3. Vérification des ambiguïtés de PersistenceController
header "AMBIGUÏTÉS DE PERSISTENCECONTROLLER"

echo -e "${BLUE}Recherche des ambiguïtés de PersistenceController...${NC}"
AMBIG_FILES=$(grep -r "'PersistenceController' is ambiguous" --include="*.swift" "$PROJECT_ROOT")
AMBIG_COUNT=$(echo "$AMBIG_FILES" | grep -v "^$" | wc -l)

echo "3. AMBIGUÏTÉS DE PERSISTENCECONTROLLER" >> "$REPORT_FILE"
echo "Nombre d'ambiguïtés détectées: $AMBIG_COUNT" >> "$REPORT_FILE"
if [ $AMBIG_COUNT -gt 0 ]; then
    echo "Occurrences:" >> "$REPORT_FILE"
    echo "$AMBIG_FILES" >> "$REPORT_FILE"
fi

# Affichage dans le terminal
echo -e "${YELLOW}Ambiguïtés de PersistenceController: ${BOLD}$AMBIG_COUNT${NC}"

# 4. Vérification des déclarations multiples de types
header "DÉCLARATIONS MULTIPLES DE TYPES"

echo -e "${BLUE}Recherche des déclarations multiples de ReviewRating...${NC}"
REVIEW_RATING_DECL=$(grep -r "enum ReviewRating" --include="*.swift" "$PROJECT_ROOT" | wc -l)

echo -e "${BLUE}Recherche des déclarations multiples de MasteryLevel...${NC}"
MASTERY_LEVEL_DECL=$(grep -r "enum MasteryLevel" --include="*.swift" "$PROJECT_ROOT" | wc -l)

echo "4. DÉCLARATIONS MULTIPLES DE TYPES" >> "$REPORT_FILE"
echo "Déclarations de ReviewRating: $REVIEW_RATING_DECL" >> "$REPORT_FILE"
echo "Déclarations de MasteryLevel: $MASTERY_LEVEL_DECL" >> "$REPORT_FILE"

# Affichage dans le terminal
echo -e "${YELLOW}Déclarations de ReviewRating: ${BOLD}$REVIEW_RATING_DECL${NC}"
echo -e "${YELLOW}Déclarations de MasteryLevel: ${BOLD}$MASTERY_LEVEL_DECL${NC}"

# 5. Vérification des erreurs de compilation liées aux modules
header "ERREURS DE COMPILATION LIÉES AUX MODULES"

echo -e "${BLUE}Recherche des erreurs 'No such module'...${NC}"
MODULE_ERRORS=$(grep -r "No such module" --include="*.swift" "$PROJECT_ROOT" | wc -l)

echo "5. ERREURS DE COMPILATION LIÉES AUX MODULES" >> "$REPORT_FILE"
echo "Erreurs 'No such module': $MODULE_ERRORS" >> "$REPORT_FILE"

# Affichage dans le terminal
echo -e "${YELLOW}Erreurs 'No such module': ${BOLD}$MODULE_ERRORS${NC}"

# Résumé global
header "RÉSUMÉ DE LA VÉRIFICATION"

TOTAL_ISSUES=$((CORE_COMMON_COUNT + MODELS_COMMON_COUNT + MALFORMED_COUNT + REVIEW_RATING_REFS + MASTERY_LEVEL_REFS + ERROR_REFS + AMBIG_COUNT + (REVIEW_RATING_DECL > 1 ? REVIEW_RATING_DECL - 1 : 0) + (MASTERY_LEVEL_DECL > 1 ? MASTERY_LEVEL_DECL - 1 : 0) + MODULE_ERRORS))

echo "RÉSUMÉ GLOBAL" >> "$REPORT_FILE"
echo "Nombre total de problèmes détectés: $TOTAL_ISSUES" >> "$REPORT_FILE"
echo "Rapport enregistré dans: $REPORT_FILE" >> "$REPORT_FILE"

if [ $TOTAL_ISSUES -eq 0 ]; then
    echo -e "${GREEN}${BOLD}Aucun problème d'import détecté. Le projet est propre!${NC}"
    echo -e "Pour plus de détails, consultez le rapport: ${BOLD}$REPORT_FILE${NC}"
else
    echo -e "${RED}${BOLD}$TOTAL_ISSUES problème(s) d'import détecté(s)!${NC}"
    echo -e "Pour plus de détails, consultez le rapport: ${BOLD}$REPORT_FILE${NC}"
    echo -e "${YELLOW}Suggestion: Exécutez ${BOLD}./analysis_tools/fix_module_imports.sh${NC} ${YELLOW}pour tenter de corriger ces problèmes automatiquement.${NC}"
fi

exit $TOTAL_ISSUES 