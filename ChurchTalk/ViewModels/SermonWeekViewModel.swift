//
//  SermonWeekViewModel.swift
//  ChurchTalk
//
//  ViewModel for the sermon-powered weekly view.
//  Manages sermon data, daily actions, and member progress.
//

import Foundation
import SwiftUI

@MainActor
class SermonWeekViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentSermon: Sermon?
    @Published var todaysActions: [DailyAction] = []
    @Published var weekProgress: MemberWeeklyProgress?
    @Published var cumulativeContext: CumulativeContext?
    @Published var suggestedQuestions: [String] = []

    @Published var isLoading = false
    @Published var error: String?

    @Published var showCumulativeContext = false

    // MARK: - Computed Properties

    var streak: Int {
        weekProgress?.streakDays ?? 0
    }

    var weekDisplay: String {
        let week = Calendar.current.component(.weekOfYear, from: Date())
        let year = Calendar.current.component(.year, from: Date())
        return "Week \(week) of 52 • \(year)"
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = AuthViewModel.shared.currentMember?.firstName ?? "there"

        switch hour {
        case 0..<12:
            return "Good morning, \(name)!"
        case 12..<17:
            return "Good afternoon, \(name)!"
        default:
            return "Good evening, \(name)!"
        }
    }

    var weeklyTheme: String? {
        if let sermon = currentSermon {
            return "This week: \(sermon.title)"
        }
        return nil
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        do {
            // Load all data in parallel
            async let sermonTask = loadSermon()
            async let actionsTask = loadTodaysActions()
            async let progressTask = loadProgress()
            async let contextTask = loadCumulativeContext()
            async let questionsTask = loadSuggestedQuestions()

            _ = try await (sermonTask, actionsTask, progressTask, contextTask, questionsTask)

            // Show cumulative context if we have more than 2 weeks
            showCumulativeContext = (cumulativeContext?.totalWeeks ?? 0) > 2

        } catch {
            self.error = "Unable to load data"
            print("SermonWeekViewModel error: \(error)")
        }

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    private func loadSermon() async throws {
        do {
            currentSermon = try await SermonAPI.shared.getCurrentSermon()
        } catch {
            // If no sermon for this week, that's okay
            print("No current sermon: \(error)")
        }
    }

    private func loadTodaysActions() async throws {
        do {
            todaysActions = try await SermonAPI.shared.getTodaysActions()
        } catch {
            // No actions is okay
            print("No actions: \(error)")
        }
    }

    private func loadProgress() async throws {
        do {
            weekProgress = try await SermonAPI.shared.getCurrentWeekProgress()
        } catch {
            print("No progress: \(error)")
        }
    }

    private func loadCumulativeContext() async throws {
        let week = Calendar.current.component(.weekOfYear, from: Date())
        do {
            cumulativeContext = try await SermonAPI.shared.getCumulativeContext(throughWeek: week)
        } catch {
            print("No cumulative context: \(error)")
        }
    }

    private func loadSuggestedQuestions() async throws {
        do {
            suggestedQuestions = try await SermonAPI.shared.getSuggestedQuestions()
        } catch {
            // Default questions
            suggestedQuestions = [
                "How can I apply this week's message to my life?",
                "What scripture should I focus on this week?",
                "How does this connect to what we learned before?"
            ]
        }
    }

    // MARK: - Actions

    func completeAction(_ action: DailyAction) async {
        do {
            let updatedAction = try await SermonAPI.shared.completeAction(actionId: action.id)

            // Update local state
            if let index = todaysActions.firstIndex(where: { $0.id == action.id }) {
                todaysActions[index] = updatedAction
            }

            // Refresh progress
            weekProgress = try await SermonAPI.shared.getCurrentWeekProgress()

        } catch {
            print("Error completing action: \(error)")
        }
    }

    func askAssistant(question: String) async throws -> AssistantResponse {
        let context = AssistantContext(
            currentWeek: Calendar.current.component(.weekOfYear, from: Date()),
            memberStage: AuthViewModel.shared.currentMember?.spiritualJourney?.currentStage,
            includeHistory: true
        )

        return try await SermonAPI.shared.askAssistant(question: question, context: context)
    }
}

// MARK: - Preview Helper

extension SermonWeekViewModel {
    static var preview: SermonWeekViewModel {
        let vm = SermonWeekViewModel()

        // Mock data for previews
        vm.currentSermon = Sermon(
            id: "1",
            churchId: "church1",
            weekNumber: 5,
            year: 2025,
            title: "Walking by Faith",
            date: Date(),
            mainScripture: Scripture(book: "Hebrews", chapter: 11, verseStart: 1, verseEnd: 6),
            keyPoints: [
                "Faith is the substance of things hoped for",
                "Without faith it is impossible to please God",
                "Faith requires action"
            ],
            preacherName: "Pastor John",
            createdAt: Date()
        )

        vm.todaysActions = [
            DailyAction(
                id: "1",
                memberId: "m1",
                churchId: "c1",
                weekNumber: 5,
                year: 2025,
                dayOfWeek: 1,
                date: Date(),
                actionType: .scripture,
                title: "Read Hebrews 11:1-6",
                description: "Focus on the definition of faith",
                estimatedMinutes: 5,
                generatedAt: Date()
            ),
            DailyAction(
                id: "2",
                memberId: "m1",
                churchId: "c1",
                weekNumber: 5,
                year: 2025,
                dayOfWeek: 1,
                date: Date(),
                actionType: .prayer,
                title: "Pray for increased faith",
                description: "Ask God to strengthen your faith",
                estimatedMinutes: 5,
                generatedAt: Date()
            )
        ]

        vm.weekProgress = MemberWeeklyProgress(
            id: "1",
            memberId: "m1",
            churchId: "c1",
            weekNumber: 5,
            year: 2025,
            actionsCompleted: 8,
            totalActions: 14,
            streakDays: 7,
            sermonWatched: true,
            attendedService: true,
            createdAt: Date()
        )

        vm.cumulativeContext = CumulativeContext(
            throughWeek: 5,
            year: 2025,
            themes: ["Faith", "Prayer", "Love", "Obedience", "Trust"],
            scriptures: [],
            keyLearnings: ["Faith requires action, not just belief"],
            sermonTitles: ["New Beginnings", "Power of Prayer", "Love in Action", "Obedience First", "Walking by Faith"],
            totalWeeks: 5
        )

        return vm
    }
}
