//
//  FundTypeCard.swift
//  ChurchTalkAdmin
//
//  Card component for displaying a single fund type
//

import SwiftUI

struct FundTypeCard: View {
    let fundType: FundType
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon and Name
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.financeColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.financeColor)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(fundType.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)

                        if let description = fundType.description, !description.isEmpty {
                            Text(description)
                                .font(.system(size: 13))
                                .foregroundColor(.secondaryText)
                                .lineLimit(2)
                        }
                    }
                }

                Spacer()

                // Status Badge
                if fundType.isActive {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.financeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.financeColor.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Text("Inactive")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondaryText.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // Properties
            HStack(spacing: 16) {
                if fundType.isTaxDeductible {
                    PropertyBadge(icon: "checkmark.seal.fill", text: "Tax Deductible", color: Color(hex: "3b82f6"))
                }

                if fundType.allowFeeCoverage {
                    PropertyBadge(icon: "dollarsign.arrow.circlepath", text: "Fee Coverage", color: Color(hex: "a855f7"))
                }
            }

            // Actions
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                        Text("Edit")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "3b82f6"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "3b82f6").opacity(0.1))
                    .cornerRadius(6)
                }

                Button(action: onDelete) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                        Text("Delete")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "ef4444"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "ef4444").opacity(0.1))
                    .cornerRadius(6)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Property Badge Component

struct PropertyBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Preview

struct FundTypeCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            FundTypeCard(
                fundType: FundType(
                    id: 1,
                    churchId: 1,
                    name: "General Fund",
                    description: "General church operations and ministry",
                    isTaxDeductible: true,
                    allowFeeCoverage: true,
                    isActive: true,
                    createdAt: Int(Date().timeIntervalSince1970),
                    updatedAt: Int(Date().timeIntervalSince1970)
                ),
                onEdit: { },
                onDelete: { }
            )

            FundTypeCard(
                fundType: FundType(
                    id: 2,
                    churchId: 1,
                    name: "Missions",
                    description: "Support for missionary work and outreach programs",
                    isTaxDeductible: true,
                    allowFeeCoverage: false,
                    isActive: false,
                    createdAt: Int(Date().timeIntervalSince1970),
                    updatedAt: Int(Date().timeIntervalSince1970)
                ),
                onEdit: { },
                onDelete: { }
            )
        }
        .padding()
        .background(Color.secondaryBackground)
    }
}
