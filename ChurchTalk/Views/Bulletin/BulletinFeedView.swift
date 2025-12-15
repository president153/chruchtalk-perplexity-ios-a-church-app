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
            // Tappable content area (for navigation)
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

                Text(post.content.strippingHTML())
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
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onNavigate?()
            }

            Divider()

            // Reactions Bar - NOT in tap area for navigation
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

    private func toggleReaction(_ type: ReactionType) async {
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
            // Remove previous reaction count
            if let prev = previousReaction {
                switch prev {
                case .like: currentReactions.like = max(0, currentReactions.like - 1)
                case .pray: currentReactions.pray = max(0, currentReactions.pray - 1)
                case .amen: currentReactions.amen = max(0, currentReactions.amen - 1)
                }
            }
            // Add new reaction
            userReaction = type
            switch type {
            case .like: currentReactions.like += 1
            case .pray: currentReactions.pray += 1
            case .amen: currentReactions.amen += 1
            }
        }

        // API call
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
            }
        } catch {
            // Revert on error
            await MainActor.run {
                userReaction = previousReaction
                currentReactions = previousReactions
            }
        }
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
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? color : .secondary)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isSelected)
                Text("\(count)")
                    .foregroundColor(isSelected ? color : .secondary)
            }
            .font(.subheadline)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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
