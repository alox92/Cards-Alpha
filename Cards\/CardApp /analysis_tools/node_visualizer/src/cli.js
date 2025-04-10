#!/usr/bin/env node

/**
 * CLI pour le visualiseur de rapport d'analyse CardApp
 * Ce script prend les fichiers JSON générés par les outils d'analyse et crée un rapport HTML interactif.
 */

const fs = require('fs-extra');
const path = require('path');
const glob = require('glob');
const { program } = require('commander');
const chalk = require('chalk');
const ReportGenerator = require('./report-generator');
const { startServer } = require('./server');

// Configuration de l'interface en ligne de commande
program
  .name('cardapp-visualizer')
  .description('Génère un rapport visuel interactif à partir des résultats d\'analyse du projet CardApp')
  .version('1.0.0')
  .option('-p, --python-report <file>', 'Fichier de rapport de l\'analyseur Python')
  .option('-s, --swift-report <file>', 'Fichier de rapport de l\'analyseur Swift CoreData')
  .option('-r, --rust-report <file>', 'Fichier de rapport de l\'analyseur de performance Rust')
  .option('-d, --reports-dir <directory>', 'Répertoire contenant les rapports JSON (alternative à la spécification individuelle)')
  .option('-o, --output <file>', 'Chemin du fichier HTML de sortie', 'cardapp_analysis_report.html')
  .option('-i, --interactive', 'Démarrer un serveur web interactif pour visualiser le rapport', false)
  .option('-t, --theme <theme>', 'Thème à utiliser (light/dark)', 'light')
  .option('-v, --verbose', 'Afficher des informations détaillées lors de la génération du rapport')
  .option('--open', 'Ouvrir automatiquement le rapport dans le navigateur par défaut', false)
  .option('--port <number>', 'Port pour le serveur interactif', '3000')
  .option('--fix-suggestions', 'Générer des scripts de correction automatique', false);

program.parse();

const options = program.opts();

// Fonction principale
async function main() {
  console.log(chalk.blue('🔍 CardApp Analysis Visualizer 🔍'));
  
  // Vérifier les paramètres d'entrée
  let reportFiles = [];
  
  if (options.reportsDir) {
    const directory = path.resolve(options.reportsDir);
    if (!fs.existsSync(directory)) {
      console.error(chalk.red(`❌ Le répertoire ${directory} n'existe pas.`));
      process.exit(1);
    }
    
    try {
      const jsonFiles = glob.sync(path.join(directory, '*.json'));
      reportFiles = jsonFiles;
      
      if (options.verbose) {
        console.log(chalk.gray(`📁 Trouvé ${jsonFiles.length} fichiers JSON dans ${directory}`));
        jsonFiles.forEach(file => console.log(chalk.gray(`   - ${path.basename(file)}`)));
      }
    } catch (error) {
      console.error(chalk.red(`❌ Erreur lors de la recherche de fichiers dans ${directory}: ${error.message}`));
      process.exit(1);
    }
  } else {
    // Collecter les rapports spécifiés individuellement
    if (options.pythonReport) reportFiles.push(path.resolve(options.pythonReport));
    if (options.swiftReport) reportFiles.push(path.resolve(options.swiftReport));
    if (options.rustReport) reportFiles.push(path.resolve(options.rustReport));
  }
  
  if (reportFiles.length === 0) {
    console.error(chalk.red('❌ Aucun fichier de rapport spécifié. Utilisez --python-report, --swift-report, --rust-report ou --reports-dir.'));
    program.help();
  }
  
  // Vérifier que tous les fichiers existent
  const missingFiles = reportFiles.filter(file => !fs.existsSync(file));
  if (missingFiles.length > 0) {
    console.error(chalk.red('❌ Les fichiers suivants n\'existent pas:'));
    missingFiles.forEach(file => console.error(chalk.red(`   - ${file}`)));
    process.exit(1);
  }
  
  // Créer le générateur de rapport
  const outputPath = path.resolve(options.output);
  const generator = new ReportGenerator({
    outputPath,
    theme: options.theme,
    verbose: options.verbose,
    generateFixSuggestions: options.fixSuggestions
  });
  
  // Charger les rapports
  console.log(chalk.blue('📊 Chargement des rapports d\'analyse...'));
  reportFiles.forEach(file => {
    try {
      const reportData = fs.readJsonSync(file);
      const reportType = detectReportType(reportData, file);
      if (reportType) {
        generator.addReport(reportType, reportData);
        console.log(chalk.green(`✅ Chargé: ${path.basename(file)} (${reportType})`));
      } else {
        console.warn(chalk.yellow(`⚠️ Type de rapport non reconnu: ${path.basename(file)}`));
      }
    } catch (error) {
      console.error(chalk.red(`❌ Erreur lors du chargement de ${file}: ${error.message}`));
    }
  });
  
  // Générer le rapport
  try {
    console.log(chalk.blue('🔧 Génération du rapport HTML...'));
    await generator.generateReport();
    console.log(chalk.green(`✅ Rapport généré avec succès: ${outputPath}`));
    
    // Générer des scripts de correction si demandé
    if (options.fixSuggestions) {
      console.log(chalk.blue('🔧 Génération des scripts de correction...'));
      const fixScriptsPath = await generator.generateFixScripts();
      console.log(chalk.green(`✅ Scripts de correction générés dans: ${fixScriptsPath}`));
    }
    
    // Démarrer le serveur interactif si demandé
    if (options.interactive) {
      const port = parseInt(options.port, 10);
      const server = await startServer(outputPath, port);
      const serverUrl = `http://localhost:${port}`;
      console.log(chalk.blue(`🚀 Serveur interactif démarré sur ${serverUrl}`));
      
      if (options.open) {
        const open = require('open');
        await open(serverUrl);
        console.log(chalk.gray('🌐 Ouverture du rapport dans le navigateur...'));
      }
      
      console.log(chalk.gray('Appuyez sur Ctrl+C pour arrêter le serveur.'));
    } else if (options.open) {
      const open = require('open');
      await open(`file://${outputPath}`);
      console.log(chalk.gray('🌐 Ouverture du rapport dans le navigateur...'));
    }
  } catch (error) {
    console.error(chalk.red(`❌ Erreur lors de la génération du rapport: ${error.message}`));
    if (options.verbose) {
      console.error(error);
    }
    process.exit(1);
  }
}

/**
 * Détecte le type de rapport en fonction de son contenu
 */
function detectReportType(data, filePath) {
  const fileName = path.basename(filePath).toLowerCase();
  
  // Détection basée sur le nom du fichier
  if (fileName.includes('python') || fileName.includes('swift_analysis')) {
    return 'python';
  } else if (fileName.includes('coredata') || fileName.includes('swift')) {
    return 'swift';
  } else if (fileName.includes('rust') || fileName.includes('performance')) {
    return 'rust';
  }
  
  // Détection basée sur le contenu
  if (data.issues_by_type && 
      (data.issues_by_type.weak_self_missing !== undefined || 
       data.issues_by_type.memory_leak !== undefined)) {
    return 'python';
  } else if (data.issues && data.model_path) {
    return 'swift';
  } else if (data.performance_metrics || data.hotspot_files) {
    return 'rust';
  }
  
  return null;
}

// Exécuter le programme principal
main().catch(error => {
  console.error(chalk.red(`❌ Erreur fatale: ${error.message}`));
  process.exit(1);
}); 