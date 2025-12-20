//
//  Story.swift
//  ChurchTalk
//
//  Story model for bulletin stories feature (24-hour ephemeral content)
//

import Foundation

struct Story: Codable, Identifiable {
    let id: String
    let churchId: String
    let userId: String
    let mediaType: MediaType
    let mediaUrl: String
    let thumbnailUrl: String?
    let duration: Int? // For videos, in seconds
    let viewCount: Int
    let hasViewed: Bool // Whether current user has viewed
    let authorName: String
    let authorPhotoUrl: String?
    let expiresAt: Date
    let createdAt: Date

    enum MediaType: String, Codable {
        case image
        case video
    }

    // Check if story is still active (not expired)
    var isActive: Bool {
        Date() < expiresAt
    }

    // Time remaining until expiration
    var timeRemaining: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.hour, .minute], from: now, to: expiresAt)

        if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Expiring"
        }
    }
}

/// Response for grouped stories (for story ring display)
struct StoryGroup: Codable, Identifiable {
    var id: String { userId }
    let userId: String
    let authorName: String
    let authorPhotoUrl: String?
    let stories: [Story]
    let hasUnseen: Bool
}

// MARK: - Preview Data Extension
#if DEBUG
extension Story {
    /// Mock stories for SwiftUI previews only
    static func mockStories() -> [Story] {
        [
            Story(
                id: "s1",
                churchId: "church1",
                userId: "admin1",
                mediaType: .image,
                mediaUrl: "https://images.unsplash.com/photo-1544427920-c49ccfb85579?w=800",
                thumbnailUrl: nil,
                duration: nil,
                viewCount: 45,
                hasViewed: false,
                authorName: "Pastor John",
                authorPhotoUrl: "https://i.pravatar.cc/150?img=12",
                expiresAt: Date().addingTimeInterval(20 * 3600),
                createdAt: Date().addingTimeInterval(-4 * 3600)
            ),
            Story(
                id: "s2",
                churchId: "church1",
                userId: "admin2",
                mediaType: .image,
                mediaUrl: "https://images.unsplash.com/photo-1502757963558-231c0e82e8e8?w=800",
                thumbnailUrl: nil,
                duration: nil,
                viewCount: 67,
                hasViewed: false,
                authorName: "Elder Sarah",
                authorPhotoUrl: "https://i.pravatar.cc/150?img=45",
                expiresAt: Date().addingTimeInterval(18 * 3600),
                createdAt: Date().addingTimeInterval(-6 * 3600)
            ),
            Story(
                id: "s3",
                churchId: "church1",
                userId: "admin3",
                mediaType: .image,
                mediaUrl: "https://images.unsplash.com/photo-1507692049790-de58290a4334?w=800",
                thumbnailUrl: nil,
                duration: nil,
                viewCount: 123,
                hasViewed: true,
                authorName: "Worship Team",
                authorPhotoUrl: "https://i.pravatar.cc/150?img=25",
                expiresAt: Date().addingTimeInterval(12 * 3600),
                createdAt: Date().addingTimeInterval(-12 * 3600)
            )
        ]
    }
}
#endif
