import SwiftUI

struct DeckView: View {
    @ObservedObject var deck: DeckViewModel
    @EnvironmentObject var audioEngine: DJAudioEngine
    let side: DeckSide

    private var accentColor: Color { side == .left ? .cyan : .magenta }

    var body: some View {
        VStack(spacing: 4) {
            // Track info LCD display
            trackDisplay

            // Jog Wheel
            JogWheelView(deck: deck, side: side)
                .padding(.horizontal, 8)

            // Transport bar: CUE + PLAY
            transportBar

            // Hot Cue pads (8 backlit pads)
            hotCuePads

            // Loop controls
            loopBar

            // Tempo fader
            tempoSection
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accentColor.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Track Display (LCD style)
    private var trackDisplay: some View {
        VStack(spacing: 1) {
            HStack {
                Text(deck.track?.title ?? "NO TRACK LOADED")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(deck.track != nil ? .white : .gray)
                    .lineLimit(1)
                Spacer()
                Text(deck.effectiveKey.displayName)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow.opacity(0.9))
                    .padding(.horizontal, 4)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(2)
            }
            HStack {
                Text(deck.track?.artist ?? "—")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                Spacer()
                Text(formatTime(deck.currentPosition))
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(deck.isPlaying ? .green : .white)
                Text("/")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                Text("-" + formatTime(deck.remainingTime))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.red.opacity(0.9))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(white: 0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Transport: CUE + PLAY (big backlit buttons)
    private var transportBar: some View {
        HStack(spacing: 6) {
            // CUE button
            DJButton(
                label: "CUE",
                isActive: !deck.isPlaying,
                activeColor: .yellow,
                height: 42
            ) {
                toggleCue()
            }

            // PLAY/PAUSE button
            DJButton(
                label: deck.isPlaying ? "PAUSE" : "PLAY",
                icon: deck.isPlaying ? "pause.fill" : "play.fill",
                isActive: deck.isPlaying,
                activeColor: .green,
                height: 42
            ) {
                togglePlay()
            }

            // SYNC
            DJButton(
                label: "SYNC",
                isActive: deck.syncEnabled,
                activeColor: accentColor,
                height: 42
            ) {
                deck.syncEnabled.toggle()
            }
        }
    }

    // MARK: - Hot Cue Pads (backlit rubber pads)
    private var hotCuePads: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 4), spacing: 3) {
            ForEach(CueSlot.allCases, id: \.self) { slot in
                let cue = deck.cuePoint(for: slot)
                HotCuePad(
                    slot: slot,
                    cue: cue,
                    action: {
                        if cue != nil {
                            if let pos = deck.jumpToCue(slot: slot) {
                                audioEngine.seek(to: pos, side: side)
                            }
                        } else {
                            deck.setCuePoint(slot: slot)
                        }
                    },
                    deleteAction: {
                        deck.deleteCue(slot: slot)
                    }
                )
            }
        }
    }

    // MARK: - Loop Bar
    private var loopBar: some View {
        HStack(spacing: 3) {
            LoopButton(label: "1/2", isActive: isLoopActive(0.5)) { toggleLoop(0.5) }
            LoopButton(label: "1", isActive: isLoopActive(1)) { toggleLoop(1) }
            LoopButton(label: "4", isActive: isLoopActive(4)) { toggleLoop(4) }
            LoopButton(label: "8", isActive: isLoopActive(8)) { toggleLoop(8) }
            LoopButton(label: "16", isActive: isLoopActive(16)) { toggleLoop(16) }

            Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 22)

            LoopButton(label: "/2", isActive: false) { deck.halveLoop() }
                .disabled(deck.activeLoop == nil)
            LoopButton(label: "x2", isActive: false) { deck.doubleLoop() }
                .disabled(deck.activeLoop == nil)
            LoopButton(label: "EXIT", isActive: deck.activeLoop != nil, activeColor: .green) { deck.deactivateLoop() }
        }
    }

