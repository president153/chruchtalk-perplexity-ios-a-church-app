import Foundation

// MARK: - User (for Auth)

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    var isEmailVerified: Bool
    var profileUrl: String?

    var firstName: String {
        let parts = name.split(separator: " ")
        return String(parts.first ?? "")
    }

    var lastName: String {
        let parts = name.split(separator: " ")
        return parts.count > 1 ? String(parts.dropFirst().joined(separator: " ")) : ""
    }
}

// MARK: - Church

struct Church: Identifiable, Codable {
    let id: String
    let name: String
    let memberCount: Int

    // Profile Images
    var imageUrl: String?  // Logo/profile image
    var coverImageUrl: String?  // Banner/cover image

    // Address (can be full or partial)
    var address: ChurchAddress?

    // For backward compatibility - computed from address
    var city: String {
        address?.city ?? ""
    }
    var state: String {
        address?.state ?? ""
    }

    // Contact Information
    var contactInfo: ChurchContactInfo?

    // Social Media Links
    var socialLinks: ChurchSocialLinks?

    // Content
    var description: String?
    var aboutContent: String?  // Extended about section
    var serviceTimes: [ServiceTime]?

    // Additional Info
    var websiteUrl: String?
    var foundedYear: Int?
    var denomination: String?

    // Leadership
    var pastor: ChurchLeader?
    var leadershipTeam: [ChurchLeader]?

    // Mission & Vision
    var missionStatement: String?
    var visionStatement: String?
    var coreValues: [String]?

    // Ministries
    var ministries: [ChurchMinistry]?

    // Computed
    var hasLeadership: Bool {
        pastor != nil || !(leadershipTeam?.isEmpty ?? true)
    }

    var hasMissionVision: Bool {
        missionStatement != nil || visionStatement != nil
    }

    var hasMinistries: Bool {
        !(ministries?.isEmpty ?? true)
    }

    var locationString: String {
        if let addr = address {
            return addr.shortFormatted
        }
        return ""
    }

    // Custom initializer for backward compatibility
    init(id: String, name: String, city: String, state: String, memberCount: Int,
         imageUrl: String? = nil, coverImageUrl: String? = nil, description: String? = nil,
         serviceTimes: [ServiceTime]? = nil, contactInfo: ChurchContactInfo? = nil,
         socialLinks: ChurchSocialLinks? = nil, websiteUrl: String? = nil,
         aboutContent: String? = nil, foundedYear: Int? = nil, denomination: String? = nil) {
        self.id = id
        self.name = name
        self.memberCount = memberCount
        self.imageUrl = imageUrl
        self.coverImageUrl = coverImageUrl
        self.address = ChurchAddress(street: "", city: city, state: state, zipCode: "")
        self.description = description
        self.serviceTimes = serviceTimes
        self.contactInfo = contactInfo
        self.socialLinks = socialLinks
        self.websiteUrl = websiteUrl
        self.aboutContent = aboutContent
        self.foundedYear = foundedYear
        self.denomination = denomination
    }

    // CodingKeys to handle _id from backend
    private enum CodingKeys: String, CodingKey {
        case id, _id, name, memberCount, imageUrl, coverImageUrl, address
        case contactInfo, socialLinks, description, aboutContent, serviceTimes
        case websiteUrl, foundedYear, denomination, pastor, leadershipTeam
        case missionStatement, visionStatement, coreValues, ministries
    }

    // Custom decoder to handle _id from backend
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle both "id" and "_id" from backend
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else {
            id = try container.decode(String.self, forKey: ._id)
        }

