//
//  BibleReferenceChip.swift
//  ChurchTalkAdmin
//
//  Bible reference chip component
//

import SwiftUI

struct BibleReferenceChip: View {
    let reference: String
    let version: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "book.fill")
                .font(.system(size: 11))

            Text(reference)
                .font(.system(size: 12, weight: .semibold))

            if let version = version {
                Text("(\(version))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondaryText)
            }
        }
        .foregroundColor(.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Color.managementColor.opacity(0.1)
        )
        .cornerRadius(16)
    }
}

// MARK: - Preview
#if DEBUG
struct BibleReferenceChip_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            BibleReferenceChip(reference: "John 3:16", version: "NIV")
            BibleReferenceChip(reference: "Psalm 23:1-6", version: "ESV")
            BibleReferenceChip(reference: "Romans 8:28", version: nil)
        }
        .padding()
        .background(Color.secondaryBackground)
        .previewLayout(.sizeThatFits)
    }
}
#endif
