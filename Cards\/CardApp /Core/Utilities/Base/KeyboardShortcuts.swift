import SwiftUI

/// Gestion centralisée des raccourcis clavier pour macOS
struct KeyboardShortcuts {
    
    // MARK: - Navigation
    struct Navigation {
        /// Raccourci pour basculer la sidebar
        static let toggleSidebar = KeyboardShortcut("s", modifiers: [.command, .control])
        
        /// Navigation entre les sections principales
        static let goToDecks = KeyboardShortcut("1", modifiers: [.command])
        static let goToCards = KeyboardShortcut("2", modifiers: [.command])
        static let goToStudy = KeyboardShortcut("3", modifiers: [.command])
        static let goToStats = KeyboardShortcut("4", modifiers: [.command])
        static let goToSettings = KeyboardShortcut("5", modifiers: [.command])
        
        /// Navigation dans les listes
        static let nextItem = KeyboardShortcut(.downArrow, modifiers: [])
        static let previousItem = KeyboardShortcut(.upArrow, modifiers: [])
        static let selectItem = KeyboardShortcut(.return, modifiers: [])
    }
    
    // MARK: - Édition
    struct Editing {
        /// Création et édition
        static let newCard = KeyboardShortcut("n", modifiers: [.command])
        static let newDeck = KeyboardShortcut("n", modifiers: [.command, .shift])
        static let edit = KeyboardShortcut("e", modifiers: [.command])
        static let delete = KeyboardShortcut(.delete, modifiers: [.command])
        static let save = KeyboardShortcut("s", modifiers: [.command])
        static let cancel = KeyboardShortcut(.escape, modifiers: [])
        
        /// Formatage
        static let bold = KeyboardShortcut("b", modifiers: [.command])
        static let italic = KeyboardShortcut("i", modifiers: [.command])
        static let underline = KeyboardShortcut("u", modifiers: [.command])
    }
    
    // MARK: - Étude
    struct Study {
        /// Navigation dans les cartes
        static let nextCard = KeyboardShortcut(.rightArrow, modifiers: [])
        static let previousCard = KeyboardShortcut(.leftArrow, modifiers: [])
        static let showAnswer = KeyboardShortcut(.space, modifiers: [])
        
        /// Évaluation des cartes
        static let againRating = KeyboardShortcut("1", modifiers: [])
        static let hardRating = KeyboardShortcut("2", modifiers: [])
        static let goodRating = KeyboardShortcut("3", modifiers: [])
        static let easyRating = KeyboardShortcut("4", modifiers: [])
        
        /// Contrôle de session
        static let startSession = KeyboardShortcut("b", modifiers: [.command])
        static let endSession = KeyboardShortcut(.escape, modifiers: [])
        static let pauseSession = KeyboardShortcut("p", modifiers: [.command])
    }
    
    // MARK: - Recherche et filtres
    struct Search {
        /// Recherche globale
        static let focusSearch = KeyboardShortcut("f", modifiers: [.command])
        static let clearSearch = KeyboardShortcut(.escape, modifiers: [])
        
        /// Filtres
        static let showAll = KeyboardShortcut("0", modifiers: [.command, .shift])
        static let showDue = KeyboardShortcut("d", modifiers: [.command, .shift])
        static let showFlagged = KeyboardShortcut("f", modifiers: [.command, .shift])
        static let showNew = KeyboardShortcut("n", modifiers: [.command, .shift])
    }
    
    // MARK: - Actions spéciales macOS
    struct MacOSSpecific {
        /// Gestion des fenêtres multiples
        static let newWindow = KeyboardShortcut("n", modifiers: [.command, .option])
        static let closeWindow = KeyboardShortcut("w", modifiers: [.command])
        
        /// Mode focus
        static let enterFullScreen = KeyboardShortcut("f", modifiers: [.command, .control])
        
        /// Export / Import
        static let exportDeck = KeyboardShortcut("e", modifiers: [.command, .shift])
        static let importDeck = KeyboardShortcut("i", modifiers: [.command, .shift])
        
        /// Actualisation
        static let refresh = KeyboardShortcut("r", modifiers: [.command])
    }
}

