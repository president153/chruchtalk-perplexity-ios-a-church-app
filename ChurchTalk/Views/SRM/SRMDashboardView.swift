import SwiftUI

struct SRMDashboardView: View {
    @State private var souls: [Soul] = []
    @State private var stats = SRMStats.empty
    @State private var searchText = ""
    @State private var selectedTypeFilter: SoulType?
    @State private var selectedStageFilter: SpiritualStage?
    @State private var showAddSoul = false
    @State private var selectedSoul: Soul?

    // Demo souls
    let demoSouls: [Soul] = [
        Soul(id: "1", firstName: "Maria", lastName: "Garcia", email: "maria@email.com", phone: "(555) 111-2222", soulType: .prospect, spiritualStage: .gospelPresentation, assignedTo: "Pastor John", notes: "Met during outreach. Very interested.", lastContactDate: Date().addingTimeInterval(-86400 * 3), nextFollowUpDate: Date().addingTimeInterval(86400 * 2), createdAt: Date().addingTimeInterval(-86400 * 7), updatedAt: Date()),
        Soul(id: "2", firstName: "James", lastName: "Wilson", email: "james@email.com", soulType: .visitor, spiritualStage: .saved, assignedTo: "Sarah M.", notes: "First time visitor. Salvation decision.", lastContactDate: Date().addingTimeInterval(-86400), createdAt: Date().addingTimeInterval(-86400 * 14), updatedAt: Date()),
        Soul(id: "3", firstName: "Emily", lastName: "Chen", email: nil, phone: nil, soulType: .member, spiritualStage: .serving, assignedTo: nil, notes: nil, lastContactDate: nil, nextFollowUpDate: nil, createdAt: Date().addingTimeInterval(-86400 * 365), updatedAt: Date(), memberId: "m1"),
        Soul(id: "4", firstName: "David", lastName: "Brown", phone: "(555) 333-4444", soulType: .prospect, spiritualStage: .initialContact, notes: "Knocked on door. Open to learning more.", lastContactDate: Date().addingTimeInterval(-86400 * 5), nextFollowUpDate: Date(), createdAt: Date().addingTimeInterval(-86400 * 5), updatedAt: Date()),
        Soul(id: "5", firstName: "Sarah", lastName: "Johnson", email: "sarah.j@email.com", soulType: .visitor, spiritualStage: .baptized, notes: "Baptized last Sunday!", lastContactDate: Date().addingTimeInterval(-86400 * 2), createdAt: Date().addingTimeInterval(-86400 * 30), updatedAt: Date()),
        Soul(id: "6", firstName: "Michael", lastName: "Lee", email: nil, phone: nil, soulType: .member, spiritualStage: .discipleship, assignedTo: nil, notes: nil, lastContactDate: nil, nextFollowUpDate: nil, createdAt: Date().addingTimeInterval(-86400 * 180), updatedAt: Date(), memberId: "m2"),
        Soul(id: "7", firstName: "Jessica", lastName: "Martinez", phone: "(555) 555-6666", soulType: .prospect, spiritualStage: .saved, assignedTo: "Pastor John", notes: "Ready for baptism class.", nextFollowUpDate: Date().addingTimeInterval(86400 * 7), createdAt: Date().addingTimeInterval(-86400 * 21), updatedAt: Date()),
    ]

    var filteredSouls: [Soul] {
        souls.filter { soul in
            let matchesSearch = searchText.isEmpty ||
                soul.fullName.localizedCaseInsensitiveContains(searchText) ||
                (soul.email?.localizedCaseInsensitiveContains(searchText) ?? false)

            let matchesType = selectedTypeFilter == nil || soul.soulType == selectedTypeFilter

            let matchesStage = selectedStageFilter == nil || soul.spiritualStage == selectedStageFilter

            return matchesSearch && matchesType && matchesStage
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats Header
                StatsHeaderView(stats: stats)
                    .padding()

                // Filter Chips
                FilterChipsView(
                    selectedType: $selectedTypeFilter,
                    selectedStage: $selectedStageFilter
                )
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search souls...", text: $searchText)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(ChurchTalkTheme.cornerRadius)
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Souls List
                if filteredSouls.isEmpty {
                    EmptySoulsView()
                } else {
                    List {
                        ForEach(filteredSouls) { soul in
                            Button(action: { selectedSoul = soul }) {
                                SoulListCard(soul: soul)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Soul Relationship Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSoul = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.churchTalkRed)
                    }
                }
            }
            .sheet(isPresented: $showAddSoul) {
                AddSoulView { newSoul in
                    withAnimation(ChurchTalkAnimations.smooth) {
                        souls.append(newSoul)
                        stats = SRMStats.calculate(from: souls)
                    }
                }
            }
            .sheet(item: $selectedSoul) { soul in
                SoulDetailView(soul: soul)
            }
            .onAppear {
                souls = demoSouls
                stats = SRMStats.calculate(from: souls)
            }
        }
    }
}

