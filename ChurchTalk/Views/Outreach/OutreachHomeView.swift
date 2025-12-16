import SwiftUI

struct OutreachHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var territories: [Territory] = []
    @State private var isLoadingTerritories = true
    @State private var territoriesError: String?
    @State private var showMySouls = false
    @State private var showSRMDashboard = false

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
            group.addTask { await loadStats() }
            group.addTask { await loadTerritories() }
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
            let souls = try await SoulsAPI.shared.getSouls(mine: true, limit: 1000)
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

#Preview {
    OutreachHomeView()
        .environmentObject(AuthViewModel())
}
