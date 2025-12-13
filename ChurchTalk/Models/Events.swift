import Foundation
import SwiftUI

// MARK: - Church Event

struct ChurchEvent: Identifiable, Codable {
    let id: String
    let churchId: String
    let title: String
    let description: String?
    var imageUrl: String?

    // Timing
    let startDate: Date
    var endDate: Date?
    var isAllDay: Bool = false
    var recurrenceRule: EventRecurrence?

    // Location
    var location: EventLocation?
    var isVirtual: Bool = false
    var virtualMeetingUrl: String?

    // Registration
    var requiresRegistration: Bool = false
    var maxCapacity: Int?
    var currentRegistrations: Int = 0
    var registrationDeadline: Date?

    // Categorization
    var category: EventCategory
    var tags: [String] = []

    // Volunteer needs
    var volunteerRoles: [VolunteerRole]?

    // Metadata
    var createdBy: String?
    let createdAt: Date
    var updatedAt: Date?
    var isPublished: Bool = true
    var isFeatured: Bool = false

    // Computed properties
    var isFull: Bool {
        guard let max = maxCapacity else { return false }
        return currentRegistrations >= max
    }

    var spotsRemaining: Int? {
        guard let max = maxCapacity else { return nil }
        return Swift.max(0, max - currentRegistrations)
    }

    var isUpcoming: Bool {
        startDate > Date()
    }

    var isPast: Bool {
        let endOrStart = endDate ?? startDate
        return endOrStart < Date()
    }

    var isOngoing: Bool {
        let now = Date()
        let end = endDate ?? startDate.addingTimeInterval(3600) // Default 1 hour
        return startDate <= now && end >= now
    }

    var needsVolunteers: Bool {
        guard let roles = volunteerRoles else { return false }
        return roles.contains { $0.filledCount < $0.requiredCount }
    }

    var dateDisplayString: String {
        let formatter = DateFormatter()
        if isAllDay {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
        }
        return formatter.string(from: startDate)
    }

    var timeDisplayString: String {
        if isAllDay {
            return "All Day"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        var result = formatter.string(from: startDate)
        if let end = endDate {
            result += " - \(formatter.string(from: end))"
        }
        return result
    }
}

// MARK: - Event Category

enum EventCategory: String, Codable, CaseIterable {
    case worship
    case outreach
    case youth
    case children
    case smallGroup
    case missions
    case fellowship
    case training
    case special
    case other

    var displayName: String {
        switch self {
        case .worship: return "Worship"
        case .outreach: return "Outreach"
        case .youth: return "Youth"
        case .children: return "Children"
        case .smallGroup: return "Small Group"
        case .missions: return "Missions"
        case .fellowship: return "Fellowship"
        case .training: return "Training"
        case .special: return "Special Event"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .worship: return "music.note.house.fill"
        case .outreach: return "hand.raised.fill"
        case .youth: return "person.3.fill"
        case .children: return "figure.and.child.holdinghands"
        case .smallGroup: return "person.2.circle.fill"
        case .missions: return "globe.americas.fill"
        case .fellowship: return "heart.circle.fill"
        case .training: return "book.fill"
        case .special: return "star.fill"
        case .other: return "calendar"
        }
    }

    var color: Color {
        switch self {
        case .worship: return .purple
        case .outreach: return .amenGreen
        case .youth: return .orange
        case .children: return .pink
        case .smallGroup: return .blue
        case .missions: return .teal
        case .fellowship: return .churchTalkRed
        case .training: return .indigo
        case .special: return .yellow
        case .other: return .gray
        }
    }
}

// MARK: - Event Location

struct EventLocation: Codable {
    var name: String?
    var address: String?
    var room: String?
    var latitude: Double?
    var longitude: Double?

    var displayString: String {
        var parts: [String] = []
        if let name = name { parts.append(name) }
        if let room = room { parts.append("Room: \(room)") }
        if let address = address { parts.append(address) }
        return parts.joined(separator: " - ")
    }

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }
}

// MARK: - Event Recurrence

struct EventRecurrence: Codable {
    var frequency: RecurrenceFrequency
    var interval: Int = 1
    var endDate: Date?
    var count: Int?
    var daysOfWeek: [Int]?

