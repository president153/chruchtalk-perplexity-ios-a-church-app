import SwiftUI

struct EventDetailView: View {
    let event: ChurchEvent
    @State private var showRegistration = false
    @State private var isRegistered = false
    @State private var showCalendarAlert = false
    @State private var calendarAlertMessage = ""
    @State private var calendarSuccess = false
    @State private var showVolunteerAlert = false
    @State private var selectedRole: VolunteerRole?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Image
                    ZStack(alignment: .bottomLeading) {
                        if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                headerPlaceholder
                            }
                        } else {
                            headerPlaceholder
                        }
                    }
                    .frame(height: 200)
                    .clipped()

                    VStack(spacing: 20) {
                        // Title and Category
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(event.category.displayName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(event.category.color)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(event.category.color.opacity(0.1))
                                    .cornerRadius(12)

                                if event.isFeatured {
                                    Label("Featured", systemImage: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }

                                Spacer()
                            }

                            Text(event.title)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)

                        // Date & Time Card
                        HStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.churchTalkRed)
                                .frame(width: 44, height: 44)
                                .background(Color.churchTalkRed.opacity(0.1))
                                .cornerRadius(12)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.dateDisplayString)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(event.timeDisplayString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // Add to Calendar Button
                            Button {
                                addToCalendar()
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.title3)
                                    Text("Add")
                                        .font(.caption2)
                                }
                                .foregroundColor(.churchTalkRed)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Location Card
                        if let location = event.location {
                            HStack(spacing: 16) {
                                Image(systemName: event.isVirtual ? "video.fill" : "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.isVirtual ? "Virtual Event" : (location.name ?? "Location"))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if let address = location.address {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if event.isVirtual, let meetingUrl = event.virtualMeetingUrl {
                                        Button {
                                            openURL(meetingUrl)
                                        } label: {
                                            Text("Join Meeting")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }

                                Spacer()

                                if !event.isVirtual {
                                    Button {
                                        openInMaps(location: location)
                                    } label: {
                                        VStack(spacing: 2) {
                                            Image(systemName: "map.fill")
                                                .font(.title3)
                                            Text("Maps")
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // Registration Info
                        if event.requiresRegistration {
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Registration Required")
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        if let remaining = event.spotsRemaining {
                                            Text("\(remaining) spots remaining")
                                                .font(.caption)
                                                .foregroundColor(remaining < 10 ? .orange : .secondary)
                                        }
                                    }

                                    Spacer()

                                    if event.isFull {
                                        Text("FULL")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.red)
                                            .cornerRadius(8)
                                    }
                                }

                                // Progress bar
                                if let max = event.maxCapacity {
                                    ProgressView(value: Double(event.currentRegistrations), total: Double(max))
                                        .tint(event.isFull ? .red : .churchTalkRed)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // Description
                        if let description = event.description {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About")
                                    .font(.headline)

                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // Volunteer Opportunities
                        if let roles = event.volunteerRoles, !roles.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Volunteer Opportunities")
                                    .font(.headline)

                                ForEach(roles) { role in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(role.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("\(role.filledCount)/\(role.requiredCount) filled")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        if !role.isFilled {
                                            Button("Volunteer") {
                                                selectedRole = role
                                                showVolunteerAlert = true
                                            }
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.amenGreen)
                                            .cornerRadius(8)
                                        } else {
                                            Text("Filled")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top)
                }
            }
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .bottom) {
                // Register Button
                if event.requiresRegistration && !event.isPast {
                    VStack {
                        Button {
                            if isRegistered {
                                isRegistered = false
                            } else {
                                showRegistration = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: isRegistered ? "checkmark.circle.fill" : "person.badge.plus")
                                Text(isRegistered ? "Registered" : (event.isFull ? "Join Waitlist" : "Register"))
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isRegistered ? Color.amenGreen : (event.isFull ? Color.orange : Color.churchTalkRed))
                            .cornerRadius(ChurchTalkTheme.cornerRadius)
                        }
                        .disabled(event.isPast)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(
                        item: shareText,
                        subject: Text(event.title),
                        message: Text(event.description ?? "")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showRegistration) {
                EventRegistrationSheet(event: event) { success in
                    if success {
                        isRegistered = true
                    }
                    showRegistration = false
                }
            }
            .alert(calendarSuccess ? "Added to Calendar" : "Calendar Error", isPresented: $showCalendarAlert) {
                Button("OK") { }
            } message: {
                Text(calendarAlertMessage)
            }
            .alert("Volunteer Sign Up", isPresented: $showVolunteerAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Up") {
                    // Simulate sign up
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } message: {
                if let role = selectedRole {
                    Text("Would you like to volunteer as \(role.name) for this event?")
                }
            }
        }
    }

    // MARK: - Share Text

    private var shareText: String {
        var text = "Check out \(event.title)!\n"
        text += "\(event.dateDisplayString)\n"
        if let location = event.location?.name {
            text += "📍 \(location)\n"
        }
        if let desc = event.description {
            text += "\n\(desc)"
        }
        return text
    }

    // MARK: - Actions

    private func addToCalendar() {
        Task {
            do {
                _ = try await CalendarService.shared.addChurchEventToCalendar(event)
                await MainActor.run {
                    calendarSuccess = true
                    calendarAlertMessage = "\"\(event.title)\" has been added to your calendar with reminders."
                    showCalendarAlert = true

                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    calendarSuccess = false
                    calendarAlertMessage = error.localizedDescription
                    showCalendarAlert = true
                }
            }
        }
    }

    private func openInMaps(location: EventLocation) {
        var urlString = "maps://"

        if let lat = location.latitude, let lon = location.longitude {
            urlString += "?ll=\(lat),\(lon)&q=\(location.name ?? "Event")"
        } else if let address = location.address {
            let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            urlString += "?q=\(encoded)"
        } else if let name = location.name {
            let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            urlString += "?q=\(encoded)"
        }

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private var headerPlaceholder: some View {
        Rectangle()
            .fill(event.category.color.gradient)
            .overlay(
                VStack {
                    Image(systemName: event.category.iconName)
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.5))
                }
            )
    }
}

#Preview {
    EventDetailView(event: ChurchEvent.sampleEvents[2])
}
