//
//  GivingAPI.swift
//  ChurchTalk
//
//  API service for giving-related endpoints.
//  Note: Actual payments are processed via Safari/browser due to Apple restrictions.
//

import Foundation

// MARK: - API Actor

@globalActor
actor GivingAPIActor {
    static let shared = GivingAPIActor()
}

// MARK: - GivingAPI

@GivingAPIActor
final class GivingAPI {

    static let shared = GivingAPI()

    private init() {}

    // MARK: - Funds

    /// List all active funds for the church
    func listFunds() async throws -> [Fund] {
        let response: FundsListResponse = try await APIClient.shared.get("/giving/funds?active_only=true")
        return response.funds.map { $0.toFund() }
    }

    // MARK: - My Donations

    /// Get my donation history
    func getMyDonations(year: Int? = nil, skip: Int = 0, limit: Int = 50) async throws -> [Donation] {
        var endpoint = "/giving/donations/my?skip=\(skip)&limit=\(limit)"
        if let year = year {
            endpoint += "&year=\(year)"
        }

        let response: DonationsListResponse = try await APIClient.shared.get(endpoint)
        return response.donations.map { $0.toDonation() }
    }

    // MARK: - My Recurring Givings

    /// Get my recurring giving subscriptions
    func getMyRecurringGivings() async throws -> [RecurringGiving] {
        let response: RecurringGivingsListResponse = try await APIClient.shared.get("/giving/recurring/my")
        return response.recurringGivings.map { $0.toRecurringGiving() }
    }

    /// Cancel a recurring giving
    func cancelRecurringGiving(id: String) async throws {
        try await APIClient.shared.delete("/giving/recurring/\(id)")
    }

    // MARK: - Tax Statements

    /// Get donor statement for a specific year
    func getDonorStatement(year: Int) async throws -> DonorStatement {
        let response: DonorStatementResponse = try await APIClient.shared.get("/giving/reports/statement/me/\(year)")
        return response.toDonorStatement()
    }

    // MARK: - Summary

    /// Get giving summary for the current user
    func getMySummary(startDate: Date? = nil, endDate: Date? = nil) async throws -> GivingSummary {
        var endpoint = "/giving/reports/summary"

        var queryItems: [String] = []
        if let start = startDate {
            queryItems.append("start_date=\(ISO8601DateFormatter().string(from: start))")
        }
        if let end = endDate {
            queryItems.append("end_date=\(ISO8601DateFormatter().string(from: end))")
        }

        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }

        let response: GivingSummaryResponse = try await APIClient.shared.get(endpoint)
        return response.toGivingSummary()
    }
}

// MARK: - List Response Wrappers

private struct FundsListResponse: Codable {
    let funds: [FundResponse]
}

private struct DonationsListResponse: Codable {
    let donations: [DonationResponse]
}

private struct RecurringGivingsListResponse: Codable {
    let recurringGivings: [RecurringGivingResponse]

    enum CodingKeys: String, CodingKey {
        case recurringGivings = "recurring_givings"
    }
}

// MARK: - Response Types

private struct FundResponse: Codable {
    let id: String
    let churchId: String
    let name: String
    let description: String?
    let isActive: Bool
    let isTaxDeductible: Bool
    let goalAmount: Double?
    let currentAmount: Double
    let allowFeeCoverage: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case churchId = "church_id"
        case name, description
        case isActive = "is_active"
        case isTaxDeductible = "is_tax_deductible"
        case goalAmount = "goal_amount"
        case currentAmount = "current_amount"
        case allowFeeCoverage = "allow_fee_coverage"
    }

    func toFund() -> Fund {
        Fund(
            id: id,
            churchId: churchId,
            name: name,
            description: description,
            isActive: isActive,
            isTaxDeductible: isTaxDeductible,
            goalAmount: goalAmount,
            currentAmount: currentAmount,
            allowFeeCoverage: allowFeeCoverage
        )
    }
}

private struct DonationResponse: Codable {
    let id: String
    let churchId: String
    let donorId: String
    let fundId: String
    let fundName: String?
    let amount: Int
    let stripeFee: Int
    let feeCoveredByDonor: Bool
    let totalCharged: Int
    let netAmount: Int
    let status: String
    let paymentMethodType: String
    let paymentMethodLast4: String?
    let isRecurring: Bool
    let donatedAt: String
    let donorNote: String?

