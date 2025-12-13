import Foundation
import EventKit
import SwiftUI

class CalendarService: ObservableObject {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                checkAuthorizationStatus()
            }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }

    // MARK: - Add Event to Calendar

    func addEventToCalendar(
        title: String,
        startDate: Date,
        endDate: Date?,
        location: String?,
        notes: String?,
        isAllDay: Bool = false
    ) async throws -> String {
        // Check authorization
        if authorizationStatus != .fullAccess && authorizationStatus != .authorized {
            let granted = await requestAccess()
            if !granted {
                throw CalendarError.accessDenied
            }
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate ?? startDate.addingTimeInterval(3600) // Default 1 hour
        event.isAllDay = isAllDay
        event.location = location
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents

        // Add reminder 1 day before
        let alarm = EKAlarm(relativeOffset: -86400) // 24 hours before
        event.addAlarm(alarm)

        // Add reminder 1 hour before
        let hourAlarm = EKAlarm(relativeOffset: -3600) // 1 hour before
        event.addAlarm(hourAlarm)

        try eventStore.save(event, span: .thisEvent)

        return event.eventIdentifier
    }

    // MARK: - Add Church Event

    func addChurchEventToCalendar(_ churchEvent: ChurchEvent) async throws -> String {
        var notes = churchEvent.description ?? ""

        // Add location details
        if let location = churchEvent.location {
            if let name = location.name {
                notes += "\n\nLocation: \(name)"
            }
            if let address = location.address {
                notes += "\n\(address)"
            }
        }

        // Add virtual meeting link
        if churchEvent.isVirtual, let virtualUrl = churchEvent.virtualMeetingUrl {
            notes += "\n\nVirtual Meeting: \(virtualUrl)"
        }

        return try await addEventToCalendar(
            title: churchEvent.title,
            startDate: churchEvent.startDate,
            endDate: churchEvent.endDate,
            location: churchEvent.location?.address ?? churchEvent.location?.name,
            notes: notes,
            isAllDay: churchEvent.isAllDay
        )
    }

    // MARK: - Remove Event

    func removeEvent(identifier: String) throws {
        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw CalendarError.eventNotFound
        }

        try eventStore.remove(event, span: .thisEvent)
    }
}

// MARK: - Errors

enum CalendarError: LocalizedError {
    case accessDenied
    case eventNotFound
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access was denied. Please enable calendar access in Settings."
        case .eventNotFound:
            return "The event could not be found in your calendar."
        case .saveFailed:
            return "Failed to save the event to your calendar."
        }
    }
}

// MARK: - SwiftUI View Modifier

struct AddToCalendarButton: View {
    let event: ChurchEvent
    @StateObject private var calendarService = CalendarService.shared
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var isLoading = false

    var body: some View {
        Button(action: addToCalendar) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "calendar.badge.plus")
                }
                Text("Add to Calendar")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .disabled(isLoading)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccess ? "Added!" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func addToCalendar() {
        isLoading = true

        Task {
            do {
                _ = try await calendarService.addChurchEventToCalendar(event)
                await MainActor.run {
                    isLoading = false
                    isSuccess = true
                    alertMessage = "\"\(event.title)\" has been added to your calendar with reminders."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    isSuccess = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddToCalendarButton(
        event: ChurchEvent(
            id: "1",
            churchId: "1",
            title: "Sunday Service",
            description: "Weekly worship service",
            startDate: Date().addingTimeInterval(86400),
            isAllDay: false,
            isVirtual: false,
            requiresRegistration: false,
            currentRegistrations: 0,
            category: .worship,
            tags: [],
            volunteerRoles: [],
            createdAt: Date(),
            isPublished: true,
            isFeatured: false
        )
    )
}
