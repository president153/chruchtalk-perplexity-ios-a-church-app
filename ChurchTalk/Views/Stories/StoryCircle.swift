//
//  StoryCircle.swift
//  ChurchTalkAdmin
//
//  Individual story circle component with gradient ring
//

import SwiftUI

struct StoryCircle: View {
    let story: Story
    let isViewed: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    // Gradient ring for unviewed stories
                    if !isViewed {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.87, green: 0.25, blue: 0.70),
                                        Color(red: 0.98, green: 0.45, blue: 0.09),
                                        Color(red: 0.99, green: 0.76, blue: 0.24)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 70, height: 70)
                    } else {
                        // Gray ring for viewed stories
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                            .frame(width: 70, height: 70)
                    }

                    // Profile image
                    AsyncImage(url: URL(string: story.authorPhotoUrl ?? "")) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.7)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 64, height: 64)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(Color.managementColor.opacity(0.2))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Text(story.authorName.prefix(1).uppercased())
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.managementColor)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }

                    // "+" badge for create story (optional)
                    // Can add later for admin story creation
                }

                // Author name
                Text(story.authorName)
                    .font(.system(size: 11))
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview
#if DEBUG
struct StoryCircle_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            StoryCircle(story: Story.mockStories()[0], isViewed: false) {}
            StoryCircle(story: Story.mockStories()[1], isViewed: true) {}
        }
        .padding()
        .background(Color.secondaryBackground)
        .previewLayout(.sizeThatFits)
    }
}
#endif
