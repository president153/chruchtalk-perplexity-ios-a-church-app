//
//  SoulsAPI.swift
//  ChurchTalk
//
//  API service for souls/SRM-related endpoints.
//

import Foundation

// MARK: - Response Types

/// Response wrapper for soul list
struct SoulListResponse: Codable {
    let souls: [Soul]
    let total: Int
}

/// Response wrapper for single soul
struct SoulResponse: Codable {
    let soul: Soul
}

// MARK: - Request Types

/// Request body for creating a soul
struct CreateSoulRequest: Codable {
    let firstName: String
    let lastName: String
    var email: String?
    var phone: String?
    let soulType: String
    var spiritualStage: Int?
    var notes: String?
}

/// Request body for updating a soul
struct UpdateSoulRequest: Codable {
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var soulType: String?
    var spiritualStage: Int?
    var assignedTo: String?
    var notes: String?
    var nextFollowUpDate: String?
    var shareStatus: String?
}

// MARK: - SoulsAPI

/// API service for souls operations
class SoulsAPI {

    // MARK: - Singleton

    static let shared = SoulsAPI()

    // MARK: - Dependencies

    private let client = APIClient.shared

    // MARK: - Init

    private init() {}

    // MARK: - List Souls

    /// Get list of souls based on view type
    /// - Parameters:
    ///   - view: View type - "mine" (default), "shared", or "all"
    ///   - soulType: Optional filter by soul type
    ///   - shareStatus: Optional filter by share status
    ///   - skip: Number of records to skip (pagination)
    ///   - limit: Maximum records to return
    /// - Returns: Array of souls
    func getSouls(
        view: String = "mine",
        soulType: String? = nil,
        shareStatus: String? = nil,
        skip: Int = 0,
        limit: Int = 50
    ) async throws -> [Soul] {
        var endpoint = "/souls?view=\(view)&skip=\(skip)&limit=\(limit)"
        if let type = soulType {
            endpoint += "&soul_type=\(type)"
        }
        if let status = shareStatus {
            endpoint += "&share_status=\(status)"
        }
        return try await client.get(endpoint)
    }

    // MARK: - Get Soul

    /// Get a specific soul by ID
    /// - Parameter id: Soul ID
    /// - Returns: Soul details
    func getSoul(id: String) async throws -> Soul {
        return try await client.get("/souls/\(id)")
    }

    // MARK: - Create Soul

    /// Create a new soul
    /// - Parameter request: Soul creation request
    /// - Returns: Created soul
    func createSoul(request: CreateSoulRequest) async throws -> Soul {
        return try await client.post("/souls", body: request)
    }

    // MARK: - Update Soul

    /// Update an existing soul
    /// - Parameters:
    ///   - id: Soul ID
    ///   - request: Update request
    /// - Returns: Updated soul
    func updateSoul(id: String, request: UpdateSoulRequest) async throws -> Soul {
        return try await client.patch("/souls/\(id)", body: request)
    }

    // MARK: - Delete Soul

    /// Delete a soul
    /// - Parameter id: Soul ID to delete
    func deleteSoul(id: String) async throws {
        try await client.delete("/souls/\(id)")
    }

    // MARK: - Share Soul

    /// Submit a soul for review to share with the church
    /// - Parameter id: Soul ID
    /// - Returns: Updated soul with pending status
    func submitForReview(id: String) async throws -> Soul {
        return try await client.post("/souls/\(id)/submit-for-review")
    }

    /// Approve a soul for sharing (admin only)
    /// - Parameter id: Soul ID
    /// - Returns: Updated soul with shared status
    func approveSoul(id: String) async throws -> Soul {
        return try await client.post("/souls/\(id)/approve")
    }

    /// Reject a soul from sharing (admin only)
    /// - Parameters:
    ///   - id: Soul ID
    ///   - reason: Rejection reason
    /// - Returns: Updated soul with rejected status
    func rejectSoul(id: String, reason: String?) async throws -> Soul {
        struct RejectRequest: Codable {
            let reason: String?
        }
        return try await client.post("/souls/\(id)/reject", body: RejectRequest(reason: reason))
    }

    // MARK: - Add Follow-up

    /// Add a follow-up record to a soul
    /// - Parameters:
    ///   - soulId: Soul ID
    ///   - contactMethod: How contact was made
    ///   - notes: Follow-up notes
    ///   - outcome: Outcome of follow-up
    /// - Returns: Updated soul
    func addFollowUp(
        soulId: String,
        contactMethod: String,
        notes: String,
        outcome: String
    ) async throws -> Soul {
        struct FollowUpRequest: Codable {
            let contactMethod: String
            let notes: String
            let outcome: String
        }
        let request = FollowUpRequest(contactMethod: contactMethod, notes: notes, outcome: outcome)
        return try await client.post("/souls/\(soulId)/follow-ups", body: request)
    }
}
