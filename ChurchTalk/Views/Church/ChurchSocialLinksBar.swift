import SwiftUI

struct ChurchSocialLinksBar: View {
    let socialLinks: ChurchSocialLinks?

    var body: some View {
        if let links = socialLinks, links.hasSocialLinks {
            VStack(alignment: .leading, spacing: 12) {
                Text("Connect With Us")
                    .font(.headline)

                HStack(spacing: 16) {
                    if let facebook = links.facebook {
                        SocialLinkButton(
                            platform: .facebook,
                            url: facebook
                        )
                    }

                    if let instagram = links.instagram {
                        SocialLinkButton(
                            platform: .instagram,
                            url: instagram
                        )
                    }

                    if let twitter = links.twitter {
                        SocialLinkButton(
                            platform: .twitter,
                            url: twitter
                        )
                    }

                    if let youtube = links.youtube {
                        SocialLinkButton(
                            platform: .youtube,
                            url: youtube
                        )
                    }

                    if let tiktok = links.tiktok {
                        SocialLinkButton(
                            platform: .tiktok,
                            url: tiktok
                        )
                    }

                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

enum SocialPlatform {
    case facebook
    case instagram
    case twitter
    case youtube
    case tiktok

    var name: String {
        switch self {
        case .facebook: return "Facebook"
        case .instagram: return "Instagram"
        case .twitter: return "X"
        case .youtube: return "YouTube"
        case .tiktok: return "TikTok"
        }
    }

    var iconName: String {
        switch self {
        case .facebook: return "f.circle.fill"
        case .instagram: return "camera.circle.fill"
        case .twitter: return "at.circle.fill"
        case .youtube: return "play.rectangle.fill"
        case .tiktok: return "music.note.list"
        }
    }

    var color: Color {
        switch self {
        case .facebook: return Color(red: 0.23, green: 0.35, blue: 0.60)
        case .instagram: return Color(red: 0.88, green: 0.19, blue: 0.42)
        case .twitter: return .black
        case .youtube: return .red
        case .tiktok: return .black
        }
    }
}

struct SocialLinkButton: View {
    let platform: SocialPlatform
    let url: String

    var body: some View {
        Button {
            openLink()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(platform.color.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: platform.iconName)
                        .font(.title2)
                        .foregroundColor(platform.color)
                }

                Text(platform.name)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func openLink() {
        var finalUrl = url
        if !url.hasPrefix("http") {
            finalUrl = "https://\(url)"
        }
        if let url = URL(string: finalUrl) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ChurchSocialLinksBar(
        socialLinks: ChurchSocialLinks(
            facebook: "https://facebook.com/firstbaptist",
            instagram: "https://instagram.com/firstbaptist",
            twitter: "https://x.com/firstbaptist",
            youtube: "https://youtube.com/@firstbaptist"
        )
    )
    .padding()
}