    enum CodingKeys: String, CodingKey {
        case id
        case churchId = "church_id"
        case donorId = "donor_id"
        case fundId = "fund_id"
        case fundName = "fund_name"
        case amount
        case stripeFee = "stripe_fee"
        case feeCoveredByDonor = "fee_covered_by_donor"
        case totalCharged = "total_charged"
        case netAmount = "net_amount"
        case status
        case paymentMethodType = "payment_method_type"
        case paymentMethodLast4 = "payment_method_last4"
        case isRecurring = "is_recurring"
        case donatedAt = "donated_at"
        case donorNote = "donor_note"
    }

    func toDonation() -> Donation {
        Donation(
            id: id,
            churchId: churchId,
            donorId: donorId,
            fundId: fundId,
            fundName: fundName,
            amount: amount,
            stripeFee: stripeFee,
            feeCoveredByDonor: feeCoveredByDonor,
            totalCharged: totalCharged,
            netAmount: netAmount,
            status: status,
            paymentMethodType: paymentMethodType,
            paymentMethodLast4: paymentMethodLast4,
            isRecurring: isRecurring,
            donatedAt: parseDate(donatedAt) ?? Date(),
            donorNote: donorNote
        )
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}

private struct RecurringGivingResponse: Codable {
    let id: String
    let churchId: String
    let fundId: String
    let fundName: String?
    let amount: Int
    let coverFees: Bool
    let frequency: String
    let nextDonationDate: String
    let isActive: Bool
    let totalDonations: Int
    let totalAmountGiven: Int
    let lastDonationAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case churchId = "church_id"
        case fundId = "fund_id"
        case fundName = "fund_name"
        case amount
        case coverFees = "cover_fees"
        case frequency
        case nextDonationDate = "next_donation_date"
        case isActive = "is_active"
        case totalDonations = "total_donations"
        case totalAmountGiven = "total_amount_given"
        case lastDonationAt = "last_donation_at"
    }

    func toRecurringGiving() -> RecurringGiving {
        RecurringGiving(
            id: id,
            churchId: churchId,
            fundId: fundId,
            fundName: fundName,
            amount: amount,
            coverFees: coverFees,
            frequency: frequency,
            nextDonationDate: parseDate(nextDonationDate) ?? Date(),
            isActive: isActive,
            totalDonations: totalDonations,
            totalAmountGiven: totalAmountGiven,
            lastDonationAt: lastDonationAt != nil ? parseDate(lastDonationAt!) : nil
        )
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}

private struct GivingSummaryResponse: Codable {
    let totalAmount: Int
    let totalDonations: Int
    let totalDonors: Int
    let averageDonation: Double
    let periodStart: String
    let periodEnd: String

    enum CodingKeys: String, CodingKey {
        case totalAmount = "total_amount"
        case totalDonations = "total_donations"
        case totalDonors = "total_donors"
        case averageDonation = "average_donation"
        case periodStart = "period_start"
        case periodEnd = "period_end"
    }

    func toGivingSummary() -> GivingSummary {
        GivingSummary(
            totalAmount: totalAmount,
            totalDonations: totalDonations,
            totalDonors: totalDonors,
            averageDonation: averageDonation,
            periodStart: parseDate(periodStart) ?? Date(),
            periodEnd: parseDate(periodEnd) ?? Date()
        )
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}

private struct DonorStatementResponse: Codable {
    let year: Int
    let totalAmount: Int
    let totalTaxDeductible: Int
    let donationCount: Int
    let donations: [DonationRecordResponse]

    enum CodingKeys: String, CodingKey {
        case year
        case totalAmount = "total_amount"
        case totalTaxDeductible = "total_tax_deductible"
        case donationCount = "donation_count"
        case donations
    }

    struct DonationRecordResponse: Codable {
        let date: String
        let amount: Int
        let fundName: String
        let isTaxDeductible: Bool

        enum CodingKeys: String, CodingKey {
            case date, amount
            case fundName = "fund_name"
            case isTaxDeductible = "is_tax_deductible"
        }
    }

    func toDonorStatement() -> DonorStatement {
        DonorStatement(
            year: year,
            totalAmount: totalAmount,
            totalTaxDeductible: totalTaxDeductible,
            donationCount: donationCount,
            donations: donations.map { record in
                DonorStatement.DonationRecord(
                    date: parseDate(record.date) ?? Date(),
                    amount: record.amount,
                    fundName: record.fundName,
                    isTaxDeductible: record.isTaxDeductible
                )
            }
        )
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
