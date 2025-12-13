//
//  KeyboardHelper.swift
//  ChurchTalk
//
//  Keyboard dismissal utility for enhanced UX
//

import SwiftUI

extension View {
    /// Dismisses the keyboard when the user taps anywhere on the view
    /// Usage: Apply .dismissKeyboardOnTap() to any view container
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}
