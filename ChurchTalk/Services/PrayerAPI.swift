//
//  PrayerAPI.swift
//  ChurchTalk
//
//  API service for prayer-related endpoints.
//

import Foundation

// MARK: - Response Types

/// Response wrapper for prayers list
struct PrayersListResponse: Codable {
    let prayers: [PrayerResponse]
    let total: Int
}

/// Response for a single prayer from API
struct PrayerResponse: Codable {
    let id: String
    let churchId: String
    let content: String
    let authorId: String
    let authorName: String?
    let isAnonymous: Bool
    let prayerCount: Int
    let hasPrayed: Bool
    let status: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case churchId, content, authorId, authorName, isAnonymous
        case prayerCount, hasPrayed, status, createdAt, updatedAt
    }

    /// Convert API response to PrayerRequest model
    func toPrayerRequest() -> PrayerRequest {
        let created = parseDate(createdAt) ?? Date()

        return PrayerRequest(
            id: id,
            content: content,
            authorId: authorId,
            authorName: authorName,
            isAnonymous: isAnonymous,
            prayerCount: prayerCount,
            createdAt: created,
            hasPrayed: hasPrayed,
            status: PrayerRequestStatus(rawValue: status) ?? .pending
        )
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")

        // Try with 6 fractional second digits
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let date = formatter.date(from: string) { return date }

        // Try with 3 fractional second digits
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let date = formatter.date(from: string) { return date }

        // Try without fractional seconds
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: string)
    }
}

/// Request body for creating a prayer
struct PrayerCreateRequest: Codable {
    let content: String
    let isAnonymous: Bool
}

/// Response for praying for someone
/// Note: Fields are optional because API returns different formats:
/// - Success: {"prayerCount": N, "hasPrayed": true}
/// - Already prayed: {"message": "Already prayed for this request"}
struct PrayResponse: Codable {
    let prayerCount: Int?
    let hasPrayed: Bool?
    let message: String?
}

// MARK: - PrayerAPI

/// API service for prayer operations
class PrayerAPI {

    // MARK: - Singleton

    static let shared = PrayerAPI()

    // MARK: - Dependencies

    private let client = APIClient.shared

    // MARK: - Init

    private init() {}

    // MARK: - Prayers

    /// Get all approved prayer requests
    /// - Parameters:
    ///   - skip: Number of records to skip
    ///   - limit: Maximum records to return
    /// - Returns: Array of PrayerRequest
    func getPrayers(
        skip: Int = 0,
        limit: Int = 20
    ) async throws -> [PrayerRequest] {
        let response: PrayersListResponse = try await client.get(
            "/prayers?skip=\(skip)&limit=\(limit)"
        )
        return response.prayers.map { $0.toPrayerRequest() }
    }

    /// Get current user's prayer requests
    /// - Returns: Array of PrayerRequest
    func getMyPrayers() async throws -> [PrayerRequest] {
        let response: PrayersListResponse = try await client.get("/prayers/mine")
        return response.prayers.map { $0.toPrayerRequest() }
    }

    /// Create a new prayer request
    /// - Parameters:
    ///   - content: Prayer request text
    ///   - isAnonymous: Whether to post anonymously
    /// - Returns: Created PrayerRequest
    func createPrayer(content: String, isAnonymous: Bool) async throws -> PrayerRequest {
        let request = PrayerCreateRequest(content: content, isAnonymous: isAnonymous)
        let response: PrayerResponse = try await client.post("/prayers", body: request)
        return response.toPrayerRequest()
    }

    /// Pray for a prayer request (increment prayer count)
    /// - Parameter prayerId: The prayer request ID
    /// - Returns: Updated prayer count and status
    func prayFor(prayerId: String) async throws -> PrayResponse {
        return try await client.post("/prayers/\(prayerId)/pray")
    }

    /// Delete a prayer request (own prayers only)
    /// - Parameter prayerId: The prayer request ID
    func deletePrayer(prayerId: String) async throws {
        try await client.delete("/prayers/\(prayerId)")
    }

    // MARK: - Admin Functions

    /// Get pending prayer requests (admin only)
    /// - Returns: Array of PrayerRequest pending approval
    func getPendingPrayers() async throws -> [PrayerRequest] {
        let response: PrayersListResponse = try await client.get("/prayers/pending")
        return response.prayers.map { $0.toPrayerRequest() }
    }

    /// Approve a prayer request (admin only)
    /// - Parameter prayerId: The prayer request ID
    func approvePrayer(prayerId: String) async throws {
        try await client.postVoid("/prayers/\(prayerId)/approve", body: EmptyBody())
    }

    /// Reject a prayer request (admin only)
    /// - Parameter prayerId: The prayer request ID
    func rejectPrayer(prayerId: String) async throws {
        try await client.postVoid("/prayers/\(prayerId)/reject", body: EmptyBody())
    }
}

// Helper for empty POST body
private struct EmptyBody: Codable {}
