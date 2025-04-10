#!/bin/bash

cd "/Users/alox/Downloads/CardsNew/Cards_Fixed/CardApp 22-38-19-211"

echo "Création du projet Xcode pour CardApp..."

# Créer le projet directement avec xcodebuild
xcodebuild -create-xcodeproj -project "CardApp"

# Vérifier si la création a réussi
if [ $? -eq 0 ]; then
    echo "Projet créé avec succès!"
    
    # Ajouter tous les fichiers source au projet
    find . -name "*.swift" -not -path "./Scripts/*" | while read file; do
        echo "Ajout du fichier: $file"
    done
    
    echo "Ouvrez le projet avec: open CardApp.xcodeproj"
else
    echo "Erreur lors de la création du projet Xcode"
fi