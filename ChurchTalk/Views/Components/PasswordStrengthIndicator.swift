//
//  PasswordStrengthIndicator.swift
//  ChurchTalkAdmin
//
//  Password strength visual indicator
//

import SwiftUI

struct PasswordStrengthIndicator: View {
    let password: String

    private var strength: PasswordStrength {
        if password.isEmpty {
            return .none
        } else if password.count < 8 {
            return .weak
        } else if password.rangeOfCharacter(from: .uppercaseLetters) != nil &&
                    password.rangeOfCharacter(from: .decimalDigits) != nil &&
                    password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:',.<>?")) != nil {
            return .strong
        } else {
            return .medium
        }
    }

    var body: some View {
        if !password.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Rectangle()
                            .fill(index < strength.rawValue ? strength.color : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }

                Text(strength.message)
                    .font(.caption)
                    .foregroundColor(strength.color)
            }
            .padding(.top, 4)
        }
    }
}

enum PasswordStrength: Int {
    case none = 0
    case weak = 1
    case medium = 2
    case strong = 3

    var color: Color {
        switch self {
        case .none: return .clear
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }

    var message: String {
        switch self {
        case .none: return ""
        case .weak: return "Weak password"
        case .medium: return "Medium password"
        case .strong: return "Strong password"
        }
    }
}