        name = try container.decode(String.self, forKey: .name)
        memberCount = try container.decodeIfPresent(Int.self, forKey: .memberCount) ?? 0
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        coverImageUrl = try container.decodeIfPresent(String.self, forKey: .coverImageUrl)
        address = try container.decodeIfPresent(ChurchAddress.self, forKey: .address)
        contactInfo = try container.decodeIfPresent(ChurchContactInfo.self, forKey: .contactInfo)
        socialLinks = try container.decodeIfPresent(ChurchSocialLinks.self, forKey: .socialLinks)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        aboutContent = try container.decodeIfPresent(String.self, forKey: .aboutContent)
        serviceTimes = try container.decodeIfPresent([ServiceTime].self, forKey: .serviceTimes)
        websiteUrl = try container.decodeIfPresent(String.self, forKey: .websiteUrl)
        foundedYear = try container.decodeIfPresent(Int.self, forKey: .foundedYear)
        denomination = try container.decodeIfPresent(String.self, forKey: .denomination)
        pastor = try container.decodeIfPresent(ChurchLeader.self, forKey: .pastor)
        leadershipTeam = try container.decodeIfPresent([ChurchLeader].self, forKey: .leadershipTeam)
        missionStatement = try container.decodeIfPresent(String.self, forKey: .missionStatement)
        visionStatement = try container.decodeIfPresent(String.self, forKey: .visionStatement)
        coreValues = try container.decodeIfPresent([String].self, forKey: .coreValues)
        ministries = try container.decodeIfPresent([ChurchMinistry].self, forKey: .ministries)
    }

    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(memberCount, forKey: .memberCount)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(coverImageUrl, forKey: .coverImageUrl)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(contactInfo, forKey: .contactInfo)
        try container.encodeIfPresent(socialLinks, forKey: .socialLinks)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(aboutContent, forKey: .aboutContent)
        try container.encodeIfPresent(serviceTimes, forKey: .serviceTimes)
        try container.encodeIfPresent(websiteUrl, forKey: .websiteUrl)
        try container.encodeIfPresent(foundedYear, forKey: .foundedYear)
        try container.encodeIfPresent(denomination, forKey: .denomination)
        try container.encodeIfPresent(pastor, forKey: .pastor)
        try container.encodeIfPresent(leadershipTeam, forKey: .leadershipTeam)
        try container.encodeIfPresent(missionStatement, forKey: .missionStatement)
        try container.encodeIfPresent(visionStatement, forKey: .visionStatement)
        try container.encodeIfPresent(coreValues, forKey: .coreValues)
        try container.encodeIfPresent(ministries, forKey: .ministries)
    }
}

// MARK: - Church Address

struct ChurchAddress: Codable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var country: String = "USA"
    var latitude: Double?
    var longitude: Double?

    var formatted: String {
        var parts: [String] = []
        if !street.isEmpty { parts.append(street) }
        if !city.isEmpty { parts.append(city) }
        if !state.isEmpty { parts.append(state) }
        if !zipCode.isEmpty { parts.append(zipCode) }
        return parts.joined(separator: ", ")
    }

    var shortFormatted: String {
        if !city.isEmpty && !state.isEmpty {
            return "\(city), \(state)"
        }
        return city.isEmpty ? state : city
    }

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }
}

// MARK: - Church Contact Info

struct ChurchContactInfo: Codable {
    var phone: String?
    var email: String?
    var fax: String?
    var officeHours: String?

    var hasContactInfo: Bool {
        phone != nil || email != nil
    }
}

// MARK: - Church Social Links

struct ChurchSocialLinks: Codable {
    var facebook: String?
    var instagram: String?
    var twitter: String?
    var youtube: String?
    var tiktok: String?

    var hasSocialLinks: Bool {
        facebook != nil || instagram != nil || twitter != nil || youtube != nil || tiktok != nil
    }

    var availableLinks: [(platform: String, url: String, icon: String)] {
        var links: [(String, String, String)] = []
        if let fb = facebook { links.append(("Facebook", fb, "link")) }
        if let ig = instagram { links.append(("Instagram", ig, "camera")) }
        if let tw = twitter { links.append(("X", tw, "at")) }
        if let yt = youtube { links.append(("YouTube", yt, "play.rectangle")) }
        if let tt = tiktok { links.append(("TikTok", tt, "music.note")) }
        return links
    }
}

// MARK: - Church Leader

struct ChurchLeader: Identifiable, Codable {
    let id: String
    let name: String
    let role: String  // "Senior Pastor", "Youth Pastor", etc.
    var photoUrl: String?
    var email: String?
    var bio: String?

    var initials: String {
        let parts = name.split(separator: " ")
        let firstInitial = parts.first?.first.map { String($0) } ?? ""
        let lastInitial = parts.count > 1 ? parts.last?.first.map { String($0) } ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }
}

// MARK: - Church Ministry

struct ChurchMinistry: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    var leaderName: String?
    var iconName: String?  // SF Symbol name
    var meetingTime: String?
    var contactEmail: String?

    var displayIcon: String {
        iconName ?? "hands.sparkles.fill"
    }
}

struct ServiceTime: Codable, Identifiable {
    var id: String { "\(day)-\(time)" }
    let day: String
    let time: String
    var serviceName: String?

