import Foundation

struct BeatGrid: Codable, Equatable {
    var firstBeatOffset: TimeInterval
    var bpm: Double
    var beats: [Beat]
    var isManuallyAdjusted: Bool

    init(firstBeatOffset: TimeInterval = 0, bpm: Double = 0, beats: [Beat] = [], isManuallyAdjusted: Bool = false) {
        self.firstBeatOffset = firstBeatOffset
        self.bpm = bpm
        self.beats = beats
        self.isManuallyAdjusted = isManuallyAdjusted
    }

    func beatPosition(at index: Int) -> TimeInterval {
        guard bpm > 0 else { return 0 }
        let beatDuration = 60.0 / bpm
        return firstBeatOffset + Double(index) * beatDuration
    }

    func nearestBeat(to position: TimeInterval) -> TimeInterval {
        guard bpm > 0 else { return position }
        let beatDuration = 60.0 / bpm
        let beatIndex = round((position - firstBeatOffset) / beatDuration)
        return firstBeatOffset + beatIndex * beatDuration
    }

    func beatsPerBar() -> Int { 4 }
}

struct Beat: Codable, Equatable {
    var position: TimeInterval
    var barNumber: Int
    var beatInBar: Int
}

struct SavedLoop: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var inPoint: TimeInterval
    var outPoint: TimeInterval
    var color: String

    init(id: UUID = UUID(), name: String = "", inPoint: TimeInterval = 0, outPoint: TimeInterval = 0, color: String = "cyan") {
        self.id = id
        self.name = name
        self.inPoint = inPoint
        self.outPoint = outPoint
        self.color = color
    }

    var length: TimeInterval { outPoint - inPoint }
}
