import SwiftUI

struct OutreachHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var territories: [Territory] = []
    @State private var isLoadingTerritories = true
    @State private var territoriesError: String?
    @State private var showMySouls = false
    @State private var showSRMDashboard = false

    // Weekly Assignment (Agentic AI)
    @State private var weeklyAssignment: WeeklyAssignment?
    @State private var isLoadingAssignment = true
    @State private var isAcceptingAssignment = false
    @State private var isStartingAssignment = false

    // Stats from API
    @State private var doorsKnocked: Int = 0
    @State private var soulsAdded: Int = 0
    @State private var followUps: Int = 0
    @State private var territoriesAssigned: Int = 0
    @State private var isLoadingStats = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Weekly Assignment Card (Agentic AI)
                    if isLoadingAssignment {
                        WeeklyAssignmentLoadingCard()
                    } else if let assignment = weeklyAssignment {
                        WeeklyAssignmentCard(
                            assignment: assignment,
                            isAccepting: isAcceptingAssignment,
                            isStarting: isStartingAssignment,
                            onAccept: { await acceptAssignment() },
                            onStart: { await startAssignment() },
                            onViewStreet: {
                                // Navigate to street detail
                            }
                        )
                    } else {
                        NoAssignmentCard()
                    }

                    // My Personal Stats Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("My Outreach Stats")
                                .font(.headline)
                            Spacer()
                            Text("All Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        HStack(spacing: 12) {
                            PersonalStatCard(value: isLoadingStats ? "-" : "\(doorsKnocked)", label: "Doors Knocked", icon: "door.left.hand.closed", color: .churchTalkRed)
                            PersonalStatCard(value: isLoadingStats ? "-" : "\(soulsAdded)", label: "Souls Added", icon: "star.fill", color: .orange)
                            PersonalStatCard(value: isLoadingStats ? "-" : "\(followUps)", label: "Follow-ups", icon: "arrow.triangle.2.circlepath", color: .green)
                        }
                        .padding(.horizontal)
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            QuickActionCard(title: "My Souls", icon: "star.fill", color: .orange) {
                                showMySouls = true
                            }
                            QuickActionCard(title: "Church SRM", icon: "person.3.fill", color: .purple) {
                                showSRMDashboard = true
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Territory List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Territories")
                                .font(.headline)
                            Spacer()
                            if !isLoadingTerritories {
                                Text("\(territoriesAssigned) assigned to me")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        if isLoadingTerritories {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.vertical, 20)
                        } else if let error = territoriesError {
                            VStack(spacing: 12) {
                                Image(systemName: "wifi.exclamationmark")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button("Retry") {
                                    Task { await loadTerritories() }
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else if territories.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "map")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("No territories available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Ask your admin to create territories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            ForEach(territories) { territory in
                                NavigationLink(destination: TerritoryDetailView(territory: territory)) {
                                    TerritoryCard(territory: territory)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Outreach")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .foregroundColor(.churchTalkRed)
                    }
                }
            }
            .sheet(isPresented: $showMySouls) {
                MySoulsView()
            }
            .sheet(isPresented: $showSRMDashboard) {
                SRMDashboardView()
                    .environmentObject(authViewModel)
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }

    private func loadData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadWeeklyAssignment() }
            group.addTask { await loadStats() }
            group.addTask { await loadTerritories() }
        }
    }

    private func loadWeeklyAssignment() async {
        await MainActor.run {
            isLoadingAssignment = true
        }

        do {
            let assignment = try await OutreachAPI.shared.getMyWeeklyAssignment()
            await MainActor.run {
                weeklyAssignment = assignment
                isLoadingAssignment = false
            }
        } catch {
            print("Failed to load weekly assignment: \(error)")
            await MainActor.run {
                weeklyAssignment = nil
                isLoadingAssignment = false
            }
        }
    }

    private func acceptAssignment() async {
        guard let assignment = weeklyAssignment else { return }

        await MainActor.run {
            isAcceptingAssignment = true
        }

        do {
            _ = try await OutreachAPI.shared.acceptAssignment(id: assignment.id)
            await loadWeeklyAssignment()
        } catch {
            print("Failed to accept assignment: \(error)")
        }

        await MainActor.run {
            isAcceptingAssignment = false
        }
    }

    private func startAssignment() async {
        guard let assignment = weeklyAssignment else { return }

        await MainActor.run {
            isStartingAssignment = true
        }

        do {
            _ = try await OutreachAPI.shared.startAssignment(id: assignment.id)
            await loadWeeklyAssignment()
        } catch {
            print("Failed to start assignment: \(error)")
        }

        await MainActor.run {
            isStartingAssignment = false
        }
    }

    private func loadStats() async {
        isLoadingStats = true

        // Load outreach stats from API
        do {
            let stats = try await OutreachAPI.shared.getStats()
            await MainActor.run {
                doorsKnocked = stats.doorsKnocked
                followUps = stats.followUps
                territoriesAssigned = stats.territoriesAssigned
            }
        } catch {
            print("Failed to load outreach stats: \(error)")
            // Fallback: keep current values
        }

        // Load souls added count
        do {
            let souls = try await SoulsAPI.shared.getSouls(view: "mine", limit: 100)
            await MainActor.run {
                soulsAdded = souls.count
            }
        } catch {
            print("Failed to load souls: \(error)")
        }

        await MainActor.run {
            isLoadingStats = false
        }
    }

    private func loadTerritories() async {
        await MainActor.run {
            isLoadingTerritories = true
            territoriesError = nil
        }

        do {
            let fetchedTerritories = try await OutreachAPI.shared.getTerritories()
            await MainActor.run {
                territories = fetchedTerritories
                isLoadingTerritories = false
            }
        } catch {
            print("Failed to load territories: \(error)")
            await MainActor.run {
                territoriesError = "Failed to load territories"
                isLoadingTerritories = false
            }
        }
    }
}

