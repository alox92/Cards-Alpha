import SwiftUI

enum CardEditMode {
    case create
    case edit
}

struct CardDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = CardViewModel()
    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var additionalInfo: String = ""
    @State private var selectedDeckID: UUID?
    @State private var showingDiscardAlert = false
    
    let mode: CardEditMode
    let card: Card?
    
    init(mode: CardEditMode, card: Card?) {
        self.mode = mode
        self.card = card
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Question")) {
                    TextEditor(text: $question)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Réponse")) {
                    TextEditor(text: $answer)
                        .frame(minHeight: 150)
                }
                
                Section(header: Text("Informations additionnelles (optionnel)")) {
                    TextEditor(text: $additionalInfo)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Paquet")) {
                    deckPicker
                }
            }
            .navigationTitle(mode == .create ? "Nouvelle carte" : "Modifier la carte")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        if hasUnsavedChanges() {
                            showingDiscardAlert = true
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(mode == .create ? "Créer" : "Enregistrer") {
                        saveCard()
                    }
                    .disabled(!isValid())
                }
            }
            .alert(isPresented: $showingDiscardAlert) {
                Alert(
                    title: Text("Modifications non enregistrées"),
                    message: Text("Voulez-vous abandonner les modifications?"),
                    primaryButton: .destructive(Text("Abandonner")) {
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(item: $viewModel.error) { error in
                Alert(
                    title: Text("Erreur"),
                    message: Text(error.localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                setupInitialValues()
                viewModel.fetchDecks()
            }
        }
    }
    
    private var deckPicker: some View {
        Picker("Sélectionner un paquet", selection: $selectedDeckID) {
            Text("Aucun paquet").tag(nil as UUID?)
            
            ForEach(viewModel.decks) { deck in
                Text(deck.name).tag(deck.id as UUID?)
            }
        }
        .pickerStyle(.menu)
    }
    
    private func setupInitialValues() {
        if let card = card, mode == .edit {
            question = card.question
            answer = card.answer
            additionalInfo = card.additionalInfo ?? ""
            selectedDeckID = card.deckID
        }
    }
    
    private func isValid() -> Bool {
        return !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func hasUnsavedChanges() -> Bool {
        if mode == .create {
            return !question.isEmpty || !answer.isEmpty || !additionalInfo.isEmpty
        } else if let card = card {
            return question != card.question ||
                   answer != card.answer ||
                   additionalInfo != (card.additionalInfo ?? "") ||
                   selectedDeckID != card.deckID
        }
        return false
    }
    
    private func saveCard() {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInfo = additionalInfo.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if mode == .create {
            let newCard = Card(
                id: UUID(),
                question: trimmedQuestion,
                answer: trimmedAnswer,
                additionalInfo: trimmedInfo.isEmpty ? nil : trimmedInfo,
                deckID: selectedDeckID,
                createdAt: Date(),
                updatedAt: Date(),
                masteryLevel: .new,
                reviewCount: 0,
                lastReviewedAt: nil,
                nextReviewDate: nil
            )
            
            viewModel.addCard(newCard)
        } else if let existingCard = card {
            let updatedCard = Card(
                id: existingCard.id,
                question: trimmedQuestion,
                answer: trimmedAnswer,
                additionalInfo: trimmedInfo.isEmpty ? nil : trimmedInfo,
                deckID: selectedDeckID,
                createdAt: existingCard.createdAt,
                updatedAt: Date(),
                masteryLevel: existingCard.masteryLevel,
                reviewCount: existingCard.reviewCount,
                lastReviewedAt: existingCard.lastReviewedAt,
                nextReviewDate: existingCard.nextReviewDate
            )
            
            viewModel.updateCard(updatedCard)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Previews
struct CardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CardDetailView(mode: .create, card: nil)
        
        CardDetailView(mode: .edit, card: Card(
            id: UUID(),
            question: "Qu'est-ce que SwiftUI?",
            answer: "Un framework déclaratif pour construire des interfaces utilisateur sur toutes les plateformes Apple.",
            additionalInfo: "Lancé en 2019 lors de la WWDC.",
            deckID: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            masteryLevel: .learning,
            reviewCount: 3,
            lastReviewedAt: Date().addingTimeInterval(-86400),
            nextReviewDate: Date().addingTimeInterval(86400)
        ))
    }
} 