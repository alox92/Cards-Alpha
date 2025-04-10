#!/bin/bash

# Inclure uniquement les répertoires qui font partie de l'application principale
# Et exclure les fichiers problématiques
find ./App ./Core -name "*.swift" | grep -v ".bak" | grep -v "CoreDataOptimizer.swift" | sort > swift_files.txt

echo "Liste des fichiers Swift générée dans swift_files.txt"
echo "Nombre de fichiers: $(wc -l < swift_files.txt)"
