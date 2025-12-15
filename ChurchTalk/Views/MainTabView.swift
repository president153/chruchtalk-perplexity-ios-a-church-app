import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0

    var isAdmin: Bool {
        authViewModel.currentMember?.isAdmin == true
    }

    var body: some View {
        Group {
            switch selectedTab {
            case 0:
                HomeView()
            case 1:
                ConnectTabView()
            case 2:
                ServeTabView()
            case 3:
                ProfileTabView(isAdmin: isAdmin)
            default:
                HomeView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            FloatingTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Floating Tab Bar

struct FloatingTabBar: View {
    @Binding var selectedTab: Int

    let tabs: [(icon: String, selectedIcon: String, title: String)] = [
        ("house", "house.fill", "Home"),
        ("bubble.left.and.bubble.right", "bubble.left.and.bubble.right.fill", "Connect"),
        ("hands.clap", "hands.clap.fill", "Serve"),
        ("person.circle", "person.circle.fill", "Profile")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                TabBarItem(
                    icon: tabs[index].icon,
                    selectedIcon: tabs[index].selectedIcon,
                    title: tabs[index].title,
                    isSelected: selectedTab == index
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Tab Bar Item

struct TabBarItem: View {
    let icon: String
    let selectedIcon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Background pill for selected state
                    if isSelected {
                        Capsule()
                            .fill(Color.churchTalkRed.opacity(0.15))
                            .frame(width: 56, height: 32)
                    }

                    Image(systemName: isSelected ? selectedIcon : icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .churchTalkRed : .gray)
                }
                .frame(height: 32)

                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .churchTalkRed : .gray)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabBarButtonStyle())
    }
}

// MARK: - Tab Bar Button Style

struct TabBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Enhanced Profile Tab with Admin Access

struct ProfileTabView: View {
    let isAdmin: Bool
    @State private var showSRM = false

    var body: some View {
        NavigationStack {
            ProfileView()
                .toolbar {
                    if isAdmin {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink(destination: SRMDashboardView()) {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.text.square.fill")
                                    Text("SRM")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.churchTalkRed)
                            }
                        }
                    }
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
