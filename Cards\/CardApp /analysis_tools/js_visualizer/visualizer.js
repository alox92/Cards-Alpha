#!/usr/bin/env node

/**
 * CardApp - Visualiseur de Rapport Interactif
 * Ce script génère un rapport HTML interactif à partir des résultats d'analyse
 * des différents outils de diagnostic (Python, Swift, Rust).
 */

const fs = require('fs');
const path = require('path');
const util = require('util');

// Promisify FS operations
const readFile = util.promisify(fs.readFile);
const writeFile = util.promisify(fs.writeFile);
const mkdir = util.promisify(fs.mkdir);

// Configuration
const CONFIG = {
  reportsDir: process.argv[2] || './reports',
  outputDir: process.argv[3] || './output',
  outputFile: 'rapport_analyse.html',
  pythonReport: 'python_analysis.json',
  swiftReport: 'swift_coredata.json',
  rustReport: 'rust_performance.json'
};

// Structure pour stocker toutes les données d'analyse
const analysisData = {
  pythonAnalysis: null,
  swiftAnalysis: null,
  rustAnalysis: null,
  summary: {
    totalIssues: 0,
    criticalIssues: 0,
    highIssues: 0,
    mediumIssues: 0,
    lowIssues: 0,
    fixableAutomatically: 0,
    topHotspots: []
  }
};

/**
 * Point d'entrée principal du script
 */
async function main() {
  console.log('⏳ Démarrage de la génération du rapport interactif...');
  
  try {
    // Créer le répertoire de sortie s'il n'existe pas
    await mkdir(CONFIG.outputDir, { recursive: true });
    
    // Charger les données d'analyse
    await loadAnalysisData();
    
    // Générer le résumé global
    generateSummary();
    
    // Générer le HTML
    const htmlContent = generateHTML();
    
    // Écrire le fichier HTML
    const outputPath = path.join(CONFIG.outputDir, CONFIG.outputFile);
    await writeFile(outputPath, htmlContent, 'utf8');
    
    console.log(`✅ Rapport généré avec succès à ${outputPath}`);
  } catch (error) {
    console.error('❌ Erreur lors de la génération du rapport:', error);
    process.exit(1);
  }
}

/**
 * Charge les données d'analyse depuis les fichiers JSON
 */
async function loadAnalysisData() {
  try {
    // Charger les rapports Python
    const pythonPath = path.join(CONFIG.reportsDir, CONFIG.pythonReport);
    if (fs.existsSync(pythonPath)) {
      const pythonData = await readFile(pythonPath, 'utf8');
      analysisData.pythonAnalysis = JSON.parse(pythonData);
      console.log('✅ Données d\'analyse Python chargées');
    } else {
      console.log('⚠️ Aucune donnée d\'analyse Python trouvée');
    }
    
    // Charger les rapports Swift
    const swiftPath = path.join(CONFIG.reportsDir, CONFIG.swiftReport);
    if (fs.existsSync(swiftPath)) {
      const swiftData = await readFile(swiftPath, 'utf8');
      analysisData.swiftAnalysis = JSON.parse(swiftData);
      console.log('✅ Données d\'analyse Swift chargées');
    } else {
      console.log('⚠️ Aucune donnée d\'analyse Swift trouvée');
    }
    
    // Charger les rapports Rust
    const rustPath = path.join(CONFIG.reportsDir, CONFIG.rustReport);
    if (fs.existsSync(rustPath)) {
      const rustData = await readFile(rustPath, 'utf8');
      analysisData.rustAnalysis = JSON.parse(rustData);
      console.log('✅ Données d\'analyse Rust chargées');
    } else {
      console.log('⚠️ Aucune donnée d\'analyse Rust trouvée');
    }
  } catch (error) {
    console.error('❌ Erreur lors du chargement des données d\'analyse:', error);
    throw error;
  }
}

/**
 * Génère un résumé global des problèmes
 */
