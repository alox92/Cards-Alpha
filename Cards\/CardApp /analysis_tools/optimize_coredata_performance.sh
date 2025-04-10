#!/bin/bash

# Couleurs pour la sortie
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Dossier pour les backups
BACKUP_DIR="backups_coredata_perf_$(date +'%Y%m%d_%H%M%S')"
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}=== Script d'optimisation des performances CoreData ===${NC}"
echo -e "${BLUE}Dossier de backups créé: $BACKUP_DIR${NC}"

# Compteurs
FETCH_REQUESTS_OPTIMIZED=0
BATCHING_ADDED=0
INDEXES_ADDED=0
PREFETCH_ADDED=0
ASYNC_OPTIMIZED=0

# Vérifier les fichiers sans fetchBatchSize
echo -e "${BLUE}Recherche des NSFetchRequest sans fetchBatchSize...${NC}"
FILES_WITHOUT_BATCH_SIZE=$(grep -l "NSFetchRequest<.*>(entityName:" --include="*.swift" . | xargs grep -L "fetchBatchSize")

if [ -n "$FILES_WITHOUT_BATCH_SIZE" ]; then
    echo -e "${YELLOW}Fichiers contenant des NSFetchRequest sans fetchBatchSize:${NC}"
    echo "$FILES_WITHOUT_BATCH_SIZE"
    
    for file in $FILES_WITHOUT_BATCH_SIZE; do
        echo -e "${BLUE}Ajout de fetchBatchSize dans $file...${NC}"
        cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
        
        # Ajouter fetchBatchSize après la ligne avec NSFetchRequest
        sed -i '' '/NSFetchRequest<.*>(entityName:/a\'$'\n''        fetchRequest.fetchBatchSize = 20;' "$file"
        
        echo -e "${GREEN}✓ fetchBatchSize ajouté dans $file${NC}"
        BATCHING_ADDED=$((BATCHING_ADDED + 1))
    done
else
    echo -e "${GREEN}Tous les NSFetchRequest semblent déjà utiliser fetchBatchSize.${NC}"
fi

# Vérifier les modèles CoreData pour ajouter des index
echo -e "${BLUE}Analyse des modèles CoreData pour ajouter des index...${NC}"

CARDAPP_MODEL="Core/Persistence/CardApp.xcdatamodeld/CardApp.xcdatamodel/contents"
if [ -f "$CARDAPP_MODEL" ]; then
    echo -e "${BLUE}Vérification des index dans $CARDAPP_MODEL...${NC}"
    cp "$CARDAPP_MODEL" "$BACKUP_DIR/$(basename "$CARDAPP_MODEL").bak"
    
    # Ajouter des index pour les attributs couramment utilisés dans les prédicats
    COMMON_PREDICATE_ATTRIBUTES=("id" "createdAt" "updatedAt" "name" "isArchived" "isFlagged")
    
    for attr in "${COMMON_PREDICATE_ATTRIBUTES[@]}"; do
        # Vérifier si l'attribut existe mais n'est pas indexé
        if grep -q "<attribute name=\"$attr\"" "$CARDAPP_MODEL" && ! grep -q "<attribute name=\"$attr\".*indexed=\"YES\"" "$CARDAPP_MODEL"; then
            echo -e "${YELLOW}Ajout d'un index pour l'attribut $attr...${NC}"
            
            # Ajouter indexed="YES" à l'attribut
            sed -i '' "s/<attribute name=\"$attr\"/<attribute name=\"$attr\" indexed=\"YES\"/" "$CARDAPP_MODEL"
            
            echo -e "${GREEN}✓ Index ajouté pour l'attribut $attr${NC}"
            INDEXES_ADDED=$((INDEXES_ADDED + 1))
        fi
    done
    
    # Vérifier si les fetch requests ont des index composites
    if ! grep -q "<fetchIndex name=" "$CARDAPP_MODEL"; then
        echo -e "${YELLOW}Ajout d'index composites pour les entités principales...${NC}"
        
        # Ajouter des index composites juste avant la balise de fermeture </model>
        cat >> "$CARDAPP_MODEL" << 'EOF'
    <fetchIndex name="byNameAndCreatedAt">
        <fetchIndexElement property="name" type="Binary" order="ascending"/>
        <fetchIndexElement property="createdAt" type="Binary" order="descending"/>
    </fetchIndex>
    <fetchIndex name="byUpdatedAt">
        <fetchIndexElement property="updatedAt" type="Binary" order="descending"/>
    </fetchIndex>
    <fetchIndex name="byFlags">
        <fetchIndexElement property="isFlagged" type="Binary" order="ascending"/>
        <fetchIndexElement property="isArchived" type="Binary" order="ascending"/>
    </fetchIndex>
