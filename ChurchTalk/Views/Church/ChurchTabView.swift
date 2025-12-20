//
//  ChurchTabView.swift
//  ChurchTalk
//
//  Combined Church tab - merges Home, Connect, and Serve into one simplified view.
//  Quick access to everything happening at your church.
//

import SwiftUI

struct ChurchTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedSection: ChurchSection = .home

    enum ChurchSection: String, CaseIterable {
        case home = "Home"
        case prayer = "Prayer"
        case connect = "Connect"
        case serve = "Serve"
        case outreach = "Outreach"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .prayer: return "hands.sparkles.fill"
            case .connect: return "person.2.fill"
            case .serve: return "heart.fill"
            case .outreach: return "figure.walk"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section Picker - Horizontal scroll pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ChurchSection.allCases, id: \.self) { section in
                            SectionPill(
                                title: section.rawValue,
                                icon: section.icon,
                                isSelected: selectedSection == section
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSection = section
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))

                // Content
                TabView(selection: $selectedSection) {
                    // Home Section
                    HomeContentView()
                        .tag(ChurchSection.home)

                    // Prayer Section
                    PrayerContentView()
                        .tag(ChurchSection.prayer)

                    // Connect Section
                    ConnectContentView()
                        .tag(ChurchSection.connect)

                    // Serve Section
                    ServeContentView()
                        .tag(ChurchSection.serve)

                    // Outreach Section
                    OutreachContentView()
                        .tag(ChurchSection.outreach)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Church")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Section Pill

struct SectionPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.churchTalkRed : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Home Content

struct HomeContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var posts: [BulletinPost] = []
    @State private var events: [ChurchEvent] = []
    @State private var featuredMedia: FeaturedMedia?
    @State private var isLoading = true

    var churchName: String {
        authViewModel.currentChurch?.name ?? "Your Church"
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Featured Media
                if let media = featuredMedia {
                    FeaturedMediaCard(media: media)
                        .padding(.horizontal)
                }

                // Upcoming Events
                if !events.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ChurchSectionHeader(title: "Upcoming Events", icon: "calendar")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(events.prefix(5)) { event in
                                    CompactEventCard(event: event)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Bulletin
                if !posts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ChurchSectionHeader(title: "Bulletin", icon: "newspaper.fill")

                        ForEach(posts.prefix(5)) { post in
                            CompactBulletinCard(post: post)
                                .padding(.horizontal)
                        }
                    }
                }

                // Loading State
                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                }

                // Bottom padding
                Color.clear.frame(height: 100)
            }
            .padding(.top, 16)
        }
        .refreshable {
            await fetchData()
        }
        .task {
            await fetchData()
        }
    }

    private func fetchData() async {
        isLoading = true

        async let postsTask = BulletinAPI.shared.getPosts(limit: 5)
        async let eventsTask = EventsAPI.shared.getUpcomingEvents(limit: 5)
        async let mediaTask = MediaAPI.shared.getFeaturedMedia()

        do {
            let fetchedPosts = try await postsTask
            await MainActor.run { posts = fetchedPosts }
        } catch { print("Failed to fetch posts: \(error)") }

        do {
            let fetchedEvents = try await eventsTask
            await MainActor.run { events = fetchedEvents }
        } catch { print("Failed to fetch events: \(error)") }

        do {
            let fetchedMedia = try await mediaTask
            await MainActor.run { featuredMedia = fetchedMedia }
        } catch { print("Failed to fetch media: \(error)") }

        await MainActor.run { isLoading = false }
    }
}

// MARK: - Prayer Content

struct PrayerContentView: View {
    @State private var showNewPrayerSheet = false
    @State private var prayerRequests: [PrayerRequest] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // New Prayer Button
                Button(action: { showNewPrayerSheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Share a Prayer Request")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.churchTalkRed.opacity(0.1))
                    .foregroundColor(.churchTalkRed)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Prayer Requests
                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if prayerRequests.isEmpty {
                    EmptyStateView(
                        icon: "hands.sparkles",
                        title: "No Prayer Requests",
                        message: "Be the first to share a prayer request"
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(prayerRequests) { request in
                        ConnectPrayerCard(request: request)
                    }
                }

                Color.clear.frame(height: 100)
            }
            .padding(.top, 16)
        }
        .refreshable {
            await loadPrayers()
        }
        .task {
            await loadPrayers()
        }
        .sheet(isPresented: $showNewPrayerSheet) {
            NewPrayerRequestView(onPrayerCreated: {
                Task { await loadPrayers() }
            })
        }
    }

