//
//  SoulJourneyProfileView.swift
//  ChurchTalk
//
//  Multi-step profile completion form for new members
//  Allows completion of basic info + spiritual journey while pending approval
//

import SwiftUI

struct SoulJourneyProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var showSuccessAlert = false

    // Basic Info fields
    @State private var bio = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var showDatePicker = false
    @State private var hasSetBirthday = false
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""

    // Spiritual Journey fields
    @State private var salvationDate: Date = Date()
    @State private var hasSalvationDate = false
    @State private var showSalvationDatePicker = false
    @State private var baptismDate: Date = Date()
    @State private var hasBaptismDate = false
    @State private var showBaptismDatePicker = false
    @State private var testimony = ""
    @State private var selectedGifts: Set<String> = []
    @State private var selectedMinistries: Set<String> = []

    let spiritualGifts = [
        "Teaching", "Serving", "Encouraging", "Giving",
        "Leadership", "Mercy", "Prophecy", "Administration"
    ]

    let ministryInterests = [
        "Worship Team", "Youth Ministry", "Children's Ministry", "Outreach",
        "Small Groups", "Prayer Team", "Media/Tech", "Hospitality"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: 2)
                    .tint(.churchTalkRed)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Step indicator
                HStack {
                    Text("Step \(currentStep + 1) of 2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(currentStep == 0 ? "Basic Info" : "Spiritual Journey")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.churchTalkRed)
                }
                .padding(.horizontal)
                .padding(.top, 4)

                // Content
                TabView(selection: $currentStep) {
                    basicInfoStep
                        .tag(0)

                    spiritualJourneyStep
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // Bottom buttons
                bottomButtons
            }
            .background(Color.background)
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        handleSkip()
                    }
                    .foregroundColor(.churchTalkRed)
                }
            }
            .alert("Profile Saved", isPresented: $showSuccessAlert) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your profile has been updated. The church administrator will review your request soon.")
            }
        }
    }

    // MARK: - Basic Info Step

    private var basicInfoStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .font(.title)
                            .foregroundColor(.churchTalkRed)
                        Text("Tell us about yourself")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text("Help your church get to know you better. All fields are optional.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // Bio
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio")
                        .font(.headline)

                    TextField("Share a little about yourself...", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                }

                // Date of Birth
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date of Birth")
                        .font(.headline)

                    Button(action: { showDatePicker.toggle() }) {
                        HStack {
                            Text(hasSetBirthday ? dateOfBirth.formatted(date: .long, time: .omitted) : "Select your birthday")
                                .foregroundColor(hasSetBirthday ? .primary : .secondary)
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(.churchTalkRed)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }

                    if showDatePicker {
                        DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .onChange(of: dateOfBirth) { _, _ in
                                hasSetBirthday = true
                            }
                    }
                }

                // Address
                VStack(alignment: .leading, spacing: 8) {
                    Text("Address")
                        .font(.headline)

                    TextField("Street", text: $street)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 12) {
                        TextField("City", text: $city)
                            .textFieldStyle(.roundedBorder)

                        TextField("State", text: $state)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)

                        TextField("ZIP", text: $zipCode)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .keyboardType(.numberPad)
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Spiritual Journey Step

    private var spiritualJourneyStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.title)
                            .foregroundColor(.churchTalkRed)
                        Text("Your Spiritual Journey")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text("Share your faith journey with your church family. All fields are optional.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // Salvation Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Salvation Date")
                        .font(.headline)

                    Button(action: { showSalvationDatePicker.toggle() }) {
                        HStack {
                            Text(hasSalvationDate ? salvationDate.formatted(date: .long, time: .omitted) : "When did you accept Christ?")
                                .foregroundColor(hasSalvationDate ? .primary : .secondary)
                            Spacer()
                            Image(systemName: "heart.circle")
                                .foregroundColor(.churchTalkRed)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }

                    if showSalvationDatePicker {
                        DatePicker("", selection: $salvationDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .onChange(of: salvationDate) { _, _ in
                                hasSalvationDate = true
                            }
                    }
                }

                // Baptism Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Baptism Date")
                        .font(.headline)

                    Button(action: { showBaptismDatePicker.toggle() }) {
                        HStack {
                            Text(hasBaptismDate ? baptismDate.formatted(date: .long, time: .omitted) : "When were you baptized?")
                                .foregroundColor(hasBaptismDate ? .primary : .secondary)
                            Spacer()
                            Image(systemName: "drop.fill")
                                .foregroundColor(.churchTalkRed)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }

                    if showBaptismDatePicker {
                        DatePicker("", selection: $baptismDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .onChange(of: baptismDate) { _, _ in
                                hasBaptismDate = true
                            }
                    }
                }

                // Testimony
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Testimony")
                        .font(.headline)

                    TextField("Share your story of faith...", text: $testimony, axis: .vertical)
                        .lineLimit(5...10)
                        .textFieldStyle(.roundedBorder)
                }

                // Spiritual Gifts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Spiritual Gifts")
                        .font(.headline)

                    Text("Select any gifts you believe God has given you")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(spiritualGifts, id: \.self) { gift in
                            ChipButton(
                                title: gift,
                                isSelected: selectedGifts.contains(gift)
                            ) {
                                toggleGift(gift)
                            }
                        }
                    }
                }

                // Ministry Interests
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ministry Interests")
                        .font(.headline)

                    Text("Select ministries you'd like to get involved in")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(ministryInterests, id: \.self) { ministry in
                            ChipButton(
                                title: ministry,
                                isSelected: selectedMinistries.contains(ministry)
                            ) {
                                toggleMinistry(ministry)
                            }
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button(action: { currentStep -= 1 }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundColor(.churchTalkRed)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.churchTalkRed.opacity(0.1))
                        .cornerRadius(12)
                    }
                }

                Button(action: handleNextOrSave) {
                    HStack {
                        Text(currentStep == 0 ? "Continue" : "Save Profile")
                        if currentStep == 0 {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.churchTalkRed)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(Color.background)
    }

    // MARK: - Actions

    private func handleSkip() {
        if currentStep == 0 {
            currentStep = 1
        } else {
            // Skip saving and dismiss
            dismiss()
        }
    }

    private func handleNextOrSave() {
        HapticManager.shared.medium()
        if currentStep == 0 {
            currentStep = 1
        } else {
            saveProfile()
        }
    }

    private func toggleGift(_ gift: String) {
        HapticManager.shared.light()
        if selectedGifts.contains(gift) {
            selectedGifts.remove(gift)
        } else {
            selectedGifts.insert(gift)
        }
    }

    private func toggleMinistry(_ ministry: String) {
        HapticManager.shared.light()
        if selectedMinistries.contains(ministry) {
            selectedMinistries.remove(ministry)
        } else {
            selectedMinistries.insert(ministry)
        }
    }

    private func saveProfile() {
        // Build address if any field is filled
        var address: Address? = nil
        if !street.isEmpty || !city.isEmpty || !state.isEmpty || !zipCode.isEmpty {
            address = Address(street: street, city: city, state: state, zipCode: zipCode)
        }

        // Build spiritual journey
        let spiritualJourney = SpiritualJourney(
            currentStage: hasSalvationDate ? .saved : .initialContact,
            salvationDate: hasSalvationDate ? salvationDate : nil,
            baptismDate: hasBaptismDate ? baptismDate : nil,
            membershipDate: nil,
            discipleshipCompletedDate: nil,
            ministryInterests: Array(selectedMinistries),
            currentMinistries: [],
            notes: testimony.isEmpty ? nil : testimony
        )

        // Update member profile through view model
        authViewModel.updateMemberProfile(
            bio: bio.isEmpty ? nil : bio,
            dateOfBirth: hasSetBirthday ? dateOfBirth : nil,
            address: address,
            spiritualJourney: spiritualJourney
        )

        showSuccessAlert = true
    }
}

// MARK: - Supporting Views

struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.churchTalkRed : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// FlowLayout is defined in SpiritualJourneyView.swift and reused here

#Preview {
    SoulJourneyProfileView()
        .environmentObject(AuthViewModel())
}
