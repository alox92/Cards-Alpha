pub mod json {
    use std::fs::File;
    use std::io::Write;
    use std::path::Path;
    
    use crate::models::PerformanceReport;
    
    /// Génère un rapport au format JSON
    pub fn generate_report(report: &PerformanceReport, output_path: &Path) {
        let json_content = match serde_json::to_string_pretty(report) {
            Ok(content) => content,
            Err(e) => {
                eprintln!("Erreur lors de la sérialisation JSON: {}", e);
                return;
            }
        };
        
        let mut file = match File::create(output_path) {
            Ok(file) => file,
            Err(e) => {
                eprintln!("Erreur lors de la création du fichier de rapport JSON: {}", e);
                return;
            }
        };
        
        if let Err(e) = file.write_all(json_content.as_bytes()) {
            eprintln!("Erreur lors de l'écriture du rapport JSON: {}", e);
        }
    }
}

pub mod html {
    use std::fs::File;
    use std::io::Write;
    use std::path::Path;
    
    use crate::models::{FileIssue, HotspotFile, IssueType, PerformanceReport, Severity};
    
    /// Génère un rapport au format HTML
    pub fn generate_report(report: &PerformanceReport, output_path: &Path) {
        let mut html_content = String::new();
        
        // En-tête HTML
        html_content.push_str(
            r#"<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'analyse de performance Swift</title>
    <style>
        :root {
            --primary: #007bff;
            --secondary: #6c757d;
            --success: #28a745;
            --danger: #dc3545;
            --warning: #ffc107;
            --info: #17a2b8;
            --dark: #343a40;
            --light: #f8f9fa;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f7;
        }
        
        .container {
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            padding: 25px;
            margin-bottom: 25px;
        }
        
        h1, h2, h3 {
            color: #333;
        }
        
        h1 {
            border-bottom: 2px solid var(--primary);
            padding-bottom: 10px;
            margin-bottom: 30px;
        }
        
        .summary-stats {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            flex: 1;
            min-width: 200px;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            background-color: white;
            text-align: center;
        }
        
        .stat-card h3 {
            margin-top: 0;
            color: var(--secondary);
            font-size: 16px;
        }
        
        .stat-card .value {
            font-size: 28px;
            font-weight: bold;
            color: var(--primary);
        }
        
        .health-meter {
            height: 10px;
            background-color: #e9ecef;
            border-radius: 5px;
            margin: 15px 0;
            overflow: hidden;
        }
        
        .health-meter-fill {
            height: 100%;
            border-radius: 5px;
            transition: width 0.5s ease;
        }
        
        .progress-good {
            background-color: var(--success);
        }
        
        .progress-warning {
            background-color: var(--warning);
        }
        
        .progress-danger {
            background-color: var(--danger);
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            font-size: 14px;
        }
        
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background-color: var(--light);
            font-weight: bold;
        }
        
        tr:hover {
            background-color: rgba(0, 123, 255, 0.05);
        }
        
        .severity-critical {
            color: #b71c1c;
            font-weight: bold;
        }
        
        .severity-high {
            color: #e65100;
            font-weight: bold;
        }
        
        .severity-medium {
            color: #ff8f00;
        }
        
        .severity-low {
            color: #558b2f;
        }
        
        .tab {
            overflow: hidden;
            border: 1px solid #ccc;
            background-color: var(--light);
            border-radius: 8px 8px 0 0;
        }
        
        .tab button {
            background-color: inherit;
            float: left;
            border: none;
            outline: none;
            cursor: pointer;
            padding: 14px 16px;
            transition: 0.3s;
            font-size: 16px;
        }
        
        .tab button:hover {
            background-color: #ddd;
        }
        
        .tab button.active {
            background-color: white;
            border-bottom: 3px solid var(--primary);
        }
        
        .tabcontent {
            display: none;
            padding: 20px;
            border: 1px solid #ccc;
            border-top: none;
            border-radius: 0 0 8px 8px;
            background-color: white;
        }
        
        .show {
            display: block;
        }
        
        .issue-card {
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 5px;
            border-left: 5px solid;
            background-color: #f8f9fa;
        }
        
        .issue-critical {
            border-left-color: #b71c1c;
        }
        
        .issue-high {
            border-left-color: #e65100;
        }
        
        .issue-medium {
            border-left-color: #ff8f00;
        }
        
        .issue-low {
            border-left-color: #558b2f;
        }
        
        .issue-header {
            display: flex;
            justify-content: space-between;
            margin-bottom: 5px;
        }
        
        .issue-file {
            font-family: monospace;
            font-size: 13px;
            color: var(--secondary);
        }
        
        .issue-message {
            margin: 10px 0;
        }
        
        .issue-suggestion {
            font-style: italic;
            color: #2e7d32;
            margin-top: 8px;
        }
        
        pre {
            background-color: #282c34;
            color: #abb2bf;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
            font-size: 13px;
            margin: 10px 0;
        }
        
        .chart-container {
            position: relative;
            height: 300px;
            margin: 20px 0;
        }
        
        .badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            color: white;
        }
        
