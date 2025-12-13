import SwiftUI

struct ChurchLeadershipSection: View {
    let pastor: ChurchLeader?
    let leadershipTeam: [ChurchLeader]?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Leadership")
                .font(.headline)

            // Pastor (Featured)
            if let pastor = pastor {
                PastorCard(leader: pastor)
            }

            // Leadership Team
            if let team = leadershipTeam, !team.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Leadership Team")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(team) { leader in
                        LeaderRow(leader: leader)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Pastor Card

struct PastorCard: View {
    let leader: ChurchLeader

    var body: some View {
        HStack(spacing: 16) {
            // Photo or Initials
            if let photoUrl = leader.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
                .frame(width: 70, height: 70)
                .clipShape(Circle())
            } else {
                initialsView
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(leader.name)
                    .font(.title3)
                    .fontWeight(.bold)

                Text(leader.role)
                    .font(.subheadline)
                    .foregroundColor(.churchTalkRed)

                if let bio = leader.bio {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.churchTalkRed.opacity(0.05))
        .cornerRadius(12)
    }

    private var initialsView: some View {
        Circle()
            .fill(Color.churchTalkRed.opacity(0.2))
            .frame(width: 70, height: 70)
            .overlay(
                Text(leader.initials)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.churchTalkRed)
            )
    }
}

// MARK: - Leader Row

struct LeaderRow: View {
    let leader: ChurchLeader

    var body: some View {
        HStack(spacing: 12) {
            // Photo or Initials
            if let photoUrl = leader.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    smallInitialsView
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                smallInitialsView
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(leader.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(leader.role)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if leader.email != nil {
                Image(systemName: "envelope.fill")
                    .font(.caption)
                    .foregroundColor(.churchTalkRed)
            }
        }
        .padding(.vertical, 8)
    }

    private var smallInitialsView: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: 44, height: 44)
            .overlay(
                Text(leader.initials)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            )
    }
}

#Preview {
    ChurchLeadershipSection(
        pastor: ChurchLeader(
            id: "1",
            name: "Pastor John Smith",
            role: "Senior Pastor",
            bio: "Leading our congregation for over 15 years with a heart for community outreach."
        ),
        leadershipTeam: [
            ChurchLeader(id: "2", name: "Sarah Johnson", role: "Worship Pastor", email: "sarah@church.org"),
            ChurchLeader(id: "3", name: "Michael Davis", role: "Youth Pastor"),
            ChurchLeader(id: "4", name: "Emily Chen", role: "Children's Director", email: "emily@church.org")
        ]
    )
    .padding()
}
