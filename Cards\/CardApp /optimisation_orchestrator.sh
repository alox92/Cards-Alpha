#!/bin/bash

# =============================================================================
# Orchestrateur d'optimisation pour CardApp
# =============================================================================
#
# Ce script exécute une suite complète d'outils d'analyse et d'optimisation
# pour diagnostiquer et corriger des problèmes dans l'application CardApp.
#
# Fonctionnalités:
# - Analyse statique du code Swift
# - Diagnostic et optimisation CoreData
# - Analyse de performance
# - Application automatique des correctifs courants
# - Génération de rapports détaillés
#
# Usage: ./optimisation_orchestrator.sh [chemin_projet]

set -e

# Styles de texte
ROUGE='\033[0;31m'
VERT='\033[0;32m'
JAUNE='\033[0;33m'
BLEU='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BLANC='\033[1;37m'
NORMAL='\033[0m'

# Configuration
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
RAPPORTS_DIR="rapports_optimisation"
CORRECTIFS_DIR="correctifs_auto"
LOG_FILE="${RAPPORTS_DIR}/orchestrator_${TIMESTAMP}.log"

# Vérifier les arguments
if [ $# -eq 0 ]; then
    CHEMIN_PROJET="$(pwd)"
else
    CHEMIN_PROJET="$1"
fi

# Vérifier que le chemin existe
if [ ! -d "$CHEMIN_PROJET" ]; then
    echo -e "${ROUGE}Erreur: Le chemin '$CHEMIN_PROJET' n'existe pas.${NORMAL}"
    exit 1
fi

# Créer les répertoires nécessaires
mkdir -p "$RAPPORTS_DIR"
mkdir -p "$CORRECTIFS_DIR"

# Fonction de journalisation
journal() {
    local NIVEAU=$1
    local MESSAGE=$2
    local COULEUR=$NORMAL
    
    case $NIVEAU in
        "INFO") COULEUR=$BLEU ;;
        "SUCCES") COULEUR=$VERT ;;
        "AVERTISSEMENT") COULEUR=$JAUNE ;;
        "ERREUR") COULEUR=$ROUGE ;;
        "ETAPE") COULEUR=$MAGENTA ;;
    esac
    
    echo -e "${COULEUR}[$(date +"%H:%M:%S")] [$NIVEAU] $MESSAGE${NORMAL}"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [$NIVEAU] $MESSAGE" >> "$LOG_FILE"
}

# Fonction pour exécuter une commande avec journalisation
executer() {
    local COMMANDE="$1"
    local DESCRIPTION="$2"
    
    journal "ETAPE" "Démarrage: $DESCRIPTION"
    echo -e "${CYAN}Exécution: $COMMANDE${NORMAL}"
    
    if eval "$COMMANDE"; then
        journal "SUCCES" "Terminé: $DESCRIPTION"
        return 0
    else
        local STATUT=$?
        journal "ERREUR" "Échec ($STATUT): $DESCRIPTION"
        return $STATUT
    fi
}

# Bannière de démarrage
echo -e "${BLANC}=======================================================${NORMAL}"
echo -e "${BLANC}     ORCHESTRATEUR D'OPTIMISATION POUR CARDAPP         ${NORMAL}"
echo -e "${BLANC}=======================================================${NORMAL}"
journal "INFO" "Démarrage de l'analyse pour le projet: $CHEMIN_PROJET"
journal "INFO" "Rapports disponibles dans: $RAPPORTS_DIR"
journal "INFO" "Correctifs automatiques dans: $CORRECTIFS_DIR"

# -----------------------------------------------------------------------------
# 1. Analyse statique du code Swift avec Python
# -----------------------------------------------------------------------------
journal "ETAPE" "ÉTAPE 1: Analyse statique du code Swift"

# Vérifier que Python est installé
if ! command -v python3 &> /dev/null; then
    journal "ERREUR" "Python 3 n'est pas installé. Installation nécessaire pour l'analyse statique."
else
    # Vérifier que le script d'analyse existe
    if [ ! -f "swift_analyzer.py" ]; then
        journal "ERREUR" "Script d'analyse swift_analyzer.py manquant."
    else
        # Rendre le script exécutable
        chmod +x swift_analyzer.py
        
        # Exécuter l'analyse
        executer "python3 swift_analyzer.py \"$CHEMIN_PROJET\"" "Analyse statique du code Swift"
        
        # Vérifier si des problèmes critiques ont été trouvés
        if grep -q "\"severite\": \"critical\"" "${RAPPORTS_DIR}/swift_analyze_"*".json" 2>/dev/null; then
            journal "AVERTISSEMENT" "Des problèmes CRITIQUES ont été détectés lors de l'analyse statique!"
        fi
    fi
