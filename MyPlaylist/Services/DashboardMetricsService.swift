import Foundation

class DashboardMetricsService {
    static let shared = DashboardMetricsService()
    
    private init() {}
    
    // 檢查是否為 Demo 模式
    private var isDemoMode: Bool {
        return DemoModeManager.shared.isDemoMode
    }
    
    // MARK: - Public Methods
    
    /// 取得完整的儀表板資料
    func fetchDashboardSummary(accessToken: String, forceRefresh: Bool = false, completion: @escaping (DashboardSummary?) -> Void) {
        // Demo 模式：返回模擬的儀表板數據
        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(self.createDemoDashboardSummary())
            }
            return
        }
        
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
    
    /// 計算今日聆聽分鐘數、歌曲數量和播放列表（即時資料，不使用快取）
    func fetchTodayListeningMinutes(accessToken: String, completion: @escaping (Int, Int, [TodayPlayedTrack]) -> Void) {
        // 🔥 不使用快取，每次都直接從 API 計算
        print("🔄 從 API 即時計算今日聆聽時間")
        
        // 獲取最近播放記錄（限制 50 筆以涵蓋完整一天）
        SpotifyAPIService.fetchRecentlyPlayed(accessToken: accessToken, limit: 50) { items in
            guard !items.isEmpty else {
                print("⚠️ 沒有獲取到播放記錄")
                completion(0, 0, [])
                return
            }
            
            print("📊 獲取到 \(items.count) 筆最近播放記錄")
            
            // 計算今天的播放時間
            let calendar = Calendar.current
            let now = Date()
            
            var processedTracks: [String: Int] = [:]  // trackKey -> duration
            var todayPlayedTracks: [TodayPlayedTrack] = []
            
            // 配置 ISO8601 解析器以支援毫秒
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            for item in items {
                // 解析播放時間
                guard let playedDate = iso8601Formatter.date(from: item.played_at) else {
                    continue
                }
                
                // 只計算今天的播放
                if calendar.isDate(playedDate, inSameDayAs: now) {
                    let trackKey = "\(item.track.id)_\(item.played_at)"
                    
                    // 避免重複計算同一筆記錄
                    if processedTracks[trackKey] == nil {
                        processedTracks[trackKey] = item.track.duration_ms
                    }
                    
                    // 添加到今日播放列表
                    let todayTrack = TodayPlayedTrack(
                        id: trackKey,
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
            
            // 計算總時長
            let totalMs = processedTracks.values.reduce(0, +)
            let totalMinutes = totalMs / 60000
            let trackCount = processedTracks.count
            
            if trackCount > 0 {
                print("✅ 今日聆聽時間: \(totalMinutes) 分鐘 (共 \(trackCount) 首歌曲)")
            } else {
                print("⚠️ 今天尚未播放任何歌曲")
            }
            
            // 按播放時間倒序排列（最新的在前）
            todayPlayedTracks.sort { $0.playedAt > $1.playedAt }
            
            completion(totalMinutes, trackCount, todayPlayedTracks)
        }
    }
    
    // MARK: - Monthly Top Items
    
    /// 取得每月熱門歌曲和藝人（基於 Spotify short_term，約 4 週）
    private func fetchWeeklyTopItems(accessToken: String, forceRefresh: Bool, completion: @escaping ([WeeklyTopEntry], [WeeklyTopEntry]) -> Void) {
        // 🔥 不使用快取，每次都從 API 抓取最新資料
        print("🔄 從 API 取得每月熱門資料（即時更新）")
        
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
            if topTracks.isEmpty && topArtists.isEmpty {
                print("⚠️ 沒有取得每月熱門資料（帳號可能沒有足夠的聆聽歷史）")
            } else {
                print("✅ 取得每月資料：\(topTracks.count) 首歌曲、\(topArtists.count) 位藝人")
            }
            
            // 不再儲存快取，每次都抓最新資料
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
    
    // MARK: - Demo Mode
    
    /// 創建 Demo 模式的儀表板數據
    private func createDemoDashboardSummary() -> DashboardSummary {
        // 今日播放的歌曲（使用 MockSpotifyData 的前 5 首）
        let todayTracks = MockSpotifyData.demoTracks.prefix(5).enumerated().map { index, track in
            TodayPlayedTrack(
                id: "\(track.id)_demo_\(index)",
                name: track.name,
                artistName: track.artists.map(\.name).joined(separator: ", "),
                albumName: track.album.name ?? "Album",
                imageUrl: track.album.images.first?.url,
                playedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-Double(index * 600))),
                durationMs: 200000
            )
        }
        
        // 本月熱門歌曲（前 3 首）
        let weeklyTopTracks = MockSpotifyData.demoTracks.prefix(3).map { track in
            WeeklyTopEntry(
                id: track.id,
                name: track.name,
                artistName: track.artists.map(\.name).joined(separator: ", "),
                imageUrl: track.album.images.first?.url,
                playCount: Int.random(in: 15...30),
                totalPlayTimeMs: nil
            )
        }
        
        // 本月熱門藝人（前 3 位）
        let weeklyTopArtists = MockSpotifyData.demoArtists.prefix(3).map { artist in
            WeeklyTopEntry(
                id: artist.id,
                name: artist.name,
                artistName: nil,
                imageUrl: artist.images.first?.url,
                playCount: Int.random(in: 20...40),
                totalPlayTimeMs: nil
            )
        }
        
        return DashboardSummary(
            todayListeningMinutes: 45,  // 45 分鐘
            todayListeningTrackCount: 5, // 5 首歌
            todayPlayedTracks: Array(todayTracks),
            weeklyTopTracks: Array(weeklyTopTracks),
            weeklyTopArtists: Array(weeklyTopArtists),
            lastUpdated: Date()
        )
    }
}

