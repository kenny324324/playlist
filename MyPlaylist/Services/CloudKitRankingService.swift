import Foundation
import CloudKit
import Combine

/// CloudKit 同步狀態
enum CloudKitSyncStatus {
    case available        // 雲端可用且同步完成
    case syncing         // 載入中或同步中
    case unavailable     // 載入失敗或不可用
}

/// CloudKit 版本的排名歷史服務
/// 支援跨裝置同步、離線快取、自動清理
class CloudKitRankingService: ObservableObject {
    static let shared = CloudKitRankingService()
    
    // 狀態追蹤（用於 UI 顯示）
    @Published var syncStatus: CloudKitSyncStatus = .unavailable
    
    // CloudKit 容器和資料庫（延遲初始化）
    private var _container: CKContainer?
    private var _database: CKDatabase?
    private var hasTriedInitialization = false
    
    // Record Type 名稱
    private let recordType = "RankingHistory"
    
    // 本地快取（用於離線存取和快速讀取）
    private var localCache: [RankingHistory] = []
    private let cacheKey = "rankingHistoryCache"
    
    // CloudKit 是否可用（延遲檢查）
    private var isCloudKitAvailable: Bool {
        if !hasTriedInitialization {
            initializeCloudKitIfPossible()
        }
        return _container != nil && _database != nil
    }
    
    private var database: CKDatabase? {
        if !hasTriedInitialization {
            initializeCloudKitIfPossible()
        }
        return _database
    }
    
    private init() {
        // 僅載入本地快取，不初始化 CloudKit
        loadLocalCache()
        print("💾 本地儲存模式已啟用")
    }
    
    // 延遲初始化 CloudKit（只在第一次需要時執行）
    private func initializeCloudKitIfPossible() {
        guard !hasTriedInitialization else { return }
        hasTriedInitialization = true
        
        // 嘗試初始化 CloudKit
        // 使用新的 Container ID (spostats2) 因為原本的可能有 Apple 同步問題
        _container = CKContainer(identifier: "iCloud.com.kenny.spostats2")
        _database = _container?.privateCloudDatabase
        
        // 檢查是否成功初始化
        if _container != nil && _database != nil {
            print("✅ CloudKit 初始化成功！")
            print("☁️ 跨裝置同步功能已啟用")
            
            // 檢查 iCloud 帳號狀態
            _container?.accountStatus { accountStatus, error in
                DispatchQueue.main.async {
                    switch accountStatus {
                    case .available:
                        print("✅ iCloud 帳號狀態：正常")
                        self.syncStatus = .available
                    case .noAccount:
                        print("⚠️ 未登入 iCloud 帳號")
                        print("💡 請到「設定」登入 iCloud")
                        self.syncStatus = .unavailable
                    case .restricted:
                        print("⚠️ iCloud 使用受限")
                        self.syncStatus = .unavailable
                    case .couldNotDetermine:
                        print("⚠️ 無法確認 iCloud 狀態")
                        self.syncStatus = .unavailable
                    case .temporarilyUnavailable:
                        print("⚠️ iCloud 暫時無法使用")
                        self.syncStatus = .unavailable
                    @unknown default:
                        print("⚠️ 未知的 iCloud 狀態")
                        self.syncStatus = .unavailable
                    }
                    
                    if let error = error {
                        print("❌ iCloud 狀態檢查錯誤: \(error.localizedDescription)")
                        self.syncStatus = .unavailable
                    }
                }
            }
        } else {
            print("⚠️ CloudKit 未啟用")
            print("💡 如需跨裝置同步，請：")
            print("   1. 在 Xcode 中開啟專案")
            print("   2. 選擇 Target > Signing & Capabilities")
            print("   3. 新增 iCloud Capability")
            print("   4. 勾選 CloudKit")
            print("   5. 重新執行 App")
            print("📖 詳細步驟請參考：CLOUDKIT_SETUP.md")
            syncStatus = .unavailable
        }
    }
    
