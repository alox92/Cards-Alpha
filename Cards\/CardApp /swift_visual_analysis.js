#!/usr/bin/env node

/**
 * Visualiseur avancé pour l'analyse du code Swift
 * 
 * Ce script génère un rapport HTML interactif à partir des données d'analyse
 * produites par les outils Python et Rust.
 * 
 * Il visualise:
 * - Les problèmes de mémoire et cycles de référence
 * - Les problèmes de concurrence et thread safety
 * - Les problèmes CoreData et optimisations
 * - Les métriques de complexité et de performance
 */

const fs = require('fs');
const path = require('path');

// Arguments de ligne de commande
const args = process.argv.slice(2);
const pythonReportPath = args[0] || './analysis_result.json';
const rustReportPath = args[0] ? args[0].replace('.json', '_rust.json') : './rapports_optimisation/performance_analysis.json';
const outputPath = args[1] || './rapports_optimisation/rapport_analyse.html';

console.log(`Génération du rapport visuel à partir de:`);
console.log(`- Rapport Python: ${pythonReportPath}`);
console.log(`- Rapport Rust: ${rustReportPath}`);
console.log(`- Sortie: ${outputPath}`);

// Création du répertoire de sortie si nécessaire
const outputDir = path.dirname(outputPath);
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}

// Chargement des données d'analyse
let pythonData = {}, rustData = {};

try {
    if (fs.existsSync(pythonReportPath)) {
        pythonData = JSON.parse(fs.readFileSync(pythonReportPath, 'utf8'));
        console.log(`Chargé les données Python avec ${pythonData.problemes?.length || 0} problèmes`);
    } else {
        console.log(`Attention: Le rapport Python n'existe pas: ${pythonReportPath}`);
    }
} catch (err) {
    console.error(`Erreur lors du chargement du rapport Python: ${err.message}`);
}

try {
    if (fs.existsSync(rustReportPath)) {
        rustData = JSON.parse(fs.readFileSync(rustReportPath, 'utf8'));
        console.log(`Chargé les données Rust avec ${rustData.issues?.length || 0} problèmes`);
    } else {
        console.log(`Attention: Le rapport Rust n'existe pas: ${rustReportPath}`);
    }
} catch (err) {
    console.error(`Erreur lors du chargement du rapport Rust: ${err.message}`);
}

// Combiner les données des deux rapports
const combinedData = {
    timestamp: new Date().toISOString(),
    problemesMemoire: [],
    problemesConcurrence: [],
    problemesCoreData: [],
    problemesComplexite: [],
    problemesAutres: [],
    statistiques: {
        totalProblemes: 0,
        parSeverite: {},
        parCategorie: {},
        parFichier: {}
    }
};

// Traiter les données Python
if (pythonData.problemes) {
    pythonData.problemes.forEach(probleme => {
        const issue = {
            fichier: probleme.fichier,
            ligne: probleme.ligne,
            message: probleme.message,
            severite: probleme.severite,
            suggestion: probleme.suggestion,
            code: probleme.code || '',
            source: 'Python'
        };

        // Classer par type
        if (probleme.type === 'memory_leak' || probleme.type.includes('memory')) {
            combinedData.problemesMemoire.push(issue);
        } else if (probleme.type === 'concurrency' || probleme.type.includes('thread')) {
            combinedData.problemesConcurrence.push(issue);
        } else if (probleme.type === 'core_data' || probleme.type.includes('coredata')) {
            combinedData.problemesCoreData.push(issue);
        } else if (probleme.type === 'complexity' || probleme.type.includes('complex')) {
            combinedData.problemesComplexite.push(issue);
        } else {
            combinedData.problemesAutres.push(issue);
        }

        // Statistiques
        combinedData.statistiques.totalProblemes++;
        
        // Par sévérité
        combinedData.statistiques.parSeverite[probleme.severite] = 
            (combinedData.statistiques.parSeverite[probleme.severite] || 0) + 1;
        
        // Par catégorie
        combinedData.statistiques.parCategorie[probleme.type] = 
            (combinedData.statistiques.parCategorie[probleme.type] || 0) + 1;
        
        // Par fichier
        const fichierBase = path.basename(probleme.fichier);
        combinedData.statistiques.parFichier[fichierBase] = 
            (combinedData.statistiques.parFichier[fichierBase] || 0) + 1;
    });
}

