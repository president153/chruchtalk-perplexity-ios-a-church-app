//
//  MediaAPI.swift
//  ChurchTalk
//
//  API service for media: sermons, livestreams, featured content.
//

import Foundation

// MARK: - Response Types

/// Media type enum matching backend
enum MediaContentType: String, Codable {
    case sermon
    case livestream
    case video
    case announcement
}

/// Featured media model
struct FeaturedMedia: Decodable, Identifiable {
    let id: String
    let churchId: String
    let title: String
    var description: String?
    var mediaType: MediaContentType
    var thumbnailUrl: String?
    var videoUrl: String?
    var youtubeId: String?
    var isLive: Bool
    var isFeatured: Bool
    var durationSeconds: Int?
    var publishedAt: Date
    var createdAt: Date

    // Custom decoder for flexible API response
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle both _id and id
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else {
            id = try container.decode(String.self, forKey: ._id)
        }

        churchId = try container.decode(String.self, forKey: .churchId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        mediaType = try container.decodeIfPresent(MediaContentType.self, forKey: .mediaType) ?? .video
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        youtubeId = try container.decodeIfPresent(String.self, forKey: .youtubeId)
        isLive = try container.decodeIfPresent(Bool.self, forKey: .isLive) ?? false
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
        publishedAt = try container.decodeIfPresent(Date.self, forKey: .publishedAt) ?? Date()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    private enum CodingKeys: String, CodingKey {
        case id, _id, churchId, title, description, mediaType
        case thumbnailUrl, videoUrl, youtubeId, isLive, isFeatured
        case durationSeconds, publishedAt, createdAt
    }

    /// Formatted duration string (e.g., "45:32")
    var formattedDuration: String? {
        guard let seconds = durationSeconds else { return nil }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    /// YouTube URL if youtubeId is available
    var youtubeURL: URL? {
        guard let youtubeId = youtubeId else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(youtubeId)")
    }

    /// Media URL (video URL or YouTube URL)
    var mediaURL: URL? {
        if let videoUrl = videoUrl, let url = URL(string: videoUrl) {
            return url
        }
        return youtubeURL
    }
}

// MARK: - MediaAPI

/// API service for media operations
class MediaAPI {

    // MARK: - Singleton

    static let shared = MediaAPI()

    // MARK: - Dependencies

    private let client = APIClient.shared

    // MARK: - Init

    private init() {}

    // MARK: - Get Featured Media

    /// Get the featured/live media for the church
    /// - Returns: Featured media item or nil if none exists
    func getFeaturedMedia() async throws -> FeaturedMedia? {
        return try await client.get("/media/featured")
    }

    // MARK: - Get All Media

    /// Get list of media items for the church
    /// - Parameters:
    ///   - mediaType: Filter by media type (optional)
    ///   - skip: Number of records to skip (pagination)
    ///   - limit: Maximum records to return
    /// - Returns: Array of media items
    func getMedia(
        mediaType: MediaContentType? = nil,
        skip: Int = 0,
        limit: Int = 50
    ) async throws -> [FeaturedMedia] {
        var endpoint = "/media?skip=\(skip)&limit=\(limit)"
        if let mediaType = mediaType {
            endpoint += "&media_type=\(mediaType.rawValue)"
        }
        return try await client.get(endpoint)
    }

    // MARK: - Get Media by ID

    /// Get a specific media item by ID
    /// - Parameter id: Media ID
    /// - Returns: Media item
    func getMedia(id: String) async throws -> FeaturedMedia {
        return try await client.get("/media/\(id)")
    }
}
