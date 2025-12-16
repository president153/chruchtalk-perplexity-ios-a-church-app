import SwiftUI

struct TerritoryDetailView: View {
    let territory: Territory
    @State private var isCheckedIn = false
    @State private var isCheckingIn = false
    @State private var streets: [OutreachStreet] = []
    @State private var isLoadingStreets = true
    @State private var streetsError: String?
    @State private var collaborators: [ActiveCollaborator] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Check In Button
                Button(action: { toggleCheckIn() }) {
                    HStack {
                        if isCheckingIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: isCheckedIn ? "checkmark.circle.fill" : "location.circle")
                            Text(isCheckedIn ? "Checked In" : "Check In to Territory")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCheckedIn ? Color.green : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isCheckingIn)
                .padding(.horizontal)

                // Active Collaborators
                if isCheckedIn && !collaborators.isEmpty {
                    CollaboratorsView(collaborators: collaborators)
                }

                // Streets List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Streets")
                            .font(.headline)
                        Spacer()
                        if !isLoadingStreets {
                            Text("\(streets.count) streets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    if isLoadingStreets {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    } else if let error = streetsError {
                        VStack(spacing: 12) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("Retry") {
                                Task { await loadStreets() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else if streets.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "road.lanes")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("No streets in this territory")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        ForEach(streets) { street in
                            NavigationLink(destination: StreetDetailView(street: street)) {
                                StreetRow(street: street)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(territory.name)
        .task {
            await loadStreets()
            await loadCollaborators()
        }
        .refreshable {
            await loadStreets()
            await loadCollaborators()
        }
    }

    private func toggleCheckIn() {
        isCheckingIn = true

        Task {
            do {
                if isCheckedIn {
                    _ = try await OutreachAPI.shared.checkoutFromTerritory(id: territory.id)
                    await MainActor.run {
                        isCheckedIn = false
                        isCheckingIn = false
                    }
                } else {
                    _ = try await OutreachAPI.shared.checkinToTerritory(id: territory.id)
                    await MainActor.run {
                        isCheckedIn = true
                        isCheckingIn = false
                    }
                    await loadCollaborators()
                }
            } catch {
                print("Failed to toggle check-in: \(error)")
                await MainActor.run {
                    isCheckingIn = false
                }
            }
        }
    }

    private func loadStreets() async {
        await MainActor.run {
            isLoadingStreets = true
            streetsError = nil
        }

        do {
            let fetchedStreets = try await OutreachAPI.shared.getStreets(territoryId: territory.id)
            await MainActor.run {
                streets = fetchedStreets
                isLoadingStreets = false
            }
        } catch {
            print("Failed to load streets: \(error)")
            await MainActor.run {
                streetsError = "Failed to load streets"
                isLoadingStreets = false
            }
        }
    }

    private func loadCollaborators() async {
        do {
            let fetchedCollaborators = try await OutreachAPI.shared.getCollaborators(territoryId: territory.id)
            await MainActor.run {
                collaborators = fetchedCollaborators
            }
        } catch {
            print("Failed to load collaborators: \(error)")
        }
    }
}

struct CollaboratorsView: View {
    let collaborators: [ActiveCollaborator]

    private let displayLimit = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Now")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: -8) {
                ForEach(Array(collaborators.prefix(displayLimit))) { collaborator in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(collaborator.memberInitials)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 2)
                        )
                }

                if collaborators.count > displayLimit {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("+\(collaborators.count - displayLimit)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                }
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

// Preview disabled - Territory requires API response format
