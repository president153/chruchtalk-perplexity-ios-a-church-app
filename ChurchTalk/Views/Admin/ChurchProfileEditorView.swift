import SwiftUI

struct ChurchProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedSection = 0

    // Church data (in production, bind to actual church model)
    @State private var churchName = "First Baptist Church"
    @State private var denomination = "Southern Baptist"
    @State private var aboutContent = "A welcoming community dedicated to sharing God's love."
    @State private var foundedYear = "1952"

    // Contact
    @State private var phone = "(661) 555-1234"
    @State private var email = "info@firstbaptist.org"
    @State private var website = "https://firstbaptist.org"
    @State private var officeHours = "Mon-Fri 9am-5pm"

    // Address
    @State private var street = "123 Main Street"
    @State private var city = "Lancaster"
    @State private var state = "CA"
    @State private var zipCode = "93534"

    // Social Links
    @State private var facebook = "https://facebook.com/firstbaptist"
    @State private var instagram = "https://instagram.com/firstbaptist"
    @State private var youtube = "https://youtube.com/@firstbaptist"

    // Mission & Vision
    @State private var missionStatement = "To share God's love with our community."
    @State private var visionStatement = "To be a beacon of hope in our city."
    @State private var coreValuesText = "Faith, Community, Service, Love"

    let sections = ["Basic Info", "Contact", "Social", "Leadership", "Mission", "Ministries"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<sections.count, id: \.self) { index in
                            Button {
                                withAnimation { selectedSection = index }
                            } label: {
                                Text(sections[index])
                                    .font(.subheadline)
                                    .fontWeight(selectedSection == index ? .semibold : .regular)
                                    .foregroundColor(selectedSection == index ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedSection == index ? Color.churchTalkRed : Color(.systemGray6))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }

                Divider()

                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedSection {
                        case 0: basicInfoSection
                        case 1: contactSection
                        case 2: socialLinksSection
                        case 3: leadershipSection
                        case 4: missionVisionSection
                        case 5: ministriesSection
                        default: basicInfoSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Church Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.churchTalkRed)
                }
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Basic Information", icon: "building.2.fill")

            EditorTextField(label: "Church Name", text: $churchName)
            EditorTextField(label: "Denomination", text: $denomination)
            EditorTextField(label: "Founded Year", text: $foundedYear, keyboardType: .numberPad)

            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $aboutContent)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            // Address
            SectionHeader(title: "Location", icon: "mappin.circle.fill")

            EditorTextField(label: "Street Address", text: $street)

            HStack(spacing: 12) {
                EditorTextField(label: "City", text: $city)
                EditorTextField(label: "State", text: $state)
                    .frame(width: 80)
            }

            EditorTextField(label: "ZIP Code", text: $zipCode, keyboardType: .numberPad)
        }
    }

    // MARK: - Contact Section

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Contact Information", icon: "phone.fill")

            EditorTextField(label: "Phone", text: $phone, keyboardType: .phonePad)
            EditorTextField(label: "Email", text: $email, keyboardType: .emailAddress)
            EditorTextField(label: "Website", text: $website, keyboardType: .URL)
            EditorTextField(label: "Office Hours", text: $officeHours)
        }
    }

    // MARK: - Social Links Section

    private var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Social Media Links", icon: "globe")

            SocialLinkField(platform: "Facebook", icon: "f.circle.fill", url: $facebook)
            SocialLinkField(platform: "Instagram", icon: "camera.fill", url: $instagram)
            SocialLinkField(platform: "YouTube", icon: "play.rectangle.fill", url: $youtube)
        }
    }

    // MARK: - Leadership Section

    private var leadershipSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Leadership Team", icon: "person.3.fill")

            Text("Add your pastor and leadership team members.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Pastor placeholder
            Button {
                // Add/Edit pastor
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Pastor")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.churchTalkRed)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.churchTalkRed.opacity(0.1))
                .cornerRadius(12)
            }

            Button {
                // Add team member
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Team Member")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Mission & Vision Section

    private var missionVisionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Mission & Vision", icon: "target")

            VStack(alignment: .leading, spacing: 8) {
                Text("Mission Statement")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $missionStatement)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Vision Statement")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $visionStatement)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Core Values (comma separated)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Faith, Love, Community...", text: $coreValuesText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }

    // MARK: - Ministries Section

    private var ministriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Ministries", icon: "hands.sparkles.fill")

            Text("Add the ministries available at your church.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                // Add ministry
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Ministry")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.churchTalkRed)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.churchTalkRed.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Save

    private func saveChanges() {
        // In production, save to backend/database
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - Helper Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.churchTalkRed)
            Text(title)
                .font(.headline)
        }
        .padding(.top, 8)
    }
}

struct EditorTextField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField(label, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct SocialLinkField: View {
    let platform: String
    let icon: String
    @Binding var url: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.churchTalkRed)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(platform)
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("URL", text: $url)
                    .font(.caption)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ChurchProfileEditorView()
        .environmentObject(AuthViewModel())
}
