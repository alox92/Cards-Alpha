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

# Créer un répertoire de sauvegarde avec horodatage
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups_unified_study_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Créer une copie de sauvegarde
cp "$FILE_PATH" "$BACKUP_DIR/UnifiedStudyService.swift"
echo -e "${GREEN}Sauvegarde créée dans $BACKUP_DIR/UnifiedStudyService.swift${NC}"

# Fonction pour ajouter @MainActor si nécessaire
add_main_actor() {
    echo -e "${BLUE}Vérification de l'annotation @MainActor...${NC}"
    
    # Vérifier si la classe a déjà @MainActor
    if grep -q "@MainActor" "$FILE_PATH"; then
        echo -e "${GREEN}L'annotation @MainActor est déjà présente.${NC}"
    else
        # Ajouter @MainActor avant la déclaration de classe
        sed -i '' 's/public final class UnifiedStudyService/@MainActor\npublic final class UnifiedStudyService/' "$FILE_PATH"
        echo -e "${GREEN}Annotation @MainActor ajoutée à la classe.${NC}"
    fi
}

# Fonction pour corriger les closures sans [weak self]
add_weak_self() {
    echo -e "${BLUE}Correction des closures sans [weak self]...${NC}"
    
    # Motifs courants où [weak self] devrait être utilisé
    patterns=(
        "Task {" 
        "DispatchQueue.main.async {"
        "context.perform {"
        "context.performAndWait {"
    )
    
    for pattern in "${patterns[@]}"; do
        # Compter les occurrences du motif
        count=$(grep -c "$pattern" "$FILE_PATH")
        
        if [ "$count" -gt 0 ]; then
            echo -e "${YELLOW}Trouvé $count occurrences de '$pattern' sans [weak self].${NC}"
            
            # Remplacer les closures sans [weak self]
            sed -i '' "s/$pattern/$pattern @MainActor [weak self] in\n            guard let self = self else { return }/" "$FILE_PATH"
            
            echo -e "${GREEN}Closures corrigées avec [weak self].${NC}"
        fi
    done
}

# Fonction pour corriger les références à fetchRequest non définies
fix_fetch_request_references() {
    echo -e "${BLUE}Correction des références à fetchRequest non définies...${NC}"
    
    # Remplacer toutes les occurrences incorrectes
    sed -i '' 's/fetchRequest\.fetchBatchSize = 20;//' "$FILE_PATH"
    sed -i '' 's/fetchRequest\.fetchBatchSize = 20//' "$FILE_PATH"
    
    # Ajouter fetchBatchSize aux requêtes appropriées
    sed -i '' 's/\(NSFetchRequest<[^>]*>\)/\1\nfetchRequest.fetchBatchSize = 20;/' "$FILE_PATH"
    
    echo -e "${GREEN}Références à fetchRequest corrigées.${NC}"
}

# Fonction pour ajouter des optimisations aux fetch requests
add_fetch_optimizations() {
    echo -e "${BLUE}Ajout d'optimisations aux fetch requests...${NC}"
    
    # Ajouter fetchLimit et fetchBatchSize aux NSFetchRequest
    sed -i '' 's/\(NSFetchRequest<[^>]*>\)/\1\nfetchRequest.fetchBatchSize = 20; fetchRequest.fetchLimit = 50/' "$FILE_PATH"
    
    echo -e "${GREEN}Optimisations ajoutées aux fetch requests.${NC}"
}

# Fonction pour corriger les qualifications des types
fix_qualified_types() {
    echo -e "${BLUE}Correction des qualifications de types...${NC}"
    
    # Remplacer les références ambiguës
    sed -i '' 's/Core\.Common\.StudyServiceError/StudyServiceError/g' "$FILE_PATH"
    sed -i '' 's/Core\.Common\.ReviewRating/ReviewRating/g' "$FILE_PATH"
    sed -i '' 's/Core\.Models\.Common\.MasteryLevel/MasteryLevel/g' "$FILE_PATH"
    
    # Ajouter les imports corrects au début du fichier
    sed -i '' '2i\
import Core
' "$FILE_PATH"
    
    echo -e "${GREEN}Qualifications de types corrigées.${NC}"
}

