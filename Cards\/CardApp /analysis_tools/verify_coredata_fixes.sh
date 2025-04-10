#!/bin/bash

# Couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPORT_DIR="reports/coredata_verification_$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$REPORT_DIR/verification_report.md"
UNIFIED_MODEL_NAME="CardApp"

# Création du répertoire de rapport
mkdir -p "$REPORT_DIR"
echo -e "${GREEN}Répertoire de rapport créé: $REPORT_DIR${NC}"

# Fonction pour vérifier si un motif existe dans un fichier
check_pattern() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    local severity="$4" # critical, warning, info
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ Fichier non trouvé: $file${NC}"
        echo "## ✗ Fichier non trouvé: $file" >> "$REPORT_FILE"
        return 1
    fi
    
    if grep -q "$pattern" "$file"; then
        case "$severity" in
            "critical")
                echo -e "${RED}✗ $description dans $file${NC}"
                echo "## ✗ $description" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo "**Fichier:** $file" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo "**Problème critique:**" >> "$REPORT_FILE"
                echo '```swift' >> "$REPORT_FILE"
                grep -n "$pattern" "$file" | head -5 >> "$REPORT_FILE"
                echo '```' >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                ;;
            "warning")
                echo -e "${YELLOW}⚠️ $description dans $file${NC}"
                echo "## ⚠️ $description" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo "**Fichier:** $file" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo "**Avertissement:**" >> "$REPORT_FILE"
                echo '```swift' >> "$REPORT_FILE"
                grep -n "$pattern" "$file" | head -5 >> "$REPORT_FILE"
                echo '```' >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                ;;
            "info")
                echo -e "${BLUE}ℹ️ $description dans $file${NC}"
                ;;
        esac
        return 0
    else
        echo -e "${GREEN}✓ $description non trouvé dans $file (OK)${NC}"
        return 1
    fi
}

# Fonction pour vérifier les modèles CoreData
verify_coredata_models() {
    echo -e "\n${BLUE}=== Vérification des modèles CoreData ===${NC}"
    echo "# Vérification des modèles CoreData" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Vérifier que le modèle unifié est utilisé dans PersistenceController
    check_pattern "Core/Persistence/PersistenceController.swift" "container = NSPersistentContainer(name: \"$UNIFIED_MODEL_NAME\")" "Modèle unifié $UNIFIED_MODEL_NAME utilisé dans PersistenceController" "info"
    
    # Vérifier s'il y a des références aux anciens modèles
    for old_model in "Core" "Cards" "Stub"; do
        if [ "$old_model" != "$UNIFIED_MODEL_NAME" ]; then
            if grep -r --include="*.swift" "NSPersistentContainer(name: \"$old_model\")" . | grep -v "BACKUP"; then
                echo -e "${RED}✗ Référence à l'ancien modèle $old_model trouvée${NC}"
                echo "## ✗ Référence à l'ancien modèle $old_model trouvée" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo "**Fichiers concernés:**" >> "$REPORT_FILE"
                echo '```' >> "$REPORT_FILE"
                grep -r --include="*.swift" "NSPersistentContainer(name: \"$old_model\")" . | grep -v "BACKUP" >> "$REPORT_FILE"
                echo '```' >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
            else
                echo -e "${GREEN}✓ Aucune référence à l'ancien modèle $old_model trouvée (OK)${NC}"
            fi
        fi
    done
}

# Fonction pour vérifier les optimisations de fetchRequest
verify_fetch_optimizations() {
    echo -e "\n${BLUE}=== Vérification des optimisations de fetchRequest ===${NC}"
    echo "# Vérification des optimisations de fetchRequest" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Rechercher les fetchRequest sans fetchBatchSize
    files_with_fetchrequest=$(grep -l --include="*.swift" "NSFetchRequest<" . | grep -v "BACKUP")
    
    if [ -z "$files_with_fetchrequest" ]; then
        echo -e "${YELLOW}⚠️ Aucun fichier contenant des NSFetchRequest trouvé${NC}"
        echo "## ⚠️ Aucun fichier contenant des NSFetchRequest trouvé" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        echo -e "${BLUE}Fichiers contenant des NSFetchRequest:${NC}"
        echo "## Fichiers contenant des NSFetchRequest" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        missing_optimization=false
        
        for file in $files_with_fetchrequest; do
            echo -e "${BLUE}Vérification de $file...${NC}"
            echo "### Vérification de $file" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            
            # Compter le nombre de NSFetchRequest
            fetch_count=$(grep -c "NSFetchRequest<" "$file")
            
            # Compter le nombre de fetchBatchSize
            batch_count=$(grep -c "fetchBatchSize" "$file")
            
            if [ "$batch_count" -lt "$fetch_count" ]; then
                missing_optimization=true
                echo -e "${RED}✗ Le fichier $file contient $fetch_count NSFetchRequest mais seulement $batch_count fetchBatchSize${NC}"
                echo "✗ Le fichier contient $fetch_count NSFetchRequest mais seulement $batch_count fetchBatchSize" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo "**Requêtes sans optimisation:**" >> "$REPORT_FILE"
                echo '```swift' >> "$REPORT_FILE"
                # Extraire les contextes de NSFetchRequest sans fetchBatchSize à proximité
                grep -A 5 "NSFetchRequest<" "$file" | grep -v "fetchBatchSize" | head -10 >> "$REPORT_FILE"
                echo '```' >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
            else
                echo -e "${GREEN}✓ Toutes les fetchRequest dans $file sont optimisées avec fetchBatchSize (OK)${NC}"
                echo "✓ Toutes les fetchRequest sont optimisées avec fetchBatchSize" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
            fi
        done
        
        if [ "$missing_optimization" = false ]; then
            echo -e "${GREEN}✓ Toutes les fetchRequest du projet sont optimisées avec fetchBatchSize (OK)${NC}"
            echo "## ✓ Toutes les fetchRequest du projet sont optimisées avec fetchBatchSize" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    fi
}

