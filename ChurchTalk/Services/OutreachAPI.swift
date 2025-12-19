//
//  OutreachAPI.swift
//  ChurchTalk
//
//  API service for outreach: territories, streets, doors.
//

import Foundation

// MARK: - Request Types

struct CreateTerritoryRequest: Codable {
    let name: String
}

struct UpdateDoorRequest: Codable {
    var status: String?
    var residentName: String?
    var notes: String?
}

// MARK: - OutreachAPI

/// API service for outreach operations
class OutreachAPI {

    // MARK: - Singleton

    static let shared = OutreachAPI()

    // MARK: - Dependencies

    private let client = APIClient.shared

    // MARK: - Init

    private init() {}

    // MARK: - Stats

    /// Get outreach stats for the current member
    func getStats() async throws -> OutreachStats {
        return try await client.get("/outreach/stats")
    }

    // MARK: - Territories

    /// Get list of territories for the church
    func getTerritories(
        status: TerritoryStatus? = nil,
        skip: Int = 0,
        limit: Int = 50
    ) async throws -> [Territory] {
        var endpoint = "/outreach/territories?skip=\(skip)&limit=\(limit)"
        if let status = status {
            endpoint += "&status=\(status.rawValue)"
        }
        return try await client.get(endpoint)
    }

    /// Get a specific territory by ID
    func getTerritory(id: String) async throws -> Territory {
        return try await client.get("/outreach/territories/\(id)")
    }

    /// Create a new territory (admin only)
    func createTerritory(name: String) async throws -> Territory {
        let request = CreateTerritoryRequest(name: name)
        return try await client.post("/outreach/territories", body: request)
    }

    /// Assign territory to a member
    func assignTerritory(id: String, memberId: String) async throws -> Territory {
        return try await client.post("/outreach/territories/\(id)/assign?member_id=\(memberId)")
    }

    /// Unassign territory
    func unassignTerritory(id: String) async throws -> Territory {
        return try await client.post("/outreach/territories/\(id)/unassign")
    }

    /// Check in to a territory for outreach
    func checkinToTerritory(id: String) async throws -> [String: Any] {
        struct CheckinResponse: Codable {
            let success: Bool
        }
        let _: CheckinResponse = try await client.post("/outreach/territories/\(id)/checkin")
        return ["success": true]
    }

    /// Check out from a territory
    func checkoutFromTerritory(id: String) async throws -> Bool {
        struct CheckoutResponse: Codable {
            let success: Bool
        }
        let response: CheckoutResponse = try await client.post("/outreach/territories/\(id)/checkout")
        return response.success
    }

    /// Get active collaborators in a territory
    func getCollaborators(territoryId: String) async throws -> [ActiveCollaborator] {
        struct CollaboratorsResponse: Decodable {
            let collaborators: [ActiveCollaborator]
        }
        let response: CollaboratorsResponse = try await client.get("/outreach/territories/\(territoryId)/collaborators")
        return response.collaborators
    }

    /// Send heartbeat to keep collaborator active
    func sendHeartbeat(territoryId: String) async throws -> Bool {
        struct HeartbeatResponse: Codable {
            let success: Bool
        }
        let response: HeartbeatResponse = try await client.post("/outreach/territories/\(territoryId)/heartbeat")
        return response.success
    }

    // MARK: - Streets

    /// Get streets in a territory
    func getStreets(territoryId: String, skip: Int = 0, limit: Int = 100) async throws -> [OutreachStreet] {
        return try await client.get("/outreach/territories/\(territoryId)/streets?skip=\(skip)&limit=\(limit)")
    }

    /// Add a street to a territory
    func createStreet(territoryId: String, name: String, estimatedHouses: Int? = nil) async throws -> OutreachStreet {
        struct CreateStreetRequest: Codable {
            let name: String
            let estimatedHouses: Int?
        }
        let request = CreateStreetRequest(name: name, estimatedHouses: estimatedHouses)
        return try await client.post("/outreach/territories/\(territoryId)/streets", body: request)
    }

    /// Delete a street
    func deleteStreet(id: String) async throws {
        try await client.delete("/outreach/streets/\(id)")
    }

    // MARK: - Doors

    /// Get doors on a street
    func getDoors(streetId: String, skip: Int = 0, limit: Int = 200) async throws -> [OutreachDoor] {
        return try await client.get("/outreach/streets/\(streetId)/doors?skip=\(skip)&limit=\(limit)")
    }

    /// Get a specific door by ID
    func getDoor(id: String) async throws -> OutreachDoor {
        return try await client.get("/outreach/doors/\(id)")
    }

    /// Add a door to a street
    func createDoor(streetId: String, houseNumber: String, fullAddress: String, latitude: Double? = nil, longitude: Double? = nil) async throws -> OutreachDoor {
        struct CreateDoorRequest: Codable {
            let houseNumber: String
            let fullAddress: String
            let latitude: Double?
            let longitude: Double?
        }
        let request = CreateDoorRequest(houseNumber: houseNumber, fullAddress: fullAddress, latitude: latitude, longitude: longitude)
        return try await client.post("/outreach/streets/\(streetId)/doors", body: request)
    }

    /// Update door status and log visit
    func updateDoor(id: String, status: DoorStatus?, residentName: String? = nil, notes: String? = nil) async throws -> OutreachDoor {
        var request = UpdateDoorRequest()
        if let status = status {
            request.status = status.rawValue
        }
        request.residentName = residentName
        request.notes = notes
        return try await client.patch("/outreach/doors/\(id)", body: request)
    }

    /// Delete a door
    func deleteDoor(id: String) async throws {
        try await client.delete("/outreach/doors/\(id)")
    }

    // MARK: - Weekly Assignments (Agentic AI)

    /// Get current member's weekly street assignment
    func getMyWeeklyAssignment() async throws -> WeeklyAssignment? {
        return try await client.get("/outreach/my-assignment")
    }

    /// Accept a weekly assignment
    func acceptAssignment(id: String) async throws -> Bool {
        struct AcceptResponse: Codable {
            let success: Bool
            let message: String
        }
        let response: AcceptResponse = try await client.post("/outreach/assignments/\(id)/accept")
        return response.success
    }

    /// Start working on a weekly assignment
    func startAssignment(id: String) async throws -> Bool {
        struct StartResponse: Codable {
            let success: Bool
            let message: String
        }
        let response: StartResponse = try await client.post("/outreach/assignments/\(id)/start")
        return response.success
    }

    /// Complete a weekly assignment
    func completeAssignment(id: String, doorsVisited: Int) async throws -> Bool {
        struct CompleteRequest: Codable {
            let doorsVisited: Int
        }
        struct CompleteResponse: Codable {
            let success: Bool
            let message: String
        }
        let request = CompleteRequest(doorsVisited: doorsVisited)
        let response: CompleteResponse = try await client.post("/outreach/assignments/\(id)/complete", body: request)
        return response.success
    }

    /// Decline a weekly assignment
    func declineAssignment(id: String, reason: String? = nil) async throws -> Bool {
        struct DeclineRequest: Codable {
            let reason: String?
        }
        struct DeclineResponse: Codable {
            let success: Bool
            let message: String
        }
        let request = DeclineRequest(reason: reason)
        let response: DeclineResponse = try await client.post("/outreach/assignments/\(id)/decline", body: request)
        return response.success
    }

    /// Get weekly outreach statistics for the church
    func getWeeklyStats() async throws -> WeeklyStats {
        return try await client.get("/outreach/weekly-stats")
    }
}
