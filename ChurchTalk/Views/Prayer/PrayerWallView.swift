import SwiftUI

struct PrayerWallView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showNewRequest = false
    @State private var showModeration = false

    // Demo approved requests
    let requests: [PrayerRequest] = [
        PrayerRequest(id: "1", content: "Please pray for my mother's surgery tomorrow. The doctors say it's routine but I'm still worried.", authorId: "1", authorName: "Sarah M.", isAnonymous: false, prayerCount: 47, createdAt: Date().addingTimeInterval(-3600), status: .approved),
        PrayerRequest(id: "2", content: "Struggling with job search. Need guidance and peace during this season.", authorId: "2", isAnonymous: true, prayerCount: 23, createdAt: Date().addingTimeInterval(-86400), status: .approved),
        PrayerRequest(id: "3", content: "Praise report! My son accepted Christ this weekend!", authorId: "3", authorName: "Michael C.", isAnonymous: false, prayerCount: 89, createdAt: Date().addingTimeInterval(-172800), status: .approved),
        PrayerRequest(id: "4", content: "Please pray for our missions team traveling to Guatemala next week.", authorId: "4", authorName: "Pastor John", isAnonymous: false, prayerCount: 156, createdAt: Date().addingTimeInterval(-259200), status: .approved),
    ]

    // Only show approved prayers on the wall
    var approvedRequests: [PrayerRequest] {
        requests.filter { $0.isApproved }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(approvedRequests) { request in
                        PrayerRequestCard(request: request)
                            .transition(ChurchTalkAnimations.cardAppear)
                    }
                }
                .padding()
            }
            .navigationTitle("Prayer Wall")
            .toolbar {
                // Admin moderation button
                if authViewModel.currentMember?.isAdmin == true {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showModeration = true }) {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundColor(.churchTalkRed)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewRequest = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.churchTalkRed)
                    }
                }
            }
            .sheet(isPresented: $showNewRequest) {
                NewPrayerRequestView()
            }
            .sheet(isPresented: $showModeration) {
                PrayerModerationView()
            }
        }
    }
}

struct PrayerRequestCard: View {
    let request: PrayerRequest
    @State private var hasPrayed = false
    @State private var showAnimation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Content
            Text(request.content)
                .font(.body)

            // Author & Time
            HStack {
                Text("- \(request.displayAuthor)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(request.createdAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Prayer Count & Button
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "hands.sparkles.fill")
                        .foregroundColor(.churchTalkRed)
                    Text("\(request.prayerCount + (hasPrayed ? 1 : 0)) prayers")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)

                Spacer()

                Button(action: {
                    if !hasPrayed {
                        hasPrayed = true
                        showAnimation = true
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showAnimation = false
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: hasPrayed ? "checkmark" : "hands.sparkles")
                        Text(hasPrayed ? "Prayed" : "I Prayed")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(hasPrayed ? .white : .churchTalkRed)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(hasPrayed ? Color.churchTalkRed : Color.churchTalkRed.opacity(0.1))
                    .cornerRadius(20)
                }
                .disabled(hasPrayed)
                .animation(ChurchTalkAnimations.bouncy, value: hasPrayed)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        .overlay(
            Group {
                if showAnimation {
                    PrayerAnimation()
                }
            }
        )
    }
}

struct PrayerAnimation: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1

    var body: some View {
        Image(systemName: "hands.sparkles.fill")
            .font(.system(size: 60))
            .foregroundColor(.churchTalkRed)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    scale = 1.5
                    opacity = 0
                }
            }
    }
}

#Preview {
    PrayerWallView()
        .environmentObject(AuthViewModel())
}
