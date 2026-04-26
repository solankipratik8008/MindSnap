//
//  GoalCompletionAnimation.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-23.
//

// ============================================================
// GoalCompletionAnimation.swift
// MindSnap — ACTIVITY-SPECIFIC ANIMATIONS
//
// WHAT CHANGED:
// 1. Added WaveAnimation — for water goals 💧
// 2. Added StarsAnimation — for reading/studying ⭐
// 3. Added SpeedLinesAnimation — for running/cycling 🏃
// 4. Added PowerBurstAnimation — for gym 💪
// 5. Added CalmPulseAnimation — for meditation/yoga 🧘
// 6. Added MoonStarsAnimation — for sleep 🌙
// 7. Added StepTrailAnimation — for walking 🚶
// 8. ActivityCompletionView — picks right animation
//    based on GoalAnimationStyle
// ============================================================

import SwiftUI

// ============================================================
// ActivityCompletionView
//
// Master view that picks the right animation
// based on the goal's activity type.
// Use this in GoalRowView instead of old animations.
// ============================================================
struct ActivityCompletionView: View {

    let style: GoalAnimationStyle
    let color: Color
    let isShowing: Bool

    var body: some View {
        ZStack {
            switch style {
            case .wave:
                WaveCompletionView(
                    isShowing: isShowing,
                    color: color
                )
            case .stars:
                StarsCompletionView(
                    isShowing: isShowing,
                    color: color
                )
            case .speedLines:
                SpeedLinesView(
                    isShowing: isShowing,
                    color: color
                )
            case .powerBurst:
                PowerBurstView(
                    isShowing: isShowing,
                    color: color
                )
            case .calmPulse:
                CalmPulseView(
                    isShowing: isShowing,
                    color: color
                )
            case .moonStars:
                MoonStarsView(
                    isShowing: isShowing,
                    color: color
                )
            case .stepTrail:
                StepTrailView(
                    isShowing: isShowing,
                    color: color
                )
            case .confetti:
                GoalCompletionBurst(
                    isShowing: isShowing,
                    color: color
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// ============================================================
// WaveCompletionView — 💧 Water goals
//
// Blue waves ripple outward from center
// ============================================================
struct WaveCompletionView: View {

    let isShowing: Bool
    let color: Color

    @State private var animate = false
    @State private var waveScale: [CGFloat] = [0.3, 0.3, 0.3]
    @State private var waveOpacity: [Double] = [0.8, 0.6, 0.4]

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        color.opacity(waveOpacity[index]),
                        lineWidth: 3
                    )
                    .scaleEffect(waveScale[index])
                    .frame(width: 80, height: 80)
            }

            // Water droplets
            ForEach(0..<6, id: \.self) { index in
                WaterDroplet(
                    index: index,
                    color: color,
                    animate: animate
                )
            }
        }
        .onChange(of: isShowing) { _, showing in
            if showing {
                animate = false
                waveScale = [0.3, 0.3, 0.3]
                waveOpacity = [0.8, 0.6, 0.4]

                // Staggered wave rings
                for i in 0..<3 {
                    withAnimation(
                        .easeOut(duration: 0.8)
                        .delay(Double(i) * 0.2)
                    ) {
                        waveScale[i] = 2.5
                        waveOpacity[i] = 0
                    }
                }
                withAnimation(.easeOut(duration: 0.8)) {
                    animate = true
                }
            }
        }
    }
}

struct WaterDroplet: View {
    let index: Int
    let color: Color
    let animate: Bool

    var angle: Double {
        Double(index) * 60.0
    }

    var body: some View {
        Circle()
            .fill(color.opacity(0.7))
            .frame(width: 8, height: 12)
            .offset(
                x: animate
                    ? cos(angle * .pi / 180) * 50
                    : 0,
                y: animate
                    ? sin(angle * .pi / 180) * 50 - 20
                    : 0
            )
            .opacity(animate ? 0 : 1)
            .animation(
                .easeOut(duration: 0.7)
                .delay(Double(index) * 0.05),
                value: animate
            )
    }
}

// ============================================================
// StarsCompletionView — ⭐ Reading/Studying goals
//
// Gold stars float upward and sparkle
// ============================================================
struct StarsCompletionView: View {

    let isShowing: Bool
    let color: Color

