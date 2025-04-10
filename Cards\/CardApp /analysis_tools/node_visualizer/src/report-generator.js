/**
 * Module de génération de rapport HTML pour l'analyseur CardApp
 */

const fs = require('fs-extra');
const path = require('path');
const ejs = require('ejs');
const chalk = require('chalk');
const highlightJs = require('highlight.js');

class ReportGenerator {
  constructor(options = {}) {
    this.options = {
      outputPath: options.outputPath || 'cardapp_analysis_report.html',
      theme: options.theme || 'light',
      verbose: options.verbose || false,
      generateFixSuggestions: options.generateFixSuggestions || false,
      templatesDir: path.join(__dirname, 'templates'),
      assetsDir: path.join(__dirname, 'assets')
    };
    
    this.reports = {
      python: null,
      swift: null,
      rust: null
    };
    
    this.combinedIssues = [];
    this.statistics = {};
    this.fixSuggestions = [];
    this.hotspotFiles = [];
  }
  
  /**
   * Ajoute un rapport à l'ensemble
   */
  addReport(type, data) {
    if (!['python', 'swift', 'rust'].includes(type)) {
      throw new Error(`Type de rapport non supporté: ${type}`);
    }
    
    this.reports[type] = data;
    
    if (this.options.verbose) {
      console.log(chalk.gray(`📄 Rapport ${type} ajouté avec ${this._getIssueCount(data)} problèmes`));
    }
  }
  
  /**
   * Génère le rapport HTML complet
   */
  async generateReport() {
    // Préparer les données
    this._processReports();
    
    // Charger les templates
    const templatePath = path.join(__dirname, 'templates', 'report.ejs');
    
    // S'assurer que le répertoire de sortie existe
    await fs.ensureDir(path.dirname(this.options.outputPath));
    
    // Créer un objet avec toutes les données pour le template
    const templateData = {
      title: 'Rapport d\'analyse CardApp',
      timestamp: new Date().toISOString(),
      theme: this.options.theme,
      issues: this.combinedIssues,
      statistics: this.statistics,
      hotspotFiles: this.hotspotFiles,
      reports: this.reports,
      highlightCode: (code, language) => {
        if (!code) return '';
        try {
          if (language) {
            return highlightJs.highlight(code, { language }).value;
          } else {
            return highlightJs.highlightAuto(code).value;
          }
        } catch (error) {
          return code;
        }
      }
    };
    
    // Générer le HTML
    let htmlContent;
    try {
      htmlContent = await this._renderTemplate('report.ejs', templateData);
    } catch (error) {
      throw new Error(`Erreur lors du rendu du template: ${error.message}`);
    }
    
    // Écrire le fichier HTML
    try {
      await fs.writeFile(this.options.outputPath, htmlContent);
    } catch (error) {
      throw new Error(`Erreur lors de l'écriture du fichier HTML: ${error.message}`);
    }
    
    // Copier les assets nécessaires
    try {
      await this._copyAssets();
    } catch (error) {
      console.warn(chalk.yellow(`⚠️ Erreur lors de la copie des assets: ${error.message}`));
    }
    
    return this.options.outputPath;
  }
  
