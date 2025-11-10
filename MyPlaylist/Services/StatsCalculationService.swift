import Foundation

// MARK: - 統計數據模型

/// 排名歌曲資訊
struct RankedTrack: Identifiable {
    let id: String
    let rank: Int              // 排名位置（1-50）
    let trackId: String
    let trackName: String
    let artistNames: String    // 藝人名稱（多個以逗號分隔）
    let albumName: String
    let albumImageUrl: String?
}

/// 專輯統計數據
struct AlbumStats {
    var tracksInShortTerm: Int = 0    // 4週內 Top 50 中有幾首
    var tracksInMediumTerm: Int = 0   // 6個月內 Top 50 中有幾首
    var tracksInLongTerm: Int = 0     // 所有時間 Top 50 中有幾首
    var recentPlayCount: Int = 0      // 最近50次播放中出現次數
    
    // 詳細歌曲列表
    var shortTermTracks: [RankedTrack] = []
    var mediumTermTracks: [RankedTrack] = []
    var longTermTracks: [RankedTrack] = []
    var recentTracks: [RankedTrack] = []
}

/// 藝人統計數據
struct ArtistStats {
    var tracksInShortTerm: Int = 0    // 4週內 Top 50 中有幾首
    var tracksInMediumTerm: Int = 0   // 6個月內 Top 50 中有幾首
    var tracksInLongTerm: Int = 0     // 所有時間 Top 50 中有幾首
    var recentPlayCount: Int = 0      // 最近50次播放中出現次數
    
    // 詳細歌曲列表
    var shortTermTracks: [RankedTrack] = []
    var mediumTermTracks: [RankedTrack] = []
    var longTermTracks: [RankedTrack] = []
    var recentTracks: [RankedTrack] = []
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
                // 過濾並保存屬於這個專輯的歌曲
                let matchedTracks = tracks.enumerated().compactMap { (index, track) -> RankedTrack? in
                    guard track.album.id == albumId else { return nil }
                    
                    return RankedTrack(
                        id: "\(track.id)_\(index)",
                        rank: index + 1,
                        trackId: track.id,
                        trackName: track.name,
                        artistNames: track.artists.map { $0.name }.joined(separator: ", "),
                        albumName: track.album.name ?? "",
                        albumImageUrl: track.album.images.first?.url
                    )
                }
                
                DispatchQueue.main.async {
                    switch statsType {
                    case "short":
                        stats.tracksInShortTerm = matchedTracks.count
                        stats.shortTermTracks = matchedTracks
                    case "medium":
                        stats.tracksInMediumTerm = matchedTracks.count
                        stats.mediumTermTracks = matchedTracks
                    case "long":
                        stats.tracksInLongTerm = matchedTracks.count
                        stats.longTermTracks = matchedTracks
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
            // 過濾並保存屬於這個專輯的歌曲
            let matchedTracks = recentTracks.enumerated().compactMap { (index, recentTrack) -> RankedTrack? in
                guard recentTrack.track.album.id == albumId else { return nil }
                
                return RankedTrack(
                    id: "\(recentTrack.track.id)_recent_\(index)",
                    rank: index + 1,
                    trackId: recentTrack.track.id,
                    trackName: recentTrack.track.name,
                    artistNames: recentTrack.track.artists.map { $0.name }.joined(separator: ", "),
                    albumName: recentTrack.track.album.name,
                    albumImageUrl: recentTrack.track.album.images.first?.url
                )
            }
            
            DispatchQueue.main.async {
                stats.recentPlayCount = matchedTracks.count
                stats.recentTracks = matchedTracks
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
                // 過濾並保存屬於這個藝人的歌曲
                let matchedTracks = tracks.enumerated().compactMap { (index, track) -> RankedTrack? in
                    guard track.artists.contains(where: { $0.id == artistId }) else { return nil }
                    
                    return RankedTrack(
                        id: "\(track.id)_\(index)",
                        rank: index + 1,
                        trackId: track.id,
                        trackName: track.name,
                        artistNames: track.artists.map { $0.name }.joined(separator: ", "),
                        albumName: track.album.name ?? "",
                        albumImageUrl: track.album.images.first?.url
                    )
                }
                
                DispatchQueue.main.async {
                    switch statsType {
                    case "short":
                        stats.tracksInShortTerm = matchedTracks.count
                        stats.shortTermTracks = matchedTracks
                    case "medium":
                        stats.tracksInMediumTerm = matchedTracks.count
                        stats.mediumTermTracks = matchedTracks
                    case "long":
                        stats.tracksInLongTerm = matchedTracks.count
                        stats.longTermTracks = matchedTracks
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
            // 過濾並保存屬於這個藝人的歌曲
            let matchedTracks = recentTracks.enumerated().compactMap { (index, recentTrack) -> RankedTrack? in
                guard recentTrack.track.artists.contains(where: { $0.id == artistId }) else { return nil }
                
                return RankedTrack(
                    id: "\(recentTrack.track.id)_recent_\(index)",
                    rank: index + 1,
                    trackId: recentTrack.track.id,
                    trackName: recentTrack.track.name,
                    artistNames: recentTrack.track.artists.map { $0.name }.joined(separator: ", "),
                    albumName: recentTrack.track.album.name,
                    albumImageUrl: recentTrack.track.album.images.first?.url
                )
            }
            
            DispatchQueue.main.async {
                stats.recentPlayCount = matchedTracks.count
                stats.recentTracks = matchedTracks
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(stats)
        }
    }
}

