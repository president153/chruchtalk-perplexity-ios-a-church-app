//
//  OnboardingView.swift
//  ChurchTalk
//
//  Enhanced onboarding with feature carousel for members
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var currentPage = 0
    @State private var showLogin = false
    @State private var showChurchSearch = false
    @State private var showContent = false

    private let features: [OnboardingFeature] = [
        OnboardingFeature(
            icon: "building.columns.fill",
            title: "Find Your Church",
            description: "Search and connect with your church community in seconds"
        ),
        OnboardingFeature(
            icon: "bell.badge.fill",
            title: "Stay Updated",
            description: "Receive bulletins, announcements, and event notifications from your church"
        ),
        OnboardingFeature(
            icon: "hands.sparkles.fill",
            title: "Join in Prayer",
            description: "Share and support prayer requests with your church family"
        ),
        OnboardingFeature(
            icon: "calendar.badge.plus",
            title: "Get Involved",
            description: "Register for events, join ministries, and serve your community"
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.churchTalkRed.opacity(0.8), Color.churchTalkRed]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Logo
                    VStack(spacing: 12) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)

                        VStack(spacing: 4) {
                            Text("A Church App")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("by ChurchTalk")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.top, 50)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -20)

                    // Feature carousel
                    TabView(selection: $currentPage) {
                        ForEach(features.indices, id: \.self) { index in
                            OnboardingFeatureCard(feature: features[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .frame(height: 340)
                    .opacity(showContent ? 1 : 0)

                    Spacer(minLength: 20)

                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            HapticManager.shared.medium()
                            showChurchSearch = true
                        }) {
                            Text("Get Started")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .foregroundColor(.churchTalkRed)
                                .background(Color.white)
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }

                        Button(action: {
                            HapticManager.shared.light()
                            showLogin = true
                        }) {
                            Text("Login")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                                )
                        }

                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                    showContent = true
                }
            }
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
                    .environmentObject(authViewModel)
            }
            .navigationDestination(isPresented: $showChurchSearch) {
                ChurchSearchView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}
