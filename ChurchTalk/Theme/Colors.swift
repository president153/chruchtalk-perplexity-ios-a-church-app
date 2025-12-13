import SwiftUI

// MARK: - ChurchTalk Brand Colors

extension Color {
    // Primary Brand Colors
    static let churchTalkRed = Color(hex: "D02220")
    static let churchTalkRedLight = Color(hex: "E57373")
    static let churchTalkRedDark = Color(hex: "B01E1C")
    static let churchPrimary = Color(hex: "D02220")  // Alias for consistency
    static let churchDark = Color(hex: "B01E1C")

    // Secondary Colors
    static let prayerPurple = Color(hex: "7B1FA2")
    static let outreachGreen = Color(hex: "388E3C")
    static let directoryBlue = Color(hex: "1976D2")

    // Reaction Colors
    static let heartRed = Color(hex: "E53935")
    static let amenGreen = Color(hex: "4CAF50")

    // Spiritual Journey Stage Colors
    static let stageInitialContact = Color(hex: "9E9E9E")
    static let stageGospel = Color(hex: "FF9800")
    static let stageSaved = Color(hex: "E91E63")
    static let stageBaptized = Color(hex: "2196F3")
    static let stageMembership = Color(hex: "4CAF50")
    static let stageDiscipleship = Color(hex: "9C27B0")
    static let stageReadyToServe = Color(hex: "FF5722")
    static let stageServing = Color(hex: "D32F2F")

    // MARK: - Light Mode Colors
    static let lightBackground = Color.white
    static let lightSecondaryBackground = Color(hex: "F3F4F6")
    static let lightCardBackground = Color.white
    static let lightText = Color(hex: "171717")
    static let lightSecondaryText = Color(hex: "6B7280")
    static let lightTertiaryText = Color(hex: "9CA3AF")
    static let lightBorder = Color(hex: "E5E7EB")

    // MARK: - Dark Mode Colors
    static let darkBackground = Color(hex: "0F172A")
    static let darkSecondaryBackground = Color(hex: "1E293B")
    static let darkCardBackground = Color(hex: "1E293B").opacity(0.95)
    static let darkText = Color(hex: "F8FAFC")
    static let darkSecondaryText = Color(hex: "CBD5E1")
    static let darkTertiaryText = Color(hex: "94A3B8")
    static let darkBorder = Color(hex: "334155")

    // MARK: - Adaptive Colors
    static var background: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(darkBackground) : UIColor(lightBackground)
        })
    }

    static var secondaryBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(darkSecondaryBackground) : UIColor(lightSecondaryBackground)
        })
    }

    static var cardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(darkCardBackground) : UIColor(lightCardBackground)
        })
    }

    static var primaryBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(darkSecondaryBackground) : UIColor(lightSecondaryBackground)
        })
    }

    static var primaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(darkText) : UIColor(lightText)
        })
    }

    static var secondaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(darkSecondaryText) : UIColor(lightSecondaryText)
        })
    }

    static var tertiaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(darkTertiaryText) : UIColor(lightTertiaryText)
        })
    }

    static var borderColor: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(darkBorder) : UIColor(lightBorder)
        })
    }

    // MARK: - Module Colors
    static let financeColor = Color(hex: "22C55E")  // Green for giving/finance
    static let srmColor = Color(hex: "EF4444")      // Red for SRM
    static let visionColor = Color(hex: "6366F1")   // Indigo for vision
    static let ministryColor = Color(hex: "EC4899") // Pink for ministry
    static let managementColor = Color(hex: "3B82F6") // Blue for management
    static let engagementColor = Color(hex: "A855F7") // Purple for engagement
    static let leadGenColor = Color(hex: "F97316")  // Orange for lead generation

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Configuration

struct ChurchTalkTheme {
    static let primaryColor = Color.churchTalkRed
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let cardShadowColor = Color.black.opacity(0.08)
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 4

    // Spacing
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24

    // Avatar sizes
    static let avatarSmall: CGFloat = 36
    static let avatarMedium: CGFloat = 44
    static let avatarLarge: CGFloat = 80
}
