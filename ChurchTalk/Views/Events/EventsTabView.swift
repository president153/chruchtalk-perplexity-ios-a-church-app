import SwiftUI

struct EventsTabView: View {
    @State private var viewMode: EventViewMode = .list
    @State private var selectedCategory: EventCategory? = nil
    @State private var selectedDate = Date()
    @State private var showingEventDetail: ChurchEvent? = nil

    // Sample data - replace with actual data from ViewModel
    private let events = ChurchEvent.sampleEvents

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View Mode Toggle
                Picker("View", selection: $viewMode) {
                    ForEach(EventViewMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.iconName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryFilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            color: .churchTalkRed
                        ) {
                            selectedCategory = nil
                        }

                        ForEach(EventCategory.allCases, id: \.self) { category in
                            CategoryFilterChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                color: category.color
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)

                // Content
                switch viewMode {
                case .list:
                    EventListView(
                        events: filteredEvents,
                        onEventTap: { event in
                            showingEventDetail = event
                        }
                    )
                case .calendar:
                    EventCalendarView(
                        events: filteredEvents,
                        selectedDate: $selectedDate,
                        onEventTap: { event in
                            showingEventDetail = event
                        }
                    )
                }
            }
            .navigationTitle("Events")
            .sheet(item: $showingEventDetail) { event in
                EventDetailView(event: event)
            }
        }
    }

    private var filteredEvents: [ChurchEvent] {
        if let category = selectedCategory {
            return events.filter { $0.category == category }
        }
        return events
    }
}

enum EventViewMode: String, CaseIterable {
    case list = "List"
    case calendar = "Calendar"

    var iconName: String {
        switch self {
        case .list: return "list.bullet"
        case .calendar: return "calendar"
        }
    }
}

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

#Preview {
    EventsTabView()
}
