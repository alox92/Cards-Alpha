import Foundation
import Combine

/// Source d'importation
public enum ImportSource: Equatable, Sendable {
    case file(URL)
    case cloud(String)
    case backup(String)
    
    public var description: String {
        switch self {
        case .file(let url):
            return "Fichier local: \(url.lastPathComponent)"
        case .cloud(let id):
            return "Cloud: \(id)"
        case .backup(let name):
            return "Sauvegarde: \(name)"
        }
    }
}

/// Stratégie d'importation
public enum ImportMode: Equatable, Sendable {
    case merge
    case replace
    case appendOnly
    
    public var description: String {
        switch self {
        case .merge:
            return "Fusion"
        case .replace:
            return "Remplacement"
        case .appendOnly:
            return "Ajout uniquement"
        }
    }
}

/// Format d'exportation
public enum ExportFormat: Equatable, Sendable {
    case json
    case xml
    case csv
    case cardarchive
    case pdf
    
    public var description: String {
        switch self {
        case .json: return "JSON"
        case .xml: return "XML"
        case .csv: return "CSV"
        case .cardarchive: return "Archive de cartes"
        case .pdf: return "PDF"
        }
    }
    
    public var fileExtension: String {
        switch self {
        case .json: return "json"
        case .xml: return "xml"
        case .csv: return "csv"
        case .cardarchive: return "cardarch"
        case .pdf: return "pdf"
        }
    }
    
    public var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .xml: return "application/xml"
        case .csv: return "text/csv"
        case .cardarchive: return "application/zip"
        case .pdf: return "application/pdf"
        }
    }
}

/// Protocole pour le service d'importation et d'exportation
public protocol ImportExportServiceProtocol {
    /// État de progression de l'opération d'importation/exportation
    var progressState: ImportExportProgress { get }
    
    /// Éditeur pour observer l'état de progression
    var progressStatePublisher: AnyPublisher<ImportExportProgress, Never> { get }
    
    /// Annule l'opération d'importation/exportation en cours
    func cancelOperation()
    
    /// Exporte les cartes spécifiées dans le format indiqué
    func exportCards(_ cards: [Card], to format: ExportFormat, destination: URL?) async throws -> URL
    
    /// Exporte le deck spécifié dans le format indiqué
    func exportDeck(_ deck: Deck, format: ExportFormat, includeSubdecks: Bool, destination: URL?) async throws -> URL
    
    /// Importe les cartes depuis un fichier
    func importCards(from url: URL, targetDeck: Deck?) async throws -> ImportResult
    
    /// Exporte tous les decks dans le format indiqué
    func exportAllDecks(format: ExportFormat, destination: URL?) async throws -> URL
}

/// État de progression de l'opération d'importation/exportation
public struct ImportExportProgress: Sendable {
    public enum OperationType: Equatable, Sendable {
        case none
        case exporting(format: ExportFormat)
        case importing(from: ImportSource, strategy: ImportMode)
        case optimization
        case backup
        case restore
        
        public var description: String {
            switch self {
            case .none: return "Aucune opération"
            case .exporting(let format): return "Exportation (\(format.description))"
            case .importing(let source, let strategy): return "Importation depuis \(source.description) (\(strategy.description))"
            case .optimization: return "Optimisation"
            case .backup: return "Sauvegarde"
            case .restore: return "Restauration"
            }
        }
    }
    
    public enum StatusType: String, Equatable, Sendable {
        case idle
        case inProgress
        case completed
        case failed
        case cancelled
    }
    
    public struct Status: Sendable {
        public let type: StatusType
        public let error: Error?
        
        public init(type: StatusType, error: Error? = nil) {
            self.type = type
            self.error = error
        }
        
        public static let idle = Status(type: .idle)
        public static let inProgress = Status(type: .inProgress)
        public static let completed = Status(type: .completed)
        public static let cancelled = Status(type: .cancelled)
        
        public static func failed(error: Error) -> Status {
            return Status(type: .failed, error: error)
        }
        
        public var description: String {
            switch type {
            case .idle: return "En attente"
            case .inProgress: return "En cours"
            case .completed: return "Terminé"
            case .cancelled: return "Annulé"
            case .failed: 
                if let error = error {
                    return "Échoué: \(error.localizedDescription)"
                }
                return "Échoué"
            }
        }
    }
    
    public let operation: OperationType
    public var status: Status
    public var progress: Double // 0.0 - 1.0
    public var itemsProcessed: Int
    public var totalItems: Int
    public var startTime: Date
    public var endTime: Date?
    
