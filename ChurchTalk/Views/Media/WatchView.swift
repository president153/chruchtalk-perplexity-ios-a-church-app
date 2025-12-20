//
//  WatchView.swift
//  ChurchTalk
//
//  Watch sermons and media content from the church.
//

import SwiftUI

struct WatchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var featuredMedia: FeaturedMedia?
    @State private var mediaList: [FeaturedMedia] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        VStack {
                            Spacer(minLength: 100)
                            ProgressView()
                            Spacer(minLength: 100)
                        }
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Spacer(minLength: 80)
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text(error)
                                .foregroundColor(.secondary)
                            Button("Retry") {
                                Task { await loadMedia() }
                            }
                            .buttonStyle(.bordered)
                            Spacer(minLength: 80)
                        }
                    } else {
                        // Live/Featured Banner
                        if let featured = featuredMedia, featured.isLive {
                            LiveBanner(media: featured)
                                .padding(.horizontal)
                        }

                        // Featured Sermon
                        if let featured = featuredMedia {
                            FeaturedSermonCard(media: featured)
                                .padding(.horizontal)
                        }

                        // Recent Sermons
                        if !mediaList.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Sermons")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(mediaList.filter { $0.id != featuredMedia?.id }) { media in
                                    SermonRow(media: media)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        // Empty State
                        if mediaList.isEmpty && featuredMedia == nil {
                            VStack(spacing: 16) {
                                Image(systemName: "play.tv")
                                    .font(.system(size: 60))
                                    .foregroundColor(.red.opacity(0.6))
                                Text("No Sermons Available")
                                    .font(.headline)
                                Text("Check back soon for new content")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 60)
                        }
                    }

                    Spacer(minLength: 40)
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
            .task {
                await loadMedia()
            }
            .refreshable {
                await loadMedia()
            }
        }
    }

    private func loadMedia() async {
        isLoading = true
        errorMessage = nil

        do {
            async let featuredTask = MediaAPI.shared.getFeaturedMedia()
            async let listTask = MediaAPI.shared.getMedia(mediaType: .sermon, limit: 20)

            let (featured, list) = try await (featuredTask, listTask)

            await MainActor.run {
                featuredMedia = featured
                mediaList = list
                isLoading = false
            }
        } catch {
            print("Failed to load media: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load sermons"
                isLoading = false
            }
        }
    }
}

// MARK: - Live Banner

private struct LiveBanner: View {
    let media: FeaturedMedia

    var body: some View {
        Button {
            openMedia(media)
        } label: {
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)

                Text("LIVE NOW")
                    .font(.subheadline)
                    .fontWeight(.bold)

                Text("- \(media.title)")
                    .font(.subheadline)
                    .lineLimit(1)

                Spacer()

                Text("Watch")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.red)
            .cornerRadius(12)
        }
    }
}

// MARK: - Featured Sermon Card

private struct FeaturedSermonCard: View {
    let media: FeaturedMedia

    var body: some View {
        Button {
            openMedia(media)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail
                ZStack {
                    if let thumbnailUrl = media.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        } placeholder: {
                            thumbnailPlaceholder
                        }
                    } else {
                        thumbnailPlaceholder
                    }

                    // Play button overlay
                    Circle()
                        .fill(.white)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                                .offset(x: 2)
                        )
                        .shadow(radius: 4)
                }
                .frame(height: 200)
                .cornerRadius(16)
                .clipped()

                // Title and info
                VStack(alignment: .leading, spacing: 4) {
                    Text(media.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    HStack {
                        if let description = media.description, !description.isEmpty {
                            Text(description)
                                .lineLimit(1)
                        }

                        Spacer()

                        if let duration = media.formattedDuration {
                            Text(duration)
                                .fontWeight(.medium)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    Text(media.publishedAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [.red.opacity(0.8), .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    Text("Watch")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            )
    }
}

// MARK: - Sermon Row

private struct SermonRow: View {
    let media: FeaturedMedia

    var body: some View {
        Button {
            openMedia(media)
        } label: {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack {
                    if let thumbnailUrl = media.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            thumbnailPlaceholder
                        }
                    } else {
                        thumbnailPlaceholder
                    }

                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .frame(width: 100, height: 60)
                .cornerRadius(8)
                .clipped()

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(media.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    HStack {
                        if let description = media.description {
                            Text(description)
                                .lineLimit(1)
                        }
                        Text(media.publishedAt, style: .date)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Duration
                if let duration = media.formattedDuration {
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.red.opacity(0.2))
            .overlay(
                Image(systemName: "play.fill")
                    .foregroundColor(.red)
            )
    }
}

// MARK: - Helper

private func openMedia(_ media: FeaturedMedia) {
    if let url = media.mediaURL {
        UIApplication.shared.open(url)
    }
}

#Preview {
    WatchView()
}
