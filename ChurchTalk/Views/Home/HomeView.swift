import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEventsSheet = false
    @State private var isRefreshing = false
    @State private var posts: [BulletinPost] = []
    @State private var events: [ChurchEvent] = []
    @State private var isLoading = true
    @State private var selectedPost: BulletinPost?

    var churchName: String {
        authViewModel.currentChurch?.name ?? "Your Church"
    }
    var churchLogoUrl: String? {
        authViewModel.currentChurch?.imageUrl
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                    // Main content section with sticky header
                    Section {
                        // Quick Actions
                        QuickActionsRow()

                        // Featured/Live Content (if available)
                        FeaturedContentCard()

                        // Upcoming Events Carousel
                        if !events.isEmpty {
                            UpcomingEventsCarousel(
                                events: events,
                                onSeeAll: { showEventsSheet = true }
                            )
                        }

                        // Announcements Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ANNOUNCEMENTS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .tracking(1)
                                .padding(.horizontal)

                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if posts.isEmpty {
                                Text("No announcements yet")
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

                        // Bottom padding for floating tab bar
                        Spacer()
                            .frame(height: 100)
                    } header: {
                        // Sticky Church Header with solid background
                        VStack(spacing: 0) {
                            HomeHeaderView(
                                churchName: churchName,
                                churchLogoUrl: churchLogoUrl
                            )
                            .padding(.bottom, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .background(
                            Color(.systemBackground)
                                .ignoresSafeArea(edges: .top)
                        )
                    }
                }
            }
            .refreshable {
                await refreshContent()
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
        do {
            let fetchedPosts = try await BulletinAPI.shared.getPosts(limit: 10)
            await MainActor.run {
                posts = fetchedPosts
                isLoading = false
            }
        } catch {
            print("Failed to fetch posts: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func refreshContent() async {
        await fetchData()
    }
}

struct FeaturedContentCard: View {
    // Demo: Show featured video or livestream
    let isLive = false
    let featuredVideoTitle = "Sunday Service - December 10"
    let featuredVideoThumbnail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Live Badge (if streaming)
            if isLive {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)

                    Text("LIVE NOW")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)

                    Text("Sunday Service")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }

            // Video Thumbnail
            Button(action: {
                // Open video player
            }) {
                ZStack {
                    // Thumbnail
                    if let thumbnailUrl = featuredVideoThumbnail, let url = URL(string: thumbnailUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        } placeholder: {
                            placeholderView
                        }
                    } else {
                        placeholderView
                    }

                    // Play Button Overlay
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .offset(x: 2)
                        )
                }
                .frame(height: 180)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .buttonStyle(ScaleButtonStyle())

            // Video Info
            VStack(alignment: .leading, spacing: 4) {
                Text(featuredVideoTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Watch the latest message")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }

    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.churchTalkRed.opacity(0.8), .churchTalkRed.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.9))

                Text("Watch Latest Message")
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
