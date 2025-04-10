import Foundation
import os.log

/// Implémentation étendue du gestionnaire de cache avec les méthodes utilisées dans CardViewModel
public class ExtendedCacheManager: CacheManagerProtocol {
    private let logger = Logger(subsystem: "com.app.cardapp", category: "ExtendedCacheManager")
    
    // Caches en mémoire
    private var cardCache: [UUID: (card: Card, expiry: Date)] = [:]
    private var deckCache: [UUID: (deck: Deck, expiry: Date)] = [:]
    
    // Durée de vie par défaut: 10 minutes
    private let defaultTTL: TimeInterval = 600
    
    // MARK: - Méthodes spécifiques pour CardViewModel
    
    /// Méthode de compatibilité pour getCachedCards(ids:) utilisée dans CardViewModel
    public func getCachedCards(for deckID: UUID?) -> [Card]? {
        if let deckID = deckID {
            return getCachedCardsForDeck(deckId: deckID)
        } else {
            // Si aucun paquet n'est spécifié, retourner toutes les cartes en cache
            let now = Date()
            let allCards = cardCache.values
                .filter { $0.expiry > now }
                .map { $0.card }
            
            return allCards.isEmpty ? nil : allCards
        }
    }
    
    /// Méthode de compatibilité pour cacheCards(_:ttl:) utilisée dans CardViewModel
    public func cacheCards(_ cards: [Card], for deckID: UUID?) {
        cacheCards(cards, ttl: defaultTTL)
    }
    
    /// Méthode de compatibilité pour invalidateCache utilisée dans CardViewModel
    public func invalidateCache(for deckID: UUID) {
        invalidateDeckWithCards(id: deckID)
    }
    
    // MARK: - Implémentation du protocole CacheManagerProtocol
    
    public func cacheCard(_ card: Card, ttl: TimeInterval? = nil) {
        let expiry = Date().addingTimeInterval(ttl ?? defaultTTL)
        cardCache[card.id] = (card: card, expiry: expiry)
        logger.debug("Carte \(card.id) mise en cache jusqu'à \(expiry)")
    }
    
    public func cacheCards(_ cards: [Card], ttl: TimeInterval? = nil) {
        let expiry = Date().addingTimeInterval(ttl ?? defaultTTL)
        
        for card in cards {
            cardCache[card.id] = (card: card, expiry: expiry)
        }
        
        logger.debug("\(cards.count) cartes mises en cache jusqu'à \(expiry)")
    }
    
    public func getCachedCard(id: UUID) -> Card? {
        guard let cached = cardCache[id], cached.expiry > Date() else {
            return nil
        }
        return cached.card
    }
    
    public func getCachedCards(ids: [UUID]) -> [Card] {
        let now = Date()
        let foundCards = ids.compactMap { id -> Card? in
            guard let cached = cardCache[id], cached.expiry > now else {
                return nil
            }
            return cached.card
        }
        return foundCards
    }
    
    public func getCachedCardsForDeck(deckId: UUID) -> [Card] {
        let now = Date()
        let deckCards = cardCache.values
            .filter { $0.expiry > now && $0.card.deckID == deckId }
            .map { $0.card }
        return deckCards
    }
    
    public func cacheDeck(_ deck: Deck, ttl: TimeInterval? = nil) {
        let expiry = Date().addingTimeInterval(ttl ?? defaultTTL)
        deckCache[deck.id] = (deck: deck, expiry: expiry)
        logger.debug("Paquet \(deck.id) mis en cache jusqu'à \(expiry)")
    }
    
    public func cacheDecks(_ decks: [Deck], ttl: TimeInterval? = nil) {
        let expiry = Date().addingTimeInterval(ttl ?? defaultTTL)
        
        for deck in decks {
            deckCache[deck.id] = (deck: deck, expiry: expiry)
        }
        
        logger.debug("\(decks.count) paquets mis en cache jusqu'à \(expiry)")
    }
    
    public func getCachedDeck(id: UUID) -> Deck? {
        guard let cached = deckCache[id], cached.expiry > Date() else {
            return nil
        }
        return cached.deck
    }
    
    public func getCachedDecks(ids: [UUID]) -> [Deck] {
        let now = Date()
        let foundDecks = ids.compactMap { id -> Deck? in
            guard let cached = deckCache[id], cached.expiry > now else {
                return nil
            }
            return cached.deck
        }
        return foundDecks
    }
    
    public func invalidateCardCache(id: UUID) {
        cardCache.removeValue(forKey: id)
        logger.debug("Cache de la carte \(id) invalidé")
    }
    