EOF
        
        echo -e "${GREEN}✓ Index composites ajoutés au modèle${NC}"
        INDEXES_ADDED=$((INDEXES_ADDED + 3))
    fi
else
    echo -e "${RED}Modèle CoreData non trouvé: $CARDAPP_MODEL${NC}"
fi

# Optimiser les opérations asynchrones avec CoreData
echo -e "${BLUE}Recherche des opérations CoreData synchrones sur le thread principal...${NC}"
FILES_WITH_MAIN_THREAD_COREDATA=$(grep -l "viewContext.*\.save()" --include="*.swift" .)

if [ -n "$FILES_WITH_MAIN_THREAD_COREDATA" ]; then
    echo -e "${YELLOW}Fichiers avec des opérations CoreData sur le thread principal:${NC}"
    echo "$FILES_WITH_MAIN_THREAD_COREDATA"
    
    for file in $FILES_WITH_MAIN_THREAD_COREDATA; do
        echo -e "${BLUE}Optimisation des opérations CoreData dans $file...${NC}"
        cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
        
        # Remplacer les opérations synchrones par des opérations asynchrones
        sed -i '' 's/viewContext\.save()/perform { viewContext.save() }/g' "$file"
        
        echo -e "${GREEN}✓ Opérations CoreData optimisées dans $file${NC}"
        ASYNC_OPTIMIZED=$((ASYNC_OPTIMIZED + 1))
    done
else
    echo -e "${GREEN}Aucune opération CoreData synchrone sur le thread principal détectée.${NC}"
fi

# Ajouter le prefetching des relations
echo -e "${BLUE}Recherche d'opportunités pour le prefetching des relations...${NC}"
FILES_WITH_RELATIONSHIPS=$(grep -l "relationship" "$CARDAPP_MODEL" | head -1)

if [ -n "$FILES_WITH_RELATIONSHIPS" ]; then
    echo -e "${YELLOW}Le modèle contient des relations qui pourraient bénéficier du prefetching.${NC}"
    
    # Chercher les fichiers avec des fetchRequest qui pourraient bénéficier du prefetching
    FILES_FOR_PREFETCH=$(grep -l "NSFetchRequest<" --include="*.swift" . | xargs grep -l "deck\|tags\|reviews\|cards")
    
    if [ -n "$FILES_FOR_PREFETCH" ]; then
        echo -e "${YELLOW}Fichiers où le prefetching pourrait être ajouté:${NC}"
        echo "$FILES_FOR_PREFETCH"
        
        for file in $FILES_FOR_PREFETCH; do
            echo -e "${BLUE}Ajout de relationshipKeyPathsForPrefetching dans $file...${NC}"
            cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
            
            # Chercher les relations à précharger dans ce fichier
            if grep -q "deck" "$file"; then
                sed -i '' '/fetchRequest\.fetchBatchSize/a\'$'\n''        fetchRequest.relationshipKeyPathsForPrefetching = ["deck"]' "$file"
                echo -e "${GREEN}✓ Prefetching ajouté pour la relation 'deck' dans $file${NC}"
                PREFETCH_ADDED=$((PREFETCH_ADDED + 1))
            elif grep -q "tags" "$file"; then
                sed -i '' '/fetchRequest\.fetchBatchSize/a\'$'\n''        fetchRequest.relationshipKeyPathsForPrefetching = ["tags"]' "$file"
                echo -e "${GREEN}✓ Prefetching ajouté pour la relation 'tags' dans $file${NC}"
                PREFETCH_ADDED=$((PREFETCH_ADDED + 1))
            elif grep -q "reviews" "$file"; then
                sed -i '' '/fetchRequest\.fetchBatchSize/a\'$'\n''        fetchRequest.relationshipKeyPathsForPrefetching = ["reviews"]' "$file"
                echo -e "${GREEN}✓ Prefetching ajouté pour la relation 'reviews' dans $file${NC}"
                PREFETCH_ADDED=$((PREFETCH_ADDED + 1))
            elif grep -q "cards" "$file"; then
                sed -i '' '/fetchRequest\.fetchBatchSize/a\'$'\n''        fetchRequest.relationshipKeyPathsForPrefetching = ["cards"]' "$file"
                echo -e "${GREEN}✓ Prefetching ajouté pour la relation 'cards' dans $file${NC}"
                PREFETCH_ADDED=$((PREFETCH_ADDED + 1))
            fi
        done
    else
        echo -e "${GREEN}Aucun fichier trouvé nécessitant le prefetching des relations.${NC}"
    fi
