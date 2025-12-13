import SwiftUI

struct SpiritualJourneyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var journey = SpiritualJourney(currentStage: .initialContact)
    @State private var showDatePicker = false
    @State private var selectedDateField: DateField?
    @State private var tempDate = Date()

    enum DateField {
        case salvation, baptism, membership
    }

    let stages: [SpiritualStage] = [
        .initialContact,
        .gospelPresentation,
        .saved,
        .baptized,
        .membership,
        .discipleship,
        .readyToServe,
        .serving
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Bar
                JourneyProgressBar(currentStep: currentStep, totalSteps: stages.count)
                    .padding()

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Stage Icon and Title
                        VStack(spacing: 12) {
                            Image(systemName: stages[currentStep].iconName)
                                .font(.system(size: 60))
                                .foregroundColor(.churchTalkRed)

                            Text(stages[currentStep].displayName)
                                .font(.title)
                                .fontWeight(.bold)

                            Text(stages[currentStep].description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)

                        Divider()
                            .padding(.horizontal, 32)

                        // Stage-specific questions
                        stageQuestionView
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 100)
                }

                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: previousStep) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.headline)
                            .foregroundColor(.churchTalkRed)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.churchTalkRed.opacity(0.1))
                            .cornerRadius(ChurchTalkTheme.cornerRadius)
                        }
                    }

                    Spacer()

                    Button(action: nextStep) {
                        HStack {
                            Text(currentStep == stages.count - 1 ? "Complete" : "Next")
                            Image(systemName: currentStep == stages.count - 1 ? "checkmark" : "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.churchTalkRed)
                        .cornerRadius(ChurchTalkTheme.cornerRadius)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Spiritual Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(
                    date: $tempDate,
                    title: datePickerTitle,
                    onSave: saveDateSelection
                )
            }
        }
    }

    @ViewBuilder
    private var stageQuestionView: some View {
        switch stages[currentStep] {
        case .initialContact:
            InitialContactView()

        case .gospelPresentation:
            GospelPresentationView(hasHeard: Binding(
                get: { journey.currentStage.rawValue >= SpiritualStage.gospelPresentation.rawValue },
                set: { if $0 { journey.currentStage = .gospelPresentation } }
            ))

        case .saved:
            SavedView(
                isSaved: Binding(
                    get: { journey.salvationDate != nil },
                    set: { _ in }
                ),
                salvationDate: journey.salvationDate,
                onSelectDate: {
                    selectedDateField = .salvation
                    tempDate = journey.salvationDate ?? Date()
                    showDatePicker = true
                }
            )

        case .baptized:
            BaptizedView(
                isBaptized: Binding(
                    get: { journey.baptismDate != nil },
                    set: { _ in }
                ),
                baptismDate: journey.baptismDate,
                onSelectDate: {
                    selectedDateField = .baptism
                    tempDate = journey.baptismDate ?? Date()
                    showDatePicker = true
                }
            )

        case .membership:
            MembershipView(
                isMember: Binding(
                    get: { journey.membershipDate != nil },
                    set: { _ in }
                ),
                membershipDate: journey.membershipDate,
                onSelectDate: {
                    selectedDateField = .membership
                    tempDate = journey.membershipDate ?? Date()
                    showDatePicker = true
                }
            )

        case .discipleship:
            DiscipleshipView(inDiscipleship: Binding(
                get: { journey.currentStage.rawValue >= SpiritualStage.discipleship.rawValue },
                set: { if $0 { journey.currentStage = .discipleship } }
            ))

        case .readyToServe:
            ReadyToServeView(isReady: Binding(
                get: { journey.currentStage.rawValue >= SpiritualStage.readyToServe.rawValue },
                set: { if $0 { journey.currentStage = .readyToServe } }
            ))

        case .serving:
            MinistrySelectionView(
                selectedMinistries: $journey.currentMinistries,
                ministryInterests: $journey.ministryInterests
            )
        }
    }

    private var datePickerTitle: String {
        switch selectedDateField {
        case .salvation: return "When were you saved?"
        case .baptism: return "When were you baptized?"
        case .membership: return "When did you become a member?"
        case .none: return "Select Date"
        }
    }

    private func saveDateSelection() {
        switch selectedDateField {
        case .salvation:
            journey.salvationDate = tempDate
            journey.currentStage = .saved
        case .baptism:
            journey.baptismDate = tempDate
            journey.currentStage = .baptized
        case .membership:
            journey.membershipDate = tempDate
            journey.currentStage = .membership
        case .none:
            break
        }
        showDatePicker = false
    }

    private func previousStep() {
        withAnimation(ChurchTalkAnimations.smooth) {
            currentStep = max(0, currentStep - 1)
        }
    }

    private func nextStep() {
        if currentStep == stages.count - 1 {
            // Complete journey
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            dismiss()
        } else {
            withAnimation(ChurchTalkAnimations.smooth) {
                currentStep = min(stages.count - 1, currentStep + 1)
            }
        }
    }
}

// MARK: - Progress Bar

struct JourneyProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.churchTalkRed : Color.gray.opacity(0.3))
                        .frame(width: index == currentStep ? 12 : 8, height: index == currentStep ? 12 : 8)
                        .animation(ChurchTalkAnimations.bouncy, value: currentStep)
                }
            }

            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Stage Views

