import SwiftUI

struct NewPrayerRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var isAnonymous = false
    @State private var isSubmitting = false

    var isValid: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                } header: {
                    Text("Your Prayer Request")
                } footer: {
                    Text("Share what's on your heart. Our church family will lift you up in prayer.")
                }

                Section {
                    Toggle("Post Anonymously", isOn: $isAnonymous)
                } footer: {
                    Text(isAnonymous ? "Your name will be hidden from others." : "Your name will be visible to other members.")
                }
            }
            .navigationTitle("New Prayer Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: submitRequest) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit")
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid || isSubmitting)
                }
            }
        }
    }

    private func submitRequest() {
        isSubmitting = true
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSubmitting = false
            dismiss()
        }
    }
}

#Preview {
    NewPrayerRequestView()
}
