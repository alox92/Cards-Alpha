# Configuration de l'entité TagItemAssociationEntity

Ce fichier explique comment ajouter l'entité `TagItemAssociationEntity` au modèle Core Data du projet.

## Pourquoi c'est nécessaire

L'entité `TagItemAssociationEntity` est utilisée par le service `TagItemAssociationService` pour stocker les associations entre les tags et différents types d'items (cartes, paquets, etc.). Cette entité n'est pas incluse dans le modèle Core Data par défaut et doit être ajoutée manuellement.

## Étapes à suivre

1. Ouvrez le projet dans Xcode
2. Naviguez vers le fichier `Core/Persistence/Cards.xcdatamodeld`
3. Ouvrez le modèle en double-cliquant dessus
4. Ajoutez une nouvelle entité en cliquant sur le bouton "+" en bas de l'éditeur Core Data
5. Nommez cette entité `TagItemAssociationEntity`
6. Configurez les attributs suivants:

| Nom       | Type | Description                            |
|-----------|------|----------------------------------------|
| id        | UUID | Identifiant unique de l'association    |
| tagID     | UUID | Identifiant du tag                     |
| itemID    | UUID | Identifiant de l'item associé          |
| itemType  | String | Type d'item ('card' ou 'deck')       |
| createdAt | Date | Date de création de l'association      |

7. Dans les propriétés de l'entité, définissez:
   - Classe: `TagItemAssociationEntity`
   - Module: `.` (point)

8. Ajoutez des index pour améliorer les performances:
   - Ajoutez un index sur `id` (ordre ascendant)
   - Ajoutez un index sur `tagID` (ordre ascendant)
   - Ajoutez un index sur `itemID` (ordre ascendant)
   - Ajoutez un index sur `itemType` (ordre ascendant)

9. Sauvegardez le modèle

## Vérification

Une fois ces étapes effectuées, vous pourrez utiliser le service `TagItemAssociationService` pour gérer les associations entre tags et items. Si l'entité n'est pas correctement configurée, vous obtiendrez une erreur lors de l'exécution à cause de l'impossibilité de trouver l'entité ou ses attributs.

## Migration de données existantes

Si vous avez déjà des données d'association entre les tags et les items stockées sous un autre format (comme des arrays dans les entités Card et Deck), vous devrez migrer ces données vers la nouvelle entité `TagItemAssociationEntity`. Vous pouvez utiliser le script SQL fourni dans `Core/Resources/SQL/create_tag_item_association.sql` comme référence. 