struct InitialContactView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to your spiritual journey!")
                .font(.headline)

            Text("We're excited to walk alongside you as you grow in your faith. This questionnaire helps us understand where you are in your journey so we can better support you.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundColor(.churchTalkRed)
                .padding(.top, 20)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct GospelPresentationView: View {
    @Binding var hasHeard: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Have you heard the Gospel message?")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("The Good News of Jesus Christ - that God loves you and sent His Son to save you.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            YesNoButtons(isYes: $hasHeard)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct SavedView: View {
    @Binding var isSaved: Bool
    let salvationDate: Date?
    let onSelectDate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Have you accepted Jesus Christ as your Lord and Savior?")
                .font(.headline)
                .multilineTextAlignment(.center)

            if let date = salvationDate {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.amenGreen)
                    Text("Saved on \(date.formatted(date: .long, time: .omitted))")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.amenGreen.opacity(0.1))
                .cornerRadius(ChurchTalkTheme.smallCornerRadius)
            }

            Button(action: onSelectDate) {
                HStack {
                    Image(systemName: salvationDate == nil ? "calendar.badge.plus" : "calendar")
                    Text(salvationDate == nil ? "Yes, I'm Saved!" : "Update Date")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.churchTalkRed)
                .cornerRadius(ChurchTalkTheme.cornerRadius)
            }

            if salvationDate == nil {
                Button("Not Yet") {
                    // Keep as not saved
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct BaptizedView: View {
    @Binding var isBaptized: Bool
    let baptismDate: Date?
    let onSelectDate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Have you been baptized?")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Baptism is an outward expression of your inward faith, symbolizing your new life in Christ.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let date = baptismDate {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.amenGreen)
                    Text("Baptized on \(date.formatted(date: .long, time: .omitted))")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.amenGreen.opacity(0.1))
                .cornerRadius(ChurchTalkTheme.smallCornerRadius)
            }

            Button(action: onSelectDate) {
                HStack {
                    Image(systemName: baptismDate == nil ? "drop.fill" : "calendar")
                    Text(baptismDate == nil ? "Yes, I'm Baptized!" : "Update Date")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.churchTalkRed)
                .cornerRadius(ChurchTalkTheme.cornerRadius)
            }

            if baptismDate == nil {
                Button("Not Yet") {
                    // Keep as not baptized
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct MembershipView: View {
    @Binding var isMember: Bool
    let membershipDate: Date?
    let onSelectDate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Are you a member of our church?")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Church membership is about committing to a local body of believers and growing together in community.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let date = membershipDate {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.amenGreen)
                    Text("Member since \(date.formatted(date: .long, time: .omitted))")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.amenGreen.opacity(0.1))
                .cornerRadius(ChurchTalkTheme.smallCornerRadius)
            }

            Button(action: onSelectDate) {
                HStack {
                    Image(systemName: membershipDate == nil ? "person.badge.plus" : "calendar")
                    Text(membershipDate == nil ? "Yes, I'm a Member!" : "Update Date")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.churchTalkRed)
                .cornerRadius(ChurchTalkTheme.cornerRadius)
            }

            if membershipDate == nil {
                Button("Not Yet") {
                    // Keep as not a member
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct DiscipleshipView: View {
    @Binding var inDiscipleship: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Are you currently in a discipleship program or small group?")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Discipleship is about growing deeper in your faith through study, mentorship, and community.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            YesNoButtons(isYes: $inDiscipleship)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct ReadyToServeView: View {
    @Binding var isReady: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Do you feel ready to serve in ministry?")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("God has given each of us unique gifts to serve His church and build up the body of believers.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            YesNoButtons(isYes: $isReady)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct MinistrySelectionView: View {
    @Binding var selectedMinistries: [String]
    @Binding var ministryInterests: [String]

    let ministries = MinistryCategory.all

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Which ministries are you currently serving in?")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(ministries, id: \.self) { ministry in
                    MinistryChip(
                        title: ministry,
                        isSelected: selectedMinistries.contains(ministry),
                        onTap: {
                            if selectedMinistries.contains(ministry) {
                                selectedMinistries.removeAll { $0 == ministry }
                            } else {
                                selectedMinistries.append(ministry)
                            }
                        }
                    )
                }
            }

            Divider()
                .padding(.vertical, 8)

            Text("Which ministries are you interested in?")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(ministries.filter { !selectedMinistries.contains($0) }, id: \.self) { ministry in
                    MinistryChip(
                        title: ministry,
                        isSelected: ministryInterests.contains(ministry),
                        isInterest: true,
                        onTap: {
                            if ministryInterests.contains(ministry) {
                                ministryInterests.removeAll { $0 == ministry }
                            } else {
                                ministryInterests.append(ministry)
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

struct MinistryChip: View {
    let title: String
    let isSelected: Bool
    var isInterest: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : (isInterest ? .churchTalkRed : .primary))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.churchTalkRed : (isInterest ? Color.churchTalkRed.opacity(0.1) : Color(.systemGray5)))
                .cornerRadius(20)
        }
        .animation(ChurchTalkAnimations.bouncy, value: isSelected)
    }
}

// MARK: - Shared Components

struct YesNoButtons: View {
    @Binding var isYes: Bool

    var body: some View {
        HStack(spacing: 16) {
            Button(action: { isYes = true }) {
                HStack {
                    Image(systemName: isYes ? "checkmark.circle.fill" : "circle")
                    Text("Yes")
                }
                .font(.headline)
                .foregroundColor(isYes ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isYes ? Color.churchTalkRed : Color(.systemGray5))
                .cornerRadius(ChurchTalkTheme.cornerRadius)
            }

            Button(action: { isYes = false }) {
                HStack {
                    Image(systemName: !isYes ? "xmark.circle.fill" : "circle")
                    Text("No")
                }
                .font(.headline)
                .foregroundColor(!isYes ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(!isYes ? Color.gray : Color(.systemGray5))
                .cornerRadius(ChurchTalkTheme.cornerRadius)
            }
        }
    }
}

struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    let title: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(title)
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

                Button(action: {
                    onSave()
                    dismiss()
                }) {
                    Text("Save Date")
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

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    SpiritualJourneyView()
}
