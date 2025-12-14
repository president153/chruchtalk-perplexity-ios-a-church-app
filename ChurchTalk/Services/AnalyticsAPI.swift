//
//  AnalyticsAPI.swift
//  ChurchTalk
//
//  API service for analytics and engagement tracking endpoints.
//

import Foundation

// MARK: - Enums

/// Source of post view
enum ViewSource: String, Codable {
    case feed
    case notification
    case share
    case search
    case direct
}

/// Device type for analytics
enum DeviceType: String, Codable {
    case ios
    case android
    case web
}

// MARK: - Request Types

/// Request to track a post view
struct TrackViewRequest: Codable {
    let postId: String
    let durationSeconds: Int
    let source: String
    let deviceType: String
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case durationSeconds = "duration_seconds"
        case source
        case deviceType = "device_type"
        case completed
    }
}

/// Request to track a post impression
struct TrackImpressionRequest: Codable {
    let postId: String
    let deviceType: String

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case deviceType = "device_type"
    }
}

/// Request to track a post share
struct TrackShareRequest: Codable {
    let postId: String
    let platform: String?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case platform
    }
}

// MARK: - Analytics API

/// API service for analytics tracking
class AnalyticsAPI {
    static let shared = AnalyticsAPI()

    private init() {}

    // MARK: - View Tracking

    /// Track when a user views a post
    /// - Parameters:
    ///   - postId: ID of the post being viewed
    ///   - durationSeconds: How long the user viewed the post
    ///   - source: Where the user came from (feed, notification, etc.)
    ///   - completed: Whether the user finished reading
    func trackView(
        postId: String,
        durationSeconds: Int,
        source: ViewSource = .feed,
        completed: Bool = false
    ) async throws {
        let request = TrackViewRequest(
            postId: postId,
            durationSeconds: durationSeconds,
            source: source.rawValue,
            deviceType: DeviceType.ios.rawValue,
            completed: completed
        )

        let _: EmptyResponse = try await APIClient.shared.request(
            endpoint: "/analytics/track/view",
            method: .post,
            body: request
        )
    }

    /// Track when a post scrolls into view (impression)
    /// - Parameter postId: ID of the post
    func trackImpression(postId: String) async throws {
        let request = TrackImpressionRequest(
            postId: postId,
            deviceType: DeviceType.ios.rawValue
        )

        let _: EmptyResponse = try await APIClient.shared.request(
            endpoint: "/analytics/track/impression",
            method: .post,
            body: request
        )
    }

    /// Track when a user shares a post
    /// - Parameters:
    ///   - postId: ID of the post being shared
    ///   - platform: Platform shared to (sms, email, copy_link, etc.)
    func trackShare(postId: String, platform: String? = nil) async throws {
        let request = TrackShareRequest(
            postId: postId,
            platform: platform
        )

        let _: EmptyResponse = try await APIClient.shared.request(
            endpoint: "/analytics/track/share",
            method: .post,
            body: request
        )
    }
}

// MARK: - Empty Response

/// Used for endpoints that don't return data
private struct EmptyResponse: Codable {}

// MARK: - Post View Tracker

/// Helper class to track view duration for a post
class PostViewTracker {
    private let postId: String
    private let source: ViewSource
    private var startTime: Date?
    private var isTracked: Bool = false

    init(postId: String, source: ViewSource = .feed) {
        self.postId = postId
        self.source = source
    }

    /// Call when the post appears on screen
    func startTracking() {
        startTime = Date()
        isTracked = false
    }

    /// Call when the post disappears from screen
    /// Will automatically track the view with duration
    func stopTracking(completed: Bool = false) {
        guard let start = startTime, !isTracked else { return }
        isTracked = true

        let duration = Int(Date().timeIntervalSince(start))

        // Only track if viewed for at least 1 second
        guard duration >= 1 else { return }

        Task {
            do {
                try await AnalyticsAPI.shared.trackView(
                    postId: postId,
                    durationSeconds: duration,
                    source: source,
                    completed: completed
                )
            } catch {
                print("Failed to track view: \(error)")
            }
        }
    }
}

// MARK: - Impression Tracker

/// Helper class to track impressions as posts scroll into view
class ImpressionTracker {
    private var trackedPostIds: Set<String> = []

    /// Track an impression if not already tracked
    /// - Parameter postId: ID of the post
    func trackIfNeeded(postId: String) {
        // Only track once per session
        guard !trackedPostIds.contains(postId) else { return }
        trackedPostIds.insert(postId)

        Task {
            do {
                try await AnalyticsAPI.shared.trackImpression(postId: postId)
            } catch {
                print("Failed to track impression: \(error)")
            }
        }
    }

    /// Reset tracked impressions (call on feed refresh)
    func reset() {
        trackedPostIds.removeAll()
    }
}
