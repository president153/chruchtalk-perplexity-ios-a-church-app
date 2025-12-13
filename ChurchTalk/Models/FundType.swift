//
//  FundType.swift
//  ChurchTalkAdmin
//
//  Created by Claude on 11/18/25.
//

import Foundation

// MARK: - Fund Type Model

struct FundType: Codable, Identifiable, Hashable {
    let id: Int
    let churchId: Int
    let name: String
    let description: String?
    let isTaxDeductible: Bool
    let allowFeeCoverage: Bool
    let isActive: Bool
    let createdAt: Int
    let updatedAt: Int

    enum CodingKeys: String, CodingKey {
        case id
        case churchId = "church_id"
        case name
        case description
        case isTaxDeductible = "is_tax_deductible"
        case allowFeeCoverage = "allow_fee_coverage"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    var statusText: String {
        isActive ? "Active" : "Inactive"
    }

    var taxDeductibleText: String {
        isTaxDeductible ? "Tax Deductible" : "Not Tax Deductible"
    }

    var feeCoverageText: String {
        allowFeeCoverage ? "Fee coverage allowed" : "Fee coverage not allowed"
    }
}

// MARK: - Fund Type Create/Update Request

struct FundTypeRequest: Codable {
    let name: String
    let description: String?
    let isTaxDeductible: Bool
    let allowFeeCoverage: Bool
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case isTaxDeductible = "is_tax_deductible"
        case allowFeeCoverage = "allow_fee_coverage"
        case isActive = "is_active"
    }
}

// MARK: - Fund Types List Response

struct FundTypesResponse: Codable {
    let fundTypes: [FundType]

    enum CodingKeys: String, CodingKey {
        case fundTypes = "fund_types"
    }
}

// MARK: - Single Fund Type Response

struct FundTypeResponse: Codable {
    let fundType: FundType

    enum CodingKeys: String, CodingKey {
        case fundType = "fund_type"
    }
}
