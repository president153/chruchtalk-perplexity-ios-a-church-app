import SwiftUI

struct PrayerWallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showNewRequest = false
    @State private var showModeration = false
    @State private var prayers: [PrayerRequest] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Button("Retry") {
                                Task { await loadPrayers() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else if prayers.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "hands.sparkles")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No prayer requests yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Be the first to share a prayer request")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        ForEach(prayers) { request in
                            PrayerRequestCard(request: request, onPrayerCountUpdated: { updatedPrayer in
                                if let index = prayers.firstIndex(where: { $0.id == updatedPrayer.id }) {
                                    prayers[index] = updatedPrayer
                                }
                            })
                            .transition(ChurchTalkAnimations.cardAppear)
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                await loadPrayers()
            }
            .navigationTitle("Prayer Wall")
            .toolbar {
                // Done button to close sheet
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        Button("Done") { dismiss() }

                        // Admin moderation button
                        if authViewModel.currentMember?.isAdmin == true {
                            Button(action: { showModeration = true }) {
                                Image(systemName: "clock.badge.checkmark")
                                    .foregroundColor(.churchTalkRed)
                            }
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
                NewPrayerRequestView(onPrayerCreated: {
                    Task { await loadPrayers() }
                })
            }
            .sheet(isPresented: $showModeration) {
                PrayerModerationView()
            }
            .task {
                await loadPrayers()
            }
        }
    }

    private func loadPrayers() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedPrayers = try await PrayerAPI.shared.getPrayers(limit: 50)
            await MainActor.run {
                prayers = fetchedPrayers
                isLoading = false
            }
        } catch {
            print("Failed to load prayers: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load prayers"
                isLoading = false
            }
        }
    }
}

struct PrayerRequestCard: View {
    let request: PrayerRequest
    var onPrayerCountUpdated: ((PrayerRequest) -> Void)? = nil
    @State private var hasPrayed: Bool
    @State private var currentPrayerCount: Int
    @State private var showAnimation = false
    @State private var isSubmitting = false

    init(request: PrayerRequest, onPrayerCountUpdated: ((PrayerRequest) -> Void)? = nil) {
        self.request = request
        self.onPrayerCountUpdated = onPrayerCountUpdated
        self._hasPrayed = State(initialValue: request.hasPrayed)
        self._currentPrayerCount = State(initialValue: request.prayerCount)
    }

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
                    Text("\(currentPrayerCount) prayers")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)

                Spacer()

                Button(action: {
                    if !hasPrayed && !isSubmitting {
                        prayForRequest()
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

    private func prayForRequest() {
        isSubmitting = true
        hasPrayed = true
        showAnimation = true

        // Optimistic update
        currentPrayerCount += 1

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showAnimation = false
        }

        // Call API
        Task {
            do {
                let response = try await PrayerAPI.shared.prayFor(prayerId: request.id)
                await MainActor.run {
                    // Handle both success and "already prayed" responses
                    // If message exists, user already prayed - keep optimistic state
                    if response.message != nil {
                        // Already prayed - keep current state
                        isSubmitting = false
                    } else {
                        // Success - update with server values
                        currentPrayerCount = response.prayerCount ?? currentPrayerCount
                        hasPrayed = response.hasPrayed ?? true
                        isSubmitting = false

                        // Update parent
                        var updatedRequest = request
                        updatedRequest.prayerCount = response.prayerCount ?? currentPrayerCount
                        updatedRequest.hasPrayed = response.hasPrayed ?? true
                        onPrayerCountUpdated?(updatedRequest)
                    }
                }
            } catch {
                print("Failed to pray: \(error)")
                await MainActor.run {
                    // Revert on error
                    currentPrayerCount -= 1
                    hasPrayed = false
                    isSubmitting = false
                }
            }
        }
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
