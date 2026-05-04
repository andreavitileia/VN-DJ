import Foundation

enum CrossfaderCurve: String, Codable, CaseIterable {
    case smooth, linear, sharp

    var displayName: String { rawValue.capitalized }
}

enum EffectType: String, Codable, CaseIterable {
    case echo = "Echo"
    case delay = "Delay"
    case reverb = "Reverb"
    case flanger = "Flanger"
    case phaser = "Phaser"
    case filter = "Filter"
    case noise = "Noise"
    case bitcrusher = "Bitcrush"
    case roll = "Roll"
    case spiral = "Spiral"
}