    @State private var stars: [StarParticle] = []
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(stars) { star in
                Image(systemName:
                    star.isBig ? "star.fill" : "sparkle"
                )
                .font(.system(size: star.size))
                .foregroundStyle(
                    star.isBig
                        ? Color.yellow
                        : color
                )
                .position(
                    x: animate
                        ? star.endX
                        : star.startX,
                    y: animate
                        ? star.endY
                        : star.startY
                )
                .rotationEffect(.degrees(
                    animate ? star.rotation : 0
                ))
                .opacity(animate ? 0 : 1)
                .scaleEffect(animate ? 0.3 : 1.0)
            }
        }
        .onChange(of: isShowing) { _, showing in
            if showing {
                generateStars()
                withAnimation(.easeOut(duration: 1.0)) {
                    animate = true
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 1.2
                ) {
                    animate = false
                    stars = []
                }
            }
        }
    }

    private func generateStars() {
        animate = false
        stars = (0..<12).map { index in
            let startX = CGFloat.random(in: -30..<30)
            let startY = CGFloat.random(in: -10..<10)
            return StarParticle(
                startX: startX,
                startY: startY,
                endX: startX + CGFloat.random(in: -60..<60),
                endY: startY - CGFloat.random(in: 60..<120),
                size: CGFloat.random(in: 10..<22),
                rotation: Double.random(in: 0..<360),
                isBig: index % 3 == 0
            )
        }
    }
}

struct StarParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let rotation: Double
    let isBig: Bool
}

// ============================================================
// SpeedLinesView — 🏃 Running/Cycling goals
//
// Orange speed lines burst outward horizontally
// ============================================================
struct SpeedLinesView: View {

    let isShowing: Bool
    let color: Color

    @State private var animate = false
    @State private var lineOpacities: [Double] = Array(
        repeating: 1.0, count: 8
    )

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                SpeedLine(
                    index: index,
                    color: color,
                    animate: animate
                )
            }

            // Central burst circle
            Circle()
                .fill(color.opacity(0.3))
                .frame(
                    width: animate ? 60 : 10,
                    height: animate ? 60 : 10
                )
                .opacity(animate ? 0 : 1)
                .animation(
                    .easeOut(duration: 0.4),
                    value: animate
                )
        }
        .onChange(of: isShowing) { _, showing in
            if showing {
                animate = false
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.05
                ) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        animate = true
                    }
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + 0.8
                    ) {
                        animate = false
                    }
                }
            }
        }
    }
}

struct SpeedLine: View {
    let index: Int
    let color: Color
    let animate: Bool

    var angle: Double { Double(index) * 45.0 }
    var length: CGFloat { CGFloat.random(in: 30..<70) }

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(
                width: animate ? length : 0,
                height: 3
            )
            .offset(
                x: animate ? cos(angle * .pi / 180) * 40 : 0,
                y: animate ? sin(angle * .pi / 180) * 40 : 0
            )
            .rotationEffect(.degrees(angle))
            .opacity(animate ? 0 : 1)
            .animation(
                .easeOut(duration: 0.5)
                .delay(Double(index) * 0.03),
                value: animate
            )
    }
}

// ============================================================
// PowerBurstView — 💪 Gym goals
//
// Red/orange explosive burst radiating outward
// ============================================================
struct PowerBurstView: View {

    let isShowing: Bool
    let color: Color

    @State private var particles: [PowerParticle] = []
    @State private var animate = false
    @State private var ringScale: CGFloat = 0.2
    @State private var ringOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // Outer ring burst
            Circle()
                .stroke(color, lineWidth: 4)
                .frame(width: 60, height: 60)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            // Power particles
            ForEach(particles) { particle in
                Rectangle()
                    .fill(particle.color)
                    .frame(
                        width: particle.size * 2,
                        height: particle.size
                    )
                    .cornerRadius(2)
                    .offset(
                        x: animate ? particle.endX : 0,
                        y: animate ? particle.endY : 0
                    )
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 0.1 : 1.2)
            }

            // Center flash
            Circle()
                .fill(color)
                .frame(
                    width: animate ? 50 : 8,
                    height: animate ? 50 : 8
                )
                .opacity(animate ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: animate)
        }
        .onChange(of: isShowing) { _, showing in
            if showing {
                generateParticles()
                withAnimation(.easeOut(duration: 0.6)) {
                    animate = true
                    ringScale = 2.0
                    ringOpacity = 0
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.8
                ) {
                    animate = false
                    particles = []
                    ringScale = 0.2
                    ringOpacity = 1.0
                }
            }
        }
    }

    private func generateParticles() {
        animate = false
        particles = (0..<10).map { index in
            let angle = Double(index) * 36.0
            let distance = CGFloat.random(in: 40..<80)
            return PowerParticle(
                color: index % 2 == 0 ? color : .yellow,
                size: CGFloat.random(in: 6..<14),
                endX: cos(angle * .pi / 180) * distance,
                endY: sin(angle * .pi / 180) * distance,
                rotation: Double.random(in: 0..<360)
            )
        }
    }
}

