import SwiftUI

struct UpcomingEventsCarousel: View {
    let events: [ChurchEvent]
    var onSeeAll: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("UPCOMING EVENTS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(1)

                Spacer()

                Button(action: onSeeAll) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.churchTalkRed)
                }
            }
            .padding(.horizontal)

            // Events Horizontal Scroll
            if events.isEmpty {
                EmptyEventsView()
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(events) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventCarouselCard(event: event)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct EventCarouselCard: View {
    let event: ChurchEvent
    private let cardWidth: CGFloat = 160

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Event Image or Category Icon
            ZStack {
                if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        categoryBackground
                    }
                    .frame(width: cardWidth, height: 100)
                    .clipped()
                } else {
                    categoryBackground
                }

                // Category Badge
                VStack {
                    HStack {
                        Spacer()
                        Text(event.category.rawValue.capitalized)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .cornerRadius(6)
                    }
                    Spacer()
                }
                .padding(8)
            }
            .frame(width: cardWidth, height: 100)
            .cornerRadius(12)

            // Event Info
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let location = event.location?.name {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .frame(width: cardWidth, alignment: .leading)
        }
        .frame(width: cardWidth)
    }

    private var categoryBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: categoryIcon)
                .font(.system(size: 32))
                .foregroundColor(categoryColor)
        }
        .frame(width: cardWidth, height: 100)
    }

    private var categoryColor: Color {
        switch event.category {
        case .worship: return .purple
        case .outreach: return .green
        case .youth: return .orange
        case .children: return .pink
        case .smallGroup: return .blue
        case .missions: return .teal
        case .fellowship: return .red
        case .training: return .indigo
        case .special: return .yellow
        case .other: return .gray
        }
    }

    private var categoryIcon: String {
        switch event.category {
        case .worship: return "music.note"
        case .outreach: return "heart.fill"
        case .youth: return "person.2.fill"
        case .children: return "figure.2.and.child.holdinghands"
        case .smallGroup: return "person.3.fill"
        case .missions: return "globe"
        case .fellowship: return "heart.circle.fill"
        case .training: return "graduationcap.fill"
        case .special: return "star.fill"
        case .other: return "calendar"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: event.startDate)
    }
}

struct EmptyEventsView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                    .font(.title)
                    .foregroundColor(.secondary)

                Text("No upcoming events")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        UpcomingEventsCarousel(
            events: [
                ChurchEvent(
                    id: "1",
                    churchId: "1",
                    title: "Christmas Eve Service",
                    description: "Join us for a special night",
                    startDate: Date().addingTimeInterval(86400 * 11),
                    isAllDay: false,
                    isVirtual: false,
                    requiresRegistration: true,
                    currentRegistrations: 45,
                    category: .worship,
                    tags: ["christmas"],
                    volunteerRoles: [],
                    createdAt: Date(),
                    isPublished: true,
                    isFeatured: true
                ),
                ChurchEvent(
                    id: "2",
                    churchId: "1",
                    title: "Youth Night",
                    description: "Fun and fellowship",
                    startDate: Date().addingTimeInterval(86400 * 2),
                    isAllDay: false,
                    isVirtual: false,
                    requiresRegistration: false,
                    currentRegistrations: 0,
                    category: .youth,
                    tags: [],
                    volunteerRoles: [],
                    createdAt: Date(),
                    isPublished: true,
                    isFeatured: false
                )
            ]
        )
    }
}
