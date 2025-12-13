import SwiftUI

struct ChurchMinistriesSection: View {
    let ministries: [ChurchMinistry]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ministries")
                    .font(.headline)
                Spacer()
                Text("\(ministries.count) active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ministries) { ministry in
                    MinistryCard(ministry: ministry)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Ministry Card

struct MinistryCard: View {
    let ministry: ChurchMinistry
    @State private var isExpanded = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Icon
                    Image(systemName: ministry.displayIcon)
                        .font(.title2)
                        .foregroundColor(.churchTalkRed)
                        .frame(width: 40, height: 40)
                        .background(Color.churchTalkRed.opacity(0.1))
                        .cornerRadius(10)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(ministry.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(ministry.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)

                        if let leader = ministry.leaderName {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.caption2)
                                Text(leader)
                            }
                            .font(.caption)
                            .foregroundColor(.churchTalkRed)
                        }

                        if let meetingTime = ministry.meetingTime {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.caption2)
                                Text(meetingTime)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Ministry List View (Alternative Layout)

struct MinistryListSection: View {
    let ministries: [ChurchMinistry]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ministries")
                .font(.headline)

            ForEach(ministries) { ministry in
                MinistryListRow(ministry: ministry)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MinistryListRow: View {
    let ministry: ChurchMinistry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: ministry.displayIcon)
                .font(.title3)
                .foregroundColor(.churchTalkRed)
                .frame(width: 36, height: 36)
                .background(Color.churchTalkRed.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(ministry.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(ministry.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if ministry.leaderName != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ScrollView {
        ChurchMinistriesSection(ministries: [
            ChurchMinistry(id: "1", name: "Youth Ministry", description: "Empowering the next generation to live for Christ", leaderName: "Jake Wilson", iconName: "star.fill", meetingTime: "Sundays 5:30 PM"),
            ChurchMinistry(id: "2", name: "Worship Team", description: "Leading our congregation in praise and worship", leaderName: "Sarah Thompson", iconName: "music.note", meetingTime: "Thursdays 7 PM"),
            ChurchMinistry(id: "3", name: "Outreach", description: "Reaching our community with God's love", iconName: "hands.sparkles.fill"),
            ChurchMinistry(id: "4", name: "Children's Ministry", description: "Teaching kids to follow Jesus", leaderName: "Emily Davis", iconName: "figure.2.and.child.holdinghands"),
            ChurchMinistry(id: "5", name: "Small Groups", description: "Growing together in faith", iconName: "person.3.fill"),
            ChurchMinistry(id: "6", name: "Prayer Team", description: "Interceding for our church family", iconName: "hands.sparkles")
        ])
        .padding()
    }
}
