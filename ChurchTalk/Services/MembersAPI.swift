//
//  MembersAPI.swift
//  ChurchTalk
//
//  API service for member-related endpoints.
//

import Foundation

// MARK: - Response Types

/// Response wrapper for member list
struct MemberListResponse: Codable {
    let members: [Member]
    let total: Int
}

/// Response wrapper for pending approvals
struct PendingApprovalsResponse: Codable {
    let members: [Member]
    let total: Int
}

/// Generic message response from API
struct MessageResponse: Codable {
    let message: String
}

// MARK: - Request Types

/// Request body for updating a member
struct MemberUpdateRequest: Codable {
    var firstName: String?
    var lastName: String?
    var phone: String?
    var ministries: [String]?
}

/// Request body for updating member role
struct MemberRoleUpdateRequest: Codable {
    let role: String
}

/// Request body for updating spiritual journey
struct SpiritualJourneyUpdateRequest: Codable {
    var currentStage: Int?
    var salvationDate: String?
    var baptismDate: String?
    var membershipDate: String?
    var ministryInterests: [String]?
    var notes: String?
}

// MARK: - MembersAPI

/// API service for member operations
class MembersAPI {

    // MARK: - Singleton

    static let shared = MembersAPI()

    // MARK: - Dependencies

    private let client = APIClient.shared

    // MARK: - Init

    private init() {}

    // MARK: - List Members

    /// Get list of approved church members (directory)
    /// - Parameters:
    ///   - search: Optional search query for name/email
    ///   - skip: Number of records to skip (pagination)
    ///   - limit: Maximum records to return
    /// - Returns: Member list response with total count
    func getMembers(
        search: String? = nil,
        skip: Int = 0,
        limit: Int = 50
    ) async throws -> MemberListResponse {
        var endpoint = "/members?skip=\(skip)&limit=\(limit)"
        if let search = search, !search.isEmpty {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search)"
        }
        return try await client.get(endpoint)
    }

    /// Get list of pending member approvals (admin only)
    /// - Parameters:
    ///   - skip: Number of records to skip
    ///   - limit: Maximum records to return
    /// - Returns: Pending approvals response with total count
    func getPendingMembers(
        skip: Int = 0,
        limit: Int = 50
    ) async throws -> PendingApprovalsResponse {
        return try await client.get("/members/pending?skip=\(skip)&limit=\(limit)")
    }

    // MARK: - Get Member

    /// Get a specific member by ID
    /// - Parameter id: Member ID
    /// - Returns: Member details
    func getMember(id: String) async throws -> Member {
        return try await client.get("/members/\(id)")
    }

    // MARK: - Update Member

    /// Update member profile
    /// - Parameters:
    ///   - id: Member ID
    ///   - request: Update request with fields to modify
    /// - Returns: Updated member
    func updateMember(id: String, request: MemberUpdateRequest) async throws -> Member {
        return try await client.patch("/members/\(id)", body: request)
    }

    // MARK: - Approve/Reject

    /// Approve a pending member (admin only)
    /// - Parameter id: Member ID to approve
    /// - Returns: Approved member
    func approveMember(id: String) async throws -> Member {
        return try await client.post("/members/\(id)/approve")
    }

    /// Reject a pending member (admin only)
    /// - Parameter id: Member ID to reject
    /// - Returns: Message response
    func rejectMember(id: String) async throws -> MessageResponse {
        return try await client.post("/members/\(id)/reject")
    }

    // MARK: - Role Management

    /// Update member role (admin only)
    /// - Parameters:
    ///   - id: Member ID
    ///   - role: New role (admin, leader, member)
    /// - Returns: Updated member
    func updateMemberRole(id: String, role: MemberRole) async throws -> Member {
        let request = MemberRoleUpdateRequest(role: role.rawValue)
        return try await client.patch("/members/\(id)/role", body: request)
    }

    // MARK: - Spiritual Journey

    /// Update member's spiritual journey
    /// - Parameters:
    ///   - id: Member ID
    ///   - request: Spiritual journey update request
    /// - Returns: Updated member
    func updateSpiritualJourney(
        id: String,
        request: SpiritualJourneyUpdateRequest
    ) async throws -> Member {
        return try await client.patch("/members/\(id)/spiritual-journey", body: request)
    }

    // MARK: - Remove Member

    /// Remove a member from the church (admin only)
    /// - Parameter id: Member ID to remove
    /// - Returns: Message response
    func removeMember(id: String) async throws -> MessageResponse {
        return try await client.delete("/members/\(id)")
    }
}
