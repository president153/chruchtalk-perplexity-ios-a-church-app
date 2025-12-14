import Foundation
import SwiftUI

// Notification for dismissing sheets after member join flow completes
extension Notification.Name {
    static let didCompleteMemberJoinFlow = Notification.Name("didCompleteMemberJoinFlow")
}

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Auth State
    @Published var isAuthenticated = true  // Auto-auth for development
    @Published var isEmailVerified = true
    @Published var isPendingApproval = false

    // MARK: - User Data
    @Published var user: User?
    @Published var currentMember: Member?
    @Published var currentChurch: Church?
    @Published var pendingChurchName: String?

    // MARK: - UI State
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var error: String?

    // MARK: - Init

    init() {
        // Auto-login as bernard@aboundfi.com for development
        // Remove this init() block when wiring real auth
        user = User(
            id: "user-bernard-001",
            email: "bernard@aboundfi.com",
            name: "Pastor Bernard",
            isEmailVerified: true
        )

        currentChurch = Church(
            id: "000000000000000000000003",
            name: "Norwalk Baptist Church",
            city: "Norwalk",
            state: "CA",
            memberCount: 150
        )

        currentMember = Member(
            id: "member-bernard-001",
            firstName: "Bernard",
            lastName: "Moses",
            email: "bernard@aboundfi.com",
            phone: nil,
            churchId: "000000000000000000000003",
            role: .admin
        )
    }

    // MARK: - Login

    func login(email: String, password: String) async -> Bool {
        isLoading = true
        showError = false
        errorMessage = nil

        do {
            let response = try await AuthAPI.shared.login(email: email, password: password)

            // Store auth token
            APIClient.shared.authToken = response.accessToken

            // Store tokens for later refresh
            UserDefaults.standard.set(response.refreshToken, forKey: "refreshToken")
            UserDefaults.standard.set(response.accessToken, forKey: "accessToken")

            // Map user response to User model
            user = User(
                id: response.user.id,
                email: response.user.email,
                name: response.user.name,
                isEmailVerified: response.user.isEmailVerified,
                profileUrl: response.user.profileUrl
            )

            // Set member if returned (user already joined a church)
            currentMember = response.member

            // TODO: Fetch church details if member exists
            if let member = response.member {
                // For now, store church ID - will fetch church details later
                UserDefaults.standard.set(member.churchId, forKey: "currentChurchId")
            }

            isAuthenticated = true
            isEmailVerified = response.user.isEmailVerified
            isPendingApproval = response.member?.isPendingApproval ?? false
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to sign in. Please try again."
            showError = true
            isLoading = false
            return false
        } catch {
            errorMessage = "Failed to sign in. Please try again."
            showError = true
            isLoading = false
            return false
        }
    }

    // MARK: - Sign In (Alias for login)

    func signIn(email: String, password: String) async {
        _ = await login(email: email, password: password)
    }

    // MARK: - Signup

    /// Store email for use during verification
    private var pendingVerificationEmail: String?

    func signup(name: String, email: String, password: String) async -> Bool {
        isLoading = true
        showError = false
        errorMessage = nil

        do {
            let response = try await AuthAPI.shared.signup(email: email, password: password, name: name)

            // Store email for verification step
            pendingVerificationEmail = email

            // Create temporary user (not authenticated until verified)
            user = User(
                id: response.userSub,
                email: response.email,
                name: name,
                isEmailVerified: false
            )

            isLoading = false
            return response.requiresVerification
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to create account. Please try again."
            showError = true
            isLoading = false
            return false
        } catch {
            errorMessage = "Failed to create account. Please try again."
            showError = true
            isLoading = false
            return false
        }
    }

    // MARK: - Email Verification

    func verifyEmail(code: String) async -> Bool {
        isLoading = true
        showError = false
        errorMessage = nil

        guard let email = pendingVerificationEmail ?? user?.email else {
            errorMessage = "No email to verify. Please sign up again."
            showError = true
            isLoading = false
            return false
        }

        do {
            let response = try await AuthAPI.shared.verifyEmail(email: email, code: code)

            if response.verified {
                user?.isEmailVerified = true
                isEmailVerified = true

                // If user signed up through church join flow, complete the process
                if let pending = pendingMember, let church = currentChurch {
                    currentMember = Member(
                        id: UUID().uuidString,
                        firstName: pending.firstName,
                        lastName: pending.lastName,
                        email: pending.email,
                        phone: pending.phone,
                        churchId: church.id
                    )
                    isPendingApproval = true
                    pendingMember = nil

                    // Notify views to dismiss sheets so PendingApprovalView shows
                    NotificationCenter.default.post(name: .didCompleteMemberJoinFlow, object: nil)
                }

                isAuthenticated = true
                pendingVerificationEmail = nil
                isLoading = false
                return true
            } else {
                errorMessage = "Verification failed"
                showError = true
                isLoading = false
                return false
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Verification failed. Please try again."
            showError = true
            isLoading = false
            return false
        } catch {
            errorMessage = "Verification failed. Please try again."
            showError = true
            isLoading = false
            return false
        }
    }

    func resendVerificationCode() async -> Bool {
        isLoading = true

        guard let email = pendingVerificationEmail ?? user?.email else {
            isLoading = false
            return false
        }

        do {
            _ = try await AuthAPI.shared.resendCode(email: email)
            isLoading = false
            return true
        } catch {
            isLoading = false
            return false
        }
    }

    // MARK: - Join Church

    // Stores pending member info for after email verification
    @Published var pendingMember: (firstName: String, lastName: String, email: String, phone: String?)?

    func joinChurch(church: Church, firstName: String, lastName: String, email: String, phone: String?) async -> Bool {
        isLoading = true
        error = nil

        do {
            try await Task.sleep(nanoseconds: 1_500_000_000)

            // Create user account (not authenticated until email verified)
            user = User(
                id: UUID().uuidString,
                email: email,
                name: "\(firstName) \(lastName)",
                isEmailVerified: false
            )

            // Store church and member info for after verification
            currentChurch = church
            pendingChurchName = church.name
            pendingMember = (firstName, lastName, email, phone)
            UserDefaults.standard.set(church.name, forKey: "currentChurchName")

            // NOT authenticated yet - needs email verification first
            isLoading = false
            return true
        } catch {
            self.error = "Failed to join church. Please try again."
            isLoading = false
            return false
        }
    }

    // MARK: - Logout

    func logout() {
        isAuthenticated = false
        isEmailVerified = false
        isPendingApproval = false
        user = nil
        currentMember = nil
        currentChurch = nil
        pendingChurchName = nil
        pendingMember = nil
        pendingVerificationEmail = nil

        // Clear stored tokens
        APIClient.shared.authToken = nil
        UserDefaults.standard.removeObject(forKey: "currentChurchName")
        UserDefaults.standard.removeObject(forKey: "currentChurchId")
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
    }

    func signOut() {
        logout()
    }

    // MARK: - Mock: Approve Join Request (for testing)

    func approveJoinRequest() {
        isPendingApproval = false
    }

    // MARK: - Profile Completion

    @Published var isProfileCompleted = false

    func updateMemberProfile(
        bio: String?,
        dateOfBirth: Date?,
        address: Address?,
        spiritualJourney: SpiritualJourney?
    ) {
        guard var member = currentMember else { return }

        // Update member fields
        member.dateOfBirth = dateOfBirth
        member.address = address
        member.spiritualJourney = spiritualJourney

        // Store bio in UserDefaults for now (would be part of Member model in production)
        if let bio = bio {
            UserDefaults.standard.set(bio, forKey: "memberBio")
        }

        currentMember = member
        isProfileCompleted = true

        // Persist profile completion status
        UserDefaults.standard.set(true, forKey: "isProfileCompleted")
    }

    func loadProfileCompletionStatus() {
        isProfileCompleted = UserDefaults.standard.bool(forKey: "isProfileCompleted")
    }
}
