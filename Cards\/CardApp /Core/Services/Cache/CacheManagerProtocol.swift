import Foundation

/**
 Protocole définissant les fonctionnalités d'un gestionnaire de cache.
 
 Ce protocole permet de gérer le cache des objets Card et Deck pour optimiser
 les performances et réduire les accès à la base de données.
 */
public protocol CacheManagerProtocol {
    // MARK: - Gestion du cache pour les cartes
    
    /// Stocke une carte dans le cache
    /// - Parameters:
    ///   - card: La carte à stocker
    ///   - ttl: Durée de vie dans le cache (en secondes), nil pour la valeur par défaut
    func cacheCard(_ card: Card, ttl: TimeInterval?)
    
    /// Stocke plusieurs cartes dans le cache
    /// - Parameters:
    ///   - cards: Les cartes à stocker
    ///   - ttl: Durée de vie dans le cache (en secondes), nil pour la valeur par défaut
    func cacheCards(_ cards: [Card], ttl: TimeInterval?)
    
    /// Récupère une carte du cache
    /// - Parameter id: L'identifiant de la carte
    /// - Returns: La carte si elle existe dans le cache, nil sinon
    func getCachedCard(id: UUID) -> Card?
    
    /// Récupère plusieurs cartes du cache
    /// - Parameter ids: Les identifiants des cartes
    /// - Returns: Les cartes trouvées dans le cache (peut être un sous-ensemble des ids demandés)
    func getCachedCards(ids: [UUID]) -> [Card]
    
    /// Récupère toutes les cartes mises en cache pour un paquet
    /// - Parameter deckId: L'identifiant du paquet
    /// - Returns: Les cartes du paquet trouvées dans le cache
    func getCachedCardsForDeck(deckId: UUID) -> [Card]
    
    // MARK: - Gestion du cache pour les paquets
    
    /// Stocke un paquet dans le cache
    /// - Parameters:
    ///   - deck: Le paquet à stocker
    ///   - ttl: Durée de vie dans le cache (en secondes), nil pour la valeur par défaut
    func cacheDeck(_ deck: Deck, ttl: TimeInterval?)
    
    /// Stocke plusieurs paquets dans le cache
    /// - Parameters:
    ///   - decks: Les paquets à stocker
    ///   - ttl: Durée de vie dans le cache (en secondes), nil pour la valeur par défaut
    func cacheDecks(_ decks: [Deck], ttl: TimeInterval?)
    
    /// Récupère un paquet du cache
    /// - Parameter id: L'identifiant du paquet
    /// - Returns: Le paquet s'il existe dans le cache, nil sinon
    func getCachedDeck(id: UUID) -> Deck?
    
    /// Récupère plusieurs paquets du cache
    /// - Parameter ids: Les identifiants des paquets
    /// - Returns: Les paquets trouvés dans le cache (peut être un sous-ensemble des ids demandés)
    func getCachedDecks(ids: [UUID]) -> [Deck]
    
    // MARK: - Gestion générale du cache
    
    /// Invalide une entrée de cache de carte spécifique
    /// - Parameter id: L'identifiant de la carte
    func invalidateCardCache(id: UUID)
    
    /// Invalide une entrée de cache de paquet spécifique
    /// - Parameter id: L'identifiant du paquet
    func invalidateDeckCache(id: UUID)
    
    /// Invalide toutes les entrées de cache liées à un paquet
    /// (le paquet lui-même et toutes ses cartes)
    /// - Parameter id: L'identifiant du paquet
    func invalidateDeckWithCards(id: UUID)
    
    /// Supprime toutes les entrées expirées du cache
    func clearExpiredEntries()
    
    /// Vide le cache des cartes
    func clearCardCache()
    
    /// Vide le cache des paquets
    func clearDeckCache()
    
    /// Vide tous les caches
    func clearAllCaches()
    
    // MARK: - Statistiques et informations sur le cache
    
    /// Retourne le nombre d'entrées dans le cache des cartes
    var cardCacheCount: Int { get }
    
    /// Retourne le nombre d'entrées dans le cache des paquets
    var deckCacheCount: Int { get }
    
    /// Retourne la taille approximative en mémoire du cache des cartes (en octets)
    var cardCacheSize: Int { get }
    
    /// Retourne la taille approximative en mémoire du cache des paquets (en octets)
    var deckCacheSize: Int { get }
    
    /// Retourne la taille totale approximative en mémoire de tous les caches (en octets)
    var totalCacheSize: Int { get }
    
    /// Calcule l'empreinte mémoire d'une carte
    /// - Parameter card: La carte
    /// - Returns: Taille approximative en octets
    func calculateCardFootprint(_ card: Card) -> Int
    
    /// Calcule l'empreinte mémoire d'un paquet (sans ses cartes)
    /// - Parameter deck: Le paquet
    /// - Returns: Taille approximative en octets
    func calculateDeckFootprint(_ deck: Deck) -> Int
    
    /// Ajuste dynamiquement la taille du cache en fonction de la mémoire disponible
    func adaptCacheSizeToAvailableMemory()
} 