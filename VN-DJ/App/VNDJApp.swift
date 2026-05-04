import SwiftUI

@main
struct VNDJApp: App {
    @StateObject private var audioEngine = DJAudioEngine()
    @StateObject private var deckA = DeckViewModel(side: .left)
    @StateObject private var deckB = DeckViewModel(side: .right)
    @StateObject private var mixer = MixerViewModel()
    @StateObject private var browser = BrowserViewModel()
    @StateObject private var spotifyService = SpotifyService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioEngine)
                .environmentObject(deckA)
                .environmentObject(deckB)
                .environmentObject(mixer)
                .environmentObject(browser)
                .environmentObject(spotifyService)
                .onAppear {
                    audioEngine.setup(deckA: deckA, deckB: deckB, mixer: mixer)
                }
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1440, height: 900)
        #endif
    }
}
