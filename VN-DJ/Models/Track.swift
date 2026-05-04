import Foundation

struct Track: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var bpm: Double
    var key: MusicalKey
    var genre: String
    var rating: Int
    var artworkData: Data?
    var fileURL: URL?
    var spotifyURI: String?
    var waveformSamples: [Float]
    var beatGrid: BeatGrid
    var cuePoints: [CuePoint]
    var loops: [SavedLoop]
    var analyzedAt: Date?
    var comment: String
    var color: TrackColor

    init(
        id: UUID = UUID(),
        title: String = "Unknown",
        artist: String = "Unknown",
        album: String = "",
        duration: TimeInterval = 0,
        bpm: Double = 0,
        key: MusicalKey = .unknown,
        genre: String = "",
        rating: Int = 0,
        artworkData: Data? = nil,
        fileURL: URL? = nil,
        spotifyURI: String? = nil,
        waveformSamples: [Float] = [],
        beatGrid: BeatGrid = BeatGrid(),
        cuePoints: [CuePoint] = [],
        loops: [SavedLoop] = [],
        analyzedAt: Date? = nil,
        comment: String = "",
        color: TrackColor = .none
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.bpm = bpm
        self.key = key
        self.genre = genre
        self.rating = rating
        self.artworkData = artworkData
        self.fileURL = fileURL
        self.spotifyURI = spotifyURI
        self.waveformSamples = waveformSamples
        self.beatGrid = beatGrid
        self.cuePoints = cuePoints
        self.loops = loops
        self.analyzedAt = analyzedAt
        self.comment = comment
        self.color = color
    }

    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
}

enum TrackColor: String, Codable, CaseIterable {
    case none, red, orange, yellow, green, cyan, blue, purple, pink
}
