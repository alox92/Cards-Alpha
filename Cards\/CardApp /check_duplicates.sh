#!/bin/bash

# Liste tous les fichiers Swift (en excluant .bak et CoreKit)
files=$(find . -name "*.swift" -not -path "./CoreKit/*" -not -path "./.build/*" -not -path "./Scripts/*" -not -path "./Tests/*" | grep -v ".bak")

# Extrait uniquement les noms de fichiers sans les chemins
basenames=$(for f in $files; do basename "$f"; done)

# Trouve les noms en double et affiche le nombre d'occurrences
echo "Fichiers en double détectés :"
echo "$basenames" | sort | uniq -c | sort -nr | grep -v "^ *1 "

# Affiche les chemins complets des fichiers en double
echo -e "\nEmplacements des fichiers en double :"
duplicates=$(echo "$basenames" | sort | uniq -d)
for dup in $duplicates; do
    echo -e "\n$dup trouvé dans :"
    find . -name "$dup" -not -path "./CoreKit/*" -not -path "./.build/*" | grep -v ".bak"
done 