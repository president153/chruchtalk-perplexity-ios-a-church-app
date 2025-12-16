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
    @State private var prayerRequests: [PrayerRequest] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

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
                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task { await loadPrayers() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 40)
                } else if prayerRequests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "hands.sparkles")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No prayer requests yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(prayerRequests) { request in
                        ConnectPrayerCard(request: request, onPrayerCountUpdated: { updatedPrayer in
                            if let index = prayerRequests.firstIndex(where: { $0.id == updatedPrayer.id }) {
                                prayerRequests[index] = updatedPrayer
                            }
                        })
                    }
                }

                // Bottom padding for tab bar
                Color.clear.frame(height: 90)
            }
            .padding(.vertical)
        }
        .task {
            await loadPrayers()
        }
        .refreshable {
            await loadPrayers()
        }
        .sheet(isPresented: $showNewPrayerSheet) {
            NewPrayerRequestView(onPrayerCreated: {
                Task { await loadPrayers() }
            })
        }
        .sheet(isPresented: $showMyPrayers) {
            MyPrayersView()
        }
    }

    private func loadPrayers() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedPrayers = try await PrayerAPI.shared.getPrayers(limit: 20)
            await MainActor.run {
                prayerRequests = fetchedPrayers
                isLoading = false
            }
        } catch {
            print("Failed to load prayers: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load prayers"
                isLoading = false
            }
        }
    }
}

struct ConnectPrayerCard: View {
    let request: PrayerRequest
    var onPrayerCountUpdated: ((PrayerRequest) -> Void)? = nil
    @State private var hasPrayed: Bool
    @State private var currentPrayerCount: Int
    @State private var isSubmitting = false

    init(request: PrayerRequest, onPrayerCountUpdated: ((PrayerRequest) -> Void)? = nil) {
        self.request = request
        self.onPrayerCountUpdated = onPrayerCountUpdated
        self._hasPrayed = State(initialValue: request.hasPrayed)
        self._currentPrayerCount = State(initialValue: request.prayerCount)
    }

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
                Button(action: {
                    if !hasPrayed && !isSubmitting {
                        prayForRequest()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: hasPrayed ? "hands.sparkles.fill" : "hands.sparkles")
                            .foregroundColor(hasPrayed ? .purple : .secondary)

                        Text("\(currentPrayerCount) prayers")
                            .foregroundColor(hasPrayed ? .purple : .secondary)
                    }
                    .font(.subheadline)
                }
                .disabled(hasPrayed)

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        .padding(.horizontal)
    }

    private func prayForRequest() {
        isSubmitting = true
        hasPrayed = true
        currentPrayerCount += 1

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        Task {
            do {
                let response = try await PrayerAPI.shared.prayFor(prayerId: request.id)
                await MainActor.run {
                    // Handle both success and "already prayed" responses
                    if response.message != nil {
                        // Already prayed - keep current state
                        isSubmitting = false
                    } else {
                        // Success - update with server values
                        currentPrayerCount = response.prayerCount ?? currentPrayerCount
                        hasPrayed = response.hasPrayed ?? true
                        isSubmitting = false

                        var updatedRequest = request
                        updatedRequest.prayerCount = response.prayerCount ?? currentPrayerCount
                        updatedRequest.hasPrayed = response.hasPrayed ?? true
                        onPrayerCountUpdated?(updatedRequest)
                    }
                }
            } catch {
                print("Failed to pray: \(error)")
                await MainActor.run {
                    currentPrayerCount -= 1
                    hasPrayed = false
                    isSubmitting = false
                }
            }
        }
    }
}

struct ConnectDirectorySectionView: View {
    let searchText: String
    @State private var members: [Member] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var filteredMembers: [Member] {
        if searchText.isEmpty {
            return members
        }
        return members.filter { member in
            member.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "wifi.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await loadMembers() }
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
            } else if members.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.2.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No members found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
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

                    // Bottom padding for tab bar
                    Color.clear.frame(height: 90)
                        .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
            }
        }
        .task {
            await loadMembers()
        }
        .refreshable {
            await loadMembers()
        }
    }

    private func loadMembers() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await MembersAPI.shared.getMembers(limit: 100)
            await MainActor.run {
                members = response.members
                isLoading = false
            }
        } catch {
            print("Failed to load members: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load members"
                isLoading = false
            }
        }
    }
}

struct ConnectGroupsSectionView: View {
    @State private var selectedCategory = "All"
    @State private var showGroupDetail: SmallGroup? = nil
    @State private var groups: [SmallGroup] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    let categories = ["All", "Small Group", "Life Group", "Bible Study", "Prayer Group", "Ministry Team"]

    var filteredGroups: [SmallGroup] {
        if selectedCategory == "All" {
            return groups
        }
        // Map category display name to group type
        let typeFilter: GroupType? = {
            switch selectedCategory {
            case "Small Group": return .smallGroup
            case "Life Group": return .lifeGroup
            case "Bible Study": return .bibleStudy
            case "Prayer Group": return .prayerGroup
            case "Ministry Team": return .ministryTeam
            default: return nil
            }
        }()
        guard let filter = typeFilter else { return groups }
        return groups.filter { $0.groupType == filter }
    }

