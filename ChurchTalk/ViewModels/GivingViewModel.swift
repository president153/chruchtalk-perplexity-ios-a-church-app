//
//  GivingViewModel.swift
//  ChurchTalk
//
//  ViewModel for managing giving state and actions.
//

import SwiftUI

@MainActor
class GivingViewModel: ObservableObject {
    // MARK: - Published State

    @Published var funds: [Fund] = []
    @Published var donations: [Donation] = []
    @Published var recurringGivings: [RecurringGiving] = []
    @Published var isLoading = false
    @Published var error: String?

    // Selection state
    @Published var selectedFund: Fund?

    // Church info (from auth store)
    var churchSlug: String = ""

    // MARK: - Initialization

    init() {}

    // MARK: - Load Data

    func loadData() async {
        isLoading = true
        error = nil

        do {
            async let fundsTask = GivingAPI.shared.listFunds()
            async let donationsTask = GivingAPI.shared.getMyDonations()
            async let recurringTask = GivingAPI.shared.getMyRecurringGivings()

            let (loadedFunds, loadedDonations, loadedRecurring) = try await (
                fundsTask,
                donationsTask,
                recurringTask
            )

            funds = loadedFunds
            donations = loadedDonations
            recurringGivings = loadedRecurring

            // Set default fund
            if selectedFund == nil && !funds.isEmpty {
                selectedFund = funds.first
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadDonations(year: Int? = nil) async {
        do {
            donations = try await GivingAPI.shared.getMyDonations(year: year)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadRecurringGivings() async {
        do {
            recurringGivings = try await GivingAPI.shared.getMyRecurringGivings()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Actions

    /// Open Safari to the giving page
    func openGivingPage(fundId: String? = nil) {
        guard let url = GivingURLBuilder.buildURL(
            churchSlug: churchSlug,
            fundId: fundId ?? selectedFund?.id
        ) else {
            error = "Unable to open giving page"
            return
        }

        UIApplication.shared.open(url)
    }

    /// Cancel a recurring giving
    func cancelRecurring(_ recurring: RecurringGiving) async {
        do {
            try await GivingAPI.shared.cancelRecurringGiving(id: recurring.id)
            // Remove from list
            recurringGivings.removeAll { $0.id == recurring.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Computed Properties

    /// Total given this year
    var yearlyTotal: Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return donations
            .filter { Calendar.current.component(.year, from: $0.donatedAt) == currentYear }
            .filter { $0.donationStatus == .succeeded }
            .reduce(0) { $0 + $1.amount }
    }

    var formattedYearlyTotal: String {
        let dollars = Double(yearlyTotal) / 100.0
        return String(format: "$%.2f", dollars)
    }

    /// Active recurring count
    var activeRecurringCount: Int {
        recurringGivings.filter { $0.isActive }.count
    }

    /// Monthly recurring total
    var monthlyRecurringTotal: Int {
        recurringGivings
            .filter { $0.isActive }
            .reduce(0) { total, recurring in
                switch recurring.recurringFrequency {
                case .weekly: return total + (recurring.amount * 4)
                case .biweekly: return total + (recurring.amount * 2)
                case .monthly: return total + recurring.amount
                }
            }
    }

    var formattedMonthlyRecurringTotal: String {
        let dollars = Double(monthlyRecurringTotal) / 100.0
        return String(format: "$%.2f", dollars)
    }
}
