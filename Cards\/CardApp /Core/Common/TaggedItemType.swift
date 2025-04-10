import Foundation

/// Type énuméré définissant les différents types d'éléments pouvant être tagués
public enum TaggedItemType: String, Codable, CaseIterable, Sendable {
    /// Une carte mémoire individuelle
    case card
    
    /// Un paquet de cartes
    case deck
    
    /// Retourne le nom localisé du type
    public var localizedName: String {
        switch self {
        case .card:
            return "Carte"
        case .deck:
            return "Paquet"
        }
    }
    
    /// Retourne une icône pour ce type d'item
    public var iconName: String {
        switch self {
        case .card:
            return "doc.text"
        case .deck:
            return "rectangle.stack"
        }
    }
} 