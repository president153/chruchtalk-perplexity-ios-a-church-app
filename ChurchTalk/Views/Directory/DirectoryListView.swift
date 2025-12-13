import SwiftUI

struct DirectoryListView: View {
    @State private var searchText = ""

    let members: [Member] = [
        Member(id: "1", firstName: "John", lastName: "Anderson", email: "john@church.org", churchId: "1", ministries: ["Worship", "Ushers"]),
        Member(id: "2", firstName: "Sarah", lastName: "Williams", email: "sarah@church.org", churchId: "1", ministries: ["Youth"]),
        Member(id: "3", firstName: "Michael", lastName: "Chen", email: "michael@church.org", churchId: "1", ministries: ["Outreach"]),
        Member(id: "4", firstName: "Emily", lastName: "Davis", email: "emily@church.org", churchId: "1", ministries: ["Children", "Worship"]),
        Member(id: "5", firstName: "David", lastName: "Kim", email: "david@church.org", churchId: "1", ministries: ["Tech"]),
        Member(id: "6", firstName: "Lisa", lastName: "Thompson", email: "lisa@church.org", churchId: "1", ministries: ["Prayer"]),
    ]

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
            List {
                ForEach(filteredMembers) { member in
                    NavigationLink(destination: MemberProfileView(member: member)) {
                        MemberRow(member: member)
                    }
                }
            }
            .navigationTitle("Directory")
            .searchable(text: $searchText, prompt: "Search members")
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