        .badge-critical {
            background-color: #b71c1c;
        }
        
        .badge-high {
            background-color: #e65100;
        }
        
        .badge-medium {
            background-color: #ff8f00;
        }
        
        .badge-low {
            background-color: #558b2f;
        }
        
        @media (max-width: 768px) {
            .summary-stats {
                flex-direction: column;
            }
            
            .stat-card {
                width: 100%;
            }
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport d'analyse de performance Swift</h1>
"#
        );
        
        // Résumé
        html_content.push_str(&format!(
            r#"
    <div class="container">
        <h2>Résumé du projet</h2>
        <div class="summary-stats">
            <div class="stat-card">
                <h3>Fichiers analysés</h3>
                <div class="value">{}</div>
            </div>
            <div class="stat-card">
                <h3>Problèmes détectés</h3>
                <div class="value">{}</div>
            </div>
            <div class="stat-card">
                <h3>Fichiers avec problèmes</h3>
                <div class="value">{} ({}%)</div>
            </div>
            <div class="stat-card">
                <h3>Score de santé</h3>
                <div class="value">{:.1}%</div>
            </div>
        </div>
        
        <h3>Score de santé du projet</h3>
        <div class="health-meter">
            <div class="health-meter-fill {}" style="width: {}%;"></div>
        </div>
    </div>
"#,
            report.project_stats.total_files,
            report.issue_count_by_severity.values().sum::<usize>(),
            report.project_stats.problematic_files,
            if report.project_stats.total_files > 0 {
                (report.project_stats.problematic_files as f64 / report.project_stats.total_files as f64) * 100.0
            } else {
                0.0
            },
            report.project_stats.health_score,
            if report.project_stats.health_score >= 70.0 {
                "progress-good"
            } else if report.project_stats.health_score >= 40.0 {
                "progress-warning"
            } else {
                "progress-danger"
            },
            report.project_stats.health_score
        ));
        
        // Onglets
        html_content.push_str(
            r#"
    <div class="container">
        <div class="tab">
            <button class="tablinks active" onclick="openTab(event, 'issues')">Problèmes détectés</button>
            <button class="tablinks" onclick="openTab(event, 'hotspots')">Points chauds</button>
            <button class="tablinks" onclick="openTab(event, 'stats')">Statistiques</button>
        </div>
        
        <div id="issues" class="tabcontent show">
"#
        );
        
        // Liste des problèmes
        if report.issue_count_by_severity.values().sum::<usize>() == 0 {
            html_content.push_str(
                r#"
            <div style="text-align: center; padding: 40px;">
                <h3 style="color: #28a745;">Aucun problème détecté !</h3>
                <p>Votre code est en bonne santé. Continuez le bon travail!</p>
            </div>
"#
            );
        } else {
            // Filtrer les problèmes critiques et élevés
            let mut all_issues: Vec<(&Path, &FileIssue)> = Vec::new();
            for result in &report.files_analyzed {
                for issue in &result.issues {
                    if issue.severity == Severity::Critical || issue.severity == Severity::High {
                        all_issues.push((&result.file_path, issue));
                    }
                }
            }
            
            // Trier par sévérité
            all_issues.sort_by(|a, b| b.1.severity.cmp(&a.1.severity));
            
            html_content.push_str(
                r#"
            <h3>Problèmes critiques</h3>
"#
            );
            
            for (file_path, issue) in all_issues {
                let severity_class = match issue.severity {
                    Severity::Critical => "critical",
                    Severity::High => "high",
                    Severity::Medium => "medium",
                    Severity::Low => "low",
                };
                
                let severity_text = match issue.severity {
                    Severity::Critical => "CRITIQUE",
                    Severity::High => "ÉLEVÉ",
                    Severity::Medium => "MOYEN",
                    Severity::Low => "FAIBLE",
                };
                
                let issue_type_text = match issue.issue_type {
                    IssueType::HighComplexity => "Complexité élevée",
                    IssueType::DeepNesting => "Imbrication profonde",
                    IssueType::UnsafeClosure => "Closure non sécurisée",
                    IssueType::CoreDataMainThread => "CoreData sur thread principal",
                    IssueType::MissingErrorHandling => "Gestion d'erreur manquante",
                    IssueType::PotentialDataRace => "Risque de course de données",
                    IssueType::InefficientCollection => "Collection inefficace",
                    IssueType::MemoryLeak => "Fuite mémoire",
                    IssueType::ResourceLeak => "Fuite de ressource",
                    IssueType::HighCoupling => "Couplage élevé",
                    IssueType::ExcessiveComputation => "Calcul excessif",
                };
                
                html_content.push_str(&format!(
                    r#"
            <div class="issue-card issue-{}">
                <div class="issue-header">
                    <span class="badge badge-{}">{}</span>
                    <span class="issue-file">{}</span>
                </div>
                <div class="issue-type">{}</div>
                <div class="issue-message">{}</div>
"#,
                    severity_class,
                    severity_class,
                    severity_text,
                    format!("{}:{}", file_path.display(), issue.line),
                    issue_type_text,
                    issue.message
                ));
                
                if let Some(suggestion) = &issue.suggestion {
                    html_content.push_str(&format!(
                        r#"                <div class="issue-suggestion">Suggestion: {}</div>
"#,
                        suggestion
                    ));
                }
                
                if let Some(snippet) = &issue.code_snippet {
                    html_content.push_str(&format!(
                        r#"                <pre>{}</pre>
"#,
                        snippet.trim()
                    ));
                }
                
                html_content.push_str(
                    r#"            </div>
"#
                );
            }
        }
        
