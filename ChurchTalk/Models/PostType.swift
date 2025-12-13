//
//  PostType.swift
//  ChurchTalkAdmin
//
//  Post types for bulletin feed
//

import Foundation
import SwiftUI

enum PostType: String, Codable, CaseIterable, Identifiable {
    case announcement
    case prayer
    case testimony
    case devotional
    case praise
    case dailyReading
    case eventHighlight

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .announcement:
            return "megaphone.fill"
        case .prayer:
            return "hands.sparkles.fill"
        case .testimony:
            return "star.fill"
        case .devotional:
            return "book.fill"
        case .praise:
            return "heart.circle.fill"
        case .dailyReading:
            return "calendar.badge.plus"
        case .eventHighlight:
            return "calendar"
        }
    }

    var displayName: String {
        switch self {
        case .announcement:
            return "Announcement"
        case .prayer:
            return "Prayer Request"
        case .testimony:
            return "Testimony"
        case .devotional:
            return "Devotional"
        case .praise:
            return "Praise Report"
        case .dailyReading:
            return "Daily Reading"
        case .eventHighlight:
            return "Event"
        }
    }

    var color: Color {
        switch self {
        case .announcement:
            return Color(red: 0.23, green: 0.51, blue: 0.96) // Blue
        case .prayer:
            return Color(red: 0.55, green: 0.36, blue: 0.96) // Purple
        case .testimony:
            return Color(red: 0.96, green: 0.62, blue: 0.05) // Gold
        case .devotional:
            return Color(red: 0.06, green: 0.72, blue: 0.51) // Green
        case .praise:
            return Color(red: 0.93, green: 0.29, blue: 0.60) // Pink
        case .dailyReading:
            return Color(red: 0.08, green: 0.72, blue: 0.65) // Teal
        case .eventHighlight:
            return Color(red: 0.98, green: 0.45, blue: 0.09) // Orange
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
