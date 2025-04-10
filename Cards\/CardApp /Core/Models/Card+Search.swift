import Foundation

// Comme CardFilterOptions est défini dans le même module, aucun import supplémentaire n'est nécessaire
// Si CardFilterOptions était dans un autre module, nous aurions besoin de l'importer

extension Card {
    /// Vérifie si la carte contient le texte de recherche dans ses principaux champs
    /// - Parameter searchText: Texte à rechercher
    /// - Returns: Vrai si la carte contient le texte, faux sinon
    public func contains(searchText: String) -> Bool {
        // Si le texte de recherche est vide, la carte correspond automatiquement
        guard !searchText.isEmpty else { return true }
        
        let lowercasedText = searchText.lowercased()
        
        // Vérifier chaque champ
        return question.lowercased().contains(lowercasedText) ||
               answer.lowercased().contains(lowercasedText) ||
               (additionalInfo?.lowercased().contains(lowercasedText) ?? false) ||
               tags.contains { $0.lowercased().contains(lowercasedText) }
    }
    
    /// Vérifie si la carte contient au moins un des tags spécifiés
    /// - Parameter tags: Liste des tags à vérifier
    /// - Returns: Vrai si la carte contient au moins un des tags, faux sinon
    public func containsAny(tags: [String]) -> Bool {
        // Si aucun tag n'est spécifié, la carte correspond automatiquement
        guard !tags.isEmpty else { return true }
        
        // Convertir en minuscules pour une recherche insensible à la casse
        let lowercasedTags = tags.map { $0.lowercased() }
        let cardLowercasedTags = self.tags.map { $0.lowercased() }
        
        // Vérifier si au moins un tag correspond
        return !Set(lowercasedTags).isDisjoint(with: Set(cardLowercasedTags))
    }
    
    /// Vérifie si la carte contient tous les tags spécifiés
    /// - Parameter tags: Liste des tags à vérifier
    /// - Returns: Vrai si la carte contient tous les tags, faux sinon
    public func containsAll(tags: [String]) -> Bool {
        // Si aucun tag n'est spécifié, la carte correspond automatiquement
        guard !tags.isEmpty else { return true }
        
        // Convertir en minuscules pour une recherche insensible à la casse
        let lowercasedTags = tags.map { $0.lowercased() }
        let cardLowercasedTags = self.tags.map { $0.lowercased() }
        
        // Vérifier si tous les tags sont présents
        return lowercasedTags.allSatisfy { searchTag in
            cardLowercasedTags.contains(searchTag)
        }
    }
    
    /// Détermine si la carte correspond aux critères de recherche et de filtre spécifiés
    /// - Parameters:
    ///   - searchText: Texte à rechercher dans les champs de la carte
    ///   - tags: Tags à rechercher dans la carte (peut être nil pour ignorer)
    ///   - matchAllTags: Si vrai, la carte doit contenir tous les tags spécifiés
    ///   - includeArchived: Si faux, les cartes archivées sont exclues
    ///   - dateRange: Plage de dates pour filtrer par date de création ou modification
    ///   - filterType: Type de filtre de date (création ou modification)
    /// - Returns: Vrai si la carte correspond à tous les critères spécifiés
    public func matches(
        searchText: String = "",
        tags: [String]? = nil,
        matchAllTags: Bool = false,
        includeArchived: Bool = true,
        dateRange: (start: Date?, end: Date?)? = nil,
        filterType: DateFilterType = .creationDate
    ) -> Bool {
        // Vérifier si la carte est archivée et si elle doit être incluse
        // Note: Si isFlagged existe, on peut l'utiliser comme proxy pour "archived"
        // Sinon, on peut utiliser une autre propriété ou ignorer ce filtre
        let archived = isFlagged // ou une autre propriété qui indique l'archivage
        if archived && !includeArchived {
            return false
        }
        
        // Vérifier le texte de recherche
        if !contains(searchText: searchText) {
            return false
        }
        
        // Vérifier les tags si spécifiés
        if let tagsToMatch = tags, !tagsToMatch.isEmpty {
            if matchAllTags {
                if !containsAll(tags: tagsToMatch) {
                    return false
                }
            } else {
                if !containsAny(tags: tagsToMatch) {
                    return false
                }
            }
        }
        
        // Vérifier la plage de dates si spécifiée
        if let range = dateRange {
            let dateToCheck: Date = filterType == .creationDate ? createdAt : updatedAt
            
            if let startDate = range.start, dateToCheck < startDate {
                return false
            }
            
            if let endDate = range.end, dateToCheck > endDate {
                return false
            }
        }
        
        // Si toutes les vérifications sont passées, la carte correspond
        return true
    }
    
