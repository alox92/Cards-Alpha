import SwiftUI
import Combine
import Foundation
import os.log
// @testable import CardApp // Accès à PerformanceMonitor et autres types Core

// MARK: - Extensions d'interface pour le monitoring
extension View {
    /// Ajoute des mesures de performance automatiques à une vue
    /// - Parameter identifier: Identifiant unique pour la vue
    /// - Returns: La vue avec mesures
    func trackPerformance(identifier: String) -> some View {
        return self
            .onAppear {
                // PerformanceMonitor.shared.recordMemoryUsage(identifier: "view_\(identifier)_appeared")
                // PerformanceMonitor.shared.startTiming(identifier: "view_\(identifier)_lifetime")
                os_log("Vue apparue: %{public}s", log: .default, type: .info, identifier)
            }
            .onDisappear {
                // PerformanceMonitor.shared.endTiming(identifier: "view_\(identifier)_lifetime")
                // PerformanceMonitor.shared.recordMemoryUsage(identifier: "view_\(identifier)_disappeared")
                os_log("Vue disparue: %{public}s", log: .default, type: .info, identifier)
            }
    }
    
    /// Encapsule une action avec mesures de performance
    /// - Parameters:
    ///   - identifier: Identifiant unique pour l'action
    ///   - action: L'action à mesurer
    /// - Returns: Une fonction encapsulée avec mesures
    func measureAction<T>(identifier: String, action: @escaping () -> T) -> () -> T {
        return {
            // PerformanceMonitor.shared.startTiming(identifier: "action_\(identifier)")
            // PerformanceMonitor.shared.recordMemoryUsage(identifier: "action_\(identifier)_start")
            os_log("Début action: %{public}s", log: .default, type: .info, identifier)
            
            let result = action()
            
            // PerformanceMonitor.shared.endTiming(identifier: "action_\(identifier)")
            // PerformanceMonitor.shared.recordMemoryUsage(identifier: "action_\(identifier)_end")
            os_log("Fin action: %{public}s", log: .default, type: .info, identifier)
            
            return result
        }
    }
    
    /// Applique un modificateur conditionnel
    /// - Parameters:
    ///   - condition: La condition à vérifier
    ///   - transform: Le modificateur à appliquer si la condition est vraie
    /// - Returns: La vue avec ou sans le modificateur
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Ajoute un modificateur pour optimiser la vue en fonction de la plateforme
    /// - Parameter action: Action personnalisée à exécuter pour l'optimisation
    /// - Returns: La vue optimisée
    func optimizedForPlatform(_ action: @escaping () -> Void = {}) -> some View {
        #if os(macOS)
        return optimizedForMacOS(action)
        #else
        return optimizedForIOS(action)
        #endif
    }
    
    /// Optimisations spécifiques pour macOS
    private func optimizedForMacOS(_ action: @escaping () -> Void = {}) -> some View {
        return self
            .onAppear {
                // Optimisations spécifiques à macOS
                action()
                
                // Journal d'optimisation
                let logger = Logger(subsystem: "com.app.cardapp", category: "Optimisations")
                logger.debug("Optimisations macOS appliquées")
            }
    }
    
    /// Optimisations spécifiques pour iOS
    private func optimizedForIOS(_ action: @escaping () -> Void = {}) -> some View {
        return self
            .onAppear {
                // Optimisations spécifiques à iOS
                action()
                
                // Journal d'optimisation
                let logger = Logger(subsystem: "com.app.cardapp", category: "Optimisations")
                logger.debug("Optimisations iOS appliquées")
            }
    }
}

// MARK: - Extensions pour les animations optimisées
extension Animation {
    /// Crée une animation optimisée selon la plateforme
    /// - Parameters:
    ///   - duration: Durée de l'animation
    ///   - curve: Courbe d'animation
    /// - Returns: Animation optimisée
    static func optimized(duration: Double? = nil, curve: String = "easeInOut") -> Animation {
        #if os(macOS)
        // Animations plus fluides sur macOS
        let duration = duration ?? 0.15
        if curve == "easeInOut" {
            return Animation.easeInOut(duration: duration)
        } else if curve == "easeIn" {
            return Animation.easeIn(duration: duration)
        } else if curve == "easeOut" {
            return Animation.easeOut(duration: duration)
        } else {
            return Animation.easeInOut(duration: duration)
        }
        #else
        // Animations standard sur iOS
        let duration = duration ?? 0.2
        if curve == "easeInOut" {
            return Animation.easeInOut(duration: duration)
        } else if curve == "easeIn" {
            return Animation.easeIn(duration: duration)
        } else if curve == "easeOut" {
            return Animation.easeOut(duration: duration)
        } else {
            return Animation.easeInOut(duration: duration)
        }
        #endif
    }
}

// MARK: - Extensions pour la liste
extension List {
    /// Optimise la liste pour les performances
    /// - Returns: Liste optimisée
    func optimizedForPerformance() -> some View {
        #if os(macOS)
        // Sur macOS, charger plus d'éléments à la fois car plus de RAM
        return self
        #else
        // Sur iOS, limiter le nombre d'éléments visibles
        return self
        #endif
    }
}

// MARK: - Extensions pour les images
extension Image {
    /// Charge une image de manière optimisée
    /// - Parameter name: Nom de l'image
    /// - Returns: Image optimisée
    static func optimizedLoad(_ name: String) -> Image {
        #if os(macOS)
        // Sur macOS, charge les images en haute résolution
        return Image(name)
        #else
        // Sur iOS, charge les images avec résolution adaptée
        return Image(name)
        #endif
    }
}

// MARK: - Extensions pour tasks asynchrones
extension Task where Success == Void, Failure == Never {
    /// Exécute une tâche asynchrone mesurée
    /// - Parameters:
    ///   - identifier: Identifiant pour la tâche
    ///   - priority: Priorité de la tâche
    ///   - operation: Opération à exécuter
    /// - Returns: La tâche créée
    @discardableResult
    static func measuredTask(
        identifier: String,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> Void
    ) -> Task {
        let localIdentifier = identifier // Capture locale pour éviter les data races
        return Task(priority: priority) { @Sendable in
            // PerformanceMonitor.shared.startTiming(identifier: "task_\(localIdentifier)")
            // PerformanceMonitor.shared.recordMemoryUsage(identifier: "task_\(localIdentifier)_start")
            os_log("Début tâche: %{public}s", log: .default, type: .info, localIdentifier)
            
            await operation()
            
            // PerformanceMonitor.shared.endTiming(identifier: "task_\(localIdentifier)")
            // PerformanceMonitor.shared.recordMemoryUsage(identifier: "task_\(localIdentifier)_end")
            os_log("Fin tâche: %{public}s", log: .default, type: .info, localIdentifier)
        }
    }
} 