import SwiftUI

/// Nordic Electric AI theme implementation for Aurora Browser
/// Based on the Nordic Electric AI color scheme from /Users/dima/Development/cv/
struct NordicElectricAI {
    // MARK: - Color Palette
    
    /// Deep blue background
    static let backgroundDeep = Color(red: 0.059, green: 0.082, blue: 0.145)
    
    /// Slightly lighter background for surfaces
    static let backgroundMedium = Color(red: 0.075, green: 0.102, blue: 0.180)
    
    /// Surface color for cards and panels
    static let surface = Color(red: 0.090, green: 0.125, blue: 0.220)
    
    /// Primary accent color - electric fjord blue
    static let accentBlue = Color(red: 0.231, green: 0.620, blue: 1.000)
    
    /// Secondary accent - glacier cyan
    static let accentCyan = Color(red: 0.125, green: 0.902, blue: 0.839)
    
    /// Tertiary accent - Freyja's royal purple
    static let accentPurple = Color(red: 0.600, green: 0.400, blue: 1.000)
    
    /// Highlight color - Nordic forest green
    static let highlightGreen = Color(red: 0.365, green: 0.941, blue: 0.690)
    
    /// Warning color - Amber like Nordic gold
    static let warningOrange = Color(red: 1.000, green: 0.620, blue: 0.310)
    
    /// Gold accent - like Freyja's tears
    static let accentGold = Color(red: 0.961, green: 0.839, blue: 0.498)
    
    /// Error color - softer red
    static let errorRed = Color(red: 1.000, green: 0.365, blue: 0.561)
    
    /// Success color - Nordic sea teal
    static let successTeal = Color(red: 0.251, green: 0.851, blue: 0.769)
    
    /// Accent color - Nordic wildflower pink
    static let accentPink = Color(red: 0.898, green: 0.443, blue: 0.710)
    
    /// Text color - snow white
    static let textPrimary = Color(red: 0.839, green: 0.898, blue: 1.000)
    
    /// Secondary text color - slightly dimmed
    static let textSecondary = Color(red: 0.639, green: 0.698, blue: 0.800)
    
    // MARK: - Gradients
    
    /// Aurora gradient for special elements
    static let auroraGradient = LinearGradient(
        gradient: Gradient(colors: [accentBlue, accentPurple, accentPink]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Holographic gradient for backgrounds
    static let holographicGradient = LinearGradient(
        gradient: Gradient(colors: [
            backgroundDeep,
            backgroundDeep.opacity(0.9),
            backgroundMedium.opacity(0.8),
            Color(red: 0.1, green: 0.15, blue: 0.25).opacity(0.7)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Electric gradient for buttons and interactive elements
    static let electricGradient = LinearGradient(
        gradient: Gradient(colors: [accentBlue, accentCyan]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Effects
    
    /// Creates a holographic card effect
    static func holographicCard<Content: View>(intensity: Double = 1.0, @ViewBuilder content: @escaping () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(accentBlue.opacity(0.3 * intensity), lineWidth: 1)
                    )
                    .shadow(color: accentBlue.opacity(0.1 * intensity), radius: 10, x: 0, y: 5)
            )
    }
    
    /// Creates a glowing effect for text or icons
    static func glowingEffect<Content: View>(color: Color = accentBlue, intensity: Double = 1.0, @ViewBuilder content: @escaping () -> Content) -> some View {
        content()
            .shadow(color: color.opacity(0.5 * intensity), radius: 5, x: 0, y: 0)
            .shadow(color: color.opacity(0.3 * intensity), radius: 10, x: 0, y: 0)
    }
    
    /// Creates a subtle animation for UI elements
    static func subtleAnimation<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        content()
            .animation(.easeInOut(duration: 0.3), value: UUID())
    }
    
    // MARK: - Text Styles
    
    /// Heading style with Nordic Electric AI aesthetics
    static func headingStyle(_ text: Text) -> some View {
        text
            .font(.system(.title, design: .rounded))
            .fontWeight(.bold)
            .foregroundColor(textPrimary)
            .shadow(color: accentBlue.opacity(0.5), radius: 2, x: 0, y: 0)
    }
    
    /// Body text style with Nordic Electric AI aesthetics
    static func bodyStyle(_ text: Text) -> some View {
        text
            .font(.system(.body, design: .rounded))
            .foregroundColor(textPrimary)
    }
    
    /// Caption style with Nordic Electric AI aesthetics
    static func captionStyle(_ text: Text) -> some View {
        text
            .font(.system(.caption, design: .rounded))
            .foregroundColor(textSecondary)
    }
    
    // MARK: - Button Styles
    
    /// Primary button style with Nordic Electric AI aesthetics
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(electricGradient)
                        .opacity(configuration.isPressed ? 0.8 : 1.0)
                )
                .foregroundColor(textPrimary)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .shadow(color: accentBlue.opacity(0.3), radius: 5, x: 0, y: 2)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    /// Secondary button style with Nordic Electric AI aesthetics
    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentBlue, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(surface)
                        )
                )
                .foregroundColor(accentBlue)
                .font(.system(.body, design: .rounded).weight(.medium))
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    /// Icon button style with Nordic Electric AI aesthetics
    struct IconButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(12)
                .background(
                    Circle()
                        .fill(surface)
                        .shadow(color: accentBlue.opacity(0.2), radius: 5, x: 0, y: 2)
                )
                .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply Nordic Electric AI theme to a view
    func nordicElectricStyle() -> some View {
        self
            .background(NordicElectricAI.backgroundDeep)
            .foregroundColor(NordicElectricAI.textPrimary)
    }
    
    /// Apply holographic card effect
    func nordicHolographicCard(intensity: Double = 1.0) -> some View {
        NordicElectricAI.holographicCard(intensity: intensity) {
            self
        }
    }
    
    /// Apply glowing effect
    func nordicGlow(color: Color = NordicElectricAI.accentBlue, intensity: Double = 1.0) -> some View {
        NordicElectricAI.glowingEffect(color: color, intensity: intensity) {
            self
        }
    }
}

// MARK: - Text Extensions

extension Text {
    /// Apply Nordic Electric AI heading style
    func nordicHeading() -> some View {
        NordicElectricAI.headingStyle(self)
    }
    
    /// Apply Nordic Electric AI body style
    func nordicBody() -> some View {
        NordicElectricAI.bodyStyle(self)
    }
    
    /// Apply Nordic Electric AI caption style
    func nordicCaption() -> some View {
        NordicElectricAI.captionStyle(self)
    }
}
