import SwiftUI

struct HomeHeaderView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showNotifications = false
    @State private var showSettings = false

    let churchName: String
    let churchLogoUrl: String?
    var collapseProgress: CGFloat = 0 // 0 = expanded, 1 = collapsed


    // Interpolated values
    private var logoSize: CGFloat {
        lerp(from: 56, to: 36, progress: collapseProgress)
    }

    private var titleFont: Font {
        collapseProgress < 0.5 ? .title2 : .headline
    }

    private var showExtras: Bool {
        collapseProgress < 0.3
    }

    var body: some View {
        VStack(spacing: lerp(from: 12, to: 6, progress: collapseProgress)) {
            // Main row - always visible
            HStack(spacing: 12) {
                // Church Logo
                churchLogo

                // Church Name + Date (stacks when expanded, inline when collapsed)
                VStack(alignment: .leading, spacing: 2) {
                    Text(churchName)
                        .font(titleFont)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    if showExtras {
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Spacer()

                // Action buttons
                actionButtons
            }

        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .animation(.easeInOut(duration: 0.2), value: showExtras)
        .sheet(isPresented: $showNotifications) {
            NotificationCenterView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Components

    private var churchLogo: some View {
        Group {
            if let logoUrl = churchLogoUrl, let url = URL(string: logoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    logoPlaceholder
                }
                .frame(width: logoSize, height: logoSize)
                .clipShape(Circle())
            } else {
                logoPlaceholder
            }
        }
    }

    private var churchInitials: String {
        let words = churchName.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let firstWord = words.first {
            return String(firstWord.prefix(2)).uppercased()
        }
        return "CH"
    }

    private var logoPlaceholder: some View {
        Circle()
            .fill(Color.churchTalkRed.opacity(0.2))
            .frame(width: logoSize, height: logoSize)
            .overlay(
                Text(churchInitials)
                    .font(.system(size: logoSize * 0.35, weight: .bold))
                    .foregroundColor(.churchTalkRed)
            )
    }

    private var actionButtons: some View {
        HStack(spacing: 14) {
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
                        .offset(x: 3, y: -3)
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

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    // Linear interpolation helper
    private func lerp(from: CGFloat, to: CGFloat, progress: CGFloat) -> CGFloat {
        from + (to - from) * progress
    }
}

// Placeholder for NotificationCenterView
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

// Quick Settings View
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showNotificationSettings = false
    @State private var showAppearanceSettings = false
    @State private var showPrivacySettings = false

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Button {
                        showNotificationSettings = true
                    } label: {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                    .foregroundColor(.primary)

                    Button {
                        showAppearanceSettings = true
                    } label: {
                        Label("Appearance", systemImage: "moon.fill")
                    }
                    .foregroundColor(.primary)

                    Button {
                        showPrivacySettings = true
                    } label: {
                        Label("Privacy", systemImage: "lock.fill")
                    }
                    .foregroundColor(.primary)
                }

                Section("Account") {
                    Button {
                        authViewModel.signOut()
                        dismiss()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showAppearanceSettings) {
                AppearanceSettingsView()
            }
            .sheet(isPresented: $showPrivacySettings) {
                PrivacySettingsView()
            }
        }
    }
}

#Preview {
    VStack {
        HomeHeaderView(
            churchName: "Norwalk Baptist Church",
            churchLogoUrl: nil,
            collapseProgress: 0
        )
        .background(Color.gray.opacity(0.1))
        .environmentObject(AuthViewModel())

        Divider()

        HomeHeaderView(
            churchName: "Norwalk Baptist Church",
            churchLogoUrl: nil,
            collapseProgress: 1
        )
        .background(Color.gray.opacity(0.1))
        .environmentObject(AuthViewModel())

        Spacer()
    }
}
