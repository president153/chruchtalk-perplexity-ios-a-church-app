import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = "John"
    @State private var lastName = "Doe"
    @State private var email = "john.doe@email.com"
    @State private var phone = "(555) 123-4567"
    @State private var dateOfBirth = Date()
    @State private var showDatePicker = false

    // Address
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""

    // Photo picker
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?

    // Navigation
    @State private var showSpiritualJourney = false
    @State private var showFamilyManagement = false

    var body: some View {
        NavigationStack {
            Form {
                // Profile Photo Section
                Section {
                    HStack {
                        Spacer()

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                if let profileImage {
                                    profileImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.churchTalkRed.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Text("\(firstName.prefix(1))\(lastName.prefix(1))")
                                                .font(.largeTitle)
                                                .fontWeight(.bold)
                                                .foregroundColor(.churchTalkRed)
                                        )
                                }

                                Circle()
                                    .fill(Color.churchTalkRed)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .onChange(of: selectedPhoto) { _, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    profileImage = Image(uiImage: uiImage)
                                }
                            }
                        }

                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // Personal Information
                Section("Personal Information") {
                    HStack {
                        Text("First Name")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("First Name", text: $firstName)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Last Name")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("Last Name", text: $lastName)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Email")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("Email", text: $email)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }

                    HStack {
                        Text("Phone")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("Phone", text: $phone)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.phonePad)
                    }

                    Button(action: { showDatePicker = true }) {
                        HStack {
                            Text("Date of Birth")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.primary)
                            Image(systemName: "calendar")
                                .foregroundColor(.churchTalkRed)
                        }
                    }

                    HStack {
                        Text("Age")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(calculateAge()) years old")
                            .foregroundColor(.primary)
                    }
                }

                // Address
                Section("Address") {
                    HStack {
                        Text("Street")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("123 Main St", text: $street)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("City")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("City", text: $city)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("State")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("CA", text: $state)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                    }

                    HStack {
                        Text("ZIP Code")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("12345", text: $zipCode)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                }

                // Spiritual Journey
                Section("Faith Journey") {
                    Button(action: { showSpiritualJourney = true }) {
                        HStack {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundColor(.churchTalkRed)
                            Text("Spiritual Journey")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // Family
                Section("Family") {
                    Button(action: { showFamilyManagement = true }) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.churchTalkRed)
                            Text("Manage Family Members")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // Milestones
                Section("Milestones") {
                    MilestoneRow(icon: "cross.fill", title: "Salvation", date: Date().addingTimeInterval(-86400 * 365 * 5))
                    MilestoneRow(icon: "drop.fill", title: "Baptism", date: Date().addingTimeInterval(-86400 * 365 * 4))
                    MilestoneRow(icon: "person.crop.circle.badge.checkmark", title: "Membership", date: Date().addingTimeInterval(-86400 * 365 * 3))
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.churchTalkRed)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DateOfBirthPicker(date: $dateOfBirth)
            }
            .sheet(isPresented: $showSpiritualJourney) {
                SpiritualJourneyView()
            }
            .sheet(isPresented: $showFamilyManagement) {
                FamilyManagementView()
            }
        }
    }

    private func calculateAge() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return components.year ?? 0
    }

    private func saveProfile() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        dismiss()
    }
}

struct MilestoneRow: View {
    let icon: String
    let title: String
    let date: Date?

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.churchTalkRed)
                .frame(width: 24)

            Text(title)

            Spacer()

            if let date {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .foregroundColor(.secondary)
            } else {
                Text("Not recorded")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

struct DateOfBirthPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Date of Birth")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                DatePicker(
                    "Select Date",
                    selection: $date,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.churchTalkRed)
                .padding()

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.churchTalkRed)
                        .cornerRadius(ChurchTalkTheme.cornerRadius)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    EditProfileView()
}