        html_content.push_str(
            r#"        </div>
        
        <div id="hotspots" class="tabcontent">
            <h3>Points chauds (fichiers les plus problématiques)</h3>
            <table>
                <thead>
                    <tr>
                        <th>Rang</th>
                        <th>Fichier</th>
                        <th>Problèmes</th>
                        <th>Score de criticité</th>
                    </tr>
                </thead>
                <tbody>
"#
        );
        
        // Tableau des points chauds
        for (i, hotspot) in report.hotspots.iter().enumerate() {
            html_content.push_str(&format!(
                r#"                <tr>
                    <td>{}</td>
                    <td>{}</td>
                    <td>{}</td>
                    <td>{:.1}</td>
                </tr>
"#,
                i + 1,
                hotspot.file_path.display(),
                hotspot.issue_count,
                hotspot.criticality_score
            ));
        }
        
        html_content.push_str(
            r#"                </tbody>
            </table>
            
            <div class="chart-container">
                <canvas id="hotspotChart"></canvas>
            </div>
        </div>
        
        <div id="stats" class="tabcontent">
"#
        );
        
        // Statistiques par sévérité
        html_content.push_str(
            r#"            <h3>Problèmes par sévérité</h3>
            <div class="chart-container" style="height: 250px;">
                <canvas id="severityChart"></canvas>
            </div>
            
            <h3>Problèmes par type</h3>
            <div class="chart-container">
                <canvas id="typeChart"></canvas>
            </div>
            
            <h3>Statistiques détaillées</h3>
            <table>
                <thead>
                    <tr>
                        <th>Métrique</th>
                        <th>Valeur</th>
                    </tr>
                </thead>
                <tbody>
"#
        );
        
        // Calculer des métriques supplémentaires
        let total_issues = report.issue_count_by_severity.values().sum::<usize>();
        let critical_issues = *report.issue_count_by_severity.get(&Severity::Critical).unwrap_or(&0);
        let high_issues = *report.issue_count_by_severity.get(&Severity::High).unwrap_or(&0);
        
        let critical_percent = if total_issues > 0 {
            (critical_issues as f64 / total_issues as f64) * 100.0
        } else {
            0.0
        };
        
        html_content.push_str(&format!(
            r#"                <tr>
                    <td>Lignes de code totales</td>
                    <td>{}</td>
                </tr>
                <tr>
                    <td>Problèmes par 1000 lignes</td>
                    <td>{:.2}</td>
                </tr>
                <tr>
                    <td>Pourcentage de problèmes critiques</td>
                    <td>{:.1}%</td>
                </tr>
                <tr>
                    <td>Nombre de fichiers sans problèmes</td>
                    <td>{}</td>
                </tr>
"#,
            report.project_stats.total_lines,
            if report.project_stats.total_lines > 0 {
                (total_issues as f64 * 1000.0) / report.project_stats.total_lines as f64
            } else {
                0.0
            },
            critical_percent,
            report.project_stats.total_files - report.project_stats.problematic_files
        ));
        
        html_content.push_str(
            r#"                </tbody>
            </table>
        </div>
    </div>
"#
        );
        
        // Données pour les graphiques
        let mut severity_data = String::new();
        for severity in &[Severity::Critical, Severity::High, Severity::Medium, Severity::Low] {
            let count = report.issue_count_by_severity.get(severity).unwrap_or(&0);
            severity_data.push_str(&format!("{}, ", count));
        }
        severity_data.pop(); // Supprimer la dernière virgule et espace
        severity_data.pop();
        