struct PowerParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
}

// ============================================================
// CalmPulseView — 🧘 Meditation/Yoga goals
//
// Soft concentric rings pulse outward gently
// ============================================================
struct CalmPulseView: View {

    let isShowing: Bool
    let color: Color

    @State private var pulseScales: [CGFloat] = [0.3, 0.3, 0.3, 0.3]
    @State private var pulseOpacities: [Double] = [0.6, 0.5, 0.4, 0.3]

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(color.opacity(pulseOpacities[index]))
                    .frame(
                        width: 20 + CGFloat(index) * 15,
                        height: 20 + CGFloat(index) * 15
                    )
                    .scaleEffect(pulseScales[index])
            }

            // Center lotus symbol
            Image(systemName: "sparkle")
                .font(.system(size: 20))
                .foregroundStyle(color)
                .opacity(isShowing ? 1 : 0)
                .scaleEffect(isShowing ? 1.2 : 0.5)
                .animation(
                    .spring(duration: 0.5, bounce: 0.4),
                    value: isShowing
                )
        }
        .onChange(of: isShowing) { _, showing in
            if showing {
                pulseScales = [0.3, 0.3, 0.3, 0.3]
                pulseOpacities = [0.6, 0.5, 0.4, 0.3]

                for i in 0..<4 {
                    withAnimation(
                        .easeOut(duration: 1.2)
                        .delay(Double(i) * 0.15)
                    ) {
                        pulseScales[i] = 3.0
                        pulseOpacities[i] = 0
                    }
                }
            }
        }
    }
}

// ============================================================
// MoonStarsView — 🌙 Sleep goals
//
// Moon and stars drift upward into night sky
// ============================================================
struct MoonStarsView: View {

    let isShowing: Bool
    let color: Color

    @State private var moonOffset: CGFloat = 0
    @State private var moonOpacity: Double = 0
    @State private var starParticles: [MoonStar] = []
    @State private var animateStars = false

    var body: some View {
        ZStack {
            // Moon
            Image(systemName: "moon.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.yellow)
                .offset(y: moonOffset)
                .opacity(moonOpacity)

            // Stars
            ForEach(starParticles) { star in
                Image(systemName: "star.fill")
                    .font(.system(size: star.size))
                    .foregroundStyle(Color.yellow.opacity(0.8))
                    .offset(
                        x: animateStars ? star.endX : star.startX,
                        y: animateStars ? star.endY : star.startY
                    )
                    .opacity(animateStars ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 1.0)
                        .delay(star.delay),
                        value: animateStars
                    )
            }
        }
        .onChange(of: isShowing) { _, showing in
            if showing {
                generateStars()
                moonOffset = 20
                moonOpacity = 0

                withAnimation(.easeOut(duration: 0.5)) {
                    moonOpacity = 1
                    moonOffset = -10
                }
                withAnimation(
                    .easeOut(duration: 1.5).delay(0.2)
                ) {
                    moonOffset = -60
                    moonOpacity = 0
                }
                withAnimation(.easeOut(duration: 1.0)) {
                    animateStars = true
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 1.5
                ) {
                    animateStars = false
                    starParticles = []
                }
            }
        }
    }

    private func generateStars() {
        animateStars = false
        starParticles = (0..<8).map { index in
            let startX = CGFloat.random(in: -60..<60)
            let startY = CGFloat.random(in: -20..<20)
            return MoonStar(
                startX: startX,
                startY: startY,
                endX: startX + CGFloat.random(in: -20..<20),
                endY: startY - CGFloat.random(in: 50..<100),
                size: CGFloat.random(in: 8..<16),
                delay: Double(index) * 0.1
            )
        }
    }
}

