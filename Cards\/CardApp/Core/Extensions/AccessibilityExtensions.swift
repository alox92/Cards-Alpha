import SwiftUI

extension View {
    /// Améliorations d'accessibilité pour les cartes
    func cardAccessibility(isFrontShowing: Bool, question: String, answer: String) -> some View {
        self
            .accessibility(label: Text(isFrontShowing ? "Question" : "Réponse"))
            .accessibility(value: Text(isFrontShowing ? question : answer))
            .accessibility(hint: Text("Appuyez pour retourner la carte"))
    }
    
    /// Améliorations d'accessibilité pour les éléments à ordre de focus explicite
    func accessibilityFocusOrder(_ order: Int) -> some View {
        #if os(macOS)
        return self.accessibility(sortPriority: Double(order))
        #else
        return self
        #endif
    }
    
    /// Améliorations d'accessibilité pour les raccourcis clavier
    func accessibilityKeyboardShortcut(_ key: String, modifiers: [EventModifiers] = []) -> some View {
        var modifiersText = ""
        
        if modifiers.contains(.command) { modifiersText += "⌘ " }
        if modifiers.contains(.shift) { modifiersText += "⇧ " }
        if modifiers.contains(.option) { modifiersText += "⌥ " }
        if modifiers.contains(.control) { modifiersText += "⌃ " }
        
        return self.accessibility(hint: Text("Raccourci clavier: \(modifiersText)\(key)"))
    }
    
    /// Ajoute un support pour modifier la taille du texte relative
    func adaptiveFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        #if os(macOS)
        return self.font(.system(size: size, weight: weight))
        #else
        return self.font(.system(size: size, weight: weight))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        #endif
    }
    
    /// Support du mode sombre explicite
    func adaptiveCardBackground() -> some View {
        #if os(macOS)
        return self.background(Color(.textBackgroundColor))
        #else
        return self.background(Color(.systemBackground))
        #endif
    }
}

// Extensions pour l'accessibilité des maquettes d'étude
extension ReviewRating {
    var accessibilityLabel: String {
        switch self {
        case .again:
            return "À revoir, pas mémorisé"
        case .hard:
            return "Difficile à se rappeler"
        case .good:
            return "Bien mémorisé"
        case .easy:
            return "Facilement mémorisé"
        }
    }
} 