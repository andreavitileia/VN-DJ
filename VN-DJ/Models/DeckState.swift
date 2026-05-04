import Foundation

enum DeckSide: String, Codable {
    case left, right
}

enum JogMode: String, Codable {
    case vinyl, cdj
}

enum TempoRange: Double, Codable, CaseIterable {
    case percent6 = 6.0
    case percent10 = 10.0
    case percent16 = 16.0
    case wide = 100.0

    var displayName: String {
        switch self {
        case .percent6: return "±6%"
        case .percent10: return "±10%"
        case .percent16: return "±16%"
        case .wide: return "WIDE"
        }
    }
}

enum QuantizeValue: String, Codable, CaseIterable {
    case oneBeat = "1"
    case halfBeat = "1/2"
    case quarterBeat = "1/4"
    case eighthBeat = "1/8"

    var fraction: Double {
        switch self {
        case .oneBeat: return 1.0
        case .halfBeat: return 0.5
        case .quarterBeat: return 0.25
        case .eighthBeat: return 0.125
        }
    }
}

struct ActiveLoop: Equatable {
    var inPoint: TimeInterval
    var outPoint: TimeInterval

    var length: TimeInterval { outPoint - inPoint }
}
