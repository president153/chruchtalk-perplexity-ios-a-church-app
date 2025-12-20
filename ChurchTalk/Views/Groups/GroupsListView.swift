//
//  GroupsListView.swift
//  ChurchTalk
//
//  Lists small groups with ability to join/leave and filter by type.
//

import SwiftUI

struct GroupsListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groups: [SmallGroup] = []
    @State private var myGroups: [SmallGroup] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedType: GroupType?
    @State private var showingMyGroups = false
    @State private var joiningGroupId: String?

    var filteredGroups: [SmallGroup] {
        let list = showingMyGroups ? myGroups : groups
        if let type = selectedType {
            return list.filter { $0.groupType == type }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Toggle between All / My Groups
                Picker("", selection: $showingMyGroups) {
                    Text("All Groups").tag(false)
                    Text("My Groups").tag(true)
                }
                .pickerStyle(.segmented)
                .padding()

                // Type Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        GroupsFilterChip(
                            title: "All",
                            isSelected: selectedType == nil
                        ) {
                            selectedType = nil
                        }

                        ForEach(GroupType.allCases, id: \.self) { type in
                            GroupsFilterChip(
                                title: type.displayName,
                                isSelected: selectedType == type
                            ) {
                                selectedType = type
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)

                // Content
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task { await loadGroups() }
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                } else if filteredGroups.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.3")
                            .font(.system(size: 50))
                            .foregroundColor(.orange.opacity(0.6))
                        Text(showingMyGroups ? "You haven't joined any groups yet" : "No groups available")
                            .font(.headline)
                        Text("Join a group to connect with others")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(filteredGroups) { group in
                        GroupCard(
                            group: group,
                            isJoining: joiningGroupId == group.id,
                            isMember: myGroups.contains { $0.id == group.id }
                        ) {
                            Task { await toggleGroupMembership(group) }
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Connect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadGroups()
            }
            .refreshable {
                await loadGroups()
            }
        }
    }

    private func loadGroups() async {
        isLoading = true
        errorMessage = nil

        do {
            async let allGroupsTask = GroupsAPI.shared.getGroups(isOpen: true)
            async let myGroupsTask = GroupsAPI.shared.getMyGroups()

            let (allGroups, memberGroups) = try await (allGroupsTask, myGroupsTask)

            await MainActor.run {
                groups = allGroups
                myGroups = memberGroups
                isLoading = false
            }
        } catch {
            print("Failed to load groups: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load groups"
                isLoading = false
            }
        }
    }

    private func toggleGroupMembership(_ group: SmallGroup) async {
        joiningGroupId = group.id
        defer { joiningGroupId = nil }

        let isMember = myGroups.contains { $0.id == group.id }

        do {
            if isMember {
                _ = try await GroupsAPI.shared.leaveGroup(id: group.id)
                await MainActor.run {
                    myGroups.removeAll { $0.id == group.id }
                }
            } else {
                let updatedGroup = try await GroupsAPI.shared.joinGroup(id: group.id)
                await MainActor.run {
                    myGroups.append(updatedGroup)
                    // Update member count in all groups list
                    if let index = groups.firstIndex(where: { $0.id == group.id }) {
                        groups[index] = updatedGroup
                    }
                }
            }
        } catch {
            print("Failed to update group membership: \(error)")
        }
    }
}

// MARK: - Group Card

private struct GroupCard: View {
    let group: SmallGroup
    let isJoining: Bool
    let isMember: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Group Icon
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: iconForType(group.groupType))
                            .foregroundColor(.orange)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)

                    Text(group.groupType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let leader = group.leaderName {
                        Text("Led by \(leader)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(group.memberCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("members")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Meeting Schedule
            if group.meetingDay != nil || group.meetingTime != nil {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(group.meetingSchedule)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Location
            if let location = group.location {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Description
            if let description = group.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Join/Leave Button
            Button(action: onToggle) {
                HStack {
                    if isJoining {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isMember ? "checkmark.circle.fill" : "plus.circle.fill")
                    }
                    Text(isMember ? "Joined" : "Join Group")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isMember ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                .foregroundColor(isMember ? .green : .orange)
                .cornerRadius(8)
            }
            .disabled(isJoining)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func iconForType(_ type: GroupType) -> String {
        switch type {
        case .smallGroup: return "person.3.fill"
        case .lifeGroup: return "leaf.fill"
        case .bibleStudy: return "book.fill"
        case .prayerGroup: return "hands.sparkles.fill"
        case .ministryTeam: return "figure.stand.line.dotted.figure.stand"
        case .other: return "circle.grid.2x2.fill"
        }
    }
}

// MARK: - Filter Chip

private struct GroupsFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.systemGray5))
                .cornerRadius(20)
        }
    }
}

#Preview {
    GroupsListView()
}
