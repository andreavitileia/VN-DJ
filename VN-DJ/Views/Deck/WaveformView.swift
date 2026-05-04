import SwiftUI

struct WaveformView: View {
    @ObservedObject var deck: DeckViewModel

    private var accentColor: Color { deck.side == .left ? .cyan : .magenta }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                // Waveform bars
                if let track = deck.track, !track.waveformSamples.isEmpty {
                    Canvas { context, size in
                        drawWaveform(context: context, size: size, samples: track.waveformSamples)
                    }
                } else {
                    Text(deck.track == nil ? "Carica un brano" : "Analisi...")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                // Playhead center line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 1)

                // Position overlay
                VStack {
                    Spacer()
                    HStack {
                        // Cue markers
                        if let track = deck.track {
                            ForEach(track.cuePoints) { cue in
                                let xPos = (cue.position / max(1, track.duration)) * geo.size.width
                                Triangle()
                                    .fill(cue.color.swiftUIColor)
                                    .frame(width: 6, height: 6)
                                    .position(x: xPos, y: geo.size.height - 3)
                            }
                        }
                    }
                }

                // Loop highlight
                if let loop = deck.activeLoop, let track = deck.track, track.duration > 0 {
                    let startX = (loop.inPoint / track.duration) * geo.size.width
                    let endX = (loop.outPoint / track.duration) * geo.size.width
                    Rectangle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: endX - startX)
                        .position(x: (startX + endX) / 2, y: geo.size.height / 2)
                }

                // Progress indicator
                if let track = deck.track, track.duration > 0 {
                    let progressX = deck.progress * geo.size.width
                    Rectangle()
                        .fill(accentColor.opacity(0.3))
                        .frame(width: progressX, height: geo.size.height)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .clipped()
        }
    }

    private func drawWaveform(context: GraphicsContext, size: CGSize, samples: [Float]) {
        let count = samples.count
        guard count > 0 else { return }

        let midY = size.height / 2
        let barWidth = max(1, size.width / CGFloat(count))

        for i in 0..<count {
            let x = CGFloat(i) / CGFloat(count) * size.width
            let amplitude = CGFloat(samples[i]) * midY
            let rect = CGRect(x: x, y: midY - amplitude, width: barWidth, height: amplitude * 2)

            let progress = CGFloat(i) / CGFloat(count)
            let color: Color = progress < CGFloat(deck.progress)
                ? .gray.opacity(0.5)
                : accentColor.opacity(0.8)

            context.fill(Path(rect), with: .color(color))
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