    /// Détermine si la carte correspond aux critères de recherche avancés
    /// - Parameters:
    ///   - searchText: Texte à rechercher
    ///   - tags: Tags à filtrer
    ///   - matchAllTags: Si vrai, la carte doit contenir tous les tags
    ///   - filterOptions: Options avancées de filtrage
    /// - Returns: Vrai si la carte correspond aux critères
    public func matches(
        searchText: String,
        tags: [String],
        matchAllTags: Bool,
        filterOptions: CardFilterOptions
    ) -> Bool {
        // Vérifier le texte de recherche
        if !searchText.isEmpty && !contains(searchText: searchText) {
            return false
        }
        
        // Vérifier les tags
        if !tags.isEmpty {
            if matchAllTags {
                if !containsAll(tags: tags) {
                    return false
                }
            } else {
                if !containsAny(tags: tags) {
                    return false
                }
            }
        }
        
        // Vérifier si la carte est archivée
        if isFlagged && !filterOptions.includeArchived {
            return false
        }
        
        // Vérifier l'état d'apprentissage
        switch filterOptions.learningState {
        case .new:
            if masteryLevel != .novice {
                return false
            }
        case .learning:
            if masteryLevel != .beginner && masteryLevel != .intermediate {
                return false
            }
        case .mastered:
            if masteryLevel != .advanced && masteryLevel != .expert {
                return false
            }
        case .dueForReview:
            if nextReviewDate == nil || nextReviewDate! > Date() {
                return false
            }
        case .all:
            // Aucun filtrage supplémentaire
            break
        }
        
        // Vérifier le niveau de difficulté
        switch filterOptions.difficultyLevel {
        case .easy:
            if ease <= 2.5 {
                return false
            }
        case .medium:
            if ease < 1.5 || ease > 2.5 {
                return false
            }
        case .hard:
            if ease >= 1.5 {
                return false
            }
        case .all:
            // Aucun filtrage supplémentaire
            break
        }
        
        // Vérifier la plage de dates
        if let dateRange = filterOptions.dateRange {
            let dateToCheck = filterOptions.dateFilterType == .creationDate ? createdAt : updatedAt
            
            if let startDate = dateRange.start, dateToCheck < startDate {
                return false
            }
            
            if let endDate = dateRange.end, dateToCheck > endDate {
                return false
            }
        }
        
        // Si toutes les vérifications sont passées, la carte correspond
        return true
    }
    
    /// Calcule un score de pertinence pour la carte par rapport au texte de recherche
    /// - Parameter searchText: Texte à rechercher
    /// - Returns: Score de pertinence (plus élevé = plus pertinent)
    public func relevanceScore(for searchText: String) -> Double {
        guard !searchText.isEmpty else { return 1.0 }
        
        let lowercasedText = searchText.lowercased()
        var score: Double = 0.0
        
        // Poids différents pour chaque champ
        let questionWeight = 1.0
        let answerWeight = 0.8
        let additionalInfoWeight = 0.6
        let tagsWeight = 1.2
        
        // Vérifier dans la question (match exact a un score plus élevé)
        if question.lowercased() == lowercasedText {
            score += 10.0 * questionWeight
        } else if question.lowercased().contains(lowercasedText) {
            score += 5.0 * questionWeight
        }
        
        // Vérifier dans la réponse
        if answer.lowercased() == lowercasedText {
            score += 8.0 * answerWeight
        } else if answer.lowercased().contains(lowercasedText) {
            score += 4.0 * answerWeight
        }
        
        // Vérifier dans les informations additionnelles
        if let additionalInfo = additionalInfo {
            if additionalInfo.lowercased() == lowercasedText {
                score += 6.0 * additionalInfoWeight
            } else if additionalInfo.lowercased().contains(lowercasedText) {
                score += 3.0 * additionalInfoWeight
            }
        }
        
        // Vérifier dans les tags (correspondance exacte a un score plus élevé)
        for tag in tags {
            if tag.lowercased() == lowercasedText {
                score += 8.0 * tagsWeight
                break
            } else if tag.lowercased().contains(lowercasedText) {
                score += 4.0 * tagsWeight
            }
        }
        
        return score
    }
} 