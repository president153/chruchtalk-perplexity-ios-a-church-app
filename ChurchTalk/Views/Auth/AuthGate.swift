//
//  AuthGate.swift
//  ChurchTalk
//
//  Root view that handles authentication state routing.
//  Shows appropriate views based on user's auth state:
//  - SplashView: Initial loading state
//  - OnboardingView: Not authenticated
//  - EmailVerificationView: Needs email verification
//  - PendingApprovalView: Waiting for church approval
//  - MainTabView: Fully authenticated
//

import SwiftUI

struct AuthGate: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSplash = true
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .onAppear {
                        startSessionCheck()
                    }
            } else {
                contentView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isEmailVerified)
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isPendingApproval)
    }

    // MARK: - Content View Based on Auth State

    @ViewBuilder
    private var contentView: some View {
        if !authViewModel.isAuthenticated {
            // Not authenticated - show onboarding/login
            OnboardingView()
                .environmentObject(authViewModel)
                .transition(.opacity)
        } else if !authViewModel.isEmailVerified {
            // Authenticated but email not verified
            NavigationStack {
                EmailVerificationView(email: authViewModel.user?.email ?? "")
                    .environmentObject(authViewModel)
            }
            .transition(.opacity)
        } else if authViewModel.isPendingApproval {
            // Email verified but waiting for church approval
            NavigationStack {
                PendingApprovalView()
                    .environmentObject(authViewModel)
            }
            .transition(.opacity)
        } else if authViewModel.currentChurch == nil {
            // Authenticated but no church selected
            NavigationStack {
                ChurchSelectionView()
                    .environmentObject(authViewModel)
            }
            .transition(.opacity)
        } else {
            // Fully authenticated with church - show main app
            MainTabView()
                .environmentObject(authViewModel)
                .transition(.opacity)
        }
    }

    // MARK: - Session Check

    private func startSessionCheck() {
        // Show splash for minimum 1.5 seconds while checking session
        let splashDuration = 1.5

        Task {
            // Session restoration happens in AuthViewModel.init()
            // Wait for it to complete
            try? await Task.sleep(nanoseconds: UInt64(splashDuration * 1_000_000_000))

            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Church Selection View

/// View for selecting a church when user is authenticated but hasn't joined one
struct ChurchSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showContent = false
    @State private var showChurchSearch = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "building.columns.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.churchTalkRed)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.5)

            // Content
            VStack(spacing: 16) {
                Text("Find Your Church")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)

                Text("You're signed in! Now let's connect you with your church community.")
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(showContent ? 1 : 0)

            Spacer()

            // Actions
            VStack(spacing: 16) {
                Button(action: {
                    HapticManager.shared.medium()
                    showChurchSearch = true
                }) {
                    Text("Search for Churches")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.churchTalkRed)
                        .cornerRadius(12)
                }

                Button(action: {
                    HapticManager.shared.medium()
                    authViewModel.logout()
                }) {
                    Text("Sign Out")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
            .opacity(showContent ? 1 : 0)
        }
        .background(Color.background)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .navigationDestination(isPresented: $showChurchSearch) {
            ChurchSearchView()
                .environmentObject(authViewModel)
        }
    }
}

// MARK: - Protected View Modifier

/// A view modifier that ensures the user is authenticated before showing content
struct ProtectedViewModifier: ViewModifier {
    @EnvironmentObject var authViewModel: AuthViewModel

    func body(content: Content) -> some View {
        Group {
            if authViewModel.isAuthenticated && authViewModel.isEmailVerified && !authViewModel.isPendingApproval {
                content
            } else {
                // This shouldn't normally be reached if using AuthGate properly
                EmptyView()
            }
        }
    }
}

extension View {
    /// Modifier to ensure view is only shown when user is fully authenticated
    func requiresAuth() -> some View {
        modifier(ProtectedViewModifier())
    }
}

// MARK: - Role-Based Access Modifier

/// A view modifier that checks if user has required role
struct RoleBasedAccessModifier: ViewModifier {
    @EnvironmentObject var authViewModel: AuthViewModel
    let requiredRoles: Set<MemberRole>
    let fallbackView: AnyView?

    init(requiredRoles: Set<MemberRole>, fallback: AnyView? = nil) {
        self.requiredRoles = requiredRoles
        self.fallbackView = fallback
    }

    func body(content: Content) -> some View {
        Group {
            if let member = authViewModel.currentMember,
               let role = member.role,
               requiredRoles.contains(role) {
                content
            } else if let fallback = fallbackView {
                fallback
            } else {
                AccessDeniedView()
            }
        }
    }
}

/// View shown when user doesn't have required role
struct AccessDeniedView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("Access Restricted")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("You don't have permission to view this content.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button("Go Back") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.churchTalkRed)
            .cornerRadius(12)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(Color.background)
    }
}

extension View {
    /// Modifier to ensure view is only shown to users with specific roles
    func requiresRole(_ roles: MemberRole..., fallback: AnyView? = nil) -> some View {
        modifier(RoleBasedAccessModifier(requiredRoles: Set(roles), fallback: fallback))
    }

    /// Modifier for admin-only views
    func adminOnly(fallback: AnyView? = nil) -> some View {
        modifier(RoleBasedAccessModifier(requiredRoles: [.admin, .owner], fallback: fallback))
    }

    /// Modifier for leader and above views
    func leaderOrAbove(fallback: AnyView? = nil) -> some View {
        modifier(RoleBasedAccessModifier(requiredRoles: [.leader, .staff, .admin, .owner], fallback: fallback))
    }
}

#Preview {
    AuthGate()
        .environmentObject(AuthViewModel())
}
