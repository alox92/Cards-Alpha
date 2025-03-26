import Foundation
import CoreData
import SwiftUI
import UniformTypeIdentifiers
import Combine
import ZIPFoundation // Pour installer: File > Add Packages... > https://github.com/weichsel/ZIPFoundation.git
import PDFKit
import SQLite3 // Pour la manipulation de la base de données SQLite d'Anki

// Extension pour le NSSavePanel pour changer le format de fichier
#if os(macOS)
extension NSSavePanel {
    @objc func didChangeFormatPopup(_ sender: NSPopUpButton) {
        guard let format = sender.selectedItem?.representedObject as? ImportExportService.FileFormat else {
            return
        }
        
        // Changer l'extension du fichier
        let currentName = nameFieldStringValue
        let nameWithoutExtension = currentName.components(separatedBy: ".").first ?? currentName
        nameFieldStringValue = "\(nameWithoutExtension).\(format.rawValue)"
        
        // Mettre à jour le type de contenu autorisé
        allowedContentTypes = [format.contentType]
    }
}
#endif

// Extension pour calculer le hash SHA1
extension Data {
    var sha1: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        self.withUnsafeBytes { bytes in
            _ = CC_SHA1(bytes.baseAddress, CC_LONG(self.count), &digest)
        }
        
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}

// Une classe simple pour gérer les opérations SQLite
class SQLiteDatabase {
    private var db: OpaquePointer?
    
    init(path: URL) throws {
        if sqlite3_open(path.path, &db) != SQLITE_OK {
            throw NSError(domain: "SQLiteDatabase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Impossible d'ouvrir la base de données"])
        }
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    func execute(_ sql: String, parameters: [Any] = []) throws {
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            throw NSError(domain: "SQLiteDatabase", code: 2, userInfo: [NSLocalizedDescriptionKey: "Erreur de préparation de la requête: \(String(cString: sqlite3_errmsg(db)))"])
        }
        
        // Lier les paramètres
        for (index, parameter) in parameters.enumerated() {
            let paramIndex = Int32(index + 1)
            
            switch parameter {
            case let value as Int:
                sqlite3_bind_int64(statement, paramIndex, sqlite3_int64(value))
            case let value as Double:
                sqlite3_bind_double(statement, paramIndex, value)
            case let value as String:
                sqlite3_bind_text(statement, paramIndex, (value as NSString).utf8String, -1, nil)
            case let value as Data:
                sqlite3_bind_blob(statement, paramIndex, (value as NSData).bytes, Int32(value.count), nil)
            case is NSNull:
                sqlite3_bind_null(statement, paramIndex)
            default:
                sqlite3_finalize(statement)
                throw NSError(domain: "SQLiteDatabase", code: 3, userInfo: [NSLocalizedDescriptionKey: "Type de paramètre non supporté"])
            }
        }
        
        // Exécuter la requête
        if sqlite3_step(statement) != SQLITE_DONE && sqlite3_step(statement) != SQLITE_ROW {
            sqlite3_finalize(statement)
            throw NSError(domain: "SQLiteDatabase", code: 4, userInfo: [NSLocalizedDescriptionKey: "Erreur d'exécution de la requête: \(String(cString: sqlite3_errmsg(db)))"])
        }
        
        sqlite3_finalize(statement)
    }
    
    func query(_ sql: String, parameters: [Any] = []) throws -> [[String: Any]] {
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            throw NSError(domain: "SQLiteDatabase", code: 2, userInfo: [NSLocalizedDescriptionKey: "Erreur de préparation de la requête: \(String(cString: sqlite3_errmsg(db)))"])
        }
        
        // Lier les paramètres
        for (index, parameter) in parameters.enumerated() {
            let paramIndex = Int32(index + 1)
            
            switch parameter {
            case let value as Int:
                sqlite3_bind_int64(statement, paramIndex, sqlite3_int64(value))
            case let value as Double:
                sqlite3_bind_double(statement, paramIndex, value)
            case let value as String:
                sqlite3_bind_text(statement, paramIndex, (value as NSString).utf8String, -1, nil)
            case let value as Data:
                sqlite3_bind_blob(statement, paramIndex, (value as NSData).bytes, Int32(value.count), nil)
            case is NSNull:
                sqlite3_bind_null(statement, paramIndex)
            default:
                sqlite3_finalize(statement)
                throw NSError(domain: "SQLiteDatabase", code: 3, userInfo: [NSLocalizedDescriptionKey: "Type de paramètre non supporté"])
            }
        }
        
        var results = [[String: Any]]()
        
        while sqlite3_step(statement) == SQLITE_ROW {
            var row = [String: Any]()
            
            let columnCount = sqlite3_column_count(statement)
            
            for i in 0..<columnCount {
                let columnName = String(cString: sqlite3_column_name(statement, i))
                let columnType = sqlite3_column_type(statement, i)
                
                switch columnType {
                case SQLITE_INTEGER:
                    row[columnName] = Int(sqlite3_column_int64(statement, i))
                case SQLITE_FLOAT:
                    row[columnName] = sqlite3_column_double(statement, i)
                case SQLITE_TEXT:
                    if let text = sqlite3_column_text(statement, i) {
                        row[columnName] = String(cString: text)
                    }
                case SQLITE_BLOB:
                    if let blob = sqlite3_column_blob(statement, i) {
                        let size = sqlite3_column_bytes(statement, i)
                        row[columnName] = Data(bytes: blob, count: Int(size))
                    }
                case SQLITE_NULL:
                    row[columnName] = NSNull()
                default:
                    break
                }
            }
            
            results.append(row)
        }
        
        sqlite3_finalize(statement)
        
        return results
    }
}

// Service de gestion des importations et exportations multi-formats
class ImportExportService: ObservableObject {
    static let shared = ImportExportService()
    
    private let context: NSManagedObjectContext
    
    // MARK: - Énumérations des formats et erreurs
    
    enum FileFormat: String, CaseIterable {
        case txt = "txt"
        case csv = "csv"
        case anki = "apkg"
        case xml = "xml"
        case opml = "opml"
        
        var contentType: UTType {
            switch self {
            case .txt: return .plainText
            case .csv: return .commaSeparatedText
            case .xml: return .xml
            case .opml: return UTType(filenameExtension: "opml") ?? .xml
            case .anki: return UTType(filenameExtension: "apkg") ?? .data
            }
        }
        
        var description: String {
            switch self {
            case .txt: return "Texte (.txt)"
            case .csv: return "CSV (.csv)"
            case .xml: return "XML (.xml)"
            case .opml: return "OPML (.opml)"
            case .anki: return "Anki (.apkg)"
            }
        }
    }
    
    enum ImportError: Error {
        case invalidFormat
        case parsingFailed
        case fileReadFailed
        case unsupportedFormat
        case invalidArchive
        case missingDatabaseFile
        case noDecksFound
        case missingDecksData
        case invalidDecksData
        case missingModelsData
        case invalidModelsData
        case databaseOpenFailed
    }
    
    enum ExportError: Error {
        case fileCreationFailed
        case archiveCreationFailed
        case databaseCreationFailed
        case mediaExtractionFailed
        case ankiExportFailed
        case unsupportedFormat
        case invalidDeckData
        case emptyDeck
    }
    
    // MARK: - Exportation
    
