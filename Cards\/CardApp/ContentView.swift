import SwiftUI
import CoreData
import Combine

// Import les ViewModels
typealias CardViewModel = CardApp.Features.Cards.CardViewModel
typealias DeckViewModel = CardApp.Features.Decks.DeckViewModel
typealias StudyViewModel = CardApp.Features.Study.StudyViewModel

struct ContentView: View {
    @EnvironmentObject private var cardViewModel: CardViewModel
    @EnvironmentObject private var deckViewModel: DeckViewModel
    @EnvironmentObject private var studyViewModel: StudyViewModel
    
    @State private var selection: Int? = 0
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: Text("Paquets"), tag: 0, selection: $selection) {
                    Label("Paquets", systemImage: "rectangle.stack")
                }
                
                NavigationLink(destination: Text("Cartes"), tag: 1, selection: $selection) {
                    Label("Cartes", systemImage: "square.stack")
                }
                
                NavigationLink(destination: Text("Étudier"), tag: 2, selection: $selection) {
                    Label("Étudier", systemImage: "book")
                }
                
                NavigationLink(destination: Text("Statistiques"), tag: 3, selection: $selection) {
                    Label("Statistiques", systemImage: "chart.bar")
                }
                
                NavigationLink(destination: Text("Paramètres"), tag: 4, selection: $selection) {
                    Label("Paramètres", systemImage: "gear")
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            
            Text("Sélectionnez une option dans le menu")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 500)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        deckViewModel.fetchDecks()
        cardViewModel.fetchCards(for: nil)
    }
}

// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview non disponible")
    }
} 