// MARK: - Extension pour l'aide au raccourci
extension KeyboardShortcuts {
    /// Générer une aide structurée pour les raccourcis
    static func generateShortcutHelp() -> [String: [ShortcutHelpItem]] {
        return [
            "Navigation": [
                ShortcutHelpItem(name: "Basculer la sidebar", shortcut: Navigation.toggleSidebar),
                ShortcutHelpItem(name: "Aller aux paquets", shortcut: Navigation.goToDecks),
                ShortcutHelpItem(name: "Aller aux cartes", shortcut: Navigation.goToCards),
                ShortcutHelpItem(name: "Aller à l'étude", shortcut: Navigation.goToStudy),
                ShortcutHelpItem(name: "Aller aux statistiques", shortcut: Navigation.goToStats),
                ShortcutHelpItem(name: "Aller aux paramètres", shortcut: Navigation.goToSettings)
            ],
            "Édition": [
                ShortcutHelpItem(name: "Nouvelle carte", shortcut: Editing.newCard),
                ShortcutHelpItem(name: "Nouveau paquet", shortcut: Editing.newDeck),
                ShortcutHelpItem(name: "Modifier", shortcut: Editing.edit),
                ShortcutHelpItem(name: "Supprimer", shortcut: Editing.delete),
                ShortcutHelpItem(name: "Enregistrer", shortcut: Editing.save),
                ShortcutHelpItem(name: "Annuler", shortcut: Editing.cancel)
            ],
            "Étude": [
                ShortcutHelpItem(name: "Carte suivante", shortcut: Study.nextCard),
                ShortcutHelpItem(name: "Carte précédente", shortcut: Study.previousCard),
                ShortcutHelpItem(name: "Afficher la réponse", shortcut: Study.showAnswer),
                ShortcutHelpItem(name: "Évaluation: Encore", shortcut: Study.againRating),
                ShortcutHelpItem(name: "Évaluation: Difficile", shortcut: Study.hardRating),
                ShortcutHelpItem(name: "Évaluation: Bien", shortcut: Study.goodRating),
                ShortcutHelpItem(name: "Évaluation: Facile", shortcut: Study.easyRating)
            ],
            "Recherche": [
                ShortcutHelpItem(name: "Rechercher", shortcut: Search.focusSearch),
                ShortcutHelpItem(name: "Afficher tout", shortcut: Search.showAll),
                ShortcutHelpItem(name: "Afficher à réviser", shortcut: Search.showDue),
                ShortcutHelpItem(name: "Afficher marqués", shortcut: Search.showFlagged)
            ],
            "Spécial macOS": [
                ShortcutHelpItem(name: "Nouvelle fenêtre", shortcut: MacOSSpecific.newWindow),
                ShortcutHelpItem(name: "Plein écran", shortcut: MacOSSpecific.enterFullScreen),
                ShortcutHelpItem(name: "Exporter paquet", shortcut: MacOSSpecific.exportDeck),
                ShortcutHelpItem(name: "Importer paquet", shortcut: MacOSSpecific.importDeck),
                ShortcutHelpItem(name: "Actualiser", shortcut: MacOSSpecific.refresh)
            ]
        ]
    }
}

// MARK: - Modèle pour l'aide
@available(macOS 12.0, *)
struct ShortcutHelpItem: Identifiable {
    let id = UUID()
    let name: String
    let shortcut: KeyboardShortcut
    
    var displayText: String {
        var modifiers = ""
        
        if shortcut.modifiers.contains(.command) {
            modifiers += "⌘"
        }
        if shortcut.modifiers.contains(.option) {
            modifiers += "⌥"
        }
        if shortcut.modifiers.contains(.control) {
            modifiers += "⌃"
        }
        if shortcut.modifiers.contains(.shift) {
            modifiers += "⇧"
        }
        
        // Gérer les touches spéciales
        var keyString = ""
        
        // Version simplifiée pour contourner les problèmes de compatibilité
        let keyEquiv = String(describing: shortcut.key)
        
        // Analyse basée sur la description
        if keyEquiv.contains("return") {
            keyString = "↩"
        } else if keyEquiv.contains("escape") {
            keyString = "⎋"
        } else if keyEquiv.contains("delete") {
            keyString = "⌫"
        } else if keyEquiv.contains("space") {
            keyString = "Space"
        } else if keyEquiv.contains("upArrow") {
            keyString = "↑"
        } else if keyEquiv.contains("downArrow") {
            keyString = "↓"
        } else if keyEquiv.contains("leftArrow") {
            keyString = "←"
        } else if keyEquiv.contains("rightArrow") {
            keyString = "→"
        } else {
            // Pour les caractères simples, utiliser le dernier caractère de la description
            if let lastChar = keyEquiv.last, lastChar.isLetter || lastChar.isNumber {
                keyString = String(lastChar).uppercased()
            } else {
                keyString = "?"
            }
        }
        
        return "\(modifiers)\(keyString)"
    }
}

// MARK: - Vue d'aide pour les raccourcis
struct KeyboardShortcutsHelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Raccourcis Clavier")
                .font(.title)
                .padding(.top)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(KeyboardShortcuts.generateShortcutHelp().keys.sorted()), id: \.self) { category in
                        if let shortcuts = KeyboardShortcuts.generateShortcutHelp()[category] {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category)
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                Divider()
                                
                                ForEach(shortcuts) { item in
                                    HStack {
                                        Text(item.name)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text(item.displayText)
                                            .font(.system(.body, design: .monospaced))
                                            .padding(4)
                                            .background(Color.secondary.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                }
                .padding()
            }
            
            Button("Fermer") {
                presentationMode.wrappedValue.dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            .padding(.bottom)
        }
        .frame(width: 500, height: 600)
    }
}

// Extension pour faciliter l'utilisation
extension View {
    /// Ajoute une aide contextuelle avec raccourci
    @available(macOS 12.0, *)
    func withShortcutHelp(_ description: String, shortcut: KeyboardShortcut) -> some View {
        self
            .keyboardShortcut(shortcut)
            .help("\(description) (\(ShortcutHelpItem(name: "", shortcut: shortcut).displayText))")
    }
    
    /// Ajoute un raccourci sans aide
    func addShortcut(_ shortcut: KeyboardShortcut) -> some View {
        self.keyboardShortcut(shortcut)
    }
} 