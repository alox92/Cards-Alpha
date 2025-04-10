# Analyse des Types et Ambiguïtés CoreData
> Rapport généré le Wed Apr  9 22:54:01 CEST 2025

## Résumé

Ce rapport analyse les problèmes d'ambiguïté des types dans le contexte CoreData du projet CardApp.


[0;34mClasses étendant NSManagedObject:[0m
```
./Core/Models/Data/CardEntity.swift:public class CardEntity: NSManagedObject, @unchecked Sendable {
./Core/Models/Data/CardReviewEntity.swift:public class CardReviewEntity: NSManagedObject, @unchecked Sendable {
./Core/Models/Data/DeckEntity.swift:public class DeckEntity: NSManagedObject, @unchecked Sendable {
./Core/Models/Data/StudySessionEntity.swift:public class StudySessionEntity: NSManagedObject, @unchecked Sendable {
./Core/Models/Data/TagEntity.swift:public class TagEntity: NSManagedObject, @unchecked Sendable {
./Core/Models/Data/TagItemAssociationEntity.swift:public class TagItemAssociationEntity: NSManagedObject, @unchecked Sendable {
./CoreDataOptimizer.swift:                            // Dans votre NSManagedObject subclass
```

[0;34mReprésentations modèles des entités CoreData:[0m
```
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    public init(from entity: CardEntity) {
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    public init(from entity: CardEntity) {
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    public init(from entity: CardEntity) {
./Core/Models/Card.swift:public init(from entity: CardEntity) {
./Core/Models/Data/CardReviewEntity.swift:    public init(from entity: CardReviewEntity) throws {
./Core/Models/Data/StudySessionEntity.swift:    public init(from entity: StudySessionEntity) throws {
./Core/Models/Data/TagEntity.swift:    public init(from entity: TagEntity) {
./Core/Models/Data/TagItemAssociationEntity.swift:    public init(from entity: TagItemAssociationEntity) throws {
```

[0;34mExtensions d'entités CoreData:[0m
```
./Core/Models/Data/CardEntity.swift:extension CardEntity {
./Core/Models/Data/CardReviewEntity.swift:extension CardReviewEntity {
./Core/Models/Data/DeckEntity.swift:extension DeckEntity {
./Core/Models/Data/StudySessionEntity.swift:extension StudySessionEntity {
./Core/Models/Data/TagEntity.swift:extension TagEntity {
./Core/Models/Data/TagItemAssociationEntity.swift:extension TagItemAssociationEntity {
./Core/Persistence/CoreDataModel.swift:extension CardEntity {
./Core/Persistence/CoreDataModel.swift:extension CardReviewEntity {
./Core/Persistence/CoreDataModel.swift:extension DeckEntity {
./Core/Persistence/CoreDataModel.swift:extension StudySessionEntity {
```

[0;34mDéfinitions de fetchRequest:[0m
```
./analysis_tools/swift_coredata_diagnostic/CoreDataFixer.swift:            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardReviewEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardReviewEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardReviewEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = CardReviewEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:fetchRequest.fetchBatchSize = 20; = StudySessionEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            let activeSessionFetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            let cardFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            let cardsFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            let cardsFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            let cardsFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            let sessionFetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let fetchRequest: NSFetchRequest<CardReviewEntity> = CardReviewEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let fetchRequest: NSFetchRequest<CardReviewEntity> = CardReviewEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let sessionFetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let sessionFetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let sessionFetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./Core/Managers/CoreDataManager.swift:        let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Managers/CoreDataManager.swift:        let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Managers/CoreDataManager.swift:        let fetchRequest: NSFetchRequest<CardReviewEntity> = CardReviewEntity.fetchRequest()
./Core/Managers/CoreDataManager.swift:        let fetchRequest: NSFetchRequest<CardReviewEntity> = CardReviewEntity.fetchRequest()
./Core/Managers/CoreDataManager.swift:        let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Managers/CoreDataManager.swift:        let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Managers/CoreDataManager.swift:        let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./Core/Models/Data/CardEntity.swift:    @nonobjc public class func fetchRequest() -> NSFetchRequest<CardEntity> {
./Core/Models/Data/CardReviewEntity.swift:    @nonobjc public class func fetchRequest() -> NSFetchRequest<CardReviewEntity> {
./Core/Models/Data/DeckEntity.swift:    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeckEntity> {
./Core/Models/Data/StudySessionEntity.swift:    @nonobjc public class func fetchRequest() -> NSFetchRequest<StudySessionEntity> {
./Core/Models/Data/TagEntity.swift:    @nonobjc public class func fetchRequest() -> NSFetchRequest<TagEntity> {
./Core/Models/Data/TagItemAssociationEntity.swift:    @nonobjc public class func fetchRequest() -> NSFetchRequest<TagItemAssociationEntity> {
./Core/Services/Example/ThreadSafeCoreDataService.swift:            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Example/ThreadSafeCoreDataService.swift:            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Example/ThreadSafeCoreDataService.swift:            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Example/ThreadSafeCoreDataService.swift:            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Study/StudyService.swift:        let request = StudySessionEntity.fetchRequest()
./Core/Services/Unified/UnifiedCardService.swift:            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedCardService.swift:            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedCardService.swift:            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedCardService.swift:            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedCardService.swift:            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedCardService.swift:            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedCardService.swift:            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedCardService.swift:            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedCardService.swift:            let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:                let oldDeckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let cardFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let cardFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let cardFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let cardFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let cardsFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let cardsFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let deckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let deckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let deckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let deckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let deckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let decksFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let parentFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let parentFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let parentFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let subdeckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:            let subdeckFetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:        let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:        let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:        let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedDeckService.swift:        let fetchRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
./Core/Services/Unified/UnifiedStudyService.swift:            let activeSessionFetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./Core/Services/Unified/UnifiedStudyService.swift:            let cardsFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedStudyService.swift:            let cardsFetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedStudyService.swift:            let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./Core/Services/Unified/UnifiedStudyService.swift:            let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./Core/Services/Unified/UnifiedStudyService.swift:            let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./Core/Services/Unified/UnifiedStudyService.swift:        let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedStudyService.swift:        let fetchRequest: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
./Core/Services/Unified/UnifiedStudyService.swift:        let fetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./Core/Services/Unified/UnifiedStudyService.swift:        let sessionFetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./Core/Services/Unified/UnifiedStudyService.swift:        let sessionFetchRequest: NSFetchRequest<StudySessionEntity> = StudySessionEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
./Core/Services/Unified/UnifiedTagService.swift:        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
```

[0;34mAttributs @NSManaged:[0m
```
./Core/Models/Data/CardEntity.swift:    @NSManaged public var additionalInfo: String?
./Core/Models/Data/CardEntity.swift:    @NSManaged public var answer: String
./Core/Models/Data/CardEntity.swift:    @NSManaged public var correctCount: Int16
./Core/Models/Data/CardEntity.swift:    @NSManaged public var createdAt: Date
./Core/Models/Data/CardEntity.swift:    @NSManaged public var deck: DeckEntity?
./Core/Models/Data/CardEntity.swift:    @NSManaged public var deckID: UUID?
./Core/Models/Data/CardEntity.swift:    @NSManaged public var ease: Double
./Core/Models/Data/CardEntity.swift:    @NSManaged public var id: UUID?
./Core/Models/Data/CardEntity.swift:    @NSManaged public var incorrectCount: Int16
./Core/Models/Data/CardEntity.swift:    @NSManaged public var interval: Int16
./Core/Models/Data/CardEntity.swift:    @NSManaged public var isFlagged: Bool
./Core/Models/Data/CardEntity.swift:    @NSManaged public var lastReviewedAt: Date?
./Core/Models/Data/CardEntity.swift:    @NSManaged public var masteryLevel: Int16
./Core/Models/Data/CardEntity.swift:    @NSManaged public var nextReviewDate: Date?
./Core/Models/Data/CardEntity.swift:    @NSManaged public var question: String
./Core/Models/Data/CardEntity.swift:    @NSManaged public var reviewCount: Int16
./Core/Models/Data/CardEntity.swift:    @NSManaged public var reviews: Set<CardReviewEntity>
./Core/Models/Data/CardEntity.swift:    @NSManaged public var tags: [String]
./Core/Models/Data/CardEntity.swift:    @NSManaged public var updatedAt: Date
./Core/Models/Data/CardReviewEntity.swift:    @NSManaged public var card: CardEntity?
./Core/Models/Data/CardReviewEntity.swift:    @NSManaged public var id: UUID?
./Core/Models/Data/CardReviewEntity.swift:    @NSManaged public var newEase: Double
./Core/Models/Data/CardReviewEntity.swift:    @NSManaged public var newInterval: Int16
./Core/Models/Data/CardReviewEntity.swift:    @NSManaged public var newMasteryLevel: Int16
./Core/Models/Data/CardReviewEntity.swift:    @NSManaged public var rating: String
./Core/Models/Data/CardReviewEntity.swift:    @NSManaged public var responseTime: Double
./Core/Models/Data/CardReviewEntity.swift:    @NSManaged public var session: StudySessionEntity?
./Core/Models/Data/CardReviewEntity.swift:    @NSManaged public var timestamp: Date
./Core/Models/Data/DeckEntity.swift:    @NSManaged public var cardCount: Int32
./Core/Models/Data/DeckEntity.swift:    @NSManaged public var cards: Set<CardEntity>
./Core/Models/Data/DeckEntity.swift:    @NSManaged public var colorName: String
./Core/Models/Data/DeckEntity.swift:    @NSManaged public var createdAt: Date
./Core/Models/Data/DeckEntity.swift:    @NSManaged public var desc: String
./Core/Models/Data/DeckEntity.swift:    @NSManaged public var icon: String
./Core/Models/Data/DeckEntity.swift:    @NSManaged public var id: UUID?
./Core/Models/Data/DeckEntity.swift:    @NSManaged public var name: String
./Core/Models/Data/DeckEntity.swift:    @NSManaged public var parentDeck: DeckEntity?
./Core/Models/Data/DeckEntity.swift:    @NSManaged public var subdecks: Set<DeckEntity>
./Core/Models/Data/DeckEntity.swift:    @NSManaged public var tags: [String]
./Core/Models/Data/DeckEntity.swift:    @NSManaged public var updatedAt: Date
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var deck: DeckEntity?
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var deckID: UUID?
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var endTime: Date?
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var id: UUID?
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var includeSubdecks: Bool
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var reviewLimit: Int32
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var reviews: Set<CardReviewEntity>
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var reviewsData: Data?
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var startTime: Date?
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var totalCorrect: Int32
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var totalIncorrect: Int32
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var totalReviews: Int32
./Core/Models/Data/StudySessionEntity.swift:    @NSManaged public var totalTime: Double
./Core/Models/Data/TagEntity.swift:    @NSManaged public var color: String
./Core/Models/Data/TagEntity.swift:    @NSManaged public var createdAt: Date
./Core/Models/Data/TagEntity.swift:    @NSManaged public var id: UUID?
./Core/Models/Data/TagEntity.swift:    @NSManaged public var name: String
./Core/Models/Data/TagEntity.swift:    @NSManaged public var tagDescription: String?
./Core/Models/Data/TagEntity.swift:    @NSManaged public var updatedAt: Date
./Core/Models/Data/TagEntity.swift:    @NSManaged public var usage: Int16
./Core/Models/Data/TagItemAssociationEntity.swift:    @NSManaged public var createdAt: Date?
./Core/Models/Data/TagItemAssociationEntity.swift:    @NSManaged public var id: UUID?
./Core/Models/Data/TagItemAssociationEntity.swift:    @NSManaged public var itemID: UUID?
./Core/Models/Data/TagItemAssociationEntity.swift:    @NSManaged public var itemType: String?
./Core/Models/Data/TagItemAssociationEntity.swift:    @NSManaged public var tagID: UUID?
./CoreDataOptimizer.swift:                            @NSManaged public var \(attribute.name): \(attributeTypeString(attribute))
```

[0;34mConversions d'entités vers modèles:[0m
```
./.build/checkouts/swift-collections/Sources/HashTreeCollections/HashNode/_HashNode+Structural filter.swift:            result.copyItemsAndChildren(level, from: $0, upTo: bucket)
./.build/checkouts/swift-collections/Sources/HashTreeCollections/HashNode/_HashNode+Structural filter.swift:          result.copyCollisions(from: $0, upTo: slot)
./.build/checkouts/swift-collections/Sources/HashTreeCollections/HashNode/_HashNode+Structural filter.swift:          result.copyItems(level, from: $0, upTo: bucket)
./.build/index-build/checkouts/swift-collections/Sources/HashTreeCollections/HashNode/_HashNode+Structural filter.swift:            result.copyItemsAndChildren(level, from: $0, upTo: bucket)
./.build/index-build/checkouts/swift-collections/Sources/HashTreeCollections/HashNode/_HashNode+Structural filter.swift:          result.copyCollisions(from: $0, upTo: slot)
./.build/index-build/checkouts/swift-collections/Sources/HashTreeCollections/HashNode/_HashNode+Structural filter.swift:          result.copyItems(level, from: $0, upTo: bucket)
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            return cardEntities.map { Card(from: $0) }
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            return cards.map { Card(from: $0) }
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            return cards.map { Card(from: $0) }
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            return entities.map { Card(from: $0) }
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            return cardEntities.map { Card(from: $0) }
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            return cards.map { Card(from: $0) }
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            return cards.map { Card(from: $0) }
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            return entities.map { Card(from: $0) }
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            return cardEntities.map { Card(from: $0) }
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            return cards.map { Card(from: $0) }
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            return cards.map { Card(from: $0) }
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            return entities.map { Card(from: $0) }
./Core/Services/Study/StudyService.swift:                return try entities.map { try CardReview(from: $0) }
./Core/Services/Study/StudyService.swift:        return try entities.map { try StudySession(from: $0) }
./Core/Services/Unified/UnifiedStudyService.swift:            return cardEntities.map { Card(from: $0) }
./Core/Services/Unified/UnifiedStudyService.swift:            return cards.map { Card(from: $0) }
./Core/Services/Unified/UnifiedStudyService.swift:            return cards.map { Card(from: $0) }
./Core/Services/Unified/UnifiedStudyService.swift:            return entities.map { Card(from: $0) }
```

[0;34mEnum utilisés avec CoreData:[0m
```
```

[0;34mAnalyse des ambiguïtés de types:[0m
### MasteryLevel
```
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:                            newMasteryLevel: entity.newMasteryLevel
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:                currentLevel: MasteryLevel(rawValue: Int(card.masteryLevel)) ?? .novice,
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:                newMasteryLevel: MasteryLevel(rawValue: Int(data.newMasteryLevel)) ?? .novice
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:                newMasteryLevel: MasteryLevel(rawValue: Int(review.newMasteryLevel)) ?? .novice
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            $0.masteryLevel == MasteryLevel.beginner.rawValue || 
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            $0.masteryLevel == MasteryLevel.beginner.rawValue || 
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            $0.masteryLevel == MasteryLevel.intermediate.rawValue 
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            $0.masteryLevel == MasteryLevel.intermediate.rawValue 
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            card.masteryLevel = review.newMasteryLevel
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            let newMasteryLevel: MasteryLevel = self.scheduler!.calculateNewMasteryLevel(
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            masteryLevel: MasteryLevel(rawValue: Int(entity.masteryLevel)) ?? .novice,
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            newMasteryLevel: MasteryLevel(rawValue: Int(entity.newMasteryLevel)) ?? .novice
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            newMasteryLevel: reviewData.newMasteryLevel
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:            review.newMasteryLevel = Int16(newMasteryLevel.rawValue)
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:        let masteredCards = cardsData.filter { $0.masteryLevel == MasteryLevel.expert.rawValue }.count
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:        let masteredCards = cardsData.filter { $0.masteryLevel == MasteryLevel.expert.rawValue }.count
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:        let newCards = cardsData.filter { $0.masteryLevel == MasteryLevel.novice.rawValue }.count
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:        let newCards = cardsData.filter { $0.masteryLevel == MasteryLevel.novice.rawValue }.count
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:        let reviewingCards = cardsData.filter { $0.masteryLevel == MasteryLevel.advanced.rawValue }.count
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:        let reviewingCards = cardsData.filter { $0.masteryLevel == MasteryLevel.advanced.rawValue }.count
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:        newMasteryLevel: Int = 0
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:        self.newMasteryLevel = MasteryLevel(rawValue: newMasteryLevel) ?? .novice
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    let newMasteryLevel: Int16
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    nonisolated func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    nonisolated static func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:                            newMasteryLevel: entity.newMasteryLevel
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:                currentLevel: MasteryLevel(rawValue: Int(card.masteryLevel)) ?? .novice,
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:                newMasteryLevel: MasteryLevel(rawValue: Int(data.newMasteryLevel)) ?? .novice
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:                newMasteryLevel: MasteryLevel(rawValue: Int(review.newMasteryLevel)) ?? .novice
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            $0.masteryLevel == MasteryLevel.beginner.rawValue || 
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            $0.masteryLevel == MasteryLevel.beginner.rawValue || 
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            $0.masteryLevel == MasteryLevel.intermediate.rawValue 
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            $0.masteryLevel == MasteryLevel.intermediate.rawValue 
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            card.masteryLevel = review.newMasteryLevel
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            let newMasteryLevel: MasteryLevel = self.scheduler!.calculateNewMasteryLevel(
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            masteryLevel: MasteryLevel(rawValue: Int(entity.masteryLevel)) ?? .novice,
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            newMasteryLevel: MasteryLevel(rawValue: Int(entity.newMasteryLevel)) ?? .novice
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            newMasteryLevel: reviewData.newMasteryLevel
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:            review.newMasteryLevel = Int16(newMasteryLevel.rawValue)
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:        let masteredCards = cardsData.filter { $0.masteryLevel == MasteryLevel.expert.rawValue }.count
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:        let masteredCards = cardsData.filter { $0.masteryLevel == MasteryLevel.expert.rawValue }.count
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:        let newCards = cardsData.filter { $0.masteryLevel == MasteryLevel.novice.rawValue }.count
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:        let newCards = cardsData.filter { $0.masteryLevel == MasteryLevel.novice.rawValue }.count
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:        let reviewingCards = cardsData.filter { $0.masteryLevel == MasteryLevel.advanced.rawValue }.count
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:        let reviewingCards = cardsData.filter { $0.masteryLevel == MasteryLevel.advanced.rawValue }.count
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:        newMasteryLevel: Int = 0
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:        self.newMasteryLevel = MasteryLevel(rawValue: newMasteryLevel) ?? .novice
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    let newMasteryLevel: Int16
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    nonisolated func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    nonisolated static func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                            newMasteryLevel: entity.newMasteryLevel
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                currentLevel: Core.Models.Common.MasteryLevel(rawValue: Int(card.masteryLevel)) ?? .novice,
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                newMasteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(data.newMasteryLevel)) ?? .novice
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                newMasteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(review.newMasteryLevel)) ?? .novice
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            $0.masteryLevel == Core.Models.Common.MasteryLevel.beginner.rawValue || 
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            $0.masteryLevel == Core.Models.Common.MasteryLevel.beginner.rawValue || 
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            $0.masteryLevel == Core.Models.Common.MasteryLevel.intermediate.rawValue 
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            $0.masteryLevel == Core.Models.Common.MasteryLevel.intermediate.rawValue 
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            card.masteryLevel = review.newMasteryLevel
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            let newMasteryLevel: Core.Models.Common.MasteryLevel = self.scheduler!.calculateNewMasteryLevel(
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            masteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(entity.masteryLevel)) ?? .novice,
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            newMasteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(entity.newMasteryLevel)) ?? .novice
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            newMasteryLevel: reviewData.newMasteryLevel
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            review.newMasteryLevel = Int16(newMasteryLevel.rawValue)
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let masteredCards = cardsData.filter { $0.masteryLevel == Core.Models.Common.MasteryLevel.expert.rawValue }.count
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let masteredCards = cardsData.filter { $0.masteryLevel == Core.Models.Common.MasteryLevel.expert.rawValue }.count
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let newCards = cardsData.filter { $0.masteryLevel == Core.Models.Common.MasteryLevel.novice.rawValue }.count
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let newCards = cardsData.filter { $0.masteryLevel == Core.Models.Common.MasteryLevel.novice.rawValue }.count
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let reviewingCards = cardsData.filter { $0.masteryLevel == Core.Models.Common.MasteryLevel.advanced.rawValue }.count
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let reviewingCards = cardsData.filter { $0.masteryLevel == Core.Models.Common.MasteryLevel.advanced.rawValue }.count
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        newMasteryLevel: Int = 0
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        self.newMasteryLevel = Core.Models.Common.MasteryLevel(rawValue: newMasteryLevel) ?? .novice
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated static func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
./Core/Common/Types.swift:        masteryLevel: Core.Models.Common.MasteryLevel? = nil,
./Core/Common/Types.swift:    public let masteryLevel: Core.Models.Common.MasteryLevel?
./Core/Common/Types.swift:// Note: Core.Models.Common.MasteryLevel est maintenant défini dans Core/Models/Common/Enums.swift
./Core/Core.swift:// Note: Dans un module Swift, tous les types publics (MasteryLevel, ReviewRating, CardSortOption, etc.)
./Core/Managers/CoreDataManager.swift:        review.newMasteryLevel = newMasteryLevel
./Core/Managers/CoreDataManager.swift:    func createCardReview(card: CardEntity, session: StudySessionEntity, rating: String, responseTime: Double, newInterval: Int16, newEase: Double, newMasteryLevel: Int16) throws -> CardReviewEntity {
./Core/Models/Card.swift:        copy.masteryLevel = newMasteryLevel
./Core/Models/Card.swift:        let newMasteryLevel = scheduler.calculateNewMasteryLevel(currentLevel: masteryLevel, rating: rating)
./Core/Models/Card.swift:        masteryLevel: Core.Models.Common.MasteryLevel = .novice,
./Core/Models/Card.swift:    public var masteryLevel: Core.Models.Common.MasteryLevel
./Core/Models/Card.swift:self.masteryLevel = MasteryLevel(rawValue: Int(entity.masteryLevel)) ?? .novice
./Core/Models/Common/Enums.swift:public enum MasteryLevel: Int, Codable, CaseIterable, Sendable {
./Core/Models/Common/Models.swift:/// - MasteryLevel et ReviewRating dans Core/Common/Types.swift
./Core/Models/Data/CardReviewEntity.swift:            newMasteryLevel: MasteryLevel(rawValue: Int(entity.newMasteryLevel)) ?? .novice
./Core/Models/Data/CardReviewEntity.swift:    @NSManaged public var newMasteryLevel: Int16
./Core/Models/Study/CardReview.swift:        newMasteryLevel: Core.Models.Common.MasteryLevel = .novice
./Core/Models/Study/CardReview.swift:        self.newMasteryLevel = newMasteryLevel
./Core/Models/Study/CardReview.swift:    public let newMasteryLevel: Core.Models.Common.MasteryLevel
./Core/Persistence/CoreDataModel.swift:            masteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(masteryLevel)) ?? .novice,
./Core/Persistence/CoreDataModel.swift:            newMasteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(newMasteryLevel)) ?? .novice
./Core/Persistence/CoreDataModel.swift:        newMasteryLevel = Int16(model.newCore.Models.Common.MasteryLevel.rawValue)
./Core/Protocols/CardSchedulerProtocolV2.swift:    func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
./Core/Services/Example/ThreadSafeCoreDataService.swift:            masteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(entity.masteryLevel)) ?? .novice,
./Core/Services/Stats/StatisticsView.swift:// struct Card: Identifiable { let id: UUID; var masteryLevel: Core.Models.Common.MasteryLevel? }
./Core/Services/Stats/StatisticsViewModel.swift:    @Published var masteryData: [StatsMasteryLevel: Int] = [:]
./Core/Services/Stats/StatisticsViewModel.swift:    /// Convertit un MasteryLevel du modèle en StatsMasteryLevel pour l'affichage
./Core/Services/Stats/StatisticsViewModel.swift:    private func generateMasteryDistributionFromDeckStats(_ deckStats: DeckStats?) -> [StatsMasteryLevel: Int] {
./Core/Services/Stats/StatisticsViewModel.swift:    public static func from(masteryLevel: Core.Models.Common.MasteryLevel) -> StatsMasteryLevel {
./Core/Services/Stats/StatisticsViewModel.swift:/// distinct de l'énumération MasteryLevel utilisée dans le modèle de carte
./Core/Services/Stats/StatisticsViewModel.swift:public enum StatsMasteryLevel: String, CaseIterable, Identifiable {
./Core/Services/Study/StudyService.swift:            newMasteryLevel: card.masteryLevel
./Core/Services/Study/StudyService.swift:        entity.newMasteryLevel = Int16(newReview.newMasteryLevel.rawValue)
./Core/Services/Unified/CardScheduler.swift:            return MasteryLevel(rawValue: max(0, currentLevel.rawValue - 1)) ?? .novice
./Core/Services/Unified/CardScheduler.swift:            return MasteryLevel(rawValue: min(4, currentLevel.rawValue + 1)) ?? .expert
./Core/Services/Unified/CardScheduler.swift:            return MasteryLevel(rawValue: min(4, currentLevel.rawValue + 2)) ?? .expert
./Core/Services/Unified/CardScheduler.swift:        return CardSchedulerV2().calculateNewMasteryLevel(currentLevel: currentLevel, rating: rating)
./Core/Services/Unified/CardScheduler.swift:    nonisolated public func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel {
./Core/Services/Unified/CardScheduler.swift:    nonisolated public static func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel {
./Core/Services/Unified/UnifiedCardService.swift:                entity.masteryLevel = Int16(Core.Models.Common.MasteryLevel.novice.rawValue) // Réinitialiser le niveau de maîtrise
./Core/Services/Unified/UnifiedCardService.swift:            masteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(entity.masteryLevel)) ?? .novice,
./Core/Services/Unified/UnifiedCardService.swift:        updatedCard.masteryLevel = CardScheduler.calculateNewMasteryLevel(
./Core/Services/Unified/UnifiedDeckService.swift:                masteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(cardEntity.masteryLevel)) ?? .novice,
./Core/Services/Unified/UnifiedStudyService.swift:            newMasteryLevel: MasteryLevel(rawValue: Int(entity.newMasteryLevel)) ?? .novice
./Core/Services/Unified/UnifiedStudyService.swift:        let newMasteryLevel: Int16
```
### ReviewRating
```
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:        self.rating = rating <= 3 ? ReviewRating(rawValue: rating) ?? .again : .again
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    let rating: ReviewRating
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    let rating: ReviewRating
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    let rating: ReviewRating
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    nonisolated func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    nonisolated func calculateNextReview(currentInterval: Int, currentEase: Double, rating: ReviewRating) -> (interval: Int, ease: Double)
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    nonisolated func calculateNextReviewDate(currentInterval: Int, rating: ReviewRating) -> Date
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    nonisolated static func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    nonisolated static func calculateNextReview(currentInterval: Int, currentEase: Double, rating: ReviewRating) -> (interval: Int, ease: Double)
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    nonisolated static func calculateNextReviewDate(currentInterval: Int, rating: ReviewRating) -> Date
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    public func recordCardReview(cardID: UUID, sessionID: UUID, rating: ReviewRating, responseTime: TimeInterval) async throws -> Core.Models.Study.CardReview {
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:        self.rating = rating <= 3 ? ReviewRating(rawValue: rating) ?? .again : .again
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    let rating: ReviewRating
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    let rating: ReviewRating
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    let rating: ReviewRating
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    nonisolated func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    nonisolated func calculateNextReview(currentInterval: Int, currentEase: Double, rating: ReviewRating) -> (interval: Int, ease: Double)
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    nonisolated func calculateNextReviewDate(currentInterval: Int, rating: ReviewRating) -> Date
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    nonisolated static func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    nonisolated static func calculateNextReview(currentInterval: Int, currentEase: Double, rating: ReviewRating) -> (interval: Int, ease: Double)
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    nonisolated static func calculateNextReviewDate(currentInterval: Int, rating: ReviewRating) -> Date
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    public func recordCardReview(cardID: UUID, sessionID: UUID, rating: ReviewRating, responseTime: TimeInterval) async throws -> Core.Models.Study.CardReview {
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        self.rating = rating <= 3 ? Core.Common.ReviewRating(rawValue: rating) ?? .again : .again
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated func calculateNextReview(currentInterval: Int, currentEase: Double, rating: Core.Common.ReviewRating) -> (interval: Int, ease: Double)
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated func calculateNextReviewDate(currentInterval: Int, rating: Core.Common.ReviewRating) -> Date
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated static func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated static func calculateNextReview(currentInterval: Int, currentEase: Double, rating: Core.Common.ReviewRating) -> (interval: Int, ease: Double)
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated static func calculateNextReviewDate(currentInterval: Int, rating: Core.Common.ReviewRating) -> Date
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    public func recordCardReview(cardID: UUID, sessionID: UUID, rating: Core.Common.ReviewRating, responseTime: TimeInterval) async throws -> Core.Models.Study.CardReview {
./Core/Common/Types.swift:    enum ReviewRating: Int, Codable, CaseIterable, Sendable {
./Core/Core.swift:// Note: Dans un module Swift, tous les types publics (MasteryLevel, ReviewRating, CardSortOption, etc.)
./Core/Models/Card.swift:    public func recordReview(rating: Core.Common.ReviewRating, scheduler: any CardSchedulerProtocolV2) -> Card {
./Core/Models/Common/Models.swift:/// - MasteryLevel et ReviewRating dans Core/Common/Types.swift
./Core/Models/Data/CardReviewEntity.swift:                return ReviewRating(rawValue: intValue) ?? .again
./Core/Models/Data/CardReviewEntity.swift:    public var reviewRating: ReviewRating {
./Core/Models/Data/StudySessionEntity.swift:               let rating = ReviewRating(rawValue: ratingValue) {
./Core/Models/Data/StudySessionEntity.swift:               let rating = ReviewRating(rawValue: ratingValue) {
./Core/Models/Study/CardReview.swift:        rating: Core.Common.ReviewRating,
./Core/Models/Study/CardReview.swift:    public let rating: Core.Common.ReviewRating
./Core/Persistence/CoreDataModel.swift:            rating: Core.Common.ReviewRating(rawValue: Int(rating) ?? 0) ?? .again,
./Core/Protocols/CardSchedulerProtocolV2.swift:    func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
./Core/Protocols/CardSchedulerProtocolV2.swift:    func calculateNextReview(currentInterval: Int, currentEase: Double, rating: Core.Common.ReviewRating) -> (interval: Int, ease: Double)
./Core/Protocols/CardSchedulerProtocolV2.swift:    func calculateNextReviewDate(currentInterval: Int, rating: Core.Common.ReviewRating) -> Date
./Core/Protocols/Services/CardServiceProtocol.swift:    func updateCardAfterReview(_ card: Card, rating: Core.Common.ReviewRating) async throws -> Card
./Core/Protocols/StudyServiceProtocol.swift:    func recordCardReview(cardID: UUID, sessionID: UUID, rating: Core.Common.ReviewRating, responseTime: TimeInterval) async throws -> CardReview
./Core/Services/Study/StudyService.swift:    public func recordCardReview(cardID: UUID, rating: Core.Common.ReviewRating, responseTime: TimeInterval) async throws -> Card {
./Core/Services/Study/StudyService.swift:    public func recordCardReview(cardID: UUID, sessionID: UUID, rating: Core.Common.ReviewRating, responseTime: TimeInterval) async throws -> CardReview {
./Core/Services/Unified/CardScheduler.swift:    nonisolated public func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel {
./Core/Services/Unified/CardScheduler.swift:    nonisolated public func calculateNextReview(currentInterval: Int, currentEase: Double, rating: ReviewRating) -> (interval: Int, ease: Double) {
./Core/Services/Unified/CardScheduler.swift:    nonisolated public func calculateNextReviewDate(currentInterval: Int, rating: ReviewRating) -> Date {
./Core/Services/Unified/CardScheduler.swift:    nonisolated public static func calculateNewMasteryLevel(currentLevel: MasteryLevel, rating: ReviewRating) -> MasteryLevel {
./Core/Services/Unified/CardScheduler.swift:    nonisolated public static func calculateNextReview(currentInterval: Int, currentEase: Double, rating: ReviewRating) -> (interval: Int, ease: Double) {
./Core/Services/Unified/CardScheduler.swift:    nonisolated public static func calculateNextReviewDate(currentInterval: Int, rating: ReviewRating) -> Date {
./Core/Services/Unified/UnifiedCardService.swift:    public func updateCardAfterReview(_ card: Card, rating: Core.Common.ReviewRating) async throws -> Card {
./Core/Services/Unified/UnifiedStudyService.swift:        let rating: ReviewRating
./Core/Services/Unified/UnifiedStudyService.swift:        let rating: ReviewRating
./Core/Services/Unified/UnifiedStudyService.swift:        let rating: ReviewRating
```

[0;34mAnalyse des ambiguïtés avec Core.Common:[0m
### Core.Common
```
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                        continuation.resume(throwing: Core.Common.StudyServiceError.invalidData)
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                        continuation.resume(throwing: Core.Common.StudyServiceError.sessionNotFound)
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                throw Core.Common.StudyServiceError.cardNotFound
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                throw Core.Common.StudyServiceError.sessionAlreadyStarted
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                throw Core.Common.StudyServiceError.sessionNotFound
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                throw Core.Common.StudyServiceError.sessionNotFound
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                throw Core.Common.StudyServiceError.sessionNotFound
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                throw Core.Common.StudyServiceError.sessionNotFound
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                throw Core.Common.StudyServiceError.sessionNotFound
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                throw Core.Common.StudyServiceError.sessionNotFound
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        self.rating = rating <= 3 ? Core.Common.ReviewRating(rawValue: rating) ?? .again : .again
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated func calculateNextReview(currentInterval: Int, currentEase: Double, rating: Core.Common.ReviewRating) -> (interval: Int, ease: Double)
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated func calculateNextReviewDate(currentInterval: Int, rating: Core.Common.ReviewRating) -> Date
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated static func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated static func calculateNextReview(currentInterval: Int, currentEase: Double, rating: Core.Common.ReviewRating) -> (interval: Int, ease: Double)
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated static func calculateNextReviewDate(currentInterval: Int, rating: Core.Common.ReviewRating) -> Date
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    public func recordCardReview(cardID: UUID, sessionID: UUID, rating: Core.Common.ReviewRating, responseTime: TimeInterval) async throws -> Core.Models.Study.CardReview {
./Core/Models/Card.swift:    public func recordReview(rating: Core.Common.ReviewRating, scheduler: any CardSchedulerProtocolV2) -> Card {
./Core/Models/Data/StudySessionEntity.swift:            throw Core.Common.StudyServiceError.invalidData
./Core/Models/Study/CardReview.swift:        rating: Core.Common.ReviewRating,
./Core/Models/Study/CardReview.swift:    public let rating: Core.Common.ReviewRating
./Core/Persistence/CoreDataModel.swift:            rating: Core.Common.ReviewRating(rawValue: Int(rating) ?? 0) ?? .again,
./Core/Protocols/CardSchedulerProtocolV2.swift:    func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
./Core/Protocols/CardSchedulerProtocolV2.swift:    func calculateNextReview(currentInterval: Int, currentEase: Double, rating: Core.Common.ReviewRating) -> (interval: Int, ease: Double)
./Core/Protocols/CardSchedulerProtocolV2.swift:    func calculateNextReviewDate(currentInterval: Int, rating: Core.Common.ReviewRating) -> Date
./Core/Protocols/Services/CardServiceProtocol.swift:    func updateCardAfterReview(_ card: Card, rating: Core.Common.ReviewRating) async throws -> Card
./Core/Protocols/StudyServiceProtocol.swift:    func recordCardReview(cardID: UUID, sessionID: UUID, rating: Core.Common.ReviewRating, responseTime: TimeInterval) async throws -> CardReview
./Core/Services/Study/StudyService.swift:                    throw Core.Common.StudyServiceError.cardNotFound
./Core/Services/Study/StudyService.swift:                    throw Core.Common.StudyServiceError.sessionNotFound
./Core/Services/Study/StudyService.swift:            throw Core.Common.StudyServiceError.cardAlreadyReviewed
./Core/Services/Study/StudyService.swift:            throw Core.Common.StudyServiceError.noActiveSession
./Core/Services/Study/StudyService.swift:            throw Core.Common.StudyServiceError.noActiveSession
./Core/Services/Study/StudyService.swift:            throw Core.Common.StudyServiceError.noActiveSession
./Core/Services/Study/StudyService.swift:            throw Core.Common.StudyServiceError.sessionAlreadyStarted
./Core/Services/Study/StudyService.swift:            throw Core.Common.StudyServiceError.sessionNotFound
./Core/Services/Study/StudyService.swift:    public func recordCardReview(cardID: UUID, rating: Core.Common.ReviewRating, responseTime: TimeInterval) async throws -> Card {
./Core/Services/Study/StudyService.swift:    public func recordCardReview(cardID: UUID, sessionID: UUID, rating: Core.Common.ReviewRating, responseTime: TimeInterval) async throws -> CardReview {
./Core/Services/Unified/UnifiedCardService.swift:    public func updateCardAfterReview(_ card: Card, rating: Core.Common.ReviewRating) async throws -> Card {
```
### Core.Models.Common
```
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                currentLevel: Core.Models.Common.MasteryLevel(rawValue: Int(card.masteryLevel)) ?? .novice,
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                newMasteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(data.newMasteryLevel)) ?? .novice
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:                newMasteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(review.newMasteryLevel)) ?? .novice
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            $0.masteryLevel == Core.Models.Common.MasteryLevel.beginner.rawValue || 
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            $0.masteryLevel == Core.Models.Common.MasteryLevel.beginner.rawValue || 
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            $0.masteryLevel == Core.Models.Common.MasteryLevel.intermediate.rawValue 
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            $0.masteryLevel == Core.Models.Common.MasteryLevel.intermediate.rawValue 
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            let newMasteryLevel: Core.Models.Common.MasteryLevel = self.scheduler!.calculateNewMasteryLevel(
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            masteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(entity.masteryLevel)) ?? .novice,
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:            newMasteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(entity.newMasteryLevel)) ?? .novice
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let masteredCards = cardsData.filter { $0.masteryLevel == Core.Models.Common.MasteryLevel.expert.rawValue }.count
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let masteredCards = cardsData.filter { $0.masteryLevel == Core.Models.Common.MasteryLevel.expert.rawValue }.count
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let newCards = cardsData.filter { $0.masteryLevel == Core.Models.Common.MasteryLevel.novice.rawValue }.count
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let newCards = cardsData.filter { $0.masteryLevel == Core.Models.Common.MasteryLevel.novice.rawValue }.count
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let reviewingCards = cardsData.filter { $0.masteryLevel == Core.Models.Common.MasteryLevel.advanced.rawValue }.count
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        let reviewingCards = cardsData.filter { $0.masteryLevel == Core.Models.Common.MasteryLevel.advanced.rawValue }.count
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        self.newMasteryLevel = Core.Models.Common.MasteryLevel(rawValue: newMasteryLevel) ?? .novice
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    nonisolated static func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
./Core/Common/Types.swift:        masteryLevel: Core.Models.Common.MasteryLevel? = nil,
./Core/Common/Types.swift:    public let masteryLevel: Core.Models.Common.MasteryLevel?
./Core/Common/Types.swift:// Note: Core.Models.Common.MasteryLevel est maintenant défini dans Core/Models/Common/Enums.swift
./Core/Models/Card.swift:        masteryLevel: Core.Models.Common.MasteryLevel = .novice,
./Core/Models/Card.swift:    public var masteryLevel: Core.Models.Common.MasteryLevel
./Core/Models/Study/CardReview.swift:        newMasteryLevel: Core.Models.Common.MasteryLevel = .novice
./Core/Models/Study/CardReview.swift:    public let newMasteryLevel: Core.Models.Common.MasteryLevel
./Core/Persistence/CoreDataModel.swift:            masteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(masteryLevel)) ?? .novice,
./Core/Persistence/CoreDataModel.swift:            newMasteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(newMasteryLevel)) ?? .novice
./Core/Persistence/CoreDataModel.swift:        newMasteryLevel = Int16(model.newCore.Models.Common.MasteryLevel.rawValue)
./Core/Protocols/CardSchedulerProtocolV2.swift:    func calculateNewMasteryLevel(currentLevel: Core.Models.Common.MasteryLevel, rating: Core.Common.ReviewRating) -> Core.Models.Common.MasteryLevel
./Core/Services/Example/ThreadSafeCoreDataService.swift:            masteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(entity.masteryLevel)) ?? .novice,
./Core/Services/Stats/StatisticsView.swift:// struct Card: Identifiable { let id: UUID; var masteryLevel: Core.Models.Common.MasteryLevel? }
./Core/Services/Stats/StatisticsViewModel.swift:    public static func from(masteryLevel: Core.Models.Common.MasteryLevel) -> StatsMasteryLevel {
./Core/Services/Unified/UnifiedCardService.swift:                entity.masteryLevel = Int16(Core.Models.Common.MasteryLevel.novice.rawValue) // Réinitialiser le niveau de maîtrise
./Core/Services/Unified/UnifiedCardService.swift:            masteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(entity.masteryLevel)) ?? .novice,
./Core/Services/Unified/UnifiedDeckService.swift:                masteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(cardEntity.masteryLevel)) ?? .novice,
```

[0;34mAnalyse des ambiguïtés avec PersistenceController:[0m
```
./analysis_tools/swift_coredata_diagnostic/CoreDataFixer.swift:            fileToModify: "\(projectPath)/Core/Persistence/PersistenceController.swift",
./analysis_tools/swift_coredata_diagnostic/CoreDataFixer.swift:            fileToModify: "\(projectPath)/Core/Persistence/PersistenceController.swift",
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:        persistenceController: PersistenceController,
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    private let persistence: PersistenceController
./backups_manual_fixes_20250409_223334/UnifiedStudyService.swift:    public init(persistence: PersistenceController, cardService: CardServiceProtocol) {
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:        persistenceController: PersistenceController,
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    private let persistence: PersistenceController
./backups_syntax_fixes_20250409_223033/UnifiedStudyService.swift:    public init(persistence: PersistenceController, cardService: CardServiceProtocol) {
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:        persistenceController: PersistenceController,
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    private let persistence: PersistenceController
./backups_unified_study_20250409_222913/UnifiedStudyService.swift:    public init(persistence: PersistenceController, cardService: CardServiceProtocol) {
./Core/DI/DependencyContainer.swift:            fatalError("PersistenceControllerProtocol ne peut pas être converti en PersistenceController")
./Core/DI/DependencyContainer.swift:            fatalError("PersistenceControllerProtocol ne peut pas être converti en PersistenceController")
./Core/DI/DependencyContainer.swift:            fatalError("PersistenceControllerProtocol ne peut pas être converti en PersistenceController")
./Core/DI/DependencyContainer.swift:            PersistenceController.shared
./Core/DI/DependencyContainer.swift:            PersistenceController(inMemory: true) : 
./Core/DI/DependencyContainer.swift:        // Convertir en PersistenceController si nécessaire
./Core/DI/DependencyContainer.swift:        // Convertir en PersistenceController si nécessaire
./Core/DI/DependencyContainer.swift:        // Convertir en PersistenceController si nécessaire
./Core/DI/DependencyContainer.swift:        if let persistenceCtrl = persistenceController as? PersistenceController {
./Core/DI/DependencyContainer.swift:        if let persistenceCtrl = persistenceController as? PersistenceController {
./Core/DI/DependencyContainer.swift:        if let persistenceCtrl = persistenceController as? PersistenceController {
./Core/DI/DependencyContainer.swift:        let persistenceController = PersistenceController()
./Core/DI/DependencyContainer.swift:    @Published public private(set) var persistenceController: PersistenceControllerProtocol!
./Core/DI/DependencyContainer.swift:    public init(persistenceController: PersistenceControllerProtocol) {}
./Core/DI/DependencyContainer.swift:    public init(persistenceController: PersistenceControllerProtocol) {}
./Core/DI/DependencyContainer.swift:    public init(persistenceController: PersistenceControllerProtocol) {}
./Core/DI/DependencyContainer.swift:    public static let shared = PersistenceController()
./Core/DI/DependencyContainer.swift:// Protocole défini dans Core/Persistence/PersistenceController.swift
./Core/DI/DependencyContainer.swift:public class PersistenceController: PersistenceControllerProtocol, @unchecked Sendable {
./Core/DI/PersistenceControllerKey.swift:        get { self[PersistenceControllerKey.self] }
./Core/DI/PersistenceControllerKey.swift:        let result = PersistenceController(inMemory: true)
./Core/DI/PersistenceControllerKey.swift:        self.persistenceController = PersistenceController(inMemory: true)
./Core/DI/PersistenceControllerKey.swift:        set { self[PersistenceControllerKey.self] = newValue }
./Core/DI/PersistenceControllerKey.swift:    let persistenceController: PersistenceController
./Core/DI/PersistenceControllerKey.swift:    public static let defaultValue: PersistenceController = {
./Core/DI/PersistenceControllerKey.swift:    public static let shared = PersistenceControllerWrapper()
./Core/DI/PersistenceControllerKey.swift:    var persistenceController: PersistenceController {
./Core/DI/PersistenceControllerKey.swift:@objc public class PersistenceControllerWrapper: NSObject, @unchecked Sendable {
./Core/DI/PersistenceControllerKey.swift:/// Clé d'environnement pour accéder au PersistenceController
./Core/DI/PersistenceControllerKey.swift:/// Extension pour ajouter le PersistenceController à l'environnement
./Core/DI/PersistenceControllerKey.swift:/// Wrapper non-isolé pour fournir le PersistenceController
./Core/DI/PersistenceControllerKey.swift:public struct PersistenceControllerKey: EnvironmentKey {
./Core/Persistence/CoreDataSimplified.swift:    static let shared = SimplifiedPersistenceController()
./Core/Persistence/CoreDataSimplified.swift:struct SimplifiedPersistenceController {
./Core/Persistence/PersistenceController.swift:    public static let shared = PersistenceController()
./Core/Persistence/PersistenceController.swift:public final class PersistenceController: PersistenceControllerProtocol, @unchecked Sendable {
./Core/Persistence/PersistenceController.swift:public protocol PersistenceControllerProtocol: Sendable {
./Core/Services/Base/BackupService.swift:    // private let persistenceController: PersistenceController
./Core/Services/Base/DataManagementService.swift:    private let persistenceController: PersistenceController
./Core/Services/Base/DataManagementService.swift:    public init(persistenceController: PersistenceController, fileManager: FileManager = .default) {
./Core/Services/Base/SyncService.swift:            fatalError("PersistenceController ne fournit pas un NSPersistentCloudKitContainer requis pour CloudSyncService.")
./Core/Services/Base/SyncService.swift:    public init(persistenceController: PersistenceController) {
./Core/Services/Example/ThreadSafeCoreDataService.swift:    private let persistenceController: PersistenceController
./Core/Services/Example/ThreadSafeCoreDataService.swift:    public init(persistenceController: PersistenceController) {
./Core/Services/Statistics/StatisticsServiceProtocol.swift:    private let persistenceController: PersistenceController
./Core/Services/Statistics/StatisticsServiceProtocol.swift:    public init(persistenceController: PersistenceController) {
./Core/Services/Stats/StatisticsViewModel.swift:        let persistenceController = PersistenceController(inMemory: true)
./Core/Services/Study/StudyService.swift:        persistence: PersistenceControllerProtocol,
./Core/Services/Study/StudyService.swift:    private let persistence: PersistenceControllerProtocol
./Core/Services/Unified/UnifiedCardService.swift:    private let persistenceController: PersistenceController
./Core/Services/Unified/UnifiedCardService.swift:    public init(persistenceController: PersistenceController) {
./Core/Services/Unified/UnifiedDeckService.swift:    private let persistenceController: PersistenceController
./Core/Services/Unified/UnifiedDeckService.swift:    public init(persistenceController: PersistenceController) {
./Core/Services/Unified/UnifiedStudyService.swift:        persistenceController: PersistenceController,
./Core/Services/Unified/UnifiedStudyService.swift:    private let persistence: PersistenceController
./Core/Services/Unified/UnifiedStudyService.swift:    public init(persistence: PersistenceController, cardService: CardServiceProtocol) {
./Core/Services/Unified/UnifiedTagService.swift:    private let persistenceController: PersistenceController
./Core/Services/Unified/UnifiedTagService.swift:    public init(persistenceController: PersistenceController, 
```

## Recommandations

Sur la base de l'analyse, voici les recommandations pour résoudre les ambiguïtés de types CoreData:

1. **Unification des modèles CoreData**
   - Utiliser un seul modèle CoreData nommé "CardApp" au lieu des deux modèles actuels
   - Mettre à jour toutes les références à NSPersistentContainer pour utiliser ce nom unifié

2. **Normalisation des types communs**
   - Définir les types comme MasteryLevel et ReviewRating dans un seul emplacement
   - Utiliser des imports qualifiés pour ces types partout ailleurs

3. **Résolution des problèmes d'ambiguïté**
   - Utiliser des qualificateurs complets pour les types ambigus (ex: Core.Common.ReviewRating)
   - Ajouter des imports clairs au début des fichiers

4. **Nettoyage des conversions entité-modèle**
   - Normaliser les initializers des modèles à partir des entités
   - S'assurer que toutes les conversions gèrent correctement les valeurs optionnelles

5. **Refactoring du PersistenceController**
   - S'assurer que PersistenceController n'est défini qu'à un seul endroit
   - Utiliser une qualification complète pour toutes les références

## Plan d'action

1. Exécuter le script `fix_coredata_models.sh` pour unifier les modèles CoreData
2. Exécuter le script `fix_ambiguous_types.sh` pour corriger les références ambiguës
3. Vérifier et corriger manuellement les problèmes restants
4. Mettre en place des directives pour éviter ces problèmes à l'avenir

