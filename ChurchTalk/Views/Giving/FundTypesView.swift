//
//  FundTypesView.swift
//  ChurchTalk
//
//  Fund types view for giving (placeholder for member app)
//

import SwiftUI

struct FundTypesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            Color.secondaryBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.financeColor)

                Text("Giving")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)

                Text("Support your church through tithes and offerings")
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Text("Coming Soon")
                    .font(.caption)
                    .foregroundColor(.tertiaryText)
                    .padding(.top, 8)
            }
        }
        .navigationTitle("Giving")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        FundTypesView()
            .environmentObject(AuthViewModel())
    }
}
