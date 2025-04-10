# Documentation de l'Unification des Modèles CoreData

## Introduction
Ce document décrit le processus d'unification des deux modèles CoreData présents dans l'application:
- `Core.xcdatamodeld` dans `Core/Models/Data/`
- `CardApp.xcdatamodeld` dans `Core/Persistence/`

L'objectif est de standardiser l'accès aux données et d'éviter les ambiguïtés et duplications.

## Analyse des Modèles Originaux

### Modèle Core.xcdatamodel
Le contenu suivant a été trouvé:
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<model type="com.apple.IDECoreDataModeler.DataModel" documentVersion="1.0" lastSavedToolsVersion="21754" systemVersion="22E261" minimumToolsVersion="Automatic" sourceLanguage="Swift" userDefinedModelVersionIdentifier="">
    <entity name="CardEntity" representedClassName="CardEntity" syncable="YES">
        <attribute name="additionalInfo" optional="YES" attributeType="String"/>
        <attribute name="answer" attributeType="String"/>
        <attribute name="correctCount" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="createdAt" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="deckID" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="ease" attributeType="Double" defaultValueString="2.5" usesScalarValueType="YES"/>
        <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="incorrectCount" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="interval" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="isFlagged" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES"/>
        <attribute name="lastReviewedAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="masteryLevel" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="nextReviewDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="question" attributeType="String"/>
        <attribute name="reviewCount" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="tags" attributeType="Transformable" valueTransformerName="NSSecureUnarchiveFromData" customClassName="[String]"/>
        <attribute name="updatedAt" attributeType="Date" usesScalarValueType="NO"/>
        <relationship name="deck" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="DeckEntity" inverseName="cards" inverseEntity="DeckEntity"/>
        <relationship name="reviews" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="CardReviewEntity" inverseName="card" inverseEntity="CardReviewEntity"/>
    </entity>
    <entity name="CardReviewEntity" representedClassName="CardReviewEntity" syncable="YES">
        <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="newEase" attributeType="Double" defaultValueString="2.5" usesScalarValueType="YES"/>
        <attribute name="newInterval" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="newMasteryLevel" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="rating" attributeType="String"/>
        <attribute name="responseTime" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <attribute name="timestamp" attributeType="Date" usesScalarValueType="NO"/>
        <relationship name="card" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="CardEntity" inverseName="reviews" inverseEntity="CardEntity"/>
        <relationship name="session" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="StudySessionEntity" inverseName="reviews" inverseEntity="StudySessionEntity"/>
    </entity>
    <entity name="DeckEntity" representedClassName="DeckEntity" syncable="YES">
        <attribute name="cardCount" attributeType="Integer 32" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="colorName" attributeType="String" defaultValueString="blue"/>
        <attribute name="createdAt" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="desc" attributeType="String" defaultValueString=""/>
        <attribute name="icon" attributeType="String" defaultValueString="rectangle.stack"/>
        <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="name" attributeType="String"/>
        <attribute name="tags" attributeType="Transformable" valueTransformerName="NSSecureUnarchiveFromData" customClassName="[String]"/>
        <attribute name="updatedAt" attributeType="Date" usesScalarValueType="NO"/>
        <relationship name="cards" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="CardEntity" inverseName="deck" inverseEntity="CardEntity"/>
        <relationship name="parentDeck" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="DeckEntity" inverseName="subdecks" inverseEntity="DeckEntity"/>
        <relationship name="subdecks" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="DeckEntity" inverseName="parentDeck" inverseEntity="DeckEntity"/>
    </entity>
    <entity name="StudySessionEntity" representedClassName="StudySessionEntity" syncable="YES">
        <attribute name="deckID" optional="YES" attributeType="UUID" usesScalarValueType="NO"/>
