#!/bin/bash

# Définition des couleurs pour une meilleure lisibilité
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Chemin du fichier UnifiedStudyService
UNIFIED_STUDY_SERVICE="Core/Services/Unified/UnifiedStudyService.swift"

# Vérification de l'existence du fichier
if [ ! -f "$UNIFIED_STUDY_SERVICE" ]; then
    echo -e "${RED}Erreur: Le fichier $UNIFIED_STUDY_SERVICE n'existe pas.${NC}"
    exit 1
fi

# Création d'un répertoire de sauvegarde
BACKUP_DIR="backups_unifiedstudy_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo -e "${BLUE}Création du répertoire de sauvegarde: $BACKUP_DIR${NC}"

# Sauvegarde du fichier original
cp "$UNIFIED_STUDY_SERVICE" "$BACKUP_DIR/"
echo -e "${GREEN}Fichier original sauvegardé dans $BACKUP_DIR/$UNIFIED_STUDY_SERVICE${NC}"

# Fonction pour ajouter @MainActor si nécessaire
add_main_actor() {
    local file="$1"
    if grep -q "@MainActor" "$file"; then
        echo -e "${YELLOW}@MainActor est déjà présent dans le fichier.${NC}"
    else
        echo -e "${BLUE}Ajout de @MainActor à la classe...${NC}"
        # Remplacer la ligne de déclaration de classe pour inclure @MainActor
        sed -i.bak 's/class UnifiedStudyService/@MainActor class UnifiedStudyService/' "$file"
        echo -e "${GREEN}@MainActor ajouté avec succès.${NC}"
    fi
}

# Fonction pour corriger les fermetures sans [weak self]
add_weak_self() {
    local file="$1"
    echo -e "${BLUE}Vérification des fermetures sans [weak self]...${NC}"
    
    # Compteur de corrections
    local weak_self_corrections=0
    
    # Chercher des modèles de fermetures sans [weak self]
    if grep -q "{ " "$file" | grep -v "\[weak self\]"; then
        # Utiliser sed pour remplacer les fermetures sans [weak self]
        sed -i.bak 's/{ $/{ [weak self] in/g' "$file"
        weak_self_corrections=$((weak_self_corrections+1))
    fi
    
    if [ $weak_self_corrections -gt 0 ]; then
        echo -e "${GREEN}$weak_self_corrections fermetures ont été corrigées pour utiliser [weak self].${NC}"
    else
        echo -e "${YELLOW}Aucune fermeture à corriger avec [weak self].${NC}"
    fi
}

# Fonction pour ajouter fetchLimit et fetchBatchSize aux requêtes
add_fetch_optimizations() {
    local file="$1"
    echo -e "${BLUE}Ajout d'optimisations fetchLimit et fetchBatchSize aux requêtes...${NC}"
    
    # Compteur de corrections
    local fetch_optimizations=0
    
    # Fichier temporaire
    local temp_file="$file.temp"
    cp "$file" "$temp_file"
    
    # Chercher des NSFetchRequest sans fetchLimit/fetchBatchSize
    if grep -q "NSFetchRequest<" "$file"; then
        # Remplacer le contenu pour ajouter fetchLimit et fetchBatchSize
        sed -i.bak '/NSFetchRequest<.*>/a\        request.fetchLimit = 1000\n        request.fetchBatchSize = 20' "$file"
        fetch_optimizations=$((fetch_optimizations+1))
    fi
    
    if [ $fetch_optimizations -gt 0 ]; then
        echo -e "${GREEN}$fetch_optimizations requêtes ont été optimisées avec fetchLimit et fetchBatchSize.${NC}"
    else
        echo -e "${YELLOW}Aucune requête à optimiser avec fetchLimit/fetchBatchSize.${NC}"
    fi
}

# Fonction pour ajouter des try-catch aux opérations CoreData
add_try_catch() {
    local file="$1"
    echo -e "${BLUE}Ajout de gestion d'erreurs try-catch aux opérations CoreData...${NC}"
    
    # Compteur de corrections
    local try_catch_corrections=0
    
    # Fichier temporaire
    local temp_file="$file.temp"
    cp "$file" "$temp_file"
    
    # Chercher des context.save() sans try-catch
    if grep -q "context\.save()" "$file" | grep -v "try"; then
        # Remplacer pour ajouter try-catch
        sed -i.bak 's/context\.save()/do { try context.save() } catch { print("Erreur lors de la sauvegarde du contexte: \(error)") }/g' "$file"
        try_catch_corrections=$((try_catch_corrections+1))
    fi
    
    if [ $try_catch_corrections -gt 0 ]; then
        echo -e "${GREEN}$try_catch_corrections opérations CoreData ont été sécurisées avec try-catch.${NC}"
    else
        echo -e "${YELLOW}Aucune opération CoreData à sécuriser avec try-catch.${NC}"
    fi
}

# Application des corrections
echo -e "${BLUE}=== Correction des problèmes dans UnifiedStudyService ===${NC}"
echo -e "${YELLOW}Fichier: $UNIFIED_STUDY_SERVICE${NC}"

# Ajouter @MainActor
add_main_actor "$UNIFIED_STUDY_SERVICE"

# Ajouter [weak self] aux fermetures
add_weak_self "$UNIFIED_STUDY_SERVICE"

# Ajouter fetchLimit et fetchBatchSize aux requêtes
add_fetch_optimizations "$UNIFIED_STUDY_SERVICE"

# Ajouter try-catch aux opérations CoreData
add_try_catch "$UNIFIED_STUDY_SERVICE"

echo -e "${GREEN}=== Corrections terminées ===${NC}"
echo -e "${YELLOW}NOTE: Certaines corrections peuvent nécessiter des ajustements manuels.${NC}"
echo -e "${BLUE}Le fichier original a été sauvegardé dans $BACKUP_DIR/$UNIFIED_STUDY_SERVICE${NC}"
echo -e "${BLUE}Pour revenir à la version originale: cp $BACKUP_DIR/$UNIFIED_STUDY_SERVICE $UNIFIED_STUDY_SERVICE${NC}"
echo -e "${GREEN}Vérifiez la compilation du projet pour vous assurer que tout fonctionne correctement.${NC}"

# Vérification finale des corrections
echo -e "\n${BLUE}=== Vérification des corrections ===${NC}"
echo -e "${YELLOW}@MainActor dans UnifiedStudyService: $(grep -c "@MainActor" "$UNIFIED_STUDY_SERVICE") occurrence(s)${NC}"
echo -e "${YELLOW}[weak self] dans UnifiedStudyService: $(grep -c "\[weak self\]" "$UNIFIED_STUDY_SERVICE") occurrence(s)${NC}"
echo -e "${YELLOW}fetchLimit dans UnifiedStudyService: $(grep -c "fetchLimit" "$UNIFIED_STUDY_SERVICE") occurrence(s)${NC}"
echo -e "${YELLOW}fetchBatchSize dans UnifiedStudyService: $(grep -c "fetchBatchSize" "$UNIFIED_STUDY_SERVICE") occurrence(s)${NC}"
echo -e "${YELLOW}try-catch dans UnifiedStudyService: $(grep -c "try.*catch" "$UNIFIED_STUDY_SERVICE") occurrence(s)${NC}"