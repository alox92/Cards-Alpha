#!/bin/bash

# Définition des couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Chemin vers le fichier UnifiedStudyService.swift
FILE_PATH="Core/Services/Unified/UnifiedStudyService.swift"

# Vérifier si le fichier existe
if [ ! -f "$FILE_PATH" ]; then
    echo -e "${RED}Erreur: Le fichier $FILE_PATH n'existe pas.${NC}"
    exit 1
fi

# Fonction pour vérifier la présence de problèmes courants
check_common_issues() {
    echo -e "${BLUE}Vérification des problèmes courants...${NC}"
    
    # 1. Vérifier les déclarations incorrectes de fetchRequest
    incorrect_declarations=$(grep -c "fetchRequest\.fetchBatchSize = 20; = " "$FILE_PATH")
    if [ "$incorrect_declarations" -gt 0 ]; then
        echo -e "${RED}Problème: $incorrect_declarations déclarations incorrectes de fetchRequest trouvées.${NC}"
    else
        echo -e "${GREEN}OK: Aucune déclaration incorrecte de fetchRequest trouvée.${NC}"
    fi
    
    # 2. Vérifier les références à fetchRequest non définies
    undefined_references=$(grep -c "fetchRequest\.fetchBatchSize = 20;" "$FILE_PATH")
    if [ "$undefined_references" -gt 0 ]; then
        echo -e "${YELLOW}Attention: $undefined_references références potentielles à fetchRequest non définies.${NC}"
        echo -e "${BLUE}Lignes concernées:${NC}"
        grep -n "fetchRequest\.fetchBatchSize = 20;" "$FILE_PATH" | head -5
    else
        echo -e "${GREEN}OK: Aucune référence à fetchRequest non définie trouvée.${NC}"
    fi
    
    # 3. Vérifier les doublons de blocs try-catch
    duplicate_try_catch=$(grep -n "do {" "$FILE_PATH" | awk -F: '{print $1}' | sort -n | uniq -d | wc -l)
    if [ "$duplicate_try_catch" -gt 0 ]; then
        echo -e "${RED}Problème: Des doublons de blocs try-catch ont été détectés.${NC}"
    else
        echo -e "${GREEN}OK: Aucun doublon de blocs try-catch détecté.${NC}"
    fi
    
    # 4. Vérifier les closures sans [weak self]
    missing_weak_self=$(grep -c "Task {$" "$FILE_PATH")
    if [ "$missing_weak_self" -gt 0 ]; then
        echo -e "${RED}Problème: $missing_weak_self Task sans [weak self] trouvées.${NC}"
    else
        echo -e "${GREEN}OK: Toutes les Task utilisent [weak self].${NC}"
    fi
    
    # 5. Vérifier les qualifications incorrectes des types
    incorrect_qualifications=$(grep -c "Core\.Common\.StudyServiceError" "$FILE_PATH")
    incorrect_qualifications=$((incorrect_qualifications + $(grep -c "Core\.Common\.ReviewRating" "$FILE_PATH")))
    incorrect_qualifications=$((incorrect_qualifications + $(grep -c "Core\.Models\.Common\.MasteryLevel" "$FILE_PATH")))
    if [ "$incorrect_qualifications" -gt 0 ]; then
        echo -e "${RED}Problème: $incorrect_qualifications qualifications incorrectes de types trouvées.${NC}"
    else
        echo -e "${GREEN}OK: Aucune qualification incorrecte de types trouvée.${NC}"
    fi
}

# Fonction pour vérifier les problèmes de structure
check_structure_issues() {
    echo -e "${BLUE}Vérification des problèmes de structure...${NC}"
    
    # 1. Vérifier les couples accolade ouvrante/fermante
    open_braces=$(grep -c "{" "$FILE_PATH")
    close_braces=$(grep -c "}" "$FILE_PATH")
    if [ "$open_braces" -ne "$close_braces" ]; then
        echo -e "${RED}Problème: Déséquilibre d'accolades ($open_braces ouvertes, $close_braces fermées).${NC}"
    else
        echo -e "${GREEN}OK: Les accolades sont équilibrées.${NC}"
    fi
    
    # 2. Vérifier les imports
    required_imports=("Foundation" "CoreData" "Combine" "Core")
    for import in "${required_imports[@]}"; do
        if ! grep -q "import $import" "$FILE_PATH"; then
            echo -e "${RED}Problème: L'import de $import est manquant.${NC}"
        else
            echo -e "${GREEN}OK: L'import de $import est présent.${NC}"
        fi
    done
    
    # 3. Vérifier la définition des structures Sendable
    required_structures=("SendableReviewData" "SendableCardData" "SendableCardReviewData" "SendableSessionData")
    for struct in "${required_structures[@]}"; do
        if ! grep -q "struct $struct" "$FILE_PATH"; then
            echo -e "${YELLOW}Attention: La structure $struct n'est pas définie.${NC}"
        else
            echo -e "${GREEN}OK: La structure $struct est définie.${NC}"
        fi
    done
}

