import SwiftUI
import EventKit

struct EventRegistrationSheet: View {
    let event: ChurchEvent
    let onComplete: (Bool) -> Void

    @State private var guestCount = 0
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    @State private var calendarAddStatus: CalendarAddStatus = .idle
    @State private var showCalendarAlert = false
    @State private var calendarAlertMessage = ""
    @Environment(\.dismiss) private var dismiss

    private enum CalendarAddStatus {
        case idle
        case adding
        case added
        case failed
    }

    var body: some View {
        NavigationStack {
            if showConfirmation {
                registrationConfirmation
            } else {
                registrationForm
            }
        }
    }

    private var registrationForm: some View {
        Form {
            // Event Summary
            Section {
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text(event.startDate.formatted(.dateTime.month(.abbreviated)))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.churchTalkRed)
                        Text(event.startDate.formatted(.dateTime.day()))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(width: 50)
                    .padding(.vertical, 8)
                    .background(Color.churchTalkRed.opacity(0.1))
                    .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                        Text(event.timeDisplayString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let location = event.location?.name {
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Guest Count
            Section {
                Stepper(value: $guestCount, in: 0...10) {
                    HStack {
                        Text("Additional Guests")
                        Spacer()
                        Text("\(guestCount)")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Attendance")
            } footer: {
                Text("You are automatically registered. Add any guests who will attend with you.")
            }

            // Notes
            Section {
                TextField("Any special requirements or notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Notes (Optional)")
            }

            // Spots remaining
            if let remaining = event.spotsRemaining {
                Section {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.orange)
                        Text("\(remaining) spots remaining")
                            .foregroundColor(remaining < 10 ? .orange : .secondary)
                    }
                }
            }
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onComplete(false)
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Register") {
                    submitRegistration()
                }
                .fontWeight(.semibold)
                .disabled(isSubmitting)
            }
        }
        .disabled(isSubmitting)
        .overlay {
            if isSubmitting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("Registering...")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
            }
        }
    }

    private var registrationConfirmation: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.amenGreen)

            VStack(spacing: 8) {
                Text("You're Registered!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("You've successfully registered for")
                    .foregroundColor(.secondary)

                Text(event.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.churchTalkRed)
                    Text(event.dateDisplayString)
                }

                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.churchTalkRed)
                    Text(event.timeDisplayString)
                }

                if let location = event.location?.name {
                    HStack {
                        Image(systemName: "mappin")
                            .foregroundColor(.churchTalkRed)
                        Text(location)
                    }
                }

                if guestCount > 0 {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.churchTalkRed)
                        Text("+\(guestCount) guest\(guestCount > 1 ? "s" : "")")
                    }
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    addToCalendar()
                } label: {
                    HStack {
                        switch calendarAddStatus {
                        case .idle:
                            Image(systemName: "calendar.badge.plus")
                            Text("Add to Calendar")
                        case .adding:
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Adding...")
                        case .added:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.amenGreen)
                            Text("Added to Calendar")
                        case .failed:
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.orange)
                            Text("Try Again")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(calendarAddStatus == .added ? Color.amenGreen.opacity(0.1) : Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .disabled(calendarAddStatus == .adding || calendarAddStatus == .added)

                Button {
                    onComplete(true)
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.churchTalkRed)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .padding()
        .alert("Calendar", isPresented: $showCalendarAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(calendarAlertMessage)
        }
    }

    private func addToCalendar() {
        calendarAddStatus = .adding

        let eventStore = EKEventStore()

        // Request calendar access
        if #available(iOS 17.0, *) {
            eventStore.requestWriteOnlyAccessToEvents { granted, error in
                handleCalendarAccess(granted: granted, error: error, eventStore: eventStore)
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                handleCalendarAccess(granted: granted, error: error, eventStore: eventStore)
            }
        }
    }

    private func handleCalendarAccess(granted: Bool, error: Error?, eventStore: EKEventStore) {
        DispatchQueue.main.async {
            if let error = error {
                print("Calendar access error: \(error)")
                calendarAddStatus = .failed
                calendarAlertMessage = "Failed to access calendar: \(error.localizedDescription)"
                showCalendarAlert = true
                return
            }

            guard granted else {
                calendarAddStatus = .failed
                calendarAlertMessage = "Calendar access was denied. Please enable calendar access in Settings to add events."
                showCalendarAlert = true
                return
            }

            // Create calendar event
            let calendarEvent = EKEvent(eventStore: eventStore)
            calendarEvent.title = event.title
            calendarEvent.startDate = event.startDate
            calendarEvent.endDate = event.endDate ?? event.startDate.addingTimeInterval(3600) // Default 1 hour
            calendarEvent.notes = event.description

            // Add location if available
            if let location = event.location {
                calendarEvent.location = location.name
                if let address = location.address {
                    calendarEvent.location = "\(location.name), \(address)"
                }
            }

            // Add reminder 1 day before
            let alarm = EKAlarm(relativeOffset: -86400) // 24 hours before
            calendarEvent.addAlarm(alarm)

            // Add reminder 1 hour before
            let hourAlarm = EKAlarm(relativeOffset: -3600) // 1 hour before
            calendarEvent.addAlarm(hourAlarm)

            calendarEvent.calendar = eventStore.defaultCalendarForNewEvents

            do {
                try eventStore.save(calendarEvent, span: .thisEvent)
                calendarAddStatus = .added

                // Success haptic
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                calendarAlertMessage = "Event has been added to your calendar with reminders."
                showCalendarAlert = true
            } catch {
                print("Failed to save calendar event: \(error)")
                calendarAddStatus = .failed
                calendarAlertMessage = "Failed to add event to calendar: \(error.localizedDescription)"
                showCalendarAlert = true
            }
        }
    }

    private func submitRegistration() {
        isSubmitting = true

        Task {
            do {
                _ = try await EventsAPI.shared.registerForEvent(
                    eventId: event.id,
                    guestCount: guestCount,
                    notes: notes.isEmpty ? nil : notes
                )
                await MainActor.run {
                    isSubmitting = false
                    withAnimation {
                        showConfirmation = true
                    }

                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                print("Failed to register: \(error)")
                await MainActor.run {
                    isSubmitting = false

                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - Event Check-In View

struct EventCheckInView: View {
    let event: ChurchEvent
    let registration: EventRegistration
    @State private var isCheckingIn = false
    @State private var checkedIn = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                if checkedIn {
                    // Checked In State
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.amenGreen)

                        Text("Checked In!")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Welcome to \(event.title)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    // Check-In Button
                    VStack(spacing: 24) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.churchTalkRed)

                        Text(event.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "calendar")
                                Text(event.dateDisplayString)
                            }
                            HStack {
                                Image(systemName: "clock")
                                Text(event.timeDisplayString)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }

                    Button {
                        performCheckIn()
                    } label: {
                        HStack {
                            if isCheckingIn {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle")
                            }
                            Text(isCheckingIn ? "Checking In..." : "Check In Now")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.churchTalkRed)
                        .cornerRadius(16)
                    }
                    .disabled(isCheckingIn)
                    .padding(.horizontal, 32)
                }

                Spacer()
            }
            .navigationTitle("Event Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func performCheckIn() {
        isCheckingIn = true

        // Simulate check-in API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCheckingIn = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                checkedIn = true
            }
        }
    }
}

#Preview("Registration") {
    EventRegistrationSheet(event: ChurchEvent.sampleEvents[1]) { success in
        print("Registration: \(success)")
    }
}

#Preview("Check-In") {
    EventCheckInView(
        event: ChurchEvent.sampleEvents[0],
        registration: EventRegistration(
            id: "1",
            eventId: "1",
            memberId: "user1",
            status: .registered,
            registeredAt: Date()
        )
    )
}
