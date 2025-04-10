#!/bin/bash

# Script pour corriger les ambiguïtés de types dans le projet CardApp
# Auteur: Claude Agent
# Date: $(date +%d/%m/%Y)

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher un message d'information
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Fonction pour afficher un message de succès
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Fonction pour afficher un avertissement
warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Fonction pour afficher une erreur
error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Créer un répertoire de backup
BACKUP_DIR="backups_ambiguities_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
info "Répertoire de sauvegarde créé: $BACKUP_DIR"

# Problème 1: Ambiguïté ReviewRating
info "Résolution des ambiguïtés pour ReviewRating..."
if [ -f "Core/Protocols/CardSchedulerProtocolV2.swift" ]; then
    cp "Core/Protocols/CardSchedulerProtocolV2.swift" "$BACKUP_DIR/"
    
    # Remplacer l'enum ReviewRating par une référence au type complet
    sed -i '' 's/public enum ReviewRating: Int, Sendable { case again, hard, good, easy }/\/\/ Type déplacé vers Core\/Common\/Types.swift pour éviter les ambiguïtés/g' "Core/Protocols/CardSchedulerProtocolV2.swift"
    
    success "CardSchedulerProtocolV2.swift modifié pour supprimer la déclaration dupliquée de ReviewRating"
else
    warning "Fichier CardSchedulerProtocolV2.swift non trouvé"
fi

# Problème 2: Ambiguïté MasteryLevel
info "Résolution des ambiguïtés pour MasteryLevel..."
if [ -f "Core/Protocols/CardSchedulerProtocolV2.swift" ]; then
    # Remplacer l'enum MasteryLevel par une référence au type complet
    sed -i '' 's/public enum MasteryLevel: Int, Sendable { case novice, beginner, intermediate, advanced, expert }/\/\/ Type déplacé vers Core\/Models\/Common\/Enums.swift pour éviter les ambiguïtés/g' "Core/Protocols/CardSchedulerProtocolV2.swift"
    
    success "CardSchedulerProtocolV2.swift modifié pour supprimer la déclaration dupliquée de MasteryLevel"
fi

# Problème 3: Ambiguïté PersistenceControllerProtocol
info "Résolution des ambiguïtés pour PersistenceControllerProtocol..."
if [ -f "Core/DI/DependencyContainer.swift" ]; then
    cp "Core/DI/DependencyContainer.swift" "$BACKUP_DIR/"
    
    # Remplacer le protocole par une référence ou le supprimer
    sed -i '' 's/public protocol PersistenceControllerProtocol {}/\/\/ Protocole défini dans Core\/Persistence\/PersistenceController.swift/g' "Core/DI/DependencyContainer.swift"
    
    success "DependencyContainer.swift modifié pour supprimer la déclaration dupliquée de PersistenceControllerProtocol"
else
    warning "Fichier DependencyContainer.swift non trouvé"
fi

# Problème 4: Ambiguïté pour les autres protocoles de service
info "Résolution des ambiguïtés pour les protocoles de service..."
if [ -f "Core/DI/DependencyContainer.swift" ]; then
    # Remplacer les protocoles dupliqués par des références
    sed -i '' 's/public protocol CardServiceProtocol {}/\/\/ Protocole défini dans Core\/Protocols\/Services\/CardServiceProtocol.swift/g' "Core/DI/DependencyContainer.swift"
    sed -i '' 's/public protocol DeckServiceProtocol {}/\/\/ Protocole défini dans Core\/Protocols\/Services\/DeckServiceProtocol.swift/g' "Core/DI/DependencyContainer.swift"
    sed -i '' 's/public protocol StudyServiceProtocol {}/\/\/ Protocole défini dans Core\/Protocols\/StudyServiceProtocol.swift/g' "Core/DI/DependencyContainer.swift"
    sed -i '' 's/public protocol TagServiceProtocol {}/\/\/ Protocole défini dans Core\/Protocols\/Services\/TagServiceProtocol.swift/g' "Core/DI/DependencyContainer.swift"
    sed -i '' 's/public protocol DataManagementServiceProtocol {}/\/\/ Protocole défini dans Core\/Protocols\/DataManagementServiceProtocol.swift/g' "Core/DI/DependencyContainer.swift"
    
    success "DependencyContainer.swift modifié pour supprimer les déclarations dupliquées de protocoles de service"
