import Foundation
import Combine

class MixerViewModel: ObservableObject {
    // Channel A
    @Published var volumeA: Float = 1.0
    @Published var eqHighA: Float = 0.0
    @Published var eqMidA: Float = 0.0
    @Published var eqLowA: Float = 0.0
    @Published var cueA: Bool = false

    // Channel B
    @Published var volumeB: Float = 1.0
    @Published var eqHighB: Float = 0.0
    @Published var eqMidB: Float = 0.0
    @Published var eqLowB: Float = 0.0
    @Published var cueB: Bool = false

    // Master
    @Published var crossfader: Float = 0.5
    @Published var crossfaderCurve: CrossfaderCurve = .smooth
    @Published var masterVolume: Float = 1.0
    @Published var headphoneMix: Float = 0.5
    @Published var headphoneVolume: Float = 1.0

    // Levels (for VU meters)
    @Published var levelA: Float = 0.0
    @Published var levelB: Float = 0.0
    @Published var masterLevel: Float = 0.0

    func resetEQ(side: DeckSide) {
        if side == .left {
            eqHighA = 0; eqMidA = 0; eqLowA = 0
        } else {
            eqHighB = 0; eqMidB = 0; eqLowB = 0
        }
    }

    func crossfaderToA() { crossfader = 0.0 }
    func crossfaderToCenter() { crossfader = 0.5 }
    func crossfaderToB() { crossfader = 1.0 }
}
