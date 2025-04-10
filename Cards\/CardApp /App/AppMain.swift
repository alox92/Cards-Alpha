import SwiftUI
import Foundation
import CoreData
 

// Point d'entrée principal de l'application
@main
struct CardAppMain: App {
    // Référence globale à AppDelegate pour iOS
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    // Conteneur de dépendances partagé à travers l'application
    @StateObject var container = DependencyContainer.shared

    var body: some Scene {
        WindowGroup {
            MainContentView(container: container)
        }
        
        #if os(macOS)
        // Commandes spécifiques à macOS
        .commands {
            CommandGroup(after: .newItem) {
                Button("Nouvelle carte") {
                    // À implémenter : créer une nouvelle carte
                    print("Nouvelle carte")
                }
                
                Button("Nouveau paquet") {
                    // À implémenter : créer un nouveau paquet
                    print("Nouveau paquet")
                }
                
                Button("Commencer une session d'étude") {
                    // À implémenter : démarrer une session d'étude
                    print("Session d'étude")
                }
            }
        }
        #endif
    }
}

// Vue principale qui gère l'état de chargement
struct MainContentView: View {
    @ObservedObject var container: DependencyContainer
    @State private var isLoaded = false
    
    var body: some View {
        Group {
            if isLoaded {
                MainNavigationView(container: container)
            } else {
                SplashScreenView()
                    .onAppear {
                        // Simuler un temps de chargement
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isLoaded = true
                        }
                    }
            }
        }
    }
}

// Vue de navigation principale adaptée à la plateforme
struct MainNavigationView: View {
    @ObservedObject var container: DependencyContainer
    
    // Les ViewModels principaux de l'application
    @StateObject private var cardViewModel: CardViewModel
    @StateObject private var tagsViewModel: TagsManagementViewModel
    
    init(container: DependencyContainer) {
        self.container = container
        
        // Initialiser les ViewModels avec les services du container
        _cardViewModel = StateObject(wrappedValue: CardViewModel(container: container))
        _tagsViewModel = StateObject(wrappedValue: TagsManagementViewModel(tagService: container.tagService))
    }
    
    var body: some View {
        #if os(macOS)
        // Interface macOS avec barre latérale
        NavigationView {
            List {
                NavigationLink(destination: Text("Liste des cartes")) {
                    Label("Cartes", systemImage: "rectangle.on.rectangle")
                }
                
                NavigationLink(destination: Text("Gestion des tags")) {
                    Label("Tags", systemImage: "tag")
                }
                
                NavigationLink(destination: Text("Statistiques à implémenter")) {
                    Label("Statistiques", systemImage: "chart.bar")
                }
                
                NavigationLink(destination: Text("Paramètres à implémenter")) {
                    Label("Paramètres", systemImage: "gear")
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            
            // Vue par défaut
            Text("Sélectionnez une option dans la barre latérale")
                .font(.title)
                .foregroundColor(.secondary)
        }
        #else
        // Interface iOS avec onglets
        TabView {
            Text("Liste des cartes")
                .tabItem {
                    Label("Cartes", systemImage: "rectangle.on.rectangle")
                }
            
            Text("Gestion des tags")
                .tabItem {
                    Label("Tags", systemImage: "tag")
                }
            
            Text("Statistiques à implémenter")
                .tabItem {
                    Label("Statistiques", systemImage: "chart.bar")
                }
            
            Text("Paramètres à implémenter")
                .tabItem {
                    Label("Paramètres", systemImage: "gear")
                }
        }
        #endif
    }
}

// Vue d'écran de démarrage
struct SplashScreenView: View {
    var body: some View {
        VStack {
            Image(systemName: "rectangle.stack.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("CardApp")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
        }
    }
} 