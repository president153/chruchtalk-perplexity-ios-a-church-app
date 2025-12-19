//
//  WeeklyFocusView.swift
//  ChurchTalk
//
//  Main weekly focus screen - "Never Miss What Matters"
//  This is designed to be the first thing members see.
//

import SwiftUI

struct WeeklyFocusView: View {
    @StateObject private var viewModel = WeeklyFocusViewModel()
    @State private var showMyCommitments = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection

                    // Pastor's Note
                    if let notes = viewModel.weeklyFocus?.pastorNotes, !notes.isEmpty {
                        pastorNoteSection(notes)
                    }

                    // Focus Items
                    if viewModel.isLoading {
                        loadingSection
                    } else if let focus = viewModel.weeklyFocus {
                        focusItemsSection(focus)
                    } else if viewModel.error != nil {
                        errorSection
                    } else {
                        emptySection
                    }

                    // My Commitments Summary
                    if viewModel.hasCommitments {
                        commitmentsSummary
                    }

                    // Bottom padding for tab bar
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                await viewModel.fetchData()
            }
            .task {
                await viewModel.fetchData()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("This Week's Focus")
                        .font(.headline)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.hasCommitments {
                        Button {
                            showMyCommitments = true
                        } label: {
                            Image(systemName: "checklist")
                        }
                    }
                }
            }
            .sheet(isPresented: $showMyCommitments) {
                MyCommitmentsView(viewModel: viewModel)
            }
            .overlay(alignment: .top) {
                // Success toast
                if viewModel.showCommitmentSuccess {
                    successToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            // Week indicator
            if let focus = viewModel.weeklyFocus {
                Text(focus.weekDateRange)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(.secondarySystemBackground))
                    )
            }

            // Title
            Text("Your Focus This Week")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Subtitle
            Text("Four simple ways to grow and connect")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Progress indicator
            if viewModel.hasCommitments {
                progressIndicator
            }
        }
        .padding(.vertical, 8)
    }

    private var progressIndicator: some View {
        HStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.secondarySystemFill))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * viewModel.fulfillmentProgress)
                }
            }
            .frame(height: 6)

            // Count
            let fulfilled = viewModel.commitments.filter { $0.status == .fulfilled }.count
            let total = viewModel.commitments.count
            Text("\(fulfilled)/\(total)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 40)
        .padding(.top, 8)
    }

    // MARK: - Pastor Note Section

    private func pastorNoteSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundColor(.churchTalkRed)
                Text("FROM YOUR PASTOR")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(1)
            }

            Text(notes)
                .font(.subheadline)
                .foregroundColor(.primary)
                .italic()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.churchTalkRed.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.churchTalkRed.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Focus Items Section

    private func focusItemsSection(_ focus: WeeklyFocus) -> some View {
        VStack(spacing: 16) {
            ForEach(focus.items.sorted(by: { $0.priority < $1.priority })) { item in
                WeeklyFocusCategoryCard(
                    item: item,
                    isCommitted: viewModel.hasCommitted(to: item.category),
                    onCommit: {
                        Task {
                            await viewModel.commit(to: item)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Loading Section

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 160)
                    .shimmer()
            }
        }
    }

    // MARK: - Error Section

    private var errorSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load")
                .font(.headline)

            Text(viewModel.error ?? "Something went wrong")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.fetchData()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Empty Section

    private var emptySection: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Focus This Week")
                .font(.headline)

            Text("Check back soon - your church will publish the weekly focus shortly.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Commitments Summary

    private var commitmentsSummary: some View {
        Button {
            showMyCommitments = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Commitments")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    let fulfilled = viewModel.commitments.filter { $0.status == .fulfilled }.count
                    let total = viewModel.commitments.count
                    Text("\(fulfilled) of \(total) completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Category icons
                HStack(spacing: -8) {
                    ForEach(viewModel.commitments.prefix(4)) { commitment in
                        Circle()
                            .fill(commitment.focusItemCategory.defaultColor)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: commitment.focusItemCategory.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Success Toast

    private var successToast: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            if let category = viewModel.lastCommittedCategory {
                Text("Committed to \(category.displayName)!")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        )
        .padding(.top, 60)
    }
}

#Preview {
    WeeklyFocusView()
}