    public func invalidateDeckCache(id: UUID) {
        deckCache.removeValue(forKey: id)
        logger.debug("Cache du paquet \(id) invalidé")
    }
    
    public func invalidateDeckWithCards(id: UUID) {
        invalidateDeckCache(id: id)
        
        // Supprimer toutes les cartes appartenant à ce paquet
        let cardsToRemove = cardCache.filter { $0.value.card.deckID == id }
        for cardID in cardsToRemove.keys {
            cardCache.removeValue(forKey: cardID)
        }
        
        logger.debug("Cache du paquet \(id) et de ses \(cardsToRemove.count) cartes invalidé")
    }
    
    public func clearExpiredEntries() {
        let now = Date()
        
        let cardCountBefore = cardCache.count
        cardCache = cardCache.filter { $0.value.expiry > now }
        
        let deckCountBefore = deckCache.count
        deckCache = deckCache.filter { $0.value.expiry > now }
        
        let cardRemoved = cardCountBefore - cardCache.count
        let deckRemoved = deckCountBefore - deckCache.count
        
        if cardRemoved > 0 || deckRemoved > 0 {
            logger.debug("Entrées expirées supprimées: \(cardRemoved) cartes, \(deckRemoved) paquets")
        }
    }
    
    public func clearCardCache() {
        let count = cardCache.count
        cardCache.removeAll()
        logger.debug("\(count) cartes supprimées du cache")
    }
    
    public func clearDeckCache() {
        let count = deckCache.count
        deckCache.removeAll()
        logger.debug("\(count) paquets supprimés du cache")
    }
    
    public func clearAllCaches() {
        let cardCount = cardCache.count
        let deckCount = deckCache.count
        
        cardCache.removeAll()
        deckCache.removeAll()
        
        logger.debug("Tous les caches vidés: \(cardCount) cartes, \(deckCount) paquets")
    }
    
    public var cardCacheCount: Int {
        return cardCache.count
    }
    
    public var deckCacheCount: Int {
        return deckCache.count
    }
    
    public var cardCacheSize: Int {
        return cardCache.values.reduce(0) { result, entry in
            result + calculateCardFootprint(entry.card)
        }
    }
    
    public var deckCacheSize: Int {
        return deckCache.values.reduce(0) { result, entry in
            result + calculateDeckFootprint(entry.deck)
        }
    }
    
    public var totalCacheSize: Int {
        return cardCacheSize + deckCacheSize
    }
    
    public func calculateCardFootprint(_ card: Card) -> Int {
        // Estimation approximative en octets
        let questionSize = card.question.count * 2 // ~2 octets par caractère UTF-16
        let answerSize = card.answer.count * 2
        let additionalInfoSize = (card.additionalInfo?.count ?? 0) * 2
        let tagsSize = card.tags.reduce(0) { $0 + $1.count * 2 }
        
        // Taille fixe pour les propriétés primitives (UUID, Date, Bool, etc.)
        let fixedSize = 200
        
        return questionSize + answerSize + additionalInfoSize + tagsSize + fixedSize
    }
    
    public func calculateDeckFootprint(_ deck: Deck) -> Int {
        // Estimation approximative en octets
        let nameSize = deck.name.count * 2 // ~2 octets par caractère UTF-16
        let descriptionSize = deck.description.count * 2
        let iconSize = deck.icon.count * 2
        let colorNameSize = deck.colorName.count * 2
        let tagsSize = deck.tags.reduce(0) { $0 + $1.count * 2 }
        
        // Taille fixe pour les propriétés primitives
        let fixedSize = 100
        
        return nameSize + descriptionSize + iconSize + colorNameSize + tagsSize + fixedSize
    }
    
    public func adaptCacheSizeToAvailableMemory() {
        // Dans une vraie implémentation, on ajusterait la taille du cache
        // en fonction de la mémoire disponible
        
        // Pour cette version simplifiée, on limite simplement le nombre d'entrées
        let maxEntries = 1000
        
        if cardCache.count > maxEntries {
            // Supprimer les entrées les plus anciennes
            let sortedEntries = cardCache.sorted { $0.value.expiry < $1.value.expiry }
            let entriesToRemove = sortedEntries.prefix(cardCache.count - maxEntries)
            
            for entry in entriesToRemove {
                cardCache.removeValue(forKey: entry.key)
            }
            
            logger.debug("Cache adapté: \(entriesToRemove.count) cartes anciennes supprimées")
        }
    }
} 