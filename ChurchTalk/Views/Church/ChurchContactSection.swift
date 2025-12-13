import SwiftUI

struct ChurchContactSection: View {
    let contactInfo: ChurchContactInfo?
    let address: ChurchAddress?
    let websiteUrl: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                // Phone
                if let phone = contactInfo?.phone {
                    ContactRow(
                        icon: "phone.fill",
                        label: "Phone",
                        value: phone,
                        color: .amenGreen
                    ) {
                        if let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                // Email
                if let email = contactInfo?.email {
                    ContactRow(
                        icon: "envelope.fill",
                        label: "Email",
                        value: email,
                        color: .churchTalkRed
                    ) {
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                // Website
                if let website = websiteUrl {
                    ContactRow(
                        icon: "globe",
                        label: "Website",
                        value: website.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: ""),
                        color: .blue
                    ) {
                        if let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                // Address
                if let addr = address, !addr.formatted.isEmpty {
                    ContactRow(
                        icon: "mappin.circle.fill",
                        label: "Address",
                        value: addr.formatted,
                        color: .orange
                    ) {
                        // Open in Maps
                        if addr.hasCoordinates, let lat = addr.latitude, let lng = addr.longitude {
                            let url = URL(string: "maps://?ll=\(lat),\(lng)")!
                            UIApplication.shared.open(url)
                        } else {
                            let query = addr.formatted.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "maps://?q=\(query)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }

                // Office Hours
                if let hours = contactInfo?.officeHours {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Office Hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(hours)
                                .font(.subheadline)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ContactRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ChurchContactSection(
        contactInfo: ChurchContactInfo(
            phone: "(661) 555-1234",
            email: "info@firstbaptist.org",
            officeHours: "Mon-Fri 9am-5pm"
        ),
        address: ChurchAddress(
            street: "123 Main Street",
            city: "Lancaster",
            state: "CA",
            zipCode: "93534"
        ),
        websiteUrl: "https://firstbaptist.org"
    )
    .padding()
}
