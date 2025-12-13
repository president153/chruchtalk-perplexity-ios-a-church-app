//
//  StoriesRowView.swift
//  ChurchTalkAdmin
//
//  Horizontal scrolling row of stories
//

import SwiftUI

struct StoriesRowView: View {
    let stories: [Story]
    @State private var selectedStory: Story?
    @State private var showStoryViewer = false

    // Track viewed stories (in real app, would sync with backend)
    @State private var viewedStoryIds: Set<String> = ["s4"] // Mock: mark story 4 as viewed

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Stories scroll view
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(stories) { story in
                        StoryCircle(
                            story: story,
                            isViewed: viewedStoryIds.contains(story.id)
                        ) {
                            selectedStory = story
                            showStoryViewer = true
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.cardBackground)

            // Separator
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)
        }
        .fullScreenCover(isPresented: $showStoryViewer) {
            if let story = selectedStory,
               let startIndex = stories.firstIndex(where: { $0.id == story.id }) {
                StoryViewer(
                    stories: stories,
                    startIndex: startIndex,
                    viewedStoryIds: $viewedStoryIds
                )
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct StoriesRowView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesRowView(stories: Story.mockStories())
            .background(Color.secondaryBackground)
            .previewLayout(.sizeThatFits)
    }
}
#endif
