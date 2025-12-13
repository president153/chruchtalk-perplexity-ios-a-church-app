import SwiftUI

struct TermsPrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Document", selection: $selectedTab) {
                    Text("Terms").tag(0)
                    Text("Privacy").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if selectedTab == 0 {
                            termsContent
                        } else {
                            privacyContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Terms & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Terms of Service")
                .font(.title2)
                .fontWeight(.bold)

            Text("Last updated: December 2024")
                .font(.caption)
                .foregroundColor(.secondary)

            Group {
                sectionTitle("1. Acceptance of Terms")
                Text("By accessing and using ChurchTalk, you accept and agree to be bound by the terms and provisions of this agreement.")

                sectionTitle("2. Use License")
                Text("Permission is granted to temporarily download one copy of ChurchTalk for personal, non-commercial transitory viewing only.")

                sectionTitle("3. User Conduct")
                Text("You agree to use ChurchTalk only for lawful purposes and in a way that does not infringe the rights of, restrict or inhibit anyone else's use and enjoyment of the app.")

                sectionTitle("4. Content")
                Text("Users are responsible for all content they post, including prayer requests, comments, and messages. Content must align with community guidelines.")

                sectionTitle("5. Privacy")
                Text("Your use of ChurchTalk is also governed by our Privacy Policy, which is incorporated into these Terms of Service.")
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
    }

    private var privacyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy Policy")
                .font(.title2)
                .fontWeight(.bold)

            Text("Last updated: December 2024")
                .font(.caption)
                .foregroundColor(.secondary)

            Group {
                sectionTitle("Information We Collect")
                Text("We collect information you provide directly, such as your name, email, and church membership details.")

                sectionTitle("How We Use Your Information")
                Text("We use your information to provide and improve ChurchTalk, facilitate church community connections, and send relevant notifications.")

                sectionTitle("Information Sharing")
                Text("We share your information with your church community as needed for the app to function. We do not sell your personal information.")

                sectionTitle("Data Security")
                Text("We implement appropriate security measures to protect your personal information against unauthorized access or disclosure.")

                sectionTitle("Your Rights")
                Text("You can access, update, or delete your personal information at any time through your profile settings.")

                sectionTitle("Contact Us")
                Text("If you have questions about this Privacy Policy, please contact us at privacy@churchtalk.app")
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.top, 8)
    }
}

#Preview {
    TermsPrivacyView()
}
