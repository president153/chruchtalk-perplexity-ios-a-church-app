//
//  CodeInputField.swift
//  ChurchTalkAdmin
//
//  6-digit verification code input field
//

import SwiftUI

struct CodeInputField: View {
    @Binding var code: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        ZStack {
            // Hidden text field for actual input
            TextField("", text: $code)
                .keyboardType(.numbersAndPunctuation)
                .textContentType(.oneTimeCode)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .focused($isFocused)
                .onChange(of: code) { newValue in
                    // Filter to only allow digits and limit to 6
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count > 6 {
                        code = String(filtered.prefix(6))
                    } else {
                        code = filtered
                    }
                }

            // Visual representation
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(code.count == index && isFocused ? Color.churchPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 48, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )

                        if index < code.count {
                            Text(String(code[code.index(code.startIndex, offsetBy: index)]))
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .onTapGesture {
            isFocused = true
        }
    }
}
