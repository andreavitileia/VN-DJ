import SwiftUI

struct MixerView: View {
    @EnvironmentObject var mixer: MixerViewModel

    var body: some View {
        VStack(spacing: 8) {
            // VN DJ logo
            Text("V N  D J")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
                .tracking(4)

            // EQ section
            eqSection

            Divider().background(Color.white.opacity(0.06))

            // Channel faders
            faderSection

            Divider().background(Color.white.opacity(0.06))

            // Crossfader
            HorizontalFaderView(label: "CROSSFADER", value: $mixer.crossfader)

            Divider().background(Color.white.opacity(0.06))

            // CUE / Headphone
            headphoneSection

            Spacer()

            // Master
            masterSection
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
        )
    }

    // MARK: - EQ Knobs

    private var eqSection: some View {
        HStack(spacing: 16) {
            // Channel A EQ
            VStack(spacing: 4) {
                Text("CH A")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(.cyan.opacity(0.7))
                    .tracking(1)
                RotaryKnobView(label: "HI", value: $mixer.eqHighA, color: .white, size: 36)
                RotaryKnobView(label: "MID", value: $mixer.eqMidA, color: .white, size: 36)
                RotaryKnobView(label: "LOW", value: $mixer.eqLowA, color: .white, size: 36)
            }

            // VU meters (simplified)
            VStack(spacing: 2) {
                Text("LVL")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                VUMeterView(level: mixer.levelA, color: .cyan)
                    .frame(width: 6, height: 60)
                VUMeterView(level: mixer.levelB, color: .magenta)
                    .frame(width: 6, height: 60)
            }

            // Channel B EQ
            VStack(spacing: 4) {
                Text("CH B")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(.magenta.opacity(0.7))
                    .tracking(1)
                RotaryKnobView(label: "HI", value: $mixer.eqHighB, color: .white, size: 36)
                RotaryKnobView(label: "MID", value: $mixer.eqMidB, color: .white, size: 36)
                RotaryKnobView(label: "LOW", value: $mixer.eqLowB, color: .white, size: 36)
            }
        }
    }

    // MARK: - Channel Faders

    private var faderSection: some View {
        HStack(spacing: 20) {
            VerticalFaderView(label: "A", value: $mixer.volumeA, color: .cyan, height: 100)
            VerticalFaderView(label: "B", value: $mixer.volumeB, color: .magenta, height: 100)
        }
    }

    // MARK: - Headphone / CUE

    private var headphoneSection: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                // CUE A
                Button(action: { mixer.cueA.toggle() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "headphones")
                            .font(.system(size: 9))
                        Text("A")
                            .font(.system(size: 9, weight: .heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 26)
                    .foregroundColor(mixer.cueA ? .black : .cyan)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(mixer.cueA ? Color.cyan.opacity(0.8) : Color(white: 0.08))
                            .shadow(color: mixer.cueA ? .cyan.opacity(0.3) : .clear, radius: 4)
                    )
                }
                .buttonStyle(.plain)

                // CUE B
                Button(action: { mixer.cueB.toggle() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "headphones")
                            .font(.system(size: 9))
                        Text("B")
                            .font(.system(size: 9, weight: .heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 26)
                    .foregroundColor(mixer.cueB ? .black : .magenta)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(mixer.cueB ? Color.magenta.opacity(0.8) : Color(white: 0.08))
                            .shadow(color: mixer.cueB ? .magenta.opacity(0.3) : .clear, radius: 4)
                    )
                }
                .buttonStyle(.plain)
            }

            // Headphone mix knob
            RotaryKnobView(label: "CUE/MIX", value: $mixer.headphoneMix, range: 0...1, color: .orange, size: 32)
        }
    }

    // MARK: - Master

    private var masterSection: some View {
        VStack(spacing: 4) {
            RotaryKnobView(label: "MASTER", value: $mixer.masterVolume, range: 0...1, color: .red, size: 38)
        }
    }
}

// MARK: - VU Meter

struct VUMeterView: View {
    let level: Float
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(white: 0.06))

                // Level
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            colors: [.green, .yellow, .red],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: geo.size.height * CGFloat(level))

                // Segment lines
                ForEach(0..<8, id: \.self) { i in
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 1)
                        .position(x: geo.size.width / 2, y: geo.size.height * CGFloat(i) / 8.0)
                }
            }
        }
    }
}
