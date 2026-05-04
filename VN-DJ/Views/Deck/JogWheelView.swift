import SwiftUI

struct JogWheelView: View {
    @ObservedObject var deck: DeckViewModel
    @EnvironmentObject var audioEngine: DJAudioEngine
    let side: DeckSide

    @State private var lastAngle: Angle = .zero
    @State private var isTouching = false
    @State private var scratchAngle: Double = 0

    private var accentColor: Color { side == .left ? .cyan : .magenta }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // Outer ring - metallic border
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.6),
                                Color.white.opacity(0.3),
                                Color.gray.opacity(0.6),
                                Color.white.opacity(0.2),
                                Color.gray.opacity(0.6)
                            ]),
                            center: .center
                        ),
                        lineWidth: size * 0.03
                    )
                    .frame(width: size * 0.95, height: size * 0.95)

                // Outer platter - dark with subtle texture
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(white: 0.12),
                                Color(white: 0.08),
                                Color(white: 0.05)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.45
                        )
                    )
                    .frame(width: size * 0.9, height: size * 0.9)

                // Rotation indicator dots around the platter
                ForEach(0..<36, id: \.self) { i in
                    let angle = Double(i) * 10.0 + scratchAngle
                    Circle()
                        .fill(Color.white.opacity(i % 9 == 0 ? 0.4 : 0.1))
                        .frame(width: i % 9 == 0 ? 4 : 2, height: i % 9 == 0 ? 4 : 2)
                        .offset(y: -size * 0.38)
                        .rotationEffect(.degrees(angle))
                }

                // Inner platter - slightly lighter
                Circle()
                    .fill(Color(white: 0.1))
                    .frame(width: size * 0.55, height: size * 0.55)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                // Center display area
                VStack(spacing: 2) {
                    // Track time
                    Text(formatTime(deck.currentPosition))
                        .font(.system(size: size * 0.07, weight: .bold, design: .monospaced))
                        .foregroundColor(deck.isPlaying ? .green : .white)

                    // BPM
                    Text(String(format: "%.1f", deck.effectiveBPM))
                        .font(.system(size: size * 0.055, weight: .medium, design: .monospaced))
                        .foregroundColor(accentColor)

                    // Pitch percentage
                    Text(String(format: "%+.1f%%", deck.tempo))
                        .font(.system(size: size * 0.04, design: .monospaced))
                        .foregroundColor(abs(deck.tempo) < 0.1 ? .green : .orange)
                }

                // Center dot (spindle)
                Circle()
                    .fill(accentColor.opacity(0.8))
                    .frame(width: size * 0.04, height: size * 0.04)
                    .offset(y: size * 0.12)
                    .rotationEffect(.degrees(scratchAngle))

                // Touch glow when touching
                if isTouching {
                    Circle()
                        .fill(accentColor.opacity(0.08))
                        .frame(width: size * 0.9, height: size * 0.9)
                }
            }
            .position(center)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isTouching {
                            isTouching = true
                            lastAngle = angle(for: value.location, center: center)
                        }

                        let current = angle(for: value.location, center: center)
                        let delta = angleDelta(from: lastAngle, to: current)
                        lastAngle = current

                        // Rotate platter visually
                        scratchAngle += delta.degrees

                        // Scrub through track
                        if let track = deck.track, track.duration > 0 {
                            let scrubAmount = delta.degrees / 360.0 * 2.0 // 2 seconds per full rotation
                            let newPos = max(0, min(track.duration, deck.currentPosition + scrubAmount))
                            deck.currentPosition = newPos
                            audioEngine.seek(to: newPos, side: side)
                        }
                    }
                    .onEnded { _ in
                        isTouching = false
                    }
            )
            // Auto-rotate when playing
            .onChange(of: deck.currentPosition) { _, newValue in
                if deck.isPlaying && !isTouching {
                    scratchAngle = newValue * 33.33 * 360.0 / 60.0 // 33.33 RPM like vinyl
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func angle(for point: CGPoint, center: CGPoint) -> Angle {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return Angle(radians: atan2(dy, dx))
    }

    private func angleDelta(from: Angle, to: Angle) -> Angle {
        var delta = to.degrees - from.degrees
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        return Angle(degrees: delta)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        let ms = Int((t - Double(Int(t))) * 100)
        return String(format: "%d:%02d.%02d", mins, secs, ms)
    }
}
