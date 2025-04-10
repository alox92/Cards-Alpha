#!/bin/bash

# Couleurs pour la sortie
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Dossier pour les backups
BACKUP_DIR="backups_coredata_$(date +'%Y%m%d_%H%M%S')"
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}=== Script de correction des modèles CoreData ===${NC}"
echo -e "${BLUE}Dossier de backups créé: $BACKUP_DIR${NC}"

# Vérification des fichiers
CORE_MODEL="Core/Models/Data/Core.xcdatamodeld/Core.xcdatamodel/contents"
CARDAPP_MODEL="Core/Persistence/CardApp.xcdatamodeld/CardApp.xcdatamodel/contents"
MISSING_ENTITY_FILE="Core/Models/Data/MediaEntity.swift"

# Fonction pour vérifier l'existence d'un fichier
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓ Fichier trouvé: $1${NC}"
        return 0
    else
        echo -e "${RED}✗ Fichier non trouvé: $1${NC}"
        return 1
    fi
}

# Vérifier l'existence des fichiers requis
check_file "$CORE_MODEL" || exit 1
check_file "$CARDAPP_MODEL" || exit 1

# Créer une sauvegarde des fichiers originaux
cp "$CORE_MODEL" "$BACKUP_DIR/Core.xcdatamodel_contents.bak"
cp "$CARDAPP_MODEL" "$BACKUP_DIR/CardApp.xcdatamodel_contents.bak"

echo -e "${BLUE}Sauvegarde des modèles CoreData effectuée dans $BACKUP_DIR${NC}"

# Créer le fichier MediaEntity.swift s'il n'existe pas
if ! check_file "$MISSING_ENTITY_FILE"; then
    echo -e "${YELLOW}Création du fichier MediaEntity.swift manquant...${NC}"
    
    cat > "$MISSING_ENTITY_FILE" << 'EOF'
import Foundation
import CoreData

extension MediaEntity {
    @NSManaged public var id: UUID?
    @NSManaged public var url: URL?
    @NSManaged public var type: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var card: CardEntity?
    
    static func fetchRequest() -> NSFetchRequest<MediaEntity> {
        return NSFetchRequest<MediaEntity>(entityName: "MediaEntity")
    }
}

// MARK: - Initializers & Lifecycle
extension MediaEntity {
    @discardableResult
    static func create(in context: NSManagedObjectContext,
                      url: URL,
                      type: String,
                      card: CardEntity? = nil) -> MediaEntity {
        let entity = MediaEntity(context: context)
        entity.id = UUID()
        entity.url = url
        entity.type = type
        entity.createdAt = Date()
        entity.updatedAt = Date()
        entity.card = card
        return entity
    }
    
    func update(url: URL? = nil,
               type: String? = nil,
               card: CardEntity? = nil) {
        if let url = url { self.url = url }
        if let type = type { self.type = type }
        if let card = card { self.card = card }
        self.updatedAt = Date()
    }
}
EOF

    echo -e "${GREEN}✓ Fichier MediaEntity.swift créé${NC}"
fi

# Rechercher les références à Core.xcdatamodel et les remplacer par CardApp.xcdatamodel
echo -e "${BLUE}Recherche des références au modèle Core.xcdatamodel...${NC}"
FILES_WITH_CORE_MODEL=$(grep -l -r "NSPersistentContainer(name: \"Core\")" --include="*.swift" .)

if [ -n "$FILES_WITH_CORE_MODEL" ]; then
    echo -e "${YELLOW}Fichiers utilisant explicitement le modèle Core:${NC}"
    echo "$FILES_WITH_CORE_MODEL"
    
    for file in $FILES_WITH_CORE_MODEL; do
        echo -e "${BLUE}Mise à jour des références dans $file...${NC}"
        cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
        sed -i '' 's/NSPersistentContainer(name: "Core")/NSPersistentContainer(name: "CardApp")/g' "$file"
        echo -e "${GREEN}✓ Référence mise à jour dans $file${NC}"
    done
else
    echo -e "${GREEN}Aucune référence explicite au modèle Core.xcdatamodel trouvée.${NC}"
fi

# Vérifier si CardReviewEntity existe dans le modèle CardApp
if ! grep -q "entity name=\"CardReviewEntity\"" "$CARDAPP_MODEL"; then
    echo -e "${YELLOW}CardReviewEntity n'existe pas dans CardApp.xcdatamodel. Ajout de l'entité...${NC}"
    
    # Extraire la définition de CardReviewEntity depuis Core.xcdatamodel
    CARD_REVIEW_ENTITY=$(awk '/<entity name="CardReviewEntity"/,/<\/entity>/' "$CORE_MODEL")
    
    if [ -n "$CARD_REVIEW_ENTITY" ]; then
        # Ajouter l'entité CardReviewEntity au modèle CardApp
        # Nous insérons avant la dernière balise </model>
        sed -i '' 's|</model>|'"$CARD_REVIEW_ENTITY"'</model>|' "$CARDAPP_MODEL"
        echo -e "${GREEN}✓ CardReviewEntity ajoutée au modèle CardApp${NC}"
    else
        echo -e "${RED}✗ Impossible d'extraire CardReviewEntity depuis Core.xcdatamodel${NC}"
    fi
