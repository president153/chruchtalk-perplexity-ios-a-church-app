import SwiftUI

struct StreetDetailView: View {
    let street: OutreachStreet
    @State private var selectedDoor: OutreachDoor? = nil
    @State private var doors: [OutreachDoor] = []
    @State private var isLoadingDoors = true
    @State private var doorsError: String?
    @State private var filterStatus: DoorStatus? = nil

    // Computed stats
    private var doorStats: DoorStats {
        var stats = DoorStats()
        for door in doors {
            switch door.status {
            case .notVisited: stats.notVisited += 1
            case .notHome: stats.notHome += 1
            case .interested: stats.interested += 1
            case .notInterested: stats.notInterested += 1
            case .followUp: stats.followUp += 1
            case .doNotContact: stats.doNotContact += 1
            case .alreadyMember: stats.alreadyMember += 1
            }
        }
        stats.total = doors.count
        stats.visited = stats.total - stats.notVisited
        return stats
    }

    private var filteredDoors: [OutreachDoor] {
        guard let filter = filterStatus else { return doors }
        return doors.filter { $0.status == filter }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // Progress Card
                StreetProgressCard(stats: doorStats)
                    .padding(.horizontal)

                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        OutreachFilterChip(title: "All", count: doorStats.total, isSelected: filterStatus == nil) {
                            filterStatus = nil
                        }
                        OutreachFilterChip(title: "Not Visited", count: doorStats.notVisited, color: .gray, isSelected: filterStatus == .notVisited) {
                            filterStatus = filterStatus == .notVisited ? nil : .notVisited
                        }
                        OutreachFilterChip(title: "Interested", count: doorStats.interested, color: .green, isSelected: filterStatus == .interested) {
                            filterStatus = filterStatus == .interested ? nil : .interested
                        }
                        OutreachFilterChip(title: "Follow Up", count: doorStats.followUp, color: .purple, isSelected: filterStatus == .followUp) {
                            filterStatus = filterStatus == .followUp ? nil : .followUp
                        }
                        OutreachFilterChip(title: "Not Home", count: doorStats.notHome, color: .orange, isSelected: filterStatus == .notHome) {
                            filterStatus = filterStatus == .notHome ? nil : .notHome
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                if isLoadingDoors {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, 40)
                } else if let error = doorsError {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task { await loadDoors() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if doors.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "door.left.hand.closed")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No doors on this street")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if filteredDoors.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No doors match this filter")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Clear Filter") {
                            filterStatus = nil
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // Door List
                    ForEach(filteredDoors) { door in
                        DoorCard(door: door) {
                            selectedDoor = door
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(street.name)
        .sheet(item: $selectedDoor) { door in
            DoorKnockingView(door: door, onDoorUpdated: {
                Task { await loadDoors() }
            })
        }
        .task {
            await loadDoors()
        }
        .refreshable {
            await loadDoors()
        }
    }

    private func loadDoors() async {
        await MainActor.run {
            isLoadingDoors = true
            doorsError = nil
        }

        do {
            let fetchedDoors = try await OutreachAPI.shared.getDoors(streetId: street.id)
            await MainActor.run {
                doors = fetchedDoors
                isLoadingDoors = false
            }
        } catch {
            print("Failed to load doors: \(error)")
            await MainActor.run {
                doorsError = "Failed to load doors"
                isLoadingDoors = false
            }
        }
    }
}

struct DoorCard: View {
    let door: OutreachDoor
    let onTap: () -> Void

    var statusColor: Color {
        switch door.status {
        case .notVisited: return .gray
        case .notHome: return .orange
        case .interested: return .green
        case .notInterested: return .red
        case .followUp: return .purple
        case .doNotContact: return .black
        case .alreadyMember: return .blue
        }
    }

    var statusIcon: String {
        switch door.status {
        case .notVisited: return "circle"
        case .notHome: return "clock.fill"
        case .interested: return "star.fill"
        case .notInterested: return "xmark.circle.fill"
        case .followUp: return "arrow.clockwise.circle.fill"
        case .doNotContact: return "hand.raised.fill"
        case .alreadyMember: return "person.crop.circle.badge.checkmark"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status Indicator
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("#\(door.houseNumber)")
                            .font(.headline)

                        if door.status != .notVisited {
                            Text(door.status.displayName)
                                .font(.caption)
                                .foregroundColor(statusColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(statusColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    if let resident = door.residentName {
                        Text(resident)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }

                    if let visitedBy = door.lastVisitedBy {
                        Text("by \(visitedBy)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// MARK: - Door Stats

struct DoorStats {
    var total: Int = 0
    var visited: Int = 0
    var notVisited: Int = 0
    var notHome: Int = 0
    var interested: Int = 0
    var notInterested: Int = 0
    var followUp: Int = 0
    var doNotContact: Int = 0
    var alreadyMember: Int = 0

    var completionPercent: Double {
        guard total > 0 else { return 0 }
        return Double(visited) / Double(total) * 100
    }
}

// MARK: - Street Progress Card

struct StreetProgressCard: View {
    let stats: DoorStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(stats.completionPercent))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.churchTalkRed)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(Color.churchTalkRed)
                        .frame(width: geometry.size.width * stats.completionPercent / 100, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)

            // Stats Grid
            HStack(spacing: 0) {
                StatItem(value: stats.total, label: "Total", color: .primary)
                StatItem(value: stats.visited, label: "Visited", color: .green)
                StatItem(value: stats.interested, label: "Interested", color: .green)
                StatItem(value: stats.followUp, label: "Follow Up", color: .purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Outreach Filter Chip

struct OutreachFilterChip: View {
    let title: String
    let count: Int
    var color: Color = .churchTalkRed
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : color.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

// Preview disabled - OutreachStreet requires API response format
