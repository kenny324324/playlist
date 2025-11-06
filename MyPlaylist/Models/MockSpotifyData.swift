//
//  MockSpotifyData.swift
//  MyPlaylist
//
//  模擬的 Spotify 數據 - 用於 Demo 模式
//

import Foundation

struct MockSpotifyData {
    
    // MARK: - Demo 用戶資料
    
    static let demoUser = SpotifyUser(
        display_name: "Demo User",
        images: [
            SpotifyImage(url: "https://i.imgur.com/demo_avatar.jpg")
        ],
        email: "demo@myplaylist.app",
        id: "demo_user_123",
        followers: SpotifyUser.Followers(total: 42)
    )
    
    // MARK: - Demo 歌曲列表
    
    static let demoTracks: [Track] = [
        Track(
            id: "demo_track_1",
            name: "Blinding Lights",
            previewUrl: "https://p.scdn.co/mp3-preview/",
            artists: [Track.TrackArtist(id: "demo_artist_1", name: "The Weeknd")],
            album: Track.TrackAlbum(
                id: "demo_album_1",
                name: "After Hours",
                images: [Track.TrackAlbum.TrackImage(url: "https://i.scdn.co/image/ab67616d0000b273")]
            )
        ),
        Track(
            id: "demo_track_2",
            name: "Shape of You",
            previewUrl: "https://p.scdn.co/mp3-preview/",
            artists: [Track.TrackArtist(id: "demo_artist_2", name: "Ed Sheeran")],
            album: Track.TrackAlbum(
                id: "demo_album_2",
                name: "÷ (Divide)",
                images: [Track.TrackAlbum.TrackImage(url: "https://i.scdn.co/image/ab67616d0000b273")]
            )
        ),
        Track(
            id: "demo_track_3",
            name: "Levitating",
            previewUrl: "https://p.scdn.co/mp3-preview/",
            artists: [Track.TrackArtist(id: "demo_artist_3", name: "Dua Lipa")],
            album: Track.TrackAlbum(
                id: "demo_album_3",
                name: "Future Nostalgia",
                images: [Track.TrackAlbum.TrackImage(url: "https://i.scdn.co/image/ab67616d0000b273")]
            )
        ),
        Track(
            id: "demo_track_4",
            name: "Someone Like You",
            previewUrl: "https://p.scdn.co/mp3-preview/",
            artists: [Track.TrackArtist(id: "demo_artist_4", name: "Adele")],
            album: Track.TrackAlbum(
                id: "demo_album_4",
                name: "21",
                images: [Track.TrackAlbum.TrackImage(url: "https://i.scdn.co/image/ab67616d0000b273")]
            )
        ),
        Track(
            id: "demo_track_5",
            name: "Anti-Hero",
            previewUrl: "https://p.scdn.co/mp3-preview/",
            artists: [Track.TrackArtist(id: "demo_artist_5", name: "Taylor Swift")],
            album: Track.TrackAlbum(
                id: "demo_album_5",
                name: "Midnights",
                images: [Track.TrackAlbum.TrackImage(url: "https://i.scdn.co/image/ab67616d0000b273")]
            )
        ),
        Track(
            id: "demo_track_6",
            name: "As It Was",
            previewUrl: "https://p.scdn.co/mp3-preview/",
            artists: [Track.TrackArtist(id: "demo_artist_6", name: "Harry Styles")],
            album: Track.TrackAlbum(
                id: "demo_album_6",
                name: "Harry's House",
                images: [Track.TrackAlbum.TrackImage(url: "https://i.scdn.co/image/ab67616d0000b273")]
            )
        ),
        Track(
            id: "demo_track_7",
            name: "Bad Guy",
            previewUrl: "https://p.scdn.co/mp3-preview/",
            artists: [Track.TrackArtist(id: "demo_artist_7", name: "Billie Eilish")],
            album: Track.TrackAlbum(
                id: "demo_album_7",
                name: "When We All Fall Asleep, Where Do We Go?",
                images: [Track.TrackAlbum.TrackImage(url: "https://i.scdn.co/image/ab67616d0000b273")]
            )
        ),
        Track(
            id: "demo_track_8",
            name: "Flowers",
            previewUrl: "https://p.scdn.co/mp3-preview/",
            artists: [Track.TrackArtist(id: "demo_artist_8", name: "Miley Cyrus")],
            album: Track.TrackAlbum(
                id: "demo_album_8",
                name: "Endless Summer Vacation",
                images: [Track.TrackAlbum.TrackImage(url: "https://i.scdn.co/image/ab67616d0000b273")]
            )
        ),
        Track(
            id: "demo_track_9",
            name: "Starboy",
            previewUrl: "https://p.scdn.co/mp3-preview/",
            artists: [Track.TrackArtist(id: "demo_artist_1", name: "The Weeknd")],
            album: Track.TrackAlbum(
                id: "demo_album_9",
                name: "Starboy",
                images: [Track.TrackAlbum.TrackImage(url: "https://i.scdn.co/image/ab67616d0000b273")]
            )
        ),
        Track(
            id: "demo_track_10",
            name: "Perfect",
            previewUrl: "https://p.scdn.co/mp3-preview/",
            artists: [Track.TrackArtist(id: "demo_artist_2", name: "Ed Sheeran")],
            album: Track.TrackAlbum(
                id: "demo_album_2",
                name: "÷ (Divide)",
                images: [Track.TrackAlbum.TrackImage(url: "https://i.scdn.co/image/ab67616d0000b273")]
            )
        )
    ]
    
