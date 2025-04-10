#!/bin/bash

# Définition des couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonction pour afficher un message en gras
bold() {
    echo -e "${YELLOW}=== $1 ===${NC}"
}

# Dossier du projet
PROJECT_DIR="$(pwd)"
BUILD_LOG="$PROJECT_DIR/build_log.txt"
ERROR_LOG="$PROJECT_DIR/build_errors.txt"

# Créer un répertoire pour les rapports
REPORTS_DIR="$PROJECT_DIR/build_reports"
mkdir -p "$REPORTS_DIR"

# Timestamp pour les rapports
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPORTS_DIR/build_report_$TIMESTAMP.md"

bold "Vérification de l'environnement de compilation"

# Vérifier si xcodebuild est disponible
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Erreur: xcodebuild n'est pas disponible.${NC}"
    echo -e "${YELLOW}Ce script nécessite Xcode Command Line Tools.${NC}"
    exit 1
fi

# Vérifier si nous sommes dans un projet Xcode ou un workspace
XCODEPROJ=$(find . -maxdepth 1 -name "*.xcodeproj" | head -n 1)
WORKSPACE=$(find . -maxdepth 1 -name "*.xcworkspace" | head -n 1)

if [ -z "$XCODEPROJ" ] && [ -z "$WORKSPACE" ]; then
    echo -e "${RED}Erreur: Aucun projet Xcode (.xcodeproj) ou workspace (.xcworkspace) trouvé dans le répertoire courant.${NC}"
    exit 1
fi

# Déterminer le schéma à compiler
if [ -n "$WORKSPACE" ]; then
    BUILD_TARGET="$WORKSPACE"
    SCHEMES=$(xcodebuild -workspace "$WORKSPACE" -list | grep -A 100 "Schemes:" | grep -v "Schemes:" | grep -v "^$" | sed 's/^ *//')
else
    BUILD_TARGET="$XCODEPROJ"
    SCHEMES=$(xcodebuild -project "$XCODEPROJ" -list | grep -A 100 "Schemes:" | grep -v "Schemes:" | grep -v "^$" | sed 's/^ *//')
fi

# Utiliser le premier schéma disponible ou un schéma par défaut
if [ -n "$SCHEMES" ]; then
    SCHEME=$(echo "$SCHEMES" | head -n 1)
    echo -e "${BLUE}Schémas disponibles:${NC}"
    echo "$SCHEMES" | sed 's/^/  - /'
    echo -e "${GREEN}Utilisation du schéma: $SCHEME${NC}"
else
    SCHEME="CardApp"
    echo -e "${YELLOW}Aucun schéma trouvé. Utilisation du schéma par défaut: $SCHEME${NC}"
fi

# Initier le rapport
cat > "$REPORT_FILE" << EOF
# Rapport de Compilation CardApp

Date: $(date "+%Y-%m-%d %H:%M:%S")

## Environnement

- OS: $(sw_vers -productName) $(sw_vers -productVersion)
- Xcode: $(xcodebuild -version | head -n 1)

## Cible de compilation

EOF

if [ -n "$WORKSPACE" ]; then
    echo "- Workspace: $(basename "$WORKSPACE")" >> "$REPORT_FILE"
else
    echo "- Projet: $(basename "$XCODEPROJ")" >> "$REPORT_FILE"
fi
echo "- Schéma: $SCHEME" >> "$REPORT_FILE"

