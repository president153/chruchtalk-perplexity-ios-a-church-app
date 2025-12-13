import SwiftUI

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss

    let faqs = [
        ("How do I update my profile?", "Go to Profile > Edit Profile to update your personal information, photo, and contact details."),
        ("How do I register for events?", "Navigate to the Serve tab, find the event you want to attend, and tap 'Register' on the event detail page."),
        ("How do I submit a prayer request?", "Go to the Connect tab, select 'Prayer', and tap 'Share a Prayer Request' to submit your prayer."),
        ("Can I remain anonymous for prayer requests?", "Yes! When submitting a prayer request, toggle on the 'Anonymous' option to hide your name."),
        ("How do I add events to my calendar?", "Open any event and tap the calendar icon to add it to your device's calendar with reminders."),
        ("How do I contact the church office?", "You can find church contact information by tapping on the church name or checking the Profile tab.")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(faqs, id: \.0) { faq in
                        FAQRow(question: faq.0, answer: faq.1)
                    }
                } header: {
                    Text("Frequently Asked Questions")
                }

                Section {
                    Button {
                        sendSupportEmail()
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.churchTalkRed)
                            Text("Email Support")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Contact Support")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("App Info")
                }
            }
            .navigationTitle("Help Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func sendSupportEmail() {
        if let url = URL(string: "mailto:support@churchtalk.app?subject=ChurchTalk%20Support") {
            UIApplication.shared.open(url)
        }
    }
}

struct FAQRow: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                Text(answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HelpCenterView()
}
