import Foundation
import SwiftUI

struct CuePoint: Identifiable, Codable, Equatable {
    let id: UUID
    var slot: CueSlot
    var position: TimeInterval
    var name: String
    var color: CueColor
    var type: CueType
    var loopLength: TimeInterval?

    init(
        id: UUID = UUID(),
        slot: CueSlot,
        position: TimeInterval,
        name: String = "",
        color: CueColor = .red,
        type: CueType = .hotCue,
        loopLength: TimeInterval? = nil
    ) {
        self.id = id
        self.slot = slot
        self.position = position
        self.name = name
        self.color = color
        self.type = type
        self.loopLength = loopLength
    }
}

enum CueSlot: String, Codable, CaseIterable {
    case A, B, C, D, E, F, G, H
}

enum CueColor: String, Codable, CaseIterable {
    case red, orange, yellow, green, cyan, blue, purple, pink

    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .cyan: return .cyan
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        }
    }
}

enum CueType: String, Codable {
    case hotCue
    case hotCueLoop
}
