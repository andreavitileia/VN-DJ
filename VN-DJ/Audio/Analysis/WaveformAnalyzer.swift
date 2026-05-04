import AVFoundation
import Accelerate

struct WaveformAnalyzer {
    static func analyze(url: URL, targetSamples: Int = 800) -> [Float] {
        guard let file = try? AVAudioFile(forReading: url) else { return [] }

        let format = file.processingFormat
        let totalFrames = AVAudioFrameCount(file.length)
        guard totalFrames > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else { return [] }

        do {
            try file.read(into: buffer)
        } catch {
            return []
        }

        guard let channelData = buffer.floatChannelData else { return [] }
        let frameCount = Int(buffer.frameLength)
        let samplesPerPixel = max(1, frameCount / targetSamples)
        var output = [Float](repeating: 0, count: targetSamples)

        for i in 0..<targetSamples {
            let start = i * samplesPerPixel
            let end = min(start + samplesPerPixel, frameCount)
            guard end > start else { continue }

            var maxVal: Float = 0
            for j in start..<end {
                let sample = abs(channelData[0][j])
                if sample > maxVal { maxVal = sample }
            }
            output[i] = maxVal
        }

        // Normalize
        var peak: Float = 0
        vDSP_maxv(output, 1, &peak, vDSP_Length(output.count))
        if peak > 0 {
            var scale = 1.0 / peak
            vDSP_vsmul(output, 1, &scale, &output, 1, vDSP_Length(output.count))
        }

        return output
    }

    static func detectBPM(url: URL) -> Double {
        guard let file = try? AVAudioFile(forReading: url) else { return 0 }

        let format = file.processingFormat
        let sampleRate = format.sampleRate
        let totalFrames = AVAudioFrameCount(file.length)

        // Analyze first 30 seconds
        let framesToAnalyze = min(totalFrames, AVAudioFrameCount(sampleRate * 30))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToAnalyze) else { return 0 }

        do { try file.read(into: buffer, frameCount: framesToAnalyze) } catch { return 0 }
        guard let channelData = buffer.floatChannelData else { return 0 }

        let frameCount = Int(buffer.frameLength)

        // Onset detection: energy in short windows
        let windowSize = Int(sampleRate * 0.01) // 10ms windows
        let hopSize = windowSize / 2
        var onsets: [Float] = []

        var prevEnergy: Float = 0
        for i in stride(from: 0, to: frameCount - windowSize, by: hopSize) {
            var energy: Float = 0
            vDSP_svesq(channelData[0] + i, 1, &energy, vDSP_Length(windowSize))
            let diff = max(0, energy - prevEnergy)
            onsets.append(diff)
            prevEnergy = energy
        }

        guard onsets.count > 100 else { return 0 }

        // Autocorrelation to find periodicity
        let minBPM = 60.0
        let maxBPM = 200.0
        let onsetRate = sampleRate / Double(hopSize)
        let minLag = Int(onsetRate * 60.0 / maxBPM)
        let maxLag = Int(onsetRate * 60.0 / minBPM)

        var bestCorr: Float = 0
        var bestLag = minLag

        for lag in minLag...min(maxLag, onsets.count / 2) {
            var corr: Float = 0
            let n = onsets.count - lag
            vDSP_dotpr(onsets, 1, Array(onsets[lag..<lag+n]), 1, &corr, vDSP_Length(n))
            if corr > bestCorr {
                bestCorr = corr
                bestLag = lag
            }
        }

        let bpm = (onsetRate * 60.0) / Double(bestLag)

        // Round to nearest reasonable BPM
        if bpm >= 60 && bpm <= 200 {
            return (bpm * 100).rounded() / 100
        }
        return 0
    }

    static func duration(of url: URL) -> TimeInterval {
        guard let file = try? AVAudioFile(forReading: url) else { return 0 }
        return Double(file.length) / file.processingFormat.sampleRate
    }
}
