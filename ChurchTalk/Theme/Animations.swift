import SwiftUI

// MARK: - Animation Constants

struct ChurchTalkAnimations {
    // Spring Animations
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.9)

    // Easing Animations
    static let quickFade = Animation.easeOut(duration: 0.2)
    static let mediumFade = Animation.easeInOut(duration: 0.3)

    // Transition Presets
    static let cardAppear = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.95).combined(with: .opacity),
        removal: .opacity
    )

    static let slideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)
    static let slideFromRight = AnyTransition.move(edge: .trailing).combined(with: .opacity)
}

// MARK: - Shimmer Effect Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -200

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        Color.white.opacity(0.4),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}

// MARK: - Pulse Effect Modifier

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Bounce on Tap Modifier

struct BounceModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(ChurchTalkAnimations.snappy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Fade In Modifier

struct FadeInModifier: ViewModifier {
    @State private var opacity: Double = 0
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.4).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

// MARK: - Slide In Modifier

struct SlideInModifier: ViewModifier {
    @State private var offset: CGFloat = 50
    @State private var opacity: Double = 0
    let delay: Double

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(ChurchTalkAnimations.smooth.delay(delay)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

// MARK: - Card Style Modifier

struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(ChurchTalkTheme.cornerRadius)
            .shadow(
                color: ChurchTalkTheme.cardShadowColor,
                radius: ChurchTalkTheme.shadowRadius,
                y: ChurchTalkTheme.shadowY
            )
    }
}

// MARK: - Primary Button Style Modifier

struct PrimaryButtonStyleModifier: ViewModifier {
    let isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.churchTalkRed : Color.gray)
            .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

// MARK: - Secondary Button Style Modifier

struct SecondaryButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.churchTalkRed)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.churchTalkRed.opacity(0.1))
            .cornerRadius(ChurchTalkTheme.cornerRadius)
    }
}

// MARK: - Avatar Style Modifier

struct AvatarStyleModifier: ViewModifier {
    let size: CGFloat
    let backgroundColor: Color

    init(size: CGFloat = ChurchTalkTheme.avatarMedium, backgroundColor: Color = Color.churchTalkRed.opacity(0.2)) {
        self.size = size
        self.backgroundColor = backgroundColor
    }

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}

// MARK: - View Extensions

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    func pulse() -> some View {
        modifier(PulseModifier())
    }

    func bounceOnTap() -> some View {
        modifier(BounceModifier())
    }

    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInModifier(delay: delay))
    }

    func slideIn(delay: Double = 0) -> some View {
        modifier(SlideInModifier(delay: delay))
    }

    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }

    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        modifier(PrimaryButtonStyleModifier(isEnabled: isEnabled))
    }

    func secondaryButtonStyle() -> some View {
        modifier(SecondaryButtonStyleModifier())
    }

    func avatarStyle(size: CGFloat = ChurchTalkTheme.avatarMedium, backgroundColor: Color = Color.churchTalkRed.opacity(0.2)) -> some View {
        modifier(AvatarStyleModifier(size: size, backgroundColor: backgroundColor))
    }
}

// MARK: - Celebration Animation View

struct CelebrationAnimation: View {
    @State private var particles: [Particle] = []
    let color: Color

    init(color: Color = .churchTalkRed) {
        self.color = color
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(color.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
            }
        }
        .onAppear {
            createParticles()
        }
    }

    private func createParticles() {
        for i in 0..<20 {
            let particle = Particle(
                id: i,
                position: CGPoint(x: CGFloat.random(in: 50...300), y: 200),
                size: CGFloat.random(in: 4...12),
                opacity: 1.0
            )
            particles.append(particle)

            withAnimation(.easeOut(duration: 1.5).delay(Double(i) * 0.05)) {
                if let index = particles.firstIndex(where: { $0.id == i }) {
                    particles[index].position.y = CGFloat.random(in: -100...100)
                    particles[index].position.x += CGFloat.random(in: -50...50)
                    particles[index].opacity = 0
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id: Int
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
}

// MARK: - Prayer Animation (Enhanced)

struct EnhancedPrayerAnimation: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.churchTalkRed)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(rotation + Double(i * 120)))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.5
                opacity = 0
                rotation = 360
            }
        }
    }
}

// MARK: - Success Checkmark Animation

struct SuccessCheckmarkAnimation: View {
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.churchTalkRed.opacity(0.2))
                .frame(width: 80, height: 80)
                .scaleEffect(scale)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.churchTalkRed)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(ChurchTalkAnimations.bouncy) {
                scale = 1
                opacity = 1
            }
        }
    }
}
