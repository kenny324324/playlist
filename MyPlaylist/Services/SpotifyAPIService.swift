import Foundation

class SpotifyAPIService {
    
    enum SpotifyAPIError: LocalizedError {
        case unauthorized
        case network(Error)
        case decoding(Error)
        case emptyData
        case noData
        
        var errorDescription: String? {
            switch self {
            case .unauthorized:
                return "Spotify 驗證失效，請重新登入。"
            case .network(let error):
                return "無法連線至 Spotify：\(error.localizedDescription)"
            case .decoding(let error):
                return "解析 Spotify 回應失敗：\(error.localizedDescription)"
            case .emptyData, .noData:
                return "Spotify 沒有返回任何資料。"
            }
        }
    }
    
    // 檢查是否為 Demo 模式
    private static var isDemoMode: Bool {
        return DemoModeManager.shared.isDemoMode
    }

    private static func authorizedRequest(url: URL, accessToken: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    private static func executeRequest<T: Decodable>(_ request: URLRequest, decode type: T.Type, completion: @escaping (Result<T, SpotifyAPIError>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.network(error)))
                return
            }
            
            if handleUnauthorized(response: response) {
                completion(.failure(.unauthorized))
                return
            }
            
            guard let data = data else {
                completion(.failure(.emptyData))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(.decoding(error)))
            }
        }.resume()
    }

    private static func handleUnauthorized(response: URLResponse?) -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        if httpResponse.statusCode == 401 {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .spotifyTokenExpired, object: nil)
            }
            return true
        }

        return false
    }
    
    static func fetchTopTracks(
        accessToken: String,
        timeRange: String,
        cacheKey: String? = nil,
        forceRefresh: Bool = false,
        completion: @escaping (Result<[Track], SpotifyAPIError>) -> Void
    ) {
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(.success(MockSpotifyData.demoTracks))
            }
            return
        }
        
        let cacheIdentifier = cacheKey ?? accessToken
        if !forceRefresh, let cached = APIResponseCache.shared.getTopTracks(userId: cacheIdentifier, timeRange: timeRange) {
            completion(.success(cached))
            return
        }
        
        guard let url = URL(string: "https://api.spotify.com/v1/me/top/tracks?limit=50&time_range=\(timeRange)") else {
            completion(.failure(.noData))
            return
        }
        
        let request = authorizedRequest(url: url, accessToken: accessToken)
        executeRequest(request, decode: TracksResponse.self) { result in
            switch result {
            case .success(let response):
                APIResponseCache.shared.setTopTracks(response.items, userId: cacheIdentifier, timeRange: timeRange)
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func fetchTopTracks(accessToken: String, timeRange: String, completion: @escaping ([Track]) -> Void) {
        fetchTopTracks(accessToken: accessToken, timeRange: timeRange, cacheKey: nil, forceRefresh: false) { result in
            switch result {
            case .success(let tracks):
                completion(tracks)
            case .failure(let error):
                print("Error fetching top tracks: \(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    static func fetchCurrentUserProfile(accessToken: String, completion: @escaping (SpotifyUser?) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion(MockSpotifyData.demoUser)
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching user profile: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            if handleUnauthorized(response: response) {
                completion(nil)
                return
            }

            do {
                let user = try JSONDecoder().decode(SpotifyUser.self, from: data)
                completion(user)
            } catch {
                print("Error decoding user profile: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
    
    static func fetchTopArtists(
        accessToken: String,
        timeRange: String = "medium_term",
        cacheKey: String? = nil,
        forceRefresh: Bool = false,
        completion: @escaping (Result<[Artist], SpotifyAPIError>) -> Void
    ) {
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(.success(MockSpotifyData.demoArtists))
            }
            return
        }
        
        let cacheIdentifier = cacheKey ?? accessToken
        if !forceRefresh, let cached = APIResponseCache.shared.getTopArtists(userId: cacheIdentifier, timeRange: timeRange) {
            completion(.success(cached))
            return
        }
        
        guard let url = URL(string: "https://api.spotify.com/v1/me/top/artists?limit=50&time_range=\(timeRange)") else {
            completion(.failure(.noData))
            return
        }
        
        let request = authorizedRequest(url: url, accessToken: accessToken)
        executeRequest(request, decode: ArtistsResponse.self) { result in
            switch result {
            case .success(let response):
                APIResponseCache.shared.setTopArtists(response.items, userId: cacheIdentifier, timeRange: timeRange)
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func fetchTopArtists(accessToken: String, timeRange: String = "medium_term", completion: @escaping ([Artist]) -> Void) {
        fetchTopArtists(accessToken: accessToken, timeRange: timeRange, cacheKey: nil, forceRefresh: false) { result in
            switch result {
            case .success(let artists):
                completion(artists)
            case .failure(let error):
                print("Error fetching top artists: \(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    // 新增的方法來獲取使用者播放列表
    static func fetchUserPlaylists(accessToken: String, completion: @escaping ([Playlist]) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                completion(MockSpotifyData.demoPlaylists)
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/me/playlists")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching playlists: \(error.localizedDescription)")
                completion([])
                return
            }

            if handleUnauthorized(response: response) {
                completion([])
                return
            }

            guard let data = data else {
                print("No data received from Spotify API")
                completion([])
                return
            }

            do {
                let playlistsResponse = try JSONDecoder().decode(PlaylistsResponse.self, from: data)
                completion(playlistsResponse.items)
            } catch {
                print("Error decoding playlists: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }

    // 新增：獲取目前正在播放的歌曲
    static func fetchCurrentlyPlaying(accessToken: String, completion: @escaping (CurrentlyPlayingResponse?) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let response = CurrentlyPlayingResponse(
                    item: MockSpotifyData.demoCurrentlyPlaying,
                    is_playing: true,
                    progress_ms: 45000
                )
                completion(response)
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching currently playing: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if handleUnauthorized(response: response) {
                completion(nil)
                return
            }

            // 檢查是否有內容正在播放
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                // 204 表示沒有內容正在播放
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received from Spotify API")
                completion(nil)
                return
            }

            do {
                let currentlyPlaying = try JSONDecoder().decode(CurrentlyPlayingResponse.self, from: data)
                completion(currentlyPlaying)
            } catch {
                print("Error decoding currently playing: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    // 新增：獲取最近播放的歌曲
    static func fetchRecentlyPlayed(
        accessToken: String,
        limit: Int = 20,
        cacheKey: String? = nil,
        forceRefresh: Bool = false,
        completion: @escaping (Result<[RecentlyPlayedTrack], SpotifyAPIError>) -> Void
    ) {
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                completion(.success(MockSpotifyData.demoRecentlyPlayed))
            }
            return
        }
        
        let cacheIdentifier = cacheKey ?? accessToken
        if !forceRefresh, let cached = APIResponseCache.shared.getRecentlyPlayed(userId: cacheIdentifier) {
            completion(.success(cached))
            return
        }
        
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/recently-played?limit=\(limit)") else {
            completion(.failure(.noData))
            return
        }
        
        let request = authorizedRequest(url: url, accessToken: accessToken)
        executeRequest(request, decode: RecentlyPlayedResponse.self) { result in
            switch result {
            case .success(let response):
                APIResponseCache.shared.setRecentlyPlayed(response.items, userId: cacheIdentifier)
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func fetchRecentlyPlayed(accessToken: String, limit: Int = 20, completion: @escaping ([RecentlyPlayedTrack]) -> Void) {
        fetchRecentlyPlayed(accessToken: accessToken, limit: limit, cacheKey: nil, forceRefresh: false) { result in
            switch result {
            case .success(let tracks):
                completion(tracks)
            case .failure(let error):
                print("Error fetching recently played: \(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    // 新增：獲取收藏的歌曲
    static func fetchSavedTracks(accessToken: String, limit: Int = 10, completion: @escaping ([SavedTrackItem]) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                completion(MockSpotifyData.demoSavedTracks)
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/me/tracks?limit=\(limit)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching saved tracks: \(error.localizedDescription)")
                completion([])
                return
            }

            if handleUnauthorized(response: response) {
                completion([])
                return
            }

            guard let data = data else {
                print("No data received from Spotify API")
                completion([])
                return
            }

            do {
                let savedTracksResponse = try JSONDecoder().decode(SavedTracksResponse.self, from: data)
                completion(savedTracksResponse.items)
            } catch {
                print("Error decoding saved tracks: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    // 新增：獲取收藏的專輯
    static func fetchSavedAlbums(accessToken: String, limit: Int = 10, completion: @escaping ([SavedAlbumItem]) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                completion(MockSpotifyData.demoSavedAlbums)
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/me/albums?limit=\(limit)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching saved albums: \(error.localizedDescription)")
                completion([])
                return
            }

            if handleUnauthorized(response: response) {
                completion([])
                return
            }

            guard let data = data else {
                print("No data received from Spotify API")
                completion([])
                return
            }

            do {
                let savedAlbumsResponse = try JSONDecoder().decode(SavedAlbumsResponse.self, from: data)
                completion(savedAlbumsResponse.items)
            } catch {
                print("Error decoding saved albums: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    // 新增：獲取追蹤的藝術家
    static func fetchFollowedArtists(accessToken: String, limit: Int = 20, completion: @escaping ([Artist]) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                completion(MockSpotifyData.demoFollowedArtists)
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/me/following?type=artist&limit=\(limit)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching followed artists: \(error.localizedDescription)")
                completion([])
                return
            }

            if handleUnauthorized(response: response) {
                completion([])
                return
            }

            guard let data = data else {
                print("No data received from Spotify API")
                completion([])
                return
            }

            do {
                let followedArtistsResponse = try JSONDecoder().decode(FollowedArtistsResponse.self, from: data)
                completion(followedArtistsResponse.artists.items)
            } catch {
                print("Error decoding followed artists: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    // MARK: - Track Detail APIs
    
    // 獲取歌曲詳細資訊
    static func fetchTrackDetail(trackId: String, accessToken: String, completion: @escaping (TrackDetail?) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                completion(MockSpotifyData.demoTrackDetail(for: trackId))
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/tracks/\(trackId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching track detail: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Track detail API status code: \(httpResponse.statusCode)")
            }
            
            if handleUnauthorized(response: response) {
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received from Spotify API")
                completion(nil)
                return
            }
            
            do {
                let trackDetail = try JSONDecoder().decode(TrackDetail.self, from: data)
                completion(trackDetail)
            } catch {
                print("Error decoding track detail: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response data: \(jsonString)")
                }
                completion(nil)
            }
        }.resume()
    }
    
    // 獲取歌曲音訊特徵
    static func fetchAudioFeatures(trackId: String, accessToken: String, completion: @escaping (AudioFeatures?) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                completion(MockSpotifyData.demoAudioFeatures(for: trackId))
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/audio-features/\(trackId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching audio features: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Audio features API status code: \(httpResponse.statusCode)")
                
                // 403 表示此功能不可用，但不應該登出用戶
                if httpResponse.statusCode == 403 {
                    print("Audio features not available for this track/account (403 Forbidden)")
                    completion(nil)
                    return
                }
            }
            
            if handleUnauthorized(response: response) {
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received from Spotify API")
                completion(nil)
                return
            }
            
            do {
                let audioFeatures = try JSONDecoder().decode(AudioFeatures.self, from: data)
                completion(audioFeatures)
            } catch {
                print("Error decoding audio features: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response data: \(jsonString)")
                }
                completion(nil)
            }
        }.resume()
    }
    
    // 獲取藝人詳細資訊
    static func fetchArtistDetail(artistId: String, accessToken: String, completion: @escaping (ArtistDetail?) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // 尋找對應的藝人，如果找不到就返回第一個
                let demoArtist = MockSpotifyData.demoArtists.first { $0.id == artistId } ?? MockSpotifyData.demoArtists.first!
                let artistDetail = ArtistDetail(
                    id: demoArtist.id,
                    name: demoArtist.name,
                    genres: demoArtist.genres,
                    images: demoArtist.images.map { SpotifyImage(url: $0.url) },
                    followers: ArtistDetail.Followers(total: demoArtist.followers.total),
                    popularity: demoArtist.popularity,
                    uri: "spotify:artist:\(demoArtist.id)",
                    external_urls: ArtistDetail.ExternalUrls(spotify: "https://open.spotify.com/artist/\(demoArtist.id)")
                )
                completion(artistDetail)
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/artists/\(artistId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching artist detail: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Artist detail API status code: \(httpResponse.statusCode)")
            }
            
            if handleUnauthorized(response: response) {
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received from Spotify API")
                completion(nil)
                return
            }
            
            do {
                let artistDetail = try JSONDecoder().decode(ArtistDetail.self, from: data)
                completion(artistDetail)
            } catch {
                print("Error decoding artist detail: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response data: \(jsonString)")
                }
                completion(nil)
            }
        }.resume()
    }
    
    // 獲取藝人熱門歌曲
    static func fetchArtistTopTracks(artistId: String, accessToken: String, completion: @escaping ([ArtistTopTrack]) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // 將 demo tracks 轉換為 ArtistTopTrack
                let topTracks = MockSpotifyData.demoTracks.prefix(5).map { track in
                    ArtistTopTrack(
                        id: track.id,
                        name: track.name,
                        album: ArtistTopTrack.ArtistTopTrackAlbum(
                            name: track.album.name ?? "Album",
                            images: track.album.images.map { SpotifyImage(url: $0.url) }
                        ),
                        artists: track.artists.map { ArtistTopTrack.ArtistTopTrackArtist(name: $0.name) },
                        preview_url: track.previewUrl,
                        duration_ms: 200000
                    )
                }
                completion(Array(topTracks))
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/artists/\(artistId)/top-tracks?market=TW")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching artist top tracks: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if handleUnauthorized(response: response) {
                completion([])
                return
            }
            
            guard let data = data else {
                print("No data received from Spotify API")
                completion([])
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ArtistTopTracksResponse.self, from: data)
                completion(response.tracks)
            } catch {
                print("Error decoding artist top tracks: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    // 獲取藝人專輯
    static func fetchArtistAlbums(artistId: String, accessToken: String, limit: Int = 10, completion: @escaping ([ArtistAlbum]) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let albums = MockSpotifyData.demoSavedAlbums.prefix(limit).map { savedAlbum in
                    ArtistAlbum(
                        id: savedAlbum.album.id,
                        name: savedAlbum.album.name,
                        images: savedAlbum.album.images,
                        release_date: savedAlbum.album.release_date,
                        total_tracks: 12,
                        artists: savedAlbum.album.artists.map { ArtistAlbum.ArtistAlbumArtist(name: $0.name) }
                    )
                }
                completion(Array(albums))
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/artists/\(artistId)/albums?market=TW&limit=\(limit)&include_groups=album,single")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching artist albums: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if handleUnauthorized(response: response) {
                completion([])
                return
            }
            
            guard let data = data else {
                print("No data received from Spotify API")
                completion([])
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ArtistAlbumsResponse.self, from: data)
                completion(response.items)
            } catch {
                print("Error decoding artist albums: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    // 獲取專輯詳細資訊
    static func fetchAlbumDetail(albumId: String, accessToken: String, completion: @escaping (AlbumDetail?) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let album = MockSpotifyData.demoSavedAlbums.first?.album ?? MockSpotifyData.demoSavedAlbums[0].album
                let albumDetail = AlbumDetail(
                    id: album.id,
                    name: album.name,
                    images: album.images,
                    artists: album.artists.map { AlbumDetail.AlbumDetailArtist(id: "demo_artist", name: $0.name) },
                    release_date: album.release_date,
                    total_tracks: 14,
                    album_type: "album",
                    popularity: 85,
                    tracks: AlbumTracksResponse(items: MockSpotifyData.demoTracks.prefix(5).map { track in
                        AlbumTrack(
                            id: track.id,
                            name: track.name,
                            track_number: 1,
                            duration_ms: 200000,
                            artists: track.artists.map { AlbumTrack.AlbumTrackArtist(name: $0.name, id: $0.id ?? "demo") },
                            preview_url: track.previewUrl
                        )
                    }),
                    uri: "spotify:album:\(album.id)",
                    external_urls: AlbumDetail.ExternalUrls(spotify: "https://open.spotify.com/album/\(album.id)")
                )
                completion(albumDetail)
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/albums/\(albumId)?market=TW")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching album detail: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Album detail API status code: \(httpResponse.statusCode)")
            }
            
            if handleUnauthorized(response: response) {
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received from Spotify API")
                completion(nil)
                return
            }
            
            do {
                let albumDetail = try JSONDecoder().decode(AlbumDetail.self, from: data)
                completion(albumDetail)
            } catch {
                print("Error decoding album detail: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response data: \(jsonString)")
                }
                completion(nil)
            }
        }.resume()
    }
    
    // MARK: - Search API
    
    // 搜尋歌曲、藝人、專輯
    static func search(query: String, types: [String], accessToken: String, limit: Int = 20, completion: @escaping (SearchResponse?) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(MockSpotifyData.demoSearchResults(query: query))
            }
            return
        }
        
        // URL 編碼搜尋關鍵字
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Failed to encode search query")
            completion(nil)
            return
        }
        
        let typeString = types.joined(separator: ",")
        let urlString = "https://api.spotify.com/v1/search?q=\(encodedQuery)&type=\(typeString)&market=TW&limit=\(limit)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid search URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error searching: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Search API status code: \(httpResponse.statusCode)")
            }
            
            if handleUnauthorized(response: response) {
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received from Spotify API")
                completion(nil)
                return
            }
            
            do {
                let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
                completion(searchResponse)
            } catch {
                print("Error decoding search results: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response data: \(jsonString)")
                }
                completion(nil)
            }
        }.resume()
    }
    
    // MARK: - Browse API
    
    // 獲取精選播放清單
    static func fetchFeaturedPlaylists(accessToken: String, limit: Int = 10, completion: @escaping ([Playlist]) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(MockSpotifyData.demoPlaylists)
            }
            return
        }
        
        // 按照官方文件：使用 locale 參數（不是 market 或 country）
        let urlString = "https://api.spotify.com/v1/browse/featured-playlists?locale=zh_TW&limit=\(limit)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        print("🔍 Fetching featured playlists")
        print("📍 URL: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 Featured playlists API status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 404 {
                    print("⚠️ 404 Error")
                    print("⚠️ Trying without locale parameter...")
                    // 如果帶 locale 失敗，嘗試不帶參數
                    fetchFeaturedPlaylistsWithoutLocale(accessToken: accessToken, limit: limit, completion: completion)
                    return
                }
            }
            
            if handleUnauthorized(response: response) {
                completion([])
                return
            }
            
            guard let data = data else {
                print("No data received from Spotify API")
                completion([])
                return
            }
            
            do {
                let featuredResponse = try JSONDecoder().decode(FeaturedPlaylistsResponse.self, from: data)
                print("✅ Featured playlists fetched successfully: \(featuredResponse.playlists.items.count) playlists")
                completion(featuredResponse.playlists.items)
            } catch {
                print("❌ Error decoding featured playlists: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Response data: \(jsonString.prefix(500))...")
                }
                completion([])
            }
        }.resume()
    }
    
    // 備用方案：不帶 locale 參數
    private static func fetchFeaturedPlaylistsWithoutLocale(accessToken: String, limit: Int, completion: @escaping ([Playlist]) -> Void) {
        let urlString = "https://api.spotify.com/v1/browse/featured-playlists?limit=\(limit)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        print("🔄 Retrying without locale parameter")
        print("📍 URL: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 Retry API status code: \(httpResponse.statusCode)")
            }
            
            if handleUnauthorized(response: response) {
                completion([])
                return
            }
            
            guard let data = data else {
                print("No data received from Spotify API")
                completion([])
                return
            }
            
            do {
                let featuredResponse = try JSONDecoder().decode(FeaturedPlaylistsResponse.self, from: data)
                print("✅ Featured playlists fetched successfully (without locale): \(featuredResponse.playlists.items.count) playlists")
                completion(featuredResponse.playlists.items)
            } catch {
                print("❌ Error decoding featured playlists: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Response data: \(jsonString.prefix(500))...")
                }
                completion([])
            }
        }.resume()
    }
    
    // 獲取新發行專輯
    static func fetchNewReleases(accessToken: String, limit: Int = 20, completion: @escaping ([NewReleaseAlbum]) -> Void) {
        // Demo 模式：返回模擬數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(MockSpotifyData.demoNewReleases)
            }
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/browse/new-releases?limit=\(limit)&market=TW")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching new releases: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("New releases API status code: \(httpResponse.statusCode)")
            }
            
            if handleUnauthorized(response: response) {
                completion([])
                return
            }
            
            guard let data = data else {
                print("No data received from Spotify API")
                completion([])
                return
            }
            
            do {
                let newReleasesResponse = try JSONDecoder().decode(NewReleasesResponse.self, from: data)
                completion(newReleasesResponse.albums.items)
            } catch {
                print("Error decoding new releases: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response data: \(jsonString)")
                }
                completion([])
            }
        }.resume()
    }
    
}
