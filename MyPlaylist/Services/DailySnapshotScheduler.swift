import Foundation

/// 每日自動將 Spotify Top 50 寫入 CloudKit，確保趨勢圖有資料
final class DailySnapshotScheduler {
    static let shared = DailySnapshotScheduler()
    
    private let defaults = UserDefaults.standard
    private let lastSnapshotKey = "DailySnapshotScheduler.lastSnapshotDate"
    private let queue = DispatchQueue(label: "com.myplaylist.dailySnapshot", qos: .background)
    private let calendar = Calendar.current
    
    private init() {}
    
    /// 在取得 accessToken 後呼叫，若今日尚未寫入則會觸發一次
    func scheduleIfNeeded(accessToken: String) {
        guard !DemoModeManager.shared.isDemoMode else {
            return
        }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            guard self.shouldRunToday else {
                return
            }
            
            SpotifyAPIService.fetchCurrentUserProfile(accessToken: accessToken) { userProfile in
                guard let userId = userProfile?.id else { return }
                
                SpotifyAPIService.fetchTopTracks(
                    accessToken: accessToken,
                    timeRange: "short_term",
                    cacheKey: userId,
                    forceRefresh: true
                ) { result in
                    switch result {
                    case .success(let tracks):
                        self.persistSnapshotIfNeeded(userId: userId, tracks: tracks)
                    case .failure(let error):
                        print("❌ [DailySnapshot] 取得 Top Tracks 失敗：\(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// 回傳最後一次快照日期（供設定頁顯示）
    func lastSnapshotDate() -> Date? {
        defaults.object(forKey: lastSnapshotKey) as? Date
    }
    
    // MARK: - Private Helpers
    
    private var shouldRunToday: Bool {
        guard let lastDate = lastSnapshotDate() else {
            return true
        }
        return !calendar.isDate(lastDate, inSameDayAs: Date())
    }
    
    private func persistSnapshotIfNeeded(userId: String, tracks: [Track]) {
        guard !tracks.isEmpty else {
            return
        }
        
        CloudKitRankingService.shared.shouldRecord(userId: userId, for: "short_term") { shouldRecord in
            guard shouldRecord else {
                self.markSnapshotComplete()
                return
            }
            
            CloudKitRankingService.shared.saveCurrentRanking(
                userId: userId,
                tracks: tracks,
                timeRange: "short_term"
            )
            self.markSnapshotComplete()
        }
    }
    
    private func markSnapshotComplete() {
        defaults.set(Date(), forKey: lastSnapshotKey)
    }
}

