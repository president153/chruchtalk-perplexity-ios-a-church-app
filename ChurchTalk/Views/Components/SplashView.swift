//
//  SplashView.swift
//  ChurchTalk
//
//  Animated splash screen shown on app launch
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            // Red background matching the logo
            Color.churchTalkRed
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Logo
                VStack(spacing: 20) {
                    // App Logo Image with animation
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    // App name
                    VStack(spacing: 4) {
                        Text("A Church App")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("by ChurchTalk")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .opacity(logoOpacity)
                }

                // Tagline - member centric
                Text("Your Church, Your Community")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(taglineOpacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Logo animation: fade in + scale
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Tagline animation: fade in with delay
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                taglineOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