    // Exporter un paquet dans un format spécifique
    func exportDeck(_ deck: Deck, to format: FileFormat) -> AnyPublisher<URL, Error> {
        return Future<URL, Error> { promise in
            do {
                // Récupérer les cartes du paquet
                let cards = self.fetchCards(for: deck.id)
                
                // Créer un répertoire temporaire pour l'export
                let tempDirURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
                
                // Nom du fichier d'export
                let sanitizedName = deck.name.replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "_", options: .regularExpression)
                let fileName = "\(sanitizedName).\(format.rawValue)"
                let fileURL = tempDirURL.appendingPathComponent(fileName)
                
                // Exporter selon le format
                switch format {
                case .json:
                    try self.exportToJSON(deck: deck, cards: cards, to: fileURL)
                case .csv:
                    try self.exportToCSV(deck: deck, cards: cards, to: fileURL)
                case .txt:
                    try self.exportToTXT(deck: deck, cards: cards, to: fileURL)
                case .markdown:
                    try self.exportToMarkdown(deck: deck, cards: cards, to: fileURL)
                case .xml:
                    try self.exportToXML(deck: deck, cards: cards, to: fileURL)
                case .opml:
                    try self.exportToOPML(deck: deck, cards: cards, to: fileURL)
                case .anki:
                    try self.exportToAnki(deck: deck, cards: cards, to: fileURL, tempDir: tempDirURL)
                }
                
                promise(.success(fileURL))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Méthodes d'exportation par format
    
    private func exportToJSON(deck: Deck, cards: [Card], to fileURL: URL) throws {
        // Créer l'objet DeckExport enrichi
        let cardExports = cards.map { card in
            EnhancedCardExport(
                question: card.question,
                answer: card.answer,
                additionalInfo: card.additionalInfo ?? "",
                tags: [], // À implémenter: récupérer les tags
                masteryLevel: card.masteryLevel.rawValue,
                reviewCount: card.reviewCount,
                lastReviewedAt: card.lastReviewedAt,
                nextReviewDate: card.nextReviewDate,
                media: [] // À implémenter: récupérer les médias
            )
        }
        
        let deckExport = EnhancedDeckExport(
            name: deck.name,
            description: deck.description,
            icon: deck.icon,
            colorName: deck.colorName,
            cards: cardExports,
            exportDate: Date(),
            version: "2.0",
            format: "json",
            tags: [] // À implémenter: récupérer les tags
        )
        
        // Encoder en JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(deckExport)
        try data.write(to: fileURL)
    }
    
    private func exportToCSV(deck: Deck, cards: [Card], to fileURL: URL) throws {
        var csvString = "Question,Réponse,Informations supplémentaires,Niveau de maîtrise,Nombre de révisions\n"
        
        for card in cards {
            let question = card.question.replacingOccurrences(of: "\"", with: "\"\"")
            let answer = card.answer.replacingOccurrences(of: "\"", with: "\"\"")
            let additionalInfo = (card.additionalInfo ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            
            csvString += "\"\(question)\",\"\(answer)\",\"\(additionalInfo)\",\"\(card.masteryLevel.displayName)\",\(card.reviewCount)\n"
        }
        
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    private func exportToTXT(deck: Deck, cards: [Card], to fileURL: URL) throws {
        var txtString = "PAQUET: \(deck.name)\n"
        txtString += "DESCRIPTION: \(deck.description)\n\n"
        
        for (index, card) in cards.enumerated() {
            txtString += "CARTE \(index + 1)\n"
            txtString += "Q: \(card.question)\n"
            txtString += "R: \(card.answer)\n"
            
            if let info = card.additionalInfo, !info.isEmpty {
                txtString += "INFO: \(info)\n"
            }
            
            txtString += "\n"
        }
        
        try txtString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    private func exportToMarkdown(deck: Deck, cards: [Card], to fileURL: URL) throws {
        var mdString = "# \(deck.name)\n\n"
        mdString += "_\(deck.description)_\n\n"
        
        for card in cards {
            mdString += "## Question\n\n"
            mdString += "\(card.question)\n\n"
            mdString += "### Réponse\n\n"
            mdString += "\(card.answer)\n\n"
            
            if let info = card.additionalInfo, !info.isEmpty {
                mdString += "#### Informations supplémentaires\n\n"
                mdString += "\(info)\n\n"
            }
            
            mdString += "---\n\n"
        }
        
        try mdString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    private func exportToXML(deck: Deck, cards: [Card], to fileURL: URL) throws {
        var xmlString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xmlString += "<deck name=\"\(escapeXML(deck.name))\" description=\"\(escapeXML(deck.description))\">\n"
        
        for card in cards {
            xmlString += "  <card>\n"
            xmlString += "    <question><![CDATA[\(card.question)]]></question>\n"
            xmlString += "    <answer><![CDATA[\(card.answer)]]></answer>\n"
            
            if let info = card.additionalInfo, !info.isEmpty {
                xmlString += "    <additionalInfo><![CDATA[\(info)]]></additionalInfo>\n"
            }
            
            xmlString += "    <masteryLevel>\(card.masteryLevel.rawValue)</masteryLevel>\n"
            xmlString += "    <reviewCount>\(card.reviewCount)</reviewCount>\n"
            xmlString += "  </card>\n"
        }
        
        xmlString += "</deck>"
        try xmlString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    private func exportToOPML(deck: Deck, cards: [Card], to fileURL: URL) throws {
        var opmlString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        opmlString += "<opml version=\"2.0\">\n"
        opmlString += "  <head>\n"
        opmlString += "    <title>\(escapeXML(deck.name))</title>\n"
        opmlString += "  </head>\n"
        opmlString += "  <body>\n"
        opmlString += "    <outline text=\"\(escapeXML(deck.name))\" description=\"\(escapeXML(deck.description))\">\n"
        
        for card in cards {
            opmlString += "      <outline text=\"\(escapeXML(card.question))\">\n"
            opmlString += "        <outline text=\"Réponse\" _note=\"\(escapeXML(card.answer))\"/>\n"
            
            if let info = card.additionalInfo, !info.isEmpty {
                opmlString += "        <outline text=\"Informations supplémentaires\" _note=\"\(escapeXML(info))\"/>\n"
            }
            
            opmlString += "      </outline>\n"
        }
        
        opmlString += "    </outline>\n"
        opmlString += "  </body>\n"
        opmlString += "</opml>"
        
        try opmlString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    private func exportToAnki(deck: Deck, cards: [Card], to fileURL: URL, tempDir: URL) throws {
        // Structure d'un fichier .apkg d'Anki:
        // 1. Un fichier ZIP contenant:
        //    - collection.anki2: Base de données SQLite avec les cards, notes, decks...
        //    - media: Fichier JSON mappant les numéros aux noms originaux des médias
        //    - Fichiers média numérotés (1, 2, 3, etc.)
        
        // Créer le fichier SQLite de la collection (collection.anki2)
        let collectionPath = tempDir.appendingPathComponent("collection.anki2")
        try createAnkiDatabase(at: collectionPath, deck: deck, cards: cards)
        
        // Créer le dossier média
        let mediaDir = tempDir.appendingPathComponent("media")
        try FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true, attributes: nil)
        
        // Extraire et traiter les médias des cartes
        let (mediaMap, mediaFiles) = try extractMedia(from: cards, to: mediaDir)
        
        // Créer le fichier média JSON
        let mediaJSON = try JSONSerialization.data(withJSONObject: mediaMap, options: .prettyPrinted)
        try mediaJSON.write(to: tempDir.appendingPathComponent("media"))
        
        // Créer l'archive ZIP
        if let archive = Archive(url: fileURL, accessMode: .create) {
            try archive.addEntry(with: "collection.anki2", fileURL: collectionPath)
            try archive.addEntry(with: "media", fileURL: tempDir.appendingPathComponent("media"))
            
            // Ajouter chaque fichier média
            for (index, file) in mediaFiles.enumerated() {
                let mediaFilePath = mediaDir.appendingPathComponent("\(index + 1)")
                try archive.addEntry(with: "\(index + 1)", fileURL: mediaFilePath)
            }
        } else {
            throw NSError(domain: "ImportExport", code: 10, userInfo: [NSLocalizedDescriptionKey: "Impossible de créer l'archive ZIP"])
        }
    }
    
    // Extrait les médias des cartes et les sauvegarde dans le dossier de destination
    private func extractMedia(from cards: [Card], to mediaDir: URL) throws -> ([String: String], [URL]) {
        var mediaMap = [String: String]()
        var mediaFiles = [URL]()
        var mediaIndex = 1
        
        let mediaRegex = try NSRegularExpression(pattern: "<img\\s+src=[\"'](.*?)[\"']\\s*\\/?\\s*>|\\[sound:(.*?)\\]", options: [])
        
        for card in cards {
            // Chercher les médias dans la question
            extractMediaFromText(card.question, using: mediaRegex, mediaDir: mediaDir, mediaMap: &mediaMap, mediaFiles: &mediaFiles, mediaIndex: &mediaIndex)
            
            // Chercher les médias dans la réponse
            extractMediaFromText(card.answer, using: mediaRegex, mediaDir: mediaDir, mediaMap: &mediaMap, mediaFiles: &mediaFiles, mediaIndex: &mediaIndex)
            
            // Chercher dans les infos additionnelles si disponibles
            if let additionalInfo = card.additionalInfo {
                extractMediaFromText(additionalInfo, using: mediaRegex, mediaDir: mediaDir, mediaMap: &mediaMap, mediaFiles: &mediaFiles, mediaIndex: &mediaIndex)
            }
        }
        
        return (mediaMap, mediaFiles)
    }
    
    private func extractMediaFromText(_ text: String, using regex: NSRegularExpression, mediaDir: URL, mediaMap: inout [String: String], mediaFiles: inout [URL], mediaIndex: inout Int) {
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            var mediaPath: String = ""
            
            // Récupérer le chemin du média (soit via img src, soit via [sound:...])
            if match.numberOfRanges > 1 && match.range(at: 1).location != NSNotFound {
                // Format <img src="...">
                mediaPath = nsString.substring(with: match.range(at: 1))
            } else if match.numberOfRanges > 2 && match.range(at: 2).location != NSNotFound {
                // Format [sound:...]
                mediaPath = nsString.substring(with: match.range(at: 2))
            }
            
            if !mediaPath.isEmpty {
                // Vérifier si nous avons déjà traité ce média
                if !mediaMap.values.contains(mediaPath) {
                    // Sauvegarder le média
                    if let url = URL(string: mediaPath) {
                        do {
                            let mediaFileName = "\(mediaIndex)"
                            let destinationURL = mediaDir.appendingPathComponent(mediaFileName)
                            
                            // Essayer de télécharger ou copier le média
                            if mediaPath.hasPrefix("http") || mediaPath.hasPrefix("https") {
                                let data = try Data(contentsOf: url)
                                try data.write(to: destinationURL)
                            } else {
                                // Essayer de trouver le fichier local
                                if let localURL = findLocalMedia(named: mediaPath) {
                                    try FileManager.default.copyItem(at: localURL, to: destinationURL)
                                }
                            }
                            
                            // Ajouter au mapping
                            mediaMap[mediaFileName] = mediaPath
                            mediaFiles.append(destinationURL)
                            mediaIndex += 1
                        } catch {
                            print("Erreur lors de la copie du média \(mediaPath): \(error)")
                        }
                    }
                }
            }
        }
    }
    
    // Fonction pour trouver un fichier média local
    private func findLocalMedia(named path: String) -> URL? {
        // Dans une implémentation réelle, vous auriez un dossier de médias à rechercher
        // Pour cet exemple, nous retournons simplement nil
        return nil
    }
    
    private func createAnkiDatabase(at path: URL, deck: Deck, cards: [Card]) throws {
        // Création d'une base de données SQLite avec le schéma Anki
        let db = try SQLiteDatabase(path: path)
        
        // Créer les tables principales selon le schéma d'Anki
        try db.execute("""
        CREATE TABLE col (
            id              integer primary key,
            crt             integer not null,
            mod             integer not null,
            scm             integer not null,
            ver             integer not null,
            dty             integer not null,
            usn             integer not null,
            ls              integer not null,
            conf            text not null,
            models          text not null,
            decks           text not null,
            dconf           text not null,
            tags            text not null
        );
        CREATE TABLE notes (
            id              integer primary key,
            guid            text not null,
            mid             integer not null,
            mod             integer not null,
            usn             integer not null,
            tags            text not null,
            flds            text not null,
            sfld            integer not null,
            csum            integer not null,
            flags           integer not null,
            data            text not null
        );
        CREATE TABLE cards (
            id              integer primary key,
            nid             integer not null,
            did             integer not null,
            ord             integer not null,
            mod             integer not null,
            usn             integer not null,
            type            integer not null,
            queue           integer not null,
            due             integer not null,
            ivl             integer not null,
            factor          integer not null,
            reps            integer not null,
            lapses          integer not null,
            left            integer not null,
            odue            integer not null,
            odid            integer not null,
            flags           integer not null,
            data            text not null
        );
        CREATE TABLE revlog (
            id              integer primary key,
            cid             integer not null,
            usn             integer not null,
            ease            integer not null,
            ivl             integer not null,
            lastIvl         integer not null,
            factor          integer not null,
            time            integer not null,
            type            integer not null
        );
        CREATE TABLE graves (
            usn             integer not null,
            oid             integer not null,
            type            integer not null
        );
        CREATE INDEX ix_notes_usn on notes (usn);
        CREATE INDEX ix_cards_usn on cards (usn);
        CREATE INDEX ix_revlog_usn on revlog (usn);
        CREATE INDEX ix_cards_nid on cards (nid);
        CREATE INDEX ix_cards_sched on cards (did, queue, due);
        CREATE INDEX ix_revlog_cid on revlog (cid);
        CREATE INDEX ix_notes_csum on notes (csum);
        """)
        
        // Les timestamps Anki sont en secondes depuis l'époque Unix
        let now = Int(Date().timeIntervalSince1970)
        
        // Préparer les données de la collection
        let colId = 1
        let modelId = 1646130103952 // ID unique pour le modèle
        let deckId = 1646130104591  // ID unique pour le deck
        
        // Créer le modèle (notetype)
        let model = createAnkiModel(id: modelId, name: "Basic")
        
        // Créer le deck
        let deckObj = createAnkiDeck(id: deckId, name: deck.name, description: deck.description)
        
        // Créer la configuration du deck
        let dconf = createAnkiDeckConfig(id: 1)
        
        // Insérer la collection
        try db.execute("""
        INSERT INTO col VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        )
        """, parameters: [
            colId,                                      // id
            now,                                       // crt (created timestamp)
            now * 1000,                                // mod (milliseconds)
            now * 1000,                                // scm (schema mod time)
            11,                                        // ver (version 11)
            0,                                         // dty (dirty: unused)
            0,                                         // usn
            0,                                         // ls (last sync time)
            createAnkiConf(),                          // conf (configuration)
            "{\"\(modelId)\": \(model)}",              // models
            "{\"\(deckId)\": \(deckObj)}",             // decks
            "{\"\(1)\": \(dconf)}",                    // dconf
            "{}"                                       // tags
        ])
        
        // Insérer les notes et les cartes
        for (index, card) in cards.enumerated() {
            let noteId = Int(Date().timeIntervalSince1970) + index
            let cardId = noteId + 100000  // Ajouter un offset pour éviter les collisions
            
            // Insérer la note
            try insertAnkiNote(db: db, noteId: noteId, modelId: modelId, card: card)
            
            // Insérer la carte
            try insertAnkiCard(db: db, cardId: cardId, noteId: noteId, deckId: deckId, card: card)
        }
    }
    
    // Créer un modèle Anki JSON
    private func createAnkiModel(id: Int, name: String) -> String {
        // Structure du modèle Anki (template)
        return """
        {
            "id": \(id),
            "name": "\(name)",
            "type": 0,
            "mod": \(Int(Date().timeIntervalSince1970)),
            "usn": -1,
            "sortf": 0,
            "did": null,
            "tmpls": [
                {
                    "name": "Card 1",
                    "ord": 0,
                    "qfmt": "{{Question}}",
                    "afmt": "{{FrontSide}}<hr id=answer>{{Answer}}",
                    "bqfmt": "",
                    "bafmt": "",
                    "did": null,
                    "bfont": "",
                    "bsize": 0
                }
            ],
            "flds": [
                {
                    "name": "Question",
                    "ord": 0,
                    "sticky": false,
                    "rtl": false,
                    "font": "Arial",
                    "size": 20,
                    "media": []
                },
                {
                    "name": "Answer",
                    "ord": 1,
                    "sticky": false,
                    "rtl": false,
                    "font": "Arial",
                    "size": 20,
                    "media": []
                },
                {
                    "name": "Info",
                    "ord": 2,
                    "sticky": false,
                    "rtl": false,
                    "font": "Arial",
                    "size": 20,
                    "media": []
                }
            ],
            "css": ".card {\\n font-family: arial;\\n font-size: 20px;\\n text-align: center;\\n color: black;\\n background-color: white;\\n}\\n",
            "latexPre": "\\\\documentclass[12pt]{article}\\n\\\\special{papersize=3in,5in}\\n\\\\usepackage[utf8]{inputenc}\\n\\\\usepackage{amssymb,amsmath}\\n\\\\pagestyle{empty}\\n\\\\setlength{\\\\parindent}{0in}\\n\\\\begin{document}\\n",
            "latexPost": "\\\\end{document}",
            "latexsvg": false,
            "req": [
                [
                    0,
                    "any",
                    [
                        0
                    ]
                ]
            ],
            "tags": [],
            "vers": []
        }
        """
    }
    
    // Créer un deck Anki JSON
    private func createAnkiDeck(id: Int, name: String, description: String) -> String {
        return """
        {
            "id": \(id),
            "name": "\(name)",
            "desc": "\(description)",
            "extendRev": 50,
            "usn": -1,
            "collapsed": false,
            "newToday": [0, 0],
            "revToday": [0, 0],
            "lrnToday": [0, 0],
            "timeToday": [0, 0],
            "dyn": 0,
            "extendNew": 10,
            "conf": 1,
            "mod": \(Int(Date().timeIntervalSince1970))
        }
        """
    }
    
    // Créer la configuration du deck
    private func createAnkiDeckConfig(id: Int) -> String {
        return """
        {
            "id": \(id),
            "name": "Default",
            "replayq": true,
            "lapse": {
                "leechFails": 8,
                "minInt": 1,
                "delays": [10],
                "leechAction": 0,
                "mult": 0
            },
            "rev": {
                "perDay": 100,
                "fuzz": 0.05,
                "ivlFct": 1,
                "maxIvl": 36500,
                "ease4": 1.3,
                "bury": false,
                "minSpace": 1
            },
            "timer": 0,
            "maxTaken": 60,
            "usn": -1,
            "new": {
                "perDay": 20,
                "delays": [1, 10],
                "separate": true,
                "ints": [1, 4, 7],
                "initialFactor": 2500,
                "bury": false,
                "order": 1
            },
            "mod": \(Int(Date().timeIntervalSince1970)),
            "autoplay": true
        }
        """
    }
    
    // Créer la configuration globale
    private func createAnkiConf() -> String {
        return """
        {
            "nextPos": 1,
            "estTimes": true,
            "activeDecks": [1],
            "sortType": "noteFld",
            "timeLim": 0,
            "sortBackwards": false,
            "addToCur": true,
            "curDeck": 1,
            "newSpread": 0,
            "dueCounts": true,
            "curModel": "\(1646130103952)",
            "collapseTime": 1200
        }
        """
    }
    
    // Insérer une note dans la base de données
    private func insertAnkiNote(db: SQLiteDatabase, noteId: Int, modelId: Int, card: Card) throws {
        // Préparer les champs séparés par le caractère 0x1f (31)
        let separator = String(UnicodeScalar(0x1f)!)
        let additionalInfo = card.additionalInfo ?? ""
        let fields = card.question + separator + card.answer + separator + additionalInfo
        
        // Calculer le checksum
        let csum = calculateChecksum(text: card.question)
        
        try db.execute("""
        INSERT INTO notes VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        )
        """, parameters: [
            noteId,                                     // id
            UUID().uuidString,                         // guid
            modelId,                                   // mid (model id)
            Int(Date().timeIntervalSince1970),         // mod
            -1,                                        // usn
            " ",                                       // tags (espace au début et à la fin)
            fields,                                    // flds
            card.question,                             // sfld
            csum,                                      // csum
            0,                                         // flags
            ""                                         // data
        ])
    }
    
    // Insérer une carte dans la base de données
    private func insertAnkiCard(db: SQLiteDatabase, cardId: Int, noteId: Int, deckId: Int, card: Card) throws {
        // Convertir le niveau de maîtrise en type et queue Anki
        let (type, queue) = ankiLearningState(from: card.masteryLevel)
        
        try db.execute("""
        INSERT INTO cards VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        )
        """, parameters: [
            cardId,                                     // id
            noteId,                                    // nid
            deckId,                                    // did
            0,                                         // ord (position du template)
            Int(Date().timeIntervalSince1970),         // mod
            -1,                                        // usn
            type,                                      // type
            queue,                                     // queue
            0,                                         // due
            0,                                         // ivl
            2500,                                      // factor (2500 = 250%)
            card.reviewCount,                          // reps
            0,                                         // lapses
            0,                                         // left
            0,                                         // odue
            0,                                         // odid
            0,                                         // flags
            ""                                         // data
        ])
    }
    
    // Transformer notre niveau de maîtrise en état d'apprentissage Anki
    private func ankiLearningState(from level: MasteryLevel) -> (Int, Int) {
        switch level {
        case .new:
            return (0, 0) // type=0 (new), queue=0 (new)
        case .learning:
            return (1, 1) // type=1 (learning), queue=1 (learning)
        case .reviewing:
            return (2, 2) // type=2 (review), queue=2 (review)
        case .mastered:
            return (2, 2) // type=2 (review), queue=2 (review)
        }
    }
    
    // Calculer le checksum (les 8 premiers chiffres du hash SHA1)
    private func calculateChecksum(text: String) -> Int {
        if let data = text.data(using: .utf8) {
            let hash = data.sha1
            let hexString = hash.prefix(8)
            let checksum = Int(hexString, radix: 16) ?? 0
            return checksum
        }
        return 0
    }
    
    // MARK: - Importation
    
    // Importer un paquet depuis un fichier
    func importDeck(from url: URL) -> AnyPublisher<Deck, Error> {
        let fileExtension = url.pathExtension.lowercased()
        
        guard let format = FileFormat(rawValue: fileExtension) else {
            return Fail(error: NSError(domain: "ImportExport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Format de fichier non supporté"]))
                .eraseToAnyPublisher()
        }
        
        return Future<Deck, Error> { promise in
            do {
                let deck: Deck
                let cards: [Card]
                
                switch format {
                case .json:
                    (deck, cards) = try self.importFromJSON(url: url)
                case .csv:
                    (deck, cards) = try self.importFromCSV(url: url)
                case .txt:
                    (deck, cards) = try self.importFromTXT(url: url)
                case .markdown:
                    (deck, cards) = try self.importFromMarkdown(url: url)
                case .xml:
                    (deck, cards) = try self.importFromXML(url: url)
                case .opml:
                    (deck, cards) = try self.importFromOPML(url: url)
                case .anki:
                    (deck, cards) = try self.importFromAnki(url: url, into: self.context)
                }
                
                // Sauvegarder le paquet et les cartes
                try self.saveDeck(deck, withCards: cards)
                
                promise(.success(deck))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Méthodes d'importation par format
    
    private func importFromJSON(url: URL) throws -> (Deck, [Card]) {
        let data = try Data(contentsOf: url)
        
        // Essayer d'abord le format enrichi
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let deckExport = try decoder.decode(EnhancedDeckExport.self, from: data)
            
            let deck = Deck(
                id: UUID(),
                name: deckExport.name,
                description: deckExport.description,
                icon: deckExport.icon,
                colorName: deckExport.colorName,
                createdAt: Date()
            )
            
            let cards = deckExport.cards.map { cardExport -> Card in
                let masteryLevel = MasteryLevel(rawValue: cardExport.masteryLevel) ?? .new
                
                return Card(
                    question: cardExport.question,
                    answer: cardExport.answer,
                    additionalInfo: cardExport.additionalInfo.isEmpty ? nil : cardExport.additionalInfo,
                    deckID: deck.id,
                    masteryLevel: masteryLevel,
                    reviewCount: cardExport.reviewCount,
                    lastReviewedAt: cardExport.lastReviewedAt,
                    nextReviewDate: cardExport.nextReviewDate
                )
            }
            
            return (deck, cards)
        } catch {
            // Format standard
            let decoder = JSONDecoder()
            let deckExport = try decoder.decode(DeckExport.self, from: data)
            
            let deck = deckExport.toDeck()
            
            let cards = deckExport.cards.map { cardExport -> Card in
                Card(
                    question: cardExport.question,
                    answer: cardExport.answer,
                    additionalInfo: cardExport.additionalInfo.isEmpty ? nil : cardExport.additionalInfo,
                    deckID: deck.id
                )
            }
            
            return (deck, cards)
        }
    }
    
    private func importFromCSV(url: URL) throws -> (Deck, [Card]) {
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "ImportExport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Impossible de lire le fichier CSV"])
        }
        
        var lines = content.components(separatedBy: "\n")
        
        // Ignorer l'en-tête
        if !lines.isEmpty {
            lines.removeFirst()
        }
        
        // Créer un paquet avec le nom du fichier
        let deckName = url.deletingPathExtension().lastPathComponent
        let deck = Deck(
            id: UUID(),
            name: deckName,
            description: "Importé depuis CSV",
            icon: "doc.text",
            colorName: "blue",
            createdAt: Date()
        )
        
        // Analyser les lignes CSV
        var cards: [Card] = []
        
        for line in lines where !line.isEmpty {
            let fields = parseCSVLine(line)
            
            if fields.count >= 2 {
                let question = fields[0]
                let answer = fields[1]
                let additionalInfo = fields.count > 2 ? fields[2] : nil
                
                cards.append(Card(
                    question: question,
                    answer: answer,
                    additionalInfo: additionalInfo?.isEmpty ?? true ? nil : additionalInfo,
                    deckID: deck.id
                ))
            }
        }
        
        return (deck, cards)
    }
    
    private func importFromTXT(url: URL) throws -> (Deck, [Card]) {
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "ImportExport", code: 3, userInfo: [NSLocalizedDescriptionKey: "Impossible de lire le fichier texte"])
        }
        
        var deckName = url.deletingPathExtension().lastPathComponent
        var deckDescription = "Importé depuis TXT"
        var cards: [Card] = []
        
        // Parser le texte
        var currentQuestion: String?
        var currentAnswer: String?
        var currentInfo: String?
        
        let lines = content.components(separatedBy: "\n")
        var i = 0
        
        // Chercher le nom du paquet
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if line.hasPrefix("PAQUET:") {
                deckName = line.replacingOccurrences(of: "PAQUET:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.hasPrefix("DESCRIPTION:") {
                deckDescription = line.replacingOccurrences(of: "DESCRIPTION:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.hasPrefix("CARTE") || line.hasPrefix("Q:") {
                break
            }
            
            i += 1
        }
        
        // Parser les cartes
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if line.hasPrefix("Q:") {
                // Sauvegarder la carte précédente
                if let question = currentQuestion, let answer = currentAnswer {
                    cards.append(Card(
                        question: question,
                        answer: answer,
                        additionalInfo: currentInfo,
                        deckID: nil
                    ))
                }
                
                // Nouvelle question
                currentQuestion = line.replacingOccurrences(of: "Q:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                currentAnswer = nil
                currentInfo = nil
            } else if line.hasPrefix("R:") {
                currentAnswer = line.replacingOccurrences(of: "R:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.hasPrefix("INFO:") {
                currentInfo = line.replacingOccurrences(of: "INFO:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            i += 1
        }
        
        // Ajouter la dernière carte
        if let question = currentQuestion, let answer = currentAnswer {
            cards.append(Card(
                question: question,
                answer: answer,
                additionalInfo: currentInfo,
                deckID: nil
            ))
        }
        
        let deck = Deck(
            id: UUID(),
            name: deckName,
            description: deckDescription,
            icon: "doc.text",
            colorName: "blue",
            createdAt: Date()
        )
        
        // Ajouter l'ID du paquet aux cartes
        cards = cards.map { card in
            var newCard = card
            return Card(
                id: newCard.id,
                question: newCard.question,
                answer: newCard.answer,
                additionalInfo: newCard.additionalInfo,
                deckID: deck.id,
                createdAt: newCard.createdAt,
                updatedAt: newCard.updatedAt,
                masteryLevel: newCard.masteryLevel,
                reviewCount: newCard.reviewCount,
                lastReviewedAt: newCard.lastReviewedAt,
                nextReviewDate: newCard.nextReviewDate
            )
        }
        
        return (deck, cards)
    }
    
    private func importFromMarkdown(url: URL) throws -> (Deck, [Card]) {
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "ImportExport", code: 4, userInfo: [NSLocalizedDescriptionKey: "Impossible de lire le fichier Markdown"])
        }
        
        // Parser le contenu Markdown
        var deckName = url.deletingPathExtension().lastPathComponent
        var deckDescription = "Importé depuis Markdown"
        var cards: [Card] = []
        
        let lines = content.components(separatedBy: "\n")
        var i = 0
        
        // Chercher le titre (H1)
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if line.hasPrefix("# ") {
                deckName = line.replacingOccurrences(of: "# ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                i += 1
                
                // Chercher la description (texte italique)
                if i < lines.count {
                    let nextLine = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    if nextLine.hasPrefix("_") && nextLine.hasSuffix("_") {
                        deckDescription = nextLine.dropFirst().dropLast().trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                break
            }
            
            i += 1
        }
        
        // Parser les cartes
        var currentQuestion: String?
        var currentAnswer: String?
        var currentInfo: String?
        var inQuestion = false
        var inAnswer = false
        var inInfo = false
        
        for j in i..<lines.count {
            let line = lines[j].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if line.hasPrefix("## Question") {
                // Sauvegarder la carte précédente
                if let question = currentQuestion, let answer = currentAnswer {
                    cards.append(Card(
                        question: question,
                        answer: answer,
                        additionalInfo: currentInfo,
                        deckID: nil
                    ))
                }
                
                // Réinitialiser pour la nouvelle carte
                currentQuestion = ""
                currentAnswer = nil
                currentInfo = nil
                inQuestion = true
                inAnswer = false
                inInfo = false
            } else if line.hasPrefix("### Réponse") {
                inQuestion = false
                inAnswer = true
                inInfo = false
                currentAnswer = ""
            } else if line.hasPrefix("#### Informations supplémentaires") {
                inQuestion = false
                inAnswer = false
                inInfo = true
                currentInfo = ""
            } else if line.hasPrefix("---") {
                // Séparateur de cartes
                inQuestion = false
                inAnswer = false
                inInfo = false
            } else if line.hasPrefix("#") {
                // Ignorer les autres titres
                inQuestion = false
                inAnswer = false
                inInfo = false
            } else if !line.isEmpty {
                // Ajouter le contenu
                if inQuestion, currentQuestion != nil {
                    currentQuestion = (currentQuestion!.isEmpty ? "" : currentQuestion! + "\n") + line
                } else if inAnswer, currentAnswer != nil {
                    currentAnswer = (currentAnswer!.isEmpty ? "" : currentAnswer! + "\n") + line
                } else if inInfo {
                    currentInfo = (currentInfo ?? "") + (currentInfo?.isEmpty ?? true ? "" : "\n") + line
                }
            }
        }
        
        // Ajouter la dernière carte
        if let question = currentQuestion, let answer = currentAnswer {
            cards.append(Card(
                question: question,
                answer: answer,
                additionalInfo: currentInfo,
                deckID: nil
            ))
        }
        
        let deck = Deck(
            id: UUID(),
            name: deckName,
            description: deckDescription,
            icon: "doc.text.fill",
            colorName: "purple",
            createdAt: Date()
        )
        
        // Ajouter l'ID du paquet aux cartes
        cards = cards.map { card in
            var newCard = card
            return Card(
                id: newCard.id,
                question: newCard.question,
                answer: newCard.answer,
                additionalInfo: newCard.additionalInfo,
                deckID: deck.id,
                createdAt: newCard.createdAt,
                updatedAt: newCard.updatedAt,
                masteryLevel: newCard.masteryLevel,
                reviewCount: newCard.reviewCount,
                lastReviewedAt: newCard.lastReviewedAt,
                nextReviewDate: newCard.nextReviewDate
            )
        }
        
        return (deck, cards)
    }
    
    private func importFromXML(url: URL) throws -> (Deck, [Card]) {
        // Implémenter l'importation XML
        // Pour une implémentation réelle, utilisez XMLParser ou une bibliothèque tierce
        
        throw NSError(domain: "ImportExport", code: 5, userInfo: [NSLocalizedDescriptionKey: "Importation XML pas encore implémentée"])
    }
    
    private func importFromOPML(url: URL) throws -> (Deck, [Card]) {
        // Implémenter l'importation OPML
        // Pour une implémentation réelle, utilisez XMLParser ou une bibliothèque tierce
        
        throw NSError(domain: "ImportExport", code: 6, userInfo: [NSLocalizedDescriptionKey: "Importation OPML pas encore implémentée"])
    }
    
    // MARK: - Importation Anki (.apkg)
    func importFromAnki(url: URL, into context: NSManagedObjectContext) throws -> (Deck, [Card]) {
        // Créer un répertoire temporaire pour extraire le fichier .apkg
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        
        // Nettoyer le répertoire temporaire après l'opération
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Ouvrir l'archive Anki
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw ImportError.invalidArchive
        }
        
        // Extraire le fichier de base de données SQLite
        let dbEntry = archive.first { $0.path == "collection.anki2" }
        guard let dbEntry = dbEntry else {
            throw ImportError.missingDatabaseFile
        }
        
        let dbPath = tempDir.appendingPathComponent("collection.anki2")
        try archive.extract(dbEntry, to: dbPath)
        
        // Extraire le fichier de mappage des médias
        let mediaMapEntry = archive.first { $0.path == "media" }
        var mediaMap: [String: String] = [:]
        
        if let mediaMapEntry = mediaMapEntry {
            let mediaMapPath = tempDir.appendingPathComponent("media")
            try archive.extract(mediaMapEntry, to: mediaMapPath)
            
            if let mediaMapData = try? Data(contentsOf: mediaMapPath),
               let jsonObject = try? JSONSerialization.jsonObject(with: mediaMapData, options: []),
               let jsonMap = jsonObject as? [String: String] {
                mediaMap = jsonMap
            }
        }
        
        // Extraire tous les fichiers médias
        for entry in archive {
            // Si ce n'est pas collection.anki2 ni media, c'est probablement un fichier média
            if entry.path != "collection.anki2" && entry.path != "media" {
                try archive.extract(entry, to: tempDir.appendingPathComponent(entry.path))
            }
        }
        
        // Ouvrir la base de données SQLite
        let db = try SQLiteDatabase(path: dbPath)
        
        // Récupérer les informations sur les decks
        let decks = try readAnkiDecks(from: db)
        
        // Si aucun deck n'est trouvé, lever une erreur
        if decks.isEmpty {
            throw ImportError.noDecksFound
        }
        
        // Par défaut, utiliser le premier deck
        let selectedDeck = decks.first!
        
        // Créer un nouveau deck dans notre modèle de données
        let deck = Deck(context: context)
        deck.id = UUID()
        deck.name = selectedDeck.name
        deck.description = selectedDeck.desc
        deck.createdAt = Date()
        deck.updatedAt = Date()
        
        // Récupérer le modèle (note type) utilisé
        let noteTypes = try readAnkiModels(from: db)
        
        // Récupérer toutes les notes et cartes associées au deck sélectionné
        let cards = try readAnkiCards(from: db, deckId: selectedDeck.id, models: noteTypes, mediaDir: tempDir, mediaMap: mediaMap, context: context, parentDeck: deck)
        
        // Sauvegarder le contexte
        try context.save()
        
        return (deck, cards)
    }
    
    // MARK: - Helpers
    
    private func fetchCards(for deckId: UUID) -> [Card] {
        let fetchRequest = NSFetchRequest<CardEntity>(entityName: "CardEntity")
        fetchRequest.predicate = NSPredicate(format: "deck.id == %@", deckId as CVarArg)
        
        do {
            let cardEntities = try context.fetch(fetchRequest)
            return cardEntities.map { Card.from($0) }
        } catch {
            print("Erreur lors de la récupération des cartes: \(error)")
            return []
        }
    }
    
    private func saveDeck(_ deck: Deck, withCards cards: [Card]) throws {
        try context.performAndWait {
            // Sauvegarder le paquet
            let deckEntity = DeckEntity(context: context)
            deckEntity.id = deck.id
            deckEntity.name = deck.name
            deckEntity.icon = deck.icon
            deckEntity.colorName = deck.colorName
            deckEntity.deckDescription = deck.description
            deckEntity.createdAt = deck.createdAt
            
            // Sauvegarder les cartes
            for card in cards {
                let cardEntity = CardEntity(context: context)
                cardEntity.id = card.id
                cardEntity.question = card.question
                cardEntity.answer = card.answer
                cardEntity.additionalInfo = card.additionalInfo
                cardEntity.masteryLevel = card.masteryLevel.rawValue
                cardEntity.reviewCount = Int16(card.reviewCount)
                cardEntity.lastReviewedAt = card.lastReviewedAt
                cardEntity.nextReviewDate = card.nextReviewDate
                cardEntity.createdAt = card.createdAt
                cardEntity.updatedAt = card.updatedAt
                cardEntity.deck = deckEntity
            }
            
            try context.save()
        }
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                if inQuotes && line.hasPrefix("\"\"") {
                    currentField.append("\"")
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        fields.append(currentField)
        return fields
    }
    
    private func escapeXML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

// MARK: - Modèles enrichis pour l'export/import

struct EnhancedCardExport: Codable {
    let question: String
    let answer: String
    let additionalInfo: String
    let tags: [ImportExportService.CardTag]
    let masteryLevel: String
    let reviewCount: Int
    let lastReviewedAt: Date?
    let nextReviewDate: Date?
    let media: [ImportExportService.MediaItem]?
}

struct EnhancedDeckExport: Codable {
    let name: String
    let description: String
    let icon: String
    let colorName: String
    let cards: [EnhancedCardExport]
    let exportDate: Date
    let version: String
    let format: String
    let tags: [ImportExportService.CardTag]
}

// MARK: - Gestionnaire de base de données Anki

class AnkiDBManager {
    struct AnkiDeckInfo {
        let id: Int64
        let name: String
        let description: String
    }
    
    struct AnkiCard {
        let id: Int64
        let question: String
        let answer: String
        let additionalInfo: String?
        let tags: [String]
        let reviewCount: Int
        let media: [String]
    }
    
    func createAnkiDB(at path: URL, deck: Deck, cards: [Card]) throws {
        // Implémentation simplifiée - dans une application réelle,
        // il faudrait créer une vraie base SQLite compatible avec Anki
        
        // Pour cette démonstration, créons un fichier texte
        let content = "Anki DB placeholder for deck: \(deck.name)"
        try content.write(to: path, atomically: true, encoding: .utf8)
    }
    
    func readAnkiDB(at path: URL) throws -> (AnkiDeckInfo, [AnkiCard]) {
        // Implémenter la lecture d'une base de données Anki (.apkg)
        // Cela nécessiterait l'utilisation de SQLite pour lire la structure d'Anki
        
        // Version simplifiée pour la démonstration
        let deckInfo = AnkiDeckInfo(
            id: 1,
            name: "Paquet importé depuis Anki",
            description: "Importé depuis un fichier .apkg"
        )
        
        let cards = [
            AnkiCard(
                id: 1,
                question: "Question exemple d'Anki",
                answer: "Réponse exemple d'Anki",
                additionalInfo: nil,
                tags: ["anki", "import"],
                reviewCount: 0,
                media: []
            )
        ]
        
        return (deckInfo, cards)
    }
}

// Structure pour représenter un deck Anki
private struct AnkiDeck {
    let id: Int
    let name: String
    let desc: String
}

// Structure pour représenter un modèle (note type) Anki
private struct AnkiModel {
    let id: Int
    let name: String
    let fieldNames: [String]
    let templates: [(name: String, questionFormat: String, answerFormat: String)]
}

// Structure pour représenter une note Anki
private struct AnkiNote {
    let id: Int
    let fields: [String]
    let tags: [String]
}

// Structure pour représenter une carte Anki
private struct AnkiCard {
    let id: Int
    let noteId: Int
    let deckId: Int
    let templateIndex: Int
    let type: Int  // 0=new, 1=learning, 2=review
    let queue: Int // -3=user buried, -2=sched buried, -1=suspended, 0=new, 1=learning, 2=review, 3=day learn relearn
    let due: Int
    let factor: Int
    let reps: Int
    let lapses: Int
}

// Lire les decks depuis la base de données Anki
private func readAnkiDecks(from db: SQLiteDatabase) throws -> [AnkiDeck] {
    // Récupérer la ligne de la collection
    let colRows = try db.query("SELECT decks FROM col")
    
    guard let colRow = colRows.first, let decksJson = colRow["decks"] as? String else {
        throw ImportError.missingDecksData
    }
    
    guard let decksData = decksJson.data(using: .utf8),
          let decksDict = try JSONSerialization.jsonObject(with: decksData, options: []) as? [String: [String: Any]] else {
        throw ImportError.invalidDecksData
    }
    
    // Transformer le dictionnaire en tableau de AnkiDeck
    var decks: [AnkiDeck] = []
    
    for (idString, deckData) in decksDict {
        guard let id = Int(idString),
              let name = deckData["name"] as? String,
              let desc = deckData["desc"] as? String else {
            continue
        }
        
        // Ignorer le deck par défaut
        if id == 1 && name == "Default" {
            continue
        }
        
        decks.append(AnkiDeck(id: id, name: name, desc: desc))
    }
    
    return decks
}

// Lire les modèles (note types) depuis la base de données Anki
private func readAnkiModels(from db: SQLiteDatabase) throws -> [Int: AnkiModel] {
    // Récupérer la ligne de la collection
    let colRows = try db.query("SELECT models FROM col")
    
    guard let colRow = colRows.first, let modelsJson = colRow["models"] as? String else {
        throw ImportError.missingModelsData
    }
    
    guard let modelsData = modelsJson.data(using: .utf8),
          let modelsDict = try JSONSerialization.jsonObject(with: modelsData, options: []) as? [String: [String: Any]] else {
        throw ImportError.invalidModelsData
    }
    
    // Transformer le dictionnaire en tableau de AnkiModel
    var models: [Int: AnkiModel] = [:]
    
    for (idString, modelData) in modelsDict {
        guard let id = Int(idString),
              let name = modelData["name"] as? String,
              let fields = modelData["flds"] as? [[String: Any]],
              let templates = modelData["tmpls"] as? [[String: Any]] else {
            continue
        }
        
        // Extraire les noms des champs
        let fieldNames = fields.compactMap { $0["name"] as? String }
        
        // Extraire les templates
        var cardTemplates: [(name: String, questionFormat: String, answerFormat: String)] = []
        
        for template in templates {
            guard let templateName = template["name"] as? String,
                  let qfmt = template["qfmt"] as? String,
                  let afmt = template["afmt"] as? String else {
                continue
            }
            
            cardTemplates.append((name: templateName, questionFormat: qfmt, answerFormat: afmt))
        }
        
        models[id] = AnkiModel(id: id, name: name, fieldNames: fieldNames, templates: cardTemplates)
    }
    
    return models
}

// Lire les cartes depuis la base de données Anki
private func readAnkiCards(from db: SQLiteDatabase, deckId: Int, models: [Int: AnkiModel], mediaDir: URL, mediaMap: [String: String], context: NSManagedObjectContext, parentDeck: Deck) throws -> [Card] {
    // Récupérer toutes les cartes du deck
    let cardRows = try db.query("SELECT * FROM cards WHERE did = ?", parameters: [deckId])
    
    if cardRows.isEmpty {
        return []
    }
    
    // Récupérer les IDs des notes associées
    let noteIds = cardRows.compactMap { $0["nid"] as? Int }
    let noteIdsString = noteIds.map { String($0) }.joined(separator: ",")
    
    // Récupérer les notes
    let noteRows = try db.query("SELECT * FROM notes WHERE id IN (\(noteIdsString))")
    
    // Organiser les notes par ID
    var notesById: [Int: AnkiNote] = [:]
    
    for noteRow in noteRows {
        guard let id = noteRow["id"] as? Int,
              let fields = noteRow["flds"] as? String,
              let tags = noteRow["tags"] as? String else {
            continue
        }
        
        // Séparer les champs (séparés par le caractère 0x1F)
        let fieldValues = fields.components(separatedBy: String(UnicodeScalar(0x1F)!))
        
        // Analyser les tags
        let tagList = tags.split(separator: " ").map { String($0) }
        
        notesById[id] = AnkiNote(id: id, fields: fieldValues, tags: tagList)
    }
    
    // Créer les cartes dans notre modèle de données
    var importedCards: [Card] = []
    
    for cardRow in cardRows {
        guard let id = cardRow["id"] as? Int,
              let noteId = cardRow["nid"] as? Int,
              let templateIndex = cardRow["ord"] as? Int,
              let type = cardRow["type"] as? Int,
              let queue = cardRow["queue"] as? Int,
              let due = cardRow["due"] as? Int,
              let factor = cardRow["factor"] as? Int,
              let reps = cardRow["reps"] as? Int,
              let lapses = cardRow["lapses"] as? Int,
              let note = notesById[noteId] else {
            continue
        }
        
        // Récupérer le modèle de la note
        let modelId = try db.query("SELECT mid FROM notes WHERE id = ?", parameters: [noteId]).first?["mid"] as? Int ?? 0
        guard let model = models[modelId], templateIndex < model.templates.count else {
            continue
        }
        
        // Créer une carte dans notre modèle de données
        let card = Card(context: context)
        card.id = UUID()
        card.createdAt = Date()
        card.updatedAt = Date()
        card.deck = parentDeck
        
        // Déterminer la question et la réponse en fonction du template
        let template = model.templates[templateIndex]
        
        // Remplacer les variables {{Field}} dans les templates
        var question = template.questionFormat
        var answer = template.answerFormat
        
        for (index, fieldName) in model.fieldNames.enumerated() {
            let fieldValue = index < note.fields.count ? note.fields[index] : ""
            
            // Remplacer les variables dans les templates
            question = question.replacingOccurrences(of: "{{\(fieldName)}}", with: fieldValue)
            answer = answer.replacingOccurrences(of: "{{\(fieldName)}}", with: fieldValue)
        }
        
        // Remplacer FrontSide dans la réponse
        answer = answer.replacingOccurrences(of: "{{FrontSide}}", with: question)
        
        // Traiter les médias dans le texte
        question = processMediaReferences(in: question, mediaDir: mediaDir, mediaMap: mediaMap)
        answer = processMediaReferences(in: answer, mediaDir: mediaDir, mediaMap: mediaMap)
        
        // Définir les propriétés de la carte
        card.question = question
        card.answer = answer
        
        // Extraire des informations supplémentaires si disponibles
        if note.fields.count > 2 {
            card.additionalInfo = note.fields[2]
        }
        
        // Convertir l'état d'apprentissage Anki en niveau de maîtrise
        card.masteryLevel = convertAnkiStateToMastery(type: type, queue: queue, factor: factor, reps: reps, lapses: lapses)
        
        // Ajouter les tags
        if !note.tags.isEmpty {
            let tags = note.tags.joined(separator: ",")
            card.tags = tags
        }
        
        importedCards.append(card)
    }
    
    return importedCards
}

// Traiter les références de médias dans le texte
private func processMediaReferences(in text: String, mediaDir: URL, mediaMap: [String: String]) -> String {
    var processedText = text
    
    // Traiter les références d'images
    let imgRegex = try! NSRegularExpression(pattern: "<img\\s+src=[\"']([^\"']+)[\"'][^>]*>", options: [])
    let imgMatches = imgRegex.matches(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text))
    
    for match in imgMatches.reversed() {
        guard let srcRange = Range(match.range(at: 1), in: text) else { continue }
        let src = String(text[srcRange])
        
        // Vérifier si la source est dans le mappage des médias
        if let mediaFileName = getMediaFileName(for: src, in: mediaMap) {
            // Générer l'URL de stockage des médias dans notre application
            let mediaDestDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Media")
            
            // Créer le répertoire des médias s'il n'existe pas
            if !FileManager.default.fileExists(atPath: mediaDestDir.path) {
                try? FileManager.default.createDirectory(at: mediaDestDir, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Copier le fichier média dans notre répertoire
            let mediaSourcePath = mediaDir.appendingPathComponent(mediaFileName)
            let mediaDestFile = mediaDestDir.appendingPathComponent(UUID().uuidString + "-" + (URL(string: src)?.lastPathComponent ?? src))
            
            if FileManager.default.fileExists(atPath: mediaSourcePath.path) {
                try? FileManager.default.copyItem(at: mediaSourcePath, to: mediaDestFile)
                
                // Mettre à jour la référence dans le texte
                let newSrc = mediaDestFile.lastPathComponent
                processedText = processedText.replacingOccurrences(of: src, with: newSrc)
            }
        }
    }
    
    // Traiter les références audio [sound:...]
    let soundRegex = try! NSRegularExpression(pattern: "\\[sound:(.*?)\\]", options: [])
    let soundMatches = soundRegex.matches(in: processedText, options: [], range: NSRange(processedText.startIndex..<processedText.endIndex, in: processedText))
    
    for match in soundMatches.reversed() {
        guard let soundRange = Range(match.range(at: 1), in: processedText) else { continue }
        let soundFile = String(processedText[soundRange])
        
        // Vérifier si le fichier est dans le mappage des médias
        if let mediaFileName = getMediaFileName(for: soundFile, in: mediaMap) {
            // Générer l'URL de stockage des médias dans notre application
            let mediaDestDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Media")
            
            // Créer le répertoire des médias s'il n'existe pas
            if !FileManager.default.fileExists(atPath: mediaDestDir.path) {
                try? FileManager.default.createDirectory(at: mediaDestDir, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Copier le fichier média dans notre répertoire
            let mediaSourcePath = mediaDir.appendingPathComponent(mediaFileName)
            let mediaDestFile = mediaDestDir.appendingPathComponent(UUID().uuidString + "-" + soundFile)
            
            if FileManager.default.fileExists(atPath: mediaSourcePath.path) {
                try? FileManager.default.copyItem(at: mediaSourcePath, to: mediaDestFile)
                
                // Mettre à jour la référence dans le texte
                let newSoundTag = "[sound:\(mediaDestFile.lastPathComponent)]"
                processedText = processedText.replacingOccurrences(of: "[sound:\(soundFile)]", with: newSoundTag)
            }
        }
    }
    
    return processedText
}

// Récupérer le nom du fichier média à partir du mappage
private func getMediaFileName(for reference: String, in mediaMap: [String: String]) -> String? {
    // Parcourir le mappage pour trouver la correspondance
    for (fileName, originalName) in mediaMap {
        if originalName == reference {
            return fileName
        }
    }
    return nil
}

// Convertir l'état d'apprentissage Anki en niveau de maîtrise
private func convertAnkiStateToMastery(type: Int, queue: Int, factor: Int, reps: Int, lapses: Int) -> Int16 {
    // type: 0=new, 1=learning, 2=review, 3=relearning
    // queue: -3=user buried, -2=sched buried, -1=suspended, 0=new, 1=learning, 2=review, 3=day learn relearn
    
    if queue < 0 {
        // Cartes suspendues ou enterrées
        return 0 // Nouveau
    }
    
    switch type {
    case 0: // Carte nouvelle
        return 0 // Nouveau
    case 1: // Carte en apprentissage
        if reps <= 1 {
            return 1 // À peine appris
        } else {
            return 2 // En cours d'apprentissage
        }
    case 2: // Carte en révision
        if lapses > 3 {
            return 3 // Apprentissage difficile
        } else if factor < 2500 {
            return 4 // Bien maîtrisé
        } else {
            return 5 // Très bien maîtrisé
        }
    case 3: // Carte en réapprentissage
        return 2 // En cours d'apprentissage
    default:
        return 0 // Par défaut: nouveau
    }
} 