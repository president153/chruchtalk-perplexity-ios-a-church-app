import SwiftUI

struct MySoulsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedFilter: SoulShareStatus? = nil
    @State private var showAddSoul = false
    @State private var selectedSoul: Soul?
    @State private var showShareSheet: Soul?

    // API data
    @State private var mySouls: [Soul] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var filteredSouls: [Soul] {
        if let filter = selectedFilter {
            return mySouls.filter { $0.shareStatus == filter }
        }
        return mySouls.sorted { $0.createdAt > $1.createdAt }
    }

    var statusCounts: [SoulShareStatus: Int] {
        var counts: [SoulShareStatus: Int] = [:]
        for soul in mySouls {
            counts[soul.shareStatus, default: 0] += 1
        }
        return counts
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats Summary
                HStack(spacing: 16) {
                    StatSummaryBox(value: "\(mySouls.count)", label: "Total Souls", icon: "star.fill", color: .churchTalkRed)
                    StatSummaryBox(value: "\(statusCounts[.shared] ?? 0)", label: "Shared", icon: "person.3.fill", color: .green)
                    StatSummaryBox(value: "\(statusCounts[.pendingReview] ?? 0)", label: "Pending", icon: "clock.fill", color: .orange)
                }
                .padding()

                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ShareStatusChip(
                            title: "All",
                            count: mySouls.count,
                            isSelected: selectedFilter == nil,
                            color: .churchTalkRed
                        ) {
                            withAnimation { selectedFilter = nil }
                        }

                        ShareStatusChip(
                            title: "Private",
                            count: statusCounts[.private] ?? 0,
                            isSelected: selectedFilter == .private,
                            color: .gray
                        ) {
                            withAnimation { selectedFilter = .private }
                        }

                        ShareStatusChip(
                            title: "Pending",
                            count: statusCounts[.pendingReview] ?? 0,
                            isSelected: selectedFilter == .pendingReview,
                            color: .orange
                        ) {
                            withAnimation { selectedFilter = .pendingReview }
                        }

                        ShareStatusChip(
                            title: "Shared",
                            count: statusCounts[.shared] ?? 0,
                            isSelected: selectedFilter == .shared,
                            color: .green
                        ) {
                            withAnimation { selectedFilter = .shared }
                        }
                    }
                    .padding(.horizontal)
                }

                Divider()
                    .padding(.top, 8)

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
                            Task { await loadSouls() }
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                } else if filteredSouls.isEmpty {
                    EmptyMySoulsView()
                } else {
                    List {
                        ForEach(filteredSouls) { soul in
                            MySoulCard(soul: soul) {
                                showShareSheet = soul
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .onTapGesture {
                                selectedSoul = soul
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Souls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSoul = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.churchTalkRed)
                    }
                }
            }
            .task {
                await loadSouls()
            }
            .refreshable {
                await loadSouls()
            }
            .sheet(isPresented: $showAddSoul) {
                AddSoulView { newSoul in
                    // Refresh to get the new soul from server
                    Task { await loadSouls() }
                }
            }
            .sheet(item: $selectedSoul) { soul in
                SoulDetailView(soul: soul)
            }
            .sheet(item: $showShareSheet) { soul in
                ShareSoulSheet(soul: soul) { updatedSoul in
                    if let index = mySouls.firstIndex(where: { $0.id == updatedSoul.id }) {
                        mySouls[index] = updatedSoul
                    }
                    // Also refresh from server to ensure consistency
                    Task { await loadSouls() }
                }
            }
        }
    }

    private func loadSouls() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedSouls = try await SoulsAPI.shared.getSouls(view: "mine", limit: 100)
            await MainActor.run {
                mySouls = fetchedSouls
                isLoading = false
            }
        } catch {
            print("Failed to load souls: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load souls"
                isLoading = false
            }
        }
    }
}

// MARK: - Stat Summary Box

struct StatSummaryBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Share Status Chip

struct ShareStatusChip: View {
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

// MARK: - My Soul Card

struct MySoulCard: View {
    let soul: Soul
    let onShare: () -> Void

    var statusColor: Color {
        switch soul.shareStatus {
        case .private: return .gray
        case .pendingReview: return .orange
        case .shared: return .green
        case .rejected: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Avatar
                Circle()
                    .fill(Color.churchTalkRed.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(soul.initials)
                            .font(.headline)
                            .foregroundColor(.churchTalkRed)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(soul.fullName)
                        .font(.headline)

                    HStack(spacing: 4) {
                        Image(systemName: soul.spiritualStage.iconName)
                        Text(soul.spiritualStage.displayName)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Share Status Badge
                HStack(spacing: 4) {
                    Image(systemName: soul.shareStatus.iconName)
                    Text(soul.shareStatus.displayName)
                }
                .font(.caption)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .cornerRadius(8)
            }

            // Notes preview
            if let notes = soul.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Actions
            HStack {
                if let lastContact = soul.lastContactDate {
                    Text("Last contact: \(lastContact.timeAgoDisplay())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if soul.shareStatus == .private {
                    Button {
                        onShare()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.churchTalkRed)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Share Soul Sheet

struct ShareSoulSheet: View {
    @Environment(\.dismiss) private var dismiss
    let soul: Soul
    let onShare: (Soul) -> Void
    @State private var additionalNotes = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Soul Info
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.churchTalkRed.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(soul.initials)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.churchTalkRed)
                        )

                    Text(soul.fullName)
                        .font(.title3)
                        .fontWeight(.bold)

                    HStack(spacing: 8) {
                        Label(soul.soulType.displayName, systemImage: soul.soulType.iconName)
                        Text("•")
                        Label(soul.spiritualStage.displayName, systemImage: soul.spiritualStage.iconName)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.top)

                // Info Box
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Sharing with Church")
                            .font(.headline)
                    }

                    Text("When you share a soul with the church, it will be reviewed by an admin before appearing in the church's SRM dashboard. This helps the church leadership coordinate follow-up efforts.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                // Additional Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes for Admin (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextEditor(text: $additionalNotes)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                Spacer()

                // Share Button
                Button {
                    var updatedSoul = soul
                    updatedSoul.shareStatus = .pendingReview
                    onShare(updatedSoul)

                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Submit for Review")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.churchTalkRed)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Share Soul")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Empty State

struct EmptyMySoulsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "star.circle")
                .font(.system(size: 50))
                .foregroundColor(.churchTalkRed.opacity(0.5))

            Text("No Souls Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Start tracking the people you meet during outreach.\nTap + to add your first soul.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    MySoulsView()
        .environmentObject(AuthViewModel())
}
