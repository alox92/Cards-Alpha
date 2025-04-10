import Foundation
import SwiftUI

/// Protocole pour définir une clé d'injection
public protocol InjectionKey {
    /// Type de la valeur associée à cette clé
    associatedtype Value
    
    /// Valeur par défaut pour cette clé
    static var currentValue: Value { get set }
}

// Le reste du fichier est supprimé car redondant ou obsolète. 