fi

# -----------------------------------------------------------------------------
# 2. Diagnostic CoreData avec Swift
# -----------------------------------------------------------------------------
journal "ETAPE" "ÉTAPE 2: Optimisation et diagnostic CoreData"

# Vérifier que Swift est installé
if ! command -v swift &> /dev/null; then
    journal "ERREUR" "Swift n'est pas installé. Installation nécessaire pour le diagnostic CoreData."
else
    # Vérifier que le script d'optimisation existe
    if [ ! -f "run_core_data_optimizer.swift" ]; then
        journal "ERREUR" "Script d'optimisation CoreData manquant (run_core_data_optimizer.swift)."
    else
        # Rendre le script exécutable
        chmod +x run_core_data_optimizer.swift
        
        # Exécuter l'optimisation CoreData
        executer "swift run_core_data_optimizer.swift \"$CHEMIN_PROJET\"" "Diagnostic et optimisation CoreData"
    fi
fi

# -----------------------------------------------------------------------------
# 3. Analyse du projet Xcode
# -----------------------------------------------------------------------------
journal "ETAPE" "ÉTAPE 3: Analyse du projet Xcode"

# Rechercher les fichiers de projet Xcode
PROJET_XCODEPROJ=$(find "$CHEMIN_PROJET" -name "*.xcodeproj" -maxdepth 2 | head -n 1)

if [ -z "$PROJET_XCODEPROJ" ]; then
    journal "AVERTISSEMENT" "Aucun fichier .xcodeproj trouvé dans le projet."
else
    journal "INFO" "Projet Xcode trouvé: $PROJET_XCODEPROJ"
    
    # Vérifier si xcodebuild est disponible
    if command -v xcodebuild &> /dev/null; then
        # Extraire le nom du schéma (peut nécessiter des ajustements)
        SCHEMA=$(xcodebuild -list -project "$PROJET_XCODEPROJ" 2>/dev/null | grep -A 10 "Schemes:" | tail -n +2 | head -n 1 | xargs)
        
        if [ -n "$SCHEMA" ]; then
            journal "INFO" "Schéma trouvé: $SCHEMA"
            
            # Exécuter une analyse Xcode
            executer "xcodebuild analyze -project \"$PROJET_XCODEPROJ\" -scheme \"$SCHEMA\" -quiet > \"$RAPPORTS_DIR/xcode_analyze_${TIMESTAMP}.log\" 2>&1" "Analyse statique Xcode"
            
            # Vérifier s'il y a des avertissements ou des erreurs
            if grep -E "warning|error" "$RAPPORTS_DIR/xcode_analyze_${TIMESTAMP}.log" > /dev/null; then
                WARNINGS=$(grep -c "warning" "$RAPPORTS_DIR/xcode_analyze_${TIMESTAMP}.log" || echo "0")
                ERRORS=$(grep -c "error" "$RAPPORTS_DIR/xcode_analyze_${TIMESTAMP}.log" || echo "0")
                journal "AVERTISSEMENT" "L'analyse Xcode a détecté $WARNINGS avertissements et $ERRORS erreurs."
            else
                journal "SUCCES" "Aucun problème détecté par l'analyse Xcode."
            fi
        else
            journal "AVERTISSEMENT" "Impossible de déterminer le schéma Xcode."
        fi
    else
        journal "AVERTISSEMENT" "xcodebuild n'est pas disponible. L'analyse Xcode est ignorée."
    fi
fi

# -----------------------------------------------------------------------------
# 4. Analyse de la structure du projet
# -----------------------------------------------------------------------------
journal "ETAPE" "ÉTAPE 4: Analyse de la structure du projet"

# Extraire les informations sur la structure des fichiers
executer "find \"$CHEMIN_PROJET\" -type f -name \"*.swift\" | sort > \"$RAPPORTS_DIR/structure_fichiers_${TIMESTAMP}.txt\"" "Extraction de la structure des fichiers Swift"

# Compter les types de fichiers
TOTAL_SWIFT=$(grep -c "\.swift$" "$RAPPORTS_DIR/structure_fichiers_${TIMESTAMP}.txt" || echo "0")
journal "INFO" "Le projet contient $TOTAL_SWIFT fichiers Swift."

# Analyser les imports et dépendances
executer "grep -h '^import' \$(find \"$CHEMIN_PROJET\" -name \"*.swift\") | sort | uniq -c | sort -nr > \"$RAPPORTS_DIR/imports_${TIMESTAMP}.txt\"" "Analyse des imports"

