import SwiftUI

struct ServeTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedSection: ServeSection = .events

    var isAdmin: Bool {
        authViewModel.currentMember?.isAdmin == true
    }

    enum ServeSection: String, CaseIterable {
        case events = "Events"
        case commitments = "My Roles"
        case outreach = "Outreach"
    }

    var availableSections: [ServeSection] {
        if isAdmin {
            return ServeSection.allCases
        }
        return [.events, .commitments]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section Picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(availableSections, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Content
                switch selectedSection {
                case .events:
                    EventsListSection()
                case .commitments:
                    MyCommitmentsSection()
                case .outreach:
                    OutreachSection()
                }
            }
            .navigationTitle("Serve")
        }
    }
}

struct EventsListSection: View {
    @State private var viewMode: EventViewMode = .list
    @State private var selectedCategory: EventCategory? = nil
    @State private var selectedDate = Date()
    @State private var selectedEvent: ChurchEvent? = nil

    enum EventViewMode: String, CaseIterable {
        case list = "List"
        case calendar = "Calendar"
    }

    // Demo events
    let events: [ChurchEvent] = [
        ChurchEvent(
            id: "1",
            churchId: "1",
            title: "Christmas Eve Service",
            description: "Join us for a special candlelight service",
            startDate: Date().addingTimeInterval(86400 * 11),
            isAllDay: false,
            isVirtual: false,
            requiresRegistration: true,
            currentRegistrations: 156,
            category: .worship,
            tags: ["christmas"],
            volunteerRoles: [],
            createdAt: Date(),
            isPublished: true,
            isFeatured: true,
        ),
        ChurchEvent(
            id: "2",
            churchId: "1",
            title: "Youth Night",
            description: "Games and fellowship",
            startDate: Date().addingTimeInterval(86400 * 2),
            isAllDay: false,
            isVirtual: false,
            requiresRegistration: false,
            currentRegistrations: 0,
            category: .youth,
            tags: [],
            volunteerRoles: [],
            createdAt: Date(),
            isPublished: true,
            isFeatured: false,
        ),
        ChurchEvent(
            id: "3",
            churchId: "1",
            title: "Community Outreach",
            description: "Serving our neighborhood",
            startDate: Date().addingTimeInterval(86400 * 7),
            isAllDay: false,
            isVirtual: false,
            requiresRegistration: true,
            currentRegistrations: 24,
            category: .outreach,
            tags: [],
            volunteerRoles: [],
            createdAt: Date(),
            isPublished: true,
            isFeatured: false,
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // View Mode Toggle
            HStack {
                Picker("View", selection: $viewMode) {
                    ForEach(EventViewMode.allCases, id: \.self) { mode in
                        Image(systemName: mode == .list ? "list.bullet" : "calendar")
                            .tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 100)

                Spacer()

                // Category Filter
                Menu {
                    Button("All Categories") { selectedCategory = nil }
                    Divider()
                    ForEach(EventCategory.allCases, id: \.self) { category in
                        Button(category.rawValue.capitalized) {
                            selectedCategory = category
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCategory?.rawValue.capitalized ?? "All")
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .foregroundColor(.churchTalkRed)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Events List or Calendar
            if viewMode == .list {
                List {
                    ForEach(filteredEvents) { event in
                        NavigationLink(destination: EventDetailView(event: event)) {
                            EventRowView(event: event)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            } else {
                // Calendar view
                EventCalendarView(
                    events: filteredEvents,
                    selectedDate: $selectedDate,
                    onEventTap: { event in
                        selectedEvent = event
                    }
                )
            }
        }
    }

    var filteredEvents: [ChurchEvent] {
        guard let category = selectedCategory else { return events }
        return events.filter { $0.category == category }
    }
}

struct EventRowView: View {
    let event: ChurchEvent

    var body: some View {
        HStack(spacing: 12) {
            // Date Box
            VStack(spacing: 2) {
                Text(monthString)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.churchTalkRed)

                Text(dayString)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .frame(width: 50, height: 50)
            .background(Color.churchTalkRed.opacity(0.1))
            .cornerRadius(8)

            // Event Info
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if event.requiresRegistration {
                        Text("\(event.currentRegistrations) registered")
                            .font(.caption)
                            .foregroundColor(.churchTalkRed)
                    }
                }

                // Category Chip
                Text(event.category.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(categoryColor.opacity(0.2))
                    .foregroundColor(categoryColor)
                    .cornerRadius(4)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: event.startDate).uppercased()
    }

    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: event.startDate)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startDate)
    }

    private var categoryColor: Color {
        switch event.category {
        case .worship: return .purple
        case .outreach: return .green
        case .youth: return .orange
        case .children: return .pink
        case .smallGroup: return .blue
        case .missions: return .teal
        case .fellowship: return .red
        case .training: return .indigo
        case .special: return .yellow
        case .other: return .gray
        }
    }
}

struct MyCommitmentsSection: View {
    // Demo volunteer commitments
    let commitments = [
        VolunteerCommitment(
            id: "1",
            eventTitle: "Sunday Service",
            role: "Greeter",
            date: Date().addingTimeInterval(86400 * 3),
            status: .confirmed
        ),
        VolunteerCommitment(
            id: "2",
            eventTitle: "Youth Night",
            role: "Small Group Leader",
            date: Date().addingTimeInterval(86400 * 2),
            status: .pending
        )
    ]

    var body: some View {
        if commitments.isEmpty {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)

                Text("No Volunteer Commitments")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Sign up to serve at upcoming events")
                    .foregroundColor(.secondary)

                Spacer()
            }
        } else {
            List {
                ForEach(commitments) { commitment in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(commitment.eventTitle)
                                .font(.body)
                                .fontWeight(.medium)

                            Spacer()

                            StatusBadge(status: commitment.status)
                        }

                        Text(commitment.role)
                            .font(.subheadline)
                            .foregroundColor(.churchTalkRed)

                        Text(formatDate(commitment.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }
}

struct VolunteerCommitment: Identifiable {
    let id: String
    let eventTitle: String
    let role: String
    let date: Date
    let status: CommitmentStatus

    enum CommitmentStatus {
        case pending, confirmed, declined
    }
}

struct StatusBadge: View {
    let status: VolunteerCommitment.CommitmentStatus

    var body: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }

    var statusText: String {
        switch status {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .declined: return "Declined"
        }
    }

    var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .confirmed: return .green
        case .declined: return .red
        }
    }
}

struct OutreachSection: View {
    var body: some View {
        OutreachHomeView()
    }
}

#Preview {
    ServeTabView()
        .environmentObject(AuthViewModel())
}
