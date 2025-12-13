import SwiftUI

struct EventRegistrationSheet: View {
    let event: ChurchEvent
    let onComplete: (Bool) -> Void

    @State private var guestCount = 0
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    @Environment(\.dismiss) private var dismiss

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
                    // TODO: Add to calendar
                } label: {
                    Label("Add to Calendar", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }

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
    }

    private func submitRegistration() {
        isSubmitting = true

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            withAnimation {
                showConfirmation = true
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
