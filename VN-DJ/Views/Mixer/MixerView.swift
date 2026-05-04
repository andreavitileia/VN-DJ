import SwiftUI

struct MixerView: View {
    @EnvironmentObject var mixer: MixerViewModel

    var body: some View {
        VStack(spacing: 8) {
            Text("MIXER")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.5))

            // EQ knobs for both channels
            HStack(spacing: 12) {
                // Channel A EQ
                VStack(spacing: 6) {
                    Text("A").font(.system(size: 9, weight: .bold)).foregroundColor(.cyan)
                    EQKnob(label: "HI", value: $mixer.eqHighA, color: .white)
                    EQKnob(label: "MID", value: $mixer.eqMidA, color: .white)
                    EQKnob(label: "LOW", value: $mixer.eqLowA, color: .white)
                }

                // Channel B EQ
                VStack(spacing: 6) {
                    Text("B").font(.system(size: 9, weight: .bold)).foregroundColor(.magenta)
                    EQKnob(label: "HI", value: $mixer.eqHighB, color: .white)
                    EQKnob(label: "MID", value: $mixer.eqMidB, color: .white)
                    EQKnob(label: "LOW", value: $mixer.eqLowB, color: .white)
                }
            }

            Divider().background(Color.gray.opacity(0.3))

            // Volume faders
            HStack(spacing: 16) {
                VolumeSlider(label: "A", value: $mixer.volumeA, color: .cyan)
                VolumeSlider(label: "B", value: $mixer.volumeB, color: .magenta)
            }

            Divider().background(Color.gray.opacity(0.3))

            // Crossfader
            VStack(spacing: 2) {
                Text("CROSSFADER")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))

                HStack(spacing: 4) {
                    Text("A").font(.system(size: 9, weight: .bold)).foregroundColor(.cyan)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Track
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)

                            // Thumb
                            let thumbX = CGFloat(mixer.crossfader) * (geo.size.width - 24)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 24, height: 18)
                                .offset(x: thumbX)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let normalized = Float(value.location.x / geo.size.width)
                                            mixer.crossfader = max(0, min(1, normalized))
                                        }
                                )
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .frame(height: 22)
                    Text("B").font(.system(size: 9, weight: .bold)).foregroundColor(.magenta)
                }
            }

            Divider().background(Color.gray.opacity(0.3))

            // CUE/PFL buttons
            HStack(spacing: 12) {
                Button(action: { mixer.cueA.toggle() }) {
                    Text("CUE A")
                        .font(.system(size: 9, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                        .background(mixer.cueA ? Color.cyan.opacity(0.6) : Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)

                Button(action: { mixer.cueB.toggle() }) {
                    Text("CUE B")
                        .font(.system(size: 9, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                        .background(mixer.cueB ? Color.magenta.opacity(0.6) : Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Master volume
            VStack(spacing: 2) {
                Text("MASTER")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                Slider(value: $mixer.masterVolume, in: 0...1)
                    .tint(.white)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.08))
    }
}

struct EQKnob: View {
    let label: String
    @Binding var value: Float
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.5))

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 28, height: 28)

                // Indicator
                let angle = Angle(degrees: Double(value / 26.0) * 135)
                Circle()
                    .fill(abs(value) > 0.1 ? color : Color.white.opacity(0.4))
                    .frame(width: 5, height: 5)
                    .offset(y: -10)
                    .rotationEffect(angle)
            }
            .frame(width: 30, height: 30)
            .gesture(
                DragGesture()
                    .onChanged { drag in
                        let delta = Float(-drag.translation.height / 50.0)
                        value = max(-26, min(6, value + delta))
                    }
            )
            .onTapGesture(count: 2) {
                value = 0
            }
        }
    }
}

struct VolumeSlider: View {
    let label: String
    @Binding var value: Float
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(color)

            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 6)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.7))
                        .frame(width: 6, height: geo.size.height * CGFloat(value))

                    // Thumb
                    let thumbY = geo.size.height * (1 - CGFloat(value))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: 18, height: 6)
                        .position(x: geo.size.width / 2, y: thumbY)
                }
                .frame(maxWidth: .infinity)
                .gesture(
                    DragGesture()
                        .onChanged { drag in
                            let normalized = 1 - Float(drag.location.y / geo.size.height)
                            value = max(0, min(1, normalized))
                        }
                )
            }
        }
    }
}
