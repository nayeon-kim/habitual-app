import SwiftUI

struct Theme {
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let accent = Color("Accent")
    static let text = Color("Text")
    static let textSecondary = Color("TextSecondary")
    
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let error = Color("Error")
    
    static let cornerRadius: CGFloat = 12
    static let padding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    
    static let animation = Animation.spring(response: 0.3, dampingFraction: 0.7)
}

extension Color {
    static let systemBackground = Color(UIColor.systemBackground)
    static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
    static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)
    
    static let label = Color(UIColor.label)
    static let secondaryLabel = Color(UIColor.secondaryLabel)
    static let tertiaryLabel = Color(UIColor.tertiaryLabel)
} 