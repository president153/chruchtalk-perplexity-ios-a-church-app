import SwiftUI

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
}

struct QuickActionsRow: View {
    @State private var showPrayerSheet = false
    @State private var showGiveSheet = false
    @State private var showEventsSheet = false
    @State private var showBibleSheet = false
    @State private var showWatchSheet = false
    @State private var showConnectSheet = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "Bible",
                    icon: "book.fill",
                    color: .purple
                ) {
                    showBibleSheet = true
                }

                QuickActionButton(
                    title: "Prayer",
                    icon: "hands.sparkles.fill",
                    color: .churchTalkRed
                ) {
                    showPrayerSheet = true
                }

                QuickActionButton(
                    title: "Give",
                    icon: "heart.fill",
                    color: .green
                ) {
                    showGiveSheet = true
                }

                QuickActionButton(
                    title: "Events",
                    icon: "calendar",
                    color: .blue
                ) {
                    showEventsSheet = true
                }

                QuickActionButton(
                    title: "Watch",
                    icon: "play.rectangle.fill",
                    color: .red
                ) {
                    showWatchSheet = true
                }

                QuickActionButton(
                    title: "Connect",
                    icon: "person.2.fill",
                    color: .orange
                ) {
                    showConnectSheet = true
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showPrayerSheet) {
            PrayerWallView()
        }
        .sheet(isPresented: $showEventsSheet) {
            EventsTabView()
        }
        .sheet(isPresented: $showGiveSheet) {
            GiveSheet()
        }
        .sheet(isPresented: $showBibleSheet) {
            BibleSheet()
        }
        .sheet(isPresented: $showWatchSheet) {
            WatchSheet()
        }
        .sheet(isPresented: $showConnectSheet) {
            ConnectSheet()
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Note: ScaleButtonStyle is defined in Components/ScaleButtonStyle.swift

// Placeholder sheets
struct GiveSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Online Giving")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Support our church's mission through secure online giving.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Button(action: {
                    // Open giving portal
                }) {
                    Text("Give Now")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Give")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct BibleSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedReading = 0

    let dailyReadings = [
        ("Psalm 23", "The Lord is my shepherd; I shall not want..."),
        ("John 3:16", "For God so loved the world that he gave his one and only Son..."),
        ("Romans 8:28", "And we know that in all things God works for the good...")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Daily Verse Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.orange)
                            Text("Today's Reading")
                                .font(.headline)
                        }

                        Text(dailyReadings[0].0)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(dailyReadings[0].1)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Reading Plan
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reading Plan")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(0..<3) { day in
                            HStack {
                                Circle()
                                    .fill(day == 0 ? Color.purple : Color.gray.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: day == 0 ? "checkmark" : "\(day + 1).circle")
                                            .font(.caption)
                                            .foregroundColor(day == 0 ? .white : .secondary)
                                    )

                                VStack(alignment: .leading) {
                                    Text("Day \(day + 1)")
                                        .fontWeight(.medium)
                                    Text(dailyReadings[day].0)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if day == 0 {
                                    Text("Complete")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }

                    // External Link
                    Button {
                        if let url = URL(string: "https://www.bible.com") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text("Open YouVersion Bible App")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("Bible")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct WatchSheet: View {
    @Environment(\.dismiss) var dismiss

    let sermons = [
        ("Walking in Faith", "Pastor John Smith", "Dec 8, 2024", "45:32"),
        ("The Christmas Story", "Pastor John Smith", "Dec 1, 2024", "52:18"),
        ("Gratitude in All Things", "Pastor Sarah Johnson", "Nov 24, 2024", "38:45")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Live Now Banner (if applicable)
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        Text("Live Sunday at 10:00 AM")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Button("Set Reminder") {
                            // Set notification reminder
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Latest Sermon - Featured
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(
                                    colors: [.red.opacity(0.8), .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 180)

                            VStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)

                                Text("Watch Latest")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }

                        Text(sermons[0].0)
                            .font(.title3)
                            .fontWeight(.bold)

                        HStack {
                            Text(sermons[0].1)
                            Text("•")
                            Text(sermons[0].2)
                            Spacer()
                            Text(sermons[0].3)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Recent Sermons
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Sermons")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(1..<sermons.count, id: \.self) { index in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 80, height: 50)
                                    .overlay(
                                        Image(systemName: "play.fill")
                                            .foregroundColor(.red)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sermons[index].0)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text("\(sermons[index].1) • \(sermons[index].2)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text(sermons[index].3)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }

                    // YouTube/External Link
                    Button {
                        if let url = URL(string: "https://www.youtube.com") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                            Text("Watch on YouTube")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top)
            }
            .navigationTitle("Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ConnectSheet: View {
    @Environment(\.dismiss) var dismiss

    let groups = [
        ("Young Adults", "Fridays at 7 PM", "house.fill", 12),
        ("Men's Bible Study", "Saturdays at 8 AM", "book.fill", 8),
        ("Women's Fellowship", "Wednesdays at 10 AM", "heart.fill", 15),
        ("Marriage Ministry", "1st Sunday Monthly", "person.2.fill", 20)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)

                        Text("Find Your Community")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Join a small group and grow together in faith")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    // Small Groups
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Small Groups")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(groups, id: \.0) { group in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.orange.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: group.2)
                                            .foregroundColor(.orange)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.0)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    Text(group.1)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(group.3)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    Text("members")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }

                    // Interest Form
                    VStack(spacing: 12) {
                        Text("Not sure which group?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button {
                            // Open interest form
                        } label: {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Get Connected")
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Connect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    QuickActionsRow()
}