    var displayString: String {
        if let name = serviceName {
            return "\(day) at \(time) - \(name)"
        }
        return "\(day) at \(time)"
    }
}

// MARK: - Member

struct Member: Identifiable, Codable, Hashable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    var phone: String?
    var avatarUrl: String?
    var churchId: String?
    var ministries: [String]

    // Extended profile fields
    var dateOfBirth: Date?
    var address: Address?
    var profilePhotoUrl: String?
    var spiritualJourney: SpiritualJourney?
    var familyId: String?
    var role: MemberRole

    // Fields from backend API
    var userId: String?
    var isPendingApproval: Bool?
    var createdAt: Date?
    var updatedAt: Date?

    // Memberwise initializer for creating instances in code
    init(
        id: String,
        firstName: String,
        lastName: String,
        email: String,
        phone: String? = nil,
        avatarUrl: String? = nil,
        churchId: String? = nil,
        ministries: [String] = [],
        dateOfBirth: Date? = nil,
        address: Address? = nil,
        profilePhotoUrl: String? = nil,
        spiritualJourney: SpiritualJourney? = nil,
        familyId: String? = nil,
        role: MemberRole = .member,
        userId: String? = nil,
        isPendingApproval: Bool? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.avatarUrl = avatarUrl
        self.churchId = churchId
        self.ministries = ministries
        self.dateOfBirth = dateOfBirth
        self.address = address
        self.profilePhotoUrl = profilePhotoUrl
        self.spiritualJourney = spiritualJourney
        self.familyId = familyId
        self.role = role
        self.userId = userId
        self.isPendingApproval = isPendingApproval
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoder to handle missing fields with defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        churchId = try container.decodeIfPresent(String.self, forKey: .churchId)
        ministries = try container.decodeIfPresent([String].self, forKey: .ministries) ?? []
        dateOfBirth = try container.decodeIfPresent(Date.self, forKey: .dateOfBirth)
        address = try container.decodeIfPresent(Address.self, forKey: .address)
        profilePhotoUrl = try container.decodeIfPresent(String.self, forKey: .profilePhotoUrl)
        spiritualJourney = try container.decodeIfPresent(SpiritualJourney.self, forKey: .spiritualJourney)
        familyId = try container.decodeIfPresent(String.self, forKey: .familyId)
        role = try container.decodeIfPresent(MemberRole.self, forKey: .role) ?? .member
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        isPendingApproval = try container.decodeIfPresent(Bool.self, forKey: .isPendingApproval)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id, firstName, lastName, email, phone, avatarUrl, churchId, ministries
        case dateOfBirth, address, profilePhotoUrl, spiritualJourney, familyId, role
        case userId, isPendingApproval, createdAt, updatedAt
    }

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
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }

    var isAdmin: Bool {
        role.isAdminRole || role == .leader
    }
}

enum MemberRole: String, Codable {
    case owner
    case admin
    case leader
    case staff
    case member
    case visitor

    /// Check if this role has admin privileges
    var isAdminRole: Bool {
        self == .owner || self == .admin
    }

    /// Check if this role can manage members
    var canManageMembers: Bool {
        [.owner, .admin, .leader].contains(self)
    }

    /// Check if this role can create content
    var canCreateContent: Bool {
        [.owner, .admin, .leader, .staff].contains(self)
    }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .leader: return "Leader"
        case .staff: return "Staff"
        case .member: return "Member"
        case .visitor: return "Visitor"
        }
    }
}

// MARK: - Address

struct Address: Codable, Hashable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var country: String = "USA"

    var formatted: String {
        "\(street), \(city), \(state) \(zipCode)"
    }
}

// MARK: - Spiritual Journey (8 Stages)

enum SpiritualStage: Int, Codable, CaseIterable {
    case initialContact = 0
    case gospelPresentation = 1
    case saved = 2
    case baptized = 3
    case membership = 4
    case discipleship = 5
    case readyToServe = 6
    case serving = 7

    var displayName: String {
        switch self {
        case .initialContact: return "Initial Contact"
        case .gospelPresentation: return "Gospel Presentation"
        case .saved: return "Saved"
        case .baptized: return "Baptized"
        case .membership: return "Membership"
        case .discipleship: return "Discipleship"
        case .readyToServe: return "Ready to Serve"
        case .serving: return "Serving"
        }
    }

