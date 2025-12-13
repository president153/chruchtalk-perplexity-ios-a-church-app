import SwiftUI

struct ContactUsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackType = "General"
    @State private var message = ""
    @State private var showConfirmation = false

    let feedbackTypes = ["General", "Bug Report", "Feature Request", "Question"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $feedbackType) {
                        ForEach(feedbackTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                } header: {
                    Text("Feedback Type")
                }

                Section {
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                } header: {
                    Text("Your Message")
                }

                Section {
                    Button {
                        submitFeedback()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Submit Feedback")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(message.isEmpty)
                }

                Section {
                    Button {
                        openEmail()
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.churchTalkRed)
                            Text("support@churchtalk.app")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        openTwitter()
                    } label: {
                        HStack {
                            Image(systemName: "at.circle.fill")
                                .foregroundColor(.black)
                            Text("@ChurchTalkApp")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Other Ways to Reach Us")
                }
            }
            .navigationTitle("Contact Us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Feedback Sent", isPresented: $showConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for your feedback! We'll get back to you soon.")
            }
        }
    }

    private func submitFeedback() {
        // In production, send to API
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        showConfirmation = true
    }

    private func openEmail() {
        if let url = URL(string: "mailto:support@churchtalk.app") {
            UIApplication.shared.open(url)
        }
    }

    private func openTwitter() {
        if let url = URL(string: "https://twitter.com/ChurchTalkApp") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ContactUsView()
}
