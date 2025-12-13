//
//  HapticManager.swift
//  ChurchTalkAdmin
//
//  Centralized haptic feedback manager for consistent tactile responses
//

import SwiftUI

/// Centralized manager for haptic feedback throughout the app
class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Impact Haptics

    /// Light impact - for subtle interactions like toggle switches
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact - for standard button taps
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact - for important actions
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Soft impact - for gentle interactions (iOS 13+)
    func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    /// Rigid impact - for firm interactions (iOS 13+)
    func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }

    // MARK: - Notification Haptics

    /// Success notification - for successful operations
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning notification - for warnings or caution
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error notification - for errors or failures
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Haptics

    /// Selection changed - for picker changes, segmented control, etc.
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Common Use Cases (Convenience Methods)

    /// Haptic for button tap
    func buttonTap() {
        medium()
    }

    /// Haptic for tab switch
    func tabSwitch() {
        light()
    }

    /// Haptic for navigation
    func navigate() {
        soft()
    }

    /// Haptic for sheet presentation
    func sheetPresent() {
        light()
    }

    /// Haptic for sheet dismissal
    func sheetDismiss() {
        light()
    }

    /// Haptic for toggle action
    func toggle() {
        light()
    }

    /// Haptic for delete action
    func delete() {
        rigid()
    }

    /// Haptic for pull to refresh
    func refresh() {
        soft()
    }

    /// Haptic for form submission
    func submit() {
        medium()
    }

    /// Haptic for menu open
    func menuOpen() {
        light()
    }
}

// MARK: - View Extension for Convenient Haptic Access

extension View {
    /// Trigger haptic feedback from any view
    func haptic(_ type: HapticType) -> some View {
        self.onTapGesture {
            HapticManager.shared.trigger(type)
        }
    }
}

// MARK: - Haptic Type Enum

enum HapticType {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case success
    case warning
    case error
    case selection
    case buttonTap
    case tabSwitch
    case navigate
    case sheetPresent
    case sheetDismiss
    case toggle
    case delete
    case refresh
    case submit
    case menuOpen
}

extension HapticManager {
    /// Trigger haptic based on type
    func trigger(_ type: HapticType) {
        switch type {
        case .light: light()
        case .medium: medium()
        case .heavy: heavy()
        case .soft: soft()
        case .rigid: rigid()
        case .success: success()
        case .warning: warning()
        case .error: error()
        case .selection: selection()
        case .buttonTap: buttonTap()
        case .tabSwitch: tabSwitch()
        case .navigate: navigate()
        case .sheetPresent: sheetPresent()
        case .sheetDismiss: sheetDismiss()
        case .toggle: toggle()
        case .delete: delete()
        case .refresh: refresh()
        case .submit: submit()
        case .menuOpen: menuOpen()
        }
    }
}
