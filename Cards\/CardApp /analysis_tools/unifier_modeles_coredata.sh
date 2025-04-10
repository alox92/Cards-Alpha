#!/bin/bash

# Couleurs pour le terminal
RESET="\033[0m"
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"

# Chemins des modèles
CORE_MODEL="./Core/Models/Data/Core.xcdatamodeld/Core.xcdatamodel/contents"
CARDAPP_MODEL="./Core/Persistence/CardApp.xcdatamodeld/CardApp.xcdatamodel/contents"

# Répertoire pour les backups et documentation
BACKUP_DIR="backups_coredata_unification_$(date +%Y%m%d_%H%M%S)"
DOC_DIR="docs"
DOC_FILE="${DOC_DIR}/MODELE_COREDATA_UNIFIE.md"

echo -e "${BOLD}${CYAN}=== UNIFICATION DES MODÈLES COREDATA POUR CARDAPP ===${RESET}\n"

# Vérifier si les deux modèles existent
if [ ! -f "$CORE_MODEL" ]; then
    echo -e "${RED}❌ Le modèle Core.xcdatamodel n'existe pas au chemin spécifié${RESET}"
    exit 1
fi

if [ ! -f "$CARDAPP_MODEL" ]; then
    echo -e "${RED}❌ Le modèle CardApp.xcdatamodel n'existe pas au chemin spécifié${RESET}"
    exit 1
fi

# Créer les répertoires nécessaires
mkdir -p "$BACKUP_DIR"
mkdir -p "$DOC_DIR"

echo -e "${GREEN}✅ Répertoires de backup et documentation créés${RESET}"

# Sauvegarder les fichiers originaux
cp "$CORE_MODEL" "${BACKUP_DIR}/Core.xcdatamodel_original"
cp "$CARDAPP_MODEL" "${BACKUP_DIR}/CardApp.xcdatamodel_original"

echo -e "${GREEN}✅ Modèles originaux sauvegardés dans ${BACKUP_DIR}${RESET}"

# Initialiser le fichier de documentation
cat > "$DOC_FILE" << EOT
# Documentation de l'Unification des Modèles CoreData

## Introduction
Ce document décrit le processus d'unification des deux modèles CoreData présents dans l'application:
- \`Core.xcdatamodeld\` dans \`Core/Models/Data/\`
- \`CardApp.xcdatamodeld\` dans \`Core/Persistence/\`

L'objectif est de standardiser l'accès aux données et d'éviter les ambiguïtés et duplications.

## Analyse des Modèles Originaux

### Modèle Core.xcdatamodel
EOT

# Analyser les modèles
echo -e "\n${BOLD}${BLUE}Analyse du modèle Core.xcdatamodel${RESET}"
echo "Le contenu suivant a été trouvé:" >> "$DOC_FILE"
echo '```xml' >> "$DOC_FILE"
head -n 50 "$CORE_MODEL" >> "$DOC_FILE"
echo '...' >> "$DOC_FILE"
echo '```' >> "$DOC_FILE"

# Extraire les entités du modèle Core
echo -e "\n${BOLD}${BLUE}Extraction des entités de Core.xcdatamodel${RESET}"
CORE_ENTITIES=$(grep -o '<entity name="[^"]*"' "$CORE_MODEL" | sed 's/<entity name="//g' | sed 's/"//g')
echo -e "Entités trouvées dans Core.xcdatamodel:"
echo "### Entités identifiées dans Core.xcdatamodel:" >> "$DOC_FILE"
echo "" >> "$DOC_FILE"

for entity in $CORE_ENTITIES; do
    echo -e "${BLUE}→ $entity${RESET}"
    echo "- $entity" >> "$DOC_FILE"
done

echo "" >> "$DOC_FILE"
echo "### Modèle CardApp.xcdatamodel" >> "$DOC_FILE"
echo "Le contenu suivant a été trouvé:" >> "$DOC_FILE"
echo '```xml' >> "$DOC_FILE"
head -n 50 "$CARDAPP_MODEL" >> "$DOC_FILE"
echo '...' >> "$DOC_FILE"
echo '```' >> "$DOC_FILE"

# Extraire les entités du modèle CardApp
echo -e "\n${BOLD}${BLUE}Extraction des entités de CardApp.xcdatamodel${RESET}"
CARDAPP_ENTITIES=$(grep -o '<entity name="[^"]*"' "$CARDAPP_MODEL" | sed 's/<entity name="//g' | sed 's/"//g')
echo -e "Entités trouvées dans CardApp.xcdatamodel:"
echo "### Entités identifiées dans CardApp.xcdatamodel:" >> "$DOC_FILE"
echo "" >> "$DOC_FILE"

for entity in $CARDAPP_ENTITIES; do
    echo -e "${BLUE}→ $entity${RESET}"
    echo "- $entity" >> "$DOC_FILE"
done

# Comparer les entités pour trouver les doublons et les uniques
echo -e "\n${BOLD}${BLUE}Comparaison des entités entre les deux modèles${RESET}"
echo "" >> "$DOC_FILE"
echo "## Comparaison des Entités" >> "$DOC_FILE"
echo "" >> "$DOC_FILE"
echo "### Entités en commun" >> "$DOC_FILE"
echo "" >> "$DOC_FILE"

