#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    /// Retourne la date formatée selon le style spécifié
    public func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
    
    /// Retourne la date formatée selon le format spécifié
    public func formatted(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    /// Retourne la date du jour à minuit
    public static var startOfDay: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    /// Retourne la date du jour à 23:59:59
    public static var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    func formatted(date: DateFormatter.Style = .medium, time: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = date
        formatter.timeStyle = time
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions
extension String {
    /// Retourne une version tronquée de la chaîne si elle dépasse la longueur maximale
    public func truncated(maxLength: Int) -> String {
        guard count > maxLength else { return self }
        return prefix(maxLength) + "..."
    }
    
    /// Vérifie si la chaîne est un UUID valide
    public var isUUID: Bool {
        UUID(uuidString: self) != nil
    }
    
    /// Retourne la première lettre de la chaîne en majuscule
    public var firstLetterCapitalized: String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }
    
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
    
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Color Extensions
extension Color {
    /// Crée une couleur à partir d'un code hexadécimal
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    var hex: String {
        #if canImport(UIKit)
        let components = UIColor(self).cgColor.components
        #elseif canImport(AppKit)
        let components = NSColor(self).cgColor.components
        #else
        let components: [CGFloat]? = nil
        #endif
        
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    }
}

// MARK: - Array Extensions
extension Array where Element: Hashable {
    /// Retourne un tableau sans doublons
    public var unique: [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - Optional Extensions
extension Optional where Wrapped == String {
    /// Retourne une chaîne vide si l'optionnel est nil
    public var orEmpty: String {
        self ?? ""
    }
}

extension Optional where Wrapped: Collection {
    /// Retourne true si l'optionnel est nil ou vide
    public var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}

// MARK: - View Extensions
extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
    
    func onFirstAppear(_ action: @escaping () -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }
}

private struct FirstAppearModifier: ViewModifier {
    let action: () -> Void
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content.onAppear {
            if !hasAppeared {
                hasAppeared = true
                action()
            }
        }
    }
}

// MARK: - Array Extensions
extension Array where Element: Identifiable {
    func sortedByIds(_ ids: [Element.ID]) -> [Element] {
        sorted { first, second in
            guard let firstIndex = ids.firstIndex(of: first.id),
                  let secondIndex = ids.firstIndex(of: second.id) else {
                return false
            }
            return firstIndex < secondIndex
        }
    }
} 