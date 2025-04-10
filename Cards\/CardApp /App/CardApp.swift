import SwiftUI
 
/// Application principale pour l'étude des cartes
public struct CardApp: App {
    @StateObject var container = DependencyContainer.shared
    
    public init() {
        // Initialisation minimale
    }
    
    public var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(container)
        }
    }
}

/// Vue principale de l'application, évite les conflits avec d'autres ContentView
struct MainView: View {
    @EnvironmentObject var container: DependencyContainer
    
    var body: some View {
        TabView {
            DeckListView()
                .tabItem {
                    Label("Paquets", systemImage: "rectangle.stack")
                }
            
            CardsListView()
                .tabItem {
                    Label("Cartes", systemImage: "rectangle.on.rectangle")
                }
            
            StudyView()
                .tabItem {
                    Label("Étude", systemImage: "books.vertical")
                }
            
            SettingsView()
                .tabItem {
                    Label("Paramètres", systemImage: "gear")
                }
        }
        .onAppear {
            container.initialize()
        }
    }
}

// Vues temporaires pour la compilation
struct DeckListView: View {
    var body: some View {
        Text("Liste des paquets")
    }
}

struct CardsListView: View {
    var body: some View {
        Text("Liste des cartes")
    }
}

struct StudyView: View {
    var body: some View {
        Text("Vue d'étude")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Paramètres")
    }
}

// MARK: - Previews
struct CardApp_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(DependencyContainer.shared)
    }
} 