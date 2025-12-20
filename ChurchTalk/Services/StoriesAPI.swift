//
//  StoriesAPI.swift
//  ChurchTalk
//
//  API service for stories endpoints (24-hour ephemeral content).
//

import Foundation

// MARK: - Request Types

/// Request body for creating a story
struct CreateStoryRequest: Codable {
    let mediaType: String
    let mediaUrl: String
    let thumbnailUrl: String?
    let duration: Int?
}

// MARK: - StoriesAPI

/// API service for stories operations
class StoriesAPI {

    // MARK: - Singleton

    static let shared = StoriesAPI()

    // MARK: - Dependencies

    private let client = APIClient.shared

    // MARK: - Init

    private init() {}

    // MARK: - Get Stories

    /// Get active stories for the church
    /// - Parameters:
    ///   - skip: Number of items to skip (pagination)
    ///   - limit: Max items to return (default 50)
    /// - Returns: Array of stories
    func getStories(skip: Int = 0, limit: Int = 50) async throws -> [Story] {
        return try await client.get("/stories?skip=\(skip)&limit=\(limit)")
    }

    /// Get stories grouped by user (for story ring display)
    /// - Returns: Array of story groups
    func getStoriesGrouped() async throws -> [StoryGroup] {
        return try await client.get("/stories/grouped")
    }

    /// Get stories by a specific user
    /// - Parameter userId: The user ID
    /// - Returns: Array of stories
    func getUserStories(userId: String) async throws -> [Story] {
        return try await client.get("/stories/user/\(userId)")
    }

    /// Get current user's stories
    /// - Parameter includeExpired: Whether to include expired stories
    /// - Returns: Array of stories
    func getMyStories(includeExpired: Bool = false) async throws -> [Story] {
        return try await client.get("/stories/me?include_expired=\(includeExpired)")
    }

    // MARK: - Get Single Story

    /// Get story by ID
    /// - Parameter id: Story ID
    /// - Returns: Story details
    func getStory(id: String) async throws -> Story {
        return try await client.get("/stories/\(id)")
    }

    // MARK: - Create Story

    /// Create a new story
    /// - Parameters:
    ///   - mediaType: Type of media (image or video)
    ///   - mediaUrl: URL of the uploaded media
    ///   - thumbnailUrl: Optional thumbnail URL (for videos)
    ///   - duration: Optional duration in seconds (for videos)
    /// - Returns: Created story
    func createStory(
        mediaType: Story.MediaType,
        mediaUrl: String,
        thumbnailUrl: String? = nil,
        duration: Int? = nil
    ) async throws -> Story {
        let request = CreateStoryRequest(
            mediaType: mediaType.rawValue,
            mediaUrl: mediaUrl,
            thumbnailUrl: thumbnailUrl,
            duration: duration
        )
        return try await client.post("/stories", body: request)
    }

    // MARK: - View Story

    /// Mark story as viewed
    /// - Parameter id: Story ID
    func viewStory(id: String) async throws {
        try await client.postVoid("/stories/\(id)/view", body: EmptyBody())
    }

    // MARK: - Get Viewers

    /// Get list of members who viewed a story (owner only)
    /// - Parameters:
    ///   - id: Story ID
    ///   - skip: Pagination offset
    ///   - limit: Max results
    /// - Returns: Array of member IDs
    func getStoryViewers(id: String, skip: Int = 0, limit: Int = 50) async throws -> [String] {
        return try await client.get("/stories/\(id)/viewers?skip=\(skip)&limit=\(limit)")
    }

    // MARK: - Delete Story

    /// Delete a story (owner only)
    /// - Parameter id: Story ID
    func deleteStory(id: String) async throws {
        try await client.delete("/stories/\(id)")
    }
}

// Helper for empty POST body
private struct EmptyBody: Codable {}