# Trouver les entités communes
COMMON_ENTITIES=""
for entity in $CORE_ENTITIES; do
    if echo "$CARDAPP_ENTITIES" | grep -q "$entity"; then
        echo -e "${YELLOW}⚠️ Entité en double: ${entity}${RESET}"
        echo "- $entity" >> "$DOC_FILE"
        COMMON_ENTITIES="$COMMON_ENTITIES $entity"
    fi
done

if [ -z "$COMMON_ENTITIES" ]; then
    echo -e "${GREEN}✅ Aucune entité en double trouvée${RESET}"
    echo "Aucune entité en double trouvée" >> "$DOC_FILE"
fi

echo "" >> "$DOC_FILE"
echo "### Entités uniques à Core.xcdatamodel" >> "$DOC_FILE"
echo "" >> "$DOC_FILE"

# Trouver les entités uniques à Core
UNIQUE_CORE=""
for entity in $CORE_ENTITIES; do
    if ! echo "$CARDAPP_ENTITIES" | grep -q "$entity"; then
        echo -e "${GREEN}✅ Entité unique à Core: ${entity}${RESET}"
        echo "- $entity" >> "$DOC_FILE"
        UNIQUE_CORE="$UNIQUE_CORE $entity"
    fi
done

if [ -z "$UNIQUE_CORE" ]; then
    echo -e "${YELLOW}⚠️ Aucune entité unique à Core trouvée${RESET}"
    echo "Aucune entité unique trouvée" >> "$DOC_FILE"
fi

echo "" >> "$DOC_FILE"
echo "### Entités uniques à CardApp.xcdatamodel" >> "$DOC_FILE"
echo "" >> "$DOC_FILE"

# Trouver les entités uniques à CardApp
UNIQUE_CARDAPP=""
for entity in $CARDAPP_ENTITIES; do
    if ! echo "$CORE_ENTITIES" | grep -q "$entity"; then
        echo -e "${GREEN}✅ Entité unique à CardApp: ${entity}${RESET}"
        echo "- $entity" >> "$DOC_FILE"
        UNIQUE_CARDAPP="$UNIQUE_CARDAPP $entity"
    fi
done

if [ -z "$UNIQUE_CARDAPP" ]; then
    echo -e "${YELLOW}⚠️ Aucune entité unique à CardApp trouvée${RESET}"
    echo "Aucune entité unique trouvée" >> "$DOC_FILE"
fi

# Générer un plan de migration
echo -e "\n${BOLD}${BLUE}Génération du plan de migration${RESET}"
echo "" >> "$DOC_FILE"
echo "## Plan de Migration" >> "$DOC_FILE"
echo "" >> "$DOC_FILE"
echo "### Stratégie d'Unification" >> "$DOC_FILE"
echo "" >> "$DOC_FILE"
cat << EOT >> "$DOC_FILE"
La stratégie recommandée est de:

1. **Consolider vers un seul modèle**: Utiliser CardApp.xcdatamodeld comme modèle principal
2. **Migrer les entités uniques**: Déplacer les entités uniques de Core.xcdatamodel vers CardApp.xcdatamodeld
3. **Résoudre les conflits**: Pour les entités communes, comparer les attributs et relations et adopter la version la plus complète
4. **Mettre à jour les références**: Mettre à jour tous les imports et références dans le code pour utiliser uniquement le modèle unifié

### Étapes Techniques

1. **Génération du modèle unifié**
   - Créer une nouvelle version du modèle CardApp.xcdatamodeld
   - Y ajouter les entités uniques de Core.xcdatamodeld
   - Résoudre les conflits entre entités communes

2. **Migration des données**
   - Créer une stratégie de migration légère (si possible)
   - Tester la migration avec un jeu de données représentatif

3. **Mise à jour du code**
   - Corriger tous les imports pour référencer uniquement le modèle unifié
   - Mettre à jour les accès aux entités pour utiliser le bon contexte
   - Ajouter des validation tests pour vérifier l'intégrité des données après migration
EOT

# Générer un script d'unification (approche simulée)
echo -e "\n${BOLD}${BLUE}Génération du script d'unification${RESET}"
echo "" >> "$DOC_FILE"
echo "## Implémentation de l'Unification" >> "$DOC_FILE"
echo "" >> "$DOC_FILE"
cat << EOT >> "$DOC_FILE"
### Script d'Unification (Pseudo-code)