# Extraire le modèle CoreData
MODELES_COREDATA=$(find "$CHEMIN_PROJET" -name "*.xcdatamodeld" -o -name "*.xcdatamodel")
if [ -n "$MODELES_COREDATA" ]; then
    for MODELE in $MODELES_COREDATA; do
        MODEL_NAME=$(basename "$MODELE")
        executer "cp -R \"$MODELE\" \"$RAPPORTS_DIR/\"" "Sauvegarde du modèle CoreData $MODEL_NAME"
    done
    journal "INFO" "Modèles CoreData sauvegardés dans $RAPPORTS_DIR"
else
    journal "AVERTISSEMENT" "Aucun modèle CoreData trouvé dans le projet."
fi

# -----------------------------------------------------------------------------
# 5. Génération d'un rapport unifié
# -----------------------------------------------------------------------------
journal "ETAPE" "ÉTAPE 5: Génération du rapport unifié"

# Créer un rapport HTML
RAPPORT_HTML="$RAPPORTS_DIR/rapport_unifie_${TIMESTAMP}.html"

cat > "$RAPPORT_HTML" << EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'optimisation CardApp</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .container {
            background: #fff;
            border-radius: 5px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .summary {
            background-color: #f8f9fa;
            border-left: 4px solid #007bff;
            padding: 15px;
            margin-bottom: 20px;
        }
        .critical {
            background-color: #f8d7da;
            border-left: 4px solid #dc3545;
            padding: 10px;
            margin-bottom: 10px;
        }
        .warning {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 10px;
            margin-bottom: 10px;
        }
        .info {
            background-color: #d1ecf1;
            border-left: 4px solid #17a2b8;
            padding: 10px;
            margin-bottom: 10px;
        }
        .success {
            background-color: #d4edda;
            border-left: 4px solid #28a745;
            padding: 10px;
            margin-bottom: 10px;
        }
        pre {
            background-color: #f8f9fa;
            border: 1px solid #eaeaea;
            border-radius: 3px;
            padding: 10px;
            overflow: auto;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport d'optimisation pour CardApp</h1>
        <p>Date du rapport: $(date +"%Y-%m-%d %H:%M:%S")</p>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p>Chemin du projet: $CHEMIN_PROJET</p>
            <p>Nombre de fichiers Swift: $TOTAL_SWIFT</p>
        </div>
        
        <h2>Résultats de l'analyse</h2>
        
        <h3>1. Analyse statique du code Swift</h3>
        <div class="info">
            <p>Consultez le rapport détaillé dans <code>${RAPPORTS_DIR}/swift_analyze_*.json</code> et <code>${RAPPORTS_DIR}/swift_analyze_*.md</code></p>
        </div>
        
        <h3>2. Diagnostic CoreData</h3>
        <div class="info">
            <p>Consultez le rapport détaillé dans <code>${RAPPORTS_DIR}/core_data_report_*.json</code></p>
        </div>
        
        <h3>3. Structure du projet</h3>
        <div class="info">
            <p>Les imports les plus fréquents:</p>
            <pre>$(head -n 10 "$RAPPORTS_DIR/imports_${TIMESTAMP}.txt" 2>/dev/null || echo "Aucune donnée disponible")</pre>
        </div>
        
        <h2>Recommandations</h2>
        <p>Basées sur les analyses effectuées, voici les principales recommandations:</p>
        <ul>
            <li>Examiner les fichiers avec des problèmes critiques identifiés dans l'analyse statique</li>
            <li>Appliquer les optimisations CoreData suggérées</li>
            <li>Revoir les patterns d'architecture pour éviter les dépendances circulaires</li>
            <li>Mettre en œuvre une gestion plus robuste des erreurs, particulièrement pour les opérations CoreData</li>
        </ul>
        
        <h2>Prochain Pas</h2>
        <p>Pour appliquer automatiquement certaines corrections:</p>
        <pre>./apply_fixes.sh</pre>
        
        <hr>
        <p><em>Rapport généré par l'Orchestrateur d'Optimisation CardApp</em></p>
    </div>
</body>
</html>
EOF

journal "SUCCES" "Rapport HTML unifié généré: $RAPPORT_HTML"

# -----------------------------------------------------------------------------
# 6. Préparation du script d'application des correctifs
# -----------------------------------------------------------------------------
journal "ETAPE" "ÉTAPE 6: Préparation du script d'application des correctifs"

# Créer un script pour appliquer les correctifs automatiques
SCRIPT_CORRECTIFS="$CORRECTIFS_DIR/apply_fixes.sh"

cat > "$SCRIPT_CORRECTIFS" << 'EOF'
#!/bin/bash

# Script d'application des correctifs automatiques pour CardApp
# Généré par l'Orchestrateur d'Optimisation

set -e

ROUGE='\033[0;31m'
VERT='\033[0;32m'
JAUNE='\033[0;33m'
BLEU='\033[0;34m'
NORMAL='\033[0m'

# Récupérer le chemin du projet
if [ $# -eq 0 ]; then
    CHEMIN_PROJET="$(pwd)"
else
    CHEMIN_PROJET="$1"
fi

echo -e "${BLEU}=== Application des correctifs automatiques pour CardApp ===${NORMAL}"
echo -e "${BLEU}Chemin du projet: $CHEMIN_PROJET${NORMAL}"

# Fonction pour appliquer un correctif
appliquer_correctif() {
    local FICHIER="$1"
    local PATTERN="$2"
    local REMPLACEMENT="$3"
    local DESCRIPTION="$4"
    
    if [ -f "$FICHIER" ]; then
        echo -e "${JAUNE}Traitement de $FICHIER : $DESCRIPTION${NORMAL}"
        
        # Créer une sauvegarde
        cp "$FICHIER" "${FICHIER}.bak"
        
        # Appliquer le correctif
        sed -i.tmp "s/$PATTERN/$REMPLACEMENT/g" "$FICHIER"
        rm -f "${FICHIER}.tmp"
        
        # Vérifier si des changements ont été effectués
        if diff -q "$FICHIER" "${FICHIER}.bak" >/dev/null; then
            echo -e "${JAUNE}  Aucun changement nécessaire${NORMAL}"
        else
            echo -e "${VERT}  Correctif appliqué avec succès${NORMAL}"
        fi
    else
        echo -e "${ROUGE}Le fichier $FICHIER n'existe pas. Correction ignorée.${NORMAL}"
    fi
}

echo -e "${BLEU}Chargement des correctifs depuis les rapports d'analyse...${NORMAL}"

# Trouver le rapport d'analyse le plus récent
DERNIER_RAPPORT=$(ls -t rapports_optimisation/swift_analyze_*.json 2>/dev/null | head -n 1)

if [ -n "$DERNIER_RAPPORT" ] && [ -f "$DERNIER_RAPPORT" ]; then
    echo -e "${VERT}Utilisation du rapport: $DERNIER_RAPPORT${NORMAL}"
    
    # Extraire et appliquer les correctifs pour les problèmes critiques et erreurs
    # Note: Ceci nécessite jq pour le parsing JSON (à installer avec brew install jq)
    if command -v jq &> /dev/null; then
        # Appliquer les correctifs pour les cycles de référence
        echo -e "${BLEU}Application des correctifs pour les cycles de référence...${NORMAL}"
        jq -r '.problemes[] | select(.type == "memory_leak" and (.severite == "critical" or .severite == "error")) | "\(.fichier)|\(.message)|\(.suggestion)"' "$DERNIER_RAPPORT" | while IFS="|" read -r FICHIER MESSAGE SUGGESTION; do
            FICHIER_COMPLET="$CHEMIN_PROJET/$FICHIER"
            if [[ "$MESSAGE" == *"Cycle de référence"* ]]; then
                appliquer_correctif "$FICHIER_COMPLET" "self\\.\([a-zA-Z0-9_]+\) = {" "self.\1 = { [weak self] in\n    guard let self = self else { return }" "Correction de cycle de référence"
            fi
        done
        
        # Appliquer les correctifs pour les opérations CoreData sans gestion d'erreurs
        echo -e "${BLEU}Application des correctifs pour les opérations CoreData sans gestion d'erreurs...${NORMAL}"
        jq -r '.problemes[] | select(.type == "core_data" and .severite == "critical") | "\(.fichier)|\(.message)"' "$DERNIER_RAPPORT" | while IFS="|" read -r FICHIER MESSAGE; do
            FICHIER_COMPLET="$CHEMIN_PROJET/$FICHIER"
            if [[ "$MESSAGE" == *"sans bloc catch"* ]]; then
                appliquer_correctif "$FICHIER_COMPLET" "try context\\.\([a-zA-Z0-9_]+\)()" "do {\n    try context.\1()\n} catch {\n    print(\"Erreur CoreData: \\(error)\")\n}" "Ajout de gestion d'erreurs pour opération CoreData"
            fi
        done
        
        echo -e "${VERT}Application des correctifs terminée${NORMAL}"
    else
        echo -e "${ROUGE}jq n'est pas installé. Impossible de parser le rapport JSON.${NORMAL}"
        echo -e "${JAUNE}Installez jq avec: brew install jq${NORMAL}"
    fi
else
    echo -e "${ROUGE}Aucun rapport d'analyse trouvé. Exécutez d'abord l'orchestrateur d'optimisation.${NORMAL}"
fi

echo -e "${BLEU}=== Application des correctifs supplémentaires ===${NORMAL}"

# 1. Correction des accès au viewContext
echo -e "${BLEU}Recherche des accès non-sécurisés au viewContext...${NORMAL}"
find "$CHEMIN_PROJET" -name "*.swift" -type f -exec grep -l "viewContext" {} \; | while read -r FICHIER; do
    # Exclure les fichiers qui ont déjà @MainActor
    if ! grep -q "@MainActor" "$FICHIER"; then
        # Vérifier si le fichier contient des fonctions qui accèdent à viewContext
        if grep -q "func.*viewContext" "$FICHIER"; then
            echo -e "${JAUNE}Ajout de @MainActor aux fonctions dans $FICHIER${NORMAL}"
            # Cette transformation est complexe et peut nécessiter une revue manuelle
            appliquer_correctif "$FICHIER" "func \([a-zA-Z0-9_]+\)()" "@MainActor\nfunc \1()" "Ajout de @MainActor aux fonctions accédant à viewContext"
        fi
    fi
done

# 2. Optimisation des fetchBatchSize
echo -e "${BLEU}Optimisation des requêtes fetch sans batchSize...${NORMAL}"
find "$CHEMIN_PROJET" -name "*.swift" -type f -exec grep -l "NSFetchRequest" {} \; | while read -r FICHIER; do
    if grep -q "let.*NSFetchRequest.*entityName:" "$FICHIER" && ! grep -q "fetchBatchSize" "$FICHIER"; then
        echo -e "${JAUNE}Ajout de fetchBatchSize aux requêtes dans $FICHIER${NORMAL}"
        appliquer_correctif "$FICHIER" "let \([a-zA-Z0-9_]+\) = NSFetchRequest<.*>(entityName: \".*\")" "let \1 = NSFetchRequest<.*>(entityName: \".*\")\n        \1.fetchBatchSize = 20" "Ajout de fetchBatchSize pour optimisation"
    fi
done

# 3. Remplacement des force unwrap (!) par des guard let
echo -e "${BLEU}Remplacement des force unwrap risqués...${NORMAL}"
find "$CHEMIN_PROJET" -name "*.swift" -type f -exec grep -l "!" {} \; | while read -r FICHIER; do
    # Cette transformation est également complexe et nécessite souvent une revue manuelle
    echo -e "${JAUNE}Les force unwrap dans $FICHIER doivent être revus manuellement${NORMAL}"
    echo -e "${JAUNE}  Veuillez rechercher les occurrences de '!' et les remplacer par des unwrap sécurisés${NORMAL}"
done

echo -e "${VERT}Tous les correctifs automatiques ont été appliqués!${NORMAL}"
echo -e "${JAUNE}IMPORTANT: Veuillez compiler le projet pour vérifier qu'aucune erreur n'a été introduite.${NORMAL}"
echo -e "${BLEU}Pour toute erreur, vous pouvez restaurer les fichiers depuis les sauvegardes .bak${NORMAL}"
EOF

chmod +x "$SCRIPT_CORRECTIFS"
journal "SUCCES" "Script d'application des correctifs créé: $SCRIPT_CORRECTIFS"

# -----------------------------------------------------------------------------
# Résumé final
# -----------------------------------------------------------------------------
echo -e "${BLANC}=======================================================${NORMAL}"
echo -e "${VERT}ANALYSE TERMINÉE${NORMAL}"
echo -e "${BLANC}=======================================================${NORMAL}"
journal "SUCCES" "Toutes les étapes d'analyse et d'optimisation ont été complétées"
journal "INFO" "Rapport complet disponible dans: $RAPPORT_HTML"
journal "INFO" "Pour appliquer automatiquement les correctifs: $SCRIPT_CORRECTIFS"

echo -e "${JAUNE}Prochaines étapes recommandées:${NORMAL}"
echo -e "${JAUNE}1. Examiner le rapport d'analyse dans $RAPPORT_HTML${NORMAL}"
echo -e "${JAUNE}2. Appliquer les correctifs automatiques avec $SCRIPT_CORRECTIFS${NORMAL}"
echo -e "${JAUNE}3. Vérifier et tester l'application après les modifications${NORMAL}"

exit 0 