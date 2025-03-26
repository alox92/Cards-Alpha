import SwiftUI
import Combine

struct DeckListView: View {
    @EnvironmentObject var deckViewModel: DeckViewModel
    @State private var searchText = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText)
                .padding(.top)
            
            if deckViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredDecks.isEmpty {
                EmptyStateView(
                    title: "Aucun paquet",
                    message: "Créez votre premier paquet pour commencer à étudier",
                    systemImage: "rectangle.stack.badge.plus",
                    action: { deckViewModel.isAddingDeck = true },
                    actionTitle: "Créer un paquet"
                )
            } else {
                List {
                    ForEach(filteredDecks) { deck in
                        NavigationLink(destination: DeckDetailView(deck: deck)) {
                            DeckRow(deck: deck)
                        }
                    }
                    .onDelete(perform: deleteDecks)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Paquets")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { deckViewModel.isAddingDeck = true }) {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                #if os(macOS)
                Button(action: { importDeck() }) {
                    Image(systemName: "square.and.arrow.down")
                }
                #endif
            }
        }
        .sheet(isPresented: $deckViewModel.isAddingDeck) {
            AddDeckView()
        }
    }
    
    private var filteredDecks: [Deck] {
        if searchText.isEmpty {
            return deckViewModel.decks
        } else {
            return deckViewModel.decks.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func deleteDecks(at offsets: IndexSet) {
        for index in offsets {
            let deck = deckViewModel.decks[index]
            deckViewModel.deleteDeck(deck)
        }
    }
    
    private func importDeck() {
        #if os(macOS)
        let openPanel = NSOpenPanel()
        let supportedTypes: [UTType] = ImportExportService.FileFormat.allCases.map { $0.contentType }
        openPanel.allowedContentTypes = supportedTypes
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Importer un paquet"
        openPanel.message = "Sélectionnez un fichier pour importer un paquet"
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            ImportExportService.shared.importDeck(from: url)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            print("Erreur lors de l'importation: \(error)")
                            #if os(macOS)
                            let alert = NSAlert()
                            alert.messageText = "Erreur d'importation"
                            alert.informativeText = error.localizedDescription
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                            #endif
                        }
                    },
                    receiveValue: { [weak self] _ in
                        self?.deckViewModel.loadDecks()
                    }
                )
                .store(in: &cancellables)
        }
        #endif
    }
}

struct DeckListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeckListView()
                .environmentObject(DeckViewModel.preview)
        }
    }
} 