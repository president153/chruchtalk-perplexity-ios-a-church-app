import SwiftUI

struct BulletinDetailView: View {
    let post: BulletinPost
    let viewSource: ViewSource
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @FocusState private var isCommentFieldFocused: Bool
    @State private var userReaction: ReactionType? = nil
    @State private var currentReactions: Reactions

    // Loading states
    @State private var isLoadingComments = true
    @State private var isSubmittingComment = false
    @State private var isTogglingReaction = false
    @State private var errorMessage: String?

    // Reply state
    @State private var replyingTo: Comment? = nil

    // View tracking
    @State private var viewTracker: PostViewTracker?
    @State private var viewStartTime: Date?

    init(post: BulletinPost, source: ViewSource = .feed) {
        self.post = post
        self.viewSource = source
        _currentReactions = State(initialValue: post.reactions)
        _userReaction = State(initialValue: post.userReaction)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Post Content (expanded)
                    BulletinPostContent(
                        post: post,
                        userReaction: $userReaction,
                        currentReactions: $currentReactions,
                        isTogglingReaction: $isTogglingReaction,
                        onReactionToggle: toggleReaction
                    )

                    Divider()
                        .padding(.vertical, 8)

                    // Comments Section
                    CommentsSection(
                        comments: comments,
                        isLoading: isLoadingComments,
                        errorMessage: errorMessage,
                        onReply: { comment in
                            replyingTo = comment
                            isCommentFieldFocused = true
                        }
                    )
                }
                .padding()
            }
            .refreshable {
                await loadComments()
            }

            // Comment Input Bar
            CommentInputBar(
                text: $newCommentText,
                isFocused: $isCommentFieldFocused,
                isSubmitting: isSubmittingComment,
                replyingTo: replyingTo,
                onCancelReply: { replyingTo = nil },
                onSubmit: submitComment
            )
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(
                    item: post.title,
                    subject: Text(post.title),
                    message: Text(post.content.prefix(200) + "...")
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .task {
            await loadComments()
        }
        .onAppear {
            // Start tracking view
            viewTracker = PostViewTracker(postId: post.id, source: viewSource)
            viewTracker?.startTracking()
            viewStartTime = Date()
        }
        .onDisappear {
            // Stop tracking and record duration
            let scrolledToBottom = false // Could track this with scroll position
            viewTracker?.stopTracking(completed: scrolledToBottom)
        }
    }

    private func loadComments() async {
        isLoadingComments = true
        errorMessage = nil

        do {
            let fetchedComments = try await BulletinAPI.shared.getComments(postId: post.id)
            await MainActor.run {
                comments = fetchedComments
                isLoadingComments = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load comments"
                isLoadingComments = false
            }
        }
    }

    private func submitComment() {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isSubmittingComment = true
        let commentContent = newCommentText
        let parentComment = replyingTo
        newCommentText = ""
        replyingTo = nil
        isCommentFieldFocused = false

        Task {
            do {
                let newComment = try await BulletinAPI.shared.createComment(
                    postId: post.id,
                    content: commentContent,
                    parentId: parentComment?.id
                )

                await MainActor.run {
                    withAnimation(ChurchTalkAnimations.smooth) {
                        if let parentId = parentComment?.id,
                           let parentIndex = comments.firstIndex(where: { $0.id == parentId }) {
                            // Add as reply to parent comment
                            comments[parentIndex].replies.append(newComment)
                        } else {
                            // Add as top-level comment
                            comments.insert(newComment, at: 0)
                        }
                    }
                    isSubmittingComment = false

                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    newCommentText = commentContent // Restore text on failure
                    replyingTo = parentComment // Restore reply state
                    isSubmittingComment = false

                    // Error haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }

    private func toggleReaction(_ type: ReactionType) {
        guard !isTogglingReaction else { return }

        isTogglingReaction = true

        // Optimistic update
        let previousReaction = userReaction
        let previousReactions = currentReactions

        withAnimation(ChurchTalkAnimations.bouncy) {
            if userReaction == type {
                userReaction = nil
                // Decrement reaction count
                switch type {
                case .like: currentReactions = Reactions(like: max(0, currentReactions.like - 1), pray: currentReactions.pray, amen: currentReactions.amen)
                case .pray: currentReactions = Reactions(like: currentReactions.like, pray: max(0, currentReactions.pray - 1), amen: currentReactions.amen)
                case .amen: currentReactions = Reactions(like: currentReactions.like, pray: currentReactions.pray, amen: max(0, currentReactions.amen - 1))
                }
            } else {
                // Remove previous reaction if exists
                if let prev = userReaction {
                    switch prev {
                    case .like: currentReactions = Reactions(like: max(0, currentReactions.like - 1), pray: currentReactions.pray, amen: currentReactions.amen)
                    case .pray: currentReactions = Reactions(like: currentReactions.like, pray: max(0, currentReactions.pray - 1), amen: currentReactions.amen)
                    case .amen: currentReactions = Reactions(like: currentReactions.like, pray: currentReactions.pray, amen: max(0, currentReactions.amen - 1))
                    }
                }

                userReaction = type
                // Increment new reaction count
                switch type {
                case .like: currentReactions = Reactions(like: currentReactions.like + 1, pray: currentReactions.pray, amen: currentReactions.amen)
                case .pray: currentReactions = Reactions(like: currentReactions.like, pray: currentReactions.pray + 1, amen: currentReactions.amen)
                case .amen: currentReactions = Reactions(like: currentReactions.like, pray: currentReactions.pray, amen: currentReactions.amen + 1)
                }
            }
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        Task {
            do {
                let response = try await BulletinAPI.shared.toggleReaction(postId: post.id, reactionType: type)

                await MainActor.run {
                    // Update with server response
                    currentReactions = Reactions(
                        like: response.reactions.like,
                        pray: response.reactions.pray,
                        amen: response.reactions.amen
                    )
                    isTogglingReaction = false
                }
            } catch {
                await MainActor.run {
                    // Revert optimistic update on error
                    userReaction = previousReaction
                    currentReactions = previousReactions
                    isTogglingReaction = false

                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
}

struct BulletinPostContent: View {
    let post: BulletinPost
    @Binding var userReaction: ReactionType?
    @Binding var currentReactions: Reactions
    @Binding var isTogglingReaction: Bool
    let onReactionToggle: (ReactionType) -> Void

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

                Menu {
                    Button(action: {}) {
                        Label("Report Post", systemImage: "flag")
                    }
                    Button(action: {}) {
                        Label("Copy Link", systemImage: "link")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }

            // Title
            Text(post.title)
                .font(.title2)
                .fontWeight(.bold)

            // Full Content
            Text(post.content.strippingHTML())
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
                DetailReactionButton(
                    type: .like,
                    count: currentReactions.like,
                    isSelected: userReaction == .like,
                    isLoading: isTogglingReaction && userReaction == .like,
                    action: { onReactionToggle(.like) }
                )

                DetailReactionButton(
                    type: .pray,
                    count: currentReactions.pray,
                    isSelected: userReaction == .pray,
                    isLoading: isTogglingReaction && userReaction == .pray,
                    action: { onReactionToggle(.pray) }
                )

                DetailReactionButton(
                    type: .amen,
                    count: currentReactions.amen,
                    isSelected: userReaction == .amen,
                    isLoading: isTogglingReaction && userReaction == .amen,
                    action: { onReactionToggle(.amen) }
                )

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
                ForEach(urls, id: \.self) { urlString in
                    AsyncImage(url: URL(string: urlString)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: ChurchTalkTheme.smallCornerRadius)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 150, height: 150)
                                .overlay(ProgressView())

                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: ChurchTalkTheme.smallCornerRadius))

                        case .failure:
                            RoundedRectangle(cornerRadius: ChurchTalkTheme.smallCornerRadius)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 150, height: 150)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )

                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
        }
    }
}

struct DetailReactionButton: View {
    let type: ReactionType
    let count: Int
    let isSelected: Bool
    var isLoading: Bool = false
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
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(height: 24)
                } else {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? color : .secondary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }

                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(isSelected ? color : .secondary)
            }
            .frame(minWidth: 50)
        }
        .disabled(isLoading)
    }
}

