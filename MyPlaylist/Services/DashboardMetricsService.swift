import Foundation

class DashboardMetricsService {
    static let shared = DashboardMetricsService()
    private typealias SpotifyAPIError = SpotifyAPIService.SpotifyAPIError
    
    private let isoFormatter: ISO8601DateFormatter
    private let calendar: Calendar
    
    private init() {
        isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        calendar = Calendar.current
    }
    
    private enum DashboardError: Error {
        case noData
        case spotify(SpotifyAPIError)
    }
    
    private struct TodayListeningSnapshot {
        let minutes: Int
        let trackCount: Int
        let tracks: [TodayPlayedTrack]
        let lastSyncedAt: Date
    }
    
    // 檢查是否為 Demo 模式
    private var isDemoMode: Bool {
        return DemoModeManager.shared.isDemoMode
    }
    
    private var dailyLogKey: String {
        return DailyListeningLog.dateKey(from: Date())
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
        
        var todaySnapshot: TodayListeningSnapshot?
        var weeklySnapshot: WeeklyTopCache?
        
        group.enter()
        loadTodaySnapshot(accessToken: accessToken, forceRefresh: forceRefresh) { result in
            switch result {
            case .success(let snapshot):
                todaySnapshot = snapshot
            case .failure(let error):
                print("❌ 今日聆聽資料載入失敗: \(error)")
            }
            group.leave()
        }
        
        group.enter()
        fetchWeeklyTopItems(accessToken: accessToken, forceRefresh: forceRefresh) { result in
            switch result {
            case .success(let cache):
                weeklySnapshot = cache
            case .failure(let error):
                print("❌ 每月熱門資料載入失敗: \(error)")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            guard let todaySnapshot = todaySnapshot else {
                print("⚠️ 無法建立 Dashboard summary，缺少今日聆聽資料")
                completion(nil)
                return
            }
            
            let weeklyCache = weeklySnapshot ?? UserDefaults.standard.weeklyTopCache
            let lastUpdated: Date
            if let weeklyDate = weeklyCache?.lastUpdated {
                lastUpdated = min(todaySnapshot.lastSyncedAt, weeklyDate)
            } else {
                lastUpdated = todaySnapshot.lastSyncedAt
            }
            let summary = DashboardSummary(
                todayListeningMinutes: todaySnapshot.minutes,
                todayListeningTrackCount: todaySnapshot.trackCount,
                todayPlayedTracks: todaySnapshot.tracks,
                weeklyTopTracks: weeklyCache?.tracks ?? [],
                weeklyTopArtists: weeklyCache?.artists ?? [],
                lastUpdated: lastUpdated
            )
            
            completion(summary)
        }
    }
    
    // MARK: - Today's Listening Time
    
    /// 計算今日聆聽分鐘數、歌曲數量和播放列表
    func fetchTodayListeningMinutes(accessToken: String, useCache: Bool = true, completion: @escaping (Int, Int, [TodayPlayedTrack]) -> Void) {
        loadTodaySnapshot(accessToken: accessToken, forceRefresh: !useCache) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let snapshot):
                    completion(snapshot.minutes, snapshot.trackCount, snapshot.tracks)
                case .failure:
                    completion(0, 0, [])
                }
            }
        }
    }
    
    // MARK: - Monthly Top Items
    
    /// 取得每月熱門歌曲和藝人（基於 Spotify short_term，約 4 週）
    private func fetchWeeklyTopItems(accessToken: String, forceRefresh: Bool, completion: @escaping (Result<WeeklyTopCache, DashboardError>) -> Void) {
        let defaults = UserDefaults.standard
        
        if !forceRefresh, let cache = defaults.weeklyTopCache, !cache.isExpired {
            completion(.success(cache))
            return
        }
        
        let group = DispatchGroup()
        var topTracks: [WeeklyTopEntry] = []
        var topArtists: [WeeklyTopEntry] = []
        var fetchError: SpotifyAPIError?
        
        group.enter()
        SpotifyAPIService.fetchTopTracks(
            accessToken: accessToken,
            timeRange: "short_term",
            cacheKey: accessToken,
            forceRefresh: forceRefresh
        ) { result in
            switch result {
            case .success(let tracks):
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
            case .failure(let error):
                fetchError = error
            }
            group.leave()
        }
        
        group.enter()
        SpotifyAPIService.fetchTopArtists(
            accessToken: accessToken,
            timeRange: "short_term",
            cacheKey: accessToken,
            forceRefresh: forceRefresh
        ) { result in
            switch result {
            case .success(let artists):
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
            case .failure(let error):
                fetchError = error
            }
            group.leave()
        }
        
        group.notify(queue: .global(qos: .userInitiated)) {
            if topTracks.isEmpty && topArtists.isEmpty {
                if let cache = defaults.weeklyTopCache {
                    completion(.success(cache))
                } else if let fetchError = fetchError {
                    completion(.failure(.spotify(fetchError)))
                } else {
                    completion(.failure(.noData))
                }
                return
            }
            
            let cache = WeeklyTopCache(
                tracks: topTracks,
                artists: topArtists,
                lastUpdated: Date(),
                weekStartDate: WeeklyTopCache.weekKey(from: Date())
            )
            defaults.weeklyTopCache = cache
            completion(.success(cache))
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
        fetchWeeklyTopItems(accessToken: accessToken, forceRefresh: true) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cache):
                    completion(cache.tracks, cache.artists)
                case .failure:
                    completion([], [])
                }
            }
        }
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

