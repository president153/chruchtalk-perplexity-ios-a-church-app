import SwiftUI

struct ChurchMissionVisionSection: View {
    let missionStatement: String?
    let visionStatement: String?
    let coreValues: [String]?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mission & Vision")
                .font(.headline)

            // Mission Statement
            if let mission = missionStatement {
                StatementCard(
                    title: "Our Mission",
                    icon: "target",
                    content: mission,
                    color: .churchTalkRed
                )
            }

            // Vision Statement
            if let vision = visionStatement {
                StatementCard(
                    title: "Our Vision",
                    icon: "eye.fill",
                    content: vision,
                    color: .purple
                )
            }

            // Core Values
            if let values = coreValues, !values.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Core Values")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(values, id: \.self) { value in
                            ValueChip(value: value)
                        }
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

// MARK: - Statement Card

struct StatementCard: View {
    let title: String
    let icon: String
    let content: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Value Chip

struct ValueChip: View {
    let value: String

    var body: some View {
        Text(value)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.churchTalkRed.opacity(0.1))
            .foregroundColor(.churchTalkRed)
            .cornerRadius(16)
    }
}

// Note: FlowLayout is defined in SpiritualJourneyView.swift and reused here

#Preview {
    ChurchMissionVisionSection(
        missionStatement: "To share God's love with our community and help people grow in their faith journey.",
        visionStatement: "To be a beacon of hope and transformation in our city, reaching every neighborhood with the Gospel.",
        coreValues: ["Faith", "Community", "Service", "Excellence", "Love", "Integrity", "Growth"]
    )
    .padding()
}
