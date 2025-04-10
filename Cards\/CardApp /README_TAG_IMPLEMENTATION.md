# Implémentation du système de tags

Ce document décrit les modifications apportées au système de gestion des tags de l'application CardApp et les améliorations futures possibles.

## Modifications réalisées

### 1. Création de l'entité TagItemAssociationEntity

Nous avons créé une entité CoreData `TagItemAssociationEntity` qui gère l'association entre les tags et différents types d'items (cartes, paquets, etc.). Cette entité a les attributs suivants :
- `id` (UUID) : Identifiant unique de l'association
- `tagID` (UUID) : Identifiant du tag
- `itemID` (UUID) : Identifiant de l'item associé
- `itemType` (String) : Type d'item ('card' ou 'deck')
- `createdAt` (Date) : Date de création de l'association

L'implémentation comprend :
- Un fichier de définition d'entité CoreData (`Core/Models/Data/TagItemAssociationEntity.swift`)
- Une description XML de l'entité pour faciliter son intégration dans le modèle CoreData (`Core/Persistence/TagItemAssociationEntity.xml`)
- Un script SQL pour créer la table correspondante (`Core/Resources/SQL/create_tag_item_association.sql`)
- Un fichier README avec les instructions d'intégration (`Core/Models/Data/README_TAG_ASSOCIATION.md`)

### 2. Mise à jour du service UnifiedTagService

Nous avons modifié le service `UnifiedTagService` pour utiliser le `TagItemAssociationService` afin de gérer les associations entre tags et items, au lieu d'utiliser directement des tableaux de tags dans les entités CardEntity et DeckEntity.

Les principales améliorations incluent :
- Ajout du service `TagItemAssociationService` comme dépendance
- Modification des méthodes d'ajout et de suppression de tags pour utiliser le service d'association
- Amélioration de la méthode de fusion de tags pour transférer toutes les associations d'un tag à un autre
- Adaptation des méthodes de calcul des statistiques pour utiliser le service d'association

## Problèmes connus et améliorations futures

### 1. Problèmes de concurrence

Des erreurs de linter persistent concernant des risques de conflits de données ("data races") lors de l'utilisation du `tagItemAssociationService` dans un contexte `@MainActor`. Il y a plusieurs approches pour résoudre ce problème :

- Implémenter le service `TagItemAssociationService` avec `@MainActor` également
- Synchroniser l'accès au service via un mécanisme de verrouillage ou de file d'attente
- Utiliser des méthodes isolées pour les appels au service

### 2. Optimisations de performance

Les opérations actuelles nécessitent parfois plusieurs appels à la base de données. On pourrait optimiser :
- Mise en cache des associations fréquemment utilisées
- Traitement par lots des opérations d'ajout et de suppression
- Réduction des appels redondants à `refreshTagsPublisher()`

### 3. Migrations de données

Pour une transition en douceur vers ce nouveau système, il faudrait :
- Créer une migration pour convertir les tags stockés directement dans les entités Card et Deck vers le nouveau système d'associations
- Ajouter une vérification de cohérence des données pour s'assurer que toutes les associations sont correctement migrées

### 4. Documentation et tests

Le système bénéficierait de :
- Documentation complète des API pour les développeurs
- Tests unitaires pour toutes les opérations CRUD sur les tags et associations
- Tests d'intégration pour vérifier l'interaction entre les différents services

## Intégration avec la base de données

Pour que le système fonctionne correctement, l'entité `TagItemAssociationEntity` doit être ajoutée au modèle CoreData. Suivez les instructions détaillées dans le fichier `Core/Models/Data/README_TAG_ASSOCIATION.md` pour cette intégration.

## Utilisation des services de tags

Exemple d'utilisation du système :

```swift
// Ajouter un tag à une carte
try await tagService.addTagToCard(tagName: "Important", cardID: card.id)

// Récupérer tous les tags associés à une carte
let tags = try await tagItemAssociationService.getTagsForItem(itemID: card.id, itemType: .card)

// Fusionner deux tags
let mergedTag = try await tagService.mergeTags(sourceID: oldTagID, targetID: newTagID)
``` 