import SwiftUI

// MARK: - Scroll Offset Tracking

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEventsSheet = false
    @State private var posts: [BulletinPost] = []
    @State private var events: [ChurchEvent] = []
    @State private var featuredMedia: FeaturedMedia?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var selectedPost: BulletinPost?
    @State private var scrollOffset: CGFloat = 0

    var churchName: String {
        authViewModel.currentChurch?.name ?? "Your Church"
    }
    var churchLogoUrl: String? {
        authViewModel.currentChurch?.imageUrl
    }

    // Calculate collapse progress (0 = expanded, 1 = collapsed)
    private var collapseProgress: CGFloat {
        let threshold: CGFloat = 80
        return min(1, max(0, scrollOffset / threshold))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // Scroll offset tracker
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: max(0, -geo.frame(in: .named("scroll")).minY)
                    )
                }
                .frame(height: 0)

                LazyVStack(spacing: 24) {
                    // Quick Actions
                    QuickActionsRow()

                    // Featured/Live Content (only show if available)
                    if let media = featuredMedia {
                        FeaturedContentCard(media: media)
                    }

                    // Upcoming Events
                    if !events.isEmpty {
                        UpcomingEventsCarousel(
                            events: events,
                            onSeeAll: { showEventsSheet = true }
                        )
                    }

                    // Bulletin Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BULLETIN")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .tracking(1)
                            .padding(.horizontal)

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if let error = loadError {
                            VStack(spacing: 12) {
                                Image(systemName: "wifi.exclamationmark")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("Retry") {
                                    Task { await fetchData() }
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else if posts.isEmpty {
                            Text("No posts yet")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(posts) { post in
                                BulletinPostCard(post: post, onNavigate: {
                                    selectedPost = post
                                })
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Bottom padding
                    Color.clear.frame(height: 100)
                }
                .padding(.top, 8)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .safeAreaInset(edge: .top) {
                // STICKY HEADER - fixed at top
                HomeHeaderView(
                    churchName: churchName,
                    churchLogoUrl: churchLogoUrl,
                    collapseProgress: collapseProgress
                )
                .background(.ultraThinMaterial)
            }
            .refreshable {
                await fetchData()
            }
            .sheet(isPresented: $showEventsSheet) {
                EventsTabView()
            }
            .task {
                await fetchData()
            }
            .navigationDestination(item: $selectedPost) { post in
                BulletinDetailView(post: post)
            }
        }
    }

    private func fetchData() async {
        isLoading = true
        loadError = nil

        // Fetch posts, events, and featured media concurrently
        async let postsTask = BulletinAPI.shared.getPosts(limit: 10)
        async let eventsTask = EventsAPI.shared.getUpcomingEvents(limit: 5)
        async let mediaTask = MediaAPI.shared.getFeaturedMedia()

        do {
            let fetchedPosts = try await postsTask
            await MainActor.run {
                posts = fetchedPosts
            }
        } catch {
            print("Failed to fetch posts: \(error)")
            await MainActor.run {
                loadError = "Failed to load bulletin. Check your connection."
            }
        }

        // Events are optional - don't fail if they don't load
        do {
            let fetchedEvents = try await eventsTask
            await MainActor.run {
                events = fetchedEvents
            }
        } catch {
            print("Failed to fetch events: \(error)")
            // Don't set error - events are not critical
        }

        // Featured media is optional - don't fail if it doesn't load
        do {
            let fetchedMedia = try await mediaTask
            await MainActor.run {
                featuredMedia = fetchedMedia
            }
        } catch {
            print("Failed to fetch featured media: \(error)")
            // Don't set error - featured media is not critical
        }

        await MainActor.run {
            isLoading = false
        }
    }
}

struct FeaturedContentCard: View {
    let media: FeaturedMedia

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if media.isLive {
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text("LIVE NOW").font(.caption).fontWeight(.bold).foregroundColor(.red)
                    Text(media.title).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
                .padding(.horizontal)
            }

            Button(action: openMedia) {
                ZStack {
                    if let thumbnailUrl = media.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(16/9, contentMode: .fill)
                        } placeholder: { placeholderView }
                    } else {
                        placeholderView
                    }

                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: media.isLive ? "antenna.radiowaves.left.and.right" : "play.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .offset(x: media.isLive ? 0 : 2)
                        )

                    // Duration badge (if not live)
                    if !media.isLive, let duration = media.formattedDuration {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text(duration)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(4)
                                    .padding(8)
                            }
                        }
                    }
                }
                .frame(height: 180)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .buttonStyle(ScaleButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(media.title).font(.subheadline).fontWeight(.medium).lineLimit(2)
                Text(media.description ?? "Watch the latest message").font(.caption).foregroundColor(.secondary).lineLimit(1)
            }
            .padding(.horizontal)
        }
    }

    private func openMedia() {
        guard let url = media.mediaURL else { return }
        UIApplication.shared.open(url)
    }

    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.churchTalkRed.opacity(0.8), .churchTalkRed.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: media.isLive ? "antenna.radiowaves.left.and.right" : "play.rectangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.9))
                Text(media.isLive ? "Watch Live" : "Watch Latest Message")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
        .frame(height: 180)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
