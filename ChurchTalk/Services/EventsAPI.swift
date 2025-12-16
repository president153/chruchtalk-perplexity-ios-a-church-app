//
//  EventsAPI.swift
//  ChurchTalk
//
//  API service for event-related endpoints.
//

import Foundation

// MARK: - Response Types

/// Response wrapper for events list
struct EventsListResponse: Codable {
    let events: [EventResponse]
    let total: Int
}

/// Response for a single event from API
struct EventResponse: Codable {
    let id: String
    let churchId: String
    let title: String
    let description: String?
    let imageUrl: String?
    let startDate: String
    let endDate: String?
    let isAllDay: Bool?
    let location: EventLocationResponse?
    let isVirtual: Bool?
    let virtualMeetingUrl: String?
    let requiresRegistration: Bool?
    let maxCapacity: Int?
    let currentRegistrations: Int?
    let registrationDeadline: String?
    let category: String?
    let tags: [String]?
    let isPublished: Bool?
    let isFeatured: Bool?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case churchId, title, description, imageUrl
        case startDate, endDate, isAllDay
        case location, isVirtual, virtualMeetingUrl
        case requiresRegistration, maxCapacity, currentRegistrations, registrationDeadline
        case category, tags, isPublished, isFeatured
        case createdAt, updatedAt
    }

    /// Convert API response to ChurchEvent model
    func toChurchEvent() -> ChurchEvent {
        let start = parseDate(startDate) ?? Date()
        let end = endDate.flatMap { parseDate($0) }
        let created = parseDate(createdAt) ?? Date()

        // Parse category
        let eventCategory: EventCategory
        if let cat = category {
            eventCategory = EventCategory(rawValue: cat) ?? .other
        } else {
            eventCategory = .other
        }

        // Parse location
        var eventLocation: EventLocation?
        if let loc = location {
            eventLocation = EventLocation(
                name: loc.name,
                address: loc.address,
                room: loc.room,
                latitude: loc.latitude,
                longitude: loc.longitude
            )
        }

        return ChurchEvent(
            id: id,
            churchId: churchId,
            title: title,
            description: description,
            imageUrl: imageUrl,
            startDate: start,
            endDate: end,
            isAllDay: isAllDay ?? false,
            recurrenceRule: nil,
            location: eventLocation,
            isVirtual: isVirtual ?? false,
            virtualMeetingUrl: virtualMeetingUrl,
            requiresRegistration: requiresRegistration ?? false,
            maxCapacity: maxCapacity,
            currentRegistrations: currentRegistrations ?? 0,
            registrationDeadline: registrationDeadline.flatMap { parseDate($0) },
            category: eventCategory,
            tags: tags ?? [],
            volunteerRoles: nil,
            createdBy: nil,
            createdAt: created,
            updatedAt: updatedAt.flatMap { parseDate($0) },
            isPublished: isPublished ?? true,
            isFeatured: isFeatured ?? false
        )
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")

        // Try with 6 fractional second digits
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let date = formatter.date(from: string) { return date }

        // Try with 3 fractional second digits
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let date = formatter.date(from: string) { return date }

        // Try without fractional seconds
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: string) { return date }

        // Try ISO8601
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: string) { return date }

        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: string)
    }
}

/// Location response from API
struct EventLocationResponse: Codable {
    let name: String?
    let address: String?
    let room: String?
    let latitude: Double?
    let longitude: Double?
}

/// Request body for event registration
struct EventRegistrationRequest: Codable {
    let guestCount: Int?
    let notes: String?
}

/// Response for event registration
struct EventRegistrationResponse: Codable {
    let id: String
    let eventId: String
    let memberId: String
    let status: String
    let registeredAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case eventId, memberId, status, registeredAt
    }
}

// MARK: - EventsAPI

/// API service for event operations
class EventsAPI {

    // MARK: - Singleton

    static let shared = EventsAPI()

    // MARK: - Dependencies

    private let client = APIClient.shared

    // MARK: - Init

    private init() {}

    // MARK: - Events

    /// Get all events
    /// - Parameters:
    ///   - skip: Number of records to skip
    ///   - limit: Maximum records to return
    ///   - category: Filter by category
    /// - Returns: Array of ChurchEvent
    func getEvents(
        skip: Int = 0,
        limit: Int = 50,
        category: EventCategory? = nil
    ) async throws -> [ChurchEvent] {
        var endpoint = "/events?skip=\(skip)&limit=\(limit)"
        if let cat = category {
            endpoint += "&category=\(cat.rawValue)"
        }
        let response: [EventResponse] = try await client.get(endpoint)
        return response.map { $0.toChurchEvent() }
    }

    /// Get upcoming events
    /// - Parameter limit: Maximum records to return
    /// - Returns: Array of ChurchEvent
    func getUpcomingEvents(limit: Int = 20) async throws -> [ChurchEvent] {
        let response: [EventResponse] = try await client.get("/events/upcoming?limit=\(limit)")
        return response.map { $0.toChurchEvent() }
    }

    /// Get a single event by ID
    /// - Parameter eventId: The event ID
    /// - Returns: ChurchEvent
    func getEvent(eventId: String) async throws -> ChurchEvent {
        let response: EventResponse = try await client.get("/events/\(eventId)")
        return response.toChurchEvent()
    }

    /// Register for an event
    /// - Parameters:
    ///   - eventId: The event ID
    ///   - guestCount: Number of additional guests
    ///   - notes: Optional notes
    /// - Returns: EventRegistration
    func registerForEvent(
        eventId: String,
        guestCount: Int = 0,
        notes: String? = nil
    ) async throws -> EventRegistration {
        let request = EventRegistrationRequest(guestCount: guestCount, notes: notes)
        let response: EventRegistrationResponse = try await client.post(
            "/events/\(eventId)/register",
            body: request
        )

        return EventRegistration(
            id: response.id,
            eventId: response.eventId,
            memberId: response.memberId,
            status: RegistrationStatus(rawValue: response.status) ?? .registered,
            registeredAt: parseDate(response.registeredAt) ?? Date()
        )
    }

    /// Cancel event registration
    /// - Parameter eventId: The event ID
    func cancelRegistration(eventId: String) async throws {
        try await client.delete("/events/\(eventId)/register")
    }

    /// Get events for a specific month (for calendar view)
    /// - Parameters:
    ///   - year: Year
    ///   - month: Month (1-12)
    /// - Returns: Array of ChurchEvent
    func getEventsForMonth(year: Int, month: Int) async throws -> [ChurchEvent] {
        let response: [EventResponse] = try await client.get(
            "/events?year=\(year)&month=\(month)"
        )
        return response.map { $0.toChurchEvent() }
    }

    // MARK: - Helpers

    private func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let date = formatter.date(from: string) { return date }

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let date = formatter.date(from: string) { return date }

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: string)
    }
}
