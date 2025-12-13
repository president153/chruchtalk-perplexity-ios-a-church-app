//
//  Story.swift
//  ChurchTalkAdmin
//
//  Story model for bulletin stories feature
//

import Foundation

struct Story: Codable, Identifiable {
    let id: String
    let churchId: String
    let userId: String
    let mediaType: MediaType
    let mediaUrl: String
    let thumbnailUrl: String?
    let duration: Int? // For videos
    let createdAt: Int
    let expiresAt: Int
    let viewCount: Int
    let views: [String] // Array of user IDs who viewed

    // Author info
    let authorName: String
    let authorPhotoUrl: String?

    enum MediaType: String, Codable {
        case image
        case video
    }

    enum CodingKeys: String, CodingKey {
        case id
        case churchId = "church_id"
        case userId = "user_id"
        case mediaType = "media_type"
        case mediaUrl = "media_url"
        case thumbnailUrl = "thumbnail_url"
        case duration
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case viewCount = "view_count"
        case views
        case authorName = "author_name"
        case authorPhotoUrl = "author_photo_url"
    }

    // Check if story has been viewed by current user
    func isViewed(by userId: String) -> Bool {
        views.contains(userId)
    }

    // Check if story is still active
    var isActive: Bool {
        let now = Int(Date().timeIntervalSince1970 * 1000)
        return now < expiresAt
    }

    // Time remaining until expiration
    var timeRemaining: String {
        let now = Date()
        let expiryDate = Date(timeIntervalSince1970: TimeInterval(expiresAt) / 1000.0)
        let components = Calendar.current.dateComponents([.day, .hour], from: now, to: expiryDate)

        if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else {
            return "Expiring soon"
        }
    }
}

// MARK: - Mock Data Extension
extension Story {
    static func mockStories() -> [Story] {
        let oneHourAgo = Int((Date().addingTimeInterval(-1 * 3600)).timeIntervalSince1970 * 1000)
        let fiveHoursAgo = Int((Date().addingTimeInterval(-5 * 3600)).timeIntervalSince1970 * 1000)
        let oneDayAgo = Int((Date().addingTimeInterval(-24 * 3600)).timeIntervalSince1970 * 1000)
        let twoDaysAgo = Int((Date().addingTimeInterval(-48 * 3600)).timeIntervalSince1970 * 1000)

        return [
            Story(
                id: "s1",
                churchId: "church1",
                userId: "admin1",
                mediaType: .image,
                mediaUrl: "https://images.unsplash.com/photo-1544427920-c49ccfb85579?w=800",
                thumbnailUrl: nil,
                duration: nil,
                createdAt: oneHourAgo,
                expiresAt: oneHourAgo + (7 * 24 * 3600 * 1000),
                viewCount: 45,
                views: [],
                authorName: "Pastor John",
                authorPhotoUrl: "https://i.pravatar.cc/150?img=12"
            ),

            Story(
                id: "s2",
                churchId: "church1",
                userId: "admin2",
                mediaType: .image,
                mediaUrl: "https://images.unsplash.com/photo-1502757963558-231c0e82e8e8?w=800",
                thumbnailUrl: nil,
                duration: nil,
                createdAt: fiveHoursAgo,
                expiresAt: fiveHoursAgo + (7 * 24 * 3600 * 1000),
                viewCount: 67,
                views: [],
                authorName: "Elder Sarah",
                authorPhotoUrl: "https://i.pravatar.cc/150?img=45"
            ),

            Story(
                id: "s3",
                churchId: "church1",
                userId: "admin3",
                mediaType: .image,
                mediaUrl: "https://images.unsplash.com/photo-1507692049790-de58290a4334?w=800",
                thumbnailUrl: nil,
                duration: nil,
                createdAt: oneDayAgo,
                expiresAt: oneDayAgo + (7 * 24 * 3600 * 1000),
                viewCount: 123,
                views: [],
                authorName: "Worship Team",
                authorPhotoUrl: "https://i.pravatar.cc/150?img=25"
            ),

            Story(
                id: "s4",
                churchId: "church1",
                userId: "admin4",
                mediaType: .image,
                mediaUrl: "https://images.unsplash.com/photo-1438232992991-995b7058bbb3?w=800",
                thumbnailUrl: nil,
                duration: nil,
                createdAt: twoDaysAgo,
                expiresAt: twoDaysAgo + (7 * 24 * 3600 * 1000),
                viewCount: 89,
                views: ["user1", "user2"], // Mark as viewed for demo
                authorName: "Youth Ministry",
                authorPhotoUrl: "https://i.pravatar.cc/150?img=67"
            )
        ]
    }
}