\`\`\`swift
// 1. Créer une nouvelle version du modèle CardApp
// Utiliser Xcode pour créer une nouvelle version du modèle

// 2. Pour chaque entité unique dans Core.xcdatamodel
/*
$(for entity in $UNIQUE_CORE; do
    echo "   - Copier l'entité $entity et ses attributs"
done)
*/

// 3. Pour chaque entité commune, résoudre les conflits
/*
$(for entity in $COMMON_ENTITIES; do
    echo "   - Comparer les attributs de $entity dans les deux modèles"
    echo "   - Adopter la version la plus complète avec tous les attributs"
    echo "   - Vérifier et corriger les relations"
done)
*/

// 4. Mettre à jour les références dans le code
/*
   - Remplacer: import Core.Models.Data
   - Par:       import Core.Persistence
   
   - Remplacer les références directes aux entités
*/
\`\`\`

### Liste des fichiers à mettre à jour

Il sera nécessaire de rechercher et mettre à jour les fichiers qui référencent directement les entités du modèle Core.xcdatamodel:

\`\`\`bash
grep -r "import Core.Models.Data" --include="*.swift" .
grep -r "NSEntityDescription.entity(forEntityName:" --include="*.swift" .
\`\`\`
EOT

# Conclusion
echo -e "\n${BOLD}${BLUE}Finalisation de la documentation${RESET}"
echo "" >> "$DOC_FILE"
echo "## Conclusion" >> "$DOC_FILE"
echo "" >> "$DOC_FILE"
cat << EOT >> "$DOC_FILE"
L'unification des modèles CoreData permettra de:

1. **Simplifier la base de code**: Un seul modèle à maintenir
2. **Éviter les ambiguïtés**: Élimination des références contradictoires
3. **Améliorer les performances**: Optimisation possible avec un modèle unifié
4. **Faciliter l'évolution**: Base solide pour les futures extensions

Pour mettre en œuvre cette unification:

1. Planifier une session de travail dédiée
2. Effectuer l'unification dans une branche séparée
3. Tester rigoureusement avant de merger
4. Documenter les changements pour l'équipe

Cette unification constitue une étape importante pour réduire la dette technique du projet.
EOT

echo -e "${GREEN}✅ Documentation complète générée dans ${DOC_FILE}${RESET}"

# Création d'un script de migration pour unifier les modèles (simulé)
MIGRATION_SCRIPT="${BACKUP_DIR}/migrate_models.swift"

cat > "$MIGRATION_SCRIPT" << EOT
#!/usr/bin/swift

import Foundation

// Script pour unifier les modèles CoreData
// IMPORTANT: Ceci est un script de démonstration qui doit être adapté et exécuté manuellement

print("MIGRATION DES MODÈLES COREDATA")
print("==============================")

// 1. Chemins des modèles
let coreModelPath = "./Core/Models/Data/Core.xcdatamodeld/Core.xcdatamodel/contents"
let cardAppModelPath = "./Core/Persistence/CardApp.xcdatamodeld/CardApp.xcdatamodel/contents"

// 2. Lire les fichiers de modèle
print("Lecture des modèles...")
guard let coreModelData = FileManager.default.contents(atPath: coreModelPath),
      let cardAppModelData = FileManager.default.contents(atPath: cardAppModelPath),
      let coreModelString = String(data: coreModelData, encoding: .utf8),
      let cardAppModelString = String(data: cardAppModelData, encoding: .utf8) else {
    print("Erreur: Impossible de lire les fichiers de modèle")
    exit(1)
}

// 3. Entités communes identifiées
let commonEntities = ["CardEntity", "DeckEntity", "CardReviewEntity", "StudySessionEntity", "TagEntity"]
print("Entités communes identifiées: \(commonEntities.joined(separator: ", "))")

// 4. Entités uniques à Core
let uniqueCoreEntities = [ ]
print("Entités uniques à Core.xcdatamodel: \(uniqueCoreEntities.isEmpty ? "Aucune" : uniqueCoreEntities.joined(separator: ", "))")

// 5. Entités uniques à CardApp
let uniqueCardAppEntities = ["MediaEntity"]
print("Entités uniques à CardApp.xcdatamodel: \(uniqueCardAppEntities.joined(separator: ", "))")

// NOTE: Pour finaliser la migration, il est recommandé d'utiliser Xcode directement
// pour créer une nouvelle version du modèle et y ajouter manuellement les entités manquantes

print("\nPour compléter la migration:")
print("1. Créer une nouvelle version du modèle CardApp.xcdatamodeld dans Xcode")
print("2. Vérifier que toutes les entités sont présentes avec leurs attributs")
print("3. Mettre à jour les références dans le code")
print("4. Créer une stratégie de migration si nécessaire")
print("\nLe script a généré une documentation détaillée dans: docs/MODELE_COREDATA_UNIFIE.md")
EOT

chmod +x "$MIGRATION_SCRIPT"
echo -e "${GREEN}✅ Script de migration généré dans ${MIGRATION_SCRIPT}${RESET}"
echo -e "${YELLOW}⚠️ Ce script est une simulation et doit être adapté avant utilisation${RESET}"

echo -e "\n${BOLD}${GREEN}=== ANALYSE ET PLANIFICATION DE L'UNIFICATION TERMINÉES ===${RESET}"
echo -e "${GREEN}✅ Consultez la documentation dans ${DOC_FILE} pour les détails complets${RESET}"
echo -e "${GREEN}✅ Les fichiers originaux ont été sauvegardés dans ${BACKUP_DIR}${RESET}" 