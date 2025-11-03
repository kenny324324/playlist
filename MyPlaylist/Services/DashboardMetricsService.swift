import Foundation

class DashboardMetricsService {
    static let shared = DashboardMetricsService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 取得完整的儀表板資料
    func fetchDashboardSummary(accessToken: String, forceRefresh: Bool = false, completion: @escaping (DashboardSummary?) -> Void) {
        let group = DispatchGroup()
        
        var todayMinutes = 0
        var todayTrackCount = 0
        var todayTracks: [TodayPlayedTrack] = []
        var weeklyTracks: [WeeklyTopEntry] = []
        var weeklyArtists: [WeeklyTopEntry] = []
        
        // 1. 計算今日聆聽分鐘數、歌曲數量和播放列表
        group.enter()
        fetchTodayListeningMinutes(accessToken: accessToken) { minutes, trackCount, tracks in
            todayMinutes = minutes
            todayTrackCount = trackCount
            todayTracks = tracks
            group.leave()
        }
        
        // 2. 取得每月熱門歌曲和藝人（Spotify short_term ≈ 4週）
        group.enter()
        fetchWeeklyTopItems(accessToken: accessToken, forceRefresh: forceRefresh) { tracks, artists in
            weeklyTracks = tracks
            weeklyArtists = artists
            group.leave()
        }
        
        group.notify(queue: .main) {
            let summary = DashboardSummary(
                todayListeningMinutes: todayMinutes,
                todayListeningTrackCount: todayTrackCount,
                todayPlayedTracks: todayTracks,
                weeklyTopTracks: weeklyTracks,
                weeklyTopArtists: weeklyArtists,
                lastUpdated: Date()
            )
            completion(summary)
        }
    }
    
    // MARK: - Today's Listening Time
    
    /// 計算今日聆聽分鐘數、歌曲數量和播放列表
    func fetchTodayListeningMinutes(accessToken: String, completion: @escaping (Int, Int, [TodayPlayedTrack]) -> Void) {
        let todayKey = DailyListeningLog.dateKey(from: Date())
        
        // 從快取讀取今日記錄
        var log = UserDefaults.standard.dailyListeningLog
        
        // 如果日期不同，重置記錄
        if log?.date != todayKey {
            log = DailyListeningLog(date: todayKey, totalMinutes: 0, lastPlayedAt: nil)
            print("🗓️ 新的一天，重置聆聽記錄")
        }
        
        // 獲取最近播放記錄（限制 50 筆以涵蓋完整一天）
        SpotifyAPIService.fetchRecentlyPlayed(accessToken: accessToken, limit: 50) { items in
            guard !items.isEmpty else {
                print("⚠️ 沒有獲取到播放記錄")
                completion(log?.totalMinutes ?? 0, 0, [])
                return
            }
            
            print("📊 獲取到 \(items.count) 筆最近播放記錄")
            
            // 計算今天的播放時間
            let calendar = Calendar.current
            let now = Date()
            
            // 調試：顯示當前時間
            let debugFormatter = DateFormatter()
            debugFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            debugFormatter.timeZone = TimeZone.current
            print("🕐 當前時間: \(debugFormatter.string(from: now))")
            print("⏰ 時區: \(TimeZone.current.identifier)")
            
            var updatedLog = log ?? DailyListeningLog(date: todayKey, totalMinutes: 0, lastPlayedAt: nil)
            var processedTracks = updatedLog.trackDurations
            var todayCount = 0
            var newTracksCount = 0
            var todayPlayedTracks: [TodayPlayedTrack] = []
            
            // 配置 ISO8601 解析器以支援毫秒
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            // 調試：顯示前 3 筆記錄的時間
            print("🔍 檢查最近 3 筆播放記錄的時間：")
            for (index, item) in items.prefix(3).enumerated() {
                if let playedDate = iso8601Formatter.date(from: item.played_at) {
                    print("  [\(index + 1)] \(item.track.name)")
                    print("      API 時間: \(item.played_at)")
                    print("      解析時間: \(debugFormatter.string(from: playedDate))")
                    print("      是今天？: \(calendar.isDate(playedDate, inSameDayAs: now))")
                }
            }
            
            for item in items {
                // 解析播放時間
                guard let playedDate = iso8601Formatter.date(from: item.played_at) else {
                    print("⚠️ 無法解析時間: \(item.played_at)")
                    continue
                }
                
                // 只計算今天的播放
                if calendar.isDate(playedDate, inSameDayAs: now) {
                    todayCount += 1
                    let trackKey = "\(item.track.id)_\(item.played_at)"
                    
                    // 避免重複計算
                    if processedTracks[trackKey] == nil {
                        processedTracks[trackKey] = item.track.duration_ms
                        newTracksCount += 1
                        print("✅ 新增: \(item.track.name) (\(item.track.duration_ms / 60000) 分鐘)")
                    }
                    
                    // 添加到今日播放列表
                    let todayTrack = TodayPlayedTrack(
                        id: "\(item.track.id)_\(item.played_at)",
                        name: item.track.name,
                        artistName: item.track.artists.map(\.name).joined(separator: ", "),
                        albumName: item.track.album.name,
                        imageUrl: item.track.album.images.first?.url,
                        playedAt: item.played_at,
                        durationMs: item.track.duration_ms
                    )
                    todayPlayedTracks.append(todayTrack)
                }
            }
            
            // 重新計算所有已處理歌曲的總時長
            let totalMs = processedTracks.values.reduce(0, +)
            let totalMinutes = totalMs / 60000
            let trackCount = processedTracks.count
            
            print("✅ 今天的播放記錄: \(todayCount) 筆，新增 \(newTracksCount) 筆")
            print("⏱️ 今日聆聽時間: \(totalMinutes) 分鐘 (共 \(trackCount) 首歌曲)")
            
            // 更新記錄
            updatedLog.totalMinutes = totalMinutes
            updatedLog.trackDurations = processedTracks
            updatedLog.lastPlayedAt = items.first?.played_at
            
            // 儲存快取
            UserDefaults.standard.dailyListeningLog = updatedLog
            print("💾 已保存聆聽記錄，共 \(trackCount) 首歌曲")
            
            // 按播放時間倒序排列（最新的在前）
            todayPlayedTracks.sort { $0.playedAt > $1.playedAt }
            
            completion(updatedLog.totalMinutes, trackCount, todayPlayedTracks)
        }
    }
    