  /**
   * Génère des scripts de correction basés sur les suggestions
   */
  async generateFixScripts() {
    if (this.fixSuggestions.length === 0) {
      console.warn(chalk.yellow('⚠️ Aucune suggestion de correction trouvée.'));
      return null;
    }
    
    const fixScriptsDir = path.join(path.dirname(this.options.outputPath), 'fix_scripts');
    await fs.ensureDir(fixScriptsDir);
    
    // Générer le script principal
    const mainScriptPath = path.join(fixScriptsDir, 'apply_fixes.sh');
    let mainScript = '#!/bin/bash\n\n';
    mainScript += '# Script de correction automatique généré par CardApp Analysis Visualizer\n';
    mainScript += `# Date: ${new Date().toISOString()}\n\n`;
    mainScript += 'set -e\n\n';
    mainScript += 'echo "🔧 Application des corrections automatiques..."\n\n';
    
    // Classer les suggestions par type
    const suggestionsByType = {};
    this.fixSuggestions.forEach(suggestion => {
      if (!suggestionsByType[suggestion.type]) {
        suggestionsByType[suggestion.type] = [];
      }
      suggestionsByType[suggestion.type].push(suggestion);
    });
    
    // Créer un script pour chaque type de suggestion
    for (const [type, suggestions] of Object.entries(suggestionsByType)) {
      const scriptPath = path.join(fixScriptsDir, `fix_${type}.sh`);
      let script = '#!/bin/bash\n\n';
      script += `# Corrections pour les problèmes de type: ${type}\n\n`;
      
      suggestions.forEach(suggestion => {
        script += `# [${suggestion.severity}] ${suggestion.file}\n`;
        script += `# ${suggestion.message}\n`;
        script += `${suggestion.fixScript}\n\n`;
      });
      
      await fs.writeFile(scriptPath, script);
      await fs.chmod(scriptPath, 0o755);
      
      mainScript += `echo "📝 Application des corrections pour ${type}..."\n`;
      mainScript += `bash "${path.basename(scriptPath)}"\n\n`;
    }
    
    mainScript += 'echo "✅ Toutes les corrections ont été appliquées."\n';
    
    await fs.writeFile(mainScriptPath, mainScript);
    await fs.chmod(mainScriptPath, 0o755);
    
    return fixScriptsDir;
  }
  
  /**
   * Traite tous les rapports pour créer une vue unifiée
   */
  _processReports() {
    // Traiter les problèmes de tous les rapports
    this._processIssues();
    
    // Agréger les statistiques
    this._aggregateStatistics();
    
    // Identifier les fichiers critiques
    this._identifyHotspotFiles();
    
    // Générer des suggestions de correction
    if (this.options.generateFixSuggestions) {
      this._generateFixSuggestions();
    }
  }
  
  /**
   * Traite les problèmes de tous les rapports en un format unifié
   */
  _processIssues() {
    // Réinitialiser la liste combinée
    this.combinedIssues = [];
    
    // Traiter le rapport Python
    if (this.reports.python && this.reports.python.issues) {
      this.reports.python.issues.forEach(issue => {
        this.combinedIssues.push({
          id: `python-${this.combinedIssues.length}`,
          file: issue.file_path,
          line: issue.line_number,
          type: issue.issue_type,
          severity: issue.severity,
          severityValue: issue.severity_value || this._getSeverityValue(issue.severity),
          message: issue.message,
          snippet: issue.snippet,
          suggestion: issue.suggestion,
          source: 'python'
        });
      });
    }
    
    // Traiter le rapport Swift
    if (this.reports.swift && this.reports.swift.issues) {
      this.reports.swift.issues.forEach(issue => {
        this.combinedIssues.push({
          id: `swift-${this.combinedIssues.length}`,
          file: this.reports.swift.model_path,
          entity: issue.entity,
          attribute: issue.attribute,
          relationship: issue.relationship,
          type: issue.issue_type,
          severity: issue.severity,
          severityValue: issue.severity_value || this._getSeverityValue(issue.severity),
          message: issue.message,
          suggestion: issue.suggestion,
          impact: issue.impact,
          source: 'swift'
        });
      });
    }
    
    // Traiter le rapport Rust
    if (this.reports.rust && this.reports.rust.issues) {
      this.reports.rust.issues.forEach(issue => {
        this.combinedIssues.push({
          id: `rust-${this.combinedIssues.length}`,
          file: issue.file_path,
          line: issue.line_number,
          type: issue.issue_type,
          severity: issue.severity,
          severityValue: issue.severity_value || this._getSeverityValue(issue.severity),
          message: issue.message,
          snippet: issue.snippet,
          suggestion: issue.suggestion,
          complexity: issue.complexity,
          source: 'rust'
        });
      });
    }
    
    // Trier les problèmes par sévérité puis par fichier
    this.combinedIssues.sort((a, b) => {
      if (b.severityValue !== a.severityValue) {
        return b.severityValue - a.severityValue;
      }
      return a.file.localeCompare(b.file);
    });
  }
  
