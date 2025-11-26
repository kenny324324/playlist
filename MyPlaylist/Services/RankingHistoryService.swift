import Foundation

class RankingHistoryService {
    static let shared = RankingHistoryService()
    private let userDefaults = UserDefaults.standard
    private let historyKey = "rankingHistory"
    
    private init() {}
    
    // MARK: - 儲存當前排名
    /// 儲存當前的歌曲排名到 UserDefaults
    /// - Parameters:
    ///   - userId: 用戶 ID，用來區分不同帳號
    ///   - tracks: 當前的歌曲列表
    ///   - timeRange: 時間範圍（short_term, medium_term, long_term）
    func saveCurrentRanking(userId: String, tracks: [Track], timeRange: String) {
        var history = loadHistory()
        
        // 只保留最近7天的記錄，避免資料過多（ 我是ㄒㄧㄤ每小時記錄一次，7天約168筆記錄）
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        history = history.filter { $0.recordedDate > sevenDaysAgo }
        
        // 加入新記錄
        let now = Date()
        for (index, track) in tracks.enumerated() {
            let record = RankingHistory(
                userId: userId,
                trackId: track.id,
                rank: index + 1,
                timeRange: timeRange,
                recordedDate: now,
                albumId: track.album.id,
                artistIds: track.artists.compactMap { $0.id }.joined(separator: ",")
            )
            history.append(record)
        }
        
        // 儲存到 UserDefaults
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    // MARK: - 計算排名變化
    /// 計算每首歌的排名變化
    /// - Parameters:
    ///   - userId: 用戶 ID，只比較同一用戶的歷史記錄
    ///   - currentTracks: 當前的歌曲列表
    ///   - timeRange: 時間範圍
    /// - Returns: 每首歌的排名變化字典（key: trackId, value: RankChange）
    func calculateRankChanges(userId: String, currentTracks: [Track], timeRange: String) -> [String: RankChange] {
        let history = loadHistory()
        
        // 找出至少1小時前的記錄（只看當前用戶的記錄）
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let previousRankings = history.filter {
            $0.userId == userId && $0.timeRange == timeRange && $0.recordedDate < oneHourAgo
        }
        
        // 如果沒有歷史記錄，所有歌曲都是新的
        guard !previousRankings.isEmpty else {
            return currentTracks.reduce(into: [:]) { result, track in
                result[track.id] = .new
            }
        }
        
        // 取得最近的一筆歷史記錄日期
        let latestPreviousDate = previousRankings.map(\.recordedDate).max()
        guard let latestDate = latestPreviousDate else {
            return [:]
        }
        
        // 取得該日期的所有排名
        let previousRanks = previousRankings.filter { $0.recordedDate == latestDate }
        
        // 計算變化
        var changes: [String: RankChange] = [:]
        for (currentIndex, track) in currentTracks.enumerated() {
            let currentRank = currentIndex + 1
            
            // 查找這首歌在上次記錄中的排名
            if let previous = previousRanks.first(where: { $0.trackId == track.id }) {
                let difference = previous.rank - currentRank
                if difference > 0 {
                    // 排名上升（數字變小）
                    changes[track.id] = .up(difference)
                } else if difference < 0 {
                    // 排名下降（數字變大）
                    changes[track.id] = .down(abs(difference))
                } else {
                    // 排名不變
                    changes[track.id] = .same
                }
            } else {
                // 新進榜
                changes[track.id] = .new
            }
        }
        
        return changes
    }
    
    // MARK: - 載入歷史記錄
    /// 從 UserDefaults 載入所有歷史記錄
    /// - Returns: 歷史記錄陣列
    private func loadHistory() -> [RankingHistory] {
        guard let data = userDefaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([RankingHistory].self, from: data) else {
            return []
        }
        return history
    }
    
    // MARK: - 清除歷史記錄
    /// 清除所有歷史記錄（用於測試或重置）
    func clearHistory() {
        userDefaults.removeObject(forKey: historyKey)
    }
    
    // MARK: - 取得最近一次記錄的日期
    /// 取得特定用戶和時間範圍的最近記錄日期
    /// - Parameters:
    ///   - userId: 用戶 ID
    ///   - timeRange: 時間範圍
    /// - Returns: 最近記錄的日期，如果沒有記錄則返回 nil
    func getLatestRecordDate(userId: String, for timeRange: String) -> Date? {
        let history = loadHistory()
        let filtered = history.filter { $0.userId == userId && $0.timeRange == timeRange }
        return filtered.map(\.recordedDate).max()
    }
    
    // MARK: - 是否需要記錄
    /// 判斷是否需要記錄新的排名（避免頻繁記錄）
    /// 設定：每1小時記錄一次
    /// - Parameters:
    ///   - userId: 用戶 ID
    ///   - timeRange: 時間範圍
    /// - Returns: 如果距離上次記錄超過1小時，返回 true
    func shouldRecord(userId: String, for timeRange: String) -> Bool {
        guard let lastRecordDate = getLatestRecordDate(userId: userId, for: timeRange) else {
            // 沒有記錄，應該記錄
            return true
        }
        
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        return lastRecordDate < oneHourAgo
    }
    
    // MARK: - 清除特定用戶的歷史記錄
    /// 清除特定用戶的所有歷史記錄（用於登出時）
    /// - Parameter userId: 用戶 ID
    func clearHistory(for userId: String) {
        var history = loadHistory()
        history = history.filter { $0.userId != userId }
        
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
}

