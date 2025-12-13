import SwiftUI

struct StreetDetailView: View {
    let street: OutreachStreet
    @State private var selectedDoor: OutreachDoor? = nil

    // Demo doors
    let doors: [OutreachDoor] = [
        OutreachDoor(id: "1", houseNumber: "3040", fullAddress: "3040 E Lingard St", status: .notVisited),
        OutreachDoor(id: "2", houseNumber: "3042", fullAddress: "3042 E Lingard St", status: .notHome, lastVisitedBy: "John D."),
        OutreachDoor(id: "3", houseNumber: "3044", fullAddress: "3044 E Lingard St", status: .interested, residentName: "Maria Garcia"),
        OutreachDoor(id: "4", houseNumber: "3046", fullAddress: "3046 E Lingard St", status: .notInterested),
        OutreachDoor(id: "5", houseNumber: "3048", fullAddress: "3048 E Lingard St", status: .followUp, residentName: "David Kim"),
        OutreachDoor(id: "6", houseNumber: "3050", fullAddress: "3050 E Lingard St", status: .notVisited),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // Live Activity Banner
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("John is knocking #3048")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)

                // Door List
                ForEach(doors) { door in
                    DoorCard(door: door) {
                        selectedDoor = door
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(street.name)
        .sheet(item: $selectedDoor) { door in
            DoorKnockingView(door: door)
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

#Preview {
    NavigationStack {
        StreetDetailView(street: OutreachStreet(id: "1", name: "E Lingard St", completionPercent: 60))
    }
}