  /**
   * Agrège les statistiques de tous les rapports
   */
  _aggregateStatistics() {
    this.statistics = {
      totalIssues: this.combinedIssues.length,
      issuesBySeverity: {
        CRITICAL: 0,
        HIGH: 0,
        MEDIUM: 0,
        LOW: 0
      },
      issuesByType: {},
      issuesBySource: {
        python: 0,
        swift: 0,
        rust: 0
      }
    };
    
    // Compter les problèmes par sévérité et type
    this.combinedIssues.forEach(issue => {
      // Par sévérité
      this.statistics.issuesBySeverity[issue.severity] = 
        (this.statistics.issuesBySeverity[issue.severity] || 0) + 1;
      
      // Par type
      this.statistics.issuesByType[issue.type] = 
        (this.statistics.issuesByType[issue.type] || 0) + 1;
      
      // Par source
      this.statistics.issuesBySource[issue.source] += 1;
    });
    
    // Ajouter des statistiques spécifiques de chaque rapport
    if (this.reports.python && this.reports.python.stats) {
      this.statistics.python = this.reports.python.stats;
    }
    
    if (this.reports.swift && this.reports.swift.stats) {
      this.statistics.swift = this.reports.swift.stats;
    }
    
    if (this.reports.rust && this.reports.rust.stats) {
      this.statistics.rust = this.reports.rust.stats;
    }
  }
  
  /**
   * Identifie les fichiers avec le plus de problèmes ou les plus critiques
   */
  _identifyHotspotFiles() {
    const fileMap = new Map();
    
    // Compter les problèmes par fichier et leur sévérité
    this.combinedIssues.forEach(issue => {
      const filePath = issue.file;
      if (!fileMap.has(filePath)) {
        fileMap.set(filePath, {
          path: filePath,
          name: path.basename(filePath),
          issueCount: 0,
          criticalCount: 0,
          highCount: 0,
          score: 0,
          issues: []
        });
      }
      
      const fileData = fileMap.get(filePath);
      fileData.issueCount += 1;
      fileData.issues.push(issue);
      
      if (issue.severity === 'CRITICAL') {
        fileData.criticalCount += 1;
        fileData.score += 10;
      } else if (issue.severity === 'HIGH') {
        fileData.highCount += 1;
        fileData.score += 5;
      } else if (issue.severity === 'MEDIUM') {
        fileData.score += 2;
      } else {
        fileData.score += 1;
      }
    });
    
    // Convertir la Map en tableau et trier par score
    this.hotspotFiles = Array.from(fileMap.values())
      .sort((a, b) => b.score - a.score)
      .slice(0, 10); // Top 10 des fichiers problématiques
  }
  
  /**
   * Génère des suggestions de correction basées sur les problèmes
   */
  _generateFixSuggestions() {
    this.fixSuggestions = [];
    
    // Traiter les problèmes qui ont des suggestions
    this.combinedIssues.forEach(issue => {
      if (issue.suggestion) {
        // Tenter de générer un script de correction
        const fixScript = this._createFixScript(issue);
        if (fixScript) {
          this.fixSuggestions.push({
            file: issue.file,
            type: issue.type,
            severity: issue.severity,
            message: issue.message,
            fixScript: fixScript
          });
        }
      }
    });
  }
  
  /**
   * Crée un script de correction pour un problème spécifique
   */
  _createFixScript(issue) {
    // Les scripts de correction dépendent du type de problème
    switch (issue.type) {
      case 'weak_self_missing':
        return this._createWeakSelfFix(issue);
      case 'missing_index':
        return this._createMissingIndexFix(issue);
      case 'coredata_error_handling':
        return this._createCoreDataErrorHandlingFix(issue);
      case 'race_condition':
        return this._createRaceConditionFix(issue);
      default:
        // Pour les autres types, simplement commenter la suggestion
        return `# TODO: ${issue.suggestion}\n# Fichier: ${issue.file}\n# Ligne: ${issue.line || 'N/A'}`;
    }
  }
  