// MARK: - Stats Header

struct StatsHeaderView: View {
    let stats: SRMStats

    var body: some View {
        VStack(spacing: 12) {
            // Total Souls
            HStack {
                VStack(alignment: .leading) {
                    Text("\(stats.totalSouls)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.churchTalkRed)
                    Text("Total Souls")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()

                // Need Follow-up Badge
                if stats.needingFollowUp > 0 {
                    VStack(alignment: .trailing) {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                            Text("\(stats.needingFollowUp)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Text("Need Follow-up")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(ChurchTalkTheme.cornerRadius)
                }
            }

            // Type Breakdown
            HStack(spacing: 12) {
                StatBadge(
                    title: "Members",
                    count: stats.byType[.member] ?? 0,
                    icon: "person.fill",
                    color: .churchTalkRed
                )
                StatBadge(
                    title: "Visitors",
                    count: stats.byType[.visitor] ?? 0,
                    icon: "person.badge.clock",
                    color: .blue
                )
                StatBadge(
                    title: "Prospects",
                    count: stats.byType[.prospect] ?? 0,
                    icon: "person.crop.circle.badge.questionmark",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct StatBadge: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(ChurchTalkTheme.smallCornerRadius)
    }
}

// MARK: - Filter Chips

struct FilterChipsView: View {
    @Binding var selectedType: SoulType?
    @Binding var selectedStage: SpiritualStage?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Clear All
                if selectedType != nil || selectedStage != nil {
                    Button(action: {
                        withAnimation(ChurchTalkAnimations.bouncy) {
                            selectedType = nil
                            selectedStage = nil
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Clear")
                        }
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                    }
                }

                // Type Filters
                ForEach(SoulType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.displayName,
                        icon: type.iconName,
                        isSelected: selectedType == type,
                        onTap: {
                            withAnimation(ChurchTalkAnimations.bouncy) {
                                selectedType = selectedType == type ? nil : type
                            }
                        }
                    )
                }

                Divider()
                    .frame(height: 20)

                // Stage Filters
                ForEach(SpiritualStage.allCases.prefix(4), id: \.self) { stage in
                    FilterChip(
                        title: stage.displayName,
                        icon: stage.iconName,
                        isSelected: selectedStage == stage,
                        onTap: {
                            withAnimation(ChurchTalkAnimations.bouncy) {
                                selectedStage = selectedStage == stage ? nil : stage
                            }
                        }
                    )
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
            }
            .font(.subheadline)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.churchTalkRed : Color(.systemGray5))
            .cornerRadius(16)
        }
    }
}

// MARK: - Soul List Card

struct SoulListCard: View {
    let soul: Soul

    var body: some View {
        HStack(spacing: 12) {
            // Avatar with type indicator
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(stageColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(soul.initials)
                            .font(.headline)
                            .foregroundColor(stageColor)
                    )

                // Type badge
                Circle()
                    .fill(typeColor)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Image(systemName: soul.soulType.iconName)
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                    )
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(soul.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Label(soul.spiritualStage.displayName, systemImage: soul.spiritualStage.iconName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if soul.needsFollowUp {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("Needs follow-up")
                            .foregroundColor(.orange)
                    }
                    .font(.caption)
                }
            }

            Spacer()

            // Contact indicators
            VStack(alignment: .trailing, spacing: 4) {
                if let lastContact = soul.lastContactDate {
                    Text(lastContact.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    if soul.email != nil {
                        Image(systemName: "envelope.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if soul.phone != nil {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
        .shadow(color: ChurchTalkTheme.cardShadowColor, radius: 4, y: 2)
    }

    private var stageColor: Color {
        switch soul.spiritualStage {
        case .initialContact, .gospelPresentation: return .purple
        case .saved, .baptized: return .blue
        case .membership, .discipleship: return .green
        case .readyToServe, .serving: return .churchTalkRed
        }
    }

    private var typeColor: Color {
        switch soul.soulType {
        case .member: return .churchTalkRed
        case .visitor: return .blue
        case .prospect: return .purple
        }
    }
}

// MARK: - Empty State

struct EmptySoulsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.churchTalkRed)

            Text("No Souls Found")
                .font(.title2)
                .fontWeight(.bold)

            Text("Start tracking souls by adding new prospects, visitors, or members.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Soul Detail View

struct SoulDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let soul: Soul
    @State private var followUpHistory: [FollowUpRecord] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    SoulDetailHeader(soul: soul)

                    // Spiritual Journey Progress
                    SpiritualJourneyProgress(currentStage: soul.spiritualStage)

                    // Contact Info
                    if soul.email != nil || soul.phone != nil {
                        ContactInfoSection(soul: soul)
                    }

                    // Notes
                    if let notes = soul.notes, !notes.isEmpty {
                        NotesSection(notes: notes)
                    }

                    // Follow-up History
                    FollowUpHistorySection(history: followUpHistory)
                }
                .padding()
            }
            .navigationTitle("Soul Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadFollowUpHistory()
            }
        }
    }

    private func loadFollowUpHistory() {
        // Demo follow-up records
        followUpHistory = [
            FollowUpRecord(id: "f1", soulId: soul.id, contactedBy: "Pastor John", contactDate: Date().addingTimeInterval(-86400 * 3), contactMethod: .phone, notes: "Called to check in. Very receptive.", outcome: .positive, nextSteps: "Schedule coffee meeting"),
            FollowUpRecord(id: "f2", soulId: soul.id, contactedBy: "Sarah M.", contactDate: Date().addingTimeInterval(-86400 * 10), contactMethod: .inPerson, notes: "Met at church event. Showed interest.", outcome: .positive),
        ]
    }
}

struct SoulDetailHeader: View {
    let soul: Soul

    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.churchTalkRed.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(soul.initials)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.churchTalkRed)
                )

            Text(soul.fullName)
                .font(.title)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                Label(soul.soulType.displayName, systemImage: soul.soulType.iconName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let assignedTo = soul.assignedTo {
                    Label(assignedTo, systemImage: "person.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct SpiritualJourneyProgress: View {
    let currentStage: SpiritualStage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spiritual Journey")
                .font(.headline)

            HStack(spacing: 4) {
                ForEach(SpiritualStage.allCases, id: \.self) { stage in
                    let isCompleted = stage.rawValue <= currentStage.rawValue
                    let isCurrent = stage == currentStage

                    VStack(spacing: 4) {
                        Circle()
                            .fill(isCompleted ? Color.churchTalkRed : Color.gray.opacity(0.3))
                            .frame(width: isCurrent ? 16 : 10, height: isCurrent ? 16 : 10)

                        if isCurrent {
                            Text(stage.displayName)
                                .font(.caption2)
                                .foregroundColor(.churchTalkRed)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    if stage != SpiritualStage.allCases.last {
                        Rectangle()
                            .fill(isCompleted && stage.rawValue < currentStage.rawValue ? Color.churchTalkRed : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct ContactInfoSection: View {
    let soul: Soul

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.headline)

            if let email = soul.email {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.churchTalkRed)
                        Text(email)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let phone = soul.phone {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.churchTalkRed)
                        Text(phone)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct NotesSection: View {
    let notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)

            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct FollowUpHistorySection: View {
    let history: [FollowUpRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Follow-up History")
                    .font(.headline)
                Spacer()
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .foregroundColor(.churchTalkRed)
                }
            }

            if history.isEmpty {
                Text("No follow-up records yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(history) { record in
                    FollowUpRecordCard(record: record)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct FollowUpRecordCard: View {
    let record: FollowUpRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: record.contactMethod.iconName)
                    .foregroundColor(.churchTalkRed)
                Text(record.contactMethod.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(record.contactDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(record.notes)
                .font(.body)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: record.outcome.iconName)
                    .foregroundColor(outcomeColor)
                Text(record.outcome.displayName)
                    .font(.caption)
                    .foregroundColor(outcomeColor)

                Spacer()

                Text("by \(record.contactedBy)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(ChurchTalkTheme.smallCornerRadius)
    }

    private var outcomeColor: Color {
        switch record.outcome {
        case .positive: return .green
        case .neutral: return .orange
        case .negative: return .red
        case .noContact: return .gray
        }
    }
}

// MARK: - Add Soul View

struct AddSoulView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var soulType: SoulType = .prospect
    @State private var spiritualStage: SpiritualStage = .initialContact
    @State private var notes = ""

    let onSave: (Soul) -> Void

    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("First Name *", text: $firstName)
                    TextField("Last Name *", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("Classification") {
                    Picker("Soul Type", selection: $soulType) {
                        ForEach(SoulType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }

                    Picker("Spiritual Stage", selection: $spiritualStage) {
                        ForEach(SpiritualStage.allCases, id: \.self) { stage in
                            Text(stage.displayName)
                                .tag(stage)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Soul")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSoul()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.churchTalkRed)
                    .disabled(!isValid)
                }
            }
        }
    }

    private func saveSoul() {
        let newSoul = Soul(
            id: UUID().uuidString,
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            soulType: soulType,
            spiritualStage: spiritualStage,
            notes: notes.isEmpty ? nil : notes,
            createdAt: Date(),
            updatedAt: Date()
        )

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        onSave(newSoul)
        dismiss()
    }
}

#Preview {
    SRMDashboardView()
}