    var description: String {
        switch self {
        case .initialContact: return "First connection with the church"
        case .gospelPresentation: return "Heard the Gospel message"
        case .saved: return "Accepted Jesus Christ as Lord and Savior"
        case .baptized: return "Baptized in water"
        case .membership: return "Became a church member"
        case .discipleship: return "Growing through discipleship training"
        case .readyToServe: return "Prepared and ready to serve"
        case .serving: return "Actively serving in ministry"
        }
    }

    var iconName: String {
        switch self {
        case .initialContact: return "person.wave.2"
        case .gospelPresentation: return "book.fill"
        case .saved: return "heart.fill"
        case .baptized: return "drop.fill"
        case .membership: return "person.badge.plus"
        case .discipleship: return "graduationcap.fill"
        case .readyToServe: return "hand.raised.fill"
        case .serving: return "star.fill"
        }
    }
}

struct SpiritualJourney: Codable, Hashable {
    var currentStage: SpiritualStage
    var salvationDate: Date?
    var baptismDate: Date?
    var membershipDate: Date?
    var discipleshipCompletedDate: Date?
    var ministryInterests: [String] = []
    var currentMinistries: [String] = []
    var notes: String?
}

// MARK: - Family Management

struct Family: Identifiable, Codable {
    let id: String
    var name: String
    var memberIds: [String]
    var relationships: [FamilyRelationship]
}

struct FamilyRelationship: Codable, Identifiable {
    var id: String { "\(memberId1)-\(memberId2)" }
    let memberId1: String
    let memberId2: String
    let relationshipType: RelationshipType
}

enum RelationshipType: String, Codable, CaseIterable {
    case spouse
    case child
    case parent

    var displayName: String {
        switch self {
        case .spouse: return "Spouse"
        case .child: return "Child"
        case .parent: return "Parent"
        }
    }

    var iconName: String {
        switch self {
        case .spouse: return "heart.fill"
        case .child: return "figure.and.child.holdinghands"
        case .parent: return "person.2.fill"
        }
    }
}

struct FamilyMember: Identifiable {
    let id: String
    let member: Member
    let relationship: RelationshipType
}

// MARK: - Bulletin Post

struct BulletinPost: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let content: String
    let author: Member
    var mediaUrls: [String] = []
    var youtubeUrl: String?
    let publishedAt: Date
    var reactions: Reactions
    var commentCount: Int
    var userReaction: ReactionType?
}

struct Reactions: Codable, Hashable {
    var like: Int
    var pray: Int
    var amen: Int

    var total: Int {
        like + pray + amen
    }
}

enum ReactionType: String, Codable {
    case like
    case pray
    case amen
}

// MARK: - Comment

struct Comment: Identifiable, Codable, Hashable {
    let id: String
    let content: String
    let author: Member
    let createdAt: Date
    var postId: String?
    var parentId: String?
    var replies: [Comment] = []
}

// MARK: - Outreach

struct Territory: Identifiable, Decodable {
    let id: String
    let churchId: String
    let name: String
    var status: TerritoryStatus
    var assignedTo: String?
    var progress: Double
    var createdAt: Date
    var updatedAt: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else {
            id = try container.decode(String.self, forKey: ._id)
        }
        churchId = try container.decode(String.self, forKey: .churchId)
        name = try container.decode(String.self, forKey: .name)
        status = try container.decodeIfPresent(TerritoryStatus.self, forKey: .status) ?? .unassigned
        assignedTo = try container.decodeIfPresent(String.self, forKey: .assignedTo)
        progress = try container.decodeIfPresent(Double.self, forKey: .progress) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    private enum CodingKeys: String, CodingKey {
        case id, _id, churchId, name, status, assignedTo, progress, createdAt, updatedAt
    }
}

enum TerritoryStatus: String, Codable {
    case unassigned
    case assigned
    case inProgress = "in_progress"
    case completed

