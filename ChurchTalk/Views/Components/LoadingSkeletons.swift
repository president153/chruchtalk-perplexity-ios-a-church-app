//
//  LoadingSkeletons.swift
//  ChurchTalkAdmin
//
//  Reusable loading skeleton components for better perceived performance
//

import SwiftUI

// MARK: - Base Skeleton Shape

struct SkeletonShape: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var isAnimating = false

    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.15),
                        Color.gray.opacity(0.25),
                        Color.gray.opacity(0.15)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Member Row Skeleton

struct SkeletonMemberRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )

            // Text content
            VStack(alignment: .leading, spacing: 8) {
                SkeletonShape(width: 140, height: 14, cornerRadius: 7)
                SkeletonShape(width: 100, height: 12, cornerRadius: 6)
            }

            Spacer()

            // Trailing badge
            SkeletonShape(width: 60, height: 24, cornerRadius: 12)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Fund Type Card Skeleton

struct SkeletonFundTypeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 6) {
                    SkeletonShape(width: 120, height: 16, cornerRadius: 8)
                    SkeletonShape(width: 80, height: 12, cornerRadius: 6)
                }

                Spacer()
            }

            // Description
            VStack(alignment: .leading, spacing: 6) {
                SkeletonShape(height: 12, cornerRadius: 6)
                SkeletonShape(width: 200, height: 12, cornerRadius: 6)
            }

            Divider()
                .background(Color.gray.opacity(0.1))

            // Footer badges
            HStack(spacing: 8) {
                SkeletonShape(width: 90, height: 22, cornerRadius: 11)
                SkeletonShape(width: 100, height: 22, cornerRadius: 11)
                Spacer()
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Dashboard Card Skeleton

struct SkeletonDashboardCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                SkeletonShape(width: 140, height: 20, cornerRadius: 10)
                Spacer()
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
            }

            // Stats
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonShape(width: 60, height: 28, cornerRadius: 8)
                    SkeletonShape(width: 80, height: 12, cornerRadius: 6)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    SkeletonShape(width: 60, height: 28, cornerRadius: 8)
                    SkeletonShape(width: 80, height: 12, cornerRadius: 6)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - List Skeleton

struct SkeletonList: View {
    let itemCount: Int
    let itemType: SkeletonType

    init(itemCount: Int = 5, itemType: SkeletonType = .memberRow) {
        self.itemCount = itemCount
        self.itemType = itemType
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<itemCount, id: \.self) { index in
                itemView(for: itemType)
                    .transition(.opacity)
                    .animation(
                        .easeInOut(duration: 0.3)
                        .delay(Double(index) * 0.05),
                        value: index
                    )
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func itemView(for type: SkeletonType) -> some View {
        switch type {
        case .memberRow:
            SkeletonMemberRow()
        case .fundTypeCard:
            SkeletonFundTypeCard()
        case .postCard:
            SkeletonPostCard()
        case .dashboardCard:
            SkeletonDashboardCard()
        }
    }

    enum SkeletonType {
        case memberRow
        case fundTypeCard
        case postCard
        case dashboardCard
    }
}

// MARK: - Generic Loading View

struct LoadingView: View {
    let message: String

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .churchPrimary))

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Skeleton Post Card

struct SkeletonPostCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with author
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 6) {
                    SkeletonShape(width: 100, height: 14, cornerRadius: 7)
                    SkeletonShape(width: 80, height: 10, cornerRadius: 5)
                }

                Spacer()

                SkeletonShape(width: 60, height: 20, cornerRadius: 10)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                SkeletonShape(height: 12, cornerRadius: 6)
                SkeletonShape(height: 12, cornerRadius: 6)
                SkeletonShape(width: 180, height: 12, cornerRadius: 6)
            }

            // Footer actions
            HStack(spacing: 20) {
                SkeletonShape(width: 50, height: 20, cornerRadius: 10)
                SkeletonShape(width: 50, height: 20, cornerRadius: 10)
                Spacer()
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// Note: ShimmerModifier is defined in Animations.swift

// MARK: - Preview
#if DEBUG
struct LoadingSkeletons_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Member Row Skeleton")
                        .font(.headline)
                    SkeletonMemberRow()

                    Text("Fund Type Card Skeleton")
                        .font(.headline)
                        .padding(.top)
                    SkeletonFundTypeCard()

                    Text("Dashboard Card Skeleton")
                        .font(.headline)
                        .padding(.top)
                    SkeletonDashboardCard()
                }
                .padding()
            }
            .background(Color.secondaryBackground)
            .previewDisplayName("Skeletons")

            SkeletonList(itemCount: 3, itemType: .memberRow)
                .background(Color.secondaryBackground)
                .previewDisplayName("Member List Skeleton")

            LoadingView(message: "Loading members...")
                .previewDisplayName("Loading View")
                .preferredColorScheme(.dark)
        }
    }
}
#endif
