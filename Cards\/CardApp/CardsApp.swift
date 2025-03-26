import SwiftUI
import CoreData
import Combine

@main
struct CardsApp: App {
    // Services
    private let persistenceController = PersistenceController(inMemory: false)
    
    // ViewModels
    @StateObject private var cardViewModel: CardViewModel
    @StateObject private var deckViewModel: DeckViewModel  
    @StateObject private var studyViewModel: StudyViewModel

    // État de l'application
    @AppStorage("darkMode") private var darkMode = false
    @State private var showingAddDeck = false
    @State private var showingAddCard = false
    
    init() {
        // Initialiser les services
        let context = persistenceController.container.viewContext
        let cardService = CardService(context: context)
        
        // Initialiser les ViewModels
        let cardVM = CardViewModel(cardService: cardService)
        let deckVM = DeckViewModel(cardService: cardService)
        let studyVM = StudyViewModel(cardService: cardService)
        
        _cardViewModel = StateObject(wrappedValue: cardVM)
        _deckViewModel = StateObject(wrappedValue: deckVM)
        _studyViewModel = StateObject(wrappedValue: studyVM)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(cardViewModel)
                .environmentObject(deckViewModel)
                .environmentObject(studyViewModel)
                .preferredColorScheme(darkMode ? .dark : .light)
                .onAppear {
                    applyColorScheme(darkMode ? .dark : .light)
                }
        }
        #if os(macOS)
        // Menu des réglages
        Settings {
            Text("Paramètres")
                .environmentObject(cardViewModel)
                .environmentObject(deckViewModel)
                .environmentObject(studyViewModel)
                .preferredColorScheme(darkMode ? .dark : .light)
        }
        #endif
    }
    
    // Commandes pour macOS
    private var macOSCommands: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Nouveau paquet") {
                showingAddDeck = true
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            
            Button("Nouvelle carte") {
                showingAddCard = true
            }
            .keyboardShortcut("n", modifiers: [.command])
        }
    }
    
    private func applyColorScheme(_ scheme: ColorScheme) {
        #if os(macOS)
        NSApp.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        #endif
    }
}