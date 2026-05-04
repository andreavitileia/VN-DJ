import Foundation
import Combine

class DeckViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let side: DeckSide

    @Published var track: Track?
    @Published var isPlaying = false
    @Published var currentPosition: TimeInterval = 0
    @Published var tempo: Double = 0.0
    @Published var tempoRange: TempoRange = .percent10
    @Published var masterTempo: Bool = true
    @Published var isMaster: Bool = false
    @Published var syncEnabled: Bool = false
    @Published var quantizeEnabled: Bool = true
    @Published var activeLoop: ActiveLoop?
    @Published var keyShift: Int = 0
    @Published var cuePosition: TimeInterval = 0

    var effectiveBPM: Double {
        guard let track = track else { return 0 }
        return track.bpm * (1.0 + tempo / 100.0)
    }

    var effectiveKey: MusicalKey {
        guard let track = track else { return .unknown }
        return track.key.shifted(by: keyShift)
    }

    var remainingTime: TimeInterval {
        guard let track = track else { return 0 }
        return max(0, track.duration - currentPosition)
    }

    var progress: Double {
        guard let track = track, track.duration > 0 else { return 0 }
        return currentPosition / track.duration
    }

    init(side: DeckSide) {
        self.side = side
        if side == .left { isMaster = true }
    }

    // MARK: - Hot Cue

    func setCuePoint(slot: CueSlot) {
        guard var track = track else { return }
        if track.cuePoints.contains(where: { $0.slot == slot }) { return }
        let colors: [CueColor] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink]
        let colorIndex = CueSlot.allCases.firstIndex(of: slot) ?? 0
        let cue = CuePoint(slot: slot, position: currentPosition, color: colors[colorIndex % colors.count])
        track.cuePoints.append(cue)
        self.track = track
    }

    func jumpToCue(slot: CueSlot) -> TimeInterval? {
        guard let cue = track?.cuePoints.first(where: { $0.slot == slot }) else { return nil }
        currentPosition = cue.position
        return cue.position
    }

    func deleteCue(slot: CueSlot) {
        guard var track = track else { return }
        track.cuePoints.removeAll { $0.slot == slot }
        self.track = track
    }

    func cuePoint(for slot: CueSlot) -> CuePoint? {
        track?.cuePoints.first { $0.slot == slot }
    }

    // MARK: - Loop

    func activateLoop(beats: Double) {
        guard let track = track, track.bpm > 0 else { return }
        let beatDuration = 60.0 / (track.bpm * (1.0 + tempo / 100.0))
        let loopLen = beatDuration * beats
        let inPt = quantizeEnabled ? track.beatGrid.nearestBeat(to: currentPosition) : currentPosition
        activeLoop = ActiveLoop(inPoint: inPt, outPoint: inPt + loopLen)
    }

    func deactivateLoop() {
        activeLoop = nil
    }

    func halveLoop() {
        guard var loop = activeLoop else { return }
        let newLen = loop.length / 2.0
        if newLen > 0.03 {
            loop = ActiveLoop(inPoint: loop.inPoint, outPoint: loop.inPoint + newLen)
            activeLoop = loop
        }
    }

    func doubleLoop() {
        guard var loop = activeLoop else { return }
        let newLen = loop.length * 2.0
        loop = ActiveLoop(inPoint: loop.inPoint, outPoint: loop.inPoint + newLen)
        activeLoop = loop
    }

    // MARK: - Beat Jump

    func beatJump(forward: Bool, beats: Double) {
        guard let track = track, track.bpm > 0 else { return }
        let beatDuration = 60.0 / (track.bpm * (1.0 + tempo / 100.0))
        let jump = beatDuration * beats * (forward ? 1.0 : -1.0)
        let newPos = max(0, min(currentPosition + jump, track.duration))
        currentPosition = newPos
    }

    // MARK: - Cue

    func setCue() {
        cuePosition = currentPosition
    }

    func jumpToCue() {
        currentPosition = cuePosition
    }

    // MARK: - Tempo

    func adjustTempo(by delta: Double) {
        let maxRange = tempoRange.rawValue
        tempo = max(-maxRange, min(maxRange, tempo + delta))
    }

    func resetTempo() {
        tempo = 0
    }

    func cycleTempoRange() {
        let all = TempoRange.allCases
        guard let idx = all.firstIndex(of: tempoRange) else { return }
        tempoRange = all[(idx + 1) % all.count]
    }
}