    // MARK: - Monthly Top Items
    
    /// 取得每月熱門歌曲和藝人（基於 Spotify short_term，約 4 週）
    private func fetchWeeklyTopItems(accessToken: String, forceRefresh: Bool, completion: @escaping ([WeeklyTopEntry], [WeeklyTopEntry]) -> Void) {
        // 檢查快取
        if !forceRefresh, let cache = UserDefaults.standard.weeklyTopCache, !cache.isExpired {
            print("📦 使用快取的每月熱門資料")
            completion(cache.tracks, cache.artists)
            return
        }
        
        print("🔄 從 API 取得每月熱門資料")
        
        let group = DispatchGroup()
        var topTracks: [WeeklyTopEntry] = []
        var topArtists: [WeeklyTopEntry] = []
        
        // 方案 A：使用 short_term (約 4 週) 的 Top API
        group.enter()
        SpotifyAPIService.fetchTopTracks(accessToken: accessToken, timeRange: "short_term") { tracks in
            topTracks = tracks.prefix(3).map { track in
                WeeklyTopEntry(
                    id: track.id,
                    name: track.name,
                    artistName: track.artists.map(\.name).joined(separator: ", "),
                    imageUrl: track.album.images.first?.url,
                    playCount: nil,
                    totalPlayTimeMs: nil
                )
            }
            group.leave()
        }
        
        group.enter()
        SpotifyAPIService.fetchTopArtists(accessToken: accessToken, timeRange: "short_term") { artists in
            topArtists = artists.prefix(3).map { artist in
                WeeklyTopEntry(
                    id: artist.id,
                    name: artist.name,
                    artistName: nil,
                    imageUrl: artist.images.first?.url,
                    playCount: nil,
                    totalPlayTimeMs: nil
                )
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            // 儲存快取
            let cache = WeeklyTopCache(
                tracks: topTracks,
                artists: topArtists,
                lastUpdated: Date(),
                weekStartDate: WeeklyTopCache.weekKey(from: Date())
            )
            UserDefaults.standard.weeklyTopCache = cache
            
            completion(topTracks, topArtists)
        }
    }
    
    // MARK: - Cache Management
    
    /// 清除所有快取
    func clearCache() {
        UserDefaults.standard.dailyListeningLog = nil
        UserDefaults.standard.weeklyTopCache = nil
        print("🗑️ Dashboard 快取已清除")
    }
    
    /// 強制刷新每月資料
    func refreshWeeklyData(accessToken: String, completion: @escaping ([WeeklyTopEntry], [WeeklyTopEntry]) -> Void) {
        fetchWeeklyTopItems(accessToken: accessToken, forceRefresh: true, completion: completion)
    }
}

