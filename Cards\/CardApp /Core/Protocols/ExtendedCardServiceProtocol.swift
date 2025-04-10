import Foundation
import Combine

public protocol ExtendedCardServiceProtocol: CardServiceProtocol {
    /// Récupère les cartes avec pagination et filtrage avancé
    /// - Parameters:
    ///   - deckID: ID du paquet pour filtrer les cartes, nil pour toutes les cartes
    ///   - page: Numéro de page (commençant à 0)
    ///   - pageSize: Nombre de cartes par page
    ///   - searchText: Texte de recherche pour filtrer les cartes
    ///   - tags: Liste des tags pour filtrer les cartes
    ///   - matchAllTags: Si true, nécessite que tous les tags soient présents; sinon, au moins un tag
    ///   - sortOption: Option de tri pour les résultats
    ///   - filterOptions: Options de filtrage supplémentaires
    /// - Returns: Publisher avec les cartes filtrées et paginées
    func fetchCards(
        deckID: UUID?,
        page: Int,
        pageSize: Int,
        searchText: String,
        tags: [String],
        matchAllTags: Bool,
        sortOption: String,
        filterOptions: CardFilterOptions
    ) -> AnyPublisher<[Card], Error>
    
    /// Récupère les cartes avec filtrage simplifié
    /// - Parameters:
    ///   - deckID: ID du paquet, nil pour toutes les cartes
    ///   - filterOption: Option de filtrage prédéfinie
    /// - Returns: Publisher avec les cartes filtrées
    func fetchCards(
        deckID: UUID?,
        filterOption: CardFilterOption
    ) -> AnyPublisher<[Card], Error>
    
    /// Récupère le nombre total de cartes correspondant aux critères
    /// - Parameters:
    ///   - deckID: ID du paquet, nil pour toutes les cartes
    ///   - searchText: Texte de recherche
    ///   - tags: Tags pour filtrer
    ///   - filterOptions: Options de filtrage supplémentaires
    /// - Returns: Publisher avec le nombre de cartes
    func fetchCardCount(
        deckID: UUID?,
        searchText: String,
        tags: [String],
        filterOptions: CardFilterOptions
    ) -> AnyPublisher<Int, Error>
    
    /// Crée une nouvelle carte
    /// - Parameter card: Objet carte à créer
    /// - Returns: Publisher avec la carte créée
    func createCard(_ card: Card) -> AnyPublisher<Card, Error>
    
    /// Supprime une carte
    /// - Parameter id: ID de la carte à supprimer
    /// - Returns: Publisher indiquant le succès ou l'échec
    func deleteCard(_ id: UUID) -> AnyPublisher<Void, Error>
    
    /// Met à jour un lot de cartes
    /// - Parameter cards: Tableau de cartes à mettre à jour
    /// - Returns: Publisher avec les cartes mises à jour
    func batchUpdateCards(_ cards: [Card]) -> AnyPublisher<[Card], Error>
} 