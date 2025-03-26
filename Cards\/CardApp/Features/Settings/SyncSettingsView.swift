import SwiftUI
import CloudKit
import UniformTypeIdentifiers
import Combine

struct SyncSettingsView: View {
    @State private var isCloudAvailable = false
    @State private var isCheckingStatus = false
    @State private var lastSyncDate: Date? = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    @State private var syncError: String? = nil
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var selectedFileName: String? = nil
    @State private var exportURL: URL? = nil
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }
    
    private var macOSLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cloudSyncSection
                
                Divider()
                
                manualBackupSection
            }
            .padding()
            .frame(maxWidth: 700)
        }
        .onAppear {
            checkCloudStatus()
        }
        .onChange(of: isCloudAvailable) { newValue in
            if newValue {
                updateLastSyncDate()
            }
        }
        .fileExporter(
            isPresented: $showingExportSheet,
            document: BackupFileDocument(),
            contentType: .json,
            defaultFilename: "CardsBackup_\(formattedCurrentDate())"
        ) { result in
            switch result {
            case .success(let url):
                print("Fichier exporté à: \(url)")
                // Utiliser le service pour exporter tous les paquets
                // Pour cette démo, nous exportons un paquet d'exemple
                if let firstDeck = fetchExampleDeck() {
                    ImportExportService.shared.exportDeck(firstDeck, to: .json)
                        .receive(on: DispatchQueue.main)
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    syncError = "Erreur d'exportation: \(error.localizedDescription)"
                                }
                            },
                            receiveValue: { tempURL in
                                do {
                                    // Remplacer le fichier exporté par les vraies données
                                    try FileManager.default.removeItem(at: url)
                                    try FileManager.default.copyItem(at: tempURL, to: url)
                                } catch {
                                    syncError = "Erreur de copie: \(error.localizedDescription)"
                                }
                            }
                        )
                        .store(in: &cancellables)
                }
            case .failure(let error):
                print("Erreur lors de l'exportation: \(error.localizedDescription)")
                syncError = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $showingImportSheet,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedURL = urls.first else { return }
                selectedFileName = selectedURL.lastPathComponent
                importBackup(from: selectedURL)
            case .failure(let error):
                print("Erreur lors de l'importation: \(error.localizedDescription)")
                syncError = error.localizedDescription
            }
        }
    }
    
    private var iOSLayout: some View {
        List {
            Section(header: Text("Synchronisation iCloud")) {
                cloudStatusRow
                
                if isCloudAvailable {
                    lastSyncRow
                    
                    Button(action: {
                        forceSynchronization()
                    }) {
                        Label("Synchroniser maintenant", systemImage: "arrow.clockwise")
                    }
                }
            }
            
            Section(header: Text("Sauvegardes manuelles")) {
                Button(action: {
                    showingExportSheet = true
                }) {
                    Label("Exporter les données", systemImage: "square.and.arrow.up")
                }
                
                Button(action: {
                    showingImportSheet = true
                }) {
                    Label("Importer une sauvegarde", systemImage: "square.and.arrow.down")
                }
                
                if let error = syncError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            checkCloudStatus()
        }
    }
    
    // MARK: - Cloud Sync Section (macOS)
    
    private var cloudSyncSection: some View {
        GroupBox(label: 
            Label("Synchronisation iCloud", systemImage: "cloud")
                .font(.headline)
        ) {
            VStack(alignment: .leading, spacing: 16) {
                cloudStatusRow
                
                if isCloudAvailable {
                    lastSyncRow
                    
                    Button(action: {
                        forceSynchronization()
                    }) {
                        Text("Synchroniser maintenant")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Text("La synchronisation iCloud n'est pas disponible. Veuillez vous connecter à votre compte iCloud dans les Préférences Système.")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }
                
                if let error = syncError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Manual Backup Section (macOS)
    
    private var manualBackupSection: some View {
        GroupBox(label:
            Label("Sauvegardes manuelles", systemImage: "externaldrive")
                .font(.headline)
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Vous pouvez sauvegarder manuellement vos données ou restaurer une sauvegarde précédente.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    Button(action: {
                        showingExportSheet = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                            Text("Exporter les données")
                        }
                        .frame(minWidth: 180, minHeight: 120)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        showingImportSheet = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 24))
                            Text("Importer une sauvegarde")
                        }
                        .frame(minWidth: 180, minHeight: 120)
                    }
                    .buttonStyle(.bordered)
                }
                
                if let fileName = selectedFileName {
                    Text("Fichier importé: \(fileName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Common Components
    
    private var cloudStatusRow: some View {
        HStack {
            if isCheckingStatus {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.trailing, 4)
            } else {
                Image(systemName: isCloudAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCloudAvailable ? .green : .red)
            }
            
            Text("Statut iCloud:")
                .fontWeight(.medium)
            
            Text(isCloudAvailable ? "Connecté" : "Non connecté")
                .foregroundColor(isCloudAvailable ? .green : .red)
            
            Spacer()
            
            Button(action: {
                checkCloudStatus()
            }) {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.plain)
            .disabled(isCheckingStatus)
        }
    }
    
    private var lastSyncRow: some View {
        HStack {
            Text("Dernière synchronisation:")
                .fontWeight(.medium)
            
            if let date = lastSyncDate {
                Text(formatDate(date))
                    .foregroundColor(.secondary)
            } else {
                Text("Jamais")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Actions
    
    private func checkCloudStatus() {
        isCheckingStatus = true
        
        CloudSyncService.shared.checkCloudStatus { available, error in
            isCloudAvailable = available
            
            if let error = error {
                syncError = error.localizedDescription
            } else {
                syncError = nil
            }
            
            isCheckingStatus = false
        }
    }
    
    private func forceSynchronization() {
        CloudSyncService.shared.forceSynchronization()
        updateLastSyncDate()
    }
    
    private func updateLastSyncDate() {
        let now = Date()
        lastSyncDate = now
        UserDefaults.standard.set(now, forKey: "lastSyncDate")
    }
    
    private func importBackup(from url: URL) {
        // Utiliser notre service d'importation
        syncError = nil
        ImportExportService.shared.importDeck(from: url)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        syncError = "Erreur d'importation: \(error.localizedDescription)"
                    }
                },
                receiveValue: { deck in
                    selectedFileName = "Paquet importé: \(deck.name) (\(deck.cards.count) cartes)"
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Helper methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formattedCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
    
    private func fetchExampleDeck() -> Deck? {
        // Dans une application réelle, vous récupéreriez un paquet réel depuis le modèle
        // Pour la démo, nous créons un paquet d'exemple
        
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest = NSFetchRequest<DeckEntity>(entityName: "DeckEntity")
        fetchRequest.fetchLimit = 1
        
        do {
            if let deckEntity = try context.fetch(fetchRequest).first {
                // Convertir l'entité en modèle
                return Deck.from(deckEntity)
            }
        } catch {
            print("Erreur lors de la récupération d'un paquet: \(error)")
        }
        
        // Si aucun paquet n'existe, créer un exemple
        return Deck(
            id: UUID(),
            name: "Sauvegarde",
            description: "Paquet de démonstration pour l'exportation",
            icon: "square.stack.3d.up",
            colorName: "blue",
            createdAt: Date()
        )
    }
}

// Document pour l'exportation
struct BackupFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .xml, .commaSeparatedText, .plainText, UTType(filenameExtension: "apkg") ?? .data] }
    
    var data: Data = Data()
    
    init() {
        // Pour l'exportation, nous créons une représentation vide que nous remplacerons
        // lors de la sélection du fichier de destination
        let placeholder = ["message": "Cette sauvegarde sera remplacée par les données réelles"]
        if let jsonData = try? JSONSerialization.data(withJSONObject: placeholder, options: .prettyPrinted) {
            self.data = jsonData
        }
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // L'exportation réelle devrait être gérée en réponse à l'événement fileExporter.onCompletion
        return FileWrapper(regularFileWithContents: data)
    }
}

struct SyncSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SyncSettingsView()
            .frame(width: 700, height: 500)
    }
} 