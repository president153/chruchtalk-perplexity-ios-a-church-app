import Foundation
import SwiftUI

// Notification for dismissing sheets after member join flow completes
extension Notification.Name {
    static let didCompleteMemberJoinFlow = Notification.Name("didCompleteMemberJoinFlow")
}

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Auth State
    @Published var isAuthenticated = false  // Start unauthenticated, restore from Keychain
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
        // Check for saved auth token and restore session
        Task {
            await restoreSession()
        }

        // Listen for unauthorized API responses to trigger logout
        NotificationCenter.default.addObserver(
            forName: .apiUnauthorized,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleUnauthorized()
        }
    }

    // MARK: - Handle Unauthorized

    private func handleUnauthorized() {
        // Only logout if we think we're authenticated
        // This prevents logout loops
        if isAuthenticated {
            print("⚠️ API returned 401 - logging out")
            logout()
        }
    }

    // MARK: - Restore Session

    /// Restore auth session from saved tokens on app launch
    func restoreSession() async {
        // In demo mode, auto-authenticate using the dev mode headers
        if AppConfig.isDemoMode {
            do {
                // Fetch current member data (uses X-Dev-Mode and X-Member-Id headers)
                let member = try await MembersAPI.shared.getCurrentMember()

                // Fetch church data
                var church: Church?
                if let churchId = member.churchId {
                    church = try? await ChurchAPI.shared.getChurch(id: churchId)
                }

                await MainActor.run {
                    self.currentMember = member
                    self.currentChurch = church
                    self.isAuthenticated = true
                    self.isEmailVerified = true
                    self.isPendingApproval = member.isPendingApproval ?? false

                    // Create user from member data
                    self.user = User(
                        id: member.userId ?? member.id,
                        email: member.email,
                        name: member.fullName,
                        isEmailVerified: true,
                        profileUrl: member.profilePhotoUrl
                    )
                }
                return
            } catch {
                print("Demo mode fetch failed: \(error)")
            }
        }

        // Non-demo mode: check for saved token in Keychain
        guard let savedToken = KeychainService.shared.accessToken else {
            // No saved token - user needs to log in
            await MainActor.run {
                isAuthenticated = false
            }
            return
        }

        // Set token to API client
        APIClient.shared.authToken = savedToken

        do {
            // Fetch current member data
            let member = try await MembersAPI.shared.getCurrentMember()

            // Fetch church data if member has a church
            var church: Church?
            if let churchId = member.churchId {
                church = try? await ChurchAPI.shared.getChurch(id: churchId)
            }

            await MainActor.run {
                self.currentMember = member
                self.currentChurch = church
                self.isAuthenticated = true
                self.isEmailVerified = true
                self.isPendingApproval = member.isPendingApproval ?? false

                // Create user from member data
                self.user = User(
                    id: member.userId ?? member.id,
                    email: member.email,
                    name: member.fullName,
                    isEmailVerified: true,
                    profileUrl: member.profilePhotoUrl
                )
            }
        } catch {
            // Token invalid or expired - clear and require login
            print("Failed to restore session: \(error)")
            await MainActor.run {
                logout()
            }
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async -> Bool {
        isLoading = true
        showError = false
        errorMessage = nil

        // Clear any stale auth tokens before login attempt
        // This prevents sending invalid tokens with the login request
        APIClient.shared.authToken = nil
        KeychainService.shared.accessToken = nil

        do {
            let response = try await AuthAPI.shared.login(email: email, password: password)

            // Store auth token
            APIClient.shared.authToken = response.accessToken

            // Store tokens securely in Keychain for later refresh
            KeychainService.shared.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                idToken: response.idToken
            )

            // Set token expiration for automatic refresh
            TokenManager.shared.setTokenExpiration(expiresIn: response.expiresIn)

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

            // Fetch church details if member exists
            if let member = response.member, let churchId = member.churchId {
                KeychainService.shared.churchId = churchId
                // Fetch church data
                if let church = try? await ChurchAPI.shared.getChurch(id: churchId) {
                    currentChurch = church
                }
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

        // Clear token manager state
        TokenManager.shared.clearTokenState()

        // Clear stored tokens from Keychain
        APIClient.shared.authToken = nil
        KeychainService.shared.clearAll()

        // Clear other UserDefaults
        UserDefaults.standard.removeObject(forKey: "currentChurchName")
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
