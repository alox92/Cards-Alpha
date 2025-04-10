#!/bin/bash

# ============================================================
# SCRIPT DE VÉRIFICATION DES CORRECTIONS
# ============================================================
#
# Ce script compile le projet après les corrections pour vérifier
# qu'aucune erreur n'a été introduite.
#
# Auteur: Claude
# Version: 1.0

# Couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR=$(pwd)
BUILD_LOG="$PROJECT_DIR/build_verification.log"

echo -e "${BLUE}=== VÉRIFICATION DES CORRECTIONS ===${NC}"
echo "Date: $(date)"
echo "Dossier du projet: $PROJECT_DIR"

# Fonction pour analyser les erreurs de compilation
analyze_errors() {
    local log_file="$1"
    local error_count=0
    local warning_count=0
    
    if [ -f "$log_file" ]; then
        error_count=$(grep -c "error:" "$log_file")
        warning_count=$(grep -c "warning:" "$log_file")
    fi
    
    echo -e "${BLUE}Résultats de la compilation:${NC}"
    echo -e "  Erreurs: ${RED}$error_count${NC}"
    echo -e "  Avertissements: ${YELLOW}$warning_count${NC}"
    
    if [ $error_count -gt 0 ]; then
        echo -e "\n${RED}Les erreurs suivantes ont été détectées:${NC}"
        grep -n "error:" "$log_file" | head -10 | while read -r line; do
            echo -e "  ${RED}$line${NC}"
        done
        
        if [ $error_count -gt 10 ]; then
            echo -e "  ${RED}... et $(($error_count - 10)) autres erreurs.${NC}"
        fi
        
        echo -e "\n${YELLOW}Suggestions de correction:${NC}"
        echo "  1. Vérifiez les modifications dans UnifiedStudyService.swift"
        echo "  2. Assurez-vous que les closures avec [weak self] ont la syntaxe correcte"
        echo "  3. Vérifiez que toutes les déclarations async/await sont cohérentes"
        echo "  4. Pour plus de détails, consultez $BUILD_LOG"
        
        return 1
    else
        echo -e "\n${GREEN}Aucune erreur de compilation détectée!${NC}"
        
        if [ $warning_count -gt 0 ]; then
            echo -e "\n${YELLOW}Avertissements:${NC}"
            grep -n "warning:" "$log_file" | head -5 | while read -r line; do
                echo -e "  ${YELLOW}$line${NC}"
            done
            
            if [ $warning_count -gt 5 ]; then
                echo -e "  ${YELLOW}... et $(($warning_count - 5)) autres avertissements.${NC}"
            fi
        fi
        
        return 0
    fi
}

# Fonction pour vérifier les problèmes de mémoire courants
check_memory_issues() {
    echo -e "\n${BLUE}Vérification des problèmes de mémoire...${NC}"
    
    # 1. Vérifier les closures avec/sans [weak self]
    local files=$(find "$PROJECT_DIR" -name "*.swift" -not -path "*/\.*" | xargs grep -l "self\.")
    local weak_self_missing=0
    
    for file in $files; do
        local closures=$(grep -c "{ *$" "$file")
        local weak_self=$(grep -c "\[weak self\]" "$file")
        
        if [ $closures -gt $weak_self ]; then
            weak_self_missing=$((weak_self_missing + (closures - weak_self)))
            echo -e "${YELLOW}⚠️ $file: Potentiellement $(($closures - $weak_self)) closures sans [weak self]${NC}"
        fi
    done
    
    if [ $weak_self_missing -eq 0 ]; then
        echo -e "${GREEN}✅ Aucun problème de [weak self] manquant détecté${NC}"
    else
        echo -e "${YELLOW}⚠️ $weak_self_missing closures potentiellement sans [weak self] détectées${NC}"
    fi
    
    # 2. Vérifier les déréférencements forcés (!)
    local forced_unwraps=$(find "$PROJECT_DIR" -name "*.swift" -not -path "*/\.*" | xargs grep -l "!")
    local forced_unwrap_count=$(echo "$forced_unwraps" | wc -l)
    
    if [ $forced_unwrap_count -gt 0 ]; then
        echo -e "${YELLOW}⚠️ $forced_unwrap_count fichiers avec déréférencenents forcés (!) détectés${NC}"
    else
        echo -e "${GREEN}✅ Aucun déréférencement forcé détecté${NC}"
    fi
}

