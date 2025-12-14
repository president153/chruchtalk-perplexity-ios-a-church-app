import SwiftUI
import Combine

struct ChurchSearchView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var selectedChurch: Church? = nil

    // Churches (single church for now - will fetch from API later)
    let churches: [Church] = [
        Church(id: "000000000000000000000003", name: "Norwalk Baptist Church", city: "Norwalk", state: "CA", memberCount: 150),
    ]

    var filteredChurches: [Church] {
        if searchText.isEmpty {
            return churches
        }
        return churches.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.city.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredChurches) { church in
                Button {
                    selectedChurch = church
                } label: {
                    ChurchRow(church: church)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Find Your Church")
        .searchable(text: $searchText, prompt: "Search by name or city")
        .sheet(item: $selectedChurch) { church in
            ChurchDetailView(church: church)
                .environmentObject(authViewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteMemberJoinFlow)) { _ in
            // Dismiss sheet when member join flow completes
            selectedChurch = nil
        }
    }
}

struct ChurchRow: View {
    let church: Church

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.churchTalkRed.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: "building.columns.fill")
                    .foregroundColor(.churchTalkRed)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(church.name)
                    .font(.headline)

                Text("\(church.city), \(church.state)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(church.memberCount) members")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ChurchSearchView()
    }
}