fi

# Problème 5: Modification des imports pour assurer la bonne résolution des types
info "Ajout des imports manquants..."

# Ajouter import pour StudyService.swift
if [ -f "Core/Services/Study/StudyService.swift" ]; then
    cp "Core/Services/Study/StudyService.swift" "$BACKUP_DIR/"
    
    # Vérifier si l'import est déjà présent
    if ! grep -q "import Core.Common" "Core/Services/Study/StudyService.swift"; then
        # Ajouter l'import après le dernier import
        sed -i '' '/^import/a\'$'\n''import Core.Common' "Core/Services/Study/StudyService.swift"
        success "Import ajouté dans StudyService.swift"
    else
        info "Import déjà présent dans StudyService.swift"
    fi
else
    warning "Fichier StudyService.swift non trouvé"
fi

# Ajouter import pour CardReview.swift
if [ -f "Core/Models/Study/CardReview.swift" ]; then
    cp "Core/Models/Study/CardReview.swift" "$BACKUP_DIR/"
    
    # Vérifier si l'import est déjà présent
    if ! grep -q "import Core.Common" "Core/Models/Study/CardReview.swift"; then
        # Ajouter l'import après le dernier import
        sed -i '' '/^import/a\'$'\n''import Core.Common' "Core/Models/Study/CardReview.swift"
        success "Import ajouté dans CardReview.swift"
    else
        info "Import déjà présent dans CardReview.swift"
    fi
else
    warning "Fichier CardReview.swift non trouvé"
fi

# Ajouter import pour CardScheduler.swift
if [ -f "Core/Services/Unified/CardScheduler.swift" ]; then
    cp "Core/Services/Unified/CardScheduler.swift" "$BACKUP_DIR/"
    
    # Vérifier si l'import est déjà présent
    if ! grep -q "import Core.Common" "Core/Services/Unified/CardScheduler.swift"; then
        # Ajouter l'import après le dernier import
        sed -i '' '/^import/a\'$'\n''import Core.Common' "Core/Services/Unified/CardScheduler.swift"
        success "Import ajouté dans CardScheduler.swift"
    else
        info "Import déjà présent dans CardScheduler.swift"
    fi
    
    # Corriger la redéclaration de CardScheduler si nécessaire
    if grep -q "invalid redeclaration of 'CardScheduler'" "build_verification.log"; then
        # Renommer la classe pour éviter le conflit
        sed -i '' 's/public class CardScheduler:/public class CardSchedulerV2:/g' "Core/Services/Unified/CardScheduler.swift"
        sed -i '' 's/return CardScheduler()/return CardSchedulerV2()/g' "Core/Services/Unified/CardScheduler.swift"
        success "Classe CardScheduler renommée en CardSchedulerV2 pour éviter les conflits"
    fi
else
    warning "Fichier CardScheduler.swift non trouvé"
fi

# Vérifier si CardReviewEntity a besoin de l'import de Core.Common
if [ -f "Core/Models/Data/CardReviewEntity.swift" ]; then
    cp "Core/Models/Data/CardReviewEntity.swift" "$BACKUP_DIR/"
    
    # Vérifier si l'import est déjà présent
    if ! grep -q "import Core.Common" "Core/Models/Data/CardReviewEntity.swift"; then
        # Ajouter l'import après le dernier import
        sed -i '' '/^import/a\'$'\n''import Core.Common' "Core/Models/Data/CardReviewEntity.swift"
        success "Import ajouté dans CardReviewEntity.swift"
    else
        info "Import déjà présent dans CardReviewEntity.swift"
    fi
else
    warning "Fichier CardReviewEntity.swift non trouvé"
fi

success "Correction des ambiguïtés terminée."
echo ""
info "Pour vérifier les corrections, exécutez: ./verify_corrections.sh"
echo ""
warning "IMPORTANT: Certaines corrections peuvent nécessiter des ajustements manuels supplémentaires."
echo ""
info "Les fichiers originaux ont été sauvegardés dans le répertoire: $BACKUP_DIR"

# Rendre le script exécutable
chmod +x verify_corrections.sh 2>/dev/null || true

exit 0 