// MARK: - Personal Stat Card

struct PersonalStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TerritoryCard: View {
    let territory: Territory

    var statusColor: Color {
        switch territory.status {
        case .unassigned: return .gray
        case .assigned: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(territory.name)
                        .font(.headline)

                    Text(territory.status.displayName)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(territory.progress))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)

                        Rectangle()
                            .fill(statusColor)
                            .frame(width: geometry.size.width * territory.progress / 100, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Weekly Assignment Cards

struct WeeklyAssignmentLoadingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.churchTalkRed)
                Text("This Week's Assignment")
                    .font(.headline)
                Spacer()
            }

            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 20)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        .padding(.horizontal)
    }
}

struct NoAssignmentCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.churchTalkRed)
                Text("This Week's Assignment")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                Text("No assignment this week")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Check back Thursday for next week's street")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        .padding(.horizontal)
    }
}

struct WeeklyAssignmentCard: View {
    let assignment: WeeklyAssignment
    let isAccepting: Bool
    let isStarting: Bool
    let onAccept: () async -> Void
    let onStart: () async -> Void
    let onViewStreet: () -> Void

    var statusColor: Color {
        switch assignment.status {
        case .pending: return .orange
        case .accepted: return .blue
        case .inProgress: return .green
        case .completed: return .gray
        case .declined: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.churchTalkRed)
                Text("This Week's Assignment")
                    .font(.headline)
                Spacer()
                Text("\(assignment.daysRemaining) days left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Street Info
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.streetName)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(assignment.territoryName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Progress
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(assignment.doorsVisited)/\(assignment.doorCount) doors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(assignment.progressPercent))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)

                        Rectangle()
                            .fill(statusColor)
                            .frame(width: geometry.size.width * assignment.progressPercent / 100, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }

            // Status Badge
            HStack {
                Text(assignment.status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(4)

                Spacer()
            }

            // Action Buttons
            HStack(spacing: 12) {
                if assignment.status == .pending {
                    Button(action: { Task { await onAccept() } }) {
                        HStack {
                            if isAccepting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Accept")
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    .disabled(isAccepting)
                } else if assignment.status == .accepted {
                    Button(action: { Task { await onStart() } }) {
                        HStack {
                            if isStarting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "play.fill")
                                Text("Start Outreach")
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.churchTalkRed)
                        .cornerRadius(8)
                    }
                    .disabled(isStarting)
                } else if assignment.status == .inProgress {
                    Button(action: onViewStreet) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("View Street")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.churchTalkRed)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    OutreachHomeView()
        .environmentObject(AuthViewModel())
}
