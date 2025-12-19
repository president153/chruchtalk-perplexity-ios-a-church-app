//
//  WeeklyFocusCategoryCard.swift
//  ChurchTalk
//
//  Individual category card for the weekly focus.
//

import SwiftUI

struct WeeklyFocusCategoryCard: View {
    let item: WeeklyFocusItem
    let isCommitted: Bool
    let onCommit: () -> Void

    @State private var isPressed = false
    @State private var showCheckmark = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and category
            HStack(spacing: 10) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(item.swiftUIColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: item.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(item.swiftUIColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.category.displayName.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(item.swiftUIColor)
                        .tracking(1)

                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                Spacer()

                // Committed checkmark
                if isCommitted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // Description
            Text(item.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            // Entity reference if applicable
            if let entityName = item.entityName {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                        .foregroundColor(item.swiftUIColor.opacity(0.7))
                    Text(entityName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Action button
            Button(action: {
                if !isCommitted {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        showCheckmark = true
                    }
                    onCommit()
                }
            }) {
                HStack {
                    if isCommitted {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text(isCommitted ? "Committed!" : item.actionLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isCommitted
                        ? Color.green.opacity(0.15)
                        : item.swiftUIColor
                )
                .foregroundColor(isCommitted ? .green : .white)
                .cornerRadius(10)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isCommitted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isCommitted ? Color.green.opacity(0.3) : item.swiftUIColor.opacity(0.2),
                    lineWidth: isCommitted ? 2 : 1
                )
        )
    }
}

// Compact version for list views
struct WeeklyFocusCategoryCardCompact: View {
    let item: WeeklyFocusItem
    let isCommitted: Bool
    let onCommit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(item.swiftUIColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: item.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(item.swiftUIColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Action
            if isCommitted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Button(item.actionLabel) {
                    onCommit()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(item.swiftUIColor)
                .cornerRadius(8)
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        WeeklyFocusCategoryCard(
            item: WeeklyFocusItem(
                category: .serve,
                title: "Volunteer at Food Bank",
                description: "Help sort and distribute food to families in need this Saturday.",
                actionLabel: "I'll help",
                actionType: "volunteer",
                entityType: "event",
                entityId: "123",
                entityName: "Community Food Bank",
                icon: "hands.sparkles.fill",
                color: "FF6B35",
                priority: 0
            ),
            isCommitted: false,
            onCommit: {}
        )

        WeeklyFocusCategoryCard(
            item: WeeklyFocusItem(
                category: .pray,
                title: "Pray for Our Missionaries",
                description: "Lift up the Johnson family serving in South America.",
                actionLabel: "I'm praying",
                actionType: "prayer",
                entityType: nil,
                entityId: nil,
                entityName: nil,
                icon: "heart.fill",
                color: "7B2CBF",
                priority: 1
            ),
            isCommitted: true,
            onCommit: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
