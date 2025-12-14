//
//  ChurchTalkApp.swift
//  ChurchTalk
//
//  Main app entry point with splash screen and auth state routing
//

import SwiftUI
import UserNotifications

@main
struct ChurchTalkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var notificationService = NotificationService.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView()
                        .onAppear {
                            // Show splash for 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showSplash = false
                                }
                            }
                        }
                } else if authViewModel.isAuthenticated {
                    if authViewModel.isPendingApproval {
                        // User is waiting for church approval
                        NavigationStack {
                            PendingApprovalView()
                                .environmentObject(authViewModel)
                        }
                    } else {
                        // Fully authenticated - show main app
                        MainTabView()
                            .environmentObject(authViewModel)
                            .task {
                                // Request notification permission after login
                                await requestNotificationPermission()
                            }
                    }
                } else {
                    // Not authenticated - show onboarding
                    OnboardingView()
                        .environmentObject(authViewModel)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
            .animation(.easeInOut(duration: 0.3), value: authViewModel.isPendingApproval)
        }
    }

    private func requestNotificationPermission() async {
        let granted = await notificationService.requestPermission()
        if granted {
            // Register for remote notifications on main thread
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}
