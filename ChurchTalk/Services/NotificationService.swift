//
//  NotificationService.swift
//  ChurchTalk
//
//  Handles push notification registration and device token management.
//

import Foundation
import UIKit
import UserNotifications

/// Request model for device registration
struct DeviceRegisterRequest: Encodable {
    let deviceToken: String
    let platform: String
    let appVersion: String?
    let osVersion: String?

    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case platform
        case appVersion = "app_version"
        case osVersion = "os_version"
    }
}

/// Response model for device registration
/// Note: APIClient uses .convertFromSnakeCase so property names match JSON automatically
struct DeviceResponse: Decodable {
    let id: String
    let userId: String
    let churchId: String
    let deviceToken: String
    let platform: String
    let isActive: Bool

    // Only _id needs explicit mapping since it starts with underscore
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case churchId
        case deviceToken
        case platform
        case isActive
    }
}

/// Service for managing push notifications and device token registration.
class NotificationService: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - Properties

    @Published var isPermissionGranted = false
    @Published var deviceToken: String?

    private let client = APIClient.shared

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Permission Request

    /// Request notification permission from the user
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isPermissionGranted = granted
            }
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    /// Check current notification permission status
    func checkPermissionStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        await MainActor.run {
            self.isPermissionGranted = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Device Token Management

    /// Register device token with the backend
    func registerDeviceToken(_ tokenData: Data) async {
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()

        await MainActor.run {
            self.deviceToken = tokenString
        }

        // Get app and OS version info
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let osVersion = await MainActor.run { UIDevice.current.systemVersion }

        let request = DeviceRegisterRequest(
            deviceToken: tokenString,
            platform: "ios",
            appVersion: appVersion,
            osVersion: osVersion
        )

        do {
            let _: DeviceResponse = try await client.post("/devices/register", body: request)
            print("Successfully registered device token")
        } catch {
            print("Failed to register device token: \(error)")
        }
    }

    /// Unregister the current device token
    func unregisterDeviceToken() async {
        guard let token = deviceToken else { return }

        do {
            try await client.delete("/devices/\(token)")
            print("Successfully unregistered device token")
            await MainActor.run {
                self.deviceToken = nil
            }
        } catch {
            print("Failed to unregister device token: \(error)")
        }
    }

    /// Send heartbeat to update last_used timestamp
    func sendHeartbeat() async {
        guard let token = deviceToken else { return }

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let osVersion = await MainActor.run { UIDevice.current.systemVersion }

        let request = DeviceRegisterRequest(
            deviceToken: token,
            platform: "ios",
            appVersion: appVersion,
            osVersion: osVersion
        )

        do {
            try await client.postVoid("/devices/heartbeat", body: request)
        } catch {
            print("Failed to send heartbeat: \(error)")
        }
    }

    // MARK: - Notification Handling

    /// Handle a received notification
    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        // Extract notification data
        if let type = userInfo["type"] as? String {
            switch type {
            case "new_post":
                if let postId = userInfo["post_id"] as? String {
                    print("Received new post notification: \(postId)")
                    // Post notification for UI to handle navigation
                    NotificationCenter.default.post(
                        name: .newPostReceived,
                        object: nil,
                        userInfo: ["postId": postId]
                    )
                }
            default:
                print("Received notification of type: \(type)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {

    /// Handle notification received while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo)
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newPostReceived = Notification.Name("newPostReceived")
}
