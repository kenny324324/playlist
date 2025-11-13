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
        cacheKey: String? = nil,
        completion: @escaping (Result<AlbumStats, SpotifyAPIService.SpotifyAPIError>) -> Void
    ) {
        var stats = AlbumStats()
        let group = DispatchGroup()
        var fetchError: SpotifyAPIService.SpotifyAPIError?
        
        // 獲取三個時間範圍的 Top 50 歌曲
        for (timeRange, statsType) in [("short_term", "short"), ("medium_term", "medium"), ("long_term", "long")] {
            group.enter()
            SpotifyAPIService.fetchTopTracks(
                accessToken: accessToken,
                timeRange: timeRange,
                cacheKey: cacheKey,
                forceRefresh: false
            ) { result in
                defer { group.leave() }
                switch result {
                case .success(let tracks):
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
                case .failure(let error):
                    fetchError = fetchError ?? error
                }
            }
        }
        
        // 獲取最近播放記錄
        group.enter()
        SpotifyAPIService.fetchRecentlyPlayed(
            accessToken: accessToken,
            limit: 50,
            cacheKey: cacheKey,
            forceRefresh: false
        ) { result in
            defer { group.leave() }
            switch result {
            case .success(let recentTracks):
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
            case .failure(let error):
                fetchError = fetchError ?? error
            }
        }
        
        group.notify(queue: .main) {
            if stats.shortTermTracks.isEmpty && stats.mediumTermTracks.isEmpty && stats.longTermTracks.isEmpty,
               stats.recentTracks.isEmpty,
               let error = fetchError {
                completion(.failure(error))
            } else {
                completion(.success(stats))
            }
        }
    }
    
    // MARK: - 藝人統計計算
    
    /// 計算藝人統計數據
    func calculateArtistStats(
        artistId: String,
        accessToken: String,
        cacheKey: String? = nil,
        completion: @escaping (Result<ArtistStats, SpotifyAPIService.SpotifyAPIError>) -> Void
    ) {
        var stats = ArtistStats()
        let group = DispatchGroup()
        var fetchError: SpotifyAPIService.SpotifyAPIError?
        
        // 獲取三個時間範圍的 Top 50 歌曲
        for (timeRange, statsType) in [("short_term", "short"), ("medium_term", "medium"), ("long_term", "long")] {
            group.enter()
            SpotifyAPIService.fetchTopTracks(
                accessToken: accessToken,
                timeRange: timeRange,
                cacheKey: cacheKey,
                forceRefresh: false
            ) { result in
                defer { group.leave() }
                switch result {
                case .success(let tracks):
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
                case .failure(let error):
                    fetchError = fetchError ?? error
                }
            }
        }
        
        // 獲取最近播放記錄
        group.enter()
        SpotifyAPIService.fetchRecentlyPlayed(
            accessToken: accessToken,
            limit: 50,
            cacheKey: cacheKey,
            forceRefresh: false
        ) { result in
            defer { group.leave() }
            switch result {
            case .success(let recentTracks):
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
            case .failure(let error):
                fetchError = fetchError ?? error
            }
        }
        
        group.notify(queue: .main) {
            if stats.shortTermTracks.isEmpty && stats.mediumTermTracks.isEmpty && stats.longTermTracks.isEmpty,
               stats.recentTracks.isEmpty,
               let error = fetchError {
                completion(.failure(error))
            } else {
                completion(.success(stats))
            }
        }
    }
}
