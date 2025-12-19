//
//  FundTypesView.swift
//  ChurchTalk
//
//  Fund types view for browsing and selecting donation funds.
//

import SwiftUI

struct FundTypesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var funds: [Fund] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var showingGiveSheet = false
    @State private var selectedFund: Fund?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if isLoading {
                ProgressView("Loading funds...")
            } else if let error = error {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if funds.isEmpty {
                ContentUnavailableView(
                    "No Funds Available",
                    systemImage: "heart.circle",
                    description: Text("Check back later for giving opportunities.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Card
                        headerCard
                            .padding(.horizontal)

                        // Funds List
                        VStack(spacing: 12) {
                            ForEach(funds) { fund in
                                FundCard(fund: fund) {
                                    selectedFund = fund
                                    openGivingPage(fundId: fund.id)
                                }
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 40)
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Giving")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadFunds()
        }
        .refreshable {
            await loadFunds()
        }
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Support Your Church")
                .font(.title2)
                .fontWeight(.bold)

            Text("Choose a fund below to give. Your generosity helps support our mission and community.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func loadFunds() async {
        isLoading = true
        error = nil

        do {
            funds = try await GivingAPI.shared.listFunds()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func openGivingPage(fundId: String) {
        // Get church identifier from auth (use id as fallback if no slug available)
        let churchIdentifier = authViewModel.currentChurch?.id ?? ""

        guard let url = GivingURLBuilder.buildURL(
            churchSlug: churchIdentifier,
            fundId: fundId
        ) else {
            error = "Unable to open giving page"
            return
        }

        UIApplication.shared.open(url)
    }
}

// MARK: - Fund Card

private struct FundCard: View {
    let fund: Fund
    let onGive: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Fund Info
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fund.name)
                        .font(.headline)

                    if let description = fund.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Tax badge
                if fund.isTaxDeductible {
                    Text("Tax Deductible")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }

            // Progress if goal exists
            if let goal = fund.goalAmount, goal > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: min(fund.currentAmount / goal, 1.0))
                        .tint(.purple)

                    HStack {
                        Text(formatCurrency(fund.currentAmount))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Goal: \(formatCurrency(goal))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Give Button
            Button(action: onGive) {
                HStack {
                    Image(systemName: "heart.fill")
                    Text("Give Now")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.purple, .purple.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

#Preview {
    NavigationStack {
        FundTypesView()
            .environmentObject(AuthViewModel())
    }
}