else
    echo -e "${GREEN}Aucune relation trouvée dans le modèle CoreData.${NC}"
fi

# Création d'une documentation sur les optimisations
OPTIMIZATION_DOC="docs/OPTIMISATIONS_COREDATA.md"
mkdir -p docs

cat > "$OPTIMIZATION_DOC" << EOF
# Optimisations CoreData pour CardApp

## Optimisations appliquées

### 1. Pagination avec fetchBatchSize
La pagination des résultats avec \`fetchBatchSize\` a été ajoutée à $BATCHING_ADDED requêtes, ce qui permet de:
- Réduire la consommation mémoire
- Améliorer les performances lors du défilement dans les listes
- Accélérer le chargement initial des vues

### 2. Indexation optimisée
$INDEXES_ADDED nouveaux index ont été ajoutés au modèle CoreData, permettant:
- Des recherches plus rapides sur les attributs communs
- Des tris optimisés
- Des filtres plus performants

### 3. Prefetching des relations
$PREFETCH_ADDED relations sont maintenant préchargées avec \`relationshipKeyPathsForPrefetching\`, offrant:
- Une réduction significative du nombre de requêtes à la base de données
- Un chargement plus rapide des détails
- Une meilleure expérience utilisateur lors de la navigation

### 4. Opérations asynchrones
$ASYNC_OPTIMIZED opérations CoreData ont été optimisées pour s'exécuter de manière asynchrone, ce qui:
- Réduit les blocages de l'interface utilisateur
- Améliore la réactivité de l'application
- Évite les ANRs (Application Not Responding)

## Bonnes pratiques pour CoreData

- **Utiliser fetchBatchSize**: Toujours définir \`fetchBatchSize\` pour les requêtes qui peuvent retourner de nombreux résultats
- **Précharger les relations**: Utiliser \`relationshipKeyPathsForPrefetching\` pour les relations fréquemment accédées
- **Indexer stratégiquement**: Indexer les attributs utilisés dans les prédicats et les tris, mais pas tous les attributs
- **Opérations asynchrones**: Effectuer les opérations CoreData en arrière-plan avec \`perform\` ou \`performAndWait\`
- **NSFetchedResultsController**: Utiliser pour les tableaux et collections qui affichent des données CoreData

## Tests de performance

Pour valider les optimisations, effectuez les tests suivants:
1. Mesurer le temps de chargement initial des listes principales
2. Vérifier la fluidité du défilement avec de grands ensembles de données
3. Monitorer l'utilisation mémoire pendant l'utilisation intensive
4. Tester la réactivité de l'UI pendant les opérations de sauvegarde

## Recommandations futures

- Implémenter un système de cache pour les entités fréquemment accédées
- Considérer l'utilisation de \`NSBatchDeleteRequest\` et \`NSBatchUpdateRequest\` pour les opérations massives
- Envisager une stratégie de migration légère pour les futures mises à jour du modèle
- Implémenter un monitoring en temps réel des performances CoreData

EOF

echo -e "${GREEN}✓ Documentation sur les optimisations créée: $OPTIMIZATION_DOC${NC}"

echo -e "${BLUE}=== Résumé des optimisations CoreData ===${NC}"
echo -e "${GREEN}✓ $BATCHING_ADDED requêtes optimisées avec fetchBatchSize${NC}"
echo -e "${GREEN}✓ $INDEXES_ADDED index ajoutés au modèle CoreData${NC}"
echo -e "${GREEN}✓ $PREFETCH_ADDED relations configurées pour le prefetching${NC}"
echo -e "${GREEN}✓ $ASYNC_OPTIMIZED opérations rendues asynchrones${NC}"
echo -e "${YELLOW}Assurez-vous de recompiler le projet pour vérifier que tout fonctionne correctement.${NC}" 