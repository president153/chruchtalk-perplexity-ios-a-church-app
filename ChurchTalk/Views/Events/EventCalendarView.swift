import SwiftUI

struct EventCalendarView: View {
    let events: [ChurchEvent]
    @Binding var selectedDate: Date
    let onEventTap: (ChurchEvent) -> Void

    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 0) {
            // Month Navigation
            HStack {
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.churchTalkRed)
                }

                Spacer()

                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.churchTalkRed)
                }
            }
            .padding()

            // Days of Week Header
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Calendar Grid
            let days = generateDaysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasEvents: eventsForDate(date).count > 0,
                            eventCount: eventsForDate(date).count
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
            .padding(.horizontal)

            Divider()
                .padding(.vertical)

            // Events for Selected Date
            VStack(alignment: .leading, spacing: 12) {
                Text(selectedDate.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.headline)
                    .padding(.horizontal)

                let dayEvents = eventsForDate(selectedDate)
                if dayEvents.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.minus")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No events on this day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(dayEvents) { event in
                                CalendarEventRow(event: event) {
                                    onEventTap(event)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            Spacer()
        }
    }

    private func generateDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }

        var days: [Date?] = []

        // Add empty cells for days before the first of the month
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // Add all days of the month
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return days
    }

    private func eventsForDate(_ date: Date) -> [ChurchEvent] {
        events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    let eventCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(textColor)

                // Event Indicator
                if hasEvents {
                    HStack(spacing: 2) {
                        ForEach(0..<min(eventCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(isSelected ? Color.white : Color.churchTalkRed)
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday && !isSelected ? Color.churchTalkRed : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var textColor: Color {
        if isSelected {
            return .white
        }
        return .primary
    }

    private var backgroundColor: Color {
        if isSelected {
            return .churchTalkRed
        }
        return .clear
    }
}

struct CalendarEventRow: View {
    let event: ChurchEvent
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time
                VStack(alignment: .trailing) {
                    Text(event.startDate.formatted(.dateTime.hour().minute()))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(width: 60)

                // Color Bar
                Rectangle()
                    .fill(event.category.color)
                    .frame(width: 4)
                    .cornerRadius(2)

                // Event Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if let location = event.location?.name {
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EventCalendarView(
        events: ChurchEvent.sampleEvents,
        selectedDate: .constant(Date())
    ) { event in
        print("Selected: \(event.title)")
    }
}
