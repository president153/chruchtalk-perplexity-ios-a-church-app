//
//  SermonWeekView.swift
//  ChurchTalk
//
//  Sermon-powered weekly view - shows this week's sermon and daily actions.
//  The pastor's message sets the tone for the week.
//

import SwiftUI

struct SermonWeekView: View {
    @StateObject private var viewModel = SermonWeekViewModel()
    @State private var showSermonDetail = false
    @State private var showAssistant = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Week Header with Streak
                    weekHeaderSection

                    // This Week's Sermon
                    if let sermon = viewModel.currentSermon {
                        sermonCard(sermon)
                    } else if viewModel.isLoading {
                        sermonLoadingCard
                    }

                    // Today's Actions
                    if !viewModel.todaysActions.isEmpty {
                        todaysActionsSection
                    }

                    // Week Progress
                    if let progress = viewModel.weekProgress {
                        weekProgressSection(progress)
                    }

                    // Cumulative Journey (shows connection to previous weeks)
                    if viewModel.showCumulativeContext {
                        cumulativeContextSection
                    }

                    // AI Assistant Button
                    assistantButton

                    // Bottom padding for tab bar
                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .navigationTitle("This Week")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Streak indicator
                        if viewModel.streak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("\(viewModel.streak)")
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSermonDetail) {
                if let sermon = viewModel.currentSermon {
                    SermonDetailSheet(sermon: sermon)
                }
            }
            .sheet(isPresented: $showAssistant) {
                SermonAssistantSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Week Header

    private var weekHeaderSection: some View {
        VStack(spacing: 8) {
            // Week number badge
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                Text(viewModel.weekDisplay)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.churchTalkRed)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.churchTalkRed.opacity(0.1))
            )

            // Greeting
            Text(viewModel.greeting)
                .font(.title2)
                .fontWeight(.bold)

            // Week theme (from sermon)
            if let theme = viewModel.weeklyTheme {
                Text(theme)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Sermon Card

    private func sermonCard(_ sermon: Sermon) -> some View {
        Button {
            showSermonDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("THIS WEEK'S MESSAGE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.churchTalkRed)
                            .tracking(0.5)

                        Text(sermon.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Play button if video exists
                    if sermon.videoUrl != nil {
                        ZStack {
                            Circle()
                                .fill(Color.churchTalkRed)
                                .frame(width: 44, height: 44)

                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                }

                // Scripture reference
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.caption)
                    Text(sermon.mainScripture.reference)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)

                // Key points preview
                if let points = sermon.keyPoints, !points.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(points.prefix(3), id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.churchTalkRed)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)

                                Text(point)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                // Preacher
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                    Text(sermon.preacherName)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.top, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.churchTalkRed.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var sermonLoadingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 120, height: 12)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.tertiarySystemFill))
                .frame(height: 24)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 180, height: 16)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .shimmer()
    }

    // MARK: - Today's Actions

    private var todaysActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("TODAY'S FOCUS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                Spacer()

                let completed = viewModel.todaysActions.filter { $0.isCompleted }.count
                Text("\(completed)/\(viewModel.todaysActions.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.churchTalkRed)
            }

            // Action cards
            ForEach(viewModel.todaysActions) { action in
                DailyActionCard(
                    action: action,
                    onComplete: {
                        Task {
                            await viewModel.completeAction(action)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Week Progress

    private func weekProgressSection(_ progress: MemberWeeklyProgress) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WEEK PROGRESS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .tracking(0.5)

            HStack(spacing: 16) {
                // Actions completed
                progressStat(
                    value: "\(progress.actionsCompleted)",
                    label: "Actions",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                // Streak
                progressStat(
                    value: "\(progress.streakDays)",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: .orange
                )

                // Completion
                progressStat(
                    value: "\(Int(progress.completionPercent))%",
                    label: "Complete",
                    icon: "chart.pie.fill",
                    color: .blue
                )
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemFill))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.churchTalkRed, .churchTalkRed.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress.completionPercent / 100)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func progressStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cumulative Context

    private var cumulativeContextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("YOUR JOURNEY")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                Spacer()

                Text("\(viewModel.cumulativeContext?.totalWeeks ?? 0) weeks")
                    .font(.caption)
                    .foregroundColor(.churchTalkRed)
            }

            if let context = viewModel.cumulativeContext {
                // Themes covered
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(context.themes.prefix(6), id: \.self) { theme in
                            Text(theme)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.churchTalkRed)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.churchTalkRed.opacity(0.1))
                                )
                        }
                    }
                }

                // Key learning
                if let learning = context.keyLearnings.first {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)

                        Text(learning)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Assistant Button

    private var assistantButton: some View {
        Button {
            showAssistant = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Need help applying this week's message?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("Ask your AI assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Daily Action Card

struct DailyActionCard: View {
    let action: DailyAction
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Completion button
            Button(action: onComplete) {
                ZStack {
                    Circle()
                        .stroke(action.isCompleted ? Color.green : Color(.tertiarySystemFill), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if action.isCompleted {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }

            // Action info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: action.actionType.icon)
                        .font(.caption)
                        .foregroundColor(.churchTalkRed)

                    Text(action.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(action.isCompleted ? .secondary : .primary)
                        .strikethrough(action.isCompleted)
                }

                if let description = action.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Time estimate
            Text("\(action.estimatedMinutes) min")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Supporting Views

struct SermonDetailSheet: View {
    let sermon: Sermon
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title and scripture
                    VStack(alignment: .leading, spacing: 8) {
                        Text(sermon.title)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(sermon.mainScripture.reference)
                            .font(.headline)
                            .foregroundColor(.churchTalkRed)

                        Text(sermon.preacherName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Video player placeholder
                    if sermon.videoUrl != nil {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black)
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                            )
                    }

                    // Key points
                    if let points = sermon.keyPoints, !points.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Points")
                                .font(.headline)

                            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(Color.churchTalkRed))

                                    Text(point)
                                        .font(.body)
                                }
                            }
                        }
                    }

                    // Scripture text
                    if let text = sermon.mainScripture.text {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scripture")
                                .font(.headline)

                            Text(text)
                                .font(.body)
                                .italic()
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.tertiarySystemBackground))
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(sermon.weekDisplay)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SermonAssistantSheet: View {
    @ObservedObject var viewModel: SermonWeekViewModel
    @Environment(\.dismiss) var dismiss
    @State private var question = ""
    @State private var isAsking = false
    @State private var response: AssistantResponse?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Suggested questions
                if response == nil && !isAsking {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("How can I help you apply this week's message?")
                                .font(.headline)
                                .padding(.bottom, 8)

                            ForEach(viewModel.suggestedQuestions, id: \.self) { q in
                                Button {
                                    question = q
                                    askQuestion()
                                } label: {
                                    HStack {
                                        Text(q)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)

                                        Spacer()

                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundColor(.churchTalkRed)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }

                // Response
                if let response = response {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(response.answer)
                                .font(.body)

                            if let refs = response.sermonReferences, !refs.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Related Sermons")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    ForEach(refs, id: \.sermonId) { ref in
                                        Text("• \(ref.title) (Week \(ref.weekNumber))")
                                            .font(.caption)
                                            .foregroundColor(.churchTalkRed)
                                    }
                                }
                            }

                            if response.escalateToHuman {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.fill")
                                    Text("For this question, I recommend speaking with your pastor or leader.")
                                }
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.orange.opacity(0.1))
                                )
                            }
                        }
                        .padding()
                    }
                }

                // Loading
                if isAsking {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Thinking...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer()

                // Input field
                HStack(spacing: 12) {
                    TextField("Ask a question...", text: $question)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button {
                        askQuestion()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.churchTalkRed)
                    }
                    .disabled(question.isEmpty || isAsking)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
            }
            .navigationTitle("Ask About This Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func askQuestion() {
        guard !question.isEmpty else { return }
        isAsking = true

        Task {
            do {
                response = try await viewModel.askAssistant(question: question)
            } catch {
                print("Error asking assistant: \(error)")
            }
            isAsking = false
        }
    }
}

#Preview {
    SermonWeekView()
}
