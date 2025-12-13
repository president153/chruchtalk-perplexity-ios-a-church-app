//
//  StoryViewer.swift
//  ChurchTalkAdmin
//
//  Full-screen story viewer with progress bars and gestures
//

import SwiftUI

struct StoryViewer: View {
    let stories: [Story]
    let startIndex: Int

    @Binding var viewedStoryIds: Set<String>
    @State private var currentIndex: Int
    @State private var progress: Double = 0
    @State private var timer: Timer?
    @State private var isPaused = false
    @Environment(\.dismiss) var dismiss

    init(stories: [Story], startIndex: Int, viewedStoryIds: Binding<Set<String>>) {
        self.stories = stories
        self.startIndex = startIndex
        self._viewedStoryIds = viewedStoryIds
        self._currentIndex = State(initialValue: startIndex)
    }

    var currentStory: Story {
        stories[currentIndex]
    }

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            // Story content
            AsyncImage(url: URL(string: currentStory.mediaUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Failed to load story")
                            .foregroundColor(.white.opacity(0.7))
                    }
                @unknown default:
                    EmptyView()
                }
            }

            // Overlay content
            VStack {
                // Progress bars
                HStack(spacing: 4) {
                    ForEach(0..<stories.count, id: \.self) { index in
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))

                                // Progress
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: geometry.size.width * progressValue(for: index))
                            }
                        }
                        .frame(height: 3)
                        .cornerRadius(1.5)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                // Header
                HStack(spacing: 12) {
                    // Author info
                    HStack(spacing: 8) {
                        AsyncImage(url: URL(string: currentStory.authorPhotoUrl ?? "")) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 32, height: 32)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentStory.authorName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Text(currentStory.timeRemaining)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    Spacer()

                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Spacer()

                // View count
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 12))
                        Text("\(currentStory.viewCount)")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(12)
                    .padding(.trailing, 12)
                    .padding(.bottom, 16)
                }
            }

            // Tap areas for navigation
            HStack(spacing: 0) {
                // Previous story (left half)
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        previousStory()
                    }

                // Next story (right half)
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        nextStory()
                    }
            }

            // Long press to pause
            Color.clear
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 0.2, pressing: { pressing in
                    if pressing {
                        pauseStory()
                    } else {
                        resumeStory()
                    }
                }, perform: {})
        }
        .statusBar(hidden: true)
        .onAppear {
            startTimer()
            markAsViewed()
        }
        .onDisappear {
            stopTimer()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
    }

    // MARK: - Helper Methods

    private func progressValue(for index: Int) -> Double {
        if index < currentIndex {
            return 1.0
        } else if index == currentIndex {
            return progress
        } else {
            return 0.0
        }
    }

    private func startTimer() {
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if !isPaused {
                progress += 0.05 / 5.0 // 5 seconds per story
                if progress >= 1.0 {
                    nextStory()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func nextStory() {
        if currentIndex < stories.count - 1 {
            currentIndex += 1
            stopTimer()
            startTimer()
            markAsViewed()
        } else {
            dismiss()
        }
    }

    private func previousStory() {
        if currentIndex > 0 {
            currentIndex -= 1
            stopTimer()
            startTimer()
            markAsViewed()
        }
    }

    private func pauseStory() {
        isPaused = true
    }

    private func resumeStory() {
        isPaused = false
    }

    private func markAsViewed() {
        viewedStoryIds.insert(currentStory.id)
    }
}

// MARK: - Preview
#if DEBUG
struct StoryViewer_Previews: PreviewProvider {
    static var previews: some View {
        StoryViewer(
            stories: Story.mockStories(),
            startIndex: 0,
            viewedStoryIds: .constant([])
        )
    }
}
#endif
