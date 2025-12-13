import SwiftUI

struct ChurchServiceTimesView: View {
    let serviceTimes: [ServiceTime]?

    var body: some View {
        if let times = serviceTimes, !times.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Service Times")
                    .font(.headline)

                VStack(spacing: 8) {
                    ForEach(times) { service in
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.churchTalkRed)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(service.day)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                if let name = service.serviceName {
                                    Text(name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Text(service.time)
                                .font(.subheadline)
                                .foregroundColor(.churchTalkRed)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 8)

                        if service.id != times.last?.id {
                            Divider()
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
}

#Preview {
    ChurchServiceTimesView(
        serviceTimes: [
            ServiceTime(day: "Sunday", time: "9:00 AM", serviceName: "Early Service"),
            ServiceTime(day: "Sunday", time: "11:00 AM", serviceName: "Main Service"),
            ServiceTime(day: "Wednesday", time: "7:00 PM", serviceName: "Bible Study")
        ]
    )
    .padding()
}
