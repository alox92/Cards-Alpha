#!/bin/bash

echo "=== Compilation du projet avec swift build ==="
swift build

if [ $? -eq 0 ]; then
    echo "=== Compilation réussie ==="
    echo "=== Lancement de l'application ==="
    # Exécuter le produit compilé
    .build/debug/CardAppDebug
else
    echo "=== Échec de la compilation ==="
fi 