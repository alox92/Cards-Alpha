import Foundation

/// Représente un paquet de cartes
public struct Deck: Identifiable, Codable, Sendable {
    /// Identifiant unique du paquet
    public let id: UUID
    
    /// Nom du paquet
    public let name: String
    
    /// Description du paquet
    public let description: String
    
    /// Icône du paquet
    public let icon: String
    
    /// Nom de la couleur du paquet
    public let colorName: String
    
    /// Tags associés au paquet
    public var tags: [String]
    
    /// Nombre de cartes dans le paquet
    public var cardCount: Int
    
    /// Date de création
    public let createdAt: Date
    
    /// Date de dernière mise à jour
    public var updatedAt: Date
    
    /// Initialisation d'un nouveau paquet
    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        icon: String = "rectangle.stack.fill",
        colorName: String = "blue",
        tags: [String] = [],
        cardCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.colorName = colorName
        self.tags = tags
        self.cardCount = cardCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Retourne une copie du paquet avec la date de mise à jour actualisée
    public func withUpdatedTimestamp() -> Deck {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }
    
    /// Retourne une copie du paquet avec un nouveau nombre de cartes
    public func withCardCount(_ count: Int) -> Deck {
        var copy = self
        copy.cardCount = count
        return copy
    }
    
    /// Retourne une copie du paquet avec un tag ajouté ou retiré
    public func toggleTag(_ tag: String) -> Deck {
        var copy = self
        if copy.tags.contains(tag) {
            copy.tags.removeAll { $0 == tag }
        } else {
            copy.tags.append(tag)
        }
        return copy
    }
    
    /// Crée un paquet de prévisualisation pour les tests
    public static func preview() -> Deck {
        return Deck(
            name: "Paquet de test",
            description: "Un paquet de test pour la prévisualisation",
            icon: "rectangle.stack.fill",
            colorName: "blue",
            tags: ["test", "preview"],
            cardCount: 10
        )
    }
} 