    // MARK: - 儲存排名記錄
    /// 儲存當前的歌曲排名到 CloudKit（如果可用）或本地
    /// - Parameters:
    ///   - userId: 用戶 ID
    ///   - tracks: 當前的歌曲列表
    ///   - timeRange: 時間範圍
    func saveCurrentRanking(userId: String, tracks: [Track], timeRange: String) {
        let now = Date()
        
        // 先更新本地快取
        for (index, track) in tracks.enumerated() {
            let historyItem = RankingHistory(
                userId: userId,
                trackId: track.id,
                rank: index + 1,
                timeRange: timeRange,
                recordedDate: now
            )
            localCache.append(historyItem)
        }
        
        // 儲存本地快取（保證離線也能用）
        saveLocalCache()
        
        // 如果 CloudKit 可用，也儲存到雲端
        guard isCloudKitAvailable, let db = database else {
            return
        }
        
        // 更新狀態為同步中
        DispatchQueue.main.async {
            self.syncStatus = .syncing
        }
        
        var recordsToSave: [CKRecord] = []
        
        // 為每首歌創建一個 CKRecord
        for (index, track) in tracks.enumerated() {
            let recordID = CKRecord.ID(recordName: "\(userId)_\(track.id)_\(timeRange)_\(Int(now.timeIntervalSince1970))")
            let record = CKRecord(recordType: recordType, recordID: recordID)
            
            // 設定欄位
            record["userId"] = userId as CKRecordValue
            record["trackId"] = track.id as CKRecordValue
            record["rank"] = index + 1 as CKRecordValue
            record["timeRange"] = timeRange as CKRecordValue
            record["recordedDate"] = now as CKRecordValue
            
            recordsToSave.append(record)
        }
        
        // 批次儲存到 CloudKit
        let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated
        
        operation.modifyRecordsResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ CloudKit: 成功同步 \(recordsToSave.count) 筆排名記錄")
                    // 清理舊記錄
                    self.cleanupOldRecords(userId: userId)
                    // 更新狀態為可用
                    self.syncStatus = .available
                    
                case .failure(let error):
                    print("❌ CloudKit 同步失敗: \(error.localizedDescription)")
                    if let ckError = error as? CKError {
                        print("🔍 錯誤 Code: \(ckError.code.rawValue)")
                    }
                    // 更新狀態為不可用
                    self.syncStatus = .unavailable
                }
            }
        }
        
        db.add(operation)
    }
    
    // MARK: - 計算排名變化
    /// 計算每首歌的排名變化（完全優先雲端策略）
    /// - Parameters:
    ///   - userId: 用戶 ID
    ///   - currentTracks: 當前的歌曲列表
    ///   - timeRange: 時間範圍
    ///   - completion: 完成回調，返回排名變化字典
    func calculateRankChanges(
        userId: String,
        currentTracks: [Track],
        timeRange: String,
        completion: @escaping ([String: RankChange]) -> Void
    ) {
        // 如果 CloudKit 可用，優先從雲端獲取資料
        if isCloudKitAvailable {
            // 更新狀態為同步中
            DispatchQueue.main.async {
                self.syncStatus = .syncing
            }
            
            print("☁️ 優先從 CloudKit 同步歷史排名資料...")
            
            // 從 CloudKit 同步資料（等待完成）
            fetchLatestRankings(userId: userId, timeRange: timeRange) { cloudRecords in
                DispatchQueue.main.async {
                    if !cloudRecords.isEmpty {
                        print("✅ 從 CloudKit 同步了 \(cloudRecords.count) 筆歷史記錄")
                        // 用 CloudKit 資料更新本地快取
                        self.updateLocalCache(with: cloudRecords, userId: userId, timeRange: timeRange)
                        
                        // 使用 CloudKit 資料計算排名變化
                        let cloudResults = self.calculateFromCache(userId: userId, currentTracks: currentTracks, timeRange: timeRange)
                        
                        // 更新狀態為可用
                        self.syncStatus = .available
                        completion(cloudResults)
                    } else {
                        // CloudKit 也沒有資料，這是真正的初次使用
                        print("ℹ️ CloudKit 也沒有歷史記錄，這是初次使用")
                        let cachedResults = self.calculateFromCache(userId: userId, currentTracks: currentTracks, timeRange: timeRange)
                        
                        // 更新狀態為可用（雖然沒有歷史資料，但 CloudKit 可用）
                        self.syncStatus = .available
                        completion(cachedResults)
                    }
                }
            }
        } else {
            // CloudKit 不可用，使用本地快取
            print("💾 CloudKit 不可用，使用本地快取")
            DispatchQueue.main.async {
                self.syncStatus = .unavailable
            }
            
            let cachedResults = calculateFromCache(userId: userId, currentTracks: currentTracks, timeRange: timeRange)
            completion(cachedResults)
        }
    }
    
    // MARK: - 從快取計算排名變化
    private func calculateFromCache(userId: String, currentTracks: [Track], timeRange: String) -> [String: RankChange] {
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        
        // 從快取中篩選符合條件的記錄
        let previousRankings = localCache.filter {
            $0.userId == userId && $0.timeRange == timeRange && $0.recordedDate < oneHourAgo
        }
        
        // 如果沒有歷史記錄，所有歌曲都是新的
        guard !previousRankings.isEmpty else {
            return currentTracks.reduce(into: [:]) { result, track in
                result[track.id] = .new
            }
        }
        
        // 取得最近的一筆記錄日期
        guard let latestDate = previousRankings.map(\.recordedDate).max() else {
            return [:]
        }
        
        // 取得該日期的所有排名
        let previousRanks = previousRankings.filter { $0.recordedDate == latestDate }
        
        // 計算變化
        var changes: [String: RankChange] = [:]
        for (currentIndex, track) in currentTracks.enumerated() {
            let currentRank = currentIndex + 1
            
            if let previous = previousRanks.first(where: { $0.trackId == track.id }) {
                let difference = previous.rank - currentRank
                if difference > 0 {
                    changes[track.id] = .up(difference)
                } else if difference < 0 {
                    changes[track.id] = .down(abs(difference))
                } else {
                    changes[track.id] = .same
                }
            } else {
                changes[track.id] = .new
            }
        }
        
        return changes
    }
    
    // MARK: - 從 CloudKit 獲取最新排名
    private func fetchLatestRankings(userId: String, timeRange: String, completion: @escaping ([RankingHistory]) -> Void) {
        // 如果 CloudKit 不可用，直接返回空陣列
        guard isCloudKitAvailable, let db = database else {
            DispatchQueue.main.async {
                self.syncStatus = .unavailable
            }
            completion([])
            return
        }
        
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        
        // 建立查詢條件
        let userPredicate = NSPredicate(format: "userId == %@", userId)
        let timeRangePredicate = NSPredicate(format: "timeRange == %@", timeRange)
        let datePredicate = NSPredicate(format: "recordedDate < %@", oneHourAgo as NSDate)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [userPredicate, timeRangePredicate, datePredicate])
        
        let query = CKQuery(recordType: recordType, predicate: compoundPredicate)
        query.sortDescriptors = [NSSortDescriptor(key: "recordedDate", ascending: false)]
        
        // 執行查詢
        db.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 100) { result in
            switch result {
            case .success(let matchResults):
                var rankings: [RankingHistory] = []
                
                for (_, recordResult) in matchResults.matchResults {
                    switch recordResult {
                    case .success(let record):
                        if let history = self.convertToRankingHistory(record: record) {
                            rankings.append(history)
                        }
                    case .failure(let error):
                        print("❌ 記錄讀取失敗: \(error)")
                    }
                }
                
                completion(rankings)
                
            case .failure(let error):
                if let ckError = error as? CKError {
                    print("❌ CloudKit 查詢失敗:", ckError, "userInfo:", ckError.userInfo)
                } else {
                    print("❌ CloudKit 查詢失敗:", error)
                }
                
                // 查詢失敗時更新狀態
                DispatchQueue.main.async {
                    self.syncStatus = .unavailable
                }
                completion([])
            }
        }
    }
    
    // MARK: - 轉換 CKRecord 為 RankingHistory
    private func convertToRankingHistory(record: CKRecord) -> RankingHistory? {
        guard let userId = record["userId"] as? String,
              let trackId = record["trackId"] as? String,
              let rank = record["rank"] as? Int,
              let timeRange = record["timeRange"] as? String,
              let recordedDate = record["recordedDate"] as? Date else {
            return nil
        }
        
        return RankingHistory(
            userId: userId,
            trackId: trackId,
            rank: rank,
            timeRange: timeRange,
            recordedDate: recordedDate
        )
    }
    
    // MARK: - 更新本地快取
    private func updateLocalCache(with cloudRecords: [RankingHistory], userId: String, timeRange: String) {
        // 移除舊的快取資料（同一用戶和時間範圍）
        localCache.removeAll { $0.userId == userId && $0.timeRange == timeRange }
        
        // 加入新資料
        localCache.append(contentsOf: cloudRecords)
        
        // 儲存快取
        saveLocalCache()
    }
    
    // MARK: - 檢查是否需要記錄
    /// 判斷是否需要記錄新的排名
    /// - Parameters:
    ///   - userId: 用戶 ID
    ///   - timeRange: 時間範圍
    ///   - completion: 完成回調
    func shouldRecord(userId: String, for timeRange: String, completion: @escaping (Bool) -> Void) {
        // 先檢查本地快取
        let cachedRecords = localCache.filter { $0.userId == userId && $0.timeRange == timeRange }
        
        if let lastDate = cachedRecords.map(\.recordedDate).max() {
            let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
            
            if lastDate > oneHourAgo {
                // 本地快取顯示不需要記錄
                completion(false)
                return
            }
        }
        
        // 如果 CloudKit 不可用，僅依靠本地快取判斷
        guard isCloudKitAvailable, let db = database else {
            // 本地快取沒有資料或已過期，應該記錄
            completion(true)
            return
        }
        
        // 從 CloudKit 確認
        let userPredicate = NSPredicate(format: "userId == %@", userId)
        let timeRangePredicate = NSPredicate(format: "timeRange == %@", timeRange)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [userPredicate, timeRangePredicate])
        
        let query = CKQuery(recordType: recordType, predicate: compoundPredicate)
        query.sortDescriptors = [NSSortDescriptor(key: "recordedDate", ascending: false)]
        
        db.fetch(withQuery: query, inZoneWith: nil, desiredKeys: ["recordedDate"], resultsLimit: 1) { result in
            switch result {
            case .success(let matchResults):
                if let firstMatch = matchResults.matchResults.first?.1,
                   case .success(let record) = firstMatch,
                   let lastDate = record["recordedDate"] as? Date {
                    let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
                    completion(lastDate < oneHourAgo)
                } else {
                    // 沒有記錄，應該記錄
                    completion(true)
                }
                
            case .failure(let error):
                print("❌ CloudKit 查詢失敗:", error)
                // 錯誤時保守處理，允許記錄
                completion(true)
            }
        }
    }
    
    // MARK: - 清理舊記錄
    /// 清理 7 天前的舊記錄
    private func cleanupOldRecords(userId: String) {
        // 先清理本地快取
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        localCache.removeAll { $0.userId == userId && $0.recordedDate < sevenDaysAgo }
        saveLocalCache()
        
        // 如果 CloudKit 可用，也清理雲端資料
        guard isCloudKitAvailable, let db = database else {
            return
        }
        
        let userPredicate = NSPredicate(format: "userId == %@ AND recordedDate < %@", userId, sevenDaysAgo as NSDate)
        let query = CKQuery(recordType: recordType, predicate: userPredicate)
        
        db.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
            switch result {
            case .success(let matchResults):
                let recordIDsToDelete = matchResults.matchResults.compactMap { _, recordResult -> CKRecord.ID? in
                    if case .success(let record) = recordResult {
                        return record.recordID
                    }
                    return nil
                }
                
                if !recordIDsToDelete.isEmpty {
                    let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsToDelete)
                    deleteOperation.modifyRecordsResultBlock = { result in
                        if case .success = result {
                            print("✅ CloudKit: 清理了 \(recordIDsToDelete.count) 筆舊記錄")
                        }
                    }
                    db.add(deleteOperation)
                }
                
            case .failure(let error):
                if let ckError = error as? CKError {
                    print("❌ CloudKit 清理失敗:", ckError, "userInfo:", ckError.userInfo)
                } else {
                    print("❌ CloudKit 清理失敗:", error)
                }
            }
        }
    }
    
    // MARK: - 本地快取管理
    private func loadLocalCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cache = try? JSONDecoder().decode([RankingHistory].self, from: data) else {
            return
        }
        localCache = cache
    }
    
    private func saveLocalCache() {
        if let encoded = try? JSONEncoder().encode(localCache) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    // MARK: - 查詢特定歌曲的排名歷史
    /// 獲取特定歌曲在過去 7 天的排名歷史
    func fetchTrackRankingHistory(
        userId: String,
        trackId: String,
        timeRange: String,
        completion: @escaping ([RankingHistory]) -> Void
    ) {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        print("📊 [CloudKit] 查詢排名歷史")
        print("  - userId: \(userId)")
        print("  - trackId: \(trackId)")
        print("  - timeRange: \(timeRange)")
        print("  - 從 \(sevenDaysAgo) 到現在")
        
        // 如果 CloudKit 可用，從雲端查詢
        guard isCloudKitAvailable, let db = database else {
            print("⚠️ CloudKit 不可用，使用本地快取")
            let filtered = self.filterLocalCache(userId: userId, trackId: trackId, timeRange: timeRange, since: sevenDaysAgo)
            completion(filtered)
            return
        }
        
        // 建立查詢條件（需要在 CloudKit Dashboard 設定 trackId 為 queryable）
        let userPredicate = NSPredicate(format: "userId == %@", userId)
        let trackPredicate = NSPredicate(format: "trackId == %@", trackId)
        let timeRangePredicate = NSPredicate(format: "timeRange == %@", timeRange)
        let datePredicate = NSPredicate(format: "recordedDate >= %@", sevenDaysAgo as NSDate)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            userPredicate, trackPredicate, timeRangePredicate, datePredicate
        ])
        
        let query = CKQuery(recordType: recordType, predicate: compoundPredicate)
        query.sortDescriptors = [NSSortDescriptor(key: "recordedDate", ascending: true)]
        
        print("☁️ 從 CloudKit 查詢歷史資料（trackId: \(trackId)）...")
        
        db.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
            switch result {
            case .success(let queryResult):
                let histories = queryResult.matchResults.compactMap { (recordID, recordResult) -> RankingHistory? in
                    switch recordResult {
                    case .success(let record):
                        return self.convertToRankingHistory(record: record)
                    case .failure(let error):
                        print("❌ 解析記錄失敗: \(error.localizedDescription)")
                        return nil
                    }
                }
                
                print("✅ 從 CloudKit 查詢到 \(histories.count) 筆歷史記錄")
                if !histories.isEmpty {
                    print("  - 最早: \(histories.first!.recordedDate)")
                    print("  - 最晚: \(histories.last!.recordedDate)")
                }
                
                DispatchQueue.main.async {
                    completion(histories)
                }
                
            case .failure(let error):
                print("❌ CloudKit 查詢失敗: \(error.localizedDescription)")
                if error.localizedDescription.contains("not marked queryable") {
                    print("⚠️ 請在 CloudKit Dashboard 將 'trackId' 欄位設定為 Queryable")
                }
                // 降級使用本地快取
                let filtered = self.filterLocalCache(userId: userId, trackId: trackId, timeRange: timeRange, since: sevenDaysAgo)
                DispatchQueue.main.async {
                    completion(filtered)
                }
            }
        }
    }
    
    // MARK: - 輔助方法：從本地快取過濾
    private func filterLocalCache(userId: String, trackId: String, timeRange: String, since: Date) -> [RankingHistory] {
        print("  - localCache 總共有 \(localCache.count) 筆記錄")
        
        let filtered = localCache.filter { history in
            history.userId == userId &&
            history.trackId == trackId &&
            history.timeRange == timeRange &&
            history.recordedDate >= since
        }
        .sorted { $0.recordedDate < $1.recordedDate }
        
        print("📊 [LocalCache] 找到 \(filtered.count) 筆符合條件的記錄")
        if !filtered.isEmpty {
            print("  - 最早: \(filtered.first!.recordedDate)")
            print("  - 最晚: \(filtered.last!.recordedDate)")
        }
        
        return filtered
    }
    
    // MARK: - 清除特定用戶的資料
    /// 清除特定用戶的所有歷史記錄
    func clearHistory(for userId: String, completion: @escaping (Bool) -> Void) {
        // 先清理本地快取
        localCache.removeAll { $0.userId == userId }
        saveLocalCache()
        
        // 如果 CloudKit 不可用，直接返回成功
        guard isCloudKitAvailable, let db = database else {
            completion(true)
            return
        }
        
        let predicate = NSPredicate(format: "userId == %@", userId)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        db.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
            switch result {
            case .success(let matchResults):
                let recordIDsToDelete = matchResults.matchResults.compactMap { _, recordResult -> CKRecord.ID? in
                    if case .success(let record) = recordResult {
                        return record.recordID
                    }
                    return nil
                }
                
                if !recordIDsToDelete.isEmpty {
                    let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsToDelete)
                    deleteOperation.modifyRecordsResultBlock = { result in
                        if case .success = result {
                            print("✅ CloudKit: 清除了 \(recordIDsToDelete.count) 筆記錄")
                            completion(true)
                        } else {
                            completion(false)
                        }
                    }
                    db.add(deleteOperation)
                } else {
                    completion(true)
                }
                
            case .failure(let error):
                if let ckError = error as? CKError {
                    print("❌ CloudKit 清除失敗:", ckError, "userInfo:", ckError.userInfo)
                } else {
                    print("❌ CloudKit 清除失敗:", error)
                }
                completion(false)
            }
        }
    }
}