struct MoonStar: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let delay: Double
}

// ============================================================
// StepTrailView — 🚶 Walking goals
//
// Green footstep dots trail across screen
// ============================================================
struct StepTrailView: View {

    let isShowing: Bool
    let color: Color

    @State private var steps: [StepDot] = []
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(steps) { step in
                Circle()
                    .fill(step.color)
                    .frame(
                        width: step.size,
                        height: step.size
                    )
                    .offset(
                        x: animate ? step.endX : step.startX,
                        y: animate ? step.endY : step.startY
                    )
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 0.3 : 1.0)
                    .animation(
                        .easeOut(duration: 0.8)
                        .delay(step.delay),
                        value: animate
                    )
            }
        }
        .onChange(of: isShowing) { _, showing in
            if showing {
                generateSteps()
                withAnimation(.easeOut(duration: 0.8)) {
                    animate = true
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 1.0
                ) {
                    animate = false
                    steps = []
                }
            }
        }
    }

    private func generateSteps() {
        animate = false
        steps = (0..<10).map { index in
            let isLeft = index % 2 == 0
            let xBase = isLeft ? -12.0 : 12.0
            return StepDot(
                startX: CGFloat(xBase),
                startY: CGFloat(index * -5),
                endX: CGFloat(xBase) + CGFloat.random(
                    in: -20..<20
                ),
                endY: CGFloat(index * -5) -
                    CGFloat.random(in: 30..<80),
                size: CGFloat.random(in: 8..<14),
                color: index % 3 == 0
                    ? color
                    : color.opacity(0.6),
                delay: Double(index) * 0.07
            )
        }
    }
}

struct StepDot: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let color: Color
    let delay: Double
}

// ============================================================
// PointsPopupView — Floats up when points earned
// ============================================================
struct PointsPopupView: View {

    let points: Int
    let isShowing: Bool

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        Text("+\(points) ⭐")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(.yellow)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.75))
                    .shadow(
                        color: .yellow.opacity(0.4),
                        radius: 8, x: 0, y: 2
                    )
            )
            .offset(y: offset)
            .opacity(opacity)
            .onChange(of: isShowing) { _, showing in
                if showing {
                    offset = 0
                    opacity = 0
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 1
                    }
                    withAnimation(
                        .easeOut(duration: 1.2).delay(0.1)
                    ) {
                        offset = -80
                    }
                    withAnimation(
                        .easeIn(duration: 0.4).delay(0.9)
                    ) {
                        opacity = 0
                    }
                }
            }
    }
}

// ============================================================
// ConfettiView — Default confetti burst
// ============================================================
struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let position: CGPoint
    let size: CGFloat
    let rotation: Double
    let velocity: CGPoint
    let shape: ConfettiShape
}

enum ConfettiShape: CaseIterable {
    case circle
    case rectangle
    case triangle
}

struct ConfettiView: View {

    let isShowing: Bool

    @State private var pieces: [ConfettiPiece] = []
    @State private var animate = false

    private let colors: [Color] = [
        .red, .orange, .yellow, .green,
        .blue, .purple, .pink, .cyan
    ]

