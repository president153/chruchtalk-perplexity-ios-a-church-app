import SwiftUI

struct DirectoryListView: View {
    @State private var searchText = ""
    @State private var members: [Member] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var filteredMembers: [Member] {
        if searchText.isEmpty {
            return members
        }
        return members.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

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
                            Task { await loadMembers() }
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                } else if members.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "person.2.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No members found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredMembers) { member in
                            NavigationLink(destination: MemberProfileView(member: member)) {
                                MemberRow(member: member)
                            }
                        }

                        // Bottom padding for tab bar
                        Color.clear.frame(height: 90)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .navigationTitle("Directory")
            .searchable(text: $searchText, prompt: "Search members")
            .task {
                await loadMembers()
            }
            .refreshable {
                await loadMembers()
            }
            .onChange(of: searchText) { _, newValue in
                // Debounced search - for server-side search in future
                // Currently filtering client-side
            }
        }
    }

    private func loadMembers() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await MembersAPI.shared.getMembers(limit: 200)
            await MainActor.run {
                members = response.members
                isLoading = false
            }
        } catch {
            print("Failed to load members: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load directory"
                isLoading = false
            }
        }
    }
}

struct MemberRow: View {
    let member: Member

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.churchTalkRed.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(member.initials)
                        .font(.headline)
                        .foregroundColor(.churchTalkRed)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(member.fullName)
                    .font(.headline)

                if !member.ministries.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(member.ministries.prefix(2), id: \.self) { ministry in
                            Text(ministry)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                        if member.ministries.count > 2 {
                            Text("+\(member.ministries.count - 2)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DirectoryListView()
}
