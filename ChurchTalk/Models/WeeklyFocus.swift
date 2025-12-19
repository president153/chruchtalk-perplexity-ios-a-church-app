//
//  WeeklyFocus.swift
//  ChurchTalk
//
//  Models for the "Never Miss What Matters" weekly focus feature.
//

import Foundation
import SwiftUI

// MARK: - Enums

enum WeeklyFocusCategory: String, Codable, CaseIterable {
    case serve
    case pray
    case attend
    case reachOut = "reach_out"

    var displayName: String {
        switch self {
        case .serve: return "Serve"
        case .pray: return "Pray"
        case .attend: return "Attend"
        case .reachOut: return "Reach Out"
        }
    }

    var icon: String {
        switch self {
        case .serve: return "hands.sparkles.fill"
        case .pray: return "heart.fill"
        case .attend: return "person.3.fill"
        case .reachOut: return "message.fill"
        }
    }

    var defaultColor: Color {
        switch self {
        case .serve: return Color(hex: "FF6B35")
        case .pray: return Color(hex: "7B2CBF")
        case .attend: return Color(hex: "0077B6")
        case .reachOut: return Color(hex: "2D6A4F")
        }
    }
}

enum CommitmentStatus: String, Codable {
    case committed
    case fulfilled
    case missed
    case cancelled
}

// MARK: - Weekly Focus Models

struct WeeklyFocusItem: Codable, Identifiable {
    var id: String { "\(category.rawValue)-\(priority)" }

    let category: WeeklyFocusCategory
    let title: String
    let description: String
    let actionLabel: String
    let actionType: String
    let entityType: String?
    let entityId: String?
    let entityName: String?
    let icon: String
    let color: String
    let priority: Int
    var hasCommitted: Bool?
    var commitmentId: String?

    var swiftUIColor: Color {
        Color(hex: color)
    }
}

struct WeeklyFocus: Codable, Identifiable {
    let id: String
    let churchId: String
    let weekStart: Date
    let weekEnd: Date
    let status: String
    let items: [WeeklyFocusItem]
    let generatedByAi: Bool
    let pastorNotes: String?
    let approvedBy: String?
    let approvedAt: Date?
    let publishedAt: Date?
    let totalViews: Int
    let totalCommitments: Int
    let commitmentsByCategory: [String: Int]?
    let createdAt: Date
    let updatedAt: Date

    var weekDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: weekStart)
        formatter.dateFormat = "MMM d, yyyy"
        let end = formatter.string(from: weekEnd)
        return "\(start) - \(end)"
    }
}

// MARK: - Commitment Models

struct MemberCommitment: Codable, Identifiable {
    let id: String
    let churchId: String
    let memberId: String
    let weeklyFocusId: String
    let focusItemCategory: WeeklyFocusCategory
    let actionType: String
    let actionLabel: String
    let itemTitle: String
    let entityType: String?
    let entityId: String?
    let entityName: String?
    let committedAt: Date
    let weekStart: Date
    let weekEnd: Date
    let status: CommitmentStatus
    let fulfilledAt: Date?
    let visibleToLeaders: Bool
    let leaderAcknowledged: Bool
    let leaderNote: String?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Request Models

struct CommitmentCreateRequest: Encodable {
    let weeklyFocusId: String
    let focusItemCategory: String
    let visibleToLeaders: Bool
    let reminderEnabled: Bool
}

struct CommitmentCancelRequest: Encodable {
    let cancelReason: String?
}

