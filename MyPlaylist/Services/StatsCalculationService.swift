import Foundation

// MARK: - 統計數據模型

/// 專輯統計數據
struct AlbumStats {
    var tracksInShortTerm: Int = 0    // 4週內 Top 50 中有幾首
    var tracksInMediumTerm: Int = 0   // 6個月內 Top 50 中有幾首
    var tracksInLongTerm: Int = 0     // 所有時間 Top 50 中有幾首
    var recentPlayCount: Int = 0      // 最近50次播放中出現次數
}

/// 藝人統計數據
struct ArtistStats {
    var tracksInShortTerm: Int = 0    // 4週內 Top 50 中有幾首
    var tracksInMediumTerm: Int = 0   // 6個月內 Top 50 中有幾首
    var tracksInLongTerm: Int = 0     // 所有時間 Top 50 中有幾首
    var recentPlayCount: Int = 0      // 最近50次播放中出現次數
}

// MARK: - 統計計算服務

class StatsCalculationService {
    static let shared = StatsCalculationService()
    
    private init() {}
    
    // MARK: - 專輯統計計算
    
    /// 計算專輯統計數據
    func calculateAlbumStats(
        albumId: String,
        accessToken: String,
        completion: @escaping (AlbumStats) -> Void
    ) {
        var stats = AlbumStats()
        let group = DispatchGroup()
        
        // 獲取三個時間範圍的 Top 50 歌曲
        for (timeRange, statsType) in [("short_term", "short"), ("medium_term", "medium"), ("long_term", "long")] {
            group.enter()
            SpotifyAPIService.fetchTopTracks(accessToken: accessToken, timeRange: timeRange) { tracks in
                // 計算有多少首歌屬於這個專輯
                let count = tracks.filter { track in
                    track.album.id == albumId
                }.count
                
                DispatchQueue.main.async {
                    switch statsType {
                    case "short":
                        stats.tracksInShortTerm = count
                    case "medium":
                        stats.tracksInMediumTerm = count
                    case "long":
                        stats.tracksInLongTerm = count
                    default:
                        break
                    }
                }
                group.leave()
            }
        }
        
        // 獲取最近播放記錄
        group.enter()
        SpotifyAPIService.fetchRecentlyPlayed(accessToken: accessToken, limit: 50) { recentTracks in
            // 計算專輯的歌曲出現次數
            let count = recentTracks.filter { recentTrack in
                recentTrack.track.album.id == albumId
            }.count
            DispatchQueue.main.async {
                stats.recentPlayCount = count
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(stats)
        }
    }
    
    // MARK: - 藝人統計計算
    
    /// 計算藝人統計數據
    func calculateArtistStats(
        artistId: String,
        accessToken: String,
        completion: @escaping (ArtistStats) -> Void
    ) {
        var stats = ArtistStats()
        let group = DispatchGroup()
        
        // 獲取三個時間範圍的 Top 50 歌曲
        for (timeRange, statsType) in [("short_term", "short"), ("medium_term", "medium"), ("long_term", "long")] {
            group.enter()
            SpotifyAPIService.fetchTopTracks(accessToken: accessToken, timeRange: timeRange) { tracks in
                // 計算有多少首歌屬於這個藝人
                let count = tracks.filter { track in
                    track.artists.contains { artist in
                        artist.id == artistId
                    }
                }.count
                
                DispatchQueue.main.async {
                    switch statsType {
                    case "short":
                        stats.tracksInShortTerm = count
                    case "medium":
                        stats.tracksInMediumTerm = count
                    case "long":
                        stats.tracksInLongTerm = count
                    default:
                        break
                    }
                }
                group.leave()
            }
        }
        
        // 獲取最近播放記錄
        group.enter()
        SpotifyAPIService.fetchRecentlyPlayed(accessToken: accessToken, limit: 50) { recentTracks in
            // 計算藝人的歌曲出現次數
            let count = recentTracks.filter { recentTrack in
                recentTrack.track.artists.contains { artist in
                    artist.id == artistId
                }
            }.count
            DispatchQueue.main.async {
                stats.recentPlayCount = count
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(stats)
        }
    }
}

