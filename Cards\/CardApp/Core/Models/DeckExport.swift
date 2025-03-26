import Foundation

struct DeckExport: Codable {
    let name: String
    let description: String
    let icon: String
    let colorName: String
    let cards: [CardExport]
    let exportDate: Date
    let version: String
    
    init(name: String, description: String, icon: String, colorName: String, cards: [CardExport]) {
        self.name = name
        self.description = description
        self.icon = icon
        self.colorName = colorName
        self.cards = cards
        self.exportDate = Date()
        self.version = "1.0"
    }
}

struct CardExport: Codable {
    let question: String
    let answer: String
    let additionalInfo: String
}

extension DeckExport {
    func toDeck() -> Deck {
        return Deck(
            id: UUID(),
            name: name,
            description: description,
            icon: icon,
            colorName: colorName,
            createdAt: Date()
        )
    }
    
    static func fromJSON(data: Data) throws -> DeckExport {
        let decoder = JSONDecoder()
        return try decoder.decode(DeckExport.self, from: data)
    }
} 