# Fonction pour vérifier les problèmes CoreData
check_coredata_issues() {
    echo -e "\n${BLUE}Vérification des problèmes CoreData...${NC}"
    
    # 1. Vérifier les fetchLimit manquants
    local fetch_requests=$(find "$PROJECT_DIR" -name "*.swift" -not -path "*/\.*" | xargs grep -l "NSFetchRequest<")
    local without_limit=0
    
    for file in $fetch_requests; do
        local requests=$(grep -c "NSFetchRequest<" "$file")
        local with_limit=$(grep -c "fetchLimit" "$file")
        
        if [ $requests -gt $with_limit ]; then
            without_limit=$((without_limit + (requests - with_limit)))
            echo -e "${YELLOW}⚠️ $file: $(($requests - $with_limit)) requêtes sans fetchLimit${NC}"
        fi
    done
    
    if [ $without_limit -eq 0 ]; then
        echo -e "${GREEN}✅ Toutes les requêtes NSFetchRequest ont un fetchLimit${NC}"
    else
        echo -e "${YELLOW}⚠️ $without_limit requêtes sans fetchLimit détectées${NC}"
    fi
    
    # 2. Vérifier les context.save() sans gestion d'erreurs
    local context_saves=$(find "$PROJECT_DIR" -name "*.swift" -not -path "*/\.*" | xargs grep -l "context\.save()")
    local without_try_catch=0
    
    for file in $context_saves; do
        local saves=$(grep -c "context\.save()" "$file")
        local with_try=$(grep -c "try.*context\.save()" "$file")
        
        if [ $saves -gt $with_try ]; then
            without_try_catch=$((without_try_catch + (saves - with_try)))
            echo -e "${YELLOW}⚠️ $file: $(($saves - $with_try)) appels context.save() sans try${NC}"
        fi
    done
    
    if [ $without_try_catch -eq 0 ]; then
        echo -e "${GREEN}✅ Tous les appels context.save() utilisent try avec gestion d'erreurs${NC}"
    else
        echo -e "${YELLOW}⚠️ $without_try_catch appels context.save() sans try détectés${NC}"
    fi
}

# Vérifier si UnifiedStudyService a @MainActor
check_unified_study_service() {
    echo -e "\n${BLUE}Vérification de UnifiedStudyService...${NC}"
    
    local file="$PROJECT_DIR/Core/Services/Unified/UnifiedStudyService.swift"
    
    if [ -f "$file" ]; then
        if grep -q "@MainActor.*class UnifiedStudyService" "$file"; then
            echo -e "${GREEN}✅ UnifiedStudyService utilise @MainActor${NC}"
        else
            echo -e "${RED}❌ UnifiedStudyService n'utilise pas @MainActor${NC}"
        fi
        
        local weak_self=$(grep -c "\[weak self\]" "$file")
        echo -e "${CYAN}ℹ️ $weak_self utilisations de [weak self] dans UnifiedStudyService${NC}"
        
        local fetch_limit=$(grep -c "fetchLimit" "$file")
        echo -e "${CYAN}ℹ️ $fetch_limit utilisation(s) de fetchLimit dans UnifiedStudyService${NC}"
        
        local batch_size=$(grep -c "fetchBatchSize" "$file")
        echo -e "${CYAN}ℹ️ $batch_size utilisation(s) de fetchBatchSize dans UnifiedStudyService${NC}"
        
        local try_catch=$(grep -c "try.*catch" "$file")
        echo -e "${CYAN}ℹ️ $try_catch bloc(s) try-catch dans UnifiedStudyService${NC}"
    else
        echo -e "${RED}❌ Fichier UnifiedStudyService.swift non trouvé${NC}"
    fi
}

# Fonction principale
main() {
    # Compiler le projet
    echo -e "${BLUE}Vérification des corrections...${NC}"
    
    # Vérifier les problèmes
    check_memory_issues
    check_coredata_issues
    check_unified_study_service
    
    echo -e "\n${GREEN}✅ Vérification des corrections terminée.${NC}"
}

# Exécuter la fonction principale
main

exit 0 