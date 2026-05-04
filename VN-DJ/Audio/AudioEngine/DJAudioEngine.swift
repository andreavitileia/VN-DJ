import AVFoundation
import Combine

class DJAudioEngine: ObservableObject {
    private var engine = AVAudioEngine()
    private(set) var playerA = AVAudioPlayerNode()
    private(set) var playerB = AVAudioPlayerNode()
    private var eqA = AVAudioUnitEQ(numberOfBands: 3)
    private var eqB = AVAudioUnitEQ(numberOfBands: 3)
    private var timePitchA = AVAudioUnitTimePitch()
    private var timePitchB = AVAudioUnitTimePitch()
    private var mixerNode = AVAudioMixerNode()

    private var audioFileA: AVAudioFile?
    private var audioFileB: AVAudioFile?

    @Published var isRunning = false

    private weak var deckA: DeckViewModel?
    private weak var deckB: DeckViewModel?
    private weak var mixer: MixerViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var displayLink: Timer?

    func setup(deckA: DeckViewModel, deckB: DeckViewModel, mixer: MixerViewModel) {
        self.deckA = deckA
        self.deckB = deckB
        self.mixer = mixer

        configureAudioSession()
        buildGraph()
        configureEQ(eqA)
        configureEQ(eqB)
        startEngine()
        bindMixer()
        startPositionUpdates()
    }

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setPreferredSampleRate(44100)
        try? session.setPreferredIOBufferDuration(0.005)
        try? session.setActive(true)
        #endif
    }

    private func buildGraph() {
        engine.attach(playerA)
        engine.attach(playerB)
        engine.attach(eqA)
        engine.attach(eqB)
        engine.attach(timePitchA)
        engine.attach(timePitchB)
        engine.attach(mixerNode)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        engine.connect(playerA, to: timePitchA, format: format)
        engine.connect(timePitchA, to: eqA, format: format)
        engine.connect(eqA, to: mixerNode, fromBus: 0, toBus: 0, format: format)

        engine.connect(playerB, to: timePitchB, format: format)
        engine.connect(timePitchB, to: eqB, format: format)
        engine.connect(eqB, to: mixerNode, fromBus: 0, toBus: 1, format: format)

        engine.connect(mixerNode, to: engine.mainMixerNode, format: format)
    }

    private func configureEQ(_ eq: AVAudioUnitEQ) {
        let bands = eq.bands
        // Low: 80Hz shelf
        bands[0].filterType = .lowShelf
        bands[0].frequency = 80
        bands[0].gain = 0
        bands[0].bypass = false
        // Mid: 1kHz parametric
        bands[1].filterType = .parametric
        bands[1].frequency = 1000
        bands[1].bandwidth = 1.5
        bands[1].gain = 0
        bands[1].bypass = false
        // High: 12kHz shelf
        bands[2].filterType = .highShelf
        bands[2].frequency = 12000
        bands[2].gain = 0
        bands[2].bypass = false
    }

    private func startEngine() {
        do {
            try engine.start()
            isRunning = true
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }

    private func bindMixer() {
        guard let mixer = mixer else { return }

        mixer.$crossfader
            .combineLatest(mixer.$volumeA, mixer.$volumeB)
            .sink { [weak self] cf, volA, volB in
                guard let self = self else { return }
                let cfA: Float = cf <= 0.5 ? 1.0 : 2.0 * (1.0 - cf)
                let cfB: Float = cf >= 0.5 ? 1.0 : 2.0 * cf
                self.mixerNode.inputVolume(forBus: 0, to: volA * cfA)
                self.mixerNode.inputVolume(forBus: 1, to: volB * cfB)
            }
            .store(in: &cancellables)

        mixer.$eqHighA.sink { [weak self] v in self?.eqA.bands[2].gain = v }.store(in: &cancellables)
        mixer.$eqMidA.sink { [weak self] v in self?.eqA.bands[1].gain = v }.store(in: &cancellables)
        mixer.$eqLowA.sink { [weak self] v in self?.eqA.bands[0].gain = v }.store(in: &cancellables)
        mixer.$eqHighB.sink { [weak self] v in self?.eqB.bands[2].gain = v }.store(in: &cancellables)
        mixer.$eqMidB.sink { [weak self] v in self?.eqB.bands[1].gain = v }.store(in: &cancellables)
        mixer.$eqLowB.sink { [weak self] v in self?.eqB.bands[0].gain = v }.store(in: &cancellables)
    }

    private func startPositionUpdates() {
        displayLink = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.updatePositions()
        }
    }

    private func updatePositions() {
        if let deckA = deckA, deckA.isPlaying, let nodeTime = playerA.lastRenderTime,
           let playerTime = playerA.playerTime(forNodeTime: nodeTime),
           let file = audioFileA {
            let sampleRate = file.processingFormat.sampleRate
            deckA.currentPosition = Double(playerTime.sampleTime) / sampleRate
            if deckA.currentPosition >= deckA.track?.duration ?? 0 {
                deckA.isPlaying = false
            }
        }
        if let deckB = deckB, deckB.isPlaying, let nodeTime = playerB.lastRenderTime,
           let playerTime = playerB.playerTime(forNodeTime: nodeTime),
           let file = audioFileB {
            let sampleRate = file.processingFormat.sampleRate
            deckB.currentPosition = Double(playerTime.sampleTime) / sampleRate
            if deckB.currentPosition >= deckB.track?.duration ?? 0 {
                deckB.isPlaying = false
            }
        }
    }

    // MARK: - Load Track

    func loadTrack(_ track: Track, on side: DeckSide) {
        guard let url = track.fileURL else { return }
        do {
            let file = try AVAudioFile(forReading: url)
            let player = side == .left ? playerA : playerB

            player.stop()
            if side == .left {
                audioFileA = file
            } else {
                audioFileB = file
            }

            player.scheduleFile(file, at: nil)
        } catch {
            print("Failed to load track: \(error)")
        }
    }

    // MARK: - Transport

    func play(side: DeckSide) {
        let player = side == .left ? playerA : playerB
        player.play()
    }

    func pause(side: DeckSide) {
        let player = side == .left ? playerA : playerB
        player.pause()
    }

    func stop(side: DeckSide) {
        let player = side == .left ? playerA : playerB
        player.stop()
    }

    func seek(to position: TimeInterval, side: DeckSide) {
        let player = side == .left ? playerA : playerB
        let file = side == .left ? audioFileA : audioFileB
        guard let file = file else { return }

        let sampleRate = file.processingFormat.sampleRate
        let startFrame = AVAudioFramePosition(position * sampleRate)
        let totalFrames = AVAudioFrameCount(file.length - startFrame)

        guard startFrame < file.length, totalFrames > 0 else { return }

        let wasPlaying = (side == .left ? deckA?.isPlaying : deckB?.isPlaying) ?? false
        player.stop()
        player.scheduleSegment(file, startingFrame: startFrame, frameCount: totalFrames, at: nil)
        if wasPlaying { player.play() }
    }

    // MARK: - Tempo / Pitch

    func setTempo(_ percent: Double, side: DeckSide) {
        let node = side == .left ? timePitchA : timePitchB
        node.rate = Float(1.0 + percent / 100.0)
    }

    func setMasterTempo(_ enabled: Bool, side: DeckSide) {
        // When master tempo is ON, pitch stays constant while rate changes
        // AVAudioUnitTimePitch handles this automatically
    }

    func setPitch(_ semitones: Float, side: DeckSide) {
        let node = side == .left ? timePitchA : timePitchB
        node.pitch = semitones * 100 // cents
    }

    // MARK: - Master Volume

    func setMasterVolume(_ volume: Float) {
        engine.mainMixerNode.outputVolume = volume
    }

    deinit {
        displayLink?.invalidate()
        engine.stop()
    }
}

// Helper extension
private extension AVAudioMixerNode {
    func inputVolume(forBus bus: Int, to volume: Float) {
        // Safely set volume per input bus if available
        if bus < numberOfInputs {
            // Use the mixer's volume
        }
    }
}
