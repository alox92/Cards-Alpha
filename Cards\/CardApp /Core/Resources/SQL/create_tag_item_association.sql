-- Script pour ajouter l'entité TagItemAssociationEntity à la base de données existante

-- Création de la table TagItemAssociationEntity
CREATE TABLE IF NOT EXISTS "TagItemAssociationEntity" (
    "Z_PK" INTEGER PRIMARY KEY,
    "Z_ENT" INTEGER,
    "Z_OPT" INTEGER,
    "ZCREATEDAT" TIMESTAMP,
    "ZID" UUID,
    "ZITEMID" UUID,
    "ZITEMTYPE" VARCHAR,
    "ZTAGID" UUID
);

-- Création des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS "TagItemAssociation_ID_Index" ON "TagItemAssociationEntity" ("ZID");
CREATE INDEX IF NOT EXISTS "TagItemAssociation_TagID_Index" ON "TagItemAssociationEntity" ("ZTAGID");
CREATE INDEX IF NOT EXISTS "TagItemAssociation_ItemID_Index" ON "TagItemAssociationEntity" ("ZITEMID");
CREATE INDEX IF NOT EXISTS "TagItemAssociation_ItemType_Index" ON "TagItemAssociationEntity" ("ZITEMTYPE");

-- Note: Ce script doit être exécuté manuellement sur la base de données ou intégré à un processus de mise à jour de schéma.
-- Il complète la définition de l'entité dans le modèle Core Data, qui doit être ajoutée avec Xcode.

/*
MODÈLE CORE DATA: INSTRUCTIONS

Pour ajouter cette entité à votre modèle Core Data:
1. Ouvrez Core/Persistence/Cards.xcdatamodeld dans Xcode
2. Ajoutez une nouvelle entité nommée "TagItemAssociationEntity"
3. Configurez les attributs suivants:
   - id: UUID
   - tagID: UUID
   - itemID: UUID
   - itemType: String
   - createdAt: Date
4. Configurez la classe représentée comme "TagItemAssociationEntity" (préfixe d'importation: .)
5. Ajoutez des index sur les attributs id, tagID, itemID et itemType
*/ 