    // MARK: - Demo 藝人列表
    
    static let demoArtists: [Artist] = [
        Artist(
            id: "demo_artist_1",
            name: "The Weeknd",
            followers: Artist.Followers(total: 89_543_210),
            images: [Artist.SpotifyArtistImage(url: "https://i.scdn.co/image/ab6761610000e5eb")],
            popularity: 95,
            genres: ["pop", "r&b", "canadian pop"]
        ),
        Artist(
            id: "demo_artist_2",
            name: "Ed Sheeran",
            followers: Artist.Followers(total: 102_876_543),
            images: [Artist.SpotifyArtistImage(url: "https://i.scdn.co/image/ab6761610000e5eb")],
            popularity: 93,
            genres: ["pop", "singer-songwriter", "uk pop"]
        ),
        Artist(
            id: "demo_artist_3",
            name: "Dua Lipa",
            followers: Artist.Followers(total: 87_234_567),
            images: [Artist.SpotifyArtistImage(url: "https://i.scdn.co/image/ab6761610000e5eb")],
            popularity: 92,
            genres: ["pop", "dance pop", "uk pop"]
        ),
        Artist(
            id: "demo_artist_4",
            name: "Adele",
            followers: Artist.Followers(total: 45_678_901),
            images: [Artist.SpotifyArtistImage(url: "https://i.scdn.co/image/ab6761610000e5eb")],
            popularity: 90,
            genres: ["british soul", "pop", "uk pop"]
        ),
        Artist(
            id: "demo_artist_5",
            name: "Taylor Swift",
            followers: Artist.Followers(total: 98_765_432),
            images: [Artist.SpotifyArtistImage(url: "https://i.scdn.co/image/ab6761610000e5eb")],
            popularity: 97,
            genres: ["pop", "country", "singer-songwriter"]
        ),
        Artist(
            id: "demo_artist_6",
            name: "Harry Styles",
            followers: Artist.Followers(total: 65_432_109),
            images: [Artist.SpotifyArtistImage(url: "https://i.scdn.co/image/ab6761610000e5eb")],
            popularity: 91,
            genres: ["pop", "rock", "indie pop"]
        ),
        Artist(
            id: "demo_artist_7",
            name: "Billie Eilish",
            followers: Artist.Followers(total: 76_543_210),
            images: [Artist.SpotifyArtistImage(url: "https://i.scdn.co/image/ab6761610000e5eb")],
            popularity: 94,
            genres: ["electropop", "indie pop", "alt z"]
        ),
        Artist(
            id: "demo_artist_8",
            name: "Miley Cyrus",
            followers: Artist.Followers(total: 54_321_098),
            images: [Artist.SpotifyArtistImage(url: "https://i.scdn.co/image/ab6761610000e5eb")],
            popularity: 88,
            genres: ["pop", "dance pop", "electropop"]
        )
    ]
    
    // MARK: - Demo 播放列表
    
    static let demoPlaylists: [Playlist] = [
        Playlist(
            id: "demo_playlist_1",
            name: "My Top Hits",
            images: [SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273")],
            owner: Playlist.Owner(display_name: "Demo User")
        ),
        Playlist(
            id: "demo_playlist_2",
            name: "Chill Vibes",
            images: [SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273")],
            owner: Playlist.Owner(display_name: "Demo User")
        ),
        Playlist(
            id: "demo_playlist_3",
            name: "Workout Mix",
            images: [SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273")],
            owner: Playlist.Owner(display_name: "Demo User")
        ),
        Playlist(
            id: "demo_playlist_4",
            name: "Evening Relaxation",
            images: [SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273")],
            owner: Playlist.Owner(display_name: "Demo User")
        )
    ]
    
    // MARK: - Demo 目前播放
    
    static let demoCurrentlyPlaying = CurrentlyPlayingTrack(
        id: "demo_track_1",
        name: "Blinding Lights",
        artists: [CurrentlyPlayingTrack.CurrentlyPlayingArtist(id: "demo_artist_1", name: "The Weeknd")],
        album: CurrentlyPlayingTrack.CurrentlyPlayingAlbum(
            id: "demo_album_1",
            name: "After Hours",
            images: [SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273")]
        ),
        preview_url: "https://p.scdn.co/mp3-preview/",
        duration_ms: 200_040
    )
    
    // MARK: - Demo 最近播放
    
    static let demoRecentlyPlayed: [RecentlyPlayedTrack] = [
        RecentlyPlayedTrack(
            track: demoCurrentlyPlaying,
            played_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600))
        ),
        RecentlyPlayedTrack(
            track: CurrentlyPlayingTrack(
                id: "demo_track_2",
                name: "Shape of You",
                artists: [CurrentlyPlayingTrack.CurrentlyPlayingArtist(id: "demo_artist_2", name: "Ed Sheeran")],
                album: CurrentlyPlayingTrack.CurrentlyPlayingAlbum(
                    id: "demo_album_2",
                    name: "÷ (Divide)",
                    images: [SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273")]
                ),
                preview_url: "https://p.scdn.co/mp3-preview/",
                duration_ms: 233_712
            ),
            played_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200))
        )
    ]
    
    // MARK: - Demo 收藏歌曲
    
    static let demoSavedTracks: [SavedTrackItem] = demoTracks.prefix(5).map { track in
        SavedTrackItem(
            added_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-Double.random(in: 0...86400*30))),
            track: track
        )
    }
    