    var body: some View {
        ZStack {
            if isShowing || animate {
                ForEach(pieces) { piece in
                    confettiShape(piece: piece)
                        .frame(
                            width: piece.size,
                            height: piece.size
                        )
                        .foregroundStyle(piece.color)
                        .position(
                            x: animate
                                ? piece.position.x + piece.velocity.x
                                : piece.position.x,
                            y: animate
                                ? piece.position.y + piece.velocity.y
                                : piece.position.y
                        )
                        .rotationEffect(.degrees(
                            animate ? piece.rotation * 3 : 0
                        ))
                        .opacity(animate ? 0 : 1)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isShowing) { _, showing in
            if showing {
                generatePieces()
                withAnimation(.easeOut(duration: 1.2)) {
                    animate = true
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 1.5
                ) {
                    animate = false
                    pieces = []
                }
            }
        }
    }

    @ViewBuilder
    private func confettiShape(
        piece: ConfettiPiece
    ) -> some View {
        switch piece.shape {
        case .circle:
            Circle().fill(piece.color)
        case .rectangle:
            Rectangle().fill(piece.color).cornerRadius(2)
        case .triangle:
            Triangle().fill(piece.color)
        }
    }

    private func generatePieces() {
        let center = CGPoint(
            x: UIScreen.main.bounds.width / 2,
            y: UIScreen.main.bounds.height / 2
        )
        pieces = (0..<60).map { _ in
            let angle = Double.random(in: 0..<360)
            let speed = Double.random(in: 150..<350)
            let radians = angle * .pi / 180
            return ConfettiPiece(
                color: colors.randomElement() ?? .purple,
                position: center,
                size: CGFloat.random(in: 6..<14),
                rotation: Double.random(in: 0..<360),
                velocity: CGPoint(
                    x: cos(radians) * speed,
                    y: sin(radians) * speed
                ),
                shape: ConfettiShape.allCases.randomElement()
                    ?? .circle
            )
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// ============================================================
// GoalCompletionBurst — Star burst on row tap
// ============================================================
struct GoalCompletionBurst: View {

    let isShowing: Bool
    let color: Color

    @State private var particles: [BurstParticle] = []
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(
                        width: particle.size,
                        height: particle.size
                    )
                    .offset(
                        x: animate ? particle.endX : 0,
                        y: animate ? particle.endY : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 0.1 : 1.0)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isShowing) { _, showing in
            if showing {
                generateParticles()
                withAnimation(.easeOut(duration: 0.6)) {
                    animate = true
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.8
                ) {
                    animate = false
                    particles = []
                }
            }
        }
    }

    private func generateParticles() {
        animate = false
        particles = (0..<12).map { index in
            let angle = Double(index) * (360.0 / 12.0)
            let radians = angle * .pi / 180
            let distance = CGFloat.random(in: 30..<60)
            return BurstParticle(
                color: [color, color.opacity(0.7), .yellow]
                    .randomElement() ?? color,
                size: CGFloat.random(in: 4..<10),
                endX: cos(radians) * distance,
                endY: sin(radians) * distance
            )
        }
    }
}

struct BurstParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let endX: CGFloat
    let endY: CGFloat
}

// ============================================================
// CelebrationView — Full screen all-goals-done overlay
// ============================================================
struct CelebrationView: View {

    let isShowing: Bool

    @State private var scaleEffect: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        if isShowing {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ConfettiView(isShowing: isShowing)

                VStack(spacing: 20) {
                    Text("🏆")
                        .font(.system(size: 80))
                        .scaleEffect(scaleEffect)

                    VStack(spacing: 8) {
                        Text("All Goals Done!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("You're absolutely crushing it today!")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 8) {
                        Text("🌟")
                        Text("+25 Bonus Points!")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(
                                        Color.yellow.opacity(0.5),
                                        lineWidth: 1.5
                                    )
                            )
                    )

                    Text("Keep the momentum going! 💪")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.9),
                                    Color.indigo.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: .purple.opacity(0.5),
                            radius: 30, x: 0, y: 10
                        )
                )
                .padding(.horizontal, 32)
                .scaleEffect(scaleEffect)
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(
                    .spring(duration: 0.6, bounce: 0.4)
                ) {
                    scaleEffect = 1.0
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 2.5
                ) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        scaleEffect = 0.8
                        opacity = 0
                    }
                }
            }
        }
    }
}

// ============================================================
// LevelUpView — Shows when user reaches a new level
// ============================================================
struct LevelUpView: View {

    let level: PointsLevel
    let isShowing: Bool

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0

    var body: some View {
        if isShowing {
            VStack(spacing: 12) {
                Text(level.emoji)
                    .font(.system(size: 60))
                Text("Level Up!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text(level.rawValue)
                    .font(.headline)
                    .foregroundStyle(level.color)
                Text(level.message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground).opacity(0.95))
                    .shadow(
                        color: level.color.opacity(0.4),
                        radius: 20
                    )
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .spring(duration: 0.5, bounce: 0.5)
                ) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

// ============================================================
// Preview
// ============================================================
#Preview("Wave") {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        WaveCompletionView(isShowing: true, color: .blue)
    }
}

#Preview("Stars") {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        StarsCompletionView(isShowing: true, color: .purple)
    }
}

#Preview("Celebration") {
    CelebrationView(isShowing: true)
}
