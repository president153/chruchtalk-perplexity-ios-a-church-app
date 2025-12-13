import SwiftUI

struct FamilyManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var familyMembers: [FamilyMemberDisplay] = []
    @State private var showAddMember = false
    @State private var memberToDelete: FamilyMemberDisplay?
    @State private var showDeleteAlert = false

    // Demo family members
    let demoFamilyMembers: [FamilyMemberDisplay] = [
        FamilyMemberDisplay(
            id: "1",
            firstName: "Jane",
            lastName: "Doe",
            relationship: .spouse,
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date()),
            email: "jane.doe@email.com",
            phone: "(555) 123-4568"
        ),
        FamilyMemberDisplay(
            id: "2",
            firstName: "Emma",
            lastName: "Doe",
            relationship: .child,
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -12, to: Date())
        ),
        FamilyMemberDisplay(
            id: "3",
            firstName: "Michael",
            lastName: "Doe",
            relationship: .child,
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -8, to: Date())
        ),
        FamilyMemberDisplay(
            id: "4",
            firstName: "Robert",
            lastName: "Doe Sr.",
            relationship: .parent,
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -65, to: Date()),
            phone: "(555) 987-6543"
        ),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if familyMembers.isEmpty {
                    EmptyFamilyView()
                } else {
                    List {
                        // Group by relationship type
                        ForEach(RelationshipType.allCases, id: \.self) { relationshipType in
                            let membersOfType = familyMembers.filter { $0.relationship == relationshipType }
                            if !membersOfType.isEmpty {
                                Section(relationshipType.sectionTitle) {
                                    ForEach(membersOfType) { member in
                                        FamilyMemberCard(member: member)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    memberToDelete = member
                                                    showDeleteAlert = true
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Family Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddMember = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.churchTalkRed)
                    }
                }
            }
            .sheet(isPresented: $showAddMember) {
                AddFamilyMemberView { newMember in
                    withAnimation(ChurchTalkAnimations.smooth) {
                        familyMembers.append(newMember)
                    }
                }
            }
            .alert("Remove Family Member", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    if let member = memberToDelete {
                        withAnimation(ChurchTalkAnimations.smooth) {
                            familyMembers.removeAll { $0.id == member.id }
                        }
                    }
                }
            } message: {
                if let member = memberToDelete {
                    Text("Are you sure you want to remove \(member.fullName) from your family?")
                }
            }
            .onAppear {
                familyMembers = demoFamilyMembers
            }
        }
    }
}

// MARK: - Display Model

struct FamilyMemberDisplay: Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let relationship: RelationshipType
    var dateOfBirth: Date?
    var email: String?
    var phone: String?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let firstInitial = firstName.first.map { String($0) } ?? ""
        let lastInitial = lastName.first.map { String($0) } ?? ""
        return (firstInitial + lastInitial).uppercased()
    }

    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: dob, to: Date())
        return components.year
    }
}

// MARK: - Components

struct FamilyMemberCard: View {
    let member: FamilyMemberDisplay

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(member.relationship.color.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(member.initials)
                        .font(.headline)
                        .foregroundColor(member.relationship.color)
                )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(member.fullName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label(member.relationship.displayName, systemImage: member.relationship.iconName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let age = member.age {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(age) years old")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Contact indicators
            HStack(spacing: 8) {
                if member.email != nil {
                    Image(systemName: "envelope.fill")
                        .font(.caption)
                        .foregroundColor(.churchTalkRed.opacity(0.6))
                }
                if member.phone != nil {
                    Image(systemName: "phone.fill")
                        .font(.caption)
                        .foregroundColor(.churchTalkRed.opacity(0.6))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyFamilyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.churchTalkRed)

            Text("No Family Members")
                .font(.title2)
                .fontWeight(.bold)

            Text("Add your spouse, children, or parents to keep your family connected.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Add Family Member View

struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var relationship: RelationshipType = .spouse
    @State private var dateOfBirth = Date()
    @State private var showDatePicker = false
    @State private var hasDOB = false
    @State private var email = ""
    @State private var phone = ""

    let onSave: (FamilyMemberDisplay) -> Void

    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Relationship Type
                Section("Relationship") {
                    Picker("Relationship", selection: $relationship) {
                        ForEach(RelationshipType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Personal Information
                Section("Personal Information") {
                    HStack {
                        Text("First Name")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("Required", text: $firstName)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Last Name")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("Required", text: $lastName)
                            .multilineTextAlignment(.trailing)
                    }

                    Toggle("Date of Birth", isOn: $hasDOB)
                        .tint(.churchTalkRed)

                    if hasDOB {
                        Button(action: { showDatePicker = true }) {
                            HStack {
                                Text("Birthday")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundColor(.primary)
                                Image(systemName: "calendar")
                                    .foregroundColor(.churchTalkRed)
                            }
                        }
                    }
                }

                // Contact Information (Optional)
                Section("Contact Information (Optional)") {
                    HStack {
                        Text("Email")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("email@example.com", text: $email)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }

                    HStack {
                        Text("Phone")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("(555) 123-4567", text: $phone)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.phonePad)
                    }
                }

                // Link to existing member hint
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.churchTalkRed)
                        Text("If this person is already a church member, they will be linked automatically.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        saveMember()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.churchTalkRed)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DateOfBirthPicker(date: $dateOfBirth)
            }
        }
    }

    private func saveMember() {
        let newMember = FamilyMemberDisplay(
            id: UUID().uuidString,
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            relationship: relationship,
            dateOfBirth: hasDOB ? dateOfBirth : nil,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone
        )

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        onSave(newMember)
        dismiss()
    }
}

// MARK: - RelationshipType Extensions

extension RelationshipType {
    var sectionTitle: String {
        switch self {
        case .spouse: return "Spouse"
        case .child: return "Children"
        case .parent: return "Parents"
        }
    }

    var color: Color {
        switch self {
        case .spouse: return .churchTalkRed
        case .child: return .blue
        case .parent: return .purple
        }
    }
}

#Preview {
    FamilyManagementView()
}
