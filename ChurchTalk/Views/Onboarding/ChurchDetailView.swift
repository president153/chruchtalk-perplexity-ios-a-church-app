import SwiftUI
import Combine

struct ChurchDetailView: View {
    let church: Church
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showJoinRequest = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Cover Image / Banner
                    ZStack(alignment: .bottomLeading) {
                        if let coverUrl = church.coverImageUrl, let url = URL(string: coverUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                defaultBanner
                            }
                            .frame(height: 200)
                            .clipped()
                        } else {
                            defaultBanner
                        }

                        // Gradient overlay
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 200)

                        // Church Logo overlay
                        HStack {
                            if let logoUrl = church.imageUrl, let url = URL(string: logoUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    defaultLogo
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(radius: 5)
                            } else {
                                defaultLogo
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white, lineWidth: 3)
                                    )
                                    .shadow(radius: 5)
                            }
                            Spacer()
                        }
                        .padding()
                        .offset(y: 40)
                    }

                    // Content
                    VStack(spacing: 20) {
                        // Header Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(church.name)
                                .font(.title)
                                .fontWeight(.bold)

                            if let denomination = church.denomination {
                                Text(denomination)
                                    .font(.subheadline)
                                    .foregroundColor(.churchTalkRed)
                            }

                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.churchTalkRed)
                                Text(church.locationString.isEmpty ? "\(church.city), \(church.state)" : church.locationString)
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 50)
                        .padding(.horizontal)

                        // Stats Row
                        HStack(spacing: 24) {
                            StatBox(value: "\(church.memberCount)", label: "Members")

                            if let foundedYear = church.foundedYear {
                                Divider().frame(height: 40)
                                StatBox(value: "\(foundedYear)", label: "Founded")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // About Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)

                            if let about = church.aboutContent ?? church.description {
                                Text(about)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Welcome to \(church.name). We are a community of believers dedicated to sharing God's love.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)

                        // Service Times
                        ChurchServiceTimesView(serviceTimes: church.serviceTimes)
                            .padding(.horizontal)

                        // Leadership Section (if data exists)
                        if church.hasLeadership {
                            ChurchLeadershipSection(
                                pastor: church.pastor,
                                leadershipTeam: church.leadershipTeam
                            )
                            .padding(.horizontal)
                        }

                        // Mission & Vision Section (if data exists)
                        if church.hasMissionVision {
                            ChurchMissionVisionSection(
                                missionStatement: church.missionStatement,
                                visionStatement: church.visionStatement,
                                coreValues: church.coreValues
                            )
                            .padding(.horizontal)
                        }

                        // Ministries Section (if data exists)
                        if church.hasMinistries, let ministries = church.ministries {
                            ChurchMinistriesSection(ministries: ministries)
                                .padding(.horizontal)
                        }

                        // Contact Section
                        ChurchContactSection(
                            contactInfo: church.contactInfo,
                            address: church.address,
                            websiteUrl: church.websiteUrl
                        )
                        .padding(.horizontal)

                        // Social Links
                        ChurchSocialLinksBar(socialLinks: church.socialLinks)
                            .padding(.horizontal)

                        // Join Button
                        Button(action: { showJoinRequest = true }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Request to Join")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.churchTalkRed)
                            .cornerRadius(ChurchTalkTheme.cornerRadius)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showJoinRequest) {
                NavigationStack {
                    JoinRequestView(church: church)
                        .environmentObject(authViewModel)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .didCompleteMemberJoinFlow)) { _ in
                // Dismiss sheets when member join flow completes
                showJoinRequest = false
                dismiss()
            }
        }
    }

    private var defaultBanner: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [.churchTalkRedLight, .churchTalkRed],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(height: 200)
            .overlay(
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.3))
            )
    }

    private var defaultLogo: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "building.columns.fill")
                    .font(.title)
                    .foregroundColor(.churchTalkRed)
            )
    }
}

struct StatBox: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.churchTalkRed)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ChurchDetailView(
        church: Church(
            id: "1",
            name: "First Baptist Church",
            city: "Lancaster",
            state: "CA",
            memberCount: 500,
            description: "A welcoming community dedicated to sharing God's love and growing together in faith. We believe in the transformative power of the Gospel and strive to be a light in our community.",
            serviceTimes: [
                ServiceTime(day: "Sunday", time: "9:00 AM", serviceName: "Early Service"),
                ServiceTime(day: "Sunday", time: "11:00 AM", serviceName: "Main Service"),
                ServiceTime(day: "Wednesday", time: "7:00 PM", serviceName: "Bible Study")
            ],
            contactInfo: ChurchContactInfo(
                phone: "(661) 555-1234",
                email: "info@firstbaptist.org",
                officeHours: "Mon-Fri 9am-5pm"
            ),
            socialLinks: ChurchSocialLinks(
                facebook: "https://facebook.com/firstbaptist",
                instagram: "https://instagram.com/firstbaptist",
                youtube: "https://youtube.com/@firstbaptist"
            ),
            websiteUrl: "https://firstbaptist.org",
            foundedYear: 1952,
            denomination: "Southern Baptist"
        )
    )
    .environmentObject(AuthViewModel())
}
