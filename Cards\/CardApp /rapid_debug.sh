#!/bin/bash

# Paramètres configurables
LOG_FILE="debug_results.log"
ERROR_REPORT="compilation_errors.txt"

# Fonctions utilitaires
log() {
  echo "$1"
  echo "$1" >> "$LOG_FILE"
}

separator() {
  log "----------------------------------------"
}

# Préparation
rm -f "$LOG_FILE" "$ERROR_REPORT"
touch "$LOG_FILE" "$ERROR_REPORT"

log "🔍 DIAGNOSTIC RAPIDE - CardApp"
separator

# 1. Vérification des erreurs de syntaxe (rapide)
log "1️⃣ Vérification rapide de la syntaxe Swift..."
find Core App -name "*.swift" -print0 | xargs -0 -n1 swift -syntax-only 2>> "$ERROR_REPORT"

if [ -s "$ERROR_REPORT" ]; then
  log "⚠️ Erreurs de syntaxe détectées:"
  grep -v "warning:" "$ERROR_REPORT" | head -5 >> "$LOG_FILE"
  log "(Voir $ERROR_REPORT pour la liste complète)"
else
  log "✅ Pas d'erreurs de syntaxe basiques détectées"
fi
separator

# 2. Vérification des dépendances problématiques
log "2️⃣ Analyse des dépendances potentiellement problématiques..."
log "Fichiers avec le plus de dépendances:"
find Core App -name "*.swift" -print0 | xargs -0 grep -l "import " | xargs wc -l | sort -nr | head -10 >> "$LOG_FILE"

log "Imports circulaires potentiels:"
grep -r "import " --include="*.swift" . | sort | uniq -c | sort -nr | head -10 >> "$LOG_FILE"
separator

# 3. Identification des erreurs de compilation par section
log "3️⃣ Compilation par sections pour isoler les problèmes..."

# Tenter de compiler uniquement Core
log "Compilation de Core uniquement..."
swift build --target Core > /dev/null 2>> "$ERROR_REPORT"
if [ $? -eq 0 ]; then
  log "✅ Module Core compilation OK"
else
  log "❌ Module Core échec de compilation"
  grep "error:" "$ERROR_REPORT" | tail -5 >> "$LOG_FILE"
fi

# Compiler avec des settings progressivement plus stricts
log "Compilation avec différents niveaux de contrôle..."
SWIFT_SETTINGS=(
  "-warnings-as-errors"
  "-strict-concurrency=complete"
  "-enable-actor-data-race-checks"
)

for setting in "${SWIFT_SETTINGS[@]}"; do
  log "Test avec: $setting"
  swift build -Xswiftc "$setting" > /dev/null 2>> "error_$setting.txt"
  if [ $? -ne 0 ]; then
    log "❌ Échec avec $setting"
    grep "error:" "error_$setting.txt" | head -3 >> "$LOG_FILE"
  else
    log "✅ Succès avec $setting"
  fi
done
separator

# 4. Analyse des fichiers les plus problématiques
log "4️⃣ Identification des fichiers les plus problématiques..."
grep "error:" "$ERROR_REPORT" | grep -o "[^:]*\.swift" | sort | uniq -c | sort -nr | head -5 >> "$LOG_FILE"
separator

log "🔍 RÉSULTATS DU DIAGNOSTIC"
log "Consultez $LOG_FILE pour tous les détails"

echo "Diagnostic terminé. Résultats enregistrés dans $LOG_FILE"
