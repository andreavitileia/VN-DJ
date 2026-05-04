import Foundation

enum MusicalKey: String, Codable, CaseIterable {
    case cMajor = "1B"
    case cMinor = "1A"
    case dbMajor = "8B"
    case csMinor = "8A"
    case dMajor = "3B"
    case dMinor = "3A"
    case ebMajor = "10B"
    case dsMinor = "10A"
    case eMajor = "5B"
    case eMinor = "5A"
    case fMajor = "12B"
    case fMinor = "12A"
    case gbMajor = "7B"
    case fsMinor = "7A"
    case gMajor = "2B"
    case gMinor = "2A"
    case abMajor = "9B"
    case gsMinor = "9A"
    case aMajor = "4B"
    case aMinor = "4A"
    case bbMajor = "11B"
    case asMinor = "11A"
    case bMajor = "6B"
    case bMinor = "6A"
    case unknown = "—"

    var displayName: String { rawValue }

    var camelotNumber: Int {
        switch self {
        case .cMajor: return 1
        case .cMinor: return 1
        case .dbMajor: return 8
        case .csMinor: return 8
        case .dMajor: return 3
        case .dMinor: return 3
        case .ebMajor: return 10
        case .dsMinor: return 10
        case .eMajor: return 5
        case .eMinor: return 5
        case .fMajor: return 12
        case .fMinor: return 12
        case .gbMajor: return 7
        case .fsMinor: return 7
        case .gMajor: return 2
        case .gMinor: return 2
        case .abMajor: return 9
        case .gsMinor: return 9
        case .aMajor: return 4
        case .aMinor: return 4
        case .bbMajor: return 11
        case .asMinor: return 11
        case .bMajor: return 6
        case .bMinor: return 6
        case .unknown: return 0
        }
    }

    var isMajor: Bool {
        rawValue.hasSuffix("B")
    }

    func isCompatible(with other: MusicalKey) -> Bool {
        if self == .unknown || other == .unknown { return false }
        if self == other { return true }
        let diff = abs(camelotNumber - other.camelotNumber)
        if diff <= 1 || diff == 11 { return true }
        if camelotNumber == other.camelotNumber && isMajor != other.isMajor { return true }
        return false
    }

    func shifted(by semitones: Int) -> MusicalKey {
        let allKeys = MusicalKey.allCases.filter { $0 != .unknown }
        guard let idx = allKeys.firstIndex(of: self) else { return self }
        let newIdx = (idx + semitones * 2 + allKeys.count * 100) % allKeys.count
        return allKeys[newIdx]
    }
}