# Fonction pour vérifier l'utilisation de @MainActor
verify_main_actor() {
    echo -e "\n${BLUE}=== Vérification de l'utilisation de @MainActor ===${NC}"
    echo "# Vérification de l'utilisation de @MainActor" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Rechercher les classes qui manipulent CoreData sans @MainActor
    files_with_coredata=$(grep -l --include="*.swift" "import CoreData" . | grep -v "BACKUP")
    
    if [ -z "$files_with_coredata" ]; then
        echo -e "${YELLOW}⚠️ Aucun fichier important CoreData trouvé${NC}"
        echo "## ⚠️ Aucun fichier important CoreData trouvé" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        echo -e "${BLUE}Fichiers important CoreData:${NC}"
        echo "## Fichiers important CoreData" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        missing_mainactor=false
        
        for file in $files_with_coredata; do
            echo -e "${BLUE}Vérification de $file...${NC}"
            echo "### Vérification de $file" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            
            # Ignorer certains fichiers où @MainActor n'est pas nécessaire
            if [[ "$file" == *"Entity+CoreDataClass.swift"* ]] || [[ "$file" == *"Entity+CoreDataProperties.swift"* ]]; then
                echo -e "${BLUE}Fichier d'entité CoreData, @MainActor non nécessaire${NC}"
                echo "Fichier d'entité CoreData, @MainActor non nécessaire" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                continue
            fi
            
            # Vérifier si le fichier contient des classes
            if grep -q "class " "$file"; then
                # Vérifier si ces classes ont @MainActor
                if grep -q "class " "$file" && ! grep -q "@MainActor" "$file"; then
                    missing_mainactor=true
                    echo -e "${RED}✗ Le fichier $file contient des classes sans annotation @MainActor${NC}"
                    echo "✗ Le fichier contient des classes sans annotation @MainActor" >> "$REPORT_FILE"
                    echo "" >> "$REPORT_FILE"
                    echo "**Classes sans @MainActor:**" >> "$REPORT_FILE"
                    echo '```swift' >> "$REPORT_FILE"
                    grep -n "class " "$file" | head -5 >> "$REPORT_FILE"
                    echo '```' >> "$REPORT_FILE"
                    echo "" >> "$REPORT_FILE"
                else
                    echo -e "${GREEN}✓ Toutes les classes dans $file sont annotées avec @MainActor (OK)${NC}"
                    echo "✓ Toutes les classes sont annotées avec @MainActor" >> "$REPORT_FILE"
                    echo "" >> "$REPORT_FILE"
                fi
            else
                echo -e "${BLUE}Aucune classe trouvée dans $file${NC}"
                echo "Aucune classe trouvée dans ce fichier" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
            fi
        done
        
        if [ "$missing_mainactor" = false ]; then
            echo -e "${GREEN}✓ Toutes les classes manipulant CoreData sont annotées avec @MainActor (OK)${NC}"
            echo "## ✓ Toutes les classes manipulant CoreData sont annotées avec @MainActor" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    fi
}

