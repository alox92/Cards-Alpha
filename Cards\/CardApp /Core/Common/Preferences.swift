import Foundation
import SwiftUI

// MARK: - UserDefaults Keys
public enum UserDefaultsKey: String {
    case theme
    case language
    case notificationsEnabled
    case soundEnabled
    case hapticFeedbackEnabled
    case autoSaveEnabled
    case defaultDeckID
    case lastSyncDate
    case iCloudSyncEnabled
    case backupFrequency
    case lastBackupDate
    case maxCardsPerSession
    case reviewDuration
    case masteryThreshold
    case showHints
    case showExamples
    case showStatistics
    case showProgress
    case showTags
    case showRatings
    case showComments
    case showHistory
    case showRelated
    case showSimilar
    case showDifficult
    case showEasy
    case showNew
    case showDue
    case showOverdue
    case showSuspended
    case showArchived
    case showDeleted
    case showHidden
    case showLocked
    case showProtected
    case showShared
    case showPublic
    case showPrivate
    case showFavorites
    case showRecent
    case showPopular
    case showTrending
    case showRecommended
    case showSuggested
    case showCustom
    case showAll
}

// MARK: - UserDefaults Wrapper
@propertyWrapper
public struct UserDefault<T> {
    private let key: UserDefaultsKey
    private let defaultValue: T
    
    public init(_ key: UserDefaultsKey, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key.rawValue) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key.rawValue)
        }
    }
}

// MARK: - App Preferences
@MainActor
public class AppPreferences: ObservableObject {
    @MainActor
    public static let shared = AppPreferences()
    
    @UserDefault(.theme, defaultValue: Theme.system.rawValue)
    public var theme: String
    
    @UserDefault(.language, defaultValue: Locale.current.languageCode ?? "en")
    public var language: String
    
    @UserDefault(.notificationsEnabled, defaultValue: true)
    public var notificationsEnabled: Bool
    
    @UserDefault(.soundEnabled, defaultValue: true)
    public var soundEnabled: Bool
    
    @UserDefault(.hapticFeedbackEnabled, defaultValue: true)
    public var hapticFeedbackEnabled: Bool
    
    @UserDefault(.autoSaveEnabled, defaultValue: true)
    public var autoSaveEnabled: Bool
    
    @UserDefault(.defaultDeckID, defaultValue: nil)
    public var defaultDeckID: String?
    
    @UserDefault(.lastSyncDate, defaultValue: nil)
    public var lastSyncDate: Date?
    
    @UserDefault(.iCloudSyncEnabled, defaultValue: true)
    public var iCloudSyncEnabled: Bool
    
    @UserDefault(.backupFrequency, defaultValue: 7)
    public var backupFrequency: Int
    
    @UserDefault(.lastBackupDate, defaultValue: nil)
    public var lastBackupDate: Date?
    
    @UserDefault(.maxCardsPerSession, defaultValue: 20)
    public var maxCardsPerSession: Int
    
    @UserDefault(.reviewDuration, defaultValue: 300)
    public var reviewDuration: Int
    
    @UserDefault(.masteryThreshold, defaultValue: 0.8)
    public var masteryThreshold: Double
    
    @UserDefault(.showHints, defaultValue: true)
    public var showHints: Bool
    
    @UserDefault(.showExamples, defaultValue: true)
    public var showExamples: Bool
    
    @UserDefault(.showStatistics, defaultValue: true)
    public var showStatistics: Bool
    
    @UserDefault(.showProgress, defaultValue: true)
    public var showProgress: Bool
    
    @UserDefault(.showTags, defaultValue: true)
    public var showTags: Bool
    
    @UserDefault(.showRatings, defaultValue: true)
    public var showRatings: Bool
    
    @UserDefault(.showComments, defaultValue: true)
    public var showComments: Bool
    
    @UserDefault(.showHistory, defaultValue: true)
    public var showHistory: Bool
    
    @UserDefault(.showRelated, defaultValue: true)
    public var showRelated: Bool
    
    @UserDefault(.showSimilar, defaultValue: true)
    public var showSimilar: Bool
    
    @UserDefault(.showDifficult, defaultValue: true)
    public var showDifficult: Bool
    
    @UserDefault(.showEasy, defaultValue: true)
    public var showEasy: Bool
    
    @UserDefault(.showNew, defaultValue: true)
    public var showNew: Bool
    
    @UserDefault(.showDue, defaultValue: true)
    public var showDue: Bool
    
    @UserDefault(.showOverdue, defaultValue: true)
    public var showOverdue: Bool
    
    @UserDefault(.showSuspended, defaultValue: false)
    public var showSuspended: Bool
    
    @UserDefault(.showArchived, defaultValue: false)
    public var showArchived: Bool
    
    @UserDefault(.showDeleted, defaultValue: false)
    public var showDeleted: Bool
    
    @UserDefault(.showHidden, defaultValue: false)
    public var showHidden: Bool
    
    @UserDefault(.showLocked, defaultValue: false)
    public var showLocked: Bool
    
    @UserDefault(.showProtected, defaultValue: false)
    public var showProtected: Bool
    
    @UserDefault(.showShared, defaultValue: false)
    public var showShared: Bool
    
    @UserDefault(.showPublic, defaultValue: false)
    public var showPublic: Bool
    
    @UserDefault(.showPrivate, defaultValue: false)
    public var showPrivate: Bool
    
    @UserDefault(.showFavorites, defaultValue: false)
    public var showFavorites: Bool
    
    @UserDefault(.showRecent, defaultValue: false)
    public var showRecent: Bool
    
    @UserDefault(.showPopular, defaultValue: false)
    public var showPopular: Bool
    
    @UserDefault(.showTrending, defaultValue: false)
    public var showTrending: Bool
    
    @UserDefault(.showRecommended, defaultValue: false)
    public var showRecommended: Bool
    
    @UserDefault(.showSuggested, defaultValue: false)
    public var showSuggested: Bool
    
    @UserDefault(.showCustom, defaultValue: false)
    public var showCustom: Bool
    
    @UserDefault(.showAll, defaultValue: true)
    public var showAll: Bool
    
    private init() {}
} 