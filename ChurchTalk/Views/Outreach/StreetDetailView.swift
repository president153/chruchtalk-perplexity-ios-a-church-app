import SwiftUI

struct StreetDetailView: View {
    let street: OutreachStreet
    @State private var selectedDoor: OutreachDoor? = nil
    @State private var doors: [OutreachDoor] = []
    @State private var isLoadingDoors = true
    @State private var doorsError: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // Stats bar
                HStack(spacing: 16) {
                    Label("\(doors.count) doors", systemImage: "door.left.hand.closed")
                    Label("\(Int(street.completionPercent))% complete", systemImage: "checkmark.circle")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

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
                } else {
                    // Door List
                    ForEach(doors) { door in
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

// Preview disabled - OutreachStreet requires API response format
