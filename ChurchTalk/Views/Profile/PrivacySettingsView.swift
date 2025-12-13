import SwiftUI

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showInDirectory") private var showInDirectory = true
    @AppStorage("showEmail") private var showEmail = true
    @AppStorage("showPhone") private var showPhone = false
    @AppStorage("allowMessages") private var allowMessages = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Show in Member Directory", isOn: $showInDirectory)
                } header: {
                    Text("Directory Visibility")
                } footer: {
                    Text("Allow other church members to find you in the directory")
                }

                Section {
                    Toggle("Show Email Address", isOn: $showEmail)
                    Toggle("Show Phone Number", isOn: $showPhone)
                } header: {
                    Text("Contact Information")
                } footer: {
                    Text("Control which contact info is visible to other members")
                }

                Section {
                    Toggle("Allow Direct Messages", isOn: $allowMessages)
                } header: {
                    Text("Communication")
                } footer: {
                    Text("Let other members send you messages through the app")
                }

                Section {
                    Button("Download My Data") {
                        // Request data export
                    }
                    .foregroundColor(.churchTalkRed)

                    Button("Delete My Account") {
                        // Show delete confirmation
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Data")
                }
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    PrivacySettingsView()
}
