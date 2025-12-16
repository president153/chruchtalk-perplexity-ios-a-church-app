//
//  GivingView.swift
//  ChurchTalk
//
//  Main giving view with give button, history, and recurring management.
//

import SwiftUI

struct GivingView: View {
    @StateObject private var viewModel = GivingViewModel()
    @State private var selectedTab: GivingTab = .overview

    enum GivingTab: String, CaseIterable {
        case overview = "Overview"
        case history = "History"
        case recurring = "Recurring"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("", selection: $selectedTab) {
                    ForEach(GivingTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                Group {
                    switch selectedTab {
                    case .overview:
                        OverviewTab(viewModel: viewModel)
                    case .history:
                        HistoryTab(viewModel: viewModel)
                    case .recurring:
                        RecurringTab(viewModel: viewModel)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Giving")
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }
}

// MARK: - Overview Tab

private struct OverviewTab: View {
    @ObservedObject var viewModel: GivingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Give Now Button
                GiveNowCard(onTap: {
                    viewModel.openGivingPage()
                })
                .padding(.horizontal)

                // Stats Cards
                HStack(spacing: 12) {
                    StatCard(
                        title: "Year to Date",
                        value: viewModel.formattedYearlyTotal,
                        icon: "chart.line.uptrend.xyaxis"
                    )

                    StatCard(
                        title: "Recurring/Mo",
                        value: viewModel.formattedMonthlyRecurringTotal,
                        icon: "repeat"
                    )
                }
                .padding(.horizontal)

                // Fund Selection
                if !viewModel.funds.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Give to a Specific Fund")
                            .font(.headline)
                            .foregroundColor(.primary)

                        ForEach(viewModel.funds) { fund in
                            FundRow(fund: fund) {
                                viewModel.openGivingPage(fundId: fund.id)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Recent Donations
                if !viewModel.donations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Donations")
                                .font(.headline)
                            Spacer()
                            Button("See All") {
                                // Switch to history tab - handled by parent
                            }
                            .font(.subheadline)
                        }

                        ForEach(viewModel.donations.prefix(3)) { donation in
                            DonationRow(donation: donation)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - History Tab

private struct HistoryTab: View {
    @ObservedObject var viewModel: GivingViewModel
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    var body: some View {
        VStack(spacing: 0) {
            // Year Picker
            HStack {
                Text("Year:")
                    .foregroundColor(.secondary)
                Picker("", selection: $selectedYear) {
                    ForEach((2020...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .onChange(of: selectedYear) { _, year in
                    Task {
                        await viewModel.loadDonations(year: year)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))

            // Donations List
            if viewModel.donations.isEmpty {
                ContentUnavailableView(
                    "No Donations",
                    systemImage: "heart",
                    description: Text("You haven't made any donations yet.")
                )
            } else {
                List(viewModel.donations) { donation in
                    DonationDetailRow(donation: donation)
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Recurring Tab

private struct RecurringTab: View {
    @ObservedObject var viewModel: GivingViewModel
    @State private var showingCancelAlert = false
    @State private var recurringToCancel: RecurringGiving?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.recurringGivings.isEmpty {
                ContentUnavailableView(
                    "No Recurring Giving",
                    systemImage: "repeat",
                    description: Text("Set up recurring giving to support your church automatically.")
                )

                Button {
                    viewModel.openGivingPage()
                } label: {
                    Label("Set Up Recurring", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .padding()
            } else {
                List(viewModel.recurringGivings) { recurring in
                    RecurringRow(recurring: recurring) {
                        recurringToCancel = recurring
                        showingCancelAlert = true
                    }
                }
                .listStyle(.plain)
            }
        }
        .alert("Cancel Recurring Giving", isPresented: $showingCancelAlert) {
            Button("Keep") { }
            Button("Cancel Giving", role: .destructive) {
                if let recurring = recurringToCancel {
                    Task {
                        await viewModel.cancelRecurring(recurring)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to cancel this recurring giving?")
        }
    }
}

// MARK: - Supporting Views

private struct GiveNowCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Give Now")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Support your church")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.purple.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.purple)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct FundRow: View {
    let fund: Fund
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(fund.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let description = fund.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.purple)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

private struct DonationRow: View {
    let donation: Donation

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(donation.fundName ?? "General Fund")
                    .font(.subheadline)
                Text(donation.donatedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(donation.formattedAmount)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct DonationDetailRow: View {
    let donation: Donation

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(donation.fundName ?? "General Fund")
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(donation.donatedAt, style: .date)
                    if donation.isRecurring {
                        Text("• Recurring")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(donation.formattedAmount)
                    .font(.headline)
                StatusBadge(status: donation.donationStatus)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct StatusBadge: View {
    let status: DonationStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(4)
    }

    var backgroundColor: Color {
        switch status {
        case .succeeded: return Color.green.opacity(0.2)
        case .pending: return Color.yellow.opacity(0.2)
        case .failed, .canceled: return Color.red.opacity(0.2)
        case .refunded: return Color.gray.opacity(0.2)
        }
    }

    var foregroundColor: Color {
        switch status {
        case .succeeded: return .green
        case .pending: return .orange
        case .failed, .canceled: return .red
        case .refunded: return .gray
        }
    }
}

private struct RecurringRow: View {
    let recurring: RecurringGiving
    let onCancel: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recurring.fundName ?? "General Fund")
                    .font(.headline)
                Text("\(recurring.recurringFrequency.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if recurring.isActive {
                    Text("Next: \(recurring.nextDonationDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(recurring.formattedAmount)
                    .font(.headline)
                if recurring.isActive {
                    Button("Cancel", action: onCancel)
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("Inactive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GivingView()
}
