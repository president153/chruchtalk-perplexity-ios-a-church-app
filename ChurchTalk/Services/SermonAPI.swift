//
//  SermonAPI.swift
//  ChurchTalk
//
//  API service for the 52-week sermon system.
//  Handles sermons, weekly phases, daily actions, and member progress.
//

import Foundation

class SermonAPI {
    static let shared = SermonAPI()
    private let client = APIClient.shared

    private init() {}

    // MARK: - Church Vision

    /// Get the church's current year vision
    func getCurrentVision() async throws -> ChurchVision {
        return try await client.get("/vision/current")
    }

    /// Get vision for a specific year
    func getVision(year: Int) async throws -> ChurchVision {
        return try await client.get("/vision/\(year)")
    }

    // MARK: - Sermons

    /// Get this week's sermon
    func getCurrentSermon() async throws -> Sermon {
        return try await client.get("/sermons/current")
    }

    /// Get sermon by week number
    func getSermon(week: Int, year: Int? = nil) async throws -> Sermon {
        let yearParam = year ?? Calendar.current.component(.year, from: Date())
        return try await client.get("/sermons/week/\(week)?year=\(yearParam)")
    }

    /// Get all sermons for a year
    func getSermons(year: Int? = nil) async throws -> [Sermon] {
        let yearParam = year ?? Calendar.current.component(.year, from: Date())
        return try await client.get("/sermons?year=\(yearParam)")
    }

    /// Get recent sermons (last N weeks)
    func getRecentSermons(limit: Int = 4) async throws -> [Sermon] {
        return try await client.get("/sermons/recent?limit=\(limit)")
    }

    // MARK: - Weekly Phases (52-week context)

    /// Get current week's phase with cumulative context
    func getCurrentWeeklyPhase() async throws -> WeeklyPhase {
        return try await client.get("/weekly-phases/current")
    }

    /// Get weekly phase by week number
    func getWeeklyPhase(week: Int, year: Int? = nil) async throws -> WeeklyPhase {
        let yearParam = year ?? Calendar.current.component(.year, from: Date())
        return try await client.get("/weekly-phases/\(week)?year=\(yearParam)")
    }

    /// Get cumulative context up to a specific week
    /// This includes all themes, scriptures, and learnings from week 1 to the specified week
    func getCumulativeContext(throughWeek: Int, year: Int? = nil) async throws -> CumulativeContext {
        let yearParam = year ?? Calendar.current.component(.year, from: Date())
        return try await client.get("/weekly-phases/cumulative?week=\(throughWeek)&year=\(yearParam)")
    }

    // MARK: - Daily Actions

    /// Get today's actions for the current member
    func getTodaysActions() async throws -> [DailyAction] {
        return try await client.get("/daily-actions/today")
    }

    /// Get this week's actions for the current member
    func getWeeklyActions() async throws -> [DailyAction] {
        return try await client.get("/daily-actions/week")
    }

    /// Get actions for a specific date
    func getActions(for date: Date) async throws -> [DailyAction] {
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: date)
        return try await client.get("/daily-actions?date=\(dateString)")
    }

    /// Mark an action as completed
    func completeAction(actionId: String, reflection: String? = nil) async throws -> DailyAction {
        struct CompleteRequest: Encodable {
            let reflection: String?
        }
        return try await client.post("/daily-actions/\(actionId)/complete", body: CompleteRequest(reflection: reflection))
    }

    /// Uncomplete an action (undo)
    func uncompleteAction(actionId: String) async throws -> DailyAction {
        return try await client.post("/daily-actions/\(actionId)/uncomplete")
    }

    // MARK: - Member Progress

    /// Get member's progress for current week
    func getCurrentWeekProgress() async throws -> MemberWeeklyProgress {
        return try await client.get("/progress/current-week")
    }

    /// Get member's progress for a specific week
    func getWeekProgress(week: Int, year: Int? = nil) async throws -> MemberWeeklyProgress {
        let yearParam = year ?? Calendar.current.component(.year, from: Date())
        return try await client.get("/progress/week/\(week)?year=\(yearParam)")
    }

    /// Get member's progress history (multiple weeks)
    func getProgressHistory(weeks: Int = 12) async throws -> [MemberWeeklyProgress] {
        return try await client.get("/progress/history?weeks=\(weeks)")
    }

    /// Get member's current streak
    func getCurrentStreak() async throws -> StreakInfo {
        return try await client.get("/progress/streak")
    }

    /// Mark sermon as watched
    func markSermonWatched(sermonId: String) async throws -> MemberWeeklyProgress {
        return try await client.post("/progress/sermon-watched/\(sermonId)")
    }

    /// Add weekly reflection
    func addWeeklyReflection(week: Int, reflection: String, keyTakeaway: String?) async throws -> MemberWeeklyProgress {
        struct ReflectionRequest: Encodable {
            let week: Int
            let reflection: String
            let keyTakeaway: String?
        }
        return try await client.post("/progress/reflection", body: ReflectionRequest(week: week, reflection: reflection, keyTakeaway: keyTakeaway))
    }

    // MARK: - AI Insights

    /// Get AI-generated insights for the member
    func getInsights() async throws -> [SermonInsight] {
        return try await client.get("/insights")
    }

    /// Get a specific type of insight
    func getInsight(type: InsightType) async throws -> SermonInsight? {
        return try await client.get("/insights/type/\(type.rawValue)")
    }

    /// Request a new AI insight based on current context
    func generateInsight() async throws -> SermonInsight {
        return try await client.post("/insights/generate")
    }

    // MARK: - Sermon AI Assistant

    /// Ask the AI assistant a question (grounded in sermon content)
    func askAssistant(question: String, context: AssistantContext? = nil) async throws -> AssistantResponse {
        struct AskRequest: Encodable {
            let question: String
            let context: AssistantContext?
        }
        return try await client.post("/assistant/ask", body: AskRequest(question: question, context: context))
    }

    /// Get suggested questions based on this week's sermon
    func getSuggestedQuestions() async throws -> [String] {
        return try await client.get("/assistant/suggested-questions")
    }
}

// MARK: - Supporting Types

struct CumulativeContext: Codable {
    let throughWeek: Int
    let year: Int
    let themes: [String]                  // All themes covered
    let scriptures: [Scripture]           // Key scriptures
    let keyLearnings: [String]            // AI-summarized learnings
    let sermonTitles: [String]            // All sermon titles
    let totalWeeks: Int                   // How many weeks of content
}

struct StreakInfo: Codable {
    let currentStreak: Int                // Days
    let longestStreak: Int
    let lastActivityDate: Date?
    let isActiveToday: Bool
}

struct AssistantContext: Codable {
    var currentWeek: Int?                 // Focus on specific week
    var memberStage: SpiritualStage?      // Member's journey stage
    var includeHistory: Bool = true       // Include cumulative context
    var relatedTopics: [String]?          // Specific topics to focus on
}

struct AssistantResponse: Codable {
    let answer: String
    var sermonReferences: [SermonReference]?   // Related sermons cited
    var scriptureReferences: [Scripture]?      // Scripture used
    var suggestedActions: [String]?            // Actions to take
    var escalateToHuman: Bool = false          // Should connect to pastor/leader?
    var escalationReason: String?              // Why escalation needed
}

struct SermonReference: Codable {
    let sermonId: String
    let title: String
    let weekNumber: Int
    let relevantQuote: String?            // Specific quote referenced
}
