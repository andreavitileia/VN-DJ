import SwiftUI

struct VerticalFaderView: View {
    let label: String
    @Binding var value: Float
    let color: Color
    let height: CGFloat

    init(label: String, value: Binding<Float>, color: Color = .white, height: CGFloat = 140) {
        self.label = label
        self._value = value
        self.color = color
        self.height = height
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(color.opacity(0.8))
                .tracking(1)

            GeometryReader { geo in
                let trackHeight = geo.size.height
                let thumbY = trackHeight * (1 - CGFloat(value))

                ZStack(alignment: .bottom) {
                    // Track groove
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.06))
                        .frame(width: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )

                    // Value fill (glow from bottom)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.1),
                                    color.opacity(0.6)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 6, height: trackHeight * CGFloat(value))

                    // Level indicator ticks
                    ForEach(0..<11, id: \.self) { i in
                        let y = trackHeight * CGFloat(i) / 10.0
                        Rectangle()
                            .fill(Color.white.opacity(i % 5 == 0 ? 0.25 : 0.08))
                            .frame(width: 14, height: 0.5)
                            .position(x: geo.size.width / 2, y: y)
                    }

                    // Thumb - realistic fader cap
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(white: 0.35),
                                        Color(white: 0.2),
                                        Color(white: 0.1)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 28, height: 14)

                        // Center grip line
                        Rectangle()
                            .fill(color.opacity(0.8))
                            .frame(width: 16, height: 1.5)
                            .shadow(color: color.opacity(0.5), radius: 2)
                    }
                    .position(x: geo.size.width / 2, y: thumbY)
                }
                .frame(maxWidth: .infinity)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let normalized = 1 - Float(drag.location.y / trackHeight)
                            value = max(0, min(1, normalized))
                        }
                )
            }
            .frame(width: 36, height: height)
        }
    }
}

struct HorizontalFaderView: View {
    let label: String
    @Binding var value: Float
    let leftLabel: String
    let rightLabel: String

    init(label: String, value: Binding<Float>, leftLabel: String = "A", rightLabel: String = "B") {
        self.label = label
        self._value = value
        self.leftLabel = leftLabel
        self.rightLabel = rightLabel
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .heavy))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)

            HStack(spacing: 6) {
                Text(leftLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan)

                GeometryReader { geo in
                    let trackWidth = geo.size.width
                    let thumbX = trackWidth * CGFloat(value)

                    ZStack {
                        // Track groove
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.06))
                            .frame(height: 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )

                        // Center notch
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 1.5, height: 12)
                            .position(x: trackWidth / 2, y: geo.size.height / 2)

                        // Thumb
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(white: 0.4),
                                            Color(white: 0.2),
                                            Color(white: 0.1)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 30, height: 20)

                            // Grip lines
                            VStack(spacing: 2) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 14, height: 0.5)
                                }
                            }
                        }
                        .position(x: thumbX, y: geo.size.height / 2)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                value = max(0, min(1, Float(drag.location.x / trackWidth)))
                            }
                    )
                }
                .frame(height: 24)

                Text(rightLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.magenta)
            }
        }
    }
}
