//
//  BulletinAPI.swift
//  ChurchTalk
//
//  API service for bulletin/post-related endpoints.
//

import Foundation

// MARK: - Response Types

/// Response for a single bulletin post from API
struct BulletinPostResponse: Codable {
    let id: String
    let churchId: String
    let title: String
    let content: String
    let postType: String
    let authorId: String
    let authorName: String?
    let authorAvatar: String?
    let mediaUrls: [String]
    let youtubeUrl: String?
    let bibleReferences: [String]
    let reactions: ReactionsResponse
    let userReactions: [String]
    let commentCount: Int
    let isPublished: Bool
    let isPinned: Bool
    let publishedAt: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case churchId, title, content, postType, authorId, authorName, authorAvatar
        case mediaUrls, youtubeUrl, bibleReferences, reactions, userReactions
        case commentCount, isPublished, isPinned, publishedAt, createdAt, updatedAt
    }

    /// Convert API response to BulletinPost model
    func toBulletinPost() -> BulletinPost {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let published = dateFormatter.date(from: publishedAt) ?? Date()

        // Create a placeholder author member
        let authorMember = Member(
            id: authorId,
            firstName: authorName?.split(separator: " ").first.map(String.init) ?? "Unknown",
            lastName: authorName?.split(separator: " ").dropFirst().joined(separator: " ") ?? "",
            email: "",
            churchId: churchId
        )

        return BulletinPost(
            id: id,
            title: title,
            content: content,
            author: authorMember,
            mediaUrls: mediaUrls,
            youtubeUrl: youtubeUrl,
            publishedAt: published,
            reactions: Reactions(
                like: reactions.like,
                pray: reactions.pray,
                amen: reactions.amen
            ),
            commentCount: commentCount
        )
    }
}

struct ReactionsResponse: Codable {
    let like: Int
    let pray: Int
    let amen: Int
}

/// Comment response from API
struct CommentResponse: Codable {
    let id: String
    let postId: String
    let authorId: String
    let authorName: String?
    let authorAvatar: String?
    let content: String
    let parentId: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case postId, authorId, authorName, authorAvatar, content, parentId, createdAt, updatedAt
    }

    /// Convert API response to Comment model
    func toComment() -> Comment {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let created = dateFormatter.date(from: createdAt) ?? Date()

        let authorMember = Member(
            id: authorId,
            firstName: authorName?.split(separator: " ").first.map(String.init) ?? "Unknown",
            lastName: authorName?.split(separator: " ").dropFirst().joined(separator: " ") ?? "",
            email: "",
            churchId: ""
        )

        return Comment(
            id: id,
            content: content,
            author: authorMember,
            createdAt: created,
            postId: postId
        )
    }
}

/// Reaction toggle response
struct ReactionToggleResponse: Codable {
    let added: Bool
    let reactions: ReactionsResponse
}

// MARK: - Request Types

/// Request body for creating a post
struct PostCreateRequest: Codable {
    let title: String
    let content: String
    var postType: String = "announcement"
    var mediaUrls: [String] = []
    var youtubeUrl: String?
    var bibleReferences: [String] = []
}

/// Request body for creating a comment
struct CommentCreateRequest: Codable {
    let content: String
    var parentId: String?
}

/// Request body for toggling a reaction
struct ReactionRequest: Codable {
    let reactionType: String

    enum CodingKeys: String, CodingKey {
        case reactionType = "reaction_type"
    }
}

// MARK: - BulletinAPI

/// API service for bulletin operations
class BulletinAPI {

    // MARK: - Singleton

    static let shared = BulletinAPI()

    // MARK: - Dependencies

    private let client = APIClient.shared

    // MARK: - Init

    private init() {}

    // MARK: - Posts

    /// Get bulletin posts for the church
    /// - Parameters:
    ///   - postType: Optional filter by post type
    ///   - skip: Number of records to skip
    ///   - limit: Maximum records to return
    /// - Returns: Array of BulletinPost
    func getPosts(
        postType: String? = nil,
        skip: Int = 0,
        limit: Int = 20
    ) async throws -> [BulletinPost] {
        var endpoint = "/bulletin?skip=\(skip)&limit=\(limit)"
        if let type = postType {
            endpoint += "&post_type=\(type)"
        }

        let responses: [BulletinPostResponse] = try await client.get(endpoint)
        return responses.map { $0.toBulletinPost() }
    }

    /// Get a single post by ID
    /// - Parameter postId: The post ID
    /// - Returns: BulletinPost
    func getPost(id postId: String) async throws -> BulletinPost {
        let response: BulletinPostResponse = try await client.get("/bulletin/\(postId)")
        return response.toBulletinPost()
    }

    /// Create a new bulletin post
    /// - Parameter request: Post creation data
    /// - Returns: Created BulletinPost
    func createPost(_ request: PostCreateRequest) async throws -> BulletinPost {
        let response: BulletinPostResponse = try await client.post("/bulletin", body: request)
        return response.toBulletinPost()
    }

    /// Toggle a reaction on a post
    /// - Parameters:
    ///   - postId: The post ID
    ///   - reactionType: Type of reaction (like, pray, amen)
    /// - Returns: ReactionToggleResponse with updated counts
    func toggleReaction(
        postId: String,
        reactionType: ReactionType
    ) async throws -> ReactionToggleResponse {
        let request = ReactionRequest(reactionType: reactionType.rawValue)
        return try await client.post("/bulletin/\(postId)/react", body: request)
    }

    // MARK: - Comments

    /// Get comments for a post
    /// - Parameters:
    ///   - postId: The post ID
    ///   - skip: Number of records to skip
    ///   - limit: Maximum records to return
    /// - Returns: Array of Comment
    func getComments(
        postId: String,
        skip: Int = 0,
        limit: Int = 50
    ) async throws -> [Comment] {
        let responses: [CommentResponse] = try await client.get(
            "/bulletin/\(postId)/comments?skip=\(skip)&limit=\(limit)"
        )
        return responses.map { $0.toComment() }
    }

    /// Create a comment on a post
    /// - Parameters:
    ///   - postId: The post ID
    ///   - content: Comment text
    ///   - parentId: Optional parent comment ID for replies
    /// - Returns: Created Comment
    func createComment(
        postId: String,
        content: String,
        parentId: String? = nil
    ) async throws -> Comment {
        let request = CommentCreateRequest(content: content, parentId: parentId)
        let response: CommentResponse = try await client.post(
            "/bulletin/\(postId)/comments",
            body: request
        )
        return response.toComment()
    }
}
