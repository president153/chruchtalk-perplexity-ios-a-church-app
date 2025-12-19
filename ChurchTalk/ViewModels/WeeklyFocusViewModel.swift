//
//  WeeklyFocusViewModel.swift
//  ChurchTalk
//
//  ViewModel for the "Never Miss What Matters" weekly focus feature.
//

import Foundation
import SwiftUI

@MainActor
class WeeklyFocusViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var weeklyFocus: WeeklyFocus?
    @Published var commitments: [MemberCommitment] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showCommitmentSuccess = false
    @Published var lastCommittedCategory: WeeklyFocusCategory?

    // MARK: - Computed Properties

    var hasCommitments: Bool {
        !commitments.isEmpty
    }

    var fulfillmentProgress: Double {
        guard !commitments.isEmpty else { return 0 }
        let fulfilled = commitments.filter { $0.status == .fulfilled }.count
        return Double(fulfilled) / Double(commitments.count)
    }

    // MARK: - Methods

    /// Fetch the current week's focus and member's commitments
    func fetchData() async {
        isLoading = true
        error = nil

        // Fetch both in parallel
        async let focusTask = WeeklyFocusAPI.shared.getCurrentFocus()
        async let commitmentsTask = WeeklyFocusAPI.shared.getMyCommitments()

        do {
            weeklyFocus = try await focusTask
        } catch {
            print("Failed to fetch weekly focus: \(error)")
            self.error = "Unable to load weekly focus"
        }

        do {
            commitments = try await commitmentsTask
            // Update hasCommitted status on focus items
            updateCommitmentStatus()
        } catch {
            print("Failed to fetch commitments: \(error)")
        }

        isLoading = false
    }

    /// Commit to a focus item
    func commit(to item: WeeklyFocusItem, visibleToLeaders: Bool = true) async {
        guard let focus = weeklyFocus else { return }

        do {
            let commitment = try await WeeklyFocusAPI.shared.commit(
                weeklyFocusId: focus.id,
                category: item.category,
                visibleToLeaders: visibleToLeaders
            )

            // Add to local list
            commitments.append(commitment)

            // Update the focus item status
            updateCommitmentStatus()

            // Show success feedback
            lastCommittedCategory = item.category
            showCommitmentSuccess = true

            // Haptic feedback
            HapticManager.shared.success()

            // Auto-dismiss success after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showCommitmentSuccess = false

        } catch {
            print("Failed to commit: \(error)")
            self.error = "Failed to save your commitment"
            HapticManager.shared.error()
        }
    }

    /// Mark a commitment as fulfilled
    func fulfillCommitment(_ commitment: MemberCommitment) async {
        do {
            let updated = try await WeeklyFocusAPI.shared.fulfillCommitment(commitmentId: commitment.id)

            // Update local list
            if let index = commitments.firstIndex(where: { $0.id == commitment.id }) {
                commitments[index] = updated
            }

            HapticManager.shared.success()

        } catch {
            print("Failed to fulfill commitment: \(error)")
            self.error = "Failed to mark as complete"
            HapticManager.shared.error()
        }
    }

    /// Cancel a commitment
    func cancelCommitment(_ commitment: MemberCommitment, reason: String? = nil) async {
        do {
            let updated = try await WeeklyFocusAPI.shared.cancelCommitment(
                commitmentId: commitment.id,
                reason: reason
            )

            // Update local list
            if let index = commitments.firstIndex(where: { $0.id == commitment.id }) {
                commitments[index] = updated
            }

            // Update focus item status
            updateCommitmentStatus()

        } catch {
            print("Failed to cancel commitment: \(error)")
            self.error = "Failed to cancel commitment"
        }
    }

    /// Check if member has committed to a specific category
    func hasCommitted(to category: WeeklyFocusCategory) -> Bool {
        commitments.contains {
            $0.focusItemCategory == category &&
            $0.status == .committed
        }
    }

    /// Get commitment for a category if exists
    func commitment(for category: WeeklyFocusCategory) -> MemberCommitment? {
        commitments.first {
            $0.focusItemCategory == category &&
            ($0.status == .committed || $0.status == .fulfilled)
        }
    }

    // MARK: - Private Methods

    private func updateCommitmentStatus() {
        guard var focus = weeklyFocus else { return }

        var updatedItems = focus.items
        for (index, item) in updatedItems.enumerated() {
            let commitment = commitments.first {
                $0.focusItemCategory == item.category &&
                ($0.status == .committed || $0.status == .fulfilled)
            }
            updatedItems[index].hasCommitted = commitment != nil
            updatedItems[index].commitmentId = commitment?.id
        }

        // Create new focus with updated items
        weeklyFocus = WeeklyFocus(
            id: focus.id,
            churchId: focus.churchId,
            weekStart: focus.weekStart,
            weekEnd: focus.weekEnd,
            status: focus.status,
            items: updatedItems,
            generatedByAi: focus.generatedByAi,
            pastorNotes: focus.pastorNotes,
            approvedBy: focus.approvedBy,
            approvedAt: focus.approvedAt,
            publishedAt: focus.publishedAt,
            totalViews: focus.totalViews,
            totalCommitments: focus.totalCommitments,
            commitmentsByCategory: focus.commitmentsByCategory,
            createdAt: focus.createdAt,
            updatedAt: focus.updatedAt
        )
    }
}
