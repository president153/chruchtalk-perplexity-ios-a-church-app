import SwiftUI

struct BulletinDetailView: View {
    let post: BulletinPost
    let viewSource: ViewSource
    @EnvironmentObject var authViewModel: AuthViewModel
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

    // Auth helpers
    var isAdmin: Bool {
        authViewModel.currentMember?.isAdmin == true
    }

    var currentUserId: String? {
        authViewModel.currentMember?.id
    }

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
                        isAdmin: isAdmin,
                        currentUserId: currentUserId,
                        onReply: { comment in
                            replyingTo = comment
                            isCommentFieldFocused = true
                        },
                        onDelete: { comment in
                            deleteComment(comment)
                        },
                        onRetry: {
                            Task { await loadComments() }
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
            .padding(.bottom, 90) // Account for floating tab bar
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
            print("Failed to load comments: \(error)")
            await MainActor.run {
                if let apiError = error as? APIError {
                    errorMessage = apiError.errorDescription ?? "Failed to load comments"
                } else {
                    errorMessage = "Failed to load comments"
                }
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

    private func deleteComment(_ comment: Comment) {
        Task {
            do {
                try await BulletinAPI.shared.deleteComment(postId: post.id, commentId: comment.id)
                await MainActor.run {
                    // Remove from local state
                    if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                        _ = withAnimation {
                            comments.remove(at: index)
                        }
                    } else {
                        // Check if it's a reply
                        for i in comments.indices {
                            if let replyIndex = comments[i].replies.firstIndex(where: { $0.id == comment.id }) {
                                _ = withAnimation {
                                    comments[i].replies.remove(at: replyIndex)
                                }
                                break
                            }
                        }
                    }

                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }

    private func toggleReaction(_ type: ReactionType) {
        guard !isTogglingReaction else { return }
        isTogglingReaction = true

        // Optimistic update - no withAnimation to avoid AttributeGraph cycle
        let previousReaction = userReaction
        let previousReactions = currentReactions

        if userReaction == type {
            // Removing reaction
            userReaction = nil
            switch type {
            case .like: currentReactions = Reactions(like: max(0, currentReactions.like - 1), pray: currentReactions.pray, amen: currentReactions.amen)
            case .pray: currentReactions = Reactions(like: currentReactions.like, pray: max(0, currentReactions.pray - 1), amen: currentReactions.amen)
            case .amen: currentReactions = Reactions(like: currentReactions.like, pray: currentReactions.pray, amen: max(0, currentReactions.amen - 1))
            }
        } else {
            // Remove previous reaction if switching
            if let prev = userReaction {
                switch prev {
                case .like: currentReactions = Reactions(like: max(0, currentReactions.like - 1), pray: currentReactions.pray, amen: currentReactions.amen)
                case .pray: currentReactions = Reactions(like: currentReactions.like, pray: max(0, currentReactions.pray - 1), amen: currentReactions.amen)
                case .amen: currentReactions = Reactions(like: currentReactions.like, pray: currentReactions.pray, amen: max(0, currentReactions.amen - 1))
                }
            }
            // Add new reaction
            userReaction = type
            switch type {
            case .like: currentReactions = Reactions(like: currentReactions.like + 1, pray: currentReactions.pray, amen: currentReactions.amen)
            case .pray: currentReactions = Reactions(like: currentReactions.like, pray: currentReactions.pray + 1, amen: currentReactions.amen)
            case .amen: currentReactions = Reactions(like: currentReactions.like, pray: currentReactions.pray, amen: currentReactions.amen + 1)
            }
        }

        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        Task {
            do {
                let response = try await BulletinAPI.shared.toggleReaction(postId: post.id, reactionType: type)
                await MainActor.run {
                    // Sync with server - use `added` to determine user's reaction state
                    currentReactions = Reactions(
                        like: response.reactions.like,
                        pray: response.reactions.pray,
                        amen: response.reactions.amen
                    )
                    // If server says reaction was added, user has this reaction; if removed, user has none
                    userReaction = response.added ? type : nil
                    isTogglingReaction = false
                }
            } catch {
                await MainActor.run {
                    // Revert on error
                    userReaction = previousReaction
                    currentReactions = previousReactions
                    isTogglingReaction = false
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

            // Reactions Bar - No loading spinners, just instant optimistic updates
            HStack(spacing: 24) {
                DetailReactionButton(
                    type: .like,
                    count: currentReactions.like,
                    isSelected: userReaction == .like,
                    action: { onReactionToggle(.like) }
                )

                DetailReactionButton(
                    type: .pray,
                    count: currentReactions.pray,
                    isSelected: userReaction == .pray,
                    action: { onReactionToggle(.pray) }
                )

                DetailReactionButton(
                    type: .amen,
                    count: currentReactions.amen,
                    isSelected: userReaction == .amen,
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
        case .like: return .heartRed
        case .pray: return .churchTalkRed
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
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 24))
                    .scaleEffect(isSelected ? 1.2 : 1.0)

                Text("\(count)")
                    .font(.subheadline)
                    .foregroundColor(isSelected ? color : .secondary)
            }
            .frame(minWidth: 60)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(DetailReactionButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// Custom button style for detail reaction buttons
struct DetailReactionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CommentsSection: View {
    let comments: [Comment]
    let isLoading: Bool
    let errorMessage: String?
    var isAdmin: Bool = false
    var currentUserId: String? = nil
    var onReply: ((Comment) -> Void)? = nil
    var onDelete: ((Comment) -> Void)? = nil
    var onRetry: (() -> Void)? = nil

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
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
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    if let onRetry = onRetry {
                        Button("Retry") {
                            onRetry()
                        }
                        .buttonStyle(.bordered)
                    }
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
                    CommentCard(
                        comment: comment,
                        onReply: onReply,
                        onDelete: onDelete,
                        isAdmin: isAdmin,
                        currentUserId: currentUserId
                    )
                    .transition(ChurchTalkAnimations.slideUp)
                }
            }
        }
    }
}

struct CommentCard: View {
    let comment: Comment
    var onReply: ((Comment) -> Void)? = nil
    var onDelete: ((Comment) -> Void)? = nil
    var isAdmin: Bool = false
    var currentUserId: String? = nil
    var isReply: Bool = false

    var isOwnComment: Bool {
        guard let userId = currentUserId else { return false }
        return comment.author.id == userId
    }

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

                    // Action buttons
                    HStack(spacing: 16) {
                        // Reply button - ONLY for admins on top-level comments
                        if !isReply && isAdmin, let onReply = onReply {
                            Button(action: { onReply(comment) }) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Delete button - for own comments OR admins
                        if (isOwnComment || isAdmin), let onDelete = onDelete {
                            Button(action: { onDelete(comment) }) {
                                Image(systemName: "trash")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(ChurchTalkTheme.cornerRadius)

            // Show nested replies
            if !comment.replies.isEmpty {
                ForEach(comment.replies) { reply in
                    CommentCard(
                        comment: reply,
                        onDelete: onDelete,
                        isAdmin: isAdmin,
                        currentUserId: currentUserId,
                        isReply: true
                    )
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
