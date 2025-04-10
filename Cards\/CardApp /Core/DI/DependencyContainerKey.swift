import Foundation
import SwiftUI

// Protocole pour permettre d'avoir une valeur par défaut non-isolée
public protocol DefaultDependencyContainerProvider {
    static var defaultContainer: DependencyContainer { get }
}

// Classe statique non-isolée qui fournit la valeur par défaut
@objc public class DefaultDependencyContainer: NSObject, DefaultDependencyContainerProvider {
    public static let defaultContainer: DependencyContainer = DependencyContainer.preview
}

/// Clé d'environnement pour accéder au DependencyContainer.
public struct DependencyContainerKey: EnvironmentKey {
    /// Valeur par défaut (instance preview qui sera remplacée)
    public static let defaultValue = DependencyContainer.preview
}

/// Extension pour accéder au conteneur de dépendances via l'environnement.
extension EnvironmentValues {
    /// Accès au conteneur de dépendances
    public var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}