// Traiter les données Rust
if (rustData.issues) {
    rustData.issues.forEach(issue => {
        const severityMap = {
            'Critical': 'critical',
            'Error': 'error',
            'Warning': 'warning'
        };

        const item = {
            fichier: issue.file,
            ligne: issue.line,
            message: issue.message,
            severite: severityMap[issue.severity] || 'warning',
            suggestion: issue.suggestion,
            code: issue.code || '',
            source: 'Rust'
        };

        // Classer par catégorie
        if (issue.category === 'memory') {
            combinedData.problemesMemoire.push(item);
        } else if (issue.category === 'concurrency') {
            combinedData.problemesConcurrence.push(item);
        } else if (issue.category === 'coredata') {
            combinedData.problemesCoreData.push(item);
        } else if (issue.category === 'complexity') {
            combinedData.problemesComplexite.push(item);
        } else {
            combinedData.problemesAutres.push(item);
        }

        // Statistiques
        combinedData.statistiques.totalProblemes++;
        
        // Par sévérité
        combinedData.statistiques.parSeverite[item.severite] = 
            (combinedData.statistiques.parSeverite[item.severite] || 0) + 1;
        
        // Par catégorie
        combinedData.statistiques.parCategorie[issue.category] = 
            (combinedData.statistiques.parCategorie[issue.category] || 0) + 1;
        
        // Par fichier
        const fichierBase = path.basename(issue.file);
        combinedData.statistiques.parFichier[fichierBase] = 
            (combinedData.statistiques.parFichier[fichierBase] || 0) + 1;
    });
}

// Fonction pour générer le HTML pour un problème
function genererHtmlProbleme(probleme) {
    const severiteClass = {
        'critical': 'bg-danger',
        'error': 'bg-warning',
        'warning': 'bg-info',
        'info': 'bg-secondary'
    }[probleme.severite] || 'bg-secondary';

    const sourceClass = probleme.source === 'Python' ? 'text-primary' : 'text-success';
    
    return `
    <div class="card mb-3">
        <div class="card-header ${severiteClass} text-white">
            <div class="d-flex justify-content-between">
                <span>${probleme.fichier}:${probleme.ligne}</span>
                <span class="${sourceClass}">${probleme.source}</span>
            </div>
        </div>
        <div class="card-body">
            <h5 class="card-title">${probleme.message}</h5>
            <p class="card-text"><strong>Suggestion:</strong> ${probleme.suggestion}</p>
            ${probleme.code ? `<pre class="bg-light p-2 rounded"><code>${probleme.code}</code></pre>` : ''}
        </div>
    </div>
    `;
}

// Fonction pour générer un graphique de répartition
function genererScriptGraphique(donnees, id, titre, type = 'bar') {
    const labels = Object.keys(donnees);
    const values = Object.values(donnees);
    
    return `
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const ctx = document.getElementById('${id}').getContext('2d');
            new Chart(ctx, {
                type: '${type}',
                data: {
                    labels: ${JSON.stringify(labels)},
                    datasets: [{
                        label: '${titre}',
                        data: ${JSON.stringify(values)},
                        backgroundColor: [
                            'rgba(255, 99, 132, 0.7)',
                            'rgba(54, 162, 235, 0.7)',
                            'rgba(255, 206, 86, 0.7)',
                            'rgba(75, 192, 192, 0.7)',
                            'rgba(153, 102, 255, 0.7)',
                            'rgba(255, 159, 64, 0.7)'
                        ]
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        title: {
                            display: true,
                            text: '${titre}',
                            font: { size: 16 }
                        },
                        legend: { display: ${type === 'pie'} }
                    }
                }
            });
        });
    </script>
    `;
}