    // MARK: - Demo 收藏專輯
    
    static let demoSavedAlbums: [SavedAlbumItem] = [
        SavedAlbumItem(
            added_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400*7)),
            album: Album(
                id: "demo_album_1",
                name: "After Hours",
                artists: [Album.AlbumArtist(name: "The Weeknd")],
                images: [SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273")],
                release_date: "2020-03-20"
            )
        ),
        SavedAlbumItem(
            added_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400*14)),
            album: Album(
                id: "demo_album_5",
                name: "Midnights",
                artists: [Album.AlbumArtist(name: "Taylor Swift")],
                images: [SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273")],
                release_date: "2022-10-21"
            )
        )
    ]
    
    // MARK: - Demo 追蹤的藝人
    
    static let demoFollowedArtists: [Artist] = Array(demoArtists.prefix(6))
    
    // MARK: - Demo 歌曲詳細資訊
    
    static func demoTrackDetail(for trackId: String) -> TrackDetail {
        return TrackDetail(
            id: trackId,
            name: "Blinding Lights",
            artists: [TrackDetail.TrackDetailArtist(id: "demo_artist_1", name: "The Weeknd")],
            album: TrackDetail.TrackDetailAlbum(
                id: "demo_album_1",
                name: "After Hours",
                images: [SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273")],
                release_date: "2020-03-20",
                total_tracks: 14
            ),
            duration_ms: 200_040,
            explicit: false,
            popularity: 95,
            preview_url: "https://p.scdn.co/mp3-preview/",
            external_urls: TrackDetail.ExternalUrls(spotify: "https://open.spotify.com/track/demo"),
            track_number: 3,
            uri: "spotify:track:demo"
        )
    }
    
    // MARK: - Demo 音訊特徵
    
    static func demoAudioFeatures(for trackId: String) -> AudioFeatures {
        return AudioFeatures(
            id: trackId,
            danceability: 0.735,
            energy: 0.789,
            key: 1,
            loudness: -5.934,
            mode: 1,
            speechiness: 0.0598,
            acousticness: 0.00146,
            instrumentalness: 0.000134,
            liveness: 0.0897,
            valence: 0.456,
            tempo: 171.005,
            duration_ms: 200_040,
            time_signature: 4
        )
    }
    
    // MARK: - Demo 搜尋結果
    
    static func demoSearchResults(query: String) -> SearchResponse {
        return SearchResponse(
            tracks: SearchResponse.SearchTracksContainer(items: Array(demoTracks.prefix(5))),
            artists: SearchResponse.SearchArtistsContainer(items: demoArtists.prefix(5).map { artist in
                SearchArtist(
                    id: artist.id,
                    name: artist.name,
                    images: artist.images.map { SpotifyImage(url: $0.url) },
                    popularity: artist.popularity,
                    genres: artist.genres,
                    followers: SearchArtist.Followers(total: artist.followers.total)
                )
            }),
            albums: SearchResponse.SearchAlbumsContainer(items: demoSavedAlbums.map { $0.album })
        )
    }
    
    // MARK: - Demo 新發行專輯
    
    static let demoNewReleases: [NewReleaseAlbum] = [
        NewReleaseAlbum(
            id: "demo_new_1",
            name: "New Album 2024",
            images: [SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273")],
            artists: [NewReleaseAlbum.NewReleaseArtist(name: "Popular Artist", id: "demo_artist_1")],
            release_date: "2024-11-01"
        ),
        NewReleaseAlbum(
            id: "demo_new_2",
            name: "Fresh Sounds",
            images: [SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273")],
            artists: [NewReleaseAlbum.NewReleaseArtist(name: "Rising Star", id: "demo_artist_2")],
            release_date: "2024-10-28"
        )
    ]
}

