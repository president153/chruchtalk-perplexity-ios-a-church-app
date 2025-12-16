import SwiftUI

struct EventsTabView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewMode: EventViewMode = .list
    @State private var selectedCategory: EventCategory? = nil
    @State private var selectedDate = Date()
    @State private var showingEventDetail: ChurchEvent? = nil

    // API data
    @State private var events: [ChurchEvent] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

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
                            Task { await loadEvents() }
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                } else {
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
            }
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadEvents()
            }
            .refreshable {
                await loadEvents()
            }
            .sheet(item: $showingEventDetail) { event in
                EventDetailView(event: event)
            }
        }
    }

    private func loadEvents() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedEvents = try await EventsAPI.shared.getEvents(limit: 100)
            await MainActor.run {
                events = fetchedEvents
                isLoading = false
            }
        } catch {
            print("Failed to load events: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load events"
                isLoading = false
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