// Générer le HTML complet
const html = `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'analyse CardApp</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { padding-top: 20px; padding-bottom: 30px; }
        .tab-pane { padding: 20px 0; }
        .chart-container { height: 300px; margin-bottom: 30px; }
        .severity-badge.critical { background-color: #dc3545; }
        .severity-badge.error { background-color: #ffc107; }
        .severity-badge.warning { background-color: #17a2b8; }
        .severity-badge.info { background-color: #6c757d; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="text-center mb-4">Rapport d'analyse CardApp</h1>
        <p class="text-center text-muted">Généré le ${new Date().toLocaleString()}</p>
        
        <div class="row mt-4 mb-4">
            <div class="col-md-4">
                <div class="card text-white bg-primary">
                    <div class="card-body text-center">
                        <h5 class="card-title">Total des problèmes</h5>
                        <p class="card-text" style="font-size: 2rem;">${combinedData.statistiques.totalProblemes}</p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card text-white bg-danger">
                    <div class="card-body text-center">
                        <h5 class="card-title">Problèmes critiques</h5>
                        <p class="card-text" style="font-size: 2rem;">${combinedData.statistiques.parSeverite.critical || 0}</p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card text-white bg-warning">
                    <div class="card-body text-center">
                        <h5 class="card-title">Problèmes importants</h5>
                        <p class="card-text" style="font-size: 2rem;">${combinedData.statistiques.parSeverite.error || 0}</p>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="row mb-4">
            <div class="col-md-6">
                <div class="chart-container">
                    <canvas id="chartCategories"></canvas>
                </div>
            </div>
            <div class="col-md-6">
                <div class="chart-container">
                    <canvas id="chartSeverite"></canvas>
                </div>
            </div>
        </div>
        
        <ul class="nav nav-tabs" id="myTab" role="tablist">
            <li class="nav-item" role="presentation">
                <button class="nav-link active" id="memoire-tab" data-bs-toggle="tab" data-bs-target="#memoire" type="button" role="tab">
                    Mémoire <span class="badge bg-secondary">${combinedData.problemesMemoire.length}</span>
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="concurrence-tab" data-bs-toggle="tab" data-bs-target="#concurrence" type="button" role="tab">
                    Concurrence <span class="badge bg-secondary">${combinedData.problemesConcurrence.length}</span>
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="coredata-tab" data-bs-toggle="tab" data-bs-target="#coredata" type="button" role="tab">
                    CoreData <span class="badge bg-secondary">${combinedData.problemesCoreData.length}</span>
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="complexite-tab" data-bs-toggle="tab" data-bs-target="#complexite" type="button" role="tab">
                    Complexité <span class="badge bg-secondary">${combinedData.problemesComplexite.length}</span>
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="autres-tab" data-bs-toggle="tab" data-bs-target="#autres" type="button" role="tab">
                    Autres <span class="badge bg-secondary">${combinedData.problemesAutres.length}</span>
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="fichiers-tab" data-bs-toggle="tab" data-bs-target="#fichiers" type="button" role="tab">
                    Par fichier
                </button>
            </li>
        </ul>
        
        <div class="tab-content" id="myTabContent">
            <div class="tab-pane fade show active" id="memoire" role="tabpanel" aria-labelledby="memoire-tab">
                <h3>Problèmes de gestion mémoire</h3>
                <p>Ces problèmes incluent les cycles de référence, les fuites mémoire et les problèmes de rétention.</p>
                ${combinedData.problemesMemoire.map(p => genererHtmlProbleme(p)).join('')}
            </div>
            
            <div class="tab-pane fade" id="concurrence" role="tabpanel" aria-labelledby="concurrence-tab">
                <h3>Problèmes de concurrence</h3>
                <p>Ces problèmes concernent la gestion des threads, la synchronisation et les opérations asynchrones.</p>
                ${combinedData.problemesConcurrence.map(p => genererHtmlProbleme(p)).join('')}
            </div>
            
            <div class="tab-pane fade" id="coredata" role="tabpanel" aria-labelledby="coredata-tab">
                <h3>Problèmes CoreData</h3>
                <p>Ces problèmes sont liés à l'utilisation de CoreData, aux requêtes et à la gestion des contextes.</p>
                ${combinedData.problemesCoreData.map(p => genererHtmlProbleme(p)).join('')}
            </div>
            
            <div class="tab-pane fade" id="complexite" role="tabpanel" aria-labelledby="complexite-tab">
                <h3>Problèmes de complexité</h3>
                <p>Ces problèmes concernent la complexité du code, la longueur des fonctions et la maintenabilité.</p>
                ${combinedData.problemesComplexite.map(p => genererHtmlProbleme(p)).join('')}
            </div>
            
            <div class="tab-pane fade" id="autres" role="tabpanel" aria-labelledby="autres-tab">
                <h3>Autres problèmes</h3>
                <p>Problèmes divers qui ne rentrent pas dans les catégories précédentes.</p>
                ${combinedData.problemesAutres.map(p => genererHtmlProbleme(p)).join('')}
            </div>
            
            <div class="tab-pane fade" id="fichiers" role="tabpanel" aria-labelledby="fichiers-tab">
                <h3>Problèmes par fichier</h3>
                <div class="chart-container">
                    <canvas id="chartFichiers"></canvas>
                </div>
                
                <div class="row mt-4">
                    <div class="col-12">
                        <table class="table table-striped">
                            <thead>
                                <tr>
                                    <th>Fichier</th>
                                    <th>Nombre de problèmes</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${Object.entries(combinedData.statistiques.parFichier)
                                    .sort((a, b) => b[1] - a[1])
                                    .map(([fichier, count]) => `
                                        <tr>
                                            <td>${fichier}</td>
                                            <td>${count}</td>
                                        </tr>
                                    `).join('')
                                }
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
        
        <hr class="my-5">
        
        <h3>Recommandations générales</h3>
        <div class="row">
            <div class="col-md-6">
                <div class="card mb-3">
                    <div class="card-header bg-primary text-white">Mémoire</div>
                    <div class="card-body">
                        <ul>
                            <li>Utilisez <code>[weak self]</code> dans les closures pour éviter les cycles de référence</li>
                            <li>Marquez les délégués avec <code>weak</code> pour éviter les rétentions fortes</li>
                            <li>Utilisez <code>guard let</code> ou <code>if let</code> au lieu du force unwrapping</li>
                            <li>Implémentez <code>deinit</code> pour nettoyer les ressources</li>
                        </ul>
                    </div>
                </div>
                
                <div class="card mb-3">
                    <div class="card-header bg-primary text-white">CoreData</div>
                    <div class="card-body">
                        <ul>
                            <li>Utilisez <code>fetchBatchSize</code> pour les requêtes volumineuses</li>
                            <li>Entourez les opérations CoreData de <code>try/catch</code></li>
                            <li>Utilisez <code>perform/performAndWait</code> pour les opérations thread-safe</li>
                            <li>Indexez les attributs fréquemment utilisés dans les requêtes</li>
                        </ul>
                    </div>
                </div>
            </div>
            
            <div class="col-md-6">
                <div class="card mb-3">
                    <div class="card-header bg-primary text-white">Concurrence</div>
                    <div class="card-body">
                        <ul>
                            <li>Utilisez <code>@MainActor</code> pour le code qui doit s'exécuter sur le thread principal</li>
                            <li>Préférez les primitives de Swift Concurrency modernes (<code>async/await</code>)</li>
                            <li>N'accédez jamais à <code>viewContext</code> depuis un thread background</li>
                            <li>Utilisez <code>Task { @MainActor in ... }</code> pour revenir au thread principal</li>
                        </ul>
                    </div>
                </div>
                
                <div class="card mb-3">
                    <div class="card-header bg-primary text-white">Structure du code</div>
                    <div class="card-body">
                        <ul>
                            <li>Limitez les fonctions à 50 lignes maximum</li>
                            <li>Réduisez la complexité cyclomatique en extrayant des méthodes</li>
                            <li>Suivez le principe de responsabilité unique (SRP)</li>
                            <li>Utilisez des extensions pour organiser votre code</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Scripts -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    
    ${genererScriptGraphique(combinedData.statistiques.parCategorie, 'chartCategories', 'Problèmes par catégorie')}
    ${genererScriptGraphique(combinedData.statistiques.parSeverite, 'chartSeverite', 'Problèmes par sévérité', 'pie')}
    ${genererScriptGraphique(
        Object.fromEntries(
            Object.entries(combinedData.statistiques.parFichier)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 10)
        ),
        'chartFichiers', 
        'Top 10 fichiers avec le plus de problèmes'
    )}
</body>
</html>
`;

// Écrire le HTML dans le fichier de sortie
fs.writeFileSync(outputPath, html);
console.log(`Rapport HTML généré avec succès: ${outputPath}`);
