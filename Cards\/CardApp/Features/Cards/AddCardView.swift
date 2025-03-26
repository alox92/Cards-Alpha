import SwiftUI

struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardViewModel: CardViewModel
    @EnvironmentObject var deckViewModel: DeckViewModel
    
    // Données de la carte
    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var selectedDeckId: UUID?
    @State private var selectedTab: Int = 0 // 0: Question, 1: Réponse
    
    // Validation
    @State private var isQuestionValid: Bool = false
    @State private var isAnswerValid: Bool = false
    @State private var isDeckSelected: Bool = false
    
    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }
    
    // MARK: - Layouts
    
    private var macOSLayout: some View {
        VStack(spacing: 0) {
            // Barre d'outils
            HStack {
                Spacer()
                
                Button("Annuler") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Créer") {
                    createCard()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(!isFormValid)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            // Contenu
            HSplitView {
                // Panel de gauche - Formulaire
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Paquet")
                            .font(.headline)
                        
                        Picker("", selection: $selectedDeckId) {
                            Text("Sélectionner un paquet")
                                .tag(nil as UUID?)
                            
                            ForEach(deckViewModel.decks) { deck in
                                Text(deck.name)
                                    .tag(deck.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedDeckId) { newValue in
                            isDeckSelected = newValue != nil
                        }
                        
                        if !isDeckSelected {
                            Text("Veuillez sélectionner un paquet")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Divider()
                    
                    TabView(selection: $selectedTab) {
                        questionFormView
                            .tabItem {
                                Label("Question", systemImage: "questionmark.circle")
                            }
                            .tag(0)
                        
                        answerFormView
                            .tabItem {
                                Label("Réponse", systemImage: "text.bubble")
                            }
                            .tag(1)
                    }
                    .frame(minHeight: 300)
                }
                .padding()
                .frame(width: 350)
                
                // Panel de droite - Aperçu
                VStack {
                    Text("Aperçu")
                        .font(.headline)
                        .padding(.top)
                    
                    Spacer()
                    
                    // Aperçu de la carte
                    ZStack {
                        // Face avant (Question)
                        cardPreview(question)
                            .opacity(selectedTab == 0 ? 1 : 0)
                        
                        // Face arrière (Réponse)
                        cardPreview(answer)
                            .opacity(selectedTab == 1 ? 1 : 0)
                    }
                    .frame(width: 300, height: 200)
                    
                    Spacer()
                    
                    // Boutons de navigation
                    HStack {
                        Button(action: {
                            selectedTab = 0
                        }) {
                            Text("Question")
                                .frame(width: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedTab == 0)
                        
                        Button(action: {
                            selectedTab = 1
                        }) {
                            Text("Réponse")
                                .frame(width: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedTab == 1)
                    }
                    .padding(.bottom)
                }
                .frame(minWidth: 350)
                .background(Color(.textBackgroundColor).opacity(0.05))
            }
        }
        .frame(width: 750, height: 500)
        .onAppear {
            if deckViewModel.decks.isEmpty {
                deckViewModel.loadDecks()
            }
        }
    }
    
    private var iOSLayout: some View {
        NavigationView {
            VStack {
                Picker("", selection: $selectedTab) {
                    Text("Question").tag(0)
                    Text("Réponse").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    questionFormView
                } else {
                    answerFormView
                }
                
                VStack {
                    Text("Paquet")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Picker("Paquet", selection: $selectedDeckId) {
                        Text("Sélectionner un paquet")
                            .tag(nil as UUID?)
                        
                        ForEach(deckViewModel.decks) { deck in
                            Text(deck.name)
                                .tag(deck.id as UUID?)
                        }
                    }
                    .pickerStyle(.wheel)
                    .onChange(of: selectedDeckId) { newValue in
                        isDeckSelected = newValue != nil
                    }
                    
                    if !isDeckSelected {
                        Text("Veuillez sélectionner un paquet")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Nouvelle carte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        createCard()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                if deckViewModel.decks.isEmpty {
                    deckViewModel.loadDecks()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var questionFormView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Question")
                .font(.headline)
            
            TextEditor(text: $question)
                .frame(minHeight: 150)
                .border(Color.gray.opacity(0.2))
                .onChange(of: question) { newValue in
                    isQuestionValid = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
            
            if !isQuestionValid && !question.isEmpty {
                Text("La question ne peut pas être vide")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Text("Conseils:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("• Soyez concis et précis\n• Évitez les questions ambiguës\n• Une seule idée par carte")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var answerFormView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Réponse")
                .font(.headline)
            
            TextEditor(text: $answer)
                .frame(minHeight: 150)
                .border(Color.gray.opacity(0.2))
                .onChange(of: answer) { newValue in
                    isAnswerValid = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
            
            if !isAnswerValid && !answer.isEmpty {
                Text("La réponse ne peut pas être vide")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Text("Conseils:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("• Soyez concis et précis\n• Répondez directement à la question\n• Évitez les informations superflues")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func cardPreview(_ content: String) -> some View {
        VStack {
            Text(content.isEmpty ? "Saisissez votre texte dans le formulaire" : content)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
        .padding()
    }
    
    // MARK: - Properties
    
    private var isFormValid: Bool {
        isQuestionValid && isAnswerValid && isDeckSelected
    }
    
    // MARK: - Functions
    
    private func createCard() {
        guard isFormValid, let deckId = selectedDeckId else { return }
        
        cardViewModel.createCard(
            question: question.trimmingCharacters(in: .whitespacesAndNewlines),
            answer: answer.trimmingCharacters(in: .whitespacesAndNewlines),
            deckId: deckId
        )
        
        dismiss()
    }
} 