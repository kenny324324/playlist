import Foundation
import UIKit

// MARK: - API 響應快取服務
/// 快取 Spotify API 的響應，減少網路請求，提升性能

class APIResponseCache {
    static let shared = APIResponseCache()
    
    // MARK: - 快取項目
    private struct CacheItem<T> {
        let data: T
        let timestamp: Date
        let expirationInterval: TimeInterval
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > expirationInterval
        }
    }
    
    // MARK: - 快取存儲（使用 NSCache）
    private let tracksCache = NSCache<NSString, CacheWrapper<[Track]>>()
    private let artistsCache = NSCache<NSString, CacheWrapper<[Artist]>>()
    private let userProfileCache = NSCache<NSString, CacheWrapper<SpotifyUser>>()
    private let playlistsCache = NSCache<NSString, CacheWrapper<[Playlist]>>()
    
    // 快取隊列（避免競態條件）
    private let cacheQueue = DispatchQueue(label: "com.myplaylist.apicache", attributes: .concurrent)
    
    // MARK: - 快取有效期設定
    private let defaultExpirationInterval: TimeInterval = 5 * 60 // 5 分鐘
    private let userProfileExpirationInterval: TimeInterval = 30 * 60 // 30 分鐘
    private let playlistsExpirationInterval: TimeInterval = 10 * 60 // 10 分鐘
    
    private init() {
        // 設定快取限制
        tracksCache.countLimit = 20 // 最多快取 20 個不同的 tracks 請求
        artistsCache.countLimit = 20
        userProfileCache.countLimit = 5
        playlistsCache.countLimit = 10
        
        // 監聽記憶體警告
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Top Tracks 快取
    func getTopTracks(userId: String, timeRange: String) -> [Track]? {
        let key = "tracks_\(userId)_\(timeRange)" as NSString
        
        return cacheQueue.sync {
            guard let wrapper = tracksCache.object(forKey: key),
                  !wrapper.isExpired else {
                PerformanceLogger.shared.logCacheMiss(type: "Top Tracks (\(timeRange))")
                return nil
            }
            PerformanceLogger.shared.logCacheHit(type: "Top Tracks (\(timeRange))", source: "記憶體")
            return wrapper.data
        }
    }
    
    func setTopTracks(_ tracks: [Track], userId: String, timeRange: String) {
        let key = "tracks_\(userId)_\(timeRange)" as NSString
        let wrapper = CacheWrapper(
            data: tracks,
            timestamp: Date(),
            expirationInterval: defaultExpirationInterval
        )
        
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.tracksCache.setObject(wrapper, forKey: key)
            PerformanceLogger.shared.logCacheSave(type: "Top Tracks (\(timeRange))", count: tracks.count)
        }
    }
    
    // MARK: - Top Artists 快取
    func getTopArtists(userId: String, timeRange: String) -> [Artist]? {
        let key = "artists_\(userId)_\(timeRange)" as NSString
        
        return cacheQueue.sync {
            guard let wrapper = artistsCache.object(forKey: key),
                  !wrapper.isExpired else {
                PerformanceLogger.shared.logCacheMiss(type: "Top Artists (\(timeRange))")
                return nil
            }
            PerformanceLogger.shared.logCacheHit(type: "Top Artists (\(timeRange))", source: "記憶體")
            return wrapper.data
        }
    }
    
    func setTopArtists(_ artists: [Artist], userId: String, timeRange: String) {
        let key = "artists_\(userId)_\(timeRange)" as NSString
        let wrapper = CacheWrapper(
            data: artists,
            timestamp: Date(),
            expirationInterval: defaultExpirationInterval
        )
        
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.artistsCache.setObject(wrapper, forKey: key)
            PerformanceLogger.shared.logCacheSave(type: "Top Artists (\(timeRange))", count: artists.count)
        }
    }
    
    // MARK: - User Profile 快取
    func getUserProfile(userId: String) -> SpotifyUser? {
        let key = "profile_\(userId)" as NSString
        
        return cacheQueue.sync {
            guard let wrapper = userProfileCache.object(forKey: key),
                  !wrapper.isExpired else {
                return nil
            }
            return wrapper.data
        }
    }
    
    func setUserProfile(_ user: SpotifyUser) {
        guard let userId = user.id else { return }
        let key = "profile_\(userId)" as NSString
        let wrapper = CacheWrapper(
            data: user,
            timestamp: Date(),
            expirationInterval: userProfileExpirationInterval
        )
        
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.userProfileCache.setObject(wrapper, forKey: key)
        }
    }
    
    // MARK: - Playlists 快取
    func getPlaylists(userId: String) -> [Playlist]? {
        let key = "playlists_\(userId)" as NSString
        
        return cacheQueue.sync {
            guard let wrapper = playlistsCache.object(forKey: key),
                  !wrapper.isExpired else {
                return nil
            }
            return wrapper.data
        }
    }
    
    func setPlaylists(_ playlists: [Playlist], userId: String) {
        let key = "playlists_\(userId)" as NSString
        let wrapper = CacheWrapper(
            data: playlists,
            timestamp: Date(),
            expirationInterval: playlistsExpirationInterval
        )
        
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.playlistsCache.setObject(wrapper, forKey: key)
        }
    }
    
    // MARK: - Recently Played 快取
    private let recentlyPlayedCache = NSCache<NSString, CacheWrapper<[RecentlyPlayedTrack]>>()
    
    func getRecentlyPlayed(userId: String) -> [RecentlyPlayedTrack]? {
        let key = "recently_\(userId)" as NSString
        
        return cacheQueue.sync {
            guard let wrapper = recentlyPlayedCache.object(forKey: key),
                  !wrapper.isExpired else {
                PerformanceLogger.shared.logCacheMiss(type: "Recently Played")
                return nil
            }
            PerformanceLogger.shared.logCacheHit(type: "Recently Played", source: "記憶體")
            return wrapper.data
        }
    }
    
    func setRecentlyPlayed(_ tracks: [RecentlyPlayedTrack], userId: String) {
        let key = "recently_\(userId)" as NSString
        let wrapper = CacheWrapper(
            data: tracks,
            timestamp: Date(),
            expirationInterval: 2 * 60  // 2 分鐘（經常變化）
        )
        
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.recentlyPlayedCache.setObject(wrapper, forKey: key)
            PerformanceLogger.shared.logCacheSave(type: "Recently Played", count: tracks.count)
        }
    }
    
    // MARK: - Saved Tracks 快取
    private let savedTracksCache = NSCache<NSString, CacheWrapper<[SavedTrackItem]>>()
    
    func getSavedTracks(userId: String) -> [SavedTrackItem]? {
        let key = "saved_tracks_\(userId)" as NSString
        
        return cacheQueue.sync {
            guard let wrapper = savedTracksCache.object(forKey: key),
                  !wrapper.isExpired else {
                PerformanceLogger.shared.logCacheMiss(type: "Saved Tracks")
                return nil
            }
            PerformanceLogger.shared.logCacheHit(type: "Saved Tracks", source: "記憶體")
            return wrapper.data
        }
    }
    
    func setSavedTracks(_ tracks: [SavedTrackItem], userId: String) {
        let key = "saved_tracks_\(userId)" as NSString
        let wrapper = CacheWrapper(
            data: tracks,
            timestamp: Date(),
            expirationInterval: playlistsExpirationInterval  // 10 分鐘
        )
        
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.savedTracksCache.setObject(wrapper, forKey: key)
            PerformanceLogger.shared.logCacheSave(type: "Saved Tracks", count: tracks.count)
        }
    }
    
    // MARK: - 清除快取
    func clearAll() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.tracksCache.removeAllObjects()
            self?.artistsCache.removeAllObjects()
            self?.userProfileCache.removeAllObjects()
            self?.playlistsCache.removeAllObjects()
            self?.recentlyPlayedCache.removeAllObjects()
            self?.savedTracksCache.removeAllObjects()
        }
        PerformanceLogger.shared.log("已清除所有 API 響應快取", icon: "🧹")
    }
    
    func clearTracks() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.tracksCache.removeAllObjects()
        }
    }
    
    func clearArtists() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.artistsCache.removeAllObjects()
        }
    }
    
    // MARK: - 記憶體警告處理
    @objc private func handleMemoryWarning() {
        PerformanceLogger.shared.logMemoryWarning()
        PerformanceLogger.shared.log("清理 API 響應快取", icon: "🧹")
        clearAll()
    }
    
    // MARK: - 取得快取狀態（用於除錯）
    func getCacheStats() -> String {
        var stats = "📊 API 快取狀態:\n"
        stats += "- Tracks: \(tracksCache.name ?? "N/A")\n"
        stats += "- Artists: \(artistsCache.name ?? "N/A")\n"
        stats += "- Profiles: \(userProfileCache.name ?? "N/A")\n"
        stats += "- Playlists: \(playlistsCache.name ?? "N/A")"
        return stats
    }
}

// MARK: - 快取包裝器（支援過期檢查）
private class CacheWrapper<T> {
    let data: T
    let timestamp: Date
    let expirationInterval: TimeInterval
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > expirationInterval
    }
    
    init(data: T, timestamp: Date, expirationInterval: TimeInterval) {
        self.data = data
        self.timestamp = timestamp
        self.expirationInterval = expirationInterval
    }
}

