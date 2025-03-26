import SwiftUI
import Combine

struct DeckDetailView: View {
    @EnvironmentObject var cardViewModel: CardViewModel
    @EnvironmentObject var deckViewModel: DeckViewModel
    @State private var showingAddCard = false
    @State private var showingEditDeck = false
    @State private var searchText = ""
    private let deck: Deck
    private var cancellables = Set<AnyCancellable>()
    
    init(deck: Deck) {
        self.deck = deck
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // En-tête avec les informations du deck
            DeckHeaderView(deck: deck)
                .padding()
                .background(deck.color.opacity(0.1))
            
            // Filtres et recherche
            VStack(spacing: 8) {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                FilterBar(
                    selectedFilter: $cardViewModel.filterOption,
                    options: CardFilterOption.allCases,
                    iconForOption: { $0.systemImage }
                )
                .padding(.horizontal)
            }
            .padding(.top)
            
            // Liste des cartes
            if cardViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredCards.isEmpty {
                EmptyStateView(
                    title: "Aucune carte",
                    message: "Ajoutez votre première carte à ce paquet",
                    systemImage: "rectangle.stack.badge.plus",
                    action: { showingAddCard = true },
                    actionTitle: "Ajouter une carte"
                )
            } else {
                List {
                    ForEach(filteredCards) { card in
                        NavigationLink(destination: CardDetailView(card: card)) {
                            CardRow(card: card)
                        }
                    }
                    .onDelete(perform: deleteCards)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(deck.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCard = true }) {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditDeck = true }) {
                        Label("Modifier le paquet", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        // Démarrer une session d'étude
                        if let studyViewModel = deckViewModel.studyViewModel {
                            studyViewModel.startSession(deckId: deck.id)
                        }
                    }) {
                        Label("Étudier", systemImage: "book.fill")
                    }
                    
                    Divider()
                    
                    Button(action: { exportDeck() }) {
                        Label("Exporter le paquet", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        // Supprimer le paquet
                        deckViewModel.deleteDeck(deck)
                    }) {
                        Label("Supprimer le paquet", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            AddCardView()
        }
        .sheet(isPresented: $showingEditDeck) {
            EditDeckView(deck: deck)
        }
        .onAppear {
            cardViewModel.fetchCards(for: deck.id)
        }
    }
    
    private var filteredCards: [Card] {
        if searchText.isEmpty {
            return cardViewModel.filteredCards
        } else {
            return cardViewModel.filteredCards.filter { card in
                card.question.localizedCaseInsensitiveContains(searchText) ||
                card.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            let card = filteredCards[index]
            cardViewModel.deleteCard(card)
        }
    }
    
    private func exportDeck() {
        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = ImportExportService.FileFormat.allCases.map { $0.contentType }
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = deck.name
        savePanel.title = "Exporter le paquet"
        savePanel.message = "Choisissez le format et l'emplacement d'exportation pour \(deck.name)"
        
        // Créer un bouton de sélection de format
        let formatPopup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 200, height: 25))
        for format in ImportExportService.FileFormat.allCases {
            formatPopup.addItem(withTitle: format.description)
            formatPopup.lastItem?.representedObject = format
            if format == .json {
                formatPopup.selectItem(at: formatPopup.numberOfItems - 1)
            }
        }
        
        let formatView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 30))
        let formatLabel = NSTextField(labelWithString: "Format d'exportation:")
        formatLabel.frame = NSRect(x: 0, y: 5, width: 130, height: 20)
        formatView.addSubview(formatLabel)
        formatPopup.frame = NSRect(x: 140, y: 0, width: 260, height: 25)
        formatView.addSubview(formatPopup)
        
        savePanel.accessoryView = formatView
        
        formatPopup.target = savePanel
        formatPopup.action = #selector(NSSavePanel.didChangeFormatPopup(_:))
        
        if savePanel.runModal() == .OK, let url = savePanel.url, let selectedItem = formatPopup.selectedItem {
            // Récupérer le format sélectionné
            guard let format = selectedItem.representedObject as? ImportExportService.FileFormat else {
                return
            }
            
            // Utiliser le service pour l'exportation
            ImportExportService.shared.exportDeck(deck, to: format)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            let alert = NSAlert()
                            alert.messageText = "Erreur lors de l'exportation"
                            alert.informativeText = error.localizedDescription
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    },
                    receiveValue: { tempURL in
                        // Copier le fichier temporaire vers l'emplacement choisi par l'utilisateur
                        let finalURL = url.appendingPathExtension(format.rawValue)
                        try? FileManager.default.removeItem(at: finalURL)
                        try? FileManager.default.copyItem(at: tempURL, to: finalURL)
                    }
                )
                .store(in: &cancellables)
        }
        #endif
    }
}

struct DeckHeaderView: View {
    let deck: Deck
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(deck.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: deck.icon)
                        .font(.system(size: 30))
                        .foregroundColor(deck.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !deck.description.isEmpty {
                        Text(deck.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Statistiques du deck
            DeckStatsView(deck: deck)
        }
    }
}

struct DeckStatsView: View {
    let deck: Deck
    
    var body: some View {
        HStack(spacing: 20) {
            StatColumn(title: "Total", value: "\(deck.totalCards)")
            StatColumn(title: "À étudier", value: "\(deck.dueCards)")
            StatColumn(title: "Succès", value: deck.formattedSuccessRate)
            StatColumn(title: "Maîtrisées", value: "\(deck.masteredCards)")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Placeholders pour éviter les erreurs de compilation
struct EditDeckView: View {
    let deck: Deck
    
    var body: some View {
        Text("Modifier le paquet")
    }
}

// MARK: - Previews
struct DeckDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeckDetailView(deck: Deck.preview)
                .environmentObject(CardViewModel.preview)
                .environmentObject(DeckViewModel.preview)
        }
    }
} 