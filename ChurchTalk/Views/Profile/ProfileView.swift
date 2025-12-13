import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showSpiritualJourney = false
    @State private var showNotifications = false
    @State private var showPrivacy = false
    @State private var showAppearance = false
    @State private var showHelpCenter = false
    @State private var showContactUs = false
    @State private var showTermsPrivacy = false
    @State private var showChurchProfile = false
    @State private var showMyPrayers = false
    @State private var showMySouls = false
    @State private var showChurchEditor = false

    // Demo stats
    let stats = [
        ("door.left.hand.closed", "127", "Doors Knocked"),
        ("star.fill", "18", "Souls Added"),
        ("hands.sparkles.fill", "45", "Prayers"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.churchTalkRed.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(authViewModel.currentMember?.initials ?? "CT")
                                    .font(.title)
                                    .foregroundColor(.churchTalkRed)
                            )

                        VStack(spacing: 4) {
                            Text(authViewModel.currentMember?.fullName ?? "Church Member")
                                .font(.title2)
                                .fontWeight(.bold)

                            // Church Name - tappable to see profile
                            Button {
                                showChurchProfile = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(authViewModel.currentChurch?.name ?? "ChurchTalk")
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }

                            // Admin Badge
                            if authViewModel.currentMember?.isAdmin == true {
                                Button {
                                    showChurchEditor = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "shield.checkered")
                                        Text("Admin")
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                    }
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.churchTalkRed)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.top)

                    // Stats
                    HStack(spacing: 0) {
                        ForEach(stats, id: \.0) { stat in
                            VStack(spacing: 8) {
                                Image(systemName: stat.0)
                                    .font(.title2)
                                    .foregroundColor(.churchTalkRed)
                                Text(stat.1)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(stat.2)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(ChurchTalkTheme.cornerRadius)
                    .padding(.horizontal)

                    // Menu Sections
                    VStack(spacing: 0) {
                        MenuSection(title: "Account") {
                            MenuItem(icon: "person.fill", title: "Edit Profile", action: { showEditProfile = true })
                            MenuItem(icon: "arrow.triangle.branch", title: "Spiritual Journey", action: { showSpiritualJourney = true })
                            MenuItem(icon: "hands.sparkles.fill", title: "My Prayers", action: { showMyPrayers = true })
                            MenuItem(icon: "star.fill", title: "My Souls", action: { showMySouls = true })
                            MenuItem(icon: "bell.fill", title: "Notifications", action: { showNotifications = true })
                            MenuItem(icon: "lock.fill", title: "Privacy", action: { showPrivacy = true })
                        }

                        MenuSection(title: "Preferences") {
                            MenuItem(icon: "moon.fill", title: "Appearance", value: "System", action: { showAppearance = true })
                            MenuItem(icon: "globe", title: "Language", value: "English", action: {
                                // Open iOS settings for language
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            })
                        }

                        MenuSection(title: "Support") {
                            MenuItem(icon: "questionmark.circle.fill", title: "Help Center", action: { showHelpCenter = true })
                            MenuItem(icon: "envelope.fill", title: "Contact Us", action: { showContactUs = true })
                            MenuItem(icon: "doc.text.fill", title: "Terms & Privacy", action: { showTermsPrivacy = true })
                        }
                    }

                    // Sign Out
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(ChurchTalkTheme.cornerRadius)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)

                    // Version
                    Text("ChurchTalk v1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showSpiritualJourney) {
                SpiritualJourneyView()
            }
            .sheet(isPresented: $showNotifications) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacySettingsView()
            }
            .sheet(isPresented: $showAppearance) {
                AppearanceSettingsView()
            }
            .sheet(isPresented: $showHelpCenter) {
                HelpCenterView()
            }
            .sheet(isPresented: $showContactUs) {
                ContactUsView()
            }
            .sheet(isPresented: $showTermsPrivacy) {
                TermsPrivacyView()
            }
            .sheet(isPresented: $showChurchProfile) {
                if let church = authViewModel.currentChurch {
                    ChurchDetailView(church: church)
                }
            }
            .sheet(isPresented: $showMyPrayers) {
                MyPrayersView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showMySouls) {
                MySoulsView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showChurchEditor) {
                ChurchProfileEditorView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct MenuSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct MenuItem: View {
    let icon: String
    let title: String
    var value: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.churchTalkRed)
                    .frame(width: 24)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                if let value = value {
                    Text(value)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }

        Divider()
            .padding(.leading, 48)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
