import Foundation

class SpotifyAPIService {

    private static func handleUnauthorized(response: URLResponse?) -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            DispatchQueue.main.async {
                SpotifyAuthService.logout()
                NotificationCenter.default.post(name: .spotifyUnauthorized, object: nil)
            }
            return true
        }
        return false
    }
    
    static func fetchTopTracks(accessToken: String, timeRange: String, completion: @escaping ([Track]) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/me/top/tracks?limit=50&time_range=\(timeRange)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching top tracks: \(error.localizedDescription)")
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
                let tracksResponse = try JSONDecoder().decode(TracksResponse.self, from: data)
                completion(tracksResponse.items)
            } catch {
                print("Error decoding tracks: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    static func fetchCurrentUserProfile(accessToken: String, completion: @escaping (SpotifyUser?) -> Void) {
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
    
    static func fetchTopArtists(accessToken: String, timeRange: String = "medium_term", completion: @escaping ([Artist]) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/me/top/artists?limit=50&time_range=\(timeRange)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching top artists: \(error.localizedDescription)")
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
                let artistsResponse = try JSONDecoder().decode(ArtistsResponse.self, from: data)
                completion(artistsResponse.items)
            } catch {
                print("Error decoding artists: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    // 新增的方法來獲取使用者播放列表
    static func fetchUserPlaylists(accessToken: String, completion: @escaping ([Playlist]) -> Void) {
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
    static func fetchCurrentlyPlaying(accessToken: String, completion: @escaping (CurrentlyPlayingTrack?) -> Void) {
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
                completion(currentlyPlaying.item)
            } catch {
                print("Error decoding currently playing: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    // 新增：獲取最近播放的歌曲
    static func fetchRecentlyPlayed(accessToken: String, limit: Int = 20, completion: @escaping ([RecentlyPlayedTrack]) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/me/player/recently-played?limit=\(limit)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching recently played: \(error.localizedDescription)")
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
                let recentlyPlayedResponse = try JSONDecoder().decode(RecentlyPlayedResponse.self, from: data)
                completion(recentlyPlayedResponse.items)
            } catch {
                print("Error decoding recently played: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    // 新增：獲取收藏的歌曲
    static func fetchSavedTracks(accessToken: String, limit: Int = 10, completion: @escaping ([SavedTrackItem]) -> Void) {
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

}
