//
//  TokenManager.swift
//  ChurchTalk
//
//  Manages JWT token lifecycle including storage, validation, and refresh.
//

import Foundation

/// Manages authentication tokens and automatic refresh.
final class TokenManager {

    // MARK: - Singleton

    static let shared = TokenManager()

    // MARK: - Properties

    private let keychainService = KeychainService.shared
    private var refreshTask: Task<Void, Never>?
    private var tokenExpirationDate: Date?

    /// Buffer time before expiration to trigger refresh (5 minutes)
    private let refreshBuffer: TimeInterval = 300

    // MARK: - Init

    private init() {}

    // MARK: - Token Expiration Tracking

    /// Set token expiration based on expiresIn value from login response.
    func setTokenExpiration(expiresIn: Int) {
        tokenExpirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        scheduleTokenRefresh()
    }

    /// Check if the current token is expired or about to expire.
    var isTokenExpiredOrExpiring: Bool {
        guard let expirationDate = tokenExpirationDate else {
            // No expiration date set, assume token is valid
            return false
        }
        // Token is expiring if we're within the refresh buffer
        return Date() >= expirationDate.addingTimeInterval(-refreshBuffer)
    }

    /// Check if token is completely expired.
    var isTokenExpired: Bool {
        guard let expirationDate = tokenExpirationDate else { return false }
        return Date() >= expirationDate
    }

    // MARK: - Token Refresh

    /// Schedule automatic token refresh before expiration.
    private func scheduleTokenRefresh() {
        // Cancel any existing refresh task
        refreshTask?.cancel()

        guard let expirationDate = tokenExpirationDate else { return }

        // Calculate delay until we should refresh (expiration - buffer)
        let refreshDate = expirationDate.addingTimeInterval(-refreshBuffer)
        let delay = refreshDate.timeIntervalSinceNow

        // Only schedule if the refresh time is in the future
        guard delay > 0 else {
            // Already time to refresh
            Task { await refreshTokenIfNeeded() }
            return
        }

        refreshTask = Task { [weak self] in
            // Wait until refresh time
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            guard !Task.isCancelled else { return }

            await self?.refreshTokenIfNeeded()
        }
    }

    /// Refresh the access token using the stored refresh token.
    @discardableResult
    func refreshTokenIfNeeded() async -> Bool {
        guard let refreshToken = keychainService.refreshToken else {
            print("[TokenManager] No refresh token available")
            return false
        }

        do {
            let response = try await AuthAPI.shared.refreshToken(refreshToken: refreshToken)

            // Update stored tokens
            keychainService.accessToken = response.accessToken
            keychainService.idToken = response.idToken

            // Update API client token
            APIClient.shared.authToken = response.accessToken

            // Update expiration and schedule next refresh
            setTokenExpiration(expiresIn: response.expiresIn)

            print("[TokenManager] Token refreshed successfully")
            return true
        } catch {
            print("[TokenManager] Token refresh failed: \(error)")
            // Record to crash reporting
            CrashReporting.shared.recordError(error, context: ["action": "token_refresh"])
            return false
        }
    }

    /// Ensure we have a valid token before making an API request.
    /// Returns true if we have a valid token, false if user needs to re-login.
    func ensureValidToken() async -> Bool {
        // If token isn't expiring, we're good
        if !isTokenExpiredOrExpiring {
            return true
        }

        // Token is expired or expiring, try to refresh
        return await refreshTokenIfNeeded()
    }

    // MARK: - Cleanup

    /// Clear token state when user logs out.
    func clearTokenState() {
        refreshTask?.cancel()
        refreshTask = nil
        tokenExpirationDate = nil
    }
}

// MARK: - APIClient Extension

extension APIClient {
    /// Execute a request with automatic token refresh if needed.
    func withTokenRefresh<T>(_ operation: () async throws -> T) async throws -> T {
        // Ensure valid token before request
        let tokenValid = await TokenManager.shared.ensureValidToken()

        if !tokenValid {
            // Couldn't refresh token, throw unauthorized
            throw APIError.unauthorized
        }

        // Execute the operation
        return try await operation()
    }
}
