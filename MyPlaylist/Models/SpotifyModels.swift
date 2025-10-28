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

// MARK: - Recommendations Models
struct RecommendationsResponse: Codable {
    let tracks: [Track]
}

// MARK: - New Releases Models
struct NewReleasesResponse: Codable {
    let albums: AlbumsContainer
    
    struct AlbumsContainer: Codable {
        let items: [Album]
    }
}

// MARK: - Featured Playlists Models
struct FeaturedPlaylistsResponse: Codable {
    let playlists: PlaylistsContainer
    
    struct PlaylistsContainer: Codable {
        let items: [Playlist]
    }
} 