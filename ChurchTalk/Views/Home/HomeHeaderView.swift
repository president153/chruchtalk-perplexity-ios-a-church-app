import SwiftUI

struct HomeHeaderView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showNotifications = false
    @State private var showSettings = false

    // Demo church data - would come from authViewModel.currentChurch
    let churchName: String
    let churchLogoUrl: String?

    // Daily verse - could be fetched from API
    let dailyVerse = ("The Lord is my shepherd; I shall not want.", "Psalm 23:1")

    var body: some View {
        VStack(spacing: 16) {
            // Top Row: Logo and Actions
            HStack(alignment: .top) {
                // Church Logo
                if let logoUrl = churchLogoUrl, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.churchTalkRed.opacity(0.2))
                            .overlay(
                                Image(systemName: "building.columns.fill")
                                    .font(.title2)
                                    .foregroundColor(.churchTalkRed)
                            )
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.churchTalkRed.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "building.columns.fill")
                                .font(.title2)
                                .foregroundColor(.churchTalkRed)
                        )
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 16) {
                    // Notification Bell
                    Button(action: { showNotifications = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.title3)
                                .foregroundColor(.churchTalkRed)

                            // Badge
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }

                    // Settings
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Church Name
            VStack(alignment: .leading, spacing: 4) {
                Text(churchName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Today's Date
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Daily Verse Card
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.title3)
                    .foregroundColor(.churchTalkRed)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\"\(dailyVerse.0)\"")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text("- \(dailyVerse.1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.churchTalkRed.opacity(0.08))
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .sheet(isPresented: $showNotifications) {
            NotificationCenterView()
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

// Placeholder for NotificationCenterView if not exists
struct NotificationCenterView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Text("No new notifications")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    HomeHeaderView(
        churchName: "Grace Community Church",
        churchLogoUrl: nil
    )
    .environmentObject(AuthViewModel())
}
