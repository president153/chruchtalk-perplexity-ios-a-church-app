import SwiftUI

struct OutreachHomeView: View {
    @State private var territories: [Territory] = [
        Territory(id: "1", name: "Downtown Lancaster", status: .assigned, progress: 45),
        Territory(id: "2", name: "East Side", status: .inProgress, progress: 72),
        Territory(id: "3", name: "North Lancaster", status: .unassigned, progress: 0),
    ]
    @State private var showMySouls = false
    @State private var showSRMDashboard = false

    // Personal outreach stats
    let myStats = (doorsKnocked: 127, soulsAdded: 18, followUps: 12)

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
                            Text("This Month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        HStack(spacing: 12) {
                            PersonalStatCard(value: "\(myStats.doorsKnocked)", label: "Doors Knocked", icon: "door.left.hand.closed", color: .churchTalkRed)
                            PersonalStatCard(value: "\(myStats.soulsAdded)", label: "Souls Added", icon: "star.fill", color: .orange)
                            PersonalStatCard(value: "\(myStats.followUps)", label: "Follow-ups", icon: "arrow.triangle.2.circlepath", color: .green)
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
                            Text("My Territories")
                                .font(.headline)
                            Spacer()
                            Text("\(territories.count) assigned")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        ForEach(territories) { territory in
                            NavigationLink(destination: TerritoryDetailView(territory: territory)) {
                                TerritoryCard(territory: territory)
                            }
                            .buttonStyle(PlainButtonStyle())
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

                    Text(territory.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
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
}