# Fonction pour vérifier l'utilisation de [weak self] dans Task et closures
verify_weak_self() {
    echo -e "\n${BLUE}=== Vérification de l'utilisation de [weak self] ===${NC}"
    echo "# Vérification de l'utilisation de [weak self]" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Rechercher Task sans [weak self]
    files_with_task=$(grep -l --include="*.swift" "Task {" . | grep -v "BACKUP")
    
    if [ -z "$files_with_task" ]; then
        echo -e "${YELLOW}⚠️ Aucun fichier contenant Task trouvé${NC}"
        echo "## ⚠️ Aucun fichier contenant Task trouvé" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        echo -e "${BLUE}Fichiers contenant Task:${NC}"
        echo "## Fichiers contenant Task" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        missing_weakself=false
        
        for file in $files_with_task; do
            echo -e "${BLUE}Vérification de $file...${NC}"
            echo "### Vérification de $file" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            
            # Vérifier s'il y a des Task sans [weak self]
            if grep -q "Task {" "$file" && ! grep -q "Task { @MainActor \[weak self\]" "$file"; then
                missing_weakself=true
                echo -e "${RED}✗ Le fichier $file contient des Task sans [weak self]${NC}"
                echo "✗ Le fichier contient des Task sans [weak self]" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo "**Task sans [weak self]:**" >> "$REPORT_FILE"
                echo '```swift' >> "$REPORT_FILE"
                grep -n -A 3 "Task {" "$file" | grep -v "\[weak self\]" | head -5 >> "$REPORT_FILE"
                echo '```' >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
            else
                echo -e "${GREEN}✓ Toutes les Task dans $file utilisent [weak self] (OK)${NC}"
                echo "✓ Toutes les Task utilisent [weak self]" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
            fi
        done
        
        # Rechercher des closures DispatchQueue sans [weak self]
        files_with_dispatch=$(grep -l --include="*.swift" "DispatchQueue" . | grep -v "BACKUP")
        
        if [ -n "$files_with_dispatch" ]; then
            echo -e "${BLUE}Fichiers contenant DispatchQueue:${NC}"
            echo "## Fichiers contenant DispatchQueue" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            
            for file in $files_with_dispatch; do
                echo -e "${BLUE}Vérification de $file...${NC}"
                echo "### Vérification de $file" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                
                # Vérifier s'il y a des DispatchQueue sans [weak self]
                if grep -q "DispatchQueue.*\.async {" "$file" && ! grep -q "DispatchQueue.*\.async { \[weak self\]" "$file"; then
                    missing_weakself=true
                    echo -e "${RED}✗ Le fichier $file contient des DispatchQueue sans [weak self]${NC}"
                    echo "✗ Le fichier contient des DispatchQueue sans [weak self]" >> "$REPORT_FILE"
                    echo "" >> "$REPORT_FILE"
                    echo "**DispatchQueue sans [weak self]:**" >> "$REPORT_FILE"
                    echo '```swift' >> "$REPORT_FILE"
                    grep -n -A 3 "DispatchQueue.*\.async {" "$file" | grep -v "\[weak self\]" | head -5 >> "$REPORT_FILE"
                    echo '```' >> "$REPORT_FILE"
                    echo "" >> "$REPORT_FILE"
                else
                    echo -e "${GREEN}✓ Toutes les DispatchQueue dans $file utilisent [weak self] (OK)${NC}"
                    echo "✓ Toutes les DispatchQueue utilisent [weak self]" >> "$REPORT_FILE"
                    echo "" >> "$REPORT_FILE"
                fi
            done
        fi
        
        if [ "$missing_weakself" = false ]; then
            echo -e "${GREEN}✓ Toutes les closures asynchrones utilisent [weak self] (OK)${NC}"
            echo "## ✓ Toutes les closures asynchrones utilisent [weak self]" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    fi
}

# Fonction pour vérifier la gestion des erreurs CoreData
verify_error_handling() {
    echo -e "\n${BLUE}=== Vérification de la gestion des erreurs CoreData ===${NC}"
    echo "# Vérification de la gestion des erreurs CoreData" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Rechercher context.save() sans try
    files_with_save=$(grep -l --include="*.swift" "context\.save()" . | grep -v "BACKUP")
    
    if [ -z "$files_with_save" ]; then
        echo -e "${YELLOW}⚠️ Aucun fichier contenant context.save() trouvé${NC}"
        echo "## ⚠️ Aucun fichier contenant context.save() trouvé" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        echo -e "${BLUE}Fichiers contenant context.save():${NC}"
        echo "## Fichiers contenant context.save()" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        missing_try=false
        
        for file in $files_with_save; do
            echo -e "${BLUE}Vérification de $file...${NC}"
            echo "### Vérification de $file" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            
            # Vérifier s'il y a des context.save() sans try
            if grep -q "context\.save()" "$file" && ! grep -q "try context\.save()" "$file"; then
                missing_try=true
                echo -e "${RED}✗ Le fichier $file contient des context.save() sans try${NC}"
                echo "✗ Le fichier contient des context.save() sans try" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo "**context.save() sans try:**" >> "$REPORT_FILE"
                echo '```swift' >> "$REPORT_FILE"
                grep -n -A 3 -B 3 "context\.save()" "$file" | grep -v "try context\.save()" | head -5 >> "$REPORT_FILE"
                echo '```' >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
            else
                echo -e "${GREEN}✓ Toutes les context.save() dans $file utilisent try (OK)${NC}"
                echo "✓ Toutes les context.save() utilisent try" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
            fi
        done
        
        if [ "$missing_try" = false ]; then
            echo -e "${GREEN}✓ Toutes les opérations context.save() utilisent try (OK)${NC}"
            echo "## ✓ Toutes les opérations context.save() utilisent try" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    fi
}

