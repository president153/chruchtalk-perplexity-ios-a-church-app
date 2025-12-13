import SwiftUI

struct ConnectTabView: View {
    @State private var searchText = ""
    @State private var selectedSection: ConnectSection = .prayer

    enum ConnectSection: String, CaseIterable {
        case prayer = "Prayer"
        case directory = "Directory"
        case groups = "Groups"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search members...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                // Section Picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(ConnectSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom)

                // Content
                switch selectedSection {
                case .prayer:
                    ConnectPrayerSectionView()
                case .directory:
                    ConnectDirectorySectionView(searchText: searchText)
                case .groups:
                    ConnectGroupsSectionView()
                }
            }
            .navigationTitle("Connect")
        }
    }
}

struct ConnectPrayerSectionView: View {
    @State private var showNewPrayerSheet = false
    @State private var showMyPrayers = false

    // Demo data using existing PrayerRequest model
    let prayerRequests = [
        PrayerRequest(
            id: "1",
            content: "Please pray for my mother's health as she recovers from surgery.",
            authorId: "1",
            authorName: "Sarah M.",
            isAnonymous: false,
            prayerCount: 24,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        PrayerRequest(
            id: "2",
            content: "Praying for guidance in a difficult work situation.",
            authorId: "2",
            authorName: nil,
            isAnonymous: true,
            prayerCount: 18,
            createdAt: Date().addingTimeInterval(-7200)
        ),
        PrayerRequest(
            id: "3",
            content: "Thankful for answered prayers! Our family has been blessed.",
            authorId: "3",
            authorName: "John D.",
            isAnonymous: false,
            prayerCount: 32,
            createdAt: Date().addingTimeInterval(-86400)
        )
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Action Buttons Row
                HStack(spacing: 12) {
                    // New Prayer Button
                    Button(action: { showNewPrayerSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Share a Prayer Request")
                        }
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.churchTalkRed.opacity(0.1))
                        .foregroundColor(.churchTalkRed)
                        .cornerRadius(12)
                    }

                    // My Prayers Button
                    Button(action: { showMyPrayers = true }) {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("My Prayers")
                        }
                        .fontWeight(.medium)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                // Prayer Requests
                ForEach(prayerRequests) { request in
                    ConnectPrayerCard(request: request)
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showNewPrayerSheet) {
            NewPrayerRequestView()
        }
        .sheet(isPresented: $showMyPrayers) {
            MyPrayersView()
        }
    }
}

struct ConnectPrayerCard: View {
    let request: PrayerRequest
    @State private var hasPrayed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author
            HStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: request.isAnonymous ? "person.fill.questionmark" : "person.fill")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(request.displayAuthor)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(request.createdAt.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Content
            Text(request.content)
                .font(.body)
                .foregroundColor(.primary)

            // Pray Button
            HStack {
                Button(action: { hasPrayed.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: hasPrayed ? "hands.sparkles.fill" : "hands.sparkles")
                            .foregroundColor(hasPrayed ? .purple : .secondary)

                        Text("\(request.prayerCount + (hasPrayed ? 1 : 0)) prayers")
                            .foregroundColor(hasPrayed ? .purple : .secondary)
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        .padding(.horizontal)
    }
}

struct ConnectDirectorySectionView: View {
    let searchText: String

    // Demo members
    let members = [
        Member(id: "1", firstName: "John", lastName: "Anderson", email: "john@church.org", churchId: "1"),
        Member(id: "2", firstName: "Sarah", lastName: "Baker", email: "sarah@church.org", churchId: "1"),
        Member(id: "3", firstName: "Mike", lastName: "Chen", email: "mike@church.org", churchId: "1"),
        Member(id: "4", firstName: "Emily", lastName: "Davis", email: "emily@church.org", churchId: "1"),
        Member(id: "5", firstName: "David", lastName: "Evans", email: "david@church.org", churchId: "1"),
    ]

    var filteredMembers: [Member] {
        if searchText.isEmpty {
            return members
        }
        return members.filter { member in
            member.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredMembers) { member in
                NavigationLink(destination: MemberProfileView(member: member)) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.churchTalkRed.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(member.initials)
                                    .font(.headline)
                                    .foregroundColor(.churchTalkRed)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.fullName)
                                .font(.body)
                                .fontWeight(.medium)

                            Text(member.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct SmallGroup: Identifiable {
    let id: String
    let name: String
    let description: String
    let leaderName: String
    let meetingDay: String
    let meetingTime: String
    let location: String
    let memberCount: Int
    let maxMembers: Int
    let icon: String
    let category: String
}

struct ConnectGroupsSectionView: View {
    @State private var selectedCategory = "All"
    @State private var showGroupDetail: SmallGroup? = nil

    let categories = ["All", "Bible Study", "Fellowship", "Service", "Youth"]

    let groups: [SmallGroup] = [
        SmallGroup(
            id: "1",
            name: "Young Adults",
            description: "A welcoming community for ages 18-30 to grow in faith, build friendships, and explore life's big questions together.",
            leaderName: "Pastor Mike Chen",
            meetingDay: "Friday",
            meetingTime: "7:00 PM",
            location: "Fellowship Hall",
            memberCount: 12,
            maxMembers: 20,
            icon: "sparkles",
            category: "Fellowship"
        ),
        SmallGroup(
            id: "2",
            name: "Men's Bible Study",
            description: "Men gathering to study Scripture, encourage one another, and grow as spiritual leaders in their homes and community.",
            leaderName: "David Anderson",
            meetingDay: "Saturday",
            meetingTime: "8:00 AM",
            location: "Room 201",
            memberCount: 8,
            maxMembers: 12,
            icon: "book.fill",
            category: "Bible Study"
        ),
        SmallGroup(
            id: "3",
            name: "Women's Fellowship",
            description: "Women supporting each other through prayer, Bible study, and meaningful conversations about faith and life.",
            leaderName: "Sarah Thompson",
            meetingDay: "Wednesday",
            meetingTime: "10:00 AM",
            location: "Prayer Room",
            memberCount: 15,
            maxMembers: 18,
            icon: "heart.fill",
            category: "Fellowship"
        ),
        SmallGroup(
            id: "4",
            name: "Marriage Ministry",
            description: "Couples strengthening their marriages through biblical principles, shared experiences, and community support.",
            leaderName: "Pastor John & Lisa Smith",
            meetingDay: "1st Sunday",
            meetingTime: "4:00 PM",
            location: "Family Center",
            memberCount: 20,
            maxMembers: 30,
            icon: "person.2.fill",
            category: "Fellowship"
        ),
        SmallGroup(
            id: "5",
            name: "Community Outreach",
            description: "Serving our local community through various outreach projects and showing God's love in action.",
            leaderName: "Emily Davis",
            meetingDay: "2nd Saturday",
            meetingTime: "9:00 AM",
            location: "Various Locations",
            memberCount: 18,
            maxMembers: 25,
            icon: "hands.sparkles.fill",
            category: "Service"
        ),
        SmallGroup(
            id: "6",
            name: "Youth Group",
            description: "Middle and high school students growing in faith through games, worship, and relevant Bible teaching.",
            leaderName: "Jake Wilson",
            meetingDay: "Sunday",
            meetingTime: "5:30 PM",
            location: "Youth Center",
            memberCount: 25,
            maxMembers: 40,
            icon: "star.fill",
            category: "Youth"
        )
    ]

    var filteredGroups: [SmallGroup] {
        if selectedCategory == "All" {
            return groups
        }
        return groups.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = category
                                }
                            } label: {
                                Text(category)
                                    .font(.subheadline)
                                    .fontWeight(selectedCategory == category ? .semibold : .regular)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.churchTalkRed : Color(.systemGray6))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Groups List
                LazyVStack(spacing: 12) {
                    ForEach(filteredGroups) { group in
                        SmallGroupCard(group: group)
                            .onTapGesture {
                                showGroupDetail = group
                            }
                    }
                }
                .padding(.horizontal)

                // Find a Group CTA
                VStack(spacing: 12) {
                    Text("Not sure which group is right for you?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button {
                        // Open group finder
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                            Text("Help Me Find a Group")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.churchTalkRed.opacity(0.1))
                        .foregroundColor(.churchTalkRed)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .padding(.vertical)
        }
        .sheet(item: $showGroupDetail) { group in
            SmallGroupDetailView(group: group)
        }
    }
}

struct SmallGroupCard: View {
    let group: SmallGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                Circle()
                    .fill(Color.churchTalkRed.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: group.icon)
                            .font(.title3)
                            .foregroundColor(.churchTalkRed)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Led by \(group.leaderName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Member count indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(group.memberCount)/\(group.maxMembers)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(group.memberCount < group.maxMembers ? .green : .orange)

                    Text("members")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Meeting info
            HStack(spacing: 16) {
                Label(group.meetingDay, systemImage: "calendar")
                Label(group.meetingTime, systemImage: "clock")
                Label(group.location, systemImage: "mappin")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            // Category tag
            Text(group.category)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.churchTalkRed.opacity(0.1))
                .foregroundColor(.churchTalkRed)
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

struct SmallGroupDetailView: View {
    @Environment(\.dismiss) var dismiss
    let group: SmallGroup
    @State private var showJoinConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.churchTalkRed.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: group.icon)
                                    .font(.largeTitle)
                                    .foregroundColor(.churchTalkRed)
                            )

                        Text(group.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(group.category)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.churchTalkRed.opacity(0.1))
                            .foregroundColor(.churchTalkRed)
                            .cornerRadius(12)
                    }
                    .padding(.top)

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)

                        Text(group.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Details
                    VStack(spacing: 16) {
                        DetailRow(icon: "person.fill", title: "Leader", value: group.leaderName)
                        DetailRow(icon: "calendar", title: "Meets", value: "\(group.meetingDay)s at \(group.meetingTime)")
                        DetailRow(icon: "mappin.and.ellipse", title: "Location", value: group.location)
                        DetailRow(icon: "person.3.fill", title: "Members", value: "\(group.memberCount) of \(group.maxMembers)")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Join Button
                    if group.memberCount < group.maxMembers {
                        Button {
                            showJoinConfirmation = true
                        } label: {
                            Text("Join This Group")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.churchTalkRed)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 8) {
                            Text("This group is currently full")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Button {
                                // Join waitlist
                            } label: {
                                Text("Join Waitlist")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundColor(.orange)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Contact Leader
                    Button {
                        // Contact group leader
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Contact Leader")
                        }
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Group Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Join Group?", isPresented: $showJoinConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Join") {
                    // Join the group
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    dismiss()
                }
            } message: {
                Text("You'll be added to \(group.name) and receive updates about meetings.")
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.churchTalkRed)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ConnectTabView()
}
