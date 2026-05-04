import SwiftUI

struct RotaryKnobView: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let color: Color
    let size: CGFloat

    @State private var lastDragY: CGFloat = 0

    init(label: String, value: Binding<Float>, range: ClosedRange<Float> = -26...6, color: Color = .white, size: CGFloat = 44) {
        self.label = label
        self._value = value
        self.range = range
        self.color = color
        self.size = size
    }

    private var normalizedValue: Double {
        let span = Double(range.upperBound - range.lowerBound)
        guard span > 0 else { return 0.5 }
        return Double(value - range.lowerBound) / span
    }

    private var rotationAngle: Double {
        -135.0 + normalizedValue * 270.0
    }

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .heavy))
                .foregroundColor(color.opacity(0.7))
                .tracking(1)

            ZStack {
                // Outer ring shadow
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: size + 4, height: size + 4)

                // Knob body - metallic gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(white: 0.25),
                                Color(white: 0.12),
                                Color(white: 0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)

                // Value arc
                Circle()
                    .trim(from: 0.25, to: 0.25 + CGFloat(normalizedValue) * 0.75)
                    .stroke(
                        color.opacity(0.8),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: size - 4, height: size - 4)
                    .rotationEffect(.degrees(135))

                // Tick marks
                ForEach(0..<11, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white.opacity(i == 5 ? 0.5 : 0.15))
                        .frame(width: 1, height: i == 5 ? 6 : 3)
                        .offset(y: -(size / 2 + 3))
                        .rotationEffect(.degrees(-135 + Double(i) * 27))
                }

                // Indicator line
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 2, height: size * 0.3)
                    .offset(y: -size * 0.2)
                    .rotationEffect(.degrees(rotationAngle))
                    .shadow(color: color.opacity(0.6), radius: 3)
            }
            .frame(width: size + 8, height: size + 8)
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { drag in
                        let delta = Float(-drag.translation.height / 100.0)
                        let span = range.upperBound - range.lowerBound
                        value = max(range.lowerBound, min(range.upperBound, value + delta * span * 0.01))
                    }
            )
            .onTapGesture(count: 2) {
                // Double tap to reset to center
                let center = (range.lowerBound + range.upperBound) / 2.0
                withAnimation(.easeOut(duration: 0.2)) { value = center }
            }

            // Value readout
            Text(String(format: "%.0f", value))
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
