//
//  ChurchTalkApp.swift
//  ChurchTalk
//
//  Main app entry point with auth gate routing
//

import SwiftUI
import UserNotifications

@main
struct ChurchTalkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var notificationService = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            AuthGate()
                .environmentObject(authViewModel)
                .task {
                    // Request notification permission when app launches
                    if authViewModel.isAuthenticated && !authViewModel.isPendingApproval {
                        await requestNotificationPermission()
                    }
                }
                .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                    if isAuthenticated && !authViewModel.isPendingApproval {
                        Task {
                            await requestNotificationPermission()
                        }
                    }
                }
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