    private func loadPrayers() async {
        isLoading = true
        do {
            let fetchedPrayers = try await PrayerAPI.shared.getPrayers(limit: 20)
            await MainActor.run {
                prayerRequests = fetchedPrayers
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Connect Content

struct ConnectContentView: View {
    @State private var members: [Member] = []
    @State private var groups: [SmallGroup] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Groups Section
                if !groups.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ChurchSectionHeader(title: "Groups", icon: "person.3.fill")

                        ForEach(groups.prefix(3)) { group in
                            SmallGroupCard(group: group)
                                .padding(.horizontal)
                        }

                        if groups.count > 3 {
                            NavigationLink(destination: GroupsListView()) {
                                Text("See All Groups")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.churchTalkRed)
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Directory Section
                VStack(alignment: .leading, spacing: 12) {
                    ChurchSectionHeader(title: "Directory", icon: "person.2.fill")

                    NavigationLink(destination: DirectoryListView()) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search Members")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }

                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                }

                Color.clear.frame(height: 100)
            }
            .padding(.top, 16)
        }
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        do {
            let fetchedGroups = try await GroupsAPI.shared.getGroups(isOpen: true)
            await MainActor.run {
                groups = fetchedGroups
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Serve Content

struct ServeContentView: View {
    @State private var opportunities: [ServeOpportunity] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Serve Intro
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.churchTalkRed)

                    Text("Ready to Serve?")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Find opportunities to use your gifts and make a difference")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

                // Opportunities would be loaded from API
                // For now, show placeholder
                VStack(spacing: 12) {
                    ServeOpportunityCard(
                        title: "Kids Ministry",
                        description: "Help with children's church on Sundays",
                        icon: "figure.and.child.holdinghands"
                    )

                    ServeOpportunityCard(
                        title: "Welcome Team",
                        description: "Greet guests and help them feel at home",
                        icon: "hand.wave.fill"
                    )

                    ServeOpportunityCard(
                        title: "Worship Team",
                        description: "Use your musical gifts in worship",
                        icon: "music.note"
                    )
                }
                .padding(.horizontal)

                Color.clear.frame(height: 100)
            }
            .padding(.top, 16)
        }
    }
}

// MARK: - Outreach Content

struct OutreachContentView: View {
    var body: some View {
        OutreachHomeView()
    }
}

// MARK: - Supporting Views

struct ChurchSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.churchTalkRed)
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .tracking(1)
        }
        .padding(.horizontal)
    }
}

struct FeaturedMediaCard: View {
    let media: FeaturedMedia

    var body: some View {
        Button(action: openMedia) {
            ZStack {
                if let thumbnailUrl = media.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        placeholderView
                    }
                } else {
                    placeholderView
                }

                // Play button overlay
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: media.isLive ? "antenna.radiowaves.left.and.right" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    )

                // Live badge
                if media.isLive {
                    VStack {
                        HStack {
                            HStack(spacing: 4) {
                                Circle().fill(Color.red).frame(width: 6, height: 6)
                                Text("LIVE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            Spacer()
                        }
                        .padding(12)
                        Spacer()
                    }
                }
            }
            .frame(height: 180)
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
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
            Text("Watch Latest Message")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(height: 180)
    }
}

struct CompactEventCard: View {
    let event: ChurchEvent

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: event.startDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedDate)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.churchTalkRed)

            Text(event.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            if let location = event.location {
                Label(location.address ?? location.name ?? "Location", systemImage: "mappin")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 160, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

struct CompactBulletinCard: View {
    let post: BulletinPost

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail or icon
            Circle()
                .fill(Color.churchTalkRed.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "newspaper.fill")
                        .foregroundColor(.churchTalkRed)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(post.publishedAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 3, y: 1)
    }
}

struct ServeOpportunityCard: View {
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.churchTalkRed.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.churchTalkRed)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Sign Up") {
                // Handle signup
            }
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.churchTalkRed)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}


// Serve opportunity model (placeholder)
struct ServeOpportunity: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
}

#Preview {
    ChurchTabView()
        .environmentObject(AuthViewModel())
}
