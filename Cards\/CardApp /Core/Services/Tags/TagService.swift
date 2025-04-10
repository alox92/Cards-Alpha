import Foundation
import Core
import Combine
import CoreData

/// Service de gestion des tags
@MainActor
public class TagService: TagServiceProtocol, @unchecked Sendable {
    // MARK: - Propriétés
    private let dataService: DataManagementServiceProtocol
    private let tagsSubject = CurrentValueSubject<[Tag], Never>([])
    
    // MARK: - Publications
    @preconcurrency
    public var tagsPublisher: AnyPublisher<[Tag], Never> {
        return tagsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialisation
    public init(dataService: DataManagementServiceProtocol) {
        self.dataService = dataService
        
        // Charger les tags au démarrage
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let tags = try await self.getAllTags()
                await self.updateTagsPublisher(with: tags)
            } catch {
                print("Erreur lors de l'initialisation des tags: \(error)")
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    public func createTag(_ tag: Tag) async throws -> Tag {
        // Vérifier si un tag avec le même nom existe déjà
        if try await tagExists(withName: tag.name) {
            throw TagServiceError.duplicateTag
        }
        
        let entity = try await dataService.create(TagEntity.self) { entity in
            entity.id = tag.id
            entity.name = tag.name
            entity.color = tag.color
            entity.tagDescription = tag.description
            entity.usage = Int16(tag.usage)
            entity.createdAt = tag.createdAt
            entity.updatedAt = tag.updatedAt
        }
        
        // Utiliser la méthode nonisolated pour la conversion
        let newTag = mapEntityToModel(entity)
        
        await updateTagsPublisher()
        return newTag
    }
    
    public func getTag(byID id: UUID) async throws -> Tag {
        guard let entity = try await dataService.fetch(TagEntity.self, id: id) else {
            throw TagServiceError.tagNotFound
        }
        
        return mapEntityToModel(entity)
    }
    
    public func getTag(byName name: String) async throws -> Tag {
        let entities = try await dataService.fetch(TagEntity.self) { request in
            request.predicate = NSPredicate(format: "name ==[cd] %@", name)
            request.fetchLimit = 1
        }
        
        guard let entity = entities.first else {
            throw TagServiceError.tagNotFound
        }
        
        return mapEntityToModel(entity)
    }
    
    public func updateTag(_ tag: Tag) async throws -> Tag {
        // Vérifier si un autre tag avec le même nom existe déjà
        let existingTagsWithSameName = try await dataService.fetch(TagEntity.self) { request in
            request.predicate = NSPredicate(format: "name ==[cd] %@ AND id != %@", tag.name, tag.id as CVarArg)
        }
        
        if !existingTagsWithSameName.isEmpty {
            throw TagServiceError.duplicateTag
        }
        
        let entity = try await dataService.update(TagEntity.self, id: tag.id) { entity in
            entity.name = tag.name
            entity.color = tag.color
            entity.tagDescription = tag.description
            entity.usage = Int16(tag.usage)
            entity.updatedAt = Date()
        }
        
        let updatedTag = mapEntityToModel(entity)
        await updateTagsPublisher()
        return updatedTag
    }
    
    public func deleteTag(_ tag: Tag) async throws {
        try await dataService.delete(TagEntity.self, id: tag.id)
        await updateTagsPublisher()
    }
    
    public func deleteTags(_ tags: [Tag]) async throws {
        try await dataService.deleteMultiple(TagEntity.self) { request in
            request.predicate = NSPredicate(format: "id IN %@", tags.map { $0.id } as NSArray)
        }
        await updateTagsPublisher()
    }
    
    // MARK: - Batch Operations
    
    public func getAllTags() async throws -> [Tag] {
        let entities = try await dataService.fetchAll(TagEntity.self)
        return entities.map { mapEntityToModel($0) }
    }
    
    public func getTags(withNames names: [String]) async throws -> [Tag] {
        let entities = try await dataService.fetch(TagEntity.self) { request in
            request.predicate = NSPredicate(format: "name IN %@", names as NSArray)
        }
        return entities.map { mapEntityToModel($0) }
    }
    
    public func getTagsUsage() async throws -> [(String, Int)] {
        let allTags = try await getAllTags()
        // Dans une implémentation complète, on compterait réellement l'utilisation
        // Ici, nous simulons des données d'utilisation aléatoires
        return allTags.map { ($0.name, Int.random(in: 0...20)) }
    }
    
    public func getTagsForItemType(_ itemType: TaggedItemType) async throws -> [Tag] {
        // Dans une implémentation complète, cette méthode récupérerait tous les tags 
        // utilisés par un type d'item spécifique
        // Pour simplifier, nous retournons tous les tags
        return try await getAllTags()
    }
    
    // MARK: - Tag Management
    
    public func addTagToCard(tagName: String, cardID: UUID) async throws {
        // Vérifier que le tag existe, sinon le créer
        var tag: Tag
        do {
            tag = try await getTag(byName: tagName)
        } catch TagServiceError.tagNotFound {
            tag = try await createTag(Tag(id: UUID(), name: tagName))
        }
        
        // Ajouter le tag à la carte via l'API spécifique aux items
        try await addTagToItems(tagID: tag.id, itemIDs: [cardID], itemType: .card)
    }
    
    public func removeTagFromCard(tagName: String, cardID: UUID) async throws {
        // Trouver le tag par son nom
        let tag = try await getTag(byName: tagName)
        
        // Supprimer le tag de la carte
        try await removeTagFromItems(tagID: tag.id, itemIDs: [cardID], itemType: .card)
    }
    
    public func addTagToDeck(tagName: String, deckID: UUID) async throws {
        // Vérifier que le tag existe, sinon le créer
        var tag: Tag
        do {
            tag = try await getTag(byName: tagName)
        } catch TagServiceError.tagNotFound {
            tag = try await createTag(Tag(id: UUID(), name: tagName))
        }
        
        // Ajouter le tag au paquet via l'API spécifique aux items
        try await addTagToItems(tagID: tag.id, itemIDs: [deckID], itemType: .deck)
    }
    
    public func removeTagFromDeck(tagName: String, deckID: UUID) async throws {
        // Trouver le tag par son nom
        let tag = try await getTag(byName: tagName)
        
        // Supprimer le tag du paquet
        try await removeTagFromItems(tagID: tag.id, itemIDs: [deckID], itemType: .deck)
    }
    
    // MARK: - Tagging Operations
    
    public func addTagToItems(tagID: UUID, itemIDs: [UUID], itemType: TaggedItemType) async throws {
        // Vérifier que le tag existe
        _ = try await getTag(byID: tagID)
        
        // Dans une implémentation complète, cette méthode ajouterait le tag aux items
        // Ici nous simulons une implémentation sans faire d'opérations réelles sur les items
        switch itemType {
        case .card:
            print("Ajout du tag aux cartes")
        case .deck:
            print("Ajout du tag aux paquets")
        }
    }
    
    public func removeTagFromItems(tagID: UUID, itemIDs: [UUID], itemType: TaggedItemType) async throws {
        // Vérifier que le tag existe
        _ = try await getTag(byID: tagID)
        
        // Dans une implémentation complète, cette méthode retirerait le tag des items
        // Ici nous simulons une implémentation sans faire d'opérations réelles sur les items
        switch itemType {
        case .card:
            print("Retrait du tag des cartes")
        case .deck:
            print("Retrait du tag des paquets")
        }
    }
    
    public func getTagsForItem(itemID: UUID, itemType: TaggedItemType) async throws -> [Tag] {
        // Dans une implémentation complète, cette méthode récupérerait les tags d'un item
        // Ici nous simulons une implémentation en retournant un sous-ensemble de tags
        let allTags = try await getAllTags()
        // En pratique, nous filtrerions les tags qui sont associés à l'item
        return allTags.prefix(min(3, allTags.count)).map { $0 }
    }
    
    public func getItemsWithTag(tagID: UUID, itemType: TaggedItemType) async throws -> [UUID] {
        // Vérifier que le tag existe
        _ = try await getTag(byID: tagID)
        
        // Dans une implémentation complète, cette méthode récupérerait les items ayant ce tag
        // Ici nous simulons une implémentation en retournant un tableau vide
        return []
    }
    
    // MARK: - Search
    
    public func searchTags(query: String) async throws -> [Tag] {
        let entities = try await dataService.fetch(TagEntity.self) { request in
            if !query.isEmpty {
                request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
            }
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        }
        return entities.map { mapEntityToModel($0) }
    }
    
    // MARK: - Import/Export
    
    public func importTags(_ tags: [Tag]) async throws -> [Tag] {
        var importedTags: [Tag] = []
        
        for tag in tags {
            do {
                // Si le tag existe déjà par son nom, on le récupère au lieu de le créer
                if try await tagExists(withName: tag.name) {
                    let existingTag = try await getTag(byName: tag.name)
                    importedTags.append(existingTag)
                } else {
                    let importedTag = try await createTag(tag)
                    importedTags.append(importedTag)
                }
            } catch {
                print("Erreur lors de l'import du tag \(tag.name): \(error)")
            }
        }
        
        return importedTags
    }
    
    public func exportTags(_ tags: [Tag]) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(tags)
    }
    
    // MARK: - Private Methods
    
    /// Vérifie si un tag avec le nom spécifié existe déjà
    private func tagExists(withName name: String) async throws -> Bool {
        let entities = try await dataService.fetch(TagEntity.self) { request in
            request.predicate = NSPredicate(format: "name ==[cd] %@", name)
            request.fetchLimit = 1
        }
        return !entities.isEmpty
    }
    
    /// Met à jour le publisher de tags
    private func updateTagsPublisher(with tags: [Tag]? = nil) async {
        let allTags: [Tag]
        if let tags = tags {
            allTags = tags
        } else {
            allTags = (try? await getAllTags()) ?? []
        }
        tagsSubject.send(allTags)
    }
    
    /// Convertit une entité TagEntity en modèle Tag
    /// Cette méthode est non-isolée pour permettre son utilisation dans des closures détachées
    private nonisolated func mapEntityToModel(_ entity: TagEntity) -> Tag {
        return Tag(
            id: entity.id ?? UUID(),
            name: entity.name,
            color: entity.color,
            description: entity.tagDescription,
            usage: Int(entity.usage),
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
} 