    // MARK: - Tempo Section
    private var tempoSection: some View {
        HStack(spacing: 8) {
            // Beat jump
            VStack(spacing: 3) {
                Text("BEAT JUMP")
                    .font(.system(size: 7, weight: .heavy))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
                HStack(spacing: 3) {
                    DJButton(label: "<<", isActive: false, activeColor: .white, height: 26, fontSize: 9) {
                        deck.beatJump(forward: false, beats: 4)
                        audioEngine.seek(to: deck.currentPosition, side: side)
                    }
                    DJButton(label: ">>", isActive: false, activeColor: .white, height: 26, fontSize: 9) {
                        deck.beatJump(forward: true, beats: 4)
                        audioEngine.seek(to: deck.currentPosition, side: side)
                    }
                }
            }

            // Tempo fader (horizontal for compact layout)
            VStack(spacing: 2) {
                Text(String(format: "TEMPO  %+.1f%%", deck.tempo))
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundColor(abs(deck.tempo) < 0.1 ? .green : accentColor)
                    .tracking(0.5)

                GeometryReader { geo in
                    let w = geo.size.width
                    let thumbX = CGFloat((deck.tempo + deck.tempoRange.rawValue) / (2.0 * deck.tempoRange.rawValue)) * w

                    ZStack {
                        // Track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.06))
                            .frame(height: 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                            )

                        // Center mark
                        Rectangle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 1.5, height: 14)
                            .position(x: w / 2, y: geo.size.height / 2)

                        // Thumb
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.35), Color(white: 0.15)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 24, height: 16)
                            .overlay(
                                Rectangle()
                                    .fill(accentColor.opacity(0.8))
                                    .frame(width: 12, height: 1)
                            )
                            .position(x: max(12, min(w - 12, thumbX)), y: geo.size.height / 2)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let norm = drag.location.x / w
                                let range = deck.tempoRange.rawValue
                                deck.tempo = Double(norm) * 2.0 * range - range
                                deck.tempo = max(-range, min(range, deck.tempo))
                                audioEngine.setTempo(deck.tempo, side: side)
                            }
                    )
                }
                .frame(height: 20)

                // Range selector
                Button(action: { deck.cycleTempoRange() }) {
                    Text(deck.tempoRange.displayName)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(2)
                }
                .buttonStyle(.plain)
            }

            // Master / Quantize
            VStack(spacing: 3) {
                DJButton(label: "MST", isActive: deck.isMaster, activeColor: .orange, height: 22, fontSize: 8) {
                    deck.isMaster.toggle()
                }
                DJButton(label: "Q", isActive: deck.quantizeEnabled, activeColor: .purple, height: 22, fontSize: 9) {
                    deck.quantizeEnabled.toggle()
                }
            }
            .frame(width: 36)
        }
    }

    // MARK: - Helpers

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

    private func toggleLoop(_ beats: Double) {
        if isLoopActive(beats) {
            deck.deactivateLoop()
        } else {
            deck.activateLoop(beats: beats)
        }
    }

    private func isLoopActive(_ beats: Double) -> Bool {
        guard let loop = deck.activeLoop, deck.effectiveBPM > 0 else { return false }
        let beatDur = 60.0 / deck.effectiveBPM
        return abs(loop.length - beatDur * beats) < 0.01
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        let ms = Int((t - Double(Int(t))) * 10)
        return String(format: "%d:%02d.%d", mins, secs, ms)
    }
}

// MARK: - Reusable DJ Styled Components

struct DJButton: View {
    let label: String
    var icon: String? = nil
    let isActive: Bool
    let activeColor: Color
    var height: CGFloat = 34
    var fontSize: CGFloat = 11
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: fontSize))
                }
                Text(label)
                    .font(.system(size: fontSize, weight: .heavy))
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .foregroundColor(isActive ? .black : .white)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isActive ? activeColor.opacity(0.9) : Color(white: 0.1))
                    .shadow(color: isActive ? activeColor.opacity(0.4) : .clear, radius: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isActive ? activeColor.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct HotCuePad: View {
    let slot: CueSlot
    let cue: CuePoint?
    let action: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        cue != nil
                            ? cue!.color.swiftUIColor.opacity(0.7)
                            : Color(white: 0.08)
                    )
                    .shadow(color: cue != nil ? cue!.color.swiftUIColor.opacity(0.3) : .clear, radius: 4)

                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        cue != nil ? cue!.color.swiftUIColor.opacity(0.5) : Color.white.opacity(0.06),
                        lineWidth: 0.5
                    )

                Text(slot.rawValue)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(cue != nil ? .white : .gray)
            }
            .frame(height: 34)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if cue != nil {
                Button("Elimina", role: .destructive, action: deleteAction)
            }
        }
    }
}

struct LoopButton: View {
    let label: String
    let isActive: Bool
    var activeColor: Color = .green
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 24)
                .foregroundColor(isActive ? .black : .white.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isActive ? activeColor.opacity(0.8) : Color(white: 0.08))
                        .shadow(color: isActive ? activeColor.opacity(0.3) : .clear, radius: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isActive ? activeColor.opacity(0.4) : Color.white.opacity(0.05), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}
