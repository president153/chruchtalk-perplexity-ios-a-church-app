//
//  WeeklyFocusAPI.swift
//  ChurchTalk
//
//  API service for the "Never Miss What Matters" weekly focus feature.
//

import Foundation

/// API service for weekly focus operations
class WeeklyFocusAPI {

    // MARK: - Singleton

    static let shared = WeeklyFocusAPI()
    private init() {}

    // MARK: - Member Endpoints

    /// Get the current week's published focus for the member
    func getCurrentFocus() async throws -> WeeklyFocus {
        return try await APIClient.shared.get("/api/v1/weekly-focus/current")
    }

    /// Commit to a weekly focus action
    func commit(
        weeklyFocusId: String,
        category: WeeklyFocusCategory,
        visibleToLeaders: Bool = true,
        reminderEnabled: Bool = true
    ) async throws -> MemberCommitment {
        let request = CommitmentCreateRequest(
            weeklyFocusId: weeklyFocusId,
            focusItemCategory: category.rawValue,
            visibleToLeaders: visibleToLeaders,
            reminderEnabled: reminderEnabled
        )
        return try await APIClient.shared.post("/api/v1/weekly-focus/commit", body: request)
    }

    /// Get member's commitments for the current week
    func getMyCommitments() async throws -> [MemberCommitment] {
        return try await APIClient.shared.get("/api/v1/weekly-focus/my-commitments")
    }

    /// Mark a commitment as fulfilled
    func fulfillCommitment(commitmentId: String) async throws -> MemberCommitment {
        return try await APIClient.shared.post("/api/v1/weekly-focus/commitments/\(commitmentId)/fulfill")
    }

    /// Cancel a commitment
    func cancelCommitment(commitmentId: String, reason: String? = nil) async throws -> MemberCommitment {
        let request = CommitmentCancelRequest(cancelReason: reason)
        return try await APIClient.shared.post("/api/v1/weekly-focus/commitments/\(commitmentId)/cancel", body: request)
    }
}
