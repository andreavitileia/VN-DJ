import SwiftUI
import UniformTypeIdentifiers

struct BrowserView: View {
    @EnvironmentObject var browser: BrowserViewModel
    @EnvironmentObject var deckA: DeckViewModel
    @EnvironmentObject var deckB: DeckViewModel
    @EnvironmentObject var audioEngine: DJAudioEngine
    @EnvironmentObject var spotifyService: SpotifyService
    @State private var showFileImporter = false

    var body: some View {
        VStack(spacing: 0) {
            // Source tabs + search
            HStack(spacing: 8) {
                ForEach(BrowserViewModel.BrowseSource.allCases, id: \.self) { source in
                    Button(action: { browser.selectedSource = source }) {
                        Text(source.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(browser.selectedSource == source ? .white : .gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(browser.selectedSource == source ? Color.cyan.opacity(0.3) : Color.clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                    TextField("Cerca...", text: $browser.searchText)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .cornerRadius(6)
                .frame(width: 200)

                Button(action: {
                    if browser.selectedSource == .spotify {
                        spotifyService.loadUserPlaylists()
                    } else {
                        showFileImporter = true
                    }
                }) {
                    Image(systemName: browser.selectedSource == .spotify ? "arrow.clockwise" : "folder.badge.plus")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.4))

            // Spotify login if needed
            if browser.selectedSource == .spotify && !spotifyService.isConnected {
                spotifyLoginView
            } else {
                // Track list
                trackListView
            }
        }
        .background(Color.black.opacity(0.7))
        .onAppear { browser.loadLocalFiles() }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: audioTypes, allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                browser.importFiles(urls: urls)
            }
        }
    }

    private var spotifyLoginView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.tv")
                .font(.system(size: 32))
                .foregroundColor(.green)
            Text("Connetti Spotify")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            Button(action: { spotifyService.connect() }) {
                Text("Login con Spotify")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var trackListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    Text("#").frame(width: 30, alignment: .leading)
                    Text("Titolo").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Artista").frame(width: 120, alignment: .leading)
                    Text("BPM").frame(width: 50, alignment: .trailing)
                    Text("Key").frame(width: 40, alignment: .center)
                    Text("Durata").frame(width: 50, alignment: .trailing)
                    Text("").frame(width: 80)
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

                ForEach(Array(browser.filteredTracks.enumerated()), id: \.element.id) { index, track in
                    TrackRow(track: track, index: index + 1) { side in
                        loadTrack(track, to: side)
                    }
                }
            }
        }
    }

    private func loadTrack(_ track: Track, to side: DeckSide) {
        let deck = side == .left ? deckA : deckB
        deck.track = track
        audioEngine.loadTrack(track, on: side)
    }

    private var audioTypes: [UTType] {
        [.audio, .mp3, .wav, .aiff, UTType("public.flac") ?? .audio, UTType("public.aac-audio") ?? .audio]
    }
}

struct TrackRow: View {
    let track: Track
    let index: Int
    let onLoad: (DeckSide) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text("\(index)")
                .frame(width: 30, alignment: .leading)
                .foregroundColor(.gray)

            Text(track.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.white)
                .lineLimit(1)

            Text(track.artist)
                .frame(width: 120, alignment: .leading)
                .foregroundColor(.gray)
                .lineLimit(1)

            Text(track.bpm > 0 ? String(format: "%.0f", track.bpm) : "—")
                .frame(width: 50, alignment: .trailing)
                .foregroundColor(.cyan)

            Text(track.key.displayName)
                .frame(width: 40, alignment: .center)
                .foregroundColor(.yellow.opacity(0.8))

            Text(formatDuration(track.duration))
                .frame(width: 50, alignment: .trailing)
                .foregroundColor(.gray)

            HStack(spacing: 4) {
                Button(action: { onLoad(.left) }) {
                    Text("A")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 28, height: 22)
                        .background(Color.cyan.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(3)
                }
                .buttonStyle(.plain)

                Button(action: { onLoad(.right) }) {
                    Text("B")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 28, height: 22)
                        .background(Color.magenta.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(3)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 80)
        }
        .font(.system(size: 11))
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(index % 2 == 0 ? Color.white.opacity(0.03) : Color.clear)
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        guard d > 0 else { return "—" }
        let m = Int(d) / 60
        let s = Int(d) % 60
        return String(format: "%d:%02d", m, s)
    }
}
