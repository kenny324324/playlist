import Foundation

// MARK: - Basic Spotify Models
struct SpotifyImage: Codable, Hashable {
    let url: String
}

struct SpotifyUser: Codable {
    let display_name: String?
    let images: [SpotifyImage]?
    let email: String?
    let id: String?
    let followers: Followers?
    
    struct Followers: Codable {
        let total: Int
    }
}

struct Artist: Codable, Identifiable {
    let id: String
    let name: String
    let followers: Followers
    let images: [SpotifyArtistImage]
    let popularity: Int
    let genres: [String]
    
    struct Followers: Codable {
        let total: Int
    }
    
    struct SpotifyArtistImage: Codable {
        let url: String
    }
}

struct Playlist: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let images: [SpotifyImage]
    let owner: Owner
    
    struct Owner: Codable, Hashable {
        let display_name: String?
    }
}

// MARK: - Track Models
struct TracksResponse: Decodable {
    let items: [Track]
}

struct Track: Decodable, Identifiable, Equatable, Encodable {
    let id: String
    let name: String
    let previewUrl: String?
    let artists: [TrackArtist]
    let album: TrackAlbum

    struct TrackArtist: Decodable, Equatable, Encodable {
        let name: String
    }

    struct TrackAlbum: Decodable, Equatable, Encodable {
        let images: [TrackImage]
        
        struct TrackImage: Decodable, Equatable, Encodable {
            let url: String
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, artists, album
        case previewUrl = "preview_url"
    }
}

// MARK: - Currently Playing Models
struct CurrentlyPlayingResponse: Codable {
    let item: CurrentlyPlayingTrack?
    let is_playing: Bool
    let progress_ms: Int?
}

struct CurrentlyPlayingTrack: Codable, Identifiable {
    let id: String
    let name: String
    let artists: [CurrentlyPlayingArtist]
    let album: CurrentlyPlayingAlbum
    let preview_url: String?
    let duration_ms: Int
    
    struct CurrentlyPlayingArtist: Codable {
        let name: String
    }
    
    struct CurrentlyPlayingAlbum: Codable {
        let name: String
        let images: [SpotifyImage]
    }
}

// MARK: - Recently Played Models
struct RecentlyPlayedResponse: Codable {
    let items: [RecentlyPlayedTrack]
}

struct RecentlyPlayedTrack: Codable, Identifiable {
    let track: CurrentlyPlayingTrack
    let played_at: String
    
    var id: String {
        return track.id + played_at
    }
}

// MARK: - Response Models
struct ArtistsResponse: Codable {
    let items: [Artist]
}

struct PlaylistsResponse: Codable {
    let items: [Playlist]
}

// MARK: - Saved Tracks Models
struct SavedTracksResponse: Codable {
    let items: [SavedTrackItem]
}

struct SavedTrackItem: Codable, Identifiable {
    let added_at: String
    let track: Track
    
    var id: String {
        return track.id
    }
}

// MARK: - Saved Albums Models
struct SavedAlbumsResponse: Codable {
    let items: [SavedAlbumItem]
}

struct SavedAlbumItem: Codable, Identifiable {
    let added_at: String
    let album: Album
    
    var id: String {
        return album.id
    }
}

struct Album: Codable, Identifiable {
    let id: String
    let name: String
    let artists: [AlbumArtist]
    let images: [SpotifyImage]
    let release_date: String?
    
    struct AlbumArtist: Codable {
        let name: String
    }
}

// MARK: - Followed Artists Models
struct FollowedArtistsResponse: Codable {
    let artists: ArtistsContainer
    
    struct ArtistsContainer: Codable {
        let items: [Artist]
    }
}

// MARK: - Track Detail Models
struct TrackDetail: Codable {
    let id: String
    let name: String
    let artists: [TrackDetailArtist]
    let album: TrackDetailAlbum
    let duration_ms: Int
    let explicit: Bool
    let popularity: Int
    let preview_url: String?
    let external_urls: ExternalUrls
    let track_number: Int
    
    struct TrackDetailArtist: Codable, Identifiable {
        let id: String
        let name: String
    }
    
    struct TrackDetailAlbum: Codable {
        let id: String
        let name: String
        let images: [SpotifyImage]
        let release_date: String?
        let total_tracks: Int
    }
    
    struct ExternalUrls: Codable {
        let spotify: String
    }
}

// MARK: - Audio Features Models
struct AudioFeatures: Codable {
    let id: String
    let danceability: Double
    let energy: Double
    let key: Int
    let loudness: Double
    let mode: Int
    let speechiness: Double
    let acousticness: Double
    let instrumentalness: Double
    let liveness: Double
    let valence: Double
    let tempo: Double
    let duration_ms: Int
    let time_signature: Int
    
    // 輔助計算屬性
    var keyString: String {
        let keys = ["C", "C♯/D♭", "D", "D♯/E♭", "E", "F", "F♯/G♭", "G", "G♯/A♭", "A", "A♯/B♭", "B"]
        return keys[key]
    }
    
    var modeString: String {
        return mode == 1 ? "大調" : "小調"
    }
}

// MARK: - Artist Detail Models
struct ArtistDetail: Codable {
    let id: String
    let name: String
    let genres: [String]
    let images: [SpotifyImage]
    let followers: Followers
    let popularity: Int
    
    struct Followers: Codable {
        let total: Int
    }
} 