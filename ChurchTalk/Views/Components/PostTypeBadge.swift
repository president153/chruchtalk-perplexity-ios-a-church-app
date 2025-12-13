//
//  PostTypeBadge.swift
//  ChurchTalkAdmin
//
//  Post type badge component
//

import SwiftUI

struct PostTypeBadge: View {
    let postType: PostType
    let isPinned: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Post type badge
            HStack(spacing: 6) {
                Image(systemName: postType.icon)
                    .font(.system(size: 10, weight: .semibold))

                Text(postType.displayName.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(postType.color)
            .cornerRadius(6)

            // Pinned badge
            if isPinned {
                HStack(spacing: 4) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                    Text("PINNED")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.orange)
                .cornerRadius(6)
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct PostTypeBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            PostTypeBadge(postType: .announcement, isPinned: true)
            PostTypeBadge(postType: .prayer, isPinned: false)
            PostTypeBadge(postType: .testimony, isPinned: false)
            PostTypeBadge(postType: .devotional, isPinned: false)
        }
        .padding()
        .background(Color.secondaryBackground)
        .previewLayout(.sizeThatFits)
    }
}
#endif
