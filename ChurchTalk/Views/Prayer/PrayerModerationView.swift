import SwiftUI

struct PrayerModerationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pendingRequests: [PrayerRequest] = []
    @State private var showingApproveAlert = false
    @State private var showingRejectAlert = false
    @State private var selectedRequest: PrayerRequest?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "wifi.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task { await loadPendingPrayers() }
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                } else if pendingRequests.isEmpty {
                    EmptyModerationView()
                } else {
                    List {
                        ForEach(pendingRequests) { request in
                            PendingPrayerCard(
                                request: request,
                                onApprove: {
                                    selectedRequest = request
                                    showingApproveAlert = true
                                },
                                onReject: {
                                    selectedRequest = request
                                    showingRejectAlert = true
                                }
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Prayer Moderation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(pendingRequests.count) pending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .alert("Approve Prayer Request", isPresented: $showingApproveAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Approve") {
                    if let request = selectedRequest {
                        approveRequest(request)
                    }
                }
            } message: {
                Text("This prayer request will be visible on the Prayer Wall.")
            }
            .alert("Reject Prayer Request", isPresented: $showingRejectAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reject", role: .destructive) {
                    if let request = selectedRequest {
                        rejectRequest(request)
                    }
                }
            } message: {
                Text("This prayer request will not be shown on the Prayer Wall.")
            }
            .task {
                await loadPendingPrayers()
            }
            .refreshable {
                await loadPendingPrayers()
            }
        }
    }

    private func loadPendingPrayers() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedPrayers = try await PrayerAPI.shared.getPendingPrayers()
            await MainActor.run {
                pendingRequests = fetchedPrayers
                isLoading = false
            }
        } catch {
            print("Failed to load pending prayers: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load pending prayers"
                isLoading = false
            }
        }
    }

    private func approveRequest(_ request: PrayerRequest) {
        Task {
            do {
                try await PrayerAPI.shared.approvePrayer(prayerId: request.id)
                await MainActor.run {
                    withAnimation(ChurchTalkAnimations.smooth) {
                        pendingRequests.removeAll { $0.id == request.id }
                    }
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                print("Failed to approve prayer: \(error)")
                await MainActor.run {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }

    private func rejectRequest(_ request: PrayerRequest) {
        Task {
            do {
                try await PrayerAPI.shared.rejectPrayer(prayerId: request.id)
                await MainActor.run {
                    withAnimation(ChurchTalkAnimations.smooth) {
                        pendingRequests.removeAll { $0.id == request.id }
                    }
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                print("Failed to reject prayer: \(error)")
                await MainActor.run {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
}

struct PendingPrayerCard: View {
    let request: PrayerRequest
    let onApprove: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Content
            Text(request.content)
                .font(.body)
                .lineLimit(4)

            // Author & Time
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: request.isAnonymous ? "person.fill.questionmark" : "person.fill")
                        .font(.caption)
                    Text(request.displayAuthor)
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)

                Spacer()

                Text(request.createdAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Action Buttons
            HStack(spacing: 16) {
                Button(action: onReject) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Reject")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(20)
                }

                Button(action: onApprove) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Approve")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.churchTalkRed)
                    .cornerRadius(20)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(ChurchTalkTheme.cornerRadius)
        .shadow(color: ChurchTalkTheme.cardShadowColor, radius: 4, y: 2)
    }
}

struct EmptyModerationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.churchTalkRed)

            Text("All Caught Up!")
                .font(.title2)
                .fontWeight(.bold)

            Text("There are no prayer requests waiting for approval.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

#Preview {
    PrayerModerationView()
}
