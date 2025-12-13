import SwiftUI

struct BulletinDetailView: View {
    let post: BulletinPost
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @FocusState private var isCommentFieldFocused: Bool
    @State private var userReaction: ReactionType? = nil

    // Demo comments
    let demoComments: [Comment] = [
        Comment(
            id: "c1",
            content: "Such an inspiring message! Really spoke to my heart.",
            author: Member(id: "1", firstName: "Sarah", lastName: "Williams", email: "sarah@church.org", churchId: "1"),
            createdAt: Date().addingTimeInterval(-1800),
            postId: "1"
        ),
        Comment(
            id: "c2",
            content: "Can't wait for next Sunday!",
            author: Member(id: "2", firstName: "Michael", lastName: "Chen", email: "michael@church.org", churchId: "1"),
            createdAt: Date().addingTimeInterval(-3600),
            postId: "1"
        ),
        Comment(
            id: "c3",
            content: "This message was exactly what I needed to hear today. God's timing is perfect!",
            author: Member(id: "3", firstName: "Emily", lastName: "Johnson", email: "emily@church.org", churchId: "1"),
            createdAt: Date().addingTimeInterval(-7200),
            postId: "1"
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Post Content (expanded)
                    BulletinPostContent(post: post, userReaction: $userReaction)

                    Divider()
                        .padding(.vertical, 8)

                    // Comments Section
                    CommentsSection(comments: comments)
                }
                .padding()
            }

            // Comment Input Bar
            CommentInputBar(
                text: $newCommentText,
                isFocused: $isCommentFieldFocused,
                onSubmit: submitComment
            )
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            comments = demoComments
        }
    }

    private func submitComment() {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let newComment = Comment(
            id: UUID().uuidString,
            content: newCommentText,
            author: Member(id: "current", firstName: "John", lastName: "Doe", email: "john@church.org", churchId: "1"),
            createdAt: Date(),
            postId: post.id
        )

        withAnimation(ChurchTalkAnimations.smooth) {
            comments.insert(newComment, at: 0)
        }

        newCommentText = ""
        isCommentFieldFocused = false

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

struct BulletinPostContent: View {
    let post: BulletinPost
    @Binding var userReaction: ReactionType?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Author Header
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.churchTalkRed.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(post.author.initials)
                            .font(.headline)
                            .foregroundColor(.churchTalkRed)
                    )

                VStack(alignment: .leading, spacing: 4) {
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

            // Title
            Text(post.title)
                .font(.title2)
                .fontWeight(.bold)

            // Full Content
            Text(post.content)
                .font(.body)
                .lineSpacing(4)

            // YouTube Player placeholder
            if let youtubeUrl = post.youtubeUrl {
                YouTubePlaceholder(url: youtubeUrl)
            }

            // Media Gallery
            if !post.mediaUrls.isEmpty {
                MediaGallery(urls: post.mediaUrls)
            }

            Divider()

            // Reactions Bar
            HStack(spacing: 24) {
                DetailReactionButton(type: .like, count: post.reactions.like, isSelected: userReaction == .like) {
                    withAnimation(ChurchTalkAnimations.bouncy) {
                        userReaction = userReaction == .like ? nil : .like
                    }
                }

                DetailReactionButton(type: .pray, count: post.reactions.pray, isSelected: userReaction == .pray) {
                    withAnimation(ChurchTalkAnimations.bouncy) {
                        userReaction = userReaction == .pray ? nil : .pray
                    }
                }

                DetailReactionButton(type: .amen, count: post.reactions.amen, isSelected: userReaction == .amen) {
                    withAnimation(ChurchTalkAnimations.bouncy) {
                        userReaction = userReaction == .amen ? nil : .amen
                    }
                }

                Spacer()
            }
        }
    }
}

struct YouTubePlaceholder: View {
    let url: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ChurchTalkTheme.cornerRadius)
                .fill(Color.black.opacity(0.9))
                .frame(height: 200)

            VStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)

                Text("Watch Video")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .onTapGesture {
            // Open YouTube URL
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

struct MediaGallery: View {
    let urls: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(urls, id: \.self) { url in
                    RoundedRectangle(cornerRadius: ChurchTalkTheme.smallCornerRadius)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
            }
        }
    }
}

struct DetailReactionButton: View {
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
        case .like: return .heartRed
        case .pray: return .churchTalkRed
        case .amen: return .amenGreen
        }
    }

    var label: String {
        switch type {
        case .like: return "Like"
        case .pray: return "Pray"
        case .amen: return "Amen"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? color : .secondary)
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text("\(count + (isSelected ? 1 : 0))")
                    .font(.caption)
                    .foregroundColor(isSelected ? color : .secondary)
            }
            .frame(minWidth: 50)
        }
    }
}

struct CommentsSection: View {
    let comments: [Comment]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comments (\(comments.count))")
                .font(.headline)

            if comments.isEmpty {
                Text("No comments yet. Be the first to comment!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(comments) { comment in
                    CommentCard(comment: comment)
                        .transition(ChurchTalkAnimations.slideUp)
                }
            }
        }
    }
}

struct CommentCard: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.churchTalkRed.opacity(0.15))
                .frame(width: ChurchTalkTheme.avatarSmall, height: ChurchTalkTheme.avatarSmall)
                .overlay(
                    Text(comment.author.initials)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.churchTalkRed)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.author.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(comment.createdAt.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(comment.content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct CommentInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Add a comment...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .focused($isFocused)
                .lineLimit(1...4)

            Button(action: onSubmit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .churchTalkRed)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .padding(.bottom, 80) // Extra padding for floating tab bar
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1),
            alignment: .top
        )
    }
}

#Preview {
    NavigationStack {
        BulletinDetailView(post: BulletinPost(
            id: "1",
            title: "Sunday Service Highlights",
            content: "What an incredible Sunday! Pastor John shared a powerful message from John 3:16 about God's unconditional love. The worship team led us in beautiful praise and we saw three people give their lives to Christ!\n\nJoin us next Sunday as we continue our series on faith and grace.",
            author: Member(id: "1", firstName: "Pastor", lastName: "John", email: "pastor@church.org", churchId: "1"),
            mediaUrls: [],
            youtubeUrl: "https://youtube.com/watch?v=example",
            publishedAt: Date().addingTimeInterval(-7200),
            reactions: Reactions(like: 42, pray: 18, amen: 25),
            commentCount: 12
        ))
    }
}
