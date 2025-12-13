//
//  ErrorStateView.swift
//  ChurchTalkAdmin
//
//  Reusable error state component with retry functionality
//

import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    let icon: String
    let retryAction: (() -> Void)?

    @State private var isRetrying = false

    init(
        title: String = "Something Went Wrong",
        message: String,
        icon: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 24) {
            // Animated error icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )

                Image(systemName: icon)
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(.red)
                    .rotationEffect(.degrees(shakeAnimation))
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.3),
                        value: shakeAnimation
                    )
            }
            .onAppear {
                pulseAnimation = 1.1
                // Trigger shake animation
                withAnimation {
                    shakeAnimation = -5
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        shakeAnimation = 5
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        shakeAnimation = 0
                    }
                }
            }

            // Error text content
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Retry button
            if let retryAction = retryAction {
                Button(action: {
                    HapticManager.shared.buttonTap()
                    isRetrying = true

                    // Call retry action
                    retryAction()

                    // Reset retrying state after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isRetrying = false
                    }
                }) {
                    HStack(spacing: 8) {
                        if isRetrying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                        }

                        Text(isRetrying ? "Retrying..." : "Try Again")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.churchPrimary)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isRetrying)
                .opacity(isRetrying ? 0.7 : 1.0)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    @State private var pulseAnimation: CGFloat = 1.0
    @State private var shakeAnimation: Double = 0
}

// MARK: - Convenience Initializers for Common Error States

extension ErrorStateView {
    /// Network error with retry
    static func networkError(retry: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Connection Error",
            message: "Unable to connect to the server. Please check your internet connection and try again.",
            icon: "wifi.exclamationmark",
            retryAction: retry
        )
    }

    /// Server error with retry
    static func serverError(retry: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Server Error",
            message: "We're having trouble connecting to our servers. Please try again in a moment.",
            icon: "server.rack",
            retryAction: retry
        )
    }

    /// Generic load error with retry
    static func loadError(itemName: String = "data", retry: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Failed to Load",
            message: "We couldn't load \(itemName). Please try again.",
            icon: "exclamationmark.triangle.fill",
            retryAction: retry
        )
    }

    /// Authentication error
    static func authError(message: String = "Your session has expired. Please log in again.") -> ErrorStateView {
        ErrorStateView(
            title: "Authentication Error",
            message: message,
            icon: "lock.fill",
            retryAction: nil
        )
    }

    /// Permission denied error
    static func permissionDenied(resource: String = "this resource") -> ErrorStateView {
        ErrorStateView(
            title: "Access Denied",
            message: "You don't have permission to access \(resource).",
            icon: "hand.raised.fill",
            retryAction: nil
        )
    }

    /// Not found error
    static func notFound(itemName: String = "item") -> ErrorStateView {
        ErrorStateView(
            title: "Not Found",
            message: "The \(itemName) you're looking for doesn't exist or has been removed.",
            icon: "questionmark.circle.fill",
            retryAction: nil
        )
    }

    /// Custom error with retry
    static func custom(
        title: String,
        message: String,
        icon: String = "exclamationmark.triangle.fill",
        retry: (() -> Void)? = nil
    ) -> ErrorStateView {
        ErrorStateView(
            title: title,
            message: message,
            icon: icon,
            retryAction: retry
        )
    }
}

// MARK: - Preview
#if DEBUG
struct ErrorStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorStateView.networkError(retry: { })
            .previewDisplayName("Network Error")

            ErrorStateView.serverError(retry: {})
                .previewDisplayName("Server Error")
                .preferredColorScheme(.dark)

            ErrorStateView.authError()
                .previewDisplayName("Auth Error")

            ErrorStateView.permissionDenied()
                .previewDisplayName("Permission Denied")
        }
    }
}
#endif
