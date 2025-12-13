//
//  OnboardingFeatureCard.swift
//  ChurchTalk
//
//  Reusable feature card for onboarding carousel
//

import SwiftUI

struct OnboardingFeature {
    let icon: String
    let title: String
    let description: String
}

struct OnboardingFeatureCard: View {
    let feature: OnboardingFeature

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: feature.icon)
                .font(.system(size: 70))
                .foregroundColor(.white)
                .frame(height: 100)

            VStack(spacing: 12) {
                Text(feature.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    ZStack {
        Color.churchTalkRed
            .ignoresSafeArea()

        OnboardingFeatureCard(
            feature: OnboardingFeature(
                icon: "building.columns.fill",
                title: "Find Your Church",
                description: "Search and connect with your church community"
            )
        )
    }
}