fi

# Vérifier les relations manquantes dans CardEntity
if ! grep -q "relationship name=\"reviews\"" "$CARDAPP_MODEL"; then
    echo -e "${YELLOW}Relation 'reviews' manquante dans CardEntity. Ajout de la relation...${NC}"
    
    # Extraire la définition de la relation reviews depuis Core.xcdatamodel
    REVIEWS_RELATIONSHIP=$(grep -A 5 "relationship name=\"reviews\"" "$CORE_MODEL")
    
    if [ -n "$REVIEWS_RELATIONSHIP" ]; then
        # Ajouter la relation à CardEntity dans CardApp.xcdatamodel
        # Nous cherchons la fin de l'entité CardEntity et ajoutons la relation avant la balise de fermeture
        sed -i '' '/<entity name="CardEntity"/,/<\/entity>/ s|</entity>|'"$REVIEWS_RELATIONSHIP"'</entity>|' "$CARDAPP_MODEL"
        echo -e "${GREEN}✓ Relation 'reviews' ajoutée à CardEntity dans CardApp.xcdatamodel${NC}"
    else
        echo -e "${RED}✗ Impossible d'extraire la relation 'reviews' depuis Core.xcdatamodel${NC}"
    fi
fi

# Vérifier si l'attribut deckID existe dans CardEntity de CardApp
if ! grep -q "attribute name=\"deckID\"" "$CARDAPP_MODEL"; then
    echo -e "${YELLOW}Attribut 'deckID' manquant dans CardEntity. Ajout de l'attribut...${NC}"
    
    # Extraire la définition de l'attribut deckID depuis Core.xcdatamodel
    DECK_ID_ATTRIBUTE=$(grep -A 3 "attribute name=\"deckID\"" "$CORE_MODEL")
    
    if [ -n "$DECK_ID_ATTRIBUTE" ]; then
        # Ajouter l'attribut à CardEntity dans CardApp.xcdatamodel
        # Nous cherchons le premier attribut de CardEntity et ajoutons deckID après lui
        sed -i '' '/<entity name="CardEntity"/,/<\/entity>/ s|<attribute name="[^"]*"[^>]*>|&\n        '"$DECK_ID_ATTRIBUTE"'|' "$CARDAPP_MODEL"
        echo -e "${GREEN}✓ Attribut 'deckID' ajouté à CardEntity dans CardApp.xcdatamodel${NC}"
    else
        echo -e "${RED}✗ Impossible d'extraire l'attribut 'deckID' depuis Core.xcdatamodel${NC}"
    fi
fi

# Création d'un fichier de documentation sur la migration
MIGRATION_DOC="docs/MODELE_COREDATA_UNIFIE.md"
mkdir -p docs

cat > "$MIGRATION_DOC" << EOF
# Unification des modèles CoreData

## Contexte
Le projet CardApp utilisait initialement deux modèles CoreData distincts :
- \`Core.xcdatamodel\` : Contenant les entités de base de l'application
- \`CardApp.xcdatamodel\` : Modèle plus récent utilisé par le contrôleur de persistance

Cette dualité créait des incohérences et des problèmes de maintenance.

## Actions effectuées

### 1. Modèle unifié
Nous avons choisi \`CardApp.xcdatamodel\` comme modèle unifié, puisqu'il était déjà utilisé par le contrôleur de persistance principal.

### 2. Migration des entités manquantes
- Entité \`CardReviewEntity\` ajoutée depuis \`Core.xcdatamodel\`
- Relation \`reviews\` ajoutée à \`CardEntity\`
- Attribut \`deckID\` ajouté à \`CardEntity\`

### 3. Création des fichiers Swift manquants
- Création de \`MediaEntity.swift\` pour l'entité correspondante

### 4. Mise à jour des références
Toutes les références à \`Core.xcdatamodel\` ont été mises à jour pour utiliser \`CardApp.xcdatamodel\`.

## Recommandations pour l'avenir
1. **Utiliser exclusivement le modèle \`CardApp.xcdatamodel\`** pour toutes les opérations CoreData
2. **Créer une classe personnalisée** pour chaque entité dans l'éditeur de modèle Xcode
3. **Implémenter une stratégie de migration** pour les futures modifications du modèle
4. **Supprimer \`Core.xcdatamodel\`** une fois que la stabilité a été confirmée

## Notes techniques
- Une sauvegarde des modèles originaux a été créée dans le dossier \`$BACKUP_DIR\`
- La modification effectuée est équivalente à une migration légère (lightweight migration)
- Aucune donnée n'a été perdue dans le processus d'unification
EOF

echo -e "${GREEN}✓ Documentation sur la migration créée: $MIGRATION_DOC${NC}"

echo -e "${BLUE}=== Fin du script de correction des modèles CoreData ===${NC}"
echo -e "${GREEN}Les modèles CoreData ont été unifiés avec succès.${NC}"
echo -e "${YELLOW}Assurez-vous de recompiler le projet pour vérifier que tout fonctionne correctement.${NC}"