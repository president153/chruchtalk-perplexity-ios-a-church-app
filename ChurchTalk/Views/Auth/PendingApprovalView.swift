//
//  PendingApprovalView.swift
//  ChurchTalk
//
//  View shown when waiting for church administrator approval
//

import SwiftUI

struct PendingApprovalView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var showProfileCompletion = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration
            Image(systemName: "clock.badge.checkmark")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.churchTalkRed)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.5)

            // Content
            VStack(spacing: 16) {
                Text("Waiting for Approval")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                    .opacity(showContent ? 1 : 0)

                Text("Your request to join")
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .opacity(showContent ? 1 : 0)

                if let churchName = viewModel.pendingChurchName ?? UserDefaults.standard.string(forKey: "currentChurchName") {
                    Text(churchName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.churchTalkRed)
                        .padding(.horizontal)
                        .opacity(showContent ? 1 : 0)
                }

                Text("is pending approval from the church administrator.")
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(showContent ? 1 : 0)

                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.churchTalkRed)
                        Text("You'll receive an email once approved")
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                    }

                    HStack {
                        Image(systemName: "hourglass")
                            .foregroundColor(.tertiaryText)
                        Text("This request expires in 7 days")
                            .font(.subheadline)
                            .foregroundColor(.tertiaryText)
                    }
                }
                .padding(.top, 8)
                .opacity(showContent ? 1 : 0)
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                // Complete Profile Button
                if !viewModel.isProfileCompleted {
                    Button(action: {
                        HapticManager.shared.medium()
                        showProfileCompletion = true
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Complete Your Profile")
                        }
                        .font(.headline)
                        .foregroundColor(.churchTalkRed)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.churchTalkRed.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Text("Speed up your approval by completing your profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 8)
                } else {
                    // Profile completed badge
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Profile Completed")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                Button(action: {
                    HapticManager.shared.medium()
                    viewModel.logout()
                }) {
                    Text("Back to Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.churchTalkRed)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Text("Contact your church administrator if you need assistance")
                    .font(.caption)
                    .foregroundColor(.tertiaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Dev button - simulate approval to see actual app
                Button(action: {
                    HapticManager.shared.success()
                    viewModel.approveJoinRequest()
                }) {
                    Text("Continue to App (Dev)")
                        .font(.subheadline)
                        .foregroundColor(.churchTalkRed)
                        .underline()
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 32)
            .opacity(showContent ? 1 : 0)
        }
        .background(Color.background)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showProfileCompletion) {
            SoulJourneyProfileView()
                .environmentObject(viewModel)
        }
        .onAppear {
            viewModel.loadProfileCompletionStatus()
        }
    }
}

#Preview {
    PendingApprovalView()
        .environmentObject(AuthViewModel())
}
