//
//  JoinRequestView.swift
//  ChurchTalk
//
//  Join church request form with enhanced UI
//

import SwiftUI

struct JoinRequestView: View {
    let church: Church
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var showEmailVerification = false
    @State private var showContent = false

    var isValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && email.contains("@") && password.count >= 8
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Church Header
                VStack(spacing: 12) {
                    // Church Avatar
                    ZStack {
                        Circle()
                            .fill(Color.churchTalkRed.opacity(0.1))
                            .frame(width: 80, height: 80)

                        if let imageUrl = church.imageUrl, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.churchTalkRed)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.churchTalkRed)
                        }
                    }

                    Text("Join \(church.name)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)

                    if !church.locationString.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                            Text(church.locationString)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                    }
                }
                .padding(.top, 20)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : -10)

                // Form
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        CustomTextField(
                            placeholder: "First Name",
                            text: $firstName,
                            icon: "person.fill"
                        )

                        CustomTextField(
                            placeholder: "Last Name",
                            text: $lastName,
                            icon: nil
                        )
                    }

                    CustomTextField(
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        icon: "envelope.fill"
                    )

                    CustomTextField(
                        placeholder: "Phone (Optional)",
                        text: $phone,
                        keyboardType: .phonePad,
                        icon: "phone.fill"
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        CustomTextField(
                            placeholder: "Create Password",
                            text: $password,
                            isSecure: true,
                            icon: "lock.fill"
                        )

                        PasswordStrengthIndicator(password: password)
                    }
                }
                .padding(.horizontal)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)

                // Info text
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.outreachGreen)
                        Text("Access church bulletin and announcements")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.outreachGreen)
                        Text("Join prayer wall and support others")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.outreachGreen)
                        Text("Register for events and ministries")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundColor(.secondaryText)
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)

                // Submit button
                LoadingButton(
                    title: "Request to Join",
                    isLoading: isSubmitting
                ) {
                    HapticManager.shared.submit()
                    isSubmitting = true
                    Task {
                        let success = await authViewModel.joinChurch(
                            church: church,
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            phone: phone.isEmpty ? nil : phone
                        )
                        isSubmitting = false
                        if success {
                            HapticManager.shared.success()
                            showEmailVerification = true
                        } else {
                            HapticManager.shared.error()
                        }
                    }
                }
                .disabled(!isValid || isSubmitting)
                .opacity(isValid ? 1 : 0.6)
                .padding(.horizontal)
                .opacity(showContent ? 1 : 0)

                Spacer()
            }
        }
        .background(Color.background)
        .dismissKeyboardOnTap()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    HapticManager.shared.light()
                    dismiss()
                }
            }
        }
        .navigationDestination(isPresented: $showEmailVerification) {
            EmailVerificationView()
                .environmentObject(authViewModel)
        }
    }
}

#Preview {
    NavigationStack {
        JoinRequestView(
            church: Church(
                id: "1",
                name: "First Baptist Church",
                city: "Lancaster",
                state: "CA",
                memberCount: 500
            )
        )
        .environmentObject(AuthViewModel())
    }
}