function generateSummary() {
  // Collecter les données du rapport Rust (performance)
  if (analysisData.rustAnalysis) {
    const rustReport = analysisData.rustAnalysis;
    analysisData.summary.totalIssues += rustReport.totalIssues || 0;
    analysisData.summary.criticalIssues += rustReport.issuesBySeverity?.critical || 0;
    analysisData.summary.highIssues += rustReport.issuesBySeverity?.high || 0;
    analysisData.summary.mediumIssues += rustReport.issuesBySeverity?.medium || 0;
    analysisData.summary.lowIssues += rustReport.issuesBySeverity?.low || 0;
    
    // Ajouter les hotspots
    if (rustReport.hotspots && Array.isArray(rustReport.hotspots)) {
      analysisData.summary.topHotspots.push(...rustReport.hotspots);
    }
  }
  
  // Collecter les données du rapport Swift (CoreData)
  if (analysisData.swiftAnalysis) {
    const swiftReport = analysisData.swiftAnalysis;
    analysisData.summary.fixableAutomatically += swiftReport.autoFixableIssues || 0;
    
    // Ajouter d'autres métriques spécifiques à CoreData
    if (swiftReport.issues && Array.isArray(swiftReport.issues)) {
      swiftReport.issues.forEach(issue => {
        analysisData.summary.totalIssues++;
        switch (issue.severity) {
          case 'critical': analysisData.summary.criticalIssues++; break;
          case 'high': analysisData.summary.highIssues++; break;
          case 'medium': analysisData.summary.mediumIssues++; break;
          case 'low': analysisData.summary.lowIssues++; break;
        }
      });
    }
  }
  
  // Collecter les données du rapport Python (analyse statique)
  if (analysisData.pythonAnalysis) {
    const pythonReport = analysisData.pythonAnalysis;
    
    if (pythonReport.issues && Array.isArray(pythonReport.issues)) {
      pythonReport.issues.forEach(issue => {
        analysisData.summary.totalIssues++;
        switch (issue.severity) {
          case 'critical': analysisData.summary.criticalIssues++; break;
          case 'high': analysisData.summary.highIssues++; break;
          case 'medium': analysisData.summary.mediumIssues++; break;
          case 'low': analysisData.summary.lowIssues++; break;
        }
        
        if (issue.autoFixable) {
          analysisData.summary.fixableAutomatically++;
        }
      });
    }
  }
  
  // Trier les hotspots par sévérité et nombre de problèmes
  analysisData.summary.topHotspots.sort((a, b) => {
    // D'abord par nombre de problèmes critiques
    const criticalDiff = (b.criticalIssues || 0) - (a.criticalIssues || 0);
    if (criticalDiff !== 0) return criticalDiff;
    
    // Ensuite par nombre total de problèmes
    return (b.totalIssues || 0) - (a.totalIssues || 0);
  });
  
  // Limiter à 10 hotspots
  analysisData.summary.topHotspots = analysisData.summary.topHotspots.slice(0, 10);
  
  console.log('✅ Résumé généré avec succès');
}

/**
 * Génère le contenu HTML complet du rapport
 */
