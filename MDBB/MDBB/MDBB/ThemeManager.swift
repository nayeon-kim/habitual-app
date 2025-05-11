import SwiftUI
import UIKit

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
    static let systemBackground = Color(uiColor: .systemBackground)
    static let secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
    static let tertiarySystemBackground = Color(uiColor: .tertiarySystemBackground)
    
    static let label = Color(uiColor: .label)
    static let secondaryLabel = Color(uiColor: .secondaryLabel)
    static let tertiaryLabel = Color(uiColor: .tertiaryLabel)
} 
