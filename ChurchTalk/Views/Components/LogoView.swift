//
//  LogoView.swift
//  ChurchTalk
//
//  Branded logo component for the member app
//

import SwiftUI

struct LogoView: View {
    var subtitle: String? = "Member"
    var size: LogoSize = .medium

    enum LogoSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 48
            case .large: return 64
            }
        }

        var titleSize: CGFloat {
            switch self {
            case .small: return 18
            case .medium: return 24
            case .large: return 32
            }
        }

        var subtitleSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }

        var iconFontSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(Color.churchTalkRed)
                    .frame(width: size.iconSize, height: size.iconSize)

                Image(systemName: "cross.fill")
                    .font(.system(size: size.iconFontSize))
                    .foregroundColor(.white)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text("ChurchTalk")
                    .font(.system(size: size.titleSize, weight: .bold))
                    .foregroundColor(.primaryText)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: size.subtitleSize))
                        .foregroundColor(.secondaryText)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        LogoView(size: .small)
        LogoView(size: .medium)
        LogoView(size: .large)
        LogoView(subtitle: nil, size: .medium)
    }
    .padding()
}
