import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("pushEnabled") private var pushEnabled = true
    @AppStorage("eventReminders") private var eventReminders = true
    @AppStorage("prayerRequests") private var prayerRequests = true
    @AppStorage("announcements") private var announcements = true
    @AppStorage("volunteerRequests") private var volunteerRequests = true
    @AppStorage("messageNotifications") private var messageNotifications = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Push Notifications", isOn: $pushEnabled)
                } footer: {
                    Text("Enable push notifications to stay updated with church activities")
                }

                Section {
                    Toggle("Event Reminders", isOn: $eventReminders)
                    Toggle("Volunteer Requests", isOn: $volunteerRequests)
                } header: {
                    Text("Events")
                }

                Section {
                    Toggle("Prayer Requests", isOn: $prayerRequests)
                    Toggle("Announcements", isOn: $announcements)
                    Toggle("Messages", isOn: $messageNotifications)
                } header: {
                    Text("Community")
                }

                Section {
                    Button(action: openSystemSettings) {
                        HStack {
                            Text("System Notification Settings")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                } footer: {
                    Text("Manage notifications in iOS Settings")
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NotificationSettingsView()
}
