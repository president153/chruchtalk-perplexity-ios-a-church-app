//
//  MyCommitmentsView.swift
//  ChurchTalk
//
//  View for tracking member's weekly commitments.
//

import SwiftUI

struct MyCommitmentsView: View {
    @ObservedObject var viewModel: WeeklyFocusViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCommitment: MemberCommitment?
    @State private var showCancelConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Progress Section
                Section {
                    progressCard
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // Active Commitments
                let activeCommitments = viewModel.commitments.filter {
                    $0.status == .committed
                }
                if !activeCommitments.isEmpty {
                    Section("Active") {
                        ForEach(activeCommitments) { commitment in
                            CommitmentRow(
                                commitment: commitment,
                                onFulfill: {
                                    Task {
                                        await viewModel.fulfillCommitment(commitment)
                                    }
                                },
                                onCancel: {
                                    selectedCommitment = commitment
                                    showCancelConfirmation = true
                                }
                            )
                        }
                    }
                }

                // Fulfilled Commitments
                let fulfilledCommitments = viewModel.commitments.filter {
                    $0.status == .fulfilled
                }
                if !fulfilledCommitments.isEmpty {
                    Section("Completed") {
                        ForEach(fulfilledCommitments) { commitment in
                            CommitmentRow(
                                commitment: commitment,
                                onFulfill: nil,
                                onCancel: nil
                            )
                        }
                    }
                }

                // Cancelled/Missed
                let otherCommitments = viewModel.commitments.filter {
                    $0.status == .cancelled || $0.status == .missed
                }
                if !otherCommitments.isEmpty {
                    Section("Past") {
                        ForEach(otherCommitments) { commitment in
                            CommitmentRow(
                                commitment: commitment,
                                onFulfill: nil,
                                onCancel: nil
                            )
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My Commitments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Cancel Commitment?",
                isPresented: $showCancelConfirmation,
                presenting: selectedCommitment
            ) { commitment in
                Button("Cancel Commitment", role: .destructive) {
                    Task {
                        await viewModel.cancelCommitment(commitment)
                    }
                }
                Button("Keep It", role: .cancel) {}
            } message: { commitment in
                Text("Are you sure you want to cancel your commitment to \(commitment.itemTitle)?")
            }
        }
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        VStack(spacing: 16) {
            // Circle Progress
            ZStack {
                Circle()
                    .stroke(Color(.secondarySystemFill), lineWidth: 12)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: viewModel.fulfillmentProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    let fulfilled = viewModel.commitments.filter { $0.status == .fulfilled }.count
                    Text("\(fulfilled)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("of \(viewModel.commitments.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Message
            Text(progressMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var progressMessage: String {
        let fulfilled = viewModel.commitments.filter { $0.status == .fulfilled }.count
        let total = viewModel.commitments.count

        if fulfilled == total && total > 0 {
            return "Amazing! You've completed all your commitments this week!"
        } else if fulfilled > 0 {
            return "Great progress! Keep going!"
        } else {
            return "You've made \(total) commitment\(total == 1 ? "" : "s") this week"
        }
    }
}

// MARK: - Commitment Row

struct CommitmentRow: View {
    let commitment: MemberCommitment
    let onFulfill: (() -> Void)?
    let onCancel: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(commitment.focusItemCategory.defaultColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: commitment.focusItemCategory.icon)
                    .font(.system(size: 18))
                    .foregroundColor(commitment.focusItemCategory.defaultColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(commitment.itemTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    statusBadge

                    Text(commitment.committedAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            if commitment.status == .committed {
                Menu {
                    if let onFulfill {
                        Button {
                            onFulfill()
                        } label: {
                            Label("Mark Complete", systemImage: "checkmark.circle")
                        }
                    }

                    if let onCancel {
                        Button(role: .destructive) {
                            onCancel()
                        } label: {
                            Label("Cancel", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch commitment.status {
        case .committed:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
                Text("Active")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        case .fulfilled:
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.caption2)
                Text("Completed")
                    .font(.caption2)
            }
            .foregroundColor(.green)
        case .missed:
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Missed")
                    .font(.caption2)
            }
            .foregroundColor(.orange)
        case .cancelled:
            HStack(spacing: 4) {
                Image(systemName: "xmark")
                    .font(.caption2)
                Text("Cancelled")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
        }
    }
}

#Preview {
    MyCommitmentsView(viewModel: WeeklyFocusViewModel())
}
