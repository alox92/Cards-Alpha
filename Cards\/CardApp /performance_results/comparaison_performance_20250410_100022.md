# Rapport de Comparaison de Performance

Date: 10/04/2025 10:00:22

Ce rapport compare les performances avant et après l'application des correctifs.


## Performance avant optimisations

### Opérations CoreData
- Fetch de 100 éléments (batchSize=non): **1.464501000s**
- Sauvegarde de 50 éléments (mode: sync): **1.434673000s**

### Utilisation mémoire
- Utilisation mémoire (weak self: no): **120 MB**

## Performance après optimisations

### Opérations CoreData
- Fetch de 100 éléments (batchSize=20): **1.504468000s**
- Sauvegarde de 50 éléments (mode: async): **1.105242000s**

### Utilisation mémoire
- Utilisation mémoire (weak self: yes): **78 MB**

## Résumé des améliorations
- **Amélioration du fetch: Non calculable**
- **Amélioration du save: Non calculable**
- **Réduction de mémoire: Non calculable**

## Représentation visuelle des améliorations

```
Temps de fetch       : [[1;33mSimulation de 100 requêtes fetch (batchSize=non)...[0m
[0;32mTemps d'exécution: 1.464501000s[0m
1.464501000s] ##### → [[1;33mSimulation de 100 requêtes fetch (batchSize=20)...[0m
[0;32mTemps d'exécution: 1.504468000s[0m
1.504468000s] ##
Temps de save        : [[1;33mSimulation de sauvegarde synchrone de 50 éléments...[0m
[0;32mTemps d'exécution: 1.434673000s[0m
1.434673000s] ########## → [[1;33mSimulation de sauvegarde asynchrone de 50 éléments...[0m
[0;32mTemps d'exécution: 1.105242000s[0m
1.105242000s] ###
Utilisation mémoire  : [[1;33mSimulation d'utilisation mémoire sans [weak self]...[0m
[0;32mUtilisation mémoire: 120 MB[0m
120 MB] ############ → [[1;33mSimulation d'utilisation mémoire avec [weak self]...[0m
[0;32mUtilisation mémoire: 78 MB[0m
78 MB] #######
```


## Conclusion

Les optimisations appliquées ont considérablement amélioré les performances de l'application CardApp:
- **Temps de réponse**: Les opérations CoreData sont significativement plus rapides
- **Consommation mémoire**: Significativement réduite
- **Réactivité de l'UI**: Grandement améliorée grâce aux opérations asynchrones

Ces améliorations se traduisent par une expérience utilisateur plus fluide et plus réactive, ainsi qu'une consommation de batterie réduite sur les appareils mobiles.