    var displayString: String {
        var result = ""
        if interval == 1 {
            result = frequency.displayName
        } else {
            result = "Every \(interval) \(frequency.pluralName)"
        }
        if let end = endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            result += " until \(formatter.string(from: end))"
        } else if let c = count {
            result += " (\(c) times)"
        }
        return result
    }
}

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case biweekly
    case monthly
    case yearly

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var pluralName: String {
        switch self {
        case .daily: return "days"
        case .weekly: return "weeks"
        case .biweekly: return "weeks"
        case .monthly: return "months"
        case .yearly: return "years"
        }
    }
}

// MARK: - Event Registration

struct EventRegistration: Identifiable, Codable {
    let id: String
    let eventId: String
    let memberId: String
    var memberName: String?
    var status: RegistrationStatus
    let registeredAt: Date
    var guestCount: Int = 0
    var notes: String?
    var checkedInAt: Date?

    var isCheckedIn: Bool {
        checkedInAt != nil
    }

    var totalAttendees: Int {
        1 + guestCount
    }
}

enum RegistrationStatus: String, Codable, CaseIterable {
    case registered
    case waitlisted
    case cancelled
    case attended
    case noShow

    var displayName: String {
        switch self {
        case .registered: return "Registered"
        case .waitlisted: return "Waitlisted"
        case .cancelled: return "Cancelled"
        case .attended: return "Attended"
        case .noShow: return "No Show"
        }
    }

    var color: Color {
        switch self {
        case .registered: return .blue
        case .waitlisted: return .orange
        case .cancelled: return .gray
        case .attended: return .amenGreen
        case .noShow: return .red
        }
    }
}

// MARK: - Volunteer Role

struct VolunteerRole: Identifiable, Codable {
    let id: String
    var name: String
    var description: String?
    var requiredCount: Int
    var filledCount: Int = 0
    var skillsRequired: [String]?
    var ministryArea: String?

    var isFilled: Bool {
        filledCount >= requiredCount
    }

    var spotsRemaining: Int {
        max(0, requiredCount - filledCount)
    }

    var progressPercent: Double {
        guard requiredCount > 0 else { return 0 }
        return Double(filledCount) / Double(requiredCount)
    }
}

// MARK: - Volunteer Request

struct VolunteerRequest: Identifiable, Codable {
    let id: String
    let eventId: String
    let memberId: String
    let roleId: String
    var roleName: String?
    var eventTitle: String?
    var status: VolunteerRequestStatus
    var message: String?
    let requestedAt: Date
    var respondedAt: Date?

    // AI Generation metadata
    var aiGenerated: Bool = false
    var aiReasoning: String?
    var aiConfidenceScore: Double?

    var isPending: Bool {
        status == .pending
    }
}

enum VolunteerRequestStatus: String, Codable, CaseIterable {
    case pending
    case accepted
    case declined
    case expired

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .expired: return "Expired"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .accepted: return .amenGreen
        case .declined: return .red
        case .expired: return .gray
        }
    }
}

// MARK: - Sample Data

extension ChurchEvent {
    static var sampleEvents: [ChurchEvent] {
        [
            ChurchEvent(
                id: "1",
                churchId: "church1",
                title: "Sunday Worship Service",
                description: "Join us for our weekly worship service with praise, prayer, and the Word.",
                imageUrl: nil,
                startDate: Date().addingTimeInterval(86400 * 2),
                endDate: Date().addingTimeInterval(86400 * 2 + 5400),
                isAllDay: false,
                location: EventLocation(name: "Main Sanctuary", room: nil),
                category: .worship,
                createdAt: Date()
            ),
            ChurchEvent(
                id: "2",
                churchId: "church1",
                title: "Youth Night",
                description: "Fun and fellowship for teens ages 13-18.",
                imageUrl: nil,
                startDate: Date().addingTimeInterval(86400 * 5),
                endDate: Date().addingTimeInterval(86400 * 5 + 7200),
                isAllDay: false,
                requiresRegistration: true,
                maxCapacity: 50,
                currentRegistrations: 32,
                category: .youth,
                createdAt: Date()
            ),
            ChurchEvent(
                id: "3",
                churchId: "church1",
                title: "Community Outreach Day",
                description: "Serve our community together through various service projects.",
                imageUrl: nil,
                startDate: Date().addingTimeInterval(86400 * 7),
                isAllDay: true,
                requiresRegistration: true,
                category: .outreach,
                volunteerRoles: [
                    VolunteerRole(id: "v1", name: "Food Distribution", requiredCount: 10, filledCount: 6),
                    VolunteerRole(id: "v2", name: "Setup Crew", requiredCount: 5, filledCount: 5)
                ],
                createdAt: Date()
            )
        ]
    }
}
