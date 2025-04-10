import SwiftUI

// MARK: - Theme
public enum Theme: String, CaseIterable {
    case system
    case light
    case dark
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    public var localizedName: String {
        switch self {
        case .system:
            return "Système"
        case .light:
            return "Clair"
        case .dark:
            return "Sombre"
        }
    }
}

// MARK: - Theme Colors
public enum ThemeColor {
    public static let primary = Color("Primary")
    public static let secondary = Color("Secondary")
    public static let accent = Color("Accent")
    public static let background = Color("Background")
    public static let foreground = Color("Foreground")
    public static let error = Color("Error")
    public static let success = Color("Success")
    public static let warning = Color("Warning")
    public static let info = Color("Info")
}

// MARK: - Theme Fonts
public enum ThemeFont {
    public static let title = Font.title
    public static let headline = Font.headline
    public static let subheadline = Font.subheadline
    public static let body = Font.body
    public static let callout = Font.callout
    public static let caption = Font.caption
    public static let footnote = Font.footnote
}

// MARK: - Theme Spacing
public enum ThemeSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}

// MARK: - Theme Corner Radius
public enum ThemeCornerRadius {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

// MARK: - Theme Shadows
public enum ThemeShadow {
    public static let xs = Color.black.opacity(0.1)
    public static let sm = Color.black.opacity(0.2)
    public static let md = Color.black.opacity(0.3)
    public static let lg = Color.black.opacity(0.4)
    public static let xl = Color.black.opacity(0.5)
}

// MARK: - Theme Animation
public enum ThemeAnimation {
    public static let fast = 0.2
    public static let normal = 0.3
    public static let slow = 0.4
} 