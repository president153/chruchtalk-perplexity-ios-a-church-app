import SwiftUI

struct BulletinFeedView: View {
    @State private var posts: [BulletinPost] = []

    // Demo data
    let demoPosts: [BulletinPost] = [
        BulletinPost(
            id: "1",
            title: "Sunday Service Highlights",
            content: "What an incredible Sunday! Pastor John shared a powerful message from John 3:16 about God's unconditional love.",
            author: Member(id: "1", firstName: "Pastor", lastName: "John", email: "pastor@church.org", churchId: "1"),
            mediaUrls: [],
            youtubeUrl: "https://youtube.com/watch?v=example",
            publishedAt: Date().addingTimeInterval(-7200),
            reactions: Reactions(like: 42, pray: 18, amen: 25),
            commentCount: 12
        ),
        BulletinPost(
            id: "2",
            title: "Youth Night This Friday!",
            content: "Join us for an amazing night of worship, games, and fellowship! All teens grades 6-12 welcome.",
            author: Member(id: "2", firstName: "Sarah", lastName: "Williams", email: "sarah@church.org", churchId: "1"),
            mediaUrls: [],
            publishedAt: Date().addingTimeInterval(-86400),
            reactions: Reactions(like: 28, pray: 5, amen: 15),
            commentCount: 8
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(demoPosts) { post in
                        NavigationLink(destination: BulletinDetailView(post: post)) {
                            BulletinPostCard(post: post)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.churchTalkRed)
                    }
                }
            }
        }
    }
}

struct BulletinPostCard: View {
    let post: BulletinPost
    @State private var userReaction: ReactionType? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author Header
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.churchTalkRed.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(post.author.initials)
                            .font(.headline)
                            .foregroundColor(.churchTalkRed)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author.fullName)
                        .font(.headline)
                    Text(post.publishedAt.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }

            // Content
            Text(post.title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(post.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)

            // YouTube indicator
            if post.youtubeUrl != nil {
                HStack {
                    Image(systemName: "play.rectangle.fill")
                        .foregroundColor(.red)
                    Text("Watch Video")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            Divider()

            // Reactions Bar
            HStack(spacing: 24) {
                ReactionButton(type: .like, count: post.reactions.like, isSelected: userReaction == .like) {
                    userReaction = userReaction == .like ? nil : .like
                }

                ReactionButton(type: .pray, count: post.reactions.pray, isSelected: userReaction == .pray) {
                    userReaction = userReaction == .pray ? nil : .pray
                }

                ReactionButton(type: .amen, count: post.reactions.amen, isSelected: userReaction == .amen) {
                    userReaction = userReaction == .amen ? nil : .amen
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "message")
                    Text("\(post.commentCount)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

struct ReactionButton: View {
    let type: ReactionType
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var icon: String {
        switch type {
        case .like: return isSelected ? "heart.fill" : "heart"
        case .pray: return "hands.sparkles.fill"
        case .amen: return isSelected ? "checkmark.circle.fill" : "checkmark.circle"
        }
    }

    var color: Color {
        switch type {
        case .like: return .red
        case .pray: return .purple
        case .amen: return .green
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? color : .secondary)
                Text("\(count)")
                    .foregroundColor(isSelected ? color : .secondary)
            }
            .font(.subheadline)
        }
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .day], from: self, to: now)

        if let days = components.day, days > 0 {
            return "\(days)d ago"
        }
        if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        }
        return "Just now"
    }
}

#Preview {
    BulletinFeedView()
}
