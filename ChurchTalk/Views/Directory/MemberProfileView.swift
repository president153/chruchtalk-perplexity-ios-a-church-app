import SwiftUI

struct MemberProfileView: View {
    let member: Member

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.churchTalkRed.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(member.initials)
                                .font(.largeTitle)
                                .foregroundColor(.churchTalkRed)
                        )

                    VStack(spacing: 4) {
                        Text(member.fullName)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(member.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)

                // Contact Actions
                HStack(spacing: 24) {
                    ContactButton(icon: "phone.fill", label: "Call", color: .amenGreen) {
                        makeCall()
                    }
                    ContactButton(icon: "message.fill", label: "Text", color: .churchTalkRed) {
                        sendText()
                    }
                    ContactButton(icon: "envelope.fill", label: "Email", color: .orange) {
                        sendEmail()
                    }
                }

                // Ministries
                if !member.ministries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ministries")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(member.ministries, id: \.self) { ministry in
                                Text(ministry)
                                    .font(.subheadline)
                                    .foregroundColor(.churchTalkRed)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.churchTalkRed.opacity(0.1))
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                // Contact Info Card
                VStack(spacing: 0) {
                    ContactInfoRow(icon: "envelope.fill", title: "Email", value: member.email) {
                        sendEmail()
                    }

                    Divider().padding(.leading, 56)

                    if let phone = member.phone {
                        ContactInfoRow(icon: "phone.fill", title: "Phone", value: phone) {
                            makeCall()
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Actions

    private func makeCall() {
        if let phone = member.phone {
            // Clean phone number
            let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if let url = URL(string: "tel://\(cleaned)") {
                UIApplication.shared.open(url)
            }
        }
    }

    private func sendText() {
        if let phone = member.phone {
            let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if let url = URL(string: "sms:\(cleaned)") {
                UIApplication.shared.open(url)
            }
        }
    }

    private func sendEmail() {
        if let url = URL(string: "mailto:\(member.email)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Contact Button

struct ContactButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                Text(label)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Contact Info Row

struct ContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(.churchTalkRed)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.body)
                        .foregroundColor(.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// FlowLayout is defined in SpiritualJourneyView.swift

#Preview {
    NavigationStack {
        MemberProfileView(member: Member(
            id: "1",
            firstName: "John",
            lastName: "Anderson",
            email: "john@church.org",
            phone: "(555) 123-4567",
            churchId: "1",
            ministries: ["Worship", "Ushers", "Outreach"]
        ))
    }
}
