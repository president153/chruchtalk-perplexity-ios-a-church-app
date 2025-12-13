import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    @AppStorage("accentColorChoice") private var accentColorChoice = "red"

    let appearanceOptions = [
        ("system", "System", "iphone"),
        ("light", "Light", "sun.max.fill"),
        ("dark", "Dark", "moon.fill")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(appearanceOptions, id: \.0) { option in
                        Button {
                            appearanceMode = option.0
                        } label: {
                            HStack {
                                Image(systemName: option.2)
                                    .foregroundColor(.churchTalkRed)
                                    .frame(width: 24)

                                Text(option.1)
                                    .foregroundColor(.primary)

                                Spacer()

                                if appearanceMode == option.0 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.churchTalkRed)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Theme")
                } footer: {
                    Text("Choose how ChurchTalk appears on your device")
                }

                Section {
                    HStack {
                        Text("App Icon")
                        Spacer()
                        Text("Default")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Text Size")
                        Spacer()
                        Text("System")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Display")
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AppearanceSettingsView()
}