  /**
   * Crée un script pour ajouter [weak self] manquant
   */
  _createWeakSelfFix(issue) {
    if (!issue.file || !issue.line || !issue.snippet) {
      return null;
    }
    
    return `# Ajouter [weak self] à la closure
if [[ -f "${issue.file}" ]]; then
  # Recherche la ligne exacte et ajoute [weak self]
  sed -i '' '${issue.line}s/{/{ [weak self] in/' "${issue.file}"
  echo "✅ Corrigé: Ajout de [weak self] dans ${issue.file} à la ligne ${issue.line}"
else
  echo "❌ Fichier non trouvé: ${issue.file}"
fi`;
  }
  
  /**
   * Crée un script pour ajouter un index manquant
   */
  _createMissingIndexFix(issue) {
    if (!issue.entity || !issue.attribute) {
      return null;
    }
    
    return `# Ajouter un index pour ${issue.entity}.${issue.attribute}
echo "⚠️ Modification manuelle requise: Ouvrir le modèle CoreData dans Xcode et ajouter un index pour l'attribut '${issue.attribute}' de l'entité '${issue.entity}'."`;
  }
  
  /**
   * Crée un script pour ajouter la gestion d'erreur à CoreData
   */
  _createCoreDataErrorHandlingFix(issue) {
    if (!issue.file || !issue.line) {
      return null;
    }
    
    return `# Ajouter la gestion d'erreur pour les requêtes CoreData
if [[ -f "${issue.file}" ]]; then
  # Ceci est une approximation - un changement manuel peut être nécessaire
  sed -i '' '${issue.line}s/context.fetch(/try context.fetch(/' "${issue.file}"
  # Vérifier si la ligne est dans un bloc do-catch
  grep -B5 -A0 "${issue.line}" "${issue.file}" | grep -q "do {" || echo "⚠️ Avertissement: La ligne ${issue.line} doit être dans un bloc do-catch pour la gestion d'erreur"
  echo "✅ Corrigé: Ajout de 'try' pour la requête fetch dans ${issue.file} à la ligne ${issue.line}"
else
  echo "❌ Fichier non trouvé: ${issue.file}"
fi`;
  }
  
  /**
   * Crée un script pour corriger une condition de concurrence
   */
  _createRaceConditionFix(issue) {
    if (!issue.file || !issue.line) {
      return null;
    }
    
    return `# Ajouter une protection pour la variable ${issue.message.match(/Variable '(\w+)'/)?.[1] || ''}
echo "⚠️ Modification manuelle requise: Dans ${issue.file} à la ligne ${issue.line}, une variable est potentiellement accédée de manière concurrente."
echo "   Suggestion: ${issue.suggestion}"`;
  }
  
  /**
   * Charge et rend un template EJS
   */
  async _renderTemplate(templateName, data) {
    const templatePath = path.join(__dirname, 'templates', templateName);
    return new Promise((resolve, reject) => {
      ejs.renderFile(templatePath, data, {}, (err, str) => {
        if (err) {
          reject(err);
        } else {
          resolve(str);
        }
      });
    });
  }
  
  /**
   * Copie les assets nécessaires dans le répertoire de sortie
   */
  async _copyAssets() {
    const assetsDir = path.join(__dirname, 'assets');
    const outputDir = path.dirname(this.options.outputPath);
    const targetAssetsDir = path.join(outputDir, 'assets');
    
    // Vérifier si le répertoire d'assets existe
    if (await fs.pathExists(assetsDir)) {
      await fs.ensureDir(targetAssetsDir);
      await fs.copy(assetsDir, targetAssetsDir);
    }
  }
  
  /**
   * Renvoie le nombre de problèmes dans un rapport
   */
  _getIssueCount(reportData) {
    if (reportData.issues && Array.isArray(reportData.issues)) {
      return reportData.issues.length;
    }
    if (reportData.issues_count !== undefined) {
      return reportData.issues_count;
    }
    return 0;
  }
  
  /**
   * Convertit une sévérité textuelle en valeur numérique
   */
  _getSeverityValue(severity) {
    const severityMap = {
      'CRITICAL': 4,
      'HIGH': 3,
      'MEDIUM': 2,
      'LOW': 1,
      'INFO': 0
    };
    
    return severityMap[severity] || 0;
  }
}

module.exports = ReportGenerator; 