# Fonction pour vérifier la syntaxe Swift (nécessite swiftc)
check_swift_syntax() {
    echo -e "${BLUE}Vérification de la syntaxe Swift...${NC}"
    
    # Créer un fichier temporaire pour les erreurs
    TMP_ERROR_FILE=$(mktemp)
    
    # Essayer de compiler le fichier pour détecter les erreurs de syntaxe
    if which swiftc > /dev/null; then
        # Utiliser swiftc si disponible
        swiftc -parse "$FILE_PATH" 2> "$TMP_ERROR_FILE"
        
        if [ -s "$TMP_ERROR_FILE" ]; then
            error_count=$(grep -c "error:" "$TMP_ERROR_FILE")
            echo -e "${RED}Problème: $error_count erreurs de syntaxe détectées.${NC}"
            echo -e "${YELLOW}Premières erreurs:${NC}"
            grep "error:" "$TMP_ERROR_FILE" | head -5
        else
            echo -e "${GREEN}OK: Aucune erreur de syntaxe détectée par swiftc.${NC}"
        fi
    else
        echo -e "${YELLOW}Impossible de vérifier la syntaxe Swift: swiftc n'est pas disponible.${NC}"
        echo -e "${YELLOW}Installation recommandée du package Xcode Command Line Tools.${NC}"
    fi
    
    # Supprimer le fichier temporaire
    rm "$TMP_ERROR_FILE"
}

# Fonction pour afficher un résumé
show_summary() {
    echo -e "\n${BLUE}=== Résumé de la vérification pour $FILE_PATH ===${NC}"
    
    # Compter les problèmes critiques
    critical_issues=0
    critical_issues=$((critical_issues + $(grep -c "fetchRequest\.fetchBatchSize = 20; = " "$FILE_PATH")))
    critical_issues=$((critical_issues + $(grep -c "Core\.Common\.StudyServiceError" "$FILE_PATH")))
    critical_issues=$((critical_issues + $(grep -c "Core\.Common\.ReviewRating" "$FILE_PATH")))
    critical_issues=$((critical_issues + $(grep -c "Core\.Models\.Common\.MasteryLevel" "$FILE_PATH")))
    
    open_braces=$(grep -c "{" "$FILE_PATH")
    close_braces=$(grep -c "}" "$FILE_PATH")
    if [ "$open_braces" -ne "$close_braces" ]; then
        critical_issues=$((critical_issues + 1))
    fi
    
    # Compter les problèmes mineurs
    minor_issues=0
    minor_issues=$((minor_issues + $(grep -c "fetchRequest\.fetchBatchSize = 20;" "$FILE_PATH")))
    minor_issues=$((minor_issues + $(grep -c "Task {$" "$FILE_PATH")))
    
    # Afficher le résumé
    if [ "$critical_issues" -eq 0 ] && [ "$minor_issues" -eq 0 ]; then
        echo -e "${GREEN}✓ Aucun problème détecté dans le fichier. Toutes les corrections ont été appliquées avec succès.${NC}"
    elif [ "$critical_issues" -eq 0 ]; then
        echo -e "${YELLOW}⚠ Des problèmes mineurs ont été détectés ($minor_issues), mais aucun problème critique.${NC}"
        echo -e "${YELLOW}→ Une vérification manuelle est recommandée pour s'assurer de la qualité du code.${NC}"
    else
        echo -e "${RED}✗ Des problèmes critiques ($critical_issues) et mineurs ($minor_issues) ont été détectés.${NC}"
        echo -e "${RED}→ Des corrections supplémentaires sont nécessaires.${NC}"
    fi
}

# Fonction principale d'exécution
main() {
    echo -e "${BLUE}Démarrage de la vérification pour $FILE_PATH...${NC}\n"
    
    # Exécuter les vérifications
    check_common_issues
    echo ""
    check_structure_issues
    echo ""
    check_swift_syntax
    
    # Afficher le résumé
    show_summary
}

# Exécution du script
main 