    var displayName: String {
        switch self {
        case .unassigned: return "Unassigned"
        case .assigned: return "Assigned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }
}

struct OutreachStreet: Identifiable, Decodable {
    let id: String
    let territoryId: String
    let name: String
    var completionPercent: Double
    var estimatedHouses: Int?
    var lastVisitedAt: Date?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else {
            id = try container.decode(String.self, forKey: ._id)
        }
        territoryId = try container.decode(String.self, forKey: .territoryId)
        name = try container.decode(String.self, forKey: .name)
        completionPercent = try container.decodeIfPresent(Double.self, forKey: .completionPercent) ?? 0
        estimatedHouses = try container.decodeIfPresent(Int.self, forKey: .estimatedHouses)
        lastVisitedAt = try container.decodeIfPresent(Date.self, forKey: .lastVisitedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id, _id, territoryId, name, completionPercent, estimatedHouses, lastVisitedAt
    }
}

struct OutreachDoor: Identifiable, Decodable {
    let id: String
    let streetId: String
    let houseNumber: String
    let fullAddress: String
    var status: DoorStatus
    var residentName: String?
    var notes: String?
    var lastVisitedAt: Date?
    var lastVisitedBy: String?
    var latitude: Double?
    var longitude: Double?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else {
            id = try container.decode(String.self, forKey: ._id)
        }
        streetId = try container.decode(String.self, forKey: .streetId)
        houseNumber = try container.decode(String.self, forKey: .houseNumber)
        fullAddress = try container.decode(String.self, forKey: .fullAddress)
        status = try container.decodeIfPresent(DoorStatus.self, forKey: .status) ?? .notVisited
        residentName = try container.decodeIfPresent(String.self, forKey: .residentName)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        lastVisitedAt = try container.decodeIfPresent(Date.self, forKey: .lastVisitedAt)
        lastVisitedBy = try container.decodeIfPresent(String.self, forKey: .lastVisitedBy)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
    }

    private enum CodingKeys: String, CodingKey {
        case id, _id, streetId, houseNumber, fullAddress, status
        case residentName, notes, lastVisitedAt, lastVisitedBy, latitude, longitude
    }
}

struct ActiveCollaborator: Identifiable, Decodable {
    let id: String
    let churchId: String
    let territoryId: String
    let memberId: String
    let memberName: String
    let memberInitials: String
    var currentDoorId: String?
    var checkedInAt: Date
    var lastActiveAt: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else {
            id = try container.decode(String.self, forKey: ._id)
        }
        churchId = try container.decode(String.self, forKey: .churchId)
        territoryId = try container.decode(String.self, forKey: .territoryId)
        memberId = try container.decode(String.self, forKey: .memberId)
        memberName = try container.decode(String.self, forKey: .memberName)
        memberInitials = try container.decode(String.self, forKey: .memberInitials)
        currentDoorId = try container.decodeIfPresent(String.self, forKey: .currentDoorId)
        checkedInAt = try container.decodeIfPresent(Date.self, forKey: .checkedInAt) ?? Date()
        lastActiveAt = try container.decodeIfPresent(Date.self, forKey: .lastActiveAt) ?? Date()
    }

    private enum CodingKeys: String, CodingKey {
        case id, _id, churchId, territoryId, memberId, memberName, memberInitials
        case currentDoorId, checkedInAt, lastActiveAt
    }
}

struct OutreachStats: Codable {
    let doorsKnocked: Int
    let followUps: Int
    let territoriesAssigned: Int
}

enum DoorStatus: String, Codable {
    case notVisited = "not_visited"
    case notHome = "not_home"
    case interested
    case notInterested = "not_interested"
    case followUp = "follow_up"
    case doNotContact = "do_not_contact"
    case alreadyMember = "already_member"

    var displayName: String {
        switch self {
        case .notVisited: return "Not Visited"
        case .notHome: return "Not Home"
        case .interested: return "Interested"
        case .notInterested: return "Not Interested"
        case .followUp: return "Follow Up"
        case .doNotContact: return "Do Not Contact"
        case .alreadyMember: return "Already Member"
        }
    }

    var color: String {
        switch self {
        case .notVisited: return "gray"
        case .notHome: return "orange"
        case .interested: return "green"
        case .notInterested: return "red"
        case .followUp: return "purple"
        case .alreadyMember: return "blue"
        case .doNotContact: return "black"
        }
    }
}

// MARK: - Prayer

enum PrayerRequestStatus: String, Codable {
    case pending
    case approved
    case rejected
}

struct PrayerRequest: Identifiable, Codable {
    let id: String
    let content: String
    let authorId: String
    var authorName: String?
    let isAnonymous: Bool
    var prayerCount: Int
    let createdAt: Date
    var hasPrayed: Bool = false

    // Moderation fields
    var status: PrayerRequestStatus = .pending
    var reviewedBy: String?
    var reviewedAt: Date?

    var displayAuthor: String {
        if isAnonymous {
            return "Anonymous"
        }
        return authorName ?? "Unknown"
    }

    var isPending: Bool {
        status == .pending
    }

    var isApproved: Bool {
        status == .approved
    }
}

