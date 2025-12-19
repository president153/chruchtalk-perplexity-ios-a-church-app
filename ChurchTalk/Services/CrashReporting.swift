//
//  CrashReporting.swift
//  ChurchTalk
//
//  Crash reporting service wrapper for Firebase Crashlytics.
//
//  SETUP INSTRUCTIONS:
//  1. Add Firebase SDK via Swift Package Manager:
//     - File > Add Package Dependencies
//     - Enter: https://github.com/firebase/firebase-ios-sdk
//     - Select FirebaseCrashlytics package
//
//  2. Download GoogleService-Info.plist from Firebase Console:
//     - Go to Firebase Console > Project Settings > iOS app
//     - Download and add to project
//
//  3. Uncomment Firebase imports and code below
//

import Foundation
// import FirebaseCore
// import FirebaseCrashlytics

/// Crash reporting service for production error tracking.
/// Wraps Firebase Crashlytics with app-specific configuration.
final class CrashReporting {

    // MARK: - Singleton

    static let shared = CrashReporting()

    private init() {}

    // MARK: - Configuration

    /// Initialize crash reporting. Call this in App init or AppDelegate.
    func configure() {
        #if !DEBUG
        // Uncomment when Firebase is added:
        // FirebaseApp.configure()
        // Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        print("[CrashReporting] Configured for production")
        #else
        print("[CrashReporting] Disabled in DEBUG mode")
        #endif
    }

    // MARK: - User Identification

    /// Set user identifier for crash reports.
    /// - Parameter userId: The user's unique identifier
    func setUserId(_ userId: String?) {
        #if !DEBUG
        // Uncomment when Firebase is added:
        // if let userId = userId {
        //     Crashlytics.crashlytics().setUserID(userId)
        // }
        #endif
    }

    /// Set custom key-value for crash context.
    func setCustomValue(_ value: Any, forKey key: String) {
        #if !DEBUG
        // Uncomment when Firebase is added:
        // Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        #endif
    }

    // MARK: - Error Logging

    /// Record a non-fatal error.
    /// - Parameters:
    ///   - error: The error to record
    ///   - context: Optional additional context
    func recordError(_ error: Error, context: [String: Any]? = nil) {
        #if !DEBUG
        // Uncomment when Firebase is added:
        // var userInfo = (error as NSError).userInfo
        // if let context = context {
        //     for (key, value) in context {
        //         userInfo[key] = value
        //     }
        // }
        // let nsError = NSError(
        //     domain: (error as NSError).domain,
        //     code: (error as NSError).code,
        //     userInfo: userInfo
        // )
        // Crashlytics.crashlytics().record(error: nsError)
        print("[CrashReporting] Error recorded: \(error.localizedDescription)")
        #endif
    }

    /// Log a message to crash reports.
    /// - Parameter message: The message to log
    func log(_ message: String) {
        #if !DEBUG
        // Uncomment when Firebase is added:
        // Crashlytics.crashlytics().log(message)
        print("[CrashReporting] Log: \(message)")
        #endif
    }

    // MARK: - Church Context

    /// Set church context for crash reports.
    func setChurchContext(churchId: String?, churchName: String?) {
        setCustomValue(churchId ?? "none", forKey: "church_id")
        setCustomValue(churchName ?? "unknown", forKey: "church_name")
    }

    /// Set member role context.
    func setMemberRole(_ role: String?) {
        setCustomValue(role ?? "unknown", forKey: "member_role")
    }
}

// MARK: - APIError Extension

extension APIError {
    /// Record this API error to crash reporting.
    func recordToCrashlytics(endpoint: String? = nil) {
        var context: [String: Any] = [:]
        if let endpoint = endpoint {
            context["endpoint"] = endpoint
        }

        switch self {
        case .requestFailed(let statusCode):
            context["status_code"] = statusCode
        case .decodingFailed(let error):
            context["decoding_error"] = error.localizedDescription
        case .networkError(let error):
            context["network_error"] = error.localizedDescription
        default:
            break
        }

        CrashReporting.shared.recordError(self, context: context)
    }
}
