import SwiftUI
import Combine

struct ChurchSearchView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var selectedChurch: Church? = nil

    // Demo churches
    let churches: [Church] = [
        Church(id: "1", name: "First Baptist Church", city: "Lancaster", state: "CA", memberCount: 500),
        Church(id: "2", name: "Grace Community Church", city: "Palmdale", state: "CA", memberCount: 350),
        Church(id: "3", name: "New Life Fellowship", city: "Lancaster", state: "CA", memberCount: 200),
        Church(id: "4", name: "Valley Church", city: "Bakersfield", state: "CA", memberCount: 800),
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
