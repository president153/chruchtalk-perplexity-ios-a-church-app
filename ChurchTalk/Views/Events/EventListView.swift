import SwiftUI

struct EventListView: View {
    let events: [ChurchEvent]
    let onEventTap: (ChurchEvent) -> Void

    var body: some View {
        if events.isEmpty {
            ContentUnavailableView(
                "No Events",
                systemImage: "calendar.badge.exclamationmark",
                description: Text("There are no upcoming events in this category.")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Featured Events
                    let featured = events.filter { $0.isFeatured }
                    if !featured.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Featured")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(featured) { event in
                                        FeaturedEventCard(event: event) {
                                            onEventTap(event)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Upcoming Events
                    let upcoming = events.filter { $0.isUpcoming && !$0.isFeatured }
                    if !upcoming.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upcoming")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(upcoming) { event in
                                EventCard(event: event) {
                                    onEventTap(event)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Past Events (collapsed by default)
                    let past = events.filter { $0.isPast }
                    if !past.isEmpty {
                        DisclosureGroup("Past Events (\(past.count))") {
                            ForEach(past) { event in
                                EventCard(event: event, isPast: true) {
                                    onEventTap(event)
                                }
                            }
                        }
                        .padding()
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

struct EventCard: View {
    let event: ChurchEvent
    var isPast: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Date Box
                VStack(spacing: 2) {
                    Text(event.startDate.formatted(.dateTime.month(.abbreviated)))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isPast ? .gray : .churchTalkRed)
                    Text(event.startDate.formatted(.dateTime.day()))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isPast ? .gray : .primary)
                }
                .frame(width: 50)
                .padding(.vertical, 8)
                .background(isPast ? Color.gray.opacity(0.1) : Color.churchTalkRed.opacity(0.1))
                .cornerRadius(8)

                // Event Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.title)
                            .font(.headline)
                            .foregroundColor(isPast ? .gray : .primary)
                            .lineLimit(1)

                        Spacer()

                        // Category Badge
                        Text(event.category.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(event.category.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(event.category.color.opacity(0.1))
                            .cornerRadius(4)
                    }

                    HStack(spacing: 12) {
                        // Time
                        Label(event.timeDisplayString, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Location
                        if let location = event.location?.name {
                            Label(location, systemImage: "mappin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    // Registration Info
                    if event.requiresRegistration {
                        HStack {
                            if event.isFull {
                                Label("Full", systemImage: "person.fill.xmark")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else if let remaining = event.spotsRemaining {
                                Label("\(remaining) spots left", systemImage: "person.badge.plus")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isPast ? 0.7 : 1)
    }
}

struct FeaturedEventCard: View {
    let event: ChurchEvent
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image or Gradient
                ZStack(alignment: .bottomLeading) {
                    if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(event.category.color.gradient)
                        }
                    } else {
                        Rectangle()
                            .fill(event.category.color.gradient)
                            .overlay(
                                Image(systemName: event.category.iconName)
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }

                    // Date Badge
                    VStack(spacing: 0) {
                        Text(event.startDate.formatted(.dateTime.month(.abbreviated)))
                            .font(.caption2)
                            .fontWeight(.semibold)
                        Text(event.startDate.formatted(.dateTime.day()))
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(12)
                }
                .frame(width: 250, height: 140)
                .clipped()

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(event.timeDisplayString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EventListView(events: ChurchEvent.sampleEvents) { event in
        print("Selected: \(event.title)")
    }
}
