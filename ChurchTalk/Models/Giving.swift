//
//  Giving.swift
//  ChurchTalk
//
//  Models for church giving and donations.
//

import Foundation

// MARK: - Enums

/// Status of a donation
enum DonationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case succeeded = "succeeded"
    case failed = "failed"
    case refunded = "refunded"
    case canceled = "canceled"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .succeeded: return "Completed"
        case .failed: return "Failed"
        case .refunded: return "Refunded"
        case .canceled: return "Canceled"
        }
    }
}

/// Frequency for recurring giving
enum RecurringFrequency: String, Codable, CaseIterable {
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        }
    }
}

// MARK: - Fund Model

/// A donation fund/category (Tithes, Missions, Building, etc.)
struct Fund: Identifiable, Codable {
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
}

// MARK: - Donation Model

/// A single donation record
struct Donation: Identifiable, Codable {
    let id: String
    let churchId: String
    let donorId: String
    let fundId: String
    let fundName: String?
    let amount: Int  // in cents
    let stripeFee: Int
    let feeCoveredByDonor: Bool
    let totalCharged: Int
    let netAmount: Int
    let status: String
    let paymentMethodType: String
    let paymentMethodLast4: String?
    let isRecurring: Bool
    let donatedAt: Date
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

    /// Format amount as currency string
    var formattedAmount: String {
        let dollars = Double(amount) / 100.0
        return String(format: "$%.2f", dollars)
    }

    /// Get donation status enum
    var donationStatus: DonationStatus {
        DonationStatus(rawValue: status) ?? .pending
    }
}

// MARK: - Recurring Giving Model

/// A recurring giving subscription
struct RecurringGiving: Identifiable, Codable {
    let id: String
    let churchId: String
    let fundId: String
    let fundName: String?
    let amount: Int
    let coverFees: Bool
    let frequency: String
    let nextDonationDate: Date
    let isActive: Bool
    let totalDonations: Int
    let totalAmountGiven: Int
    let lastDonationAt: Date?

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

    /// Format amount as currency string
    var formattedAmount: String {
        let dollars = Double(amount) / 100.0
        return String(format: "$%.2f", dollars)
    }

    /// Get frequency enum
    var recurringFrequency: RecurringFrequency {
        RecurringFrequency(rawValue: frequency) ?? .monthly
    }
}

// MARK: - Giving Summary

/// Summary of giving for a period
struct GivingSummary: Codable {
    let totalAmount: Int
    let totalDonations: Int
    let totalDonors: Int
    let averageDonation: Double
    let periodStart: Date
    let periodEnd: Date

    enum CodingKeys: String, CodingKey {
        case totalAmount = "total_amount"
        case totalDonations = "total_donations"
        case totalDonors = "total_donors"
        case averageDonation = "average_donation"
        case periodStart = "period_start"
        case periodEnd = "period_end"
    }

    var formattedTotal: String {
        let dollars = Double(totalAmount) / 100.0
        return String(format: "$%.2f", dollars)
    }

    var formattedAverage: String {
        let dollars = averageDonation / 100.0
        return String(format: "$%.2f", dollars)
    }
}

// MARK: - Donor Statement

/// Yearly giving statement for tax purposes
struct DonorStatement: Codable {
    let year: Int
    let totalAmount: Int
    let totalTaxDeductible: Int
    let donationCount: Int
    let donations: [DonationRecord]

    enum CodingKeys: String, CodingKey {
        case year
        case totalAmount = "total_amount"
        case totalTaxDeductible = "total_tax_deductible"
        case donationCount = "donation_count"
        case donations
    }

    struct DonationRecord: Codable {
        let date: Date
        let amount: Int
        let fundName: String
        let isTaxDeductible: Bool

        enum CodingKeys: String, CodingKey {
            case date, amount
            case fundName = "fund_name"
            case isTaxDeductible = "is_tax_deductible"
        }
    }

    var formattedTotal: String {
        let dollars = Double(totalAmount) / 100.0
        return String(format: "$%.2f", dollars)
    }

    var formattedTaxDeductible: String {
        let dollars = Double(totalTaxDeductible) / 100.0
        return String(format: "$%.2f", dollars)
    }
}

// MARK: - Fee Calculation

/// Calculate fees for a donation
struct FeeCalculation {
    let amount: Int
    let stripeFee: Int
    let platformFee: Int
    let totalCharged: Int
    let netToChurch: Int

    /// Calculate fees for a donation amount
    /// - Parameters:
    ///   - amount: Amount in cents
    ///   - coverFees: Whether donor is covering fees
    /// - Returns: Fee calculation result
    static func calculate(amount: Int, coverFees: Bool) -> FeeCalculation {
        let stripeRate = 0.029  // 2.9%
        let stripeFixed = 30    // $0.30 in cents
        let platformRate = 0.002 // 0.2%

        if coverFees {
            let stripeFee = Int(Double(amount) * stripeRate) + stripeFixed
            let platformFee = Int(Double(amount) * platformRate)
            return FeeCalculation(
                amount: amount,
                stripeFee: stripeFee,
                platformFee: platformFee,
                totalCharged: amount + stripeFee + platformFee,
                netToChurch: amount
            )
        } else {
            let stripeFee = Int(Double(amount) * stripeRate) + stripeFixed
            return FeeCalculation(
                amount: amount,
                stripeFee: stripeFee,
                platformFee: 0,
                totalCharged: amount,
                netToChurch: amount - stripeFee
            )
        }
    }

    var formattedTotal: String {
        let dollars = Double(totalCharged) / 100.0
        return String(format: "$%.2f", dollars)
    }

    var formattedFees: String {
        let dollars = Double(stripeFee + platformFee) / 100.0
        return String(format: "$%.2f", dollars)
    }
}

// MARK: - URL Builder for Giving Page

/// Build URL for the giving web page
struct GivingURLBuilder {
    /// Base URL for the giving page
    static let baseURL = "https://give.churchtalk.ai/give"

    /// Build URL to open giving page in Safari
    /// - Parameters:
    ///   - churchSlug: Church identifier slug
    ///   - fundId: Optional pre-selected fund ID
    /// - Returns: URL to open in Safari
    static func buildURL(churchSlug: String, fundId: String? = nil) -> URL? {
        var components = URLComponents(string: baseURL)

        var queryItems: [URLQueryItem] = []

        // Add church slug as query parameter
        queryItems.append(URLQueryItem(name: "church", value: churchSlug))

        // Add fund if specified
        if let fundId = fundId {
            queryItems.append(URLQueryItem(name: "fund", value: fundId))
        }

        // Add return URL for deep link back to app
        let returnURL = "churchtalk://giving/success"
        queryItems.append(URLQueryItem(name: "returnUrl", value: returnURL))

        components?.queryItems = queryItems

        return components?.url
    }
}