    var body: some View {
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "wifi.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await loadGroups() }
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
            } else if groups.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.3")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No groups available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Check back later or ask your church admin to create groups")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
            } else {
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
            }
        }
        .task {
            await loadGroups()
        }
        .refreshable {
            await loadGroups()
        }
        .sheet(item: $showGroupDetail) { group in
            SmallGroupDetailView(group: group, onGroupUpdated: {
                Task { await loadGroups() }
            })
        }
    }

    private func loadGroups() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedGroups = try await GroupsAPI.shared.getGroups(isOpen: true)
            await MainActor.run {
                groups = fetchedGroups
                isLoading = false
            }
        } catch {
            print("Failed to load groups: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load groups"
                isLoading = false
            }
        }
    }
}

struct SmallGroupCard: View {
    let group: SmallGroup

    private var iconForGroupType: String {
        switch group.groupType {
        case .smallGroup: return "person.3.fill"
        case .lifeGroup: return "heart.fill"
        case .bibleStudy: return "book.fill"
        case .prayerGroup: return "hands.sparkles.fill"
        case .ministryTeam: return "star.fill"
        case .other: return "circle.grid.2x2.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                Circle()
                    .fill(Color.churchTalkRed.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: iconForGroupType)
                            .font(.title3)
                            .foregroundColor(.churchTalkRed)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let leaderName = group.leaderName {
                        Text("Led by \(leaderName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Member count indicator
                if let maxMembers = group.maxMembers {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(group.memberCount)/\(maxMembers)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(group.memberCount < maxMembers ? .green : .orange)

                        Text("members")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(group.memberCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)

                        Text("members")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Meeting info
            HStack(spacing: 16) {
                if let meetingDay = group.meetingDay {
                    Label(meetingDay, systemImage: "calendar")
                }
                if let meetingTime = group.meetingTime {
                    Label(meetingTime, systemImage: "clock")
                }
                if let location = group.location {
                    Label(location, systemImage: "mappin")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            // Category tag
            Text(group.groupType.displayName)
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
    var onGroupUpdated: (() -> Void)? = nil
    @State private var showJoinConfirmation = false
    @State private var isJoining = false
    @State private var joinError: String?

    private var iconForGroupType: String {
        switch group.groupType {
        case .smallGroup: return "person.3.fill"
        case .lifeGroup: return "heart.fill"
        case .bibleStudy: return "book.fill"
        case .prayerGroup: return "hands.sparkles.fill"
        case .ministryTeam: return "star.fill"
        case .other: return "circle.grid.2x2.fill"
        }
    }

    private var isFull: Bool {
        if let maxMembers = group.maxMembers {
            return group.memberCount >= maxMembers
        }
        return false
    }

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
                                Image(systemName: iconForGroupType)
                                    .font(.largeTitle)
                                    .foregroundColor(.churchTalkRed)
                            )

                        Text(group.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(group.groupType.displayName)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.churchTalkRed.opacity(0.1))
                            .foregroundColor(.churchTalkRed)
                            .cornerRadius(12)
                    }
                    .padding(.top)

                    // Description
                    if let description = group.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)

                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }

                    // Details
                    VStack(spacing: 16) {
                        if let leaderName = group.leaderName {
                            DetailRow(icon: "person.fill", title: "Leader", value: leaderName)
                        }
                        DetailRow(icon: "calendar", title: "Meets", value: group.meetingSchedule)
                        if let location = group.location {
                            DetailRow(icon: "mappin.and.ellipse", title: "Location", value: location)
                        }
                        if let maxMembers = group.maxMembers {
                            DetailRow(icon: "person.3.fill", title: "Members", value: "\(group.memberCount) of \(maxMembers)")
                        } else {
                            DetailRow(icon: "person.3.fill", title: "Members", value: "\(group.memberCount)")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Error message
                    if let error = joinError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    // Join Button
                    if group.isOpen && !isFull {
                        Button {
                            showJoinConfirmation = true
                        } label: {
                            HStack {
                                if isJoining {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Join This Group")
                                }
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.churchTalkRed)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isJoining)
                        .padding(.horizontal)
                    } else if isFull {
                        VStack(spacing: 8) {
                            Text("This group is currently full")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Button {
                                // Join waitlist - not implemented yet
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
                    } else if !group.isOpen {
                        Text("This group is not accepting new members")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }

                    // Contact Leader
                    if group.leaderName != nil {
                        Button {
                            // Contact group leader - not implemented yet
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
                    }

                    Spacer().frame(height: 20)
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
                    joinGroup()
                }
            } message: {
                Text("You'll be added to \(group.name) and receive updates about meetings.")
            }
        }
    }

    private func joinGroup() {
        isJoining = true
        joinError = nil

        Task {
            do {
                _ = try await GroupsAPI.shared.joinGroup(id: group.id)
                await MainActor.run {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    isJoining = false
                    onGroupUpdated?()
                    dismiss()
                }
            } catch {
                print("Failed to join group: \(error)")
                await MainActor.run {
                    joinError = "Failed to join group. Please try again."
                    isJoining = false
                }
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
