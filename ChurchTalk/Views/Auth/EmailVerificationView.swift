//
//  EmailVerificationView.swift
//  ChurchTalk
//
//  Email verification screen with 6-digit code input
//

import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var code = ""
    @FocusState private var codeFieldFocused: Bool
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.churchTalkRed)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)

                Text("Verify Your Email")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                    .opacity(showContent ? 1 : 0)

                if let email = viewModel.user?.email {
                    VStack(spacing: 4) {
                        Text("We sent a 6-digit code to")
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)

                        Text(email)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                    }
                    .opacity(showContent ? 1 : 0)
                }
            }
            .padding(.top, 60)

            // Code input
            VStack(spacing: 24) {
                CodeInputField(code: $code, isFocused: $codeFieldFocused)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            codeFieldFocused = true
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // Verify button
                LoadingButton(
                    title: "Verify",
                    isLoading: viewModel.isLoading
                ) {
                    HapticManager.shared.submit()
                    Task {
                        let success = await viewModel.verifyEmail(code: code)
                        if success {
                            HapticManager.shared.success()
                            // Auth state change will trigger app routing
                            // to PendingApprovalView or MainTabView
                        } else {
                            HapticManager.shared.error()
                        }
                    }
                }
                .disabled(code.count != 6)
                .opacity(code.count == 6 ? 1 : 0.6)
                .padding(.horizontal)

                // Resend code
                Button(action: {
                    HapticManager.shared.light()
                    Task {
                        await viewModel.resendVerificationCode()
                    }
                    code = ""
                    codeFieldFocused = true
                }) {
                    Text("Didn't receive the code? Resend")
                        .font(.subheadline)
                        .foregroundColor(.churchTalkRed)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .background(Color.background)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                code = ""
                codeFieldFocused = true
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

#Preview {
    NavigationStack {
        EmailVerificationView()
            .environmentObject(AuthViewModel())
    }
}
