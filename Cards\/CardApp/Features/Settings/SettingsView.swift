import SwiftUI

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("cardsPerSession") private var cardsPerSession = 20
    @AppStorage("reviewOrder") private var reviewOrder = "due"
    @State private var selectedTab = "general"
    
    var body: some View {
        #if os(macOS)
        macOSSettingsView
        #else
        iOSSettingsView
        #endif
    }
    
    // MARK: - macOS Layout
    private var macOSSettingsView: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Général", systemImage: "gear")
                    .tag("general")
                
                Label("Étude", systemImage: "book")
                    .tag("study")
                
                Label("Synchronisation", systemImage: "icloud")
                    .tag("sync")
                
                Label("À propos", systemImage: "info.circle")
                    .tag("about")
            }
            .listStyle(.sidebar)
        } detail: {
            ScrollView {
                VStack {
                    switch selectedTab {
                    case "general":
                        generalSettings
                    case "study":
                        studySettings
                    case "sync":
                        SyncSettingsView()
                    case "about":
                        aboutSettings
                    default:
                        generalSettings
                    }
                }
                .padding(20)
                .frame(maxWidth: 700)
            }
            .navigationTitle(navigationTitle)
            .frame(minWidth: 450, minHeight: 400)
        }
    }
    
    private var navigationTitle: String {
        switch selectedTab {
        case "general": return "Paramètres généraux"
        case "study": return "Paramètres d'étude"
        case "sync": return "Synchronisation et sauvegardes"
        case "about": return "À propos"
        default: return "Paramètres"
        }
    }
    
    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: settingsLabel("Apparence", systemImage: "paintbrush")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Mode sombre", isOn: $darkMode)
                        .toggleStyle(.switch)
                        .onChange(of: darkMode) { newValue in
                            applyColorScheme(newValue ? .dark : .light)
                        }
                        .padding(.vertical, 4)
                }
                .padding(.vertical, 6)
            }
            
            GroupBox(label: settingsLabel("Retour", systemImage: "waveform")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Activer les retours visuels", isOn: $hapticFeedback)
                        .toggleStyle(.switch)
                        .padding(.vertical, 4)
                }
                .padding(.vertical, 6)
            }
            
            GroupBox(label: settingsLabel("Raccourcis clavier", systemImage: "keyboard")) {
                VStack(alignment: .leading, spacing: 12) {
                    keyboardShortcutRow(key: "Espace", action: "Retourner la carte")
                    Divider()
                    keyboardShortcutRow(key: "1", action: "Evaluer: Encore")
                    keyboardShortcutRow(key: "2", action: "Evaluer: Difficile")
                    keyboardShortcutRow(key: "3", action: "Evaluer: Correct")
                    keyboardShortcutRow(key: "4", action: "Evaluer: Facile")
                    Divider()
                    keyboardShortcutRow(key: "⌘ E", action: "Terminer la session d'étude")
                    keyboardShortcutRow(key: "⌘ N", action: "Nouvelle carte")
                    keyboardShortcutRow(key: "⌘ ⇧ N", action: "Nouveau paquet")
                }
                .padding(.vertical, 6)
            }
            
            Spacer()
        }
    }
    
    private var studySettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: settingsLabel("Session d'étude", systemImage: "book")) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Cartes par session: \(cardsPerSession)")
                            .font(.headline)
                        
                        HStack {
                            Slider(value: Binding(
                                get: { Double(cardsPerSession) },
                                set: { cardsPerSession = Int($0) }
                            ), in: 5...50, step: 5)
                            .frame(maxWidth: 250)
                            
                            Text("\(cardsPerSession)")
                                .font(.headline)
                                .frame(width: 40)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading) {
                        Text("Ordre des révisions")
                            .font(.headline)
                        
                        Picker("", selection: $reviewOrder) {
                            Text("Par échéance").tag("due")
                            Text("Aléatoire").tag("random")
                            Text("Difficulté").tag("difficulty")
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
                .padding(.vertical, 8)
            }
            
            GroupBox(label: settingsLabel("Algorithme d'étude", systemImage: "function")) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("L'algorithme de répétition espacée détermine quand vous devriez revoir vos cartes pour une mémorisation optimale.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Encore:")
                                .font(.headline)
                            Text("5 minutes")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Difficile:")
                                .font(.headline)
                            Text("1 jour")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Correct:")
                                .font(.headline)
                            Text("3 jours")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Facile:")
                                .font(.headline)
                            Text("7 jours")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
        }
    }
    
    private var aboutSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: settingsLabel("À propos", systemImage: "info.circle")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Version")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("1.0.0")
                            .fontWeight(.medium)
                    }
                    
                    Divider()
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Politique de confidentialité")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.footnote)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("Conditions d'utilisation")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.footnote)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)
            }
            
            GroupBox(label: settingsLabel("Crédits", systemImage: "person.2")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Application créée avec SwiftUI.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    Text("© 2023 Tous droits réservés")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
            
            Spacer()
        }
    }
    
    private func keyboardShortcutRow(key: String, action: String) -> some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            
            Spacer()
            
            Text(action)
                .foregroundColor(.secondary)
        }
    }
    
    private func settingsLabel(_ text: String, systemImage: String) -> some View {
        Label {
            Text(text)
                .font(.headline)
        } icon: {
            Image(systemName: systemImage)
        }
    }
    
    private func applyColorScheme(_ scheme: ColorScheme) {
        #if os(macOS)
        NSApp.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        #endif
    }
    
    // MARK: - iOS Layout
    private var iOSSettingsView: some View {
        Form {
            Section(header: Text("Apparence")) {
                Toggle("Mode sombre", isOn: $darkMode)
            }
            
            Section(header: Text("Retour haptique")) {
                Toggle("Activer les vibrations", isOn: $hapticFeedback)
            }
            
            Section(header: Text("Session d'étude")) {
                Stepper("Cartes par session: \(cardsPerSession)", value: $cardsPerSession, in: 5...50, step: 5)
                
                Picker("Ordre des révisions", selection: $reviewOrder) {
                    Text("Par échéance").tag("due")
                    Text("Aléatoire").tag("random")
                    Text("Difficulté").tag("difficulty")
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("Synchronisation")) {
                NavigationLink(destination: SyncSettingsView()) {
                    Label("Synchronisation et sauvegardes", systemImage: "icloud")
                }
            }
            
            Section(header: Text("À propos")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    Text("Politique de confidentialité")
                }
                
                Link(destination: URL(string: "https://example.com/terms")!) {
                    Text("Conditions d'utilisation")
                }
            }
        }
        .navigationTitle("Paramètres")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 