import SwiftUI

struct DoorKnockingView: View {
    let door: OutreachDoor
    var onDoorUpdated: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStatus: DoorStatus = .notVisited
    @State private var residentName = ""
    @State private var phone = ""
    @State private var notes = ""
    @State private var showAddToSRM = false
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Address Header
                    VStack(spacing: 8) {
                        Text("#\(door.houseNumber)")
                            .font(.system(size: 48, weight: .bold))

                        Text(door.fullAddress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Outcome Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Outcome")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            OutcomeButton(status: .notHome, isSelected: selectedStatus == .notHome) {
                                selectedStatus = .notHome
                            }
                            OutcomeButton(status: .notInterested, isSelected: selectedStatus == .notInterested) {
                                selectedStatus = .notInterested
                            }
                            OutcomeButton(status: .interested, isSelected: selectedStatus == .interested) {
                                selectedStatus = .interested
                            }
                            OutcomeButton(status: .followUp, isSelected: selectedStatus == .followUp) {
                                selectedStatus = .followUp
                            }
                            OutcomeButton(status: .alreadyMember, isSelected: selectedStatus == .alreadyMember) {
                                selectedStatus = .alreadyMember
                            }
                            OutcomeButton(status: .doNotContact, isSelected: selectedStatus == .doNotContact) {
                                selectedStatus = .doNotContact
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Resident Info (for interested/follow-up)
                    if selectedStatus == .interested || selectedStatus == .followUp {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Resident Information")
                                .font(.headline)

                            TextField("Name", text: $residentName)
                                .textFieldStyle(.roundedBorder)

                            TextField("Phone (Optional)", text: $phone)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.phonePad)

                            TextField("Notes", text: $notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal)
                    }

                    // Notes (for other statuses)
                    if selectedStatus != .interested && selectedStatus != .followUp && selectedStatus != .notVisited {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes (Optional)")
                                .font(.headline)

                            TextField("Add notes...", text: $notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal)
                    }

                    // Error message
                    if let error = saveError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 32)
                }
            }
            .navigationTitle("Log Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveVisit()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(selectedStatus == .notVisited || isSaving)
                }
            }
        }
    }

    private func saveVisit() {
        isSaving = true
        saveError = nil

        Task {
            do {
                _ = try await OutreachAPI.shared.updateDoor(
                    id: door.id,
                    status: selectedStatus,
                    residentName: residentName.isEmpty ? nil : residentName,
                    notes: notes.isEmpty ? nil : notes
                )

                await MainActor.run {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    isSaving = false
                    onDoorUpdated?()
                    dismiss()
                }
            } catch {
                print("Failed to save visit: \(error)")
                await MainActor.run {
                    saveError = "Failed to save. Please try again."
                    isSaving = false
                }
            }
        }
    }
}

struct OutcomeButton: View {
    let status: DoorStatus
    let isSelected: Bool
    let action: () -> Void

    var statusColor: Color {
        switch status {
        case .notVisited: return .gray
        case .notHome: return .orange
        case .interested: return .green
        case .notInterested: return .red
        case .followUp: return .purple
        case .doNotContact: return .black
        case .alreadyMember: return .blue
        }
    }

    var statusIcon: String {
        switch status {
        case .notVisited: return "circle"
        case .notHome: return "clock.fill"
        case .interested: return "star.fill"
        case .notInterested: return "xmark.circle.fill"
        case .followUp: return "arrow.clockwise.circle.fill"
        case .doNotContact: return "hand.raised.fill"
        case .alreadyMember: return "person.crop.circle.badge.checkmark"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: statusIcon)
                Text(status.displayName)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .foregroundColor(isSelected ? .white : statusColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? statusColor : statusColor.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(statusColor, lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

// Preview disabled - OutreachDoor requires API response format