struct CommentsSection: View {
    let comments: [Comment]
    let isLoading: Bool
    let errorMessage: String?
    var onReply: ((Comment) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comments (\(comments.count))")
                .font(.headline)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if let error = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if comments.isEmpty {
                Text("No comments yet. Be the first to comment!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(comments) { comment in
                    CommentCard(comment: comment, onReply: onReply)
                        .transition(ChurchTalkAnimations.slideUp)
                }
            }
        }
    }
}

struct CommentCard: View {
    let comment: Comment
    var onReply: ((Comment) -> Void)? = nil
    var isReply: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.churchTalkRed.opacity(0.15))
                    .frame(width: isReply ? 28 : ChurchTalkTheme.avatarSmall, height: isReply ? 28 : ChurchTalkTheme.avatarSmall)
                    .overlay(
                        Text(comment.author.initials)
                            .font(isReply ? .caption2 : .caption)
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

                    // Reply button (only for top-level comments)
                    if !isReply, let onReply = onReply {
                        Button(action: { onReply(comment) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                Text("Reply")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(ChurchTalkTheme.cornerRadius)

            // Show nested replies
            if !comment.replies.isEmpty {
                ForEach(comment.replies) { reply in
                    CommentCard(comment: reply, isReply: true)
                        .padding(.leading, 32)
                }
            }
        }
    }
}

struct CommentInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var isSubmitting: Bool = false
    var replyingTo: Comment? = nil
    var onCancelReply: (() -> Void)? = nil
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Reply indicator
            if let comment = replyingTo {
                HStack {
                    Text("Replying to ")
                        .foregroundColor(.secondary)
                    + Text("@\(comment.author.fullName)")
                        .foregroundColor(.churchTalkRed)
                        .fontWeight(.medium)

                    Spacer()

                    Button(action: { onCancelReply?() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .font(.caption)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }

            HStack(spacing: 12) {
                TextField(replyingTo != nil ? "Write a reply..." : "Add a comment...", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isFocused)
                    .lineLimit(1...4)
                    .disabled(isSubmitting)

                Button(action: onSubmit) {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .churchTalkRed)
                    }
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
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
        BulletinDetailView(
            post: BulletinPost(
                id: "1",
                title: "Sunday Service Highlights",
                content: "What an incredible Sunday! Pastor John shared a powerful message from John 3:16 about God's unconditional love. The worship team led us in beautiful praise and we saw three people give their lives to Christ!\n\nJoin us next Sunday as we continue our series on faith and grace.",
                author: Member(id: "1", firstName: "Pastor", lastName: "John", email: "pastor@church.org", churchId: "1"),
                mediaUrls: [],
                youtubeUrl: "https://youtube.com/watch?v=example",
                publishedAt: Date().addingTimeInterval(-7200),
                reactions: Reactions(like: 42, pray: 18, amen: 25),
                commentCount: 12
            ),
            source: .feed
        )
    }
}
