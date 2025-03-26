import SwiftUI

struct StudyDashboardView: View {
    @EnvironmentObject var deckViewModel: DeckViewModel
    @EnvironmentObject var studyViewModel: StudyViewModel
    
    var body: some View {
        VStack {
            if deckViewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if deckViewModel.decks.isEmpty {
                EmptyStateView(
                    title: "Aucun paquet",
                    message: "Créez un paquet de cartes pour commencer à étudier",
                    systemImage: "rectangle.stack.badge.plus",
                    action: {
                        // Aller à l'onglet des paquets
                    },
                    actionTitle: "Voir les paquets"
                )
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        studyHeader
                        
                        deckCarousel
                        
                        sectionHeader(title: "À réviser aujourd'hui")
                        
                        dueDecksGrid
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Étudier")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    studyViewModel.showDeckSelection = true
                }) {
                    Image(systemName: "play.circle")
                        .font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $studyViewModel.showDeckSelection) {
            NavigationStack {
                DeckSelectionView()
                    .navigationTitle("Choisir un paquet")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            deckViewModel.loadDecks()
        }
    }
    
    private var studyHeader: some View {
        VStack(spacing: 8) {
            Text("Votre progression d'aujourd'hui")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                studyStatCard(count: totalDueCards, title: "À réviser", icon: "calendar", color: .blue)
                studyStatCard(count: totalStudiedToday, title: "Étudiées", icon: "checkmark.circle", color: .green)
            }
        }
    }
    
    private var deckCarousel: some View {
        VStack(spacing: 8) {
            sectionHeader(title: "Vos paquets")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(deckViewModel.decks) { deck in
                        NavigationLink(destination: DeckDetailView(deck: deck)) {
                            deckCarouselCard(deck: deck)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
    }
    
    private var dueDecksGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(deckViewModel.dueDecks) { deck in
                NavigationLink(destination: StudyView(deckId: deck.id)) {
                    dueDeckCard(deck: deck)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if deckViewModel.dueDecks.isEmpty {
                Text("Aucun paquet à réviser aujourd'hui")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
    
    private func studyStatCard(count: Int, title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 28))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 20, weight: .bold))
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func deckCarouselCard(deck: Deck) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(deck.name)
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Text("\(deck.cardCount) cartes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                MasteryLevelBadge(level: .mastered)
                    .scaleEffect(0.8)
            }
            
            if deck.cardCount > 0 {
                ProgressView(value: deck.progressPercentage, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
            }
        }
        .padding()
        .frame(width: 180, height: 120)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func dueDeckCard(deck: Deck) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(deck.name)
                .font(.headline)
                .lineLimit(1)
            
            Spacer()
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                
                Text("\(deck.dueTodayCount) à réviser")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            NavigationLink(destination: StudyView(deckId: deck.id)) {
                Text("Étudier")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .frame(height: 130)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var totalDueCards: Int {
        deckViewModel.decks.reduce(0) { $0 + $1.dueTodayCount }
    }
    
    private var totalStudiedToday: Int {
        // À remplacer par les données réelles
        return studyViewModel.getStudiedCardsToday().count
    }
}

// MARK: - Previews
struct StudyDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let deckViewModel = DeckViewModel(context: context)
        let cardService = CardService(context: context)
        let studyViewModel = StudyViewModel(cardService: cardService)
        
        StudyDashboardView()
            .environmentObject(deckViewModel)
            .environmentObject(studyViewModel)
    }
} 