# Fonction pour compiler le projet
build_project() {
    bold "Compilation du projet"
    echo -e "${CYAN}Compilation en cours, veuillez patienter...${NC}"

    if [ -n "$WORKSPACE" ]; then
        xcodebuild clean build -workspace "$WORKSPACE" -scheme "$SCHEME" -configuration Debug -sdk iphonesimulator -destination "platform=iOS Simulator,name=iPhone 14" | tee "$BUILD_LOG"
    else
        xcodebuild clean build -project "$XCODEPROJ" -scheme "$SCHEME" -configuration Debug -sdk iphonesimulator -destination "platform=iOS Simulator,name=iPhone 14" | tee "$BUILD_LOG"
    fi

    BUILD_RESULT=$?

    # Extraire les erreurs et avertissements
    grep -E "error:|warning:" "$BUILD_LOG" > "$ERROR_LOG"
    
    ERROR_COUNT=$(grep -c "error:" "$ERROR_LOG")
    WARNING_COUNT=$(grep -c "warning:" "$ERROR_LOG")

    # Ajouter les résultats au rapport
    cat >> "$REPORT_FILE" << EOF

## Résultat de la compilation

- Statut: $([ $BUILD_RESULT -eq 0 ] && echo "✅ Succès" || echo "❌ Échec")
- Erreurs: $ERROR_COUNT
- Avertissements: $WARNING_COUNT

EOF

    if [ $ERROR_COUNT -gt 0 ]; then
        cat >> "$REPORT_FILE" << EOF

## Erreurs de compilation

\`\`\`
$(grep "error:" "$ERROR_LOG")
\`\`\`

EOF
    fi

    if [ $WARNING_COUNT -gt 0 ]; then
        cat >> "$REPORT_FILE" << EOF

## Avertissements

\`\`\`
$(grep "warning:" "$ERROR_LOG" | head -10)
$([ $(grep "warning:" "$ERROR_LOG" | wc -l) -gt 10 ] && echo "... et $(( $(grep "warning:" "$ERROR_LOG" | wc -l) - 10 )) autres avertissements")
\`\`\`

EOF
    fi

    # Analyser les types d'erreurs les plus fréquents
    if [ $ERROR_COUNT -gt 0 ]; then
        bold "Analyse des types d'erreurs"
        
        cat >> "$REPORT_FILE" << EOF

## Types d'erreurs les plus fréquents

EOF

        # Extraire et regrouper les types d'erreurs
        grep "error:" "$ERROR_LOG" | sed 's/.*error: //' | cut -d':' -f1 | sort | uniq -c | sort -nr | head -10 | while read -r count type; do
            echo "- **$type**: $count occurrences" >> "$REPORT_FILE"
        done

        # Chercher des erreurs spécifiques connues
        if grep -q "Cannot find type 'ReviewRating' in scope" "$ERROR_LOG"; then
            cat >> "$REPORT_FILE" << EOF

### Problème d'import des types (ReviewRating)

Plusieurs erreurs concernent le type `ReviewRating` qui n'est pas trouvé. Recommandations:

1. Vérifier que l'import du module contenant ce type est présent
2. Utiliser le chemin complet du type (Ex: `Core.Common.ReviewRating`)
3. Exécuter le script de correction des imports: \`./analysis_tools/fix_module_imports.sh\`

EOF
        fi

        if grep -q "Cannot find type 'MasteryLevel' in scope" "$ERROR_LOG"; then
            cat >> "$REPORT_FILE" << EOF

### Problème d'import des types (MasteryLevel)

Plusieurs erreurs concernent le type `MasteryLevel` qui n'est pas trouvé. Recommandations:

1. Vérifier que l'import du module contenant ce type est présent
2. Utiliser le chemin complet du type (Ex: `Core.Models.Common.MasteryLevel`)
3. Exécuter le script de correction des imports: \`./analysis_tools/fix_module_imports.sh\`

EOF
        fi

        if grep -q "is ambiguous for type lookup in this context" "$ERROR_LOG"; then
            cat >> "$REPORT_FILE" << EOF

### Types ambigus

Des types ambigus ont été détectés, ce qui indique plusieurs définitions du même type. Recommandations:

1. Qualifier les types avec leur module complet
2. Exécuter le script de correction des types ambigus: \`./analysis_tools/fix_ambiguous_types.sh\`

EOF
        fi

        if grep -q "non-sendable type .* in a '@Sendable' closure" "$ERROR_LOG"; then
            cat >> "$REPORT_FILE" << EOF

### Problèmes de concurrence avec types non-Sendable

Des types non conformes à Sendable sont utilisés dans des closures @Sendable. Recommandations:

1. Créer des wrappers Sendable pour ces types (structures immuables)
2. Utiliser des types de données isolés dans les contextes concurrent
3. Exécuter le script de correction de concurrence: \`./analysis_tools/fix_manually.sh\`

EOF
        fi
    fi

    # Afficher le résultat
    if [ $BUILD_RESULT -eq 0 ]; then
        echo -e "${GREEN}Compilation réussie !${NC}"
    else
        echo -e "${RED}Échec de la compilation.${NC}"
        echo -e "${YELLOW}$ERROR_COUNT erreurs et $WARNING_COUNT avertissements détectés.${NC}"
        
        # Afficher un résumé des erreurs par type
        echo -e "${BLUE}Types d'erreurs les plus fréquents:${NC}"
        grep "error:" "$ERROR_LOG" | sed 's/.*error: //' | cut -d':' -f1 | sort | uniq -c | sort -nr | head -5 | while read -r count type; do
            echo -e "  ${RED}- $type: $count occurrences${NC}"
        done
    fi
    
    echo -e "${GREEN}Rapport détaillé généré: $REPORT_FILE${NC}"
}

# Exécuter la compilation
build_project

# Recommandations finales
cat >> "$REPORT_FILE" << EOF

## Recommandations

1. Si des problèmes d'imports persistent:
   - Exécuter \`./analysis_tools/fix_module_imports.sh\` pour corriger les imports
   - Consulter \`docs/README-FIXES-IMPORTS.md\` pour les bonnes pratiques d'imports

2. Pour les problèmes de types ambigus:
   - Exécuter \`./analysis_tools/fix_ambiguous_types.sh\`
   - Vérifier les fichiers dans \`Core/Common\` et \`Core/Models/Common\` pour éliminer les duplications

3. Pour les problèmes de concurrence:
   - Consulter \`analyze_unified_study.md\` pour les bonnes pratiques
   - Exécuter \`./analysis_tools/fix_manually.sh\` pour UnifiedStudyService

4. Pour une analyse plus approfondie:
   - Exécuter \`./run_analysis.sh\` pour une analyse complète du projet
   - Consulter les rapports générés dans le dossier \`reports\`
EOF

echo -e "${BLUE}Recommandations:${NC}"
echo -e "  ${CYAN}- Consultez le rapport pour des détails sur les problèmes et solutions${NC}"
echo -e "  ${CYAN}- Utilisez les scripts d'analyse et correction de la suite d'outils${NC}"
echo -e "  ${CYAN}- Pour les problèmes non résolus, consultez la documentation dans /docs${NC}" 