        let mut type_data = String::new();
        let mut type_labels = String::new();
        for (issue_type, count) in &report.issue_count_by_type {
            let label = match issue_type {
                IssueType::HighComplexity => "Complexité",
                IssueType::DeepNesting => "Imbrication",
                IssueType::UnsafeClosure => "Closure",
                IssueType::CoreDataMainThread => "CoreData",
                IssueType::MissingErrorHandling => "Erreurs",
                IssueType::PotentialDataRace => "Race",
                IssueType::InefficientCollection => "Collection",
                IssueType::MemoryLeak => "Mémoire",
                IssueType::ResourceLeak => "Ressource",
                IssueType::HighCoupling => "Couplage",
                IssueType::ExcessiveComputation => "Calcul",
            };
            type_data.push_str(&format!("{}, ", count));
            type_labels.push_str(&format!("'{}', ", label));
        }
        if !type_data.is_empty() {
            type_data.pop(); // Supprimer la dernière virgule et espace
            type_data.pop();
        }
        if !type_labels.is_empty() {
            type_labels.pop(); // Supprimer la dernière virgule et espace
            type_labels.pop();
        }
        
        // Données pour le graphique de points chauds
        let mut hotspot_data = String::new();
        let mut hotspot_labels = String::new();
        for hotspot in report.hotspots.iter().take(10) {
            if let Some(file_name) = hotspot.file_path.file_name() {
                if let Some(name) = file_name.to_str() {
                    hotspot_labels.push_str(&format!("'{}', ", name));
                    hotspot_data.push_str(&format!("{:.1}, ", hotspot.criticality_score));
                }
            }
        }
        if !hotspot_data.is_empty() {
            hotspot_data.pop(); // Supprimer la dernière virgule et espace
            hotspot_data.pop();
        }
        if !hotspot_labels.is_empty() {
            hotspot_labels.pop(); // Supprimer la dernière virgule et espace
            hotspot_labels.pop();
        }
        
        // Script JavaScript
        html_content.push_str(&format!(
            r#"
    <script>
        // Fonction d'ouverture des onglets
        function openTab(evt, tabName) {{
            var i, tabcontent, tablinks;
            tabcontent = document.getElementsByClassName("tabcontent");
            for (i = 0; i < tabcontent.length; i++) {{
                tabcontent[i].style.display = "none";
            }}
            tablinks = document.getElementsByClassName("tablinks");
            for (i = 0; i < tablinks.length; i++) {{
                tablinks[i].className = tablinks[i].className.replace(" active", "");
            }}
            document.getElementById(tabName).style.display = "block";
            evt.currentTarget.className += " active";
        }}
        
        // Graphique de sévérité
        var severityCtx = document.getElementById('severityChart').getContext('2d');
        var severityChart = new Chart(severityCtx, {{
            type: 'pie',
            data: {{
                labels: ['Critique', 'Élevé', 'Moyen', 'Faible'],
                datasets: [{{
                    data: [{severity_data}],
                    backgroundColor: ['#b71c1c', '#e65100', '#ff8f00', '#558b2f']
                }}]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {{
                    legend: {{
                        position: 'right',
                    }}
                }}
            }}
        }});
        
        // Graphique par type
        var typeCtx = document.getElementById('typeChart').getContext('2d');
        var typeChart = new Chart(typeCtx, {{
            type: 'bar',
            data: {{
                labels: [{type_labels}],
                datasets: [{{
                    label: 'Nombre de problèmes',
                    data: [{type_data}],
                    backgroundColor: '#007bff'
                }}]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {{
                    legend: {{
                        display: false
                    }}
                }},
                scales: {{
                    y: {{
                        beginAtZero: true,
                        ticks: {{
                            precision: 0
                        }}
                    }}
                }}
            }}
        }});
        
        // Graphique des points chauds
        var hotspotCtx = document.getElementById('hotspotChart').getContext('2d');
        var hotspotChart = new Chart(hotspotCtx, {{
            type: 'bar',
            data: {{
                labels: [{hotspot_labels}],
                datasets: [{{
                    label: 'Score de criticité',
                    data: [{hotspot_data}],
                    backgroundColor: '#dc3545'
                }}]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {{
                    legend: {{
                        display: false
                    }}
                }},
                scales: {{
                    y: {{
                        beginAtZero: true
                    }}
                }}
            }}
        }});
    </script>
</body>
</html>
"#,
            severity_data = severity_data,
            type_labels = type_labels,
            type_data = type_data,
            hotspot_labels = hotspot_labels,
            hotspot_data = hotspot_data
        ));
        
        // Écrire le rapport HTML dans un fichier
        let mut file = match File::create(output_path) {
            Ok(file) => file,
            Err(e) => {
                eprintln!("Erreur lors de la création du fichier de rapport HTML: {}", e);
                return;
            }
        };
        
        if let Err(e) = file.write_all(html_content.as_bytes()) {
            eprintln!("Erreur lors de l'écriture du rapport HTML: {}", e);
        }
    }
} 