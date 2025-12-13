//
//  LoginView.swift
//  ChurchTalk
//
//  Login screen for member authentication
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var initialEmail: String? = nil

    @State private var email = ""
    @State private var password = ""
    @State private var showContent = false
    @State private var showChurchSearch = false

    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@") && !password.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo
                Image(systemName: "cross.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.churchTalkRed)
                    .padding(.top, 60)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -20)

                // Header
                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)

                    Text("Sign in to your church community")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
                .padding(.top, 8)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : -10)

                // Form
                VStack(spacing: 16) {
                    CustomTextField(
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        icon: "envelope.fill"
                    )

                    CustomTextField(
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        icon: "lock.fill"
                    )
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)

                // Login button
                LoadingButton(
                    title: "Login",
                    isLoading: viewModel.isLoading
                ) {
                    HapticManager.shared.submit()
                    Task {
                        let success = await viewModel.login(
                            email: email,
                            password: password
                        )

                        if success {
                            HapticManager.shared.success()
                        } else {
                            HapticManager.shared.error()
                        }
                    }
                }
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1 : 0.6)
                .padding(.horizontal)
                .padding(.top, 8)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)

                // Signup link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondaryText)
                    Button(action: {
                        HapticManager.shared.light()
                        showChurchSearch = true
                    }) {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.churchTalkRed)
                    }
                }
                .padding(.top, 8)
                .opacity(showContent ? 1 : 0)

                Spacer()
            }
        }
        .background(Color.background)
        .dismissKeyboardOnTap()
        .navigationDestination(isPresented: $showChurchSearch) {
            ChurchSearchView()
        }
        .onAppear {
            if let initialEmail = initialEmail {
                email = initialEmail
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
