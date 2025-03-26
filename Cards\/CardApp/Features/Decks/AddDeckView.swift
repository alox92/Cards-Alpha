import SwiftUI

struct AddDeckView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckViewModel: DeckViewModel
    
    // Données du paquet
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var icon: String = "rectangle.stack"
    @State private var colorName: String = "blue"
    
    // Validation
    @State private var isNameValid: Bool = false
    
    // Sélection
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    
    // Constantes
    private let availableIcons = [
        "rectangle.stack", "book", "doc.text", "brain", "graduationcap", 
        "lightbulb", "list.bullet", "bookmark", "tag", "flame", 
        "star", "heart", "globe", "clock", "calendar", 
        "gamecontroller", "music.note", "mic", "leaf", "wand.and.stars"
    ]
    
    private let availableColors = [
        "blue", "indigo", "purple", "pink", "red", 
        "orange", "yellow", "green", "mint", "teal", 
        "gray"
    ]
    
    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }
    
    // MARK: - Layouts
    
    private var macOSLayout: some View {
        VStack {
            HStack {
                Spacer()
                
                Button("Annuler") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Créer") {
                    createDeck()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(!isNameValid)
            }
            .padding(.horizontal)
            .padding(.top)
            
            Form {
                VStack(alignment: .leading, spacing: 20) {
                    // Aperçu
                    HStack {
                        Spacer()
                        
                        deckPreview
                            .frame(width: 200, height: 150)
                        
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    // Nom et description
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nom")
                                .font(.headline)
                            
                            TextField("Nom du paquet", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: name) { newValue in
                                    isNameValid = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                }
                            
                            if !isNameValid && !name.isEmpty {
                                Text("Veuillez entrer un nom valide")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            
                            TextEditor(text: $description)
                                .frame(height: 80)
                                .border(Color.gray.opacity(0.3), width: 1)
                        }
                    }
                    
                    // Icône et couleur
                    HStack(spacing: 20) {
                        // Icône
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icône")
                                .font(.headline)
                            
                            Picker("", selection: $icon) {
                                ForEach(availableIcons, id: \.self) { iconName in
                                    Image(systemName: iconName)
                                        .tag(iconName)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 150)
                        }
                        
                        // Couleur
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Couleur")
                                .font(.headline)
                            
                            Picker("", selection: $colorName) {
                                ForEach(availableColors, id: \.self) { color in
                                    HStack {
                                        Circle()
                                            .fill(Color(color))
                                            .frame(width: 16, height: 16)
                                        Text(color.capitalized)
                                    }
                                    .tag(color)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 150)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private var iOSLayout: some View {
        NavigationView {
            Form {
                Section(header: Text("Aperçu")) {
                    HStack {
                        Spacer()
                        deckPreview
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
                Section(header: Text("Informations")) {
                    TextField("Nom du paquet", text: $name)
                        .onChange(of: name) { newValue in
                            isNameValid = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }
                    
                    if !isNameValid && !name.isEmpty {
                        Text("Veuillez entrer un nom valide")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Description (facultative)", text: $description)
                }
                
                Section(header: Text("Apparence")) {
                    HStack {
                        Text("Icône")
                        Spacer()
                        Button(action: { showingIconPicker.toggle() }) {
                            HStack {
                                Image(systemName: icon)
                                    .foregroundColor(Color(colorName))
                                Text("Modifier")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Couleur")
                        Spacer()
                        Button(action: { showingColorPicker.toggle() }) {
                            HStack {
                                Circle()
                                    .fill(Color(colorName))
                                    .frame(width: 20, height: 20)
                                Text("Modifier")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $icon, availableIcons: availableIcons)
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $colorName, availableColors: availableColors)
            }
            .navigationTitle("Nouveau paquet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        createDeck()
                    }
                    .disabled(!isNameValid)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var deckPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(colorName).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(colorName))
                }
                
                VStack(alignment: .leading) {
                    Text(name.isEmpty ? "Titre du paquet" : name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(description.isEmpty ? "Description du paquet" : description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            HStack {
                Text("0 cartes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("0 à réviser")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: 0, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(colorName)))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(width: 250, height: 120)
    }
    
    // MARK: - Helper Views
    
    // Vue pour sélectionner une icône (iOS)
    struct IconPickerView: View {
        @Environment(\.dismiss) private var dismiss
        @Binding var selectedIcon: String
        let availableIcons: [String]
        
        var body: some View {
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                                dismiss()
                            }) {
                                Image(systemName: icon)
                                    .font(.system(size: 30))
                                    .frame(width: 60, height: 60)
                                    .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                .navigationTitle("Choisir une icône")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Terminé") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // Vue pour sélectionner une couleur (iOS)
    struct ColorPickerView: View {
        @Environment(\.dismiss) private var dismiss
        @Binding var selectedColor: String
        let availableColors: [String]
        
        var body: some View {
            NavigationView {
                List {
                    ForEach(availableColors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                            dismiss()
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 24, height: 24)
                                
                                Text(color.capitalized)
                                    .padding(.leading, 8)
                                
                                Spacer()
                                
                                if selectedColor == color {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .navigationTitle("Choisir une couleur")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Terminé") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Functions
    
    private func createDeck() {
        guard isNameValid else { return }
        
        deckViewModel.createDeck(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: icon,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            colorName: colorName
        )
        
        dismiss()
    }
} 