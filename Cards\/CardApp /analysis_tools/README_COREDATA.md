# Outils de Correction CoreData pour CardApp

> Date: Mai 2025

Ce répertoire contient un ensemble d'outils pour analyser et corriger les problèmes liés à CoreData dans le projet CardApp.

## Problèmes identifiés

L'analyse du projet a révélé plusieurs problèmes critiques :

1. **Modèles CoreData dupliqués** - Deux modèles distincts (`Core.xcdatamodeld` et `Cards.xcdatamodeld`)
2. **Ambiguïtés de types** - Définitions multiples des types `ReviewRating` et `MasteryLevel`
3. **Références non qualifiées** - Utilisation de types sans qualification complète
4. **Conversions problématiques** - Problèmes lors des conversions entre entités et modèles
5. **Problèmes de concurrence** - Utilisation non sécurisée de CoreData dans un environnement multi-thread

## Outils disponibles

### 1. Analyse

#### `analyze_coredata_types.sh`

Analyse complète des types et ambiguïtés dans le contexte CoreData.

```bash
./analyze_coredata_types.sh
```

Sortie:
- Un rapport détaillé dans `reports/coredata_types_analysis_TIMESTAMP.md`
- Des sauvegardes dans `backups_coredata_types_TIMESTAMP/`

### 2. Correction des modèles

#### `fix_coredata_models.sh`

Unification des modèles CoreData en un seul modèle cohérent.

```bash
./fix_coredata_models.sh
```

Fonctionnalités:
- Détection des modèles existants
- Création d'un modèle unifié `CardApp.xcdatamodeld`
- Mise à jour des références dans le code
- Création d'un utilitaire de migration `CoreDataMigration.swift`

### 3. Correction des ambiguïtés

#### `fix_coredata_ambiguities.sh`

Correction des ambiguïtés de types et de références.

```bash
./fix_coredata_ambiguities.sh
```

Corrections:
- Qualification des types ambigus (ReviewRating, MasteryLevel)
- Normalisation des initialisations problématiques
- Correction des ambiguïtés avec PersistenceController
- Correction des problèmes de protocole dans CardSchedulerProtocolV2

### 4. Solution complète

#### `fix_coredata_all.sh`

Script d'orchestration qui guide à travers toutes les étapes de correction.

```bash
./fix_coredata_all.sh
```

Fonctionnalités:
- Interface interactive avec confirmations
- Exécution séquentielle des outils d'analyse et de correction
- Vérification optionnelle de la compilation
- Journalisation complète des actions

## Documentation

Pour une explication détaillée des problèmes et des solutions :

- `docs/GUIDE_COREDATA.md` - Guide complet sur les problèmes CoreData et leurs solutions
- `logs/` - Journaux d'exécution des scripts
- `reports/` - Rapports d'analyse détaillés

## Bonnes pratiques

1. **Avant de commencer** :
   - Faire une copie de sauvegarde du projet
   - Vérifier que les scripts sont exécutables (`chmod +x script.sh`)

2. **Ordre d'exécution recommandé** :
   1. Lancer `fix_coredata_all.sh` pour être guidé à travers le processus
   2. Examiner les rapports générés
   3. Vérifier la compilation du projet

3. **Après corrections** :
   - Valider le fonctionnement de l'application
   - Vérifier qu'il n'y a pas de régressions
   - Consulter les logs pour comprendre les modifications effectuées

## Sauvegardes

Tous les scripts créent des sauvegardes avant de modifier les fichiers :

- `backups_coredata_models_TIMESTAMP/`
- `backups_coredata_types_TIMESTAMP/`
- `backups_coredata_ambiguities_TIMESTAMP/`

En cas de problème, vous pouvez restaurer les fichiers depuis ces répertoires.

## Résultats attendus

Après l'exécution de tous les scripts :

1. Un seul modèle CoreData (`CardApp.xcdatamodeld`)
2. Des références qualifiées pour tous les types ambigus
3. Des conversions sécurisées entre entités et modèles
4. Un utilitaire de migration pour assurer la compatibilité avec les données existantes
5. Un code plus robuste et mieux structuré

## Support

Pour plus d'informations ou en cas de problèmes, consultez la documentation complète dans `docs/GUIDE_COREDATA.md`. 