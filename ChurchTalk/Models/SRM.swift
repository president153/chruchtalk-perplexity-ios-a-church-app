import Foundation

// MARK: - Soul Types

enum SoulType: String, Codable, CaseIterable {
    case member
    case visitor
    case prospect

    var displayName: String {
        switch self {
        case .member: return "Member"
        case .visitor: return "Visitor"
        case .prospect: return "Prospect"
        }
    }

    var iconName: String {
        switch self {
        case .member: return "person.fill"
        case .visitor: return "person.badge.clock"
        case .prospect: return "person.crop.circle.badge.questionmark"
        }
    }
}

// MARK: - Soul Share Status

enum SoulShareStatus: String, Codable, CaseIterable {
    case `private`  // Only visible to user who added
    case pendingReview  // Submitted to admin for review
    case shared  // Approved and visible to church
    case rejected  // Admin rejected sharing

    var displayName: String {
        switch self {
        case .private: return "Private"
        case .pendingReview: return "Pending Review"
        case .shared: return "Shared"
        case .rejected: return "Rejected"
        }
    }

    var iconName: String {
        switch self {
        case .private: return "lock.fill"
        case .pendingReview: return "clock.fill"
        case .shared: return "person.3.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .private: return "gray"
        case .pendingReview: return "orange"
        case .shared: return "green"
        case .rejected: return "red"
        }
    }
}

// MARK: - Soul (Unified tracking entity)

struct Soul: Identifiable, Codable {
    let id: String
    let firstName: String
    let lastName: String
    var email: String?
    var phone: String?
    let soulType: SoulType
    var spiritualStage: SpiritualStage
    var assignedTo: String?
    var notes: String?
    var lastContactDate: Date?
    var nextFollowUpDate: Date?
    let createdAt: Date
    var updatedAt: Date

    // Optional link to Member if they become one
    var memberId: String?

    // Ownership and sharing
    var addedBy: String?  // Member ID of who added this soul
    var shareStatus: SoulShareStatus = .private
    var shareRejectionReason: String?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let firstInitial = firstName.first.map { String($0) } ?? ""
        let lastInitial = lastName.first.map { String($0) } ?? ""
        return (firstInitial + lastInitial).uppercased()
    }

    var needsFollowUp: Bool {
        guard let nextDate = nextFollowUpDate else { return false }
        return nextDate <= Date()
    }

    var isSharedWithChurch: Bool {
        shareStatus == .shared
    }

    var isPendingReview: Bool {
        shareStatus == .pendingReview
    }
}

// MARK: - SRM Dashboard Stats

struct SRMStats {
    var totalSouls: Int
    var byType: [SoulType: Int]
    var byStage: [SpiritualStage: Int]
    var recentlyContacted: Int
    var needingFollowUp: Int

    static var empty: SRMStats {
        SRMStats(
            totalSouls: 0,
            byType: [:],
            byStage: [:],
            recentlyContacted: 0,
            needingFollowUp: 0
        )
    }

    static func calculate(from souls: [Soul]) -> SRMStats {
        var byType: [SoulType: Int] = [:]
        var byStage: [SpiritualStage: Int] = [:]
        var recentlyContacted = 0
        var needingFollowUp = 0

        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        for soul in souls {
            byType[soul.soulType, default: 0] += 1
            byStage[soul.spiritualStage, default: 0] += 1

            if let lastContact = soul.lastContactDate, lastContact >= oneWeekAgo {
                recentlyContacted += 1
            }

            if soul.needsFollowUp {
                needingFollowUp += 1
            }
        }

        return SRMStats(
            totalSouls: souls.count,
            byType: byType,
            byStage: byStage,
            recentlyContacted: recentlyContacted,
            needingFollowUp: needingFollowUp
        )
    }
}

// MARK: - Follow-up Record

struct FollowUpRecord: Identifiable, Codable {
    let id: String
    let soulId: String
    let contactedBy: String
    let contactDate: Date
    let contactMethod: ContactMethod
    var notes: String
    var outcome: FollowUpOutcome
    var nextSteps: String?
}

enum ContactMethod: String, Codable, CaseIterable {
    case inPerson = "in_person"
    case phone
    case text
    case email
    case socialMedia = "social_media"

    var displayName: String {
        switch self {
        case .inPerson: return "In Person"
        case .phone: return "Phone Call"
        case .text: return "Text Message"
        case .email: return "Email"
        case .socialMedia: return "Social Media"
        }
    }

    var iconName: String {
        switch self {
        case .inPerson: return "person.fill"
        case .phone: return "phone.fill"
        case .text: return "message.fill"
        case .email: return "envelope.fill"
        case .socialMedia: return "globe"
        }
    }
}

enum FollowUpOutcome: String, Codable, CaseIterable {
    case positive
    case neutral
    case negative
    case noContact = "no_contact"

    var displayName: String {
        switch self {
        case .positive: return "Positive"
        case .neutral: return "Neutral"
        case .negative: return "Not Interested"
        case .noContact: return "No Contact"
        }
    }

    var iconName: String {
        switch self {
        case .positive: return "hand.thumbsup.fill"
        case .neutral: return "minus.circle.fill"
        case .negative: return "hand.thumbsdown.fill"
        case .noContact: return "phone.down.fill"
        }
    }
}

// MARK: - Ministry Categories

struct MinistryCategory {
    static let all: [String] = [
        "Worship",
        "Children",
        "Youth",
        "Outreach",
        "Ushers",
        "Greeters",
        "Tech/Media",
        "Hospitality",
        "Prayer Team",
        "Teaching",
        "Small Groups",
        "Missions",
        "Women's Ministry",
        "Men's Ministry",
        "Seniors Ministry",
        "Counseling",
        "Administration",
        "Facilities"
    ]
}
