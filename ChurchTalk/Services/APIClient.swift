//
//  APIClient.swift
//  ChurchTalk
//
//  Base API client with demo mode support for backend communication.
//

import Foundation

/// Notification posted when API receives 401 unauthorized response
extension Notification.Name {
    static let apiUnauthorized = Notification.Name("APIClientUnauthorized")
}

/// API errors that can occur during network requests.
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int)
    case decodingFailed(Error)
    case networkError(Error)
    case unauthorized
    case notFound
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let code):
            return "Request failed with status code: \(code)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized - please log in"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error - please try again later"
        }
    }
}

/// HTTP methods supported by the API client.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

/// Main API client for communicating with the ChurchTalk backend.
/// Supports demo mode which bypasses authentication for development.
class APIClient {

    // MARK: - Singleton

    static let shared = APIClient()

    // MARK: - Configuration

    /// Base URL for the API
    private let baseURL: String

    /// Whether demo mode is enabled (bypasses auth)
    private let isDemoMode: Bool

    /// Auth token for authenticated requests
    var authToken: String?

    // MARK: - Init

    private init() {
        // Use environment configuration for API URL and demo mode
        self.baseURL = AppConfig.apiBaseURL
        self.isDemoMode = AppConfig.isDemoMode
    }

    // MARK: - JSON Decoder

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        // Convert snake_case from backend to camelCase for Swift models
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // Configure date decoding for ISO8601 dates from backend
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds first
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }

            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }

            // Backend returns dates WITHOUT timezone (e.g., "2025-12-15T16:43:31.381831")
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(identifier: "UTC")

            // Try with 6 fractional second digits
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            // Try with 3 fractional second digits
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            // Try without fractional seconds
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return decoder
    }()

    private lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        // Convert camelCase from Swift models to snake_case for backend
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    // MARK: - Request Building

    private func buildRequest(
        endpoint: String,
        method: HTTPMethod,
        body: Data? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add demo mode headers for auth bypass
        if isDemoMode {
            request.setValue("true", forHTTPHeaderField: "X-Dev-Mode")
            // Add member ID for demo mode (alithia@aboundfi.com)
            request.setValue("000000000000000000000005", forHTTPHeaderField: "X-Member-Id")
            // Use hardcoded church ID for demo mode
            request.setValue("000000000000000000000003", forHTTPHeaderField: "X-Church-Id")
        } else {
            // Production mode: use stored church ID from Keychain
            if let churchId = KeychainService.shared.churchId {
                request.setValue(churchId, forHTTPHeaderField: "X-Church-Id")
            }

            // Add auth token if available
            if let token = authToken ?? KeychainService.shared.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        // Add body if provided
        if let body = body {
            request.httpBody = body
        }

        return request
    }

    // MARK: - Request Execution

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        print("🌐 API Request: \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("🌐 Request Body: \(bodyString)")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.requestFailed(statusCode: 0)
            }

            print("🌐 Response Status: \(httpResponse.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🌐 Response Body: \(jsonString.prefix(500))")
            }

            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success - decode response
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    print("❌ Decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Response JSON: \(jsonString)")
                    }
                    throw APIError.decodingFailed(error)
                }
            case 401:
                // Post notification for unauthorized - triggers logout
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .apiUnauthorized, object: nil)
                }
                throw APIError.unauthorized
            case 404:
                throw APIError.notFound
            case 500...599:
                throw APIError.serverError
            default:
                throw APIError.requestFailed(statusCode: httpResponse.statusCode)
            }
        } catch let error as APIError {
            print("❌ API Error: \(error)")
            throw error
        } catch {
            print("❌ Network Error: \(error)")
            throw APIError.networkError(error)
        }
    }

    // MARK: - Public Methods

    /// Perform a GET request
    func get<T: Decodable>(_ endpoint: String) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, method: .get)
        return try await execute(request)
    }

    /// Perform a POST request with a body
    func post<T: Decodable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        let bodyData = try encoder.encode(body)
        let request = try buildRequest(endpoint: endpoint, method: .post, body: bodyData)
        return try await execute(request)
    }

    /// Perform a POST request without a body
    func post<T: Decodable>(_ endpoint: String) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, method: .post)
        return try await execute(request)
    }

    /// Perform a PATCH request with a body
    func patch<T: Decodable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        let bodyData = try encoder.encode(body)
        let request = try buildRequest(endpoint: endpoint, method: .patch, body: bodyData)
        return try await execute(request)
    }

    /// Perform a DELETE request
    func delete<T: Decodable>(_ endpoint: String) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, method: .delete)
        return try await execute(request)
    }

    /// Perform a DELETE request with no response body
    func delete(_ endpoint: String) async throws {
        let request = try buildRequest(endpoint: endpoint, method: .delete)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(statusCode: 0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }

    /// Perform a POST request with body, no response expected
    func postVoid<B: Encodable>(_ endpoint: String, body: B) async throws {
        let bodyData = try encoder.encode(body)
        let request = try buildRequest(endpoint: endpoint, method: .post, body: bodyData)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(statusCode: 0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }
}
