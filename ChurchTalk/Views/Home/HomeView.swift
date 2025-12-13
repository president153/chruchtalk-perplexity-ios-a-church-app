import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEventsSheet = false
    @State private var isRefreshing = false

    // Demo data - would come from ViewModel/API
    let churchName = "Grace Community Church"
    let churchLogoUrl: String? = nil

    let demoEvents: [ChurchEvent] = [
        ChurchEvent(
            id: "1",
            churchId: "1",
            title: "Christmas Eve Service",
            description: "Join us for a special candlelight service celebrating the birth of Christ.",
            startDate: Date().addingTimeInterval(86400 * 11),
            isAllDay: false,
            isVirtual: false,
            requiresRegistration: true,
            currentRegistrations: 156,
            category: .worship,
            tags: ["christmas", "special"],
            volunteerRoles: [],
            createdAt: Date(),
            isPublished: true,
            isFeatured: true,
        ),
        ChurchEvent(
            id: "2",
            churchId: "1",
            title: "Youth Night",
            description: "Games, worship, and fellowship for grades 6-12",
            startDate: Date().addingTimeInterval(86400 * 2),
            isAllDay: false,
            isVirtual: false,
            requiresRegistration: false,
            currentRegistrations: 0,
            category: .youth,
            tags: ["youth"],
            volunteerRoles: [],
            createdAt: Date(),
            isPublished: true,
            isFeatured: false,
        ),
        ChurchEvent(
            id: "3",
            churchId: "1",
            title: "Small Group Leaders Meeting",
            description: "Monthly gathering for small group leaders",
            startDate: Date().addingTimeInterval(86400 * 5),
            isAllDay: false,
            isVirtual: false,
            requiresRegistration: true,
            currentRegistrations: 12,
            category: .smallGroup,
            tags: ["leaders"],
            volunteerRoles: [],
            createdAt: Date(),
            isPublished: true,
            isFeatured: false,
        )
    ]

    let demoPosts: [BulletinPost] = [
        BulletinPost(
            id: "1",
            title: "Sunday Service Highlights",
            content: "What an incredible Sunday! Pastor John shared a powerful message from John 3:16 about God's unconditional love. If you missed it, the recording will be available soon.",
            author: Member(id: "1", firstName: "Pastor", lastName: "John", email: "pastor@church.org", churchId: "1"),
            mediaUrls: [],
            youtubeUrl: "https://youtube.com/watch?v=example",
            publishedAt: Date().addingTimeInterval(-7200),
            reactions: Reactions(like: 42, pray: 18, amen: 25),
            commentCount: 12
        ),
        BulletinPost(
            id: "2",
            title: "Volunteer Appreciation Dinner",
            content: "Thank you to all our amazing volunteers! You are the backbone of our ministry. Join us for a special appreciation dinner next Saturday.",
            author: Member(id: "2", firstName: "Sarah", lastName: "Williams", email: "sarah@church.org", churchId: "1"),
            mediaUrls: [],
            publishedAt: Date().addingTimeInterval(-86400),
            reactions: Reactions(like: 28, pray: 5, amen: 15),
            commentCount: 8
        ),
        BulletinPost(
            id: "3",
            title: "New Small Groups Starting",
            content: "We're launching new small groups in January! Whether you're interested in Bible study, prayer groups, or fellowship, there's a place for you.",
            author: Member(id: "3", firstName: "Mike", lastName: "Johnson", email: "mike@church.org", churchId: "1"),
            mediaUrls: [],
            publishedAt: Date().addingTimeInterval(-172800),
            reactions: Reactions(like: 35, pray: 12, amen: 20),
            commentCount: 15
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with church name and date
                    HomeHeaderView(
                        churchName: churchName,
                        churchLogoUrl: churchLogoUrl
                    )

                    // Quick Actions
                    QuickActionsRow()

                    // Featured/Live Content (if available)
                    FeaturedContentCard()

                    // Upcoming Events Carousel
                    UpcomingEventsCarousel(
                        events: demoEvents,
                        onSeeAll: { showEventsSheet = true }
                    )

                    // Announcements Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ANNOUNCEMENTS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .tracking(1)
                            .padding(.horizontal)

                        LazyVStack(spacing: 16) {
                            ForEach(demoPosts) { post in
                                NavigationLink(destination: BulletinDetailView(post: post)) {
                                    BulletinPostCard(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Bottom padding
                    Spacer()
                        .frame(height: 20)
                }
            }
            .refreshable {
                await refreshContent()
            }
            .sheet(isPresented: $showEventsSheet) {
                EventsTabView()
            }
        }
    }

    private func refreshContent() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // Refresh data from API
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
