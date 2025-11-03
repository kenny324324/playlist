import Foundation

// MARK: - Dashboard Summary Models

/// 儀表板總覽資料
struct DashboardSummary: Codable {
    let todayListeningMinutes: Int
    let todayListeningTrackCount: Int  // 今日聆聽的歌曲數量
    let todayPlayedTracks: [TodayPlayedTrack]  // 今日播放的歌曲列表
    let weeklyTopTracks: [WeeklyTopEntry]  // 實際為本月資料（Spotify short_term ≈ 4週）
    let weeklyTopArtists: [WeeklyTopEntry]  // 實際為本月資料（Spotify short_term ≈ 4週）
    let lastUpdated: Date
    
    var todayListeningHours: Double {
        return Double(todayListeningMinutes) / 60.0
    }
    
    var todayListeningFormatted: String {
        if todayListeningMinutes < 60 {
            return "\(todayListeningMinutes) 分鐘"
        } else {
            let hours = todayListeningMinutes / 60
            let minutes = todayListeningMinutes % 60
            if minutes == 0 {
                return "\(hours) 小時"
            } else {
                return "\(hours) 小時 \(minutes) 分"
            }
        }
    }
}

/// 今日播放的歌曲
struct TodayPlayedTrack: Codable, Identifiable {
    let id: String
    let name: String
    let artistName: String
    let albumName: String
    let imageUrl: String?
    let playedAt: String  // ISO8601 格式
    let durationMs: Int
    
    var playedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: playedAt)
    }
    
    var formattedTime: String {
        guard let date = playedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var durationFormatted: String {
        let totalSeconds = durationMs / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// 每月熱門項目（歌曲或藝人）- 基於 Spotify short_term（約 4 週）
struct WeeklyTopEntry: Codable, Identifiable {
    let id: String
    let name: String
    let artistName: String?  // 如果是歌曲，包含藝人名稱
    let imageUrl: String?
    let playCount: Int?
    let totalPlayTimeMs: Int?
    
    var totalPlayTimeFormatted: String? {
        guard let ms = totalPlayTimeMs else { return nil }
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

/// 每日聆聽記錄（用於快取）
struct DailyListeningLog: Codable {
    let date: String  // 格式: yyyy-MM-dd
    var totalMinutes: Int
    var lastPlayedAt: String?  // ISO8601 格式，用於避免重複計算
    var trackDurations: [String: Int] = [:]  // trackId: duration_ms
    
    static func dateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

/// 每月熱門快取（基於 Spotify short_term，約 4 週）
struct WeeklyTopCache: Codable {
    let tracks: [WeeklyTopEntry]
    let artists: [WeeklyTopEntry]
    let lastUpdated: Date
    let weekStartDate: String  // 格式: yyyy-MM-dd
    
    static func weekKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        return formatter.string(from: weekStart)
    }
    
    var isExpired: Bool {
        // 快取有效期：4 小時
        return Date().timeIntervalSince(lastUpdated) > 4 * 3600
    }
}

// MARK: - UserDefaults Keys Extension
extension UserDefaults {
    private enum Keys {
        static let dailyListeningLog = "dashboard.dailyListeningLog"
        static let weeklyTopCache = "dashboard.weeklyTopCache"
    }
    
    var dailyListeningLog: DailyListeningLog? {
        get {
            guard let data = data(forKey: Keys.dailyListeningLog) else { return nil }
            return try? JSONDecoder().decode(DailyListeningLog.self, from: data)
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Keys.dailyListeningLog)
            } else {
                removeObject(forKey: Keys.dailyListeningLog)
            }
        }
    }
    
    var weeklyTopCache: WeeklyTopCache? {
        get {
            guard let data = data(forKey: Keys.weeklyTopCache) else { return nil }
            return try? JSONDecoder().decode(WeeklyTopCache.self, from: data)
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Keys.weeklyTopCache)
            } else {
                removeObject(forKey: Keys.weeklyTopCache)
            }
        }
    }
}

