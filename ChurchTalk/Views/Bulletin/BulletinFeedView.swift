import SwiftUI

struct BulletinFeedView: View {
    @State private var posts: [BulletinPost] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var impressionTracker = ImpressionTracker()
    @State private var selectedPost: BulletinPost?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading posts...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await fetchPosts() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if posts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "newspaper")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No posts yet")
                            .font(.headline)
                        Text("Check back later for updates from your church")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                BulletinPostCard(post: post, onNavigate: {
                                    selectedPost = post
                                })
                                .onAppear {
                                    // Track impression when post scrolls into view
                                    impressionTracker.trackIfNeeded(postId: post.id)
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        // Reset impressions on refresh
                        impressionTracker.reset()
                        await fetchPosts()
                    }
                    .navigationDestination(item: $selectedPost) { post in
                        BulletinDetailView(post: post, source: .feed)
                    }
                }
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
        .task {
            await fetchPosts()
        }
    }

    private func fetchPosts() async {
        isLoading = posts.isEmpty
        errorMessage = nil

        do {
            let fetchedPosts = try await BulletinAPI.shared.getPosts()
            await MainActor.run {
                posts = fetchedPosts
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load posts: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

struct BulletinPostCard: View {
    let post: BulletinPost
    var onNavigate: (() -> Void)? = nil  // Optional navigation callback
    @State private var userReaction: ReactionType? = nil
    @State private var currentReactions: Reactions

    init(post: BulletinPost, onNavigate: (() -> Void)? = nil) {
        self.post = post
        self.onNavigate = onNavigate
        self._currentReactions = State(initialValue: post.reactions)
        self._userReaction = State(initialValue: post.userReaction)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tappable content area (for navigation) - using Button instead of onTapGesture
            Button(action: {
                onNavigate?()
            }) {
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
                                .foregroundColor(.primary)
                            Text(post.publishedAt.timeAgoDisplay())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                    }

                    // Content
                    Text(post.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Text(post.content.strippingHTML())
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Divider()

            // Reactions Bar - Separate from navigation button
            HStack(spacing: 24) {
                ReactionButton(
                    type: .like,
                    count: currentReactions.like,
                    isSelected: userReaction == .like
                ) {
                    Task { await toggleReaction(.like) }
                }

                ReactionButton(
                    type: .pray,
                    count: currentReactions.pray,
                    isSelected: userReaction == .pray
                ) {
                    Task { await toggleReaction(.pray) }
                }

                ReactionButton(
                    type: .amen,
                    count: currentReactions.amen,
                    isSelected: userReaction == .amen
                ) {
                    Task { await toggleReaction(.amen) }
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

    @State private var isTogglingReaction = false

    private func toggleReaction(_ type: ReactionType) async {
        guard !isTogglingReaction else { return }
        isTogglingReaction = true

        // Optimistic update
        let previousReaction = userReaction
        let previousReactions = currentReactions

        if userReaction == type {
            userReaction = nil
            switch type {
            case .like: currentReactions.like = max(0, currentReactions.like - 1)
            case .pray: currentReactions.pray = max(0, currentReactions.pray - 1)
            case .amen: currentReactions.amen = max(0, currentReactions.amen - 1)
            }
        } else {
            if let prev = previousReaction {
                switch prev {
                case .like: currentReactions.like = max(0, currentReactions.like - 1)
                case .pray: currentReactions.pray = max(0, currentReactions.pray - 1)
                case .amen: currentReactions.amen = max(0, currentReactions.amen - 1)
                }
            }
            userReaction = type
            switch type {
            case .like: currentReactions.like += 1
            case .pray: currentReactions.pray += 1
            case .amen: currentReactions.amen += 1
            }
        }

        do {
            let response = try await BulletinAPI.shared.toggleReaction(
                postId: post.id,
                reactionType: type
            )
            await MainActor.run {
                currentReactions = Reactions(
                    like: response.reactions.like,
                    pray: response.reactions.pray,
                    amen: response.reactions.amen
                )
                // Sync user reaction state with server
                userReaction = response.added ? type : nil
                isTogglingReaction = false
            }
        } catch {
            await MainActor.run {
                userReaction = previousReaction
                currentReactions = previousReactions
                isTogglingReaction = false
            }
        }
    }
}

struct ReactionButton: View {
    let type: ReactionType
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var emoji: String {
        switch type {
        case .like: return "❤️"
        case .pray: return "🙏"
        case .amen: return "🙌"
        }
    }

    var color: Color {
        switch type {
        case .like: return .red
        case .pray: return .purple
        case .amen: return .orange
        }
    }

    var body: some View {
        Button {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            action()
        } label: {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 18))
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isSelected)
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundColor(isSelected ? color : .secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(ReactionButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// Custom button style for reactions to ensure taps are captured
struct ReactionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let now = Date()
        let diffSeconds = Int(now.timeIntervalSince(self))
        let diffMinutes = diffSeconds / 60
        let diffHours = diffMinutes / 60
        let diffDays = diffHours / 24
        let diffWeeks = diffDays / 7
        let diffMonths = diffDays / 30

        if diffSeconds < 60 {
            return "Just now"
        }
        if diffMinutes < 60 {
            return "\(diffMinutes)m ago"
        }
        if diffHours < 24 {
            return "\(diffHours)h ago"
        }
        if diffDays < 7 {
            return "\(diffDays)d ago"
        }
        if diffWeeks < 4 {
            return "\(diffWeeks)w ago"
        }
        if diffMonths < 12 {
            return "\(diffMonths)mo ago"
        }

        // Full date for older posts
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: self)
    }
}

extension String {
    /// Strips HTML tags from the string
    func strippingHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        }

        // Fallback: simple regex stripping
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

#Preview {
    BulletinFeedView()
}
