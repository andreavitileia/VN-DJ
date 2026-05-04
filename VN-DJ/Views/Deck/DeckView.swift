import SwiftUI

struct DeckView: View {
    @ObservedObject var deck: DeckViewModel
    @EnvironmentObject var audioEngine: DJAudioEngine
    let side: DeckSide

    private var accentColor: Color { side == .left ? .cyan : .magenta }

    var body: some View {
        VStack(spacing: 6) {
            // Track info
            trackInfoBar

            // Hot Cue buttons
            hotCueRow

            // Loop controls
            loopRow

            // Transport + Tempo
            HStack(spacing: 8) {
                transportControls
                tempoSlider
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.6))
    }

    // MARK: - Track Info
    private var trackInfoBar: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(deck.track?.title ?? "No Track")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(deck.track?.artist ?? "—")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f BPM", deck.effectiveBPM))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)
                Text(deck.effectiveKey.displayName)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(deck.currentPosition))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.green)
                Text("-" + formatTime(deck.remainingTime))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.red.opacity(0.8))
            }
        }
    }

    // MARK: - Hot Cue
    private var hotCueRow: some View {
        HStack(spacing: 4) {
            ForEach(CueSlot.allCases, id: \.self) { slot in
                let cue = deck.cuePoint(for: slot)
                Button(action: {
                    if cue != nil {
                        if let pos = deck.jumpToCue(slot: slot) {
                            audioEngine.seek(to: pos, side: side)
                        }
                    } else {
                        deck.setCuePoint(slot: slot)
                    }
                }) {
                    Text(slot.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(cue != nil ? cue!.color.swiftUIColor.opacity(0.8) : Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if cue != nil {
                        Button("Elimina", role: .destructive) {
                            deck.deleteCue(slot: slot)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Loop
    private var loopRow: some View {
        HStack(spacing: 4) {
            loopButton(label: "1/2", beats: 0.5)
            loopButton(label: "1", beats: 1)
            loopButton(label: "4", beats: 4)
            loopButton(label: "8", beats: 8)
            loopButton(label: "16", beats: 16)

            Button(action: { deck.halveLoop() }) {
                Image(systemName: "divide")
                    .font(.system(size: 10))
                    .frame(width: 30, height: 26)
                    .background(Color.orange.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .disabled(deck.activeLoop == nil)

            Button(action: { deck.doubleLoop() }) {
                Image(systemName: "multiply")
                    .font(.system(size: 10))
                    .frame(width: 30, height: 26)
                    .background(Color.orange.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .disabled(deck.activeLoop == nil)

            Button(action: { deck.deactivateLoop() }) {
                Text("EXIT")
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: 36, height: 26)
                    .background(deck.activeLoop != nil ? Color.green.opacity(0.6) : Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
    }

    private func loopButton(label: String, beats: Double) -> some View {
        Button(action: {
            if let loop = deck.activeLoop {
                let beatDur = 60.0 / max(1, deck.effectiveBPM)
                let expectedLen = beatDur * beats
                if abs(loop.length - expectedLen) < 0.01 {
                    deck.deactivateLoop()
                } else {
                    deck.activateLoop(beats: beats)
                }
            } else {
                deck.activateLoop(beats: beats)
            }
        }) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .background(isLoopActive(beats: beats) ? Color.green.opacity(0.7) : Color.white.opacity(0.1))
                .foregroundColor(.white)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    private func isLoopActive(beats: Double) -> Bool {
        guard let loop = deck.activeLoop, deck.effectiveBPM > 0 else { return false }
        let beatDur = 60.0 / deck.effectiveBPM
        return abs(loop.length - beatDur * beats) < 0.01
    }

    // MARK: - Transport
    private var transportControls: some View {
        VStack(spacing: 4) {
            // Play / Cue
            HStack(spacing: 6) {
                Button(action: { toggleCue() }) {
                    Text("CUE")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.yellow.opacity(0.6))
                        .foregroundColor(.black)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: { togglePlay() }) {
                    Image(systemName: deck.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(deck.isPlaying ? Color.green.opacity(0.7) : Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            // Beat Jump
            HStack(spacing: 4) {
                Button(action: { deck.beatJump(forward: false, beats: 4) }) {
                    Text("<< 4")
                        .font(.system(size: 9, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)

                Button(action: { deck.beatJump(forward: true, beats: 4) }) {
                    Text("4 >>")
                        .font(.system(size: 9, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }

            // Sync / Master
            HStack(spacing: 4) {
                Button(action: { deck.syncEnabled.toggle() }) {
                    Text("SYNC")
                        .font(.system(size: 10, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 26)
                        .background(deck.syncEnabled ? accentColor.opacity(0.7) : Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)

                Button(action: { deck.isMaster.toggle() }) {
                    Text("MASTER")
                        .font(.system(size: 9, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 26)
                        .background(deck.isMaster ? Color.orange.opacity(0.7) : Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)

                Button(action: { deck.quantizeEnabled.toggle() }) {
                    Text("Q")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 30, height: 26)
                        .background(deck.quantizeEnabled ? Color.purple.opacity(0.6) : Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tempo Slider
    private var tempoSlider: some View {
        VStack(spacing: 2) {
            Text(String(format: "%+.1f%%", deck.tempo))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(abs(deck.tempo) < 0.1 ? .green : .white)

            GeometryReader { geo in
                ZStack(alignment: .center) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 4)

                    // Center line
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 12, height: 1)
                        .offset(y: 0)

                    // Thumb
                    let range = deck.tempoRange.rawValue
                    let normalizedY = CGFloat(-deck.tempo / range) * (geo.size.height / 2.0)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor)
                        .frame(width: 20, height: 8)
                        .offset(y: normalizedY)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let center = geo.size.height / 2.0
                            let offset = value.location.y - center
                            let normalized = -offset / center
                            deck.tempo = Double(normalized) * deck.tempoRange.rawValue
                            deck.tempo = max(-deck.tempoRange.rawValue, min(deck.tempoRange.rawValue, deck.tempo))
                            audioEngine.setTempo(deck.tempo, side: side)
                        }
                )
            }
            .frame(width: 40)

            Button(action: {
                deck.cycleTempoRange()
            }) {
                Text(deck.tempoRange.displayName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func togglePlay() {
        if deck.isPlaying {
            audioEngine.pause(side: side)
        } else {
            audioEngine.play(side: side)
        }
        deck.isPlaying.toggle()
    }

    private func toggleCue() {
        if deck.isPlaying {
            audioEngine.pause(side: side)
            deck.isPlaying = false
            deck.setCue()
        } else {
            audioEngine.seek(to: deck.cuePosition, side: side)
            deck.currentPosition = deck.cuePosition
        }
    }

    // MARK: - Helpers

    private func formatTime(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        let ms = Int((t - Double(Int(t))) * 10)
        return String(format: "%d:%02d.%d", mins, secs, ms)
    }
}
