import Foundation
import Combine
#if os(iOS)
import UIKit
#endif

class BrowserViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var searchText: String = ""
    @Published var selectedSource: BrowseSource = .local
    @Published var spotifyTracks: [Track] = []
    @Published var isLoading = false

    enum BrowseSource: String, CaseIterable {
        case local = "File Locali"
        case spotify = "Spotify"
    }

    var filteredTracks: [Track] {
        let source = selectedSource == .local ? tracks : spotifyTracks
        if searchText.isEmpty { return source }
        let query = searchText.lowercased()
        return source.filter {
            $0.title.lowercased().contains(query) ||
            $0.artist.lowercased().contains(query) ||
            $0.album.lowercased().contains(query)
        }
    }

    func loadLocalFiles() {
        // Load audio files from Documents directory
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let extensions = ["mp3", "wav", "aiff", "m4a", "flac", "aac"]
            var found: [Track] = []
            
            if let enumerator = fm.enumerator(at: docs, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                for case let url as URL in enumerator {
                    if extensions.contains(url.pathExtension.lowercased()) {
                        let track = Track(
                            title: url.deletingPathExtension().lastPathComponent,
                            artist: "Local",
                            fileURL: url
                        )
                        found.append(track)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self?.tracks = found
                self?.isLoading = false
            }
        }
    }

    func importFiles(urls: [URL]) {
        for url in urls {
            let track = Track(
                title: url.deletingPathExtension().lastPathComponent,
                artist: "",
                fileURL: url
            )
            tracks.append(track)
        }
    }
}
