import Foundation
import SwiftUI

extension Color {
    static let magenta = Color(red: 1.0, green: 0.0, blue: 0.8)
}

enum AppConstants {
    static let appName = "VN DJ"
    static let version = "1.0.0"

    enum Audio {
        static let sampleRate: Double = 44100
        static let bufferSize: UInt32 = 256
        static let channels: UInt32 = 2
    }

    enum UI {
        static let deckBackgroundColor = Color.black.opacity(0.6)
        static let mixerBackgroundColor = Color.gray.opacity(0.08)
        static let accentA = Color.cyan
        static let accentB = Color.magenta

        static let hotCueColors: [Color] = [
            .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink
        ]
    }

    enum Tempo {
        static let defaultRange: Double = 10.0
        static let minBPM: Double = 60.0
        static let maxBPM: Double = 200.0
    }
}
