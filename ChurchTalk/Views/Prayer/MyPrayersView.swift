import SwiftUI

struct MyPrayersView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedFilter: PrayerRequestStatus? = nil
    @State private var showDeleteConfirmation = false
    @State private var prayerToDelete: PrayerRequest?

    // API data
    @State private var myPrayers: [PrayerRequest] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var filteredPrayers: [PrayerRequest] {
        if let filter = selectedFilter {
            return myPrayers.filter { $0.status == filter }
        }
        return myPrayers.sorted { $0.createdAt > $1.createdAt }
    }

    var statusCounts: [PrayerRequestStatus: Int] {
        var counts: [PrayerRequestStatus: Int] = [:]
        for prayer in myPrayers {
            counts[prayer.status, default: 0] += 1
        }
        return counts
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChipButton(
                            title: "All",
                            count: myPrayers.count,
                            isSelected: selectedFilter == nil,
                            color: .churchTalkRed
                        ) {
                            withAnimation { selectedFilter = nil }
                        }

                        FilterChipButton(
                            title: "Pending",
                            count: statusCounts[.pending] ?? 0,
                            isSelected: selectedFilter == .pending,
                            color: .orange
                        ) {
                            withAnimation { selectedFilter = .pending }
                        }

                        FilterChipButton(
                            title: "Approved",
                            count: statusCounts[.approved] ?? 0,
                            isSelected: selectedFilter == .approved,
                            color: .green
                        ) {
                            withAnimation { selectedFilter = .approved }
                        }

                        FilterChipButton(
                            title: "Rejected",
                            count: statusCounts[.rejected] ?? 0,
                            isSelected: selectedFilter == .rejected,
                            color: .red
                        ) {
                            withAnimation { selectedFilter = .rejected }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))

                Divider()

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
                            Task { await loadMyPrayers() }
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                } else if filteredPrayers.isEmpty {
                    EmptyMyPrayersView(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredPrayers) { prayer in
                            MyPrayerCard(prayer: prayer)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        prayerToDelete = prayer
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Prayers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadMyPrayers()
            }
            .refreshable {
                await loadMyPrayers()
            }
            .alert("Delete Prayer?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let prayer = prayerToDelete {
                        deletePrayer(prayer)
                    }
                }
            } message: {
                Text("This prayer request will be permanently deleted.")
            }
        }
    }

    private func loadMyPrayers() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedPrayers = try await PrayerAPI.shared.getMyPrayers()
            await MainActor.run {
                myPrayers = fetchedPrayers
                isLoading = false
            }
        } catch {
            print("Failed to load my prayers: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load your prayers"
                isLoading = false
            }
        }
    }

    private func deletePrayer(_ prayer: PrayerRequest) {
        Task {
            do {
                try await PrayerAPI.shared.deletePrayer(prayerId: prayer.id)
                await MainActor.run {
                    withAnimation {
                        myPrayers.removeAll { $0.id == prayer.id }
                    }

                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                print("Failed to delete prayer: \(error)")
                await MainActor.run {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - Filter Chip Button

struct FilterChipButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : color.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.systemGray6))
            .cornerRadius(20)
        }
    }
}

// MARK: - My Prayer Card

struct MyPrayerCard: View {
    let prayer: PrayerRequest

    var statusColor: Color {
        switch prayer.status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }

    var statusIcon: String {
        switch prayer.status {
        case .pending: return "clock.fill"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status Badge
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                    Text(prayer.status.rawValue.capitalized)
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .cornerRadius(12)

                Spacer()

                if prayer.isAnonymous {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.slash.fill")
                        Text("Anonymous")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            // Content
            Text(prayer.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)

            // Footer
            HStack {
                Text(prayer.createdAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if prayer.status == .approved {
                    HStack(spacing: 4) {
                        Image(systemName: "hands.sparkles.fill")
                            .foregroundColor(.churchTalkRed)
                        Text("\(prayer.prayerCount) prayers")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                if prayer.status == .pending {
                    Text("Awaiting review")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                if prayer.status == .rejected {
                    Text("Not approved for prayer wall")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Empty State

struct EmptyMyPrayersView: View {
    let filter: PrayerRequestStatus?

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "hands.sparkles")
                .font(.system(size: 50))
                .foregroundColor(.churchTalkRed.opacity(0.5))

            if let filter = filter {
                Text("No \(filter.rawValue) prayers")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("You don't have any \(filter.rawValue) prayer requests.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No Prayer Requests")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("You haven't submitted any prayer requests yet.\nShare your prayer needs with the community.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    MyPrayersView()
        .environmentObject(AuthViewModel())
}