function generateHTML() {
  return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Rapport d'Analyse CardApp</title>
  <style>
    :root {
      --primary: #1e88e5;
      --critical: #d32f2f;
      --high: #f57c00;
      --medium: #fbc02d;
      --low: #7cb342;
      --bg-dark: #263238;
      --bg-light: #eceff1;
      --text-dark: #37474f;
      --text-light: #eceff1;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', sans-serif;
      margin: 0;
      padding: 0;
      background-color: var(--bg-light);
      color: var(--text-dark);
    }
    
    header {
      background-color: var(--primary);
      color: white;
      padding: 1.5rem;
      box-shadow: 0 3px 5px rgba(0,0,0,0.1);
    }
    
    header h1 {
      margin: 0;
      font-size: 2rem;
    }
    
    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 2rem;
    }
    
    .card {
      background-color: white;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      margin-bottom: 2rem;
      padding: 1.5rem;
    }
    
    .card h2 {
      margin-top: 0;
      border-bottom: 2px solid var(--bg-light);
      padding-bottom: 0.5rem;
      color: var(--primary);
    }
    
    .summary-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 1rem;
      margin-bottom: 2rem;
    }
    
    .summary-item {
      background-color: white;
      border-radius: 8px;
      padding: 1.5rem;
      text-align: center;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .summary-item h3 {
      margin-top: 0;
      font-size: 1rem;
      font-weight: 500;
      color: var(--text-dark);
    }
    
    .summary-item p {
      font-size: 2rem;
      font-weight: 700;
      margin: 0.5rem 0;
    }
    
    .critical { color: var(--critical); }
    .high { color: var(--high); }
    .medium { color: var(--medium); }
    .low { color: var(--low); }
    
    .hotspots-list {
      list-style: none;
      padding: 0;
    }
    
    .hotspot-item {
      border-left: 4px solid var(--primary);
      padding: 1rem;
      margin-bottom: 1rem;
      background-color: var(--bg-light);
      border-radius: 0 4px 4px 0;
    }
    
    .hotspot-item h4 {
      margin: 0 0 0.5rem 0;
    }
    
    .hotspot-item p {
      margin: 0.2rem 0;
    }
    
    .badge {
      display: inline-block;
      padding: 0.2rem 0.5rem;
      border-radius: 4px;
      color: white;
      font-size: 0.8rem;
      margin-right: 0.5rem;
    }
    
    .badge.critical { background-color: var(--critical); }
    .badge.high { background-color: var(--high); }
    .badge.medium { background-color: var(--medium); }
    .badge.low { background-color: var(--low); }
    
    .tab-container {
      margin-top: 2rem;
    }
    
    .tabs {
      display: flex;
      flex-wrap: wrap;
      margin-bottom: 1rem;
    }
    
    .tab {
      padding: 0.8rem 1.5rem;
      background-color: var(--bg-light);
      cursor: pointer;
      border: none;
      border-right: 1px solid white;
    }
    
    .tab:first-child {
      border-radius: 8px 0 0 8px;
    }
    
    .tab:last-child {
      border-radius: 0 8px 8px 0;
      border-right: none;
    }
    
    .tab.active {
      background-color: var(--primary);
      color: white;
    }
    
    .tab-content {
      display: none;
    }
    
    .tab-content.active {
      display: block;
    }
    
    table {
      width: 100%;
      border-collapse: collapse;
    }
    
    table th,
    table td {
      padding: 0.8rem;
      text-align: left;
      border-bottom: 1px solid var(--bg-light);
    }
    
    table th {
      background-color: var(--primary);
      color: white;
    }
    
    table tr:hover {
      background-color: var(--bg-light);
    }
    
    .no-data {
      text-align: center;
      padding: 2rem;
      color: #78909c;
      font-style: italic;
    }
    
    .footer {
      text-align: center;
      padding: 2rem;
      color: #78909c;
      font-size: 0.9rem;
    }
    
    @media (max-width: 768px) {
      .container {
        padding: 1rem;
      }
      
      .summary-grid {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <header>
    <div class="container">
      <h1>Rapport d'Analyse CardApp</h1>
      <p>Généré le ${new Date().toLocaleString('fr-FR')}</p>
    </div>
  </header>
  
  <main class="container">
    <section class="card">
      <h2>Résumé des Problèmes</h2>
      
      <div class="summary-grid">
        <div class="summary-item">
          <h3>Problèmes Totaux</h3>
          <p>${analysisData.summary.totalIssues}</p>
        </div>
        
        <div class="summary-item">
          <h3>Problèmes Critiques</h3>
          <p class="critical">${analysisData.summary.criticalIssues}</p>
        </div>
        
        <div class="summary-item">
          <h3>Problèmes Élevés</h3>
          <p class="high">${analysisData.summary.highIssues}</p>
        </div>
        
        <div class="summary-item">
          <h3>Problèmes Moyens</h3>
          <p class="medium">${analysisData.summary.mediumIssues}</p>
        </div>
        
        <div class="summary-item">
          <h3>Problèmes Faibles</h3>
          <p class="low">${analysisData.summary.lowIssues}</p>
        </div>
        
        <div class="summary-item">
          <h3>Corrigibles Automatiquement</h3>
          <p>${analysisData.summary.fixableAutomatically}</p>
        </div>
      </div>
    </section>
    
    <section class="card">
      <h2>Points Chauds Principaux</h2>
      
      ${
        analysisData.summary.topHotspots.length > 0 
        ? `<ul class="hotspots-list">
            ${analysisData.summary.topHotspots.map(hotspot => `
              <li class="hotspot-item">
                <h4>${hotspot.filePath || 'Fichier inconnu'}</h4>
                <p>
                  ${hotspot.criticalIssues ? `<span class="badge critical">Critique: ${hotspot.criticalIssues}</span>` : ''}
                  ${hotspot.highIssues ? `<span class="badge high">Élevé: ${hotspot.highIssues}</span>` : ''}
                  ${hotspot.mediumIssues ? `<span class="badge medium">Moyen: ${hotspot.mediumIssues}</span>` : ''}
                  ${hotspot.lowIssues ? `<span class="badge low">Faible: ${hotspot.lowIssues}</span>` : ''}
                </p>
                ${hotspot.description ? `<p>${hotspot.description}</p>` : ''}
              </li>
            `).join('')}
          </ul>`
        : '<div class="no-data">Aucun point chaud identifié</div>'
      }
    </section>
    
    <section class="card">
      <h2>Détails par Outil d'Analyse</h2>
      
      <div class="tab-container">
        <div class="tabs">
          <button class="tab active" onclick="showTab('rust-tab')">Analyse de Performance (Rust)</button>
          <button class="tab" onclick="showTab('swift-tab')">Optimisation CoreData (Swift)</button>
          <button class="tab" onclick="showTab('python-tab')">Analyse Statique (Python)</button>
        </div>
        
        <div id="rust-tab" class="tab-content active">
          ${
            analysisData.rustAnalysis 
            ? `<h3>Statistiques Globales</h3>
               <p>Nombre total de fichiers analysés: ${analysisData.rustAnalysis.totalFilesAnalyzed || 0}</p>
               <p>Temps total d'analyse: ${(analysisData.rustAnalysis.analysisTimeMs / 1000).toFixed(2)}s</p>
               
               <h3>Problèmes par Type</h3>
               <table>
                 <thead>
                   <tr>
                     <th>Type de Problème</th>
                     <th>Nombre d'Occurrences</th>
                   </tr>
                 </thead>
                 <tbody>
                   ${Object.entries(analysisData.rustAnalysis.issuesByType || {})
                     .map(([type, count]) => `
                       <tr>
                         <td>${type}</td>
                         <td>${count}</td>
                       </tr>
                     `).join('')}
                 </tbody>
               </table>`
            : '<div class="no-data">Données d\'analyse Rust non disponibles</div>'
          }
        </div>
        
        <div id="swift-tab" class="tab-content">
          ${
            analysisData.swiftAnalysis 
            ? `<h3>Optimisations CoreData</h3>
               <p>Problèmes identifiés: ${analysisData.swiftAnalysis.totalIssues || 0}</p>
               <p>Problèmes réparables automatiquement: ${analysisData.swiftAnalysis.autoFixableIssues || 0}</p>
               
               <h3>Détails des Problèmes</h3>
               <table>
                 <thead>
                   <tr>
                     <th>Description</th>
                     <th>Sévérité</th>
                     <th>Emplacement</th>
                     <th>Réparable Auto.</th>
                   </tr>
                 </thead>
                 <tbody>
                   ${(analysisData.swiftAnalysis.issues || [])
                     .map(issue => `
                       <tr>
                         <td>${issue.description}</td>
                         <td><span class="badge ${issue.severity}">${issue.severity}</span></td>
                         <td>${issue.location}</td>
                         <td>${issue.autoFixable ? '✅' : '❌'}</td>
                       </tr>
                     `).join('')}
                 </tbody>
               </table>`
            : '<div class="no-data">Données d\'analyse Swift non disponibles</div>'
          }
        </div>
        
        <div id="python-tab" class="tab-content">
          ${
            analysisData.pythonAnalysis 
            ? `<h3>Analyse Statique</h3>
               <p>Nombre total de problèmes détectés: ${analysisData.pythonAnalysis.totalIssues || 0}</p>
               
               <h3>Détails des Problèmes</h3>
               <table>
                 <thead>
                   <tr>
                     <th>Type</th>
                     <th>Description</th>
                     <th>Sévérité</th>
                     <th>Fichier</th>
                     <th>Ligne</th>
                   </tr>
                 </thead>
                 <tbody>
                   ${(analysisData.pythonAnalysis.issues || [])
                     .map(issue => `
                       <tr>
                         <td>${issue.type}</td>
                         <td>${issue.description}</td>
                         <td><span class="badge ${issue.severity}">${issue.severity}</span></td>
                         <td>${issue.file}</td>
                         <td>${issue.line}</td>
                       </tr>
                     `).join('')}
                 </tbody>
               </table>`
            : '<div class="no-data">Données d\'analyse Python non disponibles</div>'
          }
        </div>
      </div>
    </section>
  </main>
  
  <footer class="footer">
    <p>Généré par CardApp Analysis Tools © ${new Date().getFullYear()}</p>
  </footer>
  
  <script>
    function showTab(tabId) {
      // Masquer tous les contenus d'onglet
      const tabContents = document.querySelectorAll('.tab-content');
      tabContents.forEach(content => content.classList.remove('active'));
      
      // Désactiver tous les onglets
      const tabs = document.querySelectorAll('.tab');
      tabs.forEach(tab => tab.classList.remove('active'));
      
      // Activer l'onglet et le contenu sélectionnés
      document.getElementById(tabId).classList.add('active');
      document.querySelector(`.tab[onclick="showTab('${tabId}')"]`).classList.add('active');
    }
  </script>
</body>
</html>`;
}

// Exécuter le script
main(); 