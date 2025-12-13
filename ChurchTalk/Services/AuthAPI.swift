//
//  AuthAPI.swift
//  ChurchTalk
//
//  API service for authentication endpoints.
//

import Foundation

// MARK: - Response Types

/// Response from signup endpoint
struct SignupResponse: Codable {
    let userSub: String
    let email: String
    let requiresVerification: Bool
}

/// Response from email verification endpoint
struct VerifyEmailResponse: Codable {
    let verified: Bool
    let userId: String
    let nextStep: String
}

/// Response from login endpoint
struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let idToken: String
    let expiresIn: Int
    let tokenType: String
    let user: UserResponse
    let member: Member?
}

/// User data returned from login
struct UserResponse: Codable {
    let id: String
    let email: String
    let name: String
    let isEmailVerified: Bool
    let profileUrl: String?
}

/// Response from token refresh endpoint
struct RefreshTokenResponse: Codable {
    let accessToken: String
    let idToken: String
    let expiresIn: Int
    let tokenType: String
}

/// Response from /me endpoint
struct CurrentUserResponse: Codable {
    let id: String
    let email: String
    let name: String
    let isEmailVerified: Bool
    let profileUrl: String?
    let createdAt: Date?
}

// MARK: - Request Types

/// Request body for signup
struct SignupRequest: Codable {
    let email: String
    let password: String
    let name: String
}

/// Request body for email verification
struct VerifyEmailRequest: Codable {
    let email: String
    let code: String
}

/// Request body for login
struct LoginRequest: Codable {
    let email: String
    let password: String
}

/// Request body for token refresh
struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

/// Request body for forgot password
struct ForgotPasswordRequest: Codable {
    let email: String
}

/// Request body for password reset
struct ResetPasswordRequest: Codable {
    let email: String
    let code: String
    let newPassword: String
}

/// Request body for resend verification code
struct ResendCodeRequest: Codable {
    let email: String
}

// MARK: - AuthAPI

/// API service for authentication operations
class AuthAPI {

    // MARK: - Singleton

    static let shared = AuthAPI()

    // MARK: - Dependencies

    private let client = APIClient.shared

    // MARK: - Init

    private init() {}

    // MARK: - Signup

    /// Register a new user
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password (min 8 characters)
    ///   - name: User full name
    /// - Returns: Signup response with user_sub and verification status
    func signup(email: String, password: String, name: String) async throws -> SignupResponse {
        let request = SignupRequest(email: email, password: password, name: name)
        return try await client.post("/auth/signup", body: request)
    }

    // MARK: - Email Verification

    /// Verify email with 6-digit code
    /// - Parameters:
    ///   - email: User email
    ///   - code: 6-digit verification code
    /// - Returns: Verification response with next step
    func verifyEmail(email: String, code: String) async throws -> VerifyEmailResponse {
        let request = VerifyEmailRequest(email: email, code: code)
        return try await client.post("/auth/verify-email", body: request)
    }

    /// Resend verification code
    /// - Parameter email: User email
    /// - Returns: Message response
    func resendCode(email: String) async throws -> MessageResponse {
        let request = ResendCodeRequest(email: email)
        return try await client.post("/auth/resend-code", body: request)
    }

    // MARK: - Login

    /// Login with email and password
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    /// - Returns: Login response with tokens, user, and member info
    func login(email: String, password: String) async throws -> LoginResponse {
        let request = LoginRequest(email: email, password: password)
        return try await client.post("/auth/login", body: request)
    }

    // MARK: - Token Refresh

    /// Refresh access token using refresh token
    /// - Parameter refreshToken: Current refresh token
    /// - Returns: New token set
    func refreshToken(refreshToken: String) async throws -> RefreshTokenResponse {
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        return try await client.post("/auth/refresh", body: request)
    }

    // MARK: - Password Reset

    /// Request password reset (sends code to email)
    /// - Parameter email: User email
    /// - Returns: Message response
    func forgotPassword(email: String) async throws -> MessageResponse {
        let request = ForgotPasswordRequest(email: email)
        return try await client.post("/auth/forgot-password", body: request)
    }

    /// Reset password with verification code
    /// - Parameters:
    ///   - email: User email
    ///   - code: 6-digit reset code
    ///   - newPassword: New password
    /// - Returns: Message response
    func resetPassword(email: String, code: String, newPassword: String) async throws -> MessageResponse {
        let request = ResetPasswordRequest(email: email, code: code, newPassword: newPassword)
        return try await client.post("/auth/reset-password", body: request)
    }

    // MARK: - Current User

    /// Get current authenticated user info
    /// - Returns: Current user response
    func getCurrentUser() async throws -> CurrentUserResponse {
        return try await client.get("/auth/me")
    }
}
