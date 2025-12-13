import SwiftUI

struct TerritoryDetailView: View {
    let territory: Territory
    @State private var isCheckedIn = false

    // Demo streets
    let streets: [OutreachStreet] = [
        OutreachStreet(id: "1", name: "E Lingard St", completionPercent: 85),
        OutreachStreet(id: "2", name: "E Avenue J", completionPercent: 60),
        OutreachStreet(id: "3", name: "E Lancaster Blvd", completionPercent: 30),
        OutreachStreet(id: "4", name: "N 10th St W", completionPercent: 0),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Check In Button
                Button(action: { isCheckedIn.toggle() }) {
                    HStack {
                        Image(systemName: isCheckedIn ? "checkmark.circle.fill" : "location.circle")
                        Text(isCheckedIn ? "Checked In" : "Check In to Territory")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCheckedIn ? Color.green : Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Active Collaborators
                if isCheckedIn {
                    CollaboratorsView()
                }

                // Streets List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Streets")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(streets) { street in
                        NavigationLink(destination: StreetDetailView(street: street)) {
                            StreetRow(street: street)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(territory.name)
    }
}

struct CollaboratorsView: View {
    let collaborators = ["JD", "SM", "KL"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Now")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: -8) {
                ForEach(collaborators, id: \.self) { initials in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(initials)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 2)
                        )
                }

                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("+2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StreetRow: View {
    let street: OutreachStreet

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(street.name)
                    .font(.headline)

                HStack(spacing: 4) {
                    Text("\(Int(street.completionPercent))% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Mini progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: street.completionPercent / 100)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(street.completionPercent))")
                    .font(.caption2)
                    .fontWeight(.medium)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        TerritoryDetailView(territory: Territory(id: "1", name: "Downtown Lancaster", status: .inProgress, progress: 45))
    }
}
