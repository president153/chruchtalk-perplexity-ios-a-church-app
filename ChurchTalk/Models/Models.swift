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

struct Member: Identifiable, Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    var phone: String?
    var avatarUrl: String?
    let churchId: String
    var ministries: [String] = []

    // Extended profile fields
    var dateOfBirth: Date?
    var address: Address?
    var profilePhotoUrl: String?
    var spiritualJourney: SpiritualJourney?
    var familyId: String?
    var role: MemberRole = .member

    // Fields from backend API
    var userId: String?
    var isPendingApproval: Bool = false
    var createdAt: Date?
    var updatedAt: Date?

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
        role == .admin || role == .leader
    }
}

enum MemberRole: String, Codable {
    case admin
    case leader
    case member
}

// MARK: - Address

struct Address: Codable {
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

struct SpiritualJourney: Codable {
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

struct BulletinPost: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let author: Member
    var mediaUrls: [String] = []
    var youtubeUrl: String?
    let publishedAt: Date
    var reactions: Reactions
    var commentCount: Int
}

struct Reactions: Codable {
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

struct Comment: Identifiable, Codable {
    let id: String
    let content: String
    let author: Member
    let createdAt: Date
    var postId: String?
}

// MARK: - Outreach

struct Territory: Identifiable, Codable {
    let id: String
    let name: String
    var streets: [OutreachStreet] = []
    var status: TerritoryStatus = .unassigned
    var assignedTo: String?
    var progress: Double = 0
}

enum TerritoryStatus: String, Codable {
    case unassigned
    case assigned
    case inProgress = "in_progress"
    case completed
}

struct OutreachStreet: Identifiable, Codable {
    let id: String
    let name: String
    var doors: [OutreachDoor] = []
    var completionPercent: Double = 0
}

struct OutreachDoor: Identifiable, Codable {
    let id: String
    let houseNumber: String
    let fullAddress: String
    var status: DoorStatus = .notVisited
    var residentName: String?
    var notes: String?
    var lastVisitedAt: Date?
    var lastVisitedBy: String?
}

enum DoorStatus: String, Codable {
    case notVisited = "not_visited"
    case notHome = "not_home"
    case interested
    case notInterested = "not_interested"
    case followUp = "follow_up"
    case doNotContact = "do_not_contact"

    var displayName: String {
        switch self {
        case .notVisited: return "Not Visited"
        case .notHome: return "Not Home"
        case .interested: return "Interested"
        case .notInterested: return "Not Interested"
        case .followUp: return "Follow Up"
        case .doNotContact: return "Do Not Contact"
        }
    }

    var color: String {
        switch self {
        case .notVisited: return "gray"
        case .notHome: return "orange"
        case .interested: return "green"
        case .notInterested: return "red"
        case .followUp: return "purple"
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

// MARK: - Collaboration

struct ActiveCollaborator: Identifiable, Codable {
    let id: String
    let memberId: String
    let memberName: String
    var memberInitials: String
    var currentDoorId: String?
    let checkedInAt: Date
    var lastActiveAt: Date
}
