//
//  EmptyStateView.swift
//  ChurchTalkAdmin
//
//  Reusable empty state component for consistent UX
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    let iconColor: Color

    init(
        icon: String,
        title: String,
        message: String,
        iconColor: Color = .gray,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.iconColor = iconColor
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(iconColor.opacity(0.4))
                .scaleEffect(animationScale)
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.6)
                    .repeatForever(autoreverses: true),
                    value: animationScale
                )
                .onAppear {
                    animationScale = 1.05
                }

            // Text content
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Optional action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.shared.buttonTap()
                    action()
                }) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(iconColor)
                        .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    @State private var animationScale: CGFloat = 1.0
}

// MARK: - Convenience Initializers for Common Empty States

extension EmptyStateView {
    /// Empty state for no members
    static func noMembers(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "person.3.fill",
            title: "No Members Yet",
            message: "Members will appear here once they join your church",
            iconColor: .srmColor,
            actionTitle: action != nil ? "Invite Members" : nil,
            action: action
        )
    }

    /// Empty state for no posts
    static func noPosts(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "newspaper.fill",
            title: "No Posts Yet",
            message: "Start engaging your congregation by creating your first bulletin post",
            iconColor: .managementColor,
            actionTitle: action != nil ? "Create Post" : nil,
            action: action
        )
    }

    /// Empty state for no search results
    static func noSearchResults(searchTerm: String = "") -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: searchTerm.isEmpty
                ? "Try adjusting your search or filters"
                : "No results found for \"\(searchTerm)\"",
            iconColor: .gray
        )
    }

    /// Empty state for no fund types
    static func noFundTypes(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "folder.fill.badge.plus",
            title: "No Fund Types",
            message: "Create fund categories to organize and track donations",
            iconColor: .financeColor,
            actionTitle: action != nil ? "Create Fund Type" : nil,
            action: action
        )
    }

    /// Empty state for no donations
    static func noDonations() -> EmptyStateView {
        EmptyStateView(
            icon: "heart.fill",
            title: "No Donations Yet",
            message: "Donations and giving history will appear here",
            iconColor: .financeColor
        )
    }

    /// Empty state for no events
    static func noEvents(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "calendar",
            title: "No Events",
            message: "Create events to keep your congregation informed",
            iconColor: .engagementColor,
            actionTitle: action != nil ? "Create Event" : nil,
            action: action
        )
    }

    /// Empty state for no stories
    static func noStories(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "photo.on.rectangle.angled",
            title: "No Stories",
            message: "Share moments with your congregation through stories",
            iconColor: .engagementColor,
            actionTitle: action != nil ? "Create Story" : nil,
            action: action
        )
    }

    /// Empty state for filtered results
    static func noFilteredResults(filterDescription: String = "these filters") -> EmptyStateView {
        EmptyStateView(
            icon: "line.3.horizontal.decrease.circle",
            title: "No Matches",
            message: "No items match \(filterDescription). Try adjusting your filters.",
            iconColor: .gray
        )
    }

    /// Empty state for network issues
    static func networkError(retry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.exclamationmark",
            title: "No Connection",
            message: "Check your internet connection and try again",
            iconColor: .orange,
            actionTitle: "Try Again",
            action: retry
        )
    }
}

// MARK: - Preview
#if DEBUG
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmptyStateView.noMembers()
                .previewDisplayName("No Members")

            EmptyStateView.noPosts(action: {})
                .previewDisplayName("No Posts with Action")

            EmptyStateView.noSearchResults(searchTerm: "John")
                .previewDisplayName("No Search Results")

            EmptyStateView.noFundTypes(action: {})
                .previewDisplayName("No Fund Types")
                .preferredColorScheme(.dark)
        }
    }
}
#endif
