import SwiftUI

struct DeckSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var deckViewModel: DeckViewModel
    @EnvironmentObject var studyViewModel: StudyViewModel
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.top)
                
                if deckViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredDecks.isEmpty {
                    EmptyStateView(
                        title: "Aucun paquet",
                        message: "Créez d'abord un paquet pour pouvoir étudier",
                        systemImage: "rectangle.stack.badge.plus"
                    )
                } else {
                    List {
                        ForEach(filteredDecks) { deck in
                            DeckRow(deck: deck)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectDeck(deck)
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Choisir un paquet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                deckViewModel.loadDecks()
            }
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
    
    private func selectDeck(_ deck: Deck) {
        // Navigation vers StudyView
        let deckId = deck.id
        presentationMode.wrappedValue.dismiss()
        
        // Nous pouvons démarrer directement la session d'étude ici,
        // ou laisser la vue StudyView s'en charger via onAppear
        // studyViewModel.startSession(deckId: deckId)
    }
}

struct DeckSelectionRow: View {
    let deck: Deck
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(deck.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: deck.icon)
                    .font(.system(size: 24))
                    .foregroundColor(deck.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Text("\(deck.totalCards) cartes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if deck.dueCards > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text("\(deck.dueCards) à réviser")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct DeckSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let deckViewModel = DeckViewModel(context: context)
        let cardService = CardService(context: context)
        let studyViewModel = StudyViewModel(cardService: cardService)
        
        DeckSelectionView()
            .environmentObject(deckViewModel)
            .environmentObject(studyViewModel)
    }
} 