// MARK: - Today Snapshot Helpers
extension DashboardMetricsService {
    private func loadTodaySnapshot(accessToken: String, forceRefresh: Bool, completion: @escaping (Result<TodayListeningSnapshot, DashboardError>) -> Void) {
        let defaults = UserDefaults.standard
        var log = defaults.dailyListeningLog
        let todayKey = dailyLogKey
        
        if log?.date != todayKey {
            log = DailyListeningLog(date: todayKey)
        }
        
        if !forceRefresh, let cachedLog = log, cachedLog.isFresh {
            completion(.success(snapshot(from: cachedLog)))
            return
        }
        
        refreshDailyLog(accessToken: accessToken, existingLog: log) { result in
            completion(result)
        }
    }
    
    private func refreshDailyLog(accessToken: String, existingLog: DailyListeningLog?, completion: @escaping (Result<TodayListeningSnapshot, DashboardError>) -> Void) {
        SpotifyAPIService.fetchRecentlyPlayed(
            accessToken: accessToken,
            limit: 50,
            cacheKey: accessToken,
            forceRefresh: true
        ) { result in
            switch result {
            case .success(let items):
                let snapshot = self.mergeDailyLog(with: items, existingLog: existingLog)
                completion(.success(snapshot))
            case .failure(let error):
                if let log = existingLog {
                    completion(.success(self.snapshot(from: log)))
                } else {
                    completion(.failure(.spotify(error)))
                }
            }
        }
    }
    
    private func mergeDailyLog(with items: [RecentlyPlayedTrack], existingLog: DailyListeningLog?) -> TodayListeningSnapshot {
        var log = existingLog ?? DailyListeningLog(date: dailyLogKey)
        if log.date != dailyLogKey {
            log = DailyListeningLog(date: dailyLogKey)
        }
        let now = Date()
        
        // 僅保留今日的播放紀錄
        let todaysItems = items.filter { track in
            guard let playedDate = isoFormatter.date(from: track.played_at) else {
                return false
            }
            return calendar.isDate(playedDate, inSameDayAs: now)
        }
        
        var trackDurations = log.trackDurations
        var todayTracks = log.tracks
        
        for item in todaysItems {
            let trackKey = "\(item.track.id)_\(item.played_at)"
            guard trackDurations[trackKey] == nil else { continue }
            
            trackDurations[trackKey] = item.track.duration_ms
            
            let track = TodayPlayedTrack(
                id: trackKey,
                name: item.track.name,
                artistName: item.track.artists.map(\.name).joined(separator: ", "),
                albumName: item.track.album.name,
                imageUrl: item.track.album.images.first?.url,
                playedAt: item.played_at,
                durationMs: item.track.duration_ms
            )
            todayTracks.append(track)
            
            if let currentLatest = log.lastPlayedAt,
               let currentDate = isoFormatter.date(from: currentLatest),
               let newDate = isoFormatter.date(from: item.played_at) {
                if newDate > currentDate {
                    log.lastPlayedAt = item.played_at
                }
            } else {
                log.lastPlayedAt = item.played_at
            }
        }
        
        todayTracks.sort { $0.playedAt > $1.playedAt }
        log.tracks = todayTracks
        log.trackDurations = trackDurations
        log.totalMinutes = trackDurations.values.reduce(0, +) / 60000
        log.lastSyncedAt = Date()
        UserDefaults.standard.dailyListeningLog = log
        
        return snapshot(from: log)
    }
    
    private func snapshot(from log: DailyListeningLog) -> TodayListeningSnapshot {
        return TodayListeningSnapshot(
            minutes: log.totalMinutes,
            trackCount: log.trackDurations.count,
            tracks: log.tracks.sorted { $0.playedAt > $1.playedAt },
            lastSyncedAt: log.lastSyncedAt ?? Date()
        )
    }
}