...
```
### Entités identifiées dans Core.xcdatamodel:

- CardEntity
- CardReviewEntity
- DeckEntity
- StudySessionEntity
- TagEntity

### Modèle CardApp.xcdatamodel
Le contenu suivant a été trouvé:
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<model type="com.apple.IDECoreDataModeler.DataModel" documentVersion="1.0" lastSavedToolsVersion="21754" systemVersion="22F66" minimumToolsVersion="Automatic" sourceLanguage="Swift" userDefinedModelVersionIdentifier="">
    <entity name="CardEntity" representedClassName=".CardEntity" syncable="YES">
        <attribute name="additionalInfo" optional="YES" attributeType="String"/>
        <attribute name="answer" attributeType="String"/>
        <attribute name="correctCount" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="createdAt" indexed="YES" attributeType="Date" defaultDateTimeInterval="708103500" usesScalarValueType="NO"/>
        <attribute name="id" indexed="YES" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="incorrectCount" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="isFlagged" indexed="YES" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES"/>
        <attribute name="lastReviewedAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="masteryLevel" attributeType="String" defaultValueString="new"/>
        <attribute name="nextReviewDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="question" attributeType="String"/>
        <attribute name="reviewCount" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="tags" optional="YES" attributeType="String"/>
        <attribute name="updatedAt" indexed="YES" attributeType="Date" defaultDateTimeInterval="708103500" usesScalarValueType="NO"/>
        <relationship name="deck" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="DeckEntity" inverseName="cards" inverseEntity="DeckEntity"/>
        <relationship name="mediaItems" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="MediaEntity" inverseName="card" inverseEntity="CardEntity"/>
        <fetchIndex name="byIdIndex">
            <fetchIndexElement property="id" type="Binary" order="ascending"/>
        </fetchIndex>
        <fetchIndex name="byMasteryLevelIndex">
            <fetchIndexElement property="masteryLevel" type="Binary" order="ascending"/>
        </fetchIndex>
        <fetchIndex name="byNextReviewDateIndex">
            <fetchIndexElement property="nextReviewDate" type="Binary" order="ascending"/>
        </fetchIndex>
        <fetchIndex name="byIsFlaggedIndex">
            <fetchIndexElement property="isFlagged" type="Binary" order="ascending"/>
        </fetchIndex>
        <fetchIndex name="byCreatedAtIndex">
            <fetchIndexElement property="createdAt" type="Binary" order="descending"/>
        </fetchIndex>
        <fetchIndex name="byUpdatedAtIndex">
            <fetchIndexElement property="updatedAt" type="Binary" order="descending"/>
        </fetchIndex>
    </entity>
    <entity name="DeckEntity" representedClassName=".DeckEntity" syncable="YES">
        <attribute name="colorName" attributeType="String" defaultValueString="blue"/>
        <attribute name="createdAt" indexed="YES" attributeType="Date" defaultDateTimeInterval="708103500" usesScalarValueType="NO"/>
        <attribute name="descriptionText" optional="YES" attributeType="String"/>
        <attribute name="icon" attributeType="String" defaultValueString="rectangle.stack"/>
        <attribute name="id" indexed="YES" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="name" indexed="YES" attributeType="String"/>
        <attribute name="tags" optional="YES" attributeType="String"/>
        <attribute name="updatedAt" indexed="YES" attributeType="Date" defaultDateTimeInterval="708103500" usesScalarValueType="NO"/>
        <relationship name="cards" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="CardEntity" inverseName="deck" inverseEntity="CardEntity"/>
        <fetchIndex name="byIdIndex">
            <fetchIndexElement property="id" type="Binary" order="ascending"/>
...
```
### Entités identifiées dans CardApp.xcdatamodel:

- CardEntity
- DeckEntity
- MediaEntity
- StudySessionEntity
- TagEntity

## Comparaison des Entités

### Entités en commun

- CardEntity
- DeckEntity
- StudySessionEntity
- TagEntity

### Entités uniques à Core.xcdatamodel

- CardReviewEntity

### Entités uniques à CardApp.xcdatamodel

- MediaEntity

## Plan de Migration

### Stratégie d'Unification

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

## Implémentation de l'Unification

### Script d'Unification (Pseudo-code)

```swift
// 1. Créer une nouvelle version du modèle CardApp
// Utiliser Xcode pour créer une nouvelle version du modèle

// 2. Pour chaque entité unique dans Core.xcdatamodel
/*
   - Copier l'entité CardReviewEntity et ses attributs
*/

// 3. Pour chaque entité commune, résoudre les conflits
/*
   - Comparer les attributs de CardEntity dans les deux modèles
   - Adopter la version la plus complète avec tous les attributs
   - Vérifier et corriger les relations
   - Comparer les attributs de DeckEntity dans les deux modèles
   - Adopter la version la plus complète avec tous les attributs
   - Vérifier et corriger les relations
   - Comparer les attributs de StudySessionEntity dans les deux modèles
   - Adopter la version la plus complète avec tous les attributs
   - Vérifier et corriger les relations
   - Comparer les attributs de TagEntity dans les deux modèles
   - Adopter la version la plus complète avec tous les attributs
   - Vérifier et corriger les relations
*/

// 4. Mettre à jour les références dans le code
/*
   - Remplacer: import Core.Models.Data
   - Par:       import Core.Persistence
   
   - Remplacer les références directes aux entités
*/
```

### Liste des fichiers à mettre à jour

Il sera nécessaire de rechercher et mettre à jour les fichiers qui référencent directement les entités du modèle Core.xcdatamodel:

```bash
grep -r "import Core.Models.Data" --include="*.swift" .
grep -r "NSEntityDescription.entity(forEntityName:" --include="*.swift" .
```

## Conclusion

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
