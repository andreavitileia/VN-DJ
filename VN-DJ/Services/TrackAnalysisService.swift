import Foundation

class TrackAnalysisService {
    static let shared = TrackAnalysisService()

    func analyze(track: Track, completion: @escaping (Track) -> Void) {
        guard let url = track.fileURL else {
            completion(track)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var analyzed = track

            // Duration
            analyzed.duration = WaveformAnalyzer.duration(of: url)

            // Waveform
            analyzed.waveformSamples = WaveformAnalyzer.analyze(url: url)

            // BPM
            let bpm = WaveformAnalyzer.detectBPM(url: url)
            if bpm > 0 {
                analyzed.bpm = bpm
                analyzed.beatGrid = BeatGrid(firstBeatOffset: 0, bpm: bpm)
            }

            analyzed.analyzedAt = Date()

            DispatchQueue.main.async {
                completion(analyzed)
            }
        }
    }
}
