import SwiftUI
import PhotosUI
import MapKit
import CoreLocation

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    // Form state - initialized from authViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var dateOfBirth = Date()
    @State private var showDatePicker = false

    // Address
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""

    // Map
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var addressCoordinate: CLLocationCoordinate2D?

    // Photo picker
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var selectedImageData: Data?

    // Navigation
    @State private var showSpiritualJourney = false
    @State private var showFamilyManagement = false

    // Loading/Error state
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    profilePhotoSection
                    personalInfoSection
                    addressSection
                    faithJourneySection
                    familySection
                    milestonesSection
                }
                .disabled(isSaving)
                .opacity(isSaving ? 0.6 : 1)

                if isSaving {
                    loadingOverlay
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.churchTalkRed)
                    .disabled(isSaving || !hasChanges())
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
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your profile has been updated successfully!")
            }
            .onAppear {
                loadCurrentData()
            }
        }
    }

    // MARK: - Extracted Sections

    private var profilePhotoSection: some View {
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
                            selectedImageData = data
                        }
                    }
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }

    private var personalInfoSection: some View {
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
                Text(email)
                    .foregroundColor(.primary.opacity(0.6))
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
    }

    private var addressSection: some View {
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
            if let coordinate = addressCoordinate {
                Map(position: .constant(.region(mapRegion))) {
                    Marker("", coordinate: coordinate)
                        .tint(.red)
                }
                .frame(height: 150)
                .cornerRadius(12)
                .allowsHitTesting(false)
            }
            if !street.isEmpty && !city.isEmpty && !state.isEmpty {
                Button {
                    geocodeAddress()
                } label: {
                    HStack {
                        Image(systemName: "location.magnifyingglass")
                        Text(addressCoordinate == nil ? "Show on Map" : "Update Map")
                    }
                    .font(.subheadline)
                    .foregroundColor(.churchTalkRed)
                }
            }
        }
    }

    private var faithJourneySection: some View {
        Section("Faith Journey") {
            Button(action: { showSpiritualJourney = true }) {
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundColor(.churchTalkRed)
                    Text("Spiritual Journey")
                    Spacer()
                    if let stage = authViewModel.currentMember?.spiritualJourney?.currentStage {
                        Text("Stage \(stage)")
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
        }
    }

    private var familySection: some View {
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
    }

    private var milestonesSection: some View {
        Section("Milestones") {
            MilestoneRow(
                icon: "cross.fill",
                title: "Salvation",
                date: authViewModel.currentMember?.spiritualJourney?.salvationDate
            )
            MilestoneRow(
                icon: "drop.fill",
                title: "Baptism",
                date: authViewModel.currentMember?.spiritualJourney?.baptismDate
            )
            MilestoneRow(
                icon: "person.crop.circle.badge.checkmark",
                title: "Membership",
                date: authViewModel.currentMember?.spiritualJourney?.membershipDate
            )
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            ProgressView("Saving...")
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
        }
    }

    // MARK: - Data Management

    private func loadCurrentData() {
        guard let member = authViewModel.currentMember else { return }

        firstName = member.firstName
        lastName = member.lastName
        email = member.email
        phone = member.phone ?? ""

        // Load date of birth if available
        if let dob = member.dateOfBirth {
            dateOfBirth = dob
        }

        // Load address if available
        if let address = member.address {
            street = address.street
            city = address.city
            state = address.state
            zipCode = address.zipCode ?? ""
            // Auto-geocode if address exists
            geocodeAddress()
        }

        // Load profile image if available
        if let photoUrl = member.profilePhotoUrl, let url = URL(string: photoUrl) {
            Task {
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }

    private func hasChanges() -> Bool {
        guard let member = authViewModel.currentMember else { return false }

        let nameChanged = firstName != member.firstName ||
                          lastName != member.lastName ||
                          phone != (member.phone ?? "")

        // Check address changes
        let currentAddress = member.address
        let addressChanged = street != (currentAddress?.street ?? "") ||
                             city != (currentAddress?.city ?? "") ||
                             state != (currentAddress?.state ?? "") ||
                             zipCode != (currentAddress?.zipCode ?? "")

        // Check if image was selected
        let imageChanged = selectedImageData != nil

        return nameChanged || addressChanged || imageChanged
    }

    private func calculateAge() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return components.year ?? 0
    }

    private func saveProfile() {
        guard let memberId = authViewModel.currentMember?.id else { return }

        isSaving = true

        Task {
            do {
                // Upload profile image if one was selected
                var profileImageUrl: String? = nil
                if let imageData = selectedImageData,
                   let uiImage = UIImage(data: imageData) {
                    profileImageUrl = try await UploadsAPI.shared.uploadImage(
                        uiImage,
                        uploadType: .profilePhoto
                    )
                }

                // Build address if any field is filled
                var addressRequest: AddressUpdateRequest? = nil
                if !street.isEmpty || !city.isEmpty || !state.isEmpty || !zipCode.isEmpty {
                    addressRequest = AddressUpdateRequest(
                        street: street.isEmpty ? nil : street,
                        city: city.isEmpty ? nil : city,
                        state: state.isEmpty ? nil : state,
                        zipCode: zipCode.isEmpty ? nil : zipCode
                    )
                }

                // Format date of birth as ISO8601 with time (backend expects datetime)
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime]
                let dateOfBirthString = dateFormatter.string(from: dateOfBirth)

                let request = MemberUpdateRequest(
                    firstName: firstName,
                    lastName: lastName,
                    phone: phone.isEmpty ? nil : phone,
                    profilePhotoUrl: profileImageUrl,
                    dateOfBirth: dateOfBirthString,
                    ministries: nil,
                    address: addressRequest
                )

                let updatedMember = try await MembersAPI.shared.updateMember(id: memberId, request: request)

                await MainActor.run {
                    // Update the local member in authViewModel
                    authViewModel.currentMember = updatedMember

                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    isSaving = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSaving = false

                    // Error haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }

    private func geocodeAddress() {
        let addressString = "\(street), \(city), \(state) \(zipCode)"
        let geocoder = CLGeocoder()

        geocoder.geocodeAddressString(addressString) { placemarks, error in
            if let placemark = placemarks?.first,
               let location = placemark.location {
                DispatchQueue.main.async {
                    self.addressCoordinate = location.coordinate
                    self.mapRegion = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Types

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

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.churchTalkRed)
                        .cornerRadius(ChurchTalkTheme.cornerRadius)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom, 40)
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
        .environmentObject(AuthViewModel())
}
