//
//  ScaleButtonStyle.swift
//  ChurchTalkAdmin
//
//  Button style with scale animation for tap feedback
//

import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Extension for easy use
extension View {
    func scaleButton() -> some View {
        self.buttonStyle(ScaleButtonStyle())
    }
}
