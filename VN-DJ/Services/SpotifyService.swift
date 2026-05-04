import Foundation
import Combine

class SpotifyService: ObservableObject {
    @Published var isConnected = false
    @Published var userName: String = ""
    @Published var playlists: [SpotifyPlaylist] = []
    @Published var playlistTracks: [Track] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var accessToken: String?

    // Spotify App credentials - configure in Spotify Developer Dashboard
    private let clientID = "YOUR_SPOTIFY_CLIENT_ID"
    private let redirectURI = "vndj://spotify-callback"

    struct SpotifyPlaylist: Identifiable, Codable {
        let id: String
        let name: String
        let trackCount: Int
        let imageURL: String?
    }

    // MARK: - Auth

    func connect() {
        // Build Spotify authorization URL
        let scopes = "user-read-private user-library-read playlist-read-private streaming"
        let encodedScopes = scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? scopes
        let authURL = "https://accounts.spotify.com/authorize?client_id=\(clientID)&response_type=token&redirect_uri=\(redirectURI)&scope=\(encodedScopes)"

        #if os(iOS)
        if let url = URL(string: authURL) {
            DispatchQueue.main.async {
                // Open in Safari for OAuth
                // In production, use ASWebAuthenticationSession
                print("Open auth URL: \(url)")
            }
        }
        #elseif os(macOS)
        if let url = URL(string: authURL) {
            // Open in default browser
            print("Open auth URL: \(url)")
        }
        #endif
    }

    func handleCallback(url: URL) {
        // Parse access token from callback URL fragment
        guard let fragment = url.fragment else { return }
        let params = fragment.components(separatedBy: "&")
        for param in params {
            let pair = param.components(separatedBy: "=")
            if pair.count == 2 && pair[0] == "access_token" {
                accessToken = pair[1]
                isConnected = true
                loadUserProfile()
                loadUserPlaylists()
                return
            }
        }
    }

    // MARK: - API Calls

    func loadUserProfile() {
        apiRequest(endpoint: "me") { [weak self] (result: Result<SpotifyUser, Error>) in
            if case .success(let user) = result {
                DispatchQueue.main.async {
                    self?.userName = user.display_name ?? "DJ"
                }
            }
        }
    }

    func loadUserPlaylists() {
        guard isConnected else { return }
        isLoading = true

        apiRequest(endpoint: "me/playlists?limit=50") { [weak self] (result: Result<SpotifyPaging<SpotifyPlaylistAPI>, Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                if case .success(let paging) = result {
                    self?.playlists = paging.items.map { item in
                        SpotifyPlaylist(
                            id: item.id,
                            name: item.name,
                            trackCount: item.tracks.total,
                            imageURL: item.images?.first?.url
                        )
                    }
                }
            }
        }
    }

    func loadPlaylistTracks(playlistID: String) {
        isLoading = true

        apiRequest(endpoint: "playlists/\(playlistID)/tracks?limit=100") { [weak self] (result: Result<SpotifyPaging<SpotifyPlaylistTrack>, Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                if case .success(let paging) = result {
                    self?.playlistTracks = paging.items.compactMap { item -> Track? in
                        guard let t = item.track else { return nil }
                        return Track(
                            title: t.name,
                            artist: t.artists.map(\.name).joined(separator: ", "),
                            album: t.album.name,
                            duration: Double(t.duration_ms) / 1000.0,
                            spotifyURI: t.uri
                        )
                    }
                }
            }
        }
    }

    // MARK: - Network

    private func apiRequest<T: Decodable>(endpoint: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let token = accessToken,
              let url = URL(string: "https://api.spotify.com/v1/\(endpoint)") else {
            completion(.failure(SpotifyError.notAuthenticated))
            return
        }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(SpotifyError.noData))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    enum SpotifyError: Error {
        case notAuthenticated, noData
    }
}

// MARK: - Spotify API Models

struct SpotifyUser: Codable {
    let id: String
    let display_name: String?
}

struct SpotifyPaging<T: Codable>: Codable {
    let items: [T]
    let total: Int
}

struct SpotifyPlaylistAPI: Codable {
    let id: String
    let name: String
    let tracks: SpotifyPlaylistTracksRef
    let images: [SpotifyImage]?
}

struct SpotifyPlaylistTracksRef: Codable {
    let total: Int
}

struct SpotifyImage: Codable {
    let url: String
}

struct SpotifyPlaylistTrack: Codable {
    let track: SpotifyTrackAPI?
}

struct SpotifyTrackAPI: Codable {
    let id: String
    let name: String
    let uri: String
    let duration_ms: Int
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
}

struct SpotifyArtist: Codable {
    let name: String
}

struct SpotifyAlbum: Codable {
    let name: String
    let images: [SpotifyImage]?
}
