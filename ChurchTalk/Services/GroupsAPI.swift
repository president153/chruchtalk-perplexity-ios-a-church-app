//
//  GroupsAPI.swift
//  ChurchTalk
//
//  API service for small groups / life groups.
//

import Foundation

// MARK: - Response Types

/// Group type enum matching backend
enum GroupType: String, Codable, CaseIterable {
    case smallGroup = "small_group"
    case lifeGroup = "life_group"
    case bibleStudy = "bible_study"
    case prayerGroup = "prayer_group"
    case ministryTeam = "ministry_team"
    case other = "other"

    var displayName: String {
        switch self {
        case .smallGroup: return "Small Group"
        case .lifeGroup: return "Life Group"
        case .bibleStudy: return "Bible Study"
        case .prayerGroup: return "Prayer Group"
        case .ministryTeam: return "Ministry Team"
        case .other: return "Other"
        }
    }
}

/// Meeting frequency enum matching backend
enum MeetingFrequency: String, Codable {
    case weekly
    case biweekly
    case monthly
    case asNeeded = "as_needed"

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        case .asNeeded: return "As Needed"
        }
    }
}

/// Group model
struct SmallGroup: Identifiable, Decodable {
    let id: String
    let churchId: String
    let name: String
    var description: String?
    var groupType: GroupType
    var leaderId: String?
    var leaderName: String?
    var memberCount: Int
    var maxMembers: Int?
    var meetingDay: String?
    var meetingTime: String?
    var meetingFrequency: MeetingFrequency
    var location: String?
    var isOpen: Bool
    var isActive: Bool
    var imageUrl: String?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    // Custom decoder for flexible API response
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle both _id and id
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else {
            id = try container.decode(String.self, forKey: ._id)
        }

        churchId = try container.decode(String.self, forKey: .churchId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        groupType = try container.decodeIfPresent(GroupType.self, forKey: .groupType) ?? .smallGroup
        leaderId = try container.decodeIfPresent(String.self, forKey: .leaderId)
        leaderName = try container.decodeIfPresent(String.self, forKey: .leaderName)
        memberCount = try container.decodeIfPresent(Int.self, forKey: .memberCount) ?? 0
        maxMembers = try container.decodeIfPresent(Int.self, forKey: .maxMembers)
        meetingDay = try container.decodeIfPresent(String.self, forKey: .meetingDay)
        meetingTime = try container.decodeIfPresent(String.self, forKey: .meetingTime)
        meetingFrequency = try container.decodeIfPresent(MeetingFrequency.self, forKey: .meetingFrequency) ?? .weekly
        location = try container.decodeIfPresent(String.self, forKey: .location)
        isOpen = try container.decodeIfPresent(Bool.self, forKey: .isOpen) ?? true
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    private enum CodingKeys: String, CodingKey {
        case id, _id, churchId, name, description, groupType, leaderId, leaderName
        case memberCount, maxMembers, meetingDay, meetingTime, meetingFrequency
        case location, isOpen, isActive, imageUrl, tags, createdAt, updatedAt
    }

    var meetingSchedule: String {
        var parts: [String] = []
        if let day = meetingDay {
            parts.append(day)
        }
        if let time = meetingTime {
            parts.append("at \(time)")
        }
        parts.append("(\(meetingFrequency.displayName))")
        return parts.joined(separator: " ")
    }
}

// MARK: - Request Types

struct CreateGroupRequest: Codable {
    let name: String
    var description: String?
    var groupType: String?
    var leaderId: String?
    var maxMembers: Int?
    var meetingDay: String?
    var meetingTime: String?
    var meetingFrequency: String?
    var location: String?
    var isOpen: Bool?
    var tags: [String]?
}

// MARK: - GroupsAPI

/// API service for groups operations
class GroupsAPI {

    // MARK: - Singleton

    static let shared = GroupsAPI()

    // MARK: - Dependencies

    private let client = APIClient.shared

    // MARK: - Init

    private init() {}

    // MARK: - Get Groups

    /// Get list of groups for the church
    /// - Parameters:
    ///   - type: Filter by group type
    ///   - isOpen: Filter by open/closed status
    ///   - skip: Pagination offset
    ///   - limit: Max results to return
    /// - Returns: Array of groups
    func getGroups(
        type: GroupType? = nil,
        isOpen: Bool? = nil,
        skip: Int = 0,
        limit: Int = 50
    ) async throws -> [SmallGroup] {
        var endpoint = "/groups?skip=\(skip)&limit=\(limit)"
        if let type = type {
            endpoint += "&type=\(type.rawValue)"
        }
        if let isOpen = isOpen {
            endpoint += "&open=\(isOpen)"
        }
        return try await client.get(endpoint)
    }

    // MARK: - Get My Groups

    /// Get groups the current member belongs to
    /// - Returns: Array of groups
    func getMyGroups() async throws -> [SmallGroup] {
        return try await client.get("/groups/my-groups")
    }

    // MARK: - Get Group

    /// Get a specific group by ID
    /// - Parameter id: Group ID
    /// - Returns: Group details
    func getGroup(id: String) async throws -> SmallGroup {
        return try await client.get("/groups/\(id)")
    }

    // MARK: - Join Group

    /// Join a group
    /// - Parameter id: Group ID to join
    /// - Returns: Updated group
    func joinGroup(id: String) async throws -> SmallGroup {
        return try await client.post("/groups/\(id)/join")
    }

    // MARK: - Leave Group

    /// Leave a group
    /// - Parameter id: Group ID to leave
    /// - Returns: Updated group
    func leaveGroup(id: String) async throws -> SmallGroup {
        return try await client.post("/groups/\(id)/leave")
    }

    // MARK: - Create Group (Admin)

    /// Create a new group (admin/leader only)
    /// - Parameter request: Group creation request
    /// - Returns: Created group
    func createGroup(request: CreateGroupRequest) async throws -> SmallGroup {
        return try await client.post("/groups", body: request)
    }
}
