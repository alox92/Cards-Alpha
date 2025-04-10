import Foundation

/// Modèle représentant un tag
public struct Tag: Identifiable, Codable, Hashable, Sendable {
    // MARK: - Propriétés d'identification
    public let id: UUID
    
    // MARK: - Contenu du tag
    public var name: String
    public var color: String
    public var description: String?
    
    // MARK: - Statistiques
    public var usage: Int
    
    // MARK: - Méta-données
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialisation
    public init(
        id: UUID = UUID(),
        name: String,
        color: String = "blue",
        description: String? = nil,
        usage: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.description = description
        self.usage = usage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Méthodes Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Méthodes utilitaires
    
    /// Retourne une copie du tag avec une date de mise à jour actualisée
    public func withUpdatedTimestamp() -> Tag {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }
    
    /// Retourne une copie du tag avec un nouveau compteur d'utilisation
    public func withUsageCount(_ count: Int) -> Tag {
        var copy = self
        copy.usage = count
        copy.updatedAt = Date()
        return copy
    }
    
    /// Incrémente le compteur d'utilisation du tag
    public func incrementUsage() -> Tag {
        var copy = self
        copy.usage += 1
        copy.updatedAt = Date()
        return copy
    }
    
    /// Décrémente le compteur d'utilisation du tag
    public func decrementUsage() -> Tag {
        var copy = self
        copy.usage = max(0, usage - 1)
        copy.updatedAt = Date()
        return copy
    }
} 