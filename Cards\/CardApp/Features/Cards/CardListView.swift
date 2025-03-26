import SwiftUI

struct CardListView: View {
    @ObservedObject var viewModel: CardViewModel
    @State private var showAddCard = false
    @State private var searchText = ""
    @State private var selectedFilter: CardFilterOption = .all
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Barre de recherche
                SearchBar(text: $searchText, placeholder: "Rechercher une carte")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Filtres
                FilterBar(selectedOption: $selectedFilter) { option in
                    viewModel.filterOption = option
                }
                .padding(.bottom, 8)
                
                // Liste des cartes
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredCards.isEmpty {
                    EmptyStateView(
                        icon: "rectangle.on.rectangle",
                        title: "Aucune carte",
                        message: viewModel.cards.isEmpty ? 
                            "Ajoutez votre première carte" : 
                            "Aucune carte ne correspond aux critères de recherche"
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredCards) { card in
                            NavigationLink(destination: CardDetailView(card: card, viewModel: viewModel)) {
                                CardListItemView(card: card)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle(viewModel.selectedDeck?.name ?? "Toutes les cartes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddCard = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCard) {
                CardFormView(viewModel: viewModel)
            }
            .onAppear {
                // Synchroniser la valeur de searchText avec le ViewModel
                viewModel.searchText = searchText
                
                // S'il n'y a pas de cartes, charger les cartes
                if viewModel.cards.isEmpty {
                    viewModel.fetchCards(for: viewModel.selectedDeck)
                }
            }
            .onChange(of: searchText) { newValue in
                viewModel.searchText = newValue
            }
            .onChange(of: selectedFilter) { newValue in
                viewModel.filterOption = newValue
            }
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Erreur"),
                    message: Text(viewModel.errorMessage ?? "Une erreur est survenue"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct CardListItemView: View {
    let card: Card
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(card.question)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                // Badge de niveau de maîtrise
                MasteryBadge(level: card.masteryLevel)
            }
            
            Text(card.answer)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            // Informations supplémentaires
            HStack(spacing: 12) {
                // Statistiques de révision
                Label("\(card.reviewCount)", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Date de révision
                if let nextDate = card.nextReviewDate {
                    Label(nextDate, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundColor(card.isDue ? .red : .secondary)
                }
                
                Spacer()
                
                // Indicateur de carte marquée
                if card.isFlagged {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.red)
                }
                
                // Tags
                if !card.tags.isEmpty {
                    Image(systemName: "tag")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MasteryBadge: View {
    let level: MasteryLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.caption2)
            
            Text(level.title)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(level.color.opacity(0.2))
        .foregroundColor(level.color)
        .cornerRadius(4)
    }
}

struct FilterBar: View {
    @Binding var selectedOption: CardFilterOption
    var onSelect: (CardFilterOption) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CardFilterOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedOption = option
                        onSelect(option)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: option.icon)
                                .font(.footnote)
                            
                            Text(option.title)
                                .font(.footnote)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedOption == option ? option.color.opacity(0.2) : Color.secondary.opacity(0.1))
                        .foregroundColor(selectedOption == option ? option.color : .primary)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct EmptyStateView: View {
    var icon: String
    var title: String
    var message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CardFormView: View {
    @ObservedObject var viewModel: CardViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var question = ""
    @State private var answer = ""
    @State private var additionalInfo = ""
    @State private var tags = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Question")) {
                    TextEditor(text: $question)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Réponse")) {
                    TextEditor(text: $answer)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Informations supplémentaires (optionnel)")) {
                    TextEditor(text: $additionalInfo)
                        .frame(minHeight: 80)
                }
                
                Section(header: Text("Tags (séparés par des virgules)")) {
                    TextField("swift, programmation, code", text: $tags)
                }
            }
            .navigationTitle("Nouvelle carte")
            .navigationBarItems(
                leading: Button("Annuler") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Sauvegarder") {
                    saveCard()
                }
                .disabled(question.isEmpty || answer.isEmpty)
            )
        }
    }
    
    private func saveCard() {
        let tagArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        viewModel.createCard(
            question: question,
            answer: answer,
            additionalInfo: additionalInfo.isEmpty ? nil : additionalInfo,
            tags: tagArray
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct CardDetailView: View {
    let card: Card
    @ObservedObject var viewModel: CardViewModel
    @State private var isEditing = false
    @State private var editedCard: Card
    
    init(card: Card, viewModel: CardViewModel) {
        self.card = card
        self.viewModel = viewModel
        self._editedCard = State(initialValue: card)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // En-tête avec niveau de maîtrise
                HStack {
                    MasteryBadge(level: card.masteryLevel)
                    
                    Spacer()
                    
                    if card.isFlagged {
                        Label("Marquée", systemImage: "flag.fill")
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
                .padding(.bottom, 8)
                
                // Question
                VStack(alignment: .leading, spacing: 8) {
                    Text("Question")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(card.question)
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Réponse
                VStack(alignment: .leading, spacing: 8) {
                    Text("Réponse")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(card.answer)
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Informations supplémentaires
                if let info = card.additionalInfo, !info.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Informations supplémentaires")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(info)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Tags
                if !card.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(card.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Statistiques
                VStack(alignment: .leading, spacing: 8) {
                    Text("Statistiques")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        StatItem(value: "\(card.reviewCount)", label: "Révisions", icon: "arrow.clockwise")
                        
                        Divider()
                        
                        StatItem(value: "\(card.correctCount)", label: "Correctes", icon: "checkmark.circle", color: .green)
                        
                        Divider()
                        
                        StatItem(value: "\(card.incorrectCount)", label: "Incorrectes", icon: "xmark.circle", color: .red)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Date de révision
                    if let nextDate = card.nextReviewDate {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            
                            Text("Prochaine révision")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(nextDate, format: .dateTime.day().month().year())
                                .foregroundColor(card.isDue ? .red : .primary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Détail de la carte")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isEditing = true
                }) {
                    Text("Modifier")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            CardEditView(card: $editedCard, viewModel: viewModel, isPresented: $isEditing)
        }
    }
}

struct StatItem: View {
    var value: String
    var label: String
    var icon: String
    var color: Color = .blue
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CardEditView: View {
    @Binding var card: Card
    @ObservedObject var viewModel: CardViewModel
    @Binding var isPresented: Bool
    
    @State private var question: String
    @State private var answer: String
    @State private var additionalInfo: String
    @State private var tags: String
    @State private var isFlagged: Bool
    
    init(card: Binding<Card>, viewModel: CardViewModel, isPresented: Binding<Bool>) {
        self._card = card
        self.viewModel = viewModel
        self._isPresented = isPresented
        
        _question = State(initialValue: card.wrappedValue.question)
        _answer = State(initialValue: card.wrappedValue.answer)
        _additionalInfo = State(initialValue: card.wrappedValue.additionalInfo ?? "")
        _tags = State(initialValue: card.wrappedValue.tags.joined(separator: ", "))
        _isFlagged = State(initialValue: card.wrappedValue.isFlagged)
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
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Informations supplémentaires")) {
                    TextEditor(text: $additionalInfo)
                        .frame(minHeight: 80)
                }
                
                Section(header: Text("Tags (séparés par des virgules)")) {
                    TextField("swift, programmation, code", text: $tags)
                }
                
                Section {
                    Toggle("Marquer cette carte", isOn: $isFlagged)
                }
            }
            .navigationTitle("Modifier la carte")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        saveChanges()
                    }
                    .disabled(question.isEmpty || answer.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        let tagArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        var updatedCard = card
        updatedCard.question = question
        updatedCard.answer = answer
        updatedCard.additionalInfo = additionalInfo.isEmpty ? nil : additionalInfo
        updatedCard.tags = tagArray
        updatedCard.isFlagged = isFlagged
        updatedCard.updatedAt = Date()
        
        viewModel.updateCard(updatedCard)
        card = updatedCard
        isPresented = false
    }
}

struct CardListView_Previews: PreviewProvider {
    static var previews: some View {
        let persistence = PersistenceController.preview
        let service = CardService(context: persistence.container.viewContext)
        let viewModel = CardViewModel(cardService: service)
        
        return CardListView(viewModel: viewModel)
    }
} 