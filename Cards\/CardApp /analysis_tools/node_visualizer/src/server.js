/**
 * Module serveur pour le visualiseur interactif
 */

const express = require('express');
const path = require('path');
const fs = require('fs-extra');

/**
 * Démarre un serveur Express pour afficher le rapport HTML
 * @param {string} reportPath - Chemin du fichier HTML à servir
 * @param {number} port - Port sur lequel démarrer le serveur
 * @returns {Object} - Objet serveur Express
 */
async function startServer(reportPath, port = 3000) {
  const app = express();
  const reportDir = path.dirname(reportPath);
  const reportFileName = path.basename(reportPath);
  
  // Configuration pour servir les fichiers statiques
  app.use(express.static(reportDir));
  
  // Route principale qui sert le rapport
  app.get('/', (req, res) => {
    res.sendFile(reportPath);
  });
  
  // Route API pour obtenir la liste des problèmes en JSON
  app.get('/api/issues', async (req, res) => {
    try {
      // Cette route est utilisée pour obtenir des données en temps réel
      // pour les visualisations interactives
      const issues = await extractIssuesFromReport(reportPath);
      res.json(issues);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });
  
  // Route API pour obtenir les statistiques en JSON
  app.get('/api/stats', async (req, res) => {
    try {
      const stats = await extractStatsFromReport(reportPath);
      res.json(stats);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });
  
  // Route pour les fichiers sources
  app.get('/api/source/:filePath(*)', async (req, res) => {
    try {
      const filePath = req.params.filePath;
      const decodedPath = decodeURIComponent(filePath);
      
      // Sécurité: vérifier que le chemin demandé est absolu
      if (!path.isAbsolute(decodedPath)) {
        return res.status(400).json({ error: 'Chemin invalide. Le chemin doit être absolu.' });
      }
      
      // Vérifier que le fichier existe
      if (!await fs.pathExists(decodedPath)) {
        return res.status(404).json({ error: `Le fichier ${decodedPath} n'existe pas.` });
      }
      
      // Lire le contenu du fichier
      const content = await fs.readFile(decodedPath, 'utf8');
      
      // Renvoyer le contenu en JSON
      res.json({ 
        path: decodedPath,
        name: path.basename(decodedPath),
        content 
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });
  
  // Démarrer le serveur
  return new Promise((resolve, reject) => {
    const server = app.listen(port, err => {
      if (err) {
        reject(err);
      } else {
        resolve(server);
      }
    });
  });
}

/**
 * Extrait les données de problèmes du rapport HTML
 * @param {string} reportPath - Chemin du fichier de rapport HTML
 * @returns {Array} - Tableau des problèmes
 */
async function extractIssuesFromReport(reportPath) {
  try {
    // Cette implémentation est simplifiée - dans un cas réel,
    // nous analyserions le contenu HTML ou chargerions un JSON séparé
    
    // Pour le moment, nous recherchons un fichier JSON qui a le même nom de base
    const jsonPath = reportPath.replace(/\.html$/, '.json');
    
    if (await fs.pathExists(jsonPath)) {
      const data = await fs.readJson(jsonPath);
      if (data.combinedIssues) {
        return data.combinedIssues;
      }
    }
    
    // Si nous ne trouvons pas de fichier JSON, nous retournons un tableau vide
    return [];
  } catch (error) {
    console.error('Erreur lors de l\'extraction des problèmes:', error);
    return [];
  }
}

/**
 * Extrait les statistiques du rapport HTML
 * @param {string} reportPath - Chemin du fichier de rapport HTML
 * @returns {Object} - Statistiques
 */
async function extractStatsFromReport(reportPath) {
  try {
    // Même approche que pour extractIssuesFromReport
    const jsonPath = reportPath.replace(/\.html$/, '.json');
    
    if (await fs.pathExists(jsonPath)) {
      const data = await fs.readJson(jsonPath);
      if (data.statistics) {
        return data.statistics;
      }
    }
    
    return {};
  } catch (error) {
    console.error('Erreur lors de l\'extraction des statistiques:', error);
    return {};
  }
}

module.exports = {
  startServer
}; 