import SwiftUI

struct ContentView: View {
    @EnvironmentObject var deckA: DeckViewModel
    @EnvironmentObject var deckB: DeckViewModel
    @EnvironmentObject var mixer: MixerViewModel
    @EnvironmentObject var browser: BrowserViewModel
    @State private var showBrowser = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar
                    TopBarView(showBrowser: $showBrowser)
                        .frame(height: 44)

                    if showBrowser {
                        BrowserView()
                            .frame(height: geo.size.height * 0.35)
                            .transition(.move(edge: .top))
                    }

                    // Waveform area
                    HStack(spacing: 0) {
                        WaveformView(deck: deckA)
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 1)
                        WaveformView(deck: deckB)
                    }
                    .frame(height: showBrowser ? geo.size.height * 0.15 : geo.size.height * 0.25)

                    // Main area: Deck A + Mixer + Deck B
                    HStack(spacing: 0) {
                        DeckView(deck: deckA, side: .left)
                            .frame(maxWidth: .infinity)

                        MixerView()
                            .frame(width: min(geo.size.width * 0.2, 280))

                        DeckView(deck: deckB, side: .right)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        #if os(iOS)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        #endif
    }
}

struct TopBarView: View {
    @Binding var showBrowser: Bool
    @EnvironmentObject var deckA: DeckViewModel
    @EnvironmentObject var deckB: DeckViewModel

    var body: some View {
        HStack {
            Text("VN DJ")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)

            Spacer()

            Button(action: { withAnimation(.easeInOut(duration: 0.3)) { showBrowser.toggle() } }) {
                HStack(spacing: 4) {
                    Image(systemName: showBrowser ? "chevron.up" : "magnifyingglass")
                    Text("BROWSE")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(showBrowser ? Color.cyan.opacity(0.3) : Color.white.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Spacer()

            // Master BPM display
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("DECK A")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.cyan)
                    Text(String(format: "%.1f", deckA.effectiveBPM))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                VStack(spacing: 2) {
                    Text("DECK B")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.magenta)
                    Text(String(format: "%.1f", deckB.effectiveBPM))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(Color.black.opacity(0.9))
    }
}