# Fonction pour ajouter des blocs try-catch autour des context.save()
add_try_catch() {
    echo -e "${BLUE}Ajout de try-catch autour des operations CoreData...${NC}"
    
    # Remplacer les appels context.save() sans gestion d'erreur
    sed -i '' 's/try context\.save()/do {\n                try context.save()\n                logger.log("Contexte sauvegardé avec succès")\n            } catch {\n                logger.error("Erreur lors de la sauvegarde du contexte: \\(error)")\n                throw error\n            }/g' "$FILE_PATH"
    
    echo -e "${GREEN}Blocs try-catch ajoutés.${NC}"
}

# Fonction pour réparer les paramètres avec qualifications incorrectes
fix_parameter_names() {
    echo -e "${BLUE}Correction des noms de paramètres qualifiés incorrectement...${NC}"
    
    # Remplacer les noms de paramètres incorrects
    sed -i '' 's/newCore\.Models\.Common\.MasteryLevel/newMasteryLevel/g' "$FILE_PATH"
    sed -i '' 's/calculateNewCore\.Models\.Common\.MasteryLevel/calculateNewMasteryLevel/g' "$FILE_PATH"
    
    echo -e "${GREEN}Noms de paramètres corrigés.${NC}"
}

# Fonction pour corriger la syntaxe de Task
fix_task_syntax() {
    echo -e "${BLUE}Correction de la syntaxe des Task...${NC}"
    
    # Corriger la syntaxe incorrecte de Task
    sed -i '' 's/Task {/Task { @MainActor [weak self] in\n        guard let self = self else { return }/g' "$FILE_PATH"
    
    echo -e "${GREEN}Syntaxe des Task corrigée.${NC}"
}

# Fonction pour corriger les structures Sendable
fix_sendable_structures() {
    echo -e "${BLUE}Ajout des structures Sendable manquantes...${NC}"
    
    # Ajouter la définition des structures SendableReviewData et autres si nécessaires
    if ! grep -q "struct SendableReviewData" "$FILE_PATH"; then
        echo "
// MARK: - Structures Sendable pour le passage de données entre acteurs

/// Structure Sendable pour les données de révision
private struct SendableReviewData: Sendable {
    let timestamp: Date
    let rating: ReviewRating
    let responseTime: Double
}

/// Structure Sendable pour les données de carte
private struct SendableCardData: Sendable {
    let id: UUID
    let masteryLevel: Int16
    let nextReviewDate: Date?
    let reviews: [SendableReviewData]
}

/// Structure Sendable pour les données de révision de carte
private struct SendableCardReviewData: Sendable {
    let id: UUID?
    let cardID: UUID
    let sessionID: UUID?
    let timestamp: Date
    let rating: ReviewRating
    let responseTime: Double
    let newInterval: Int16
    let newEase: Double
    let newMasteryLevel: Int16
}

/// Structure Sendable pour les données de session
private struct SendableSessionData: Sendable {
    let id: UUID?
    let deckID: UUID?
    let startTime: Date
    let endTime: Date?
    let reviews: [SendableSessionReviewData]
}

/// Structure Sendable pour les données de révision de session
private struct SendableSessionReviewData: Sendable {
    let cardID: UUID?
    let timestamp: Date
    let rating: ReviewRating
    let responseTime: Double
}
" >> "$FILE_PATH"
        
        echo -e "${GREEN}Structures Sendable ajoutées.${NC}"
    else
        echo -e "${YELLOW}Structures Sendable déjà présentes.${NC}"
    fi
}

# Fonction principale d'exécution
main() {
    echo -e "${BLUE}Démarrage des corrections pour $FILE_PATH...${NC}"
    
    # Appliquer toutes les corrections
    add_main_actor
    fix_qualified_types
    add_weak_self
    fix_fetch_request_references
    add_fetch_optimizations
    add_try_catch
    fix_parameter_names
    fix_task_syntax
    fix_sendable_structures
    
    echo -e "${GREEN}Corrections terminées.${NC}"
    echo -e "${YELLOW}Note: Certaines corrections peuvent nécessiter des ajustements manuels supplémentaires.${NC}"
    echo -e "${YELLOW}La version originale du fichier a été sauvegardée dans $BACKUP_DIR/UnifiedStudyService.swift${NC}"
}

# Exécution du script
main 