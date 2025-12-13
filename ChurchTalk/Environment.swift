//
//  Environment.swift
//  ChurchTalk
//
//  Environment configuration for different build targets.
//  Controls API URL and demo mode settings per environment.
//

import Foundation

/// App environment configuration
enum AppEnvironment: String {
    case development
    case staging
    case production

    /// API base URL for the environment
    var apiBaseURL: String {
        switch self {
        case .development:
            return "http://localhost:8000/api/v1"
        case .staging:
            return "https://api-staging.churchtalk.app/api/v1"
        case .production:
            return "https://api.churchtalk.app/api/v1"
        }
    }

    /// Whether demo mode (auth bypass) is enabled
    /// Set to false for production when authentication is ready
    var isDemoModeEnabled: Bool {
        switch self {
        case .development:
            return true
        case .staging:
            return true  // Keep enabled for TestFlight testing
        case .production:
            return true  // TODO: Set to false when authentication is ready
        }
    }

    /// Current environment based on build configuration
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
}

/// Global environment configuration
struct Environment {
    /// Current app environment
    static let current = AppEnvironment.current

    /// API base URL - can be overridden via UserDefaults for testing
    static var apiBaseURL: String {
        // Allow override from UserDefaults for testing
        if let override = UserDefaults.standard.string(forKey: "api_base_url_override"),
           !override.isEmpty {
            return override
        }
        return current.apiBaseURL
    }

    /// Whether demo mode is enabled - can be overridden via UserDefaults for testing
    static var isDemoMode: Bool {
        // Allow override from UserDefaults for testing
        if UserDefaults.standard.object(forKey: "demo_mode_override") != nil {
            return UserDefaults.standard.bool(forKey: "demo_mode_override")
        }
        return current.isDemoModeEnabled
    }

    // MARK: - Configuration Methods

    /// Set API URL override (for testing/debugging)
    /// - Parameter url: The URL to use, or nil to reset to default
    static func setAPIBaseURLOverride(_ url: String?) {
        if let url = url {
            UserDefaults.standard.set(url, forKey: "api_base_url_override")
        } else {
            UserDefaults.standard.removeObject(forKey: "api_base_url_override")
        }
    }

    /// Toggle demo mode override (for testing/debugging)
    /// - Parameter enabled: Whether to enable demo mode, or nil to reset to default
    static func setDemoModeOverride(_ enabled: Bool?) {
        if let enabled = enabled {
            UserDefaults.standard.set(enabled, forKey: "demo_mode_override")
        } else {
            UserDefaults.standard.removeObject(forKey: "demo_mode_override")
        }
    }

    /// Reset all overrides to use default environment settings
    static func resetOverrides() {
        UserDefaults.standard.removeObject(forKey: "api_base_url_override")
        UserDefaults.standard.removeObject(forKey: "demo_mode_override")
    }
}