# Fonction pour vérifier les conversions entre entités et modèles
verify_entity_conversions() {
    echo -e "\n${BLUE}=== Vérification des conversions entre entités et modèles ===${NC}"
    echo "# Vérification des conversions entre entités et modèles" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Rechercher les références qualifiées problématiques
    patterns=("Core\.Models\.Common\.MasteryLevel" "Core\.Models\.Common\.ReviewRating" "Core\.Common\.StudyServiceError" "newCore\.Models\.Common\.MasteryLevel" "calculateNewCore\.Models\.Common\.MasteryLevel")
    
    for pattern in "${patterns[@]}"; do
        echo -e "${BLUE}Recherche de références qualifiées: $pattern${NC}"
        echo "## Recherche de références qualifiées: $pattern" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        if grep -r --include="*.swift" "$pattern" . | grep -v "BACKUP"; then
            echo -e "${RED}✗ Références qualifiées problématiques trouvées: $pattern${NC}"
            echo "✗ Références qualifiées problématiques trouvées" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            echo "**Fichiers concernés:**" >> "$REPORT_FILE"
            echo '```' >> "$REPORT_FILE"
            grep -r --include="*.swift" "$pattern" . | grep -v "BACKUP" >> "$REPORT_FILE"
            echo '```' >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        else
            echo -e "${GREEN}✓ Aucune référence qualifiée problématique trouvée: $pattern (OK)${NC}"
            echo "✓ Aucune référence qualifiée problématique trouvée" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    done
}

# Générer une conclusion pour le rapport
generate_conclusion() {
    echo -e "\n${BLUE}=== Génération de la conclusion du rapport ===${NC}"
    
    # Compter les problèmes par catégorie
    critical_count=$(grep -c "✗" "$REPORT_FILE")
    warning_count=$(grep -c "⚠️" "$REPORT_FILE")
    success_count=$(grep -c "✓" "$REPORT_FILE")
    
    echo "# Conclusion" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "## Résumé des vérifications" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "- **Problèmes critiques:** $critical_count" >> "$REPORT_FILE"
    echo "- **Avertissements:** $warning_count" >> "$REPORT_FILE"
    echo "- **Vérifications réussies:** $success_count" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    if [ "$critical_count" -gt 0 ]; then
        echo "## ⚠️ Actions recommandées" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "Des problèmes critiques ont été détectés. Il est recommandé de:" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "1. Exécuter à nouveau les scripts de correction:" >> "$REPORT_FILE"
        echo "   - `./analysis_tools/fix_coredata_models.sh`" >> "$REPORT_FILE"
        echo "   - `./analysis_tools/fix_coredata_conversions.sh`" >> "$REPORT_FILE"
        echo "2. Vérifier manuellement les fichiers problématiques mentionnés dans ce rapport" >> "$REPORT_FILE"
        echo "3. Relancer cette vérification après avoir effectué les corrections" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        echo "## ✅ Conclusion" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "Toutes les vérifications critiques ont été passées avec succès. Le projet semble avoir correctement appliqué les corrections CoreData." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "### Recommandations" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "Pour maintenir la qualité du code:" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "1. Continuer à suivre les bonnes pratiques documentées dans `docs/GUIDE_COREDATA.md`" >> "$REPORT_FILE"
        echo "2. Exécuter régulièrement cette vérification pour s'assurer que les nouvelles modifications respectent les standards" >> "$REPORT_FILE"
        echo "3. Former les nouveaux membres de l'équipe aux bonnes pratiques CoreData identifiées" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
    
    echo "Rapport généré le $(date)" >> "$REPORT_FILE"
    
    echo -e "${GREEN}Rapport de vérification complet généré: $REPORT_FILE${NC}"
}

# Fonction principale
main() {
    echo -e "${BLUE}=== Démarrage de la vérification des corrections CoreData ===${NC}"
    
    # Initialisation du rapport
    echo "# Rapport de vérification des corrections CoreData" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "Date: $(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Exécution des vérifications
    verify_coredata_models
    verify_fetch_optimizations
    verify_main_actor
    verify_weak_self
    verify_error_handling
    verify_entity_conversions
    
    # Génération de la conclusion
    generate_conclusion
    
    echo -e "\n${GREEN}=== Vérification des corrections CoreData terminée ===${NC}"
    echo -e "${YELLOW}Consultez le rapport complet: $REPORT_FILE${NC}"
}

# Exécution du script
main 