    public init(
        operation: OperationType = .none,
        status: Status = .idle,
        progress: Double = 0.0,
        itemsProcessed: Int = 0,
        totalItems: Int = 0,
        startTime: Date = Date(),
        endTime: Date? = nil
    ) {
        self.operation = operation
        self.status = status
        self.progress = progress
        self.itemsProcessed = itemsProcessed
        self.totalItems = totalItems
        self.startTime = startTime
        self.endTime = endTime
    }
    
    /// Valeur par défaut pour l'état d'attente
    public static let idle = ImportExportProgress(operation: .none, status: .idle)
}

/// Résultat d'une opération d'importation
public struct ImportResult {
    public let itemsImported: Int
    public let itemsSkipped: Int
    public let itemsFailed: Int
    public let warnings: [String]
    public let errors: [String]
    
    public var isSuccessful: Bool {
        return itemsFailed == 0 && errors.isEmpty
    }
}

/// Implémentation par défaut du service d'importation et d'exportation
public class ImportExportService: ImportExportServiceProtocol {
    private let cardService: any CardServiceProtocol
    private let deckService: any DeckServiceProtocol
    private let dataManagementService: any DataManagementServiceProtocol
    
    private let progressSubject = CurrentValueSubject<ImportExportProgress, Never>(ImportExportProgress.idle)
    
    public var progressState: ImportExportProgress {
        return progressSubject.value
    }
    
    public var progressStatePublisher: AnyPublisher<ImportExportProgress, Never> {
        return progressSubject.eraseToAnyPublisher()
    }
    
    public init(cardService: any CardServiceProtocol, deckService: any DeckServiceProtocol, dataManagementService: any DataManagementServiceProtocol) {
        self.cardService = cardService
        self.deckService = deckService
        self.dataManagementService = dataManagementService
    }
    
    public func cancelOperation() {
        var current = progressState
        if current.status.type == .inProgress {
            current.status = .cancelled
            progressSubject.send(current)
        }
    }
    
    public func exportCards(_ cards: [Card], to format: ExportFormat, destination: URL?) async throws -> URL {
        // Simuler une exportation
        let destinationURL = destination ?? FileManager.default.temporaryDirectory.appendingPathComponent("cards.\(format.fileExtension)")
        
        updateProgress(.init(
            operation: .exporting(format: format),
            status: .inProgress,
            progress: 0.0,
            itemsProcessed: 0,
            totalItems: cards.count
        ))
        
        for (index, _) in cards.enumerated() {
            // Simuler le traitement de chaque carte
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            updateProgress(.init(
                operation: .exporting(format: format),
                status: .inProgress,
                progress: Double(index + 1) / Double(cards.count),
                itemsProcessed: index + 1,
                totalItems: cards.count
            ))
        }
        
        updateProgress(.init(
            operation: .exporting(format: format),
            status: .completed,
            progress: 1.0,
            itemsProcessed: cards.count,
            totalItems: cards.count
        ))
        
        return destinationURL
    }
    
    public func exportDeck(_ deck: Deck, format: ExportFormat, includeSubdecks: Bool, destination: URL?) async throws -> URL {
        // Simuler l'exportation de deck
        let destinationURL = destination ?? FileManager.default.temporaryDirectory.appendingPathComponent("deck.\(format.fileExtension)")
        
        // Obtenir toutes les cartes du deck
        let cards: [Card] = [] // À implémenter
        
        return try await exportCards(cards, to: format, destination: destinationURL)
    }
    
    public func importCards(from url: URL, targetDeck: Deck?) async throws -> ImportResult {
        // Simuler l'importation
        updateProgress(.init(
            operation: .importing(from: .file(url), strategy: .merge),
            status: .inProgress,
            progress: 0.0,
            itemsProcessed: 0,
            totalItems: 10 // Nombre estimé
        ))
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
        
        updateProgress(.init(
            operation: .importing(from: .file(url), strategy: .merge),
            status: .completed,
            progress: 1.0,
            itemsProcessed: 8,
            totalItems: 10
        ))
        
        return ImportResult(
            itemsImported: 8,
            itemsSkipped: 1,
            itemsFailed: 1,
            warnings: ["Une carte avait un format inattendu"],
            errors: []
        )
    }
    
    public func exportAllDecks(format: ExportFormat, destination: URL?) async throws -> URL {
        // Simuler l'exportation de tous les decks
        let destinationURL = destination ?? FileManager.default.temporaryDirectory.appendingPathComponent("all_decks.\(format.fileExtension)")
        
        // Obtenir tous les decks
        let _: [Deck] = [] // À implémenter
        
        // Obtenir toutes les cartes
        let allCards: [Card] = [] // À implémenter
        
        return try await exportCards(allCards, to: format, destination: destinationURL)
    }
    
    private func updateProgress(_ progress: ImportExportProgress) {
        progressSubject.send(progress)
    }
} 