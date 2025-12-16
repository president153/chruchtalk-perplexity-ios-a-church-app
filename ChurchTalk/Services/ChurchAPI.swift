//
//  ChurchAPI.swift
//  ChurchTalk
//
//  API service for church-related endpoints.
//

import Foundation

// MARK: - Response Types

/// Response wrapper for church search
struct ChurchSearchResponse: Codable {
    let churches: [Church]
    let total: Int
}

// MARK: - ChurchAPI

/// API service for church operations
class ChurchAPI {

    // MARK: - Singleton

    static let shared = ChurchAPI()

    // MARK: - Dependencies

    private let client = APIClient.shared

    // MARK: - Init

    private init() {}

    // MARK: - Search Churches

    /// Search for churches
    /// - Parameters:
    ///   - query: Search query for church name
    ///   - city: Filter by city
    ///   - state: Filter by state
    ///   - skip: Pagination offset
    ///   - limit: Maximum results
    /// - Returns: Search results with churches
    func searchChurches(
        query: String? = nil,
        city: String? = nil,
        state: String? = nil,
        skip: Int = 0,
        limit: Int = 20
    ) async throws -> ChurchSearchResponse {
        var endpoint = "/churches?skip=\(skip)&limit=\(limit)"
        if let query = query, !query.isEmpty {
            endpoint += "&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        }
        if let city = city {
            endpoint += "&city=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city)"
        }
        if let state = state {
            endpoint += "&state=\(state.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? state)"
        }
        return try await client.get(endpoint)
    }

    // MARK: - Get Church

    /// Get church details by ID
    /// - Parameter id: Church ID
    /// - Returns: Church details
    func getChurch(id: String) async throws -> Church {
        return try await client.get("/churches/\(id)")
    }
}
