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
    private let fileManager = FileManager.default
    private let cacheQueue = DispatchQueue(label: "com.myplaylist.rankingCache", qos: .utility)
    private lazy var cacheFileURL: URL = {
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = directory.appendingPathComponent("RankingCache", isDirectory: true)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("ranking_history.json")
    }()
    
    // 狀態追蹤（用於 UI 顯示）
    @Published var syncStatus: CloudKitSyncStatus = .unavailable

    private struct DailyAggregateRecord {
        enum EntityType: String {
            case album
            case artist
        }
        
        let userId: String
        let entityType: EntityType
        let entityId: String
        let timeRange: String
        let dayKey: Date
        let count: Int
        let capturedAt: Date
    }
    
    private struct DailyAggregateData {
        let dayKey: Date
        let count: Int
        let capturedAt: Date
    }
    
    // CloudKit 容器和資料庫（延遲初始化）
    private var _container: CKContainer?
    private var _database: CKDatabase?
    private var hasTriedInitialization = false
    
    // Record Type 名稱
    private let recordType = "RankingHistory"
    private let aggregateRecordType = "DailyAggregate"
    
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
                recordedDate: now,
                albumId: track.album.id,
                artistIds: track.artists.compactMap { $0.id }.joined(separator: ",")
            )
            localCache.append(historyItem)
        }
        
        trimLocalCache(for: userId)
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
            record["albumId"] = (track.album.id ?? "") as CKRecordValue
            record["artistIds"] = track.artists.compactMap { $0.id }.joined(separator: ",") as CKRecordValue
            
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
                    // 寫入每日加總資料
                    self.saveDailyAggregates(
                        userId: userId,
                        timeRange: timeRange,
                        tracks: tracks,
                        recordedDate: now
                    )
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
        
        // 新欄位（可能為 nil，用於向後兼容）
        let albumId = record["albumId"] as? String
        let artistIds = record["artistIds"] as? String
        
        return RankingHistory(
            userId: userId,
            trackId: trackId,
            rank: rank,
            timeRange: timeRange,
            recordedDate: recordedDate,
            albumId: albumId,
            artistIds: artistIds
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
        if let data = try? Data(contentsOf: cacheFileURL),
           let cache = try? JSONDecoder().decode([RankingHistory].self, from: data) {
            localCache = cache
            return
        }
        
        // Legacy UserDefaults migration
        if let legacyData = UserDefaults.standard.data(forKey: cacheKey),
           let cache = try? JSONDecoder().decode([RankingHistory].self, from: legacyData) {
            localCache = cache
            saveLocalCache()
            UserDefaults.standard.removeObject(forKey: cacheKey)
            return
        }
        
        // Older RankingHistoryService（UserDefaults "rankingHistory"）資料也一起遷移
        if localCache.isEmpty,
           let legacyData = UserDefaults.standard.data(forKey: "rankingHistory"),
           let cache = try? JSONDecoder().decode([RankingHistory].self, from: legacyData) {
            localCache = cache
            saveLocalCache()
            UserDefaults.standard.removeObject(forKey: "rankingHistory")
        }
    }
    
    private func saveLocalCache() {
        let snapshot = localCache
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try JSONEncoder().encode(snapshot)
                try self.ensureCacheDirectoryExists()
                try data.write(to: self.cacheFileURL, options: .atomic)
            } catch {
                print("❌ 儲存本地排名快取失敗: \(error.localizedDescription)")
            }
        }
    }

    private func saveDailyAggregates(
        userId: String,
        timeRange: String,
        tracks: [Track],
        recordedDate: Date
    ) {
        guard isCloudKitAvailable, let db = database else {
            return
        }
        guard !tracks.isEmpty else { return }
        
        let dayKey = Calendar.current.startOfDay(for: recordedDate)
        var aggregates: [DailyAggregateRecord] = []
        
        var albumCounts: [String: Int] = [:]
        var artistCounts: [String: Int] = [:]
        
        for track in tracks {
            if let albumId = track.album.id, !albumId.isEmpty {
                albumCounts[albumId, default: 0] += 1
            }
            
            let artistIds = track.artists.compactMap { $0.id }.filter { !$0.isEmpty }
            for artistId in artistIds {
                artistCounts[artistId, default: 0] += 1
            }
        }
        
        let capturedAt = recordedDate
        for (albumId, count) in albumCounts {
            aggregates.append(DailyAggregateRecord(
                userId: userId,
                entityType: .album,
                entityId: albumId,
                timeRange: timeRange,
                dayKey: dayKey,
                count: count,
                capturedAt: capturedAt
            ))
        }
        
        for (artistId, count) in artistCounts {
            aggregates.append(DailyAggregateRecord(
                userId: userId,
                entityType: .artist,
                entityId: artistId,
                timeRange: timeRange,
                dayKey: dayKey,
                count: count,
                capturedAt: capturedAt
            ))
        }
        
        guard !aggregates.isEmpty else { return }
        
        let recordsToSave: [CKRecord] = aggregates.map { aggregate in
            let keyTimestamp = Int(aggregate.dayKey.timeIntervalSince1970)
            let recordName = "\(aggregate.userId)_\(aggregate.entityType.rawValue)_\(aggregate.entityId)_\(aggregate.timeRange)_\(keyTimestamp)"
            let recordID = CKRecord.ID(recordName: recordName)
            let record = CKRecord(recordType: aggregateRecordType, recordID: recordID)
            
            record["userId"] = aggregate.userId as CKRecordValue
            record["entityType"] = aggregate.entityType.rawValue as CKRecordValue
            record["entityId"] = aggregate.entityId as CKRecordValue
            record["timeRange"] = aggregate.timeRange as CKRecordValue
            record["dayKey"] = aggregate.dayKey as CKRecordValue
            record["count"] = aggregate.count as CKRecordValue
            record["capturedAt"] = aggregate.capturedAt as CKRecordValue
            
            return record
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
        operation.savePolicy = .allKeys
        operation.qualityOfService = .utility
        operation.modifyRecordsResultBlock = { result in
            if case .failure(let error) = result {
                print("❌ CloudKit: 儲存 DailyAggregate 失敗：\(error.localizedDescription)")
            } else {
                print("✅ CloudKit: 更新每日加總 \(recordsToSave.count) 筆")
            }
        }
        db.add(operation)
    }
    
    private func fetchDailyAggregates(
        db: CKDatabase,
        userId: String,
        entityType: DailyAggregateRecord.EntityType,
        entityId: String,
        timeRange: String,
        since: Date,
        completion: @escaping ([DailyAggregateData]) -> Void
    ) {
        var fetchedAggregates: [DailyAggregateData] = []
        
        let predicates: [NSPredicate] = [
            NSPredicate(format: "userId == %@", userId),
            NSPredicate(format: "entityType == %@", entityType.rawValue),
            NSPredicate(format: "entityId == %@", entityId),
            NSPredicate(format: "timeRange == %@", timeRange),
            NSPredicate(format: "dayKey >= %@", since as NSDate)
        ]
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: aggregateRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "dayKey", ascending: false)]
        
        func finish() {
            DispatchQueue.main.async {
                completion(fetchedAggregates)
            }
        }
        
        func fetchPage(cursor: CKQueryOperation.Cursor? = nil) {
            let operation: CKQueryOperation
            if let cursor = cursor {
                operation = CKQueryOperation(cursor: cursor)
            } else {
                operation = CKQueryOperation(query: query)
            }
            
            operation.resultsLimit = 400
            operation.desiredKeys = ["dayKey", "count", "capturedAt"]
            
            operation.recordMatchedBlock = { _, recordResult in
                if case .success(let record) = recordResult,
                   let dayKey = record["dayKey"] as? Date,
                   let count = record["count"] as? Int,
                   let capturedAt = record["capturedAt"] as? Date {
                    fetchedAggregates.append(DailyAggregateData(dayKey: dayKey, count: count, capturedAt: capturedAt))
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success(let cursor):
                    if let cursor = cursor {
                        fetchPage(cursor: cursor)
                    } else {
                        finish()
                    }
                case .failure(let error):
                    print("❌ CloudKit DailyAggregate 查詢失敗: \(error.localizedDescription)")
                    finish()
                }
            }
            
            db.add(operation)
        }
        
        fetchPage()
    }
    
    private func buildAggregateDataPoints(from aggregates: [DailyAggregateData]) -> [CountDataPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let past7Days = (0...6).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()
        
        var latestPerDay: [Date: DailyAggregateData] = [:]
        for aggregate in aggregates {
            let day = calendar.startOfDay(for: aggregate.dayKey)
            if let existing = latestPerDay[day] {
                if aggregate.capturedAt > existing.capturedAt {
                    latestPerDay[day] = aggregate
                }
            } else {
                latestPerDay[day] = aggregate
            }
        }
        
        return past7Days.map { date in
            CountDataPoint(date: date, count: latestPerDay[date]?.count ?? 0)
        }
    }
    
    private func ensureCacheDirectoryExists() throws {
        let directory = cacheFileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
    
    private func trimLocalCache(for userId: String) {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        localCache.removeAll { $0.userId == userId && $0.recordedDate < sevenDaysAgo }
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
    
    // MARK: - 查詢過去 7 天所有進入 Top 5 的歌曲
    /// 查詢過去 7 天所有曾經排名 <= 5 的歌曲 ID
    func fetchAllTop5TracksInLast7Days(
        userId: String,
        timeRange: String,
        completion: @escaping ([String]) -> Void
    ) {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        print("📊 [CloudKit] 查詢過去 7 天所有 Top 5 歌曲")
        print("  - 查詢條件：userId=\(userId), timeRange=\(timeRange), date>=\(sevenDaysAgo), rank<=5")
        
        // 如果 CloudKit 不可用，從本地快取查詢
        guard isCloudKitAvailable, let db = database else {
            print("⚠️ CloudKit 不可用，使用本地快取")
            print("  - localCache 總共有 \(localCache.count) 筆記錄")
            
            // Debug: 列出本地快取中所有記錄的日期範圍
            if let oldest = localCache.map(\.recordedDate).min(),
               let newest = localCache.map(\.recordedDate).max() {
                print("  - 本地快取日期範圍：\(oldest) 到 \(newest)")
            }
            
            let filtered = localCache.filter { 
                $0.userId == userId && 
                $0.timeRange == timeRange && 
                $0.recordedDate >= sevenDaysAgo && 
                $0.rank <= 5 
            }
            
            print("  - 符合條件的記錄：\(filtered.count) 筆")
            
            // Debug: 列出所有符合條件的記錄
            for record in filtered.prefix(30) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd HH:mm"
                print("    - \(formatter.string(from: record.recordedDate)): Track \(record.trackId.prefix(10))... Rank #\(record.rank)")
            }
            
            let trackIds = filtered.map { $0.trackId }
            let uniqueTrackIds = Array(Set(trackIds))
            
            print("  - 去重後有 \(uniqueTrackIds.count) 首不同的歌曲曾經進入 Top 5")
            print("  - 這意味著過去 7 天內有 \(uniqueTrackIds.count) 首歌曾經排名在前 5 名內")
            
            completion(uniqueTrackIds)
            return
        }
        
        // 從 CloudKit 查詢
        let userPredicate = NSPredicate(format: "userId == %@", userId)
        let timeRangePredicate = NSPredicate(format: "timeRange == %@", timeRange)
        let datePredicate = NSPredicate(format: "recordedDate >= %@", sevenDaysAgo as NSDate)
        let rankPredicate = NSPredicate(format: "rank <= 5")
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            userPredicate, timeRangePredicate, datePredicate, rankPredicate
        ])
        
        let query = CKQuery(recordType: recordType, predicate: compoundPredicate)
        query.sortDescriptors = [NSSortDescriptor(key: "recordedDate", ascending: false)]
        
        // 使用遞迴方式獲取所有分頁結果
        var allRecordDetails: [(trackId: String, rank: Int, date: Date)] = []
        
        func fetchPage(cursor: CKQueryOperation.Cursor? = nil) {
            let operation: CKQueryOperation
            
            if let cursor = cursor {
                operation = CKQueryOperation(cursor: cursor)
            } else {
                operation = CKQueryOperation(query: query)
            }
            
            operation.desiredKeys = ["trackId", "rank", "recordedDate"]
            operation.resultsLimit = 400  // 每次獲取 400 筆
            
            operation.recordMatchedBlock = { recordID, recordResult in
                if case .success(let record) = recordResult,
                   let trackId = record["trackId"] as? String,
                   let rank = record["rank"] as? Int,
                   let date = record["recordedDate"] as? Date {
                    allRecordDetails.append((trackId: trackId, rank: rank, date: date))
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success(let cursor):
                    if let cursor = cursor {
                        // 還有更多資料，繼續獲取下一頁
                        print("  📄 已獲取 \(allRecordDetails.count) 筆，繼續獲取下一頁...")
                        fetchPage(cursor: cursor)
                    } else {
                        // 所有資料都獲取完畢
                        self.processAllRecords(allRecordDetails, userId: userId, timeRange: timeRange, sevenDaysAgo: sevenDaysAgo, completion: completion)
                    }
                    
                case .failure(let error):
                    print("❌ CloudKit 查詢失敗: \(error.localizedDescription)")
                    // 降級使用本地快取
                    let trackIds = self.localCache
                        .filter { $0.userId == userId && $0.timeRange == timeRange && $0.recordedDate >= sevenDaysAgo && $0.rank <= 5 }
                        .map { $0.trackId }
                    let uniqueTrackIds = Array(Set(trackIds))
                    
                    DispatchQueue.main.async {
                        completion(uniqueTrackIds)
                    }
                }
            }
            
            db.add(operation)
        }
        
        // 開始第一頁的查詢
        fetchPage()
    }
    
    // 處理所有獲取到的記錄
    private func processAllRecords(
        _ recordDetails: [(trackId: String, rank: Int, date: Date)],
        userId: String,
        timeRange: String,
        sevenDaysAgo: Date,
        completion: @escaping ([String]) -> Void
    ) {
        let trackIds = recordDetails.map { $0.trackId }
        let uniqueTrackIds = Array(Set(trackIds))
        
        print("✅ CloudKit 查詢成功（包含所有分頁）")
        print("  - 找到 \(trackIds.count) 筆記錄")
        print("  - 去重後有 \(uniqueTrackIds.count) 首不同的歌曲曾經進入 Top 5")
        
        // Debug: 按日期分析每天的 Top 5
        print("\n📅 按日期分析（每天的 Top 5）：")
        let calendar = Calendar.current
        let groupedByDate = Dictionary(grouping: recordDetails) { record -> Date in
            calendar.startOfDay(for: record.date)
        }
        
        let sortedDates = groupedByDate.keys.sorted()
        for date in sortedDates {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd (EEE)"
            print("\n  📆 \(formatter.string(from: date))")
            
            if let dayRecords = groupedByDate[date] {
                // 找出該天最新的一筆記錄時間
                let latestTime = dayRecords.map { $0.date }.max()!
                let latestRecords = dayRecords.filter { $0.date == latestTime }
                
                // 按排名排序
                let top5 = latestRecords
                    .filter { $0.rank <= 5 }
                    .sorted(by: { $0.rank < $1.rank })
                
                for record in top5 {
                    print("     #\(record.rank): \(record.trackId.prefix(15))...")
                }
                
                if top5.count < 5 {
                    print("     ⚠️ 只有 \(top5.count) 首歌的記錄")
                }
            }
        }
        
        // Debug: 顯示每首歌的詳細記錄
        print("\n📋 詳細記錄（按歌曲分組）：")
        let groupedByTrack = Dictionary(grouping: recordDetails, by: { $0.trackId })
        for (trackId, records) in groupedByTrack.sorted(by: { $0.value.count > $1.value.count }) {
            let sortedRecords = records.sorted(by: { $0.date < $1.date })
            print("\n  🎵 Track \(trackId.prefix(15))...")
            print("     共 \(records.count) 筆記錄")
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd HH:mm"
            for record in sortedRecords.prefix(10) {
                print("     - \(formatter.string(from: record.date)): Rank #\(record.rank)")
            }
            if sortedRecords.count > 10 {
                print("     ... 還有 \(sortedRecords.count - 10) 筆")
            }
        }
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        DispatchQueue.main.async {
            completion(uniqueTrackIds)
        }
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
    
    // MARK: - 查詢專輯數量趨勢
    /// 獲取專輯在過去時間內的歌曲數量趨勢
    func fetchAlbumCountTrend(
        userId: String,
        albumId: String,
        timeRange: String,
        fallbackTrackIds: Set<String>? = nil,
        completion: @escaping (AlbumCountTrend?) -> Void
    ) {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        print("📊 [CloudKit] 查詢專輯數量趨勢")
        print("  - userId: \(userId)")
        print("  - albumId: \(albumId)")
        print("  - timeRange: \(timeRange)")
        
        guard isCloudKitAvailable, let db = database else {
            print("⚠️ CloudKit 不可用，使用本地快取")
            let trend = processAlbumCountTrendFromCache(albumId: albumId, userId: userId, timeRange: timeRange, since: sevenDaysAgo)
            completion(trend)
            return
        }
        
        fetchDailyAggregates(
            db: db,
            userId: userId,
            entityType: .album,
            entityId: albumId,
            timeRange: timeRange,
            since: sevenDaysAgo
        ) { aggregates in
            if !aggregates.isEmpty {
                let dataPoints = self.buildAggregateDataPoints(from: aggregates)
                let trend = AlbumCountTrend(albumId: albumId, albumName: "", dataPoints: dataPoints)
                completion(trend)
            } else {
                self.fetchAlbumCountTrendFromHistory(
                    db: db,
                    userId: userId,
                    albumId: albumId,
                    timeRange: timeRange,
                    fallbackTrackIds: fallbackTrackIds,
                    since: sevenDaysAgo,
                    completion: completion
                )
            }
        }
    }
    
    // MARK: - 查詢藝人數量趨勢
    /// 獲取藝人在過去時間內的歌曲數量趨勢
    func fetchArtistCountTrend(
        userId: String,
        artistId: String,
        timeRange: String,
        fallbackTrackIds: Set<String>? = nil,
        completion: @escaping (ArtistCountTrend?) -> Void
    ) {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        print("📊 [CloudKit] 查詢藝人數量趨勢")
        print("  - userId: \(userId)")
        print("  - artistId: \(artistId)")
        print("  - timeRange: \(timeRange)")
        
        guard isCloudKitAvailable, let db = database else {
            print("⚠️ CloudKit 不可用，使用本地快取")
            let trend = processArtistCountTrendFromCache(artistId: artistId, userId: userId, timeRange: timeRange, since: sevenDaysAgo)
            completion(trend)
            return
        }
        
        fetchDailyAggregates(
            db: db,
            userId: userId,
            entityType: .artist,
            entityId: artistId,
            timeRange: timeRange,
            since: sevenDaysAgo
        ) { aggregates in
            if !aggregates.isEmpty {
                let dataPoints = self.buildAggregateDataPoints(from: aggregates)
                let trend = ArtistCountTrend(artistId: artistId, artistName: "", dataPoints: dataPoints)
                completion(trend)
            } else {
                self.fetchArtistCountTrendFromHistory(
                    db: db,
                    userId: userId,
                    artistId: artistId,
                    timeRange: timeRange,
                    fallbackTrackIds: fallbackTrackIds,
                    since: sevenDaysAgo,
                    completion: completion
                )
            }
        }
    }
    
    // MARK: - 共用過濾工具（供測試與診斷使用）
    func filterAlbumHistories(_ histories: [RankingHistory], albumId: String, fallbackTrackIds: Set<String>?) -> [RankingHistory] {
        histories.filter { history in
            if let historyAlbumId = history.albumId, !historyAlbumId.isEmpty {
                return historyAlbumId == albumId
            }
            guard let fallbackTrackIds = fallbackTrackIds else { return false }
            return fallbackTrackIds.contains(history.trackId)
        }
    }
    
    func filterArtistHistories(_ histories: [RankingHistory], artistId: String, fallbackTrackIds: Set<String>?) -> [RankingHistory] {
        histories.filter { history in
            if let artistIdsString = history.artistIds, !artistIdsString.isEmpty {
                let artistIds = artistIdsString.split(separator: ",").map(String.init)
                return artistIds.contains(artistId)
            }
            guard let fallbackTrackIds = fallbackTrackIds else { return false }
            return fallbackTrackIds.contains(history.trackId)
        }
    }
    
    struct CloudKitDiagnosticsSnapshot {
        let syncStatus: CloudKitSyncStatus
        let totalEntries: Int
        let earliestDate: Date?
        let latestDate: Date?
        let distinctDays: Int
    }
    
    func diagnosticsSnapshot(userId: String, timeRange: String) -> CloudKitDiagnosticsSnapshot {
        let entries = localCache.filter { $0.userId == userId && $0.timeRange == timeRange }
        let earliest = entries.map(\.recordedDate).min()
        let latest = entries.map(\.recordedDate).max()
        let distinctDays = Set(entries.map { Calendar.current.startOfDay(for: $0.recordedDate) }).count
        return CloudKitDiagnosticsSnapshot(
            syncStatus: syncStatus,
            totalEntries: entries.count,
            earliestDate: earliest,
            latestDate: latest,
            distinctDays: distinctDays
        )
    }
    
    // MARK: - 處理專輯數量趨勢數據
    func processAlbumCountTrend(histories: [RankingHistory], albumId: String) -> AlbumCountTrend? {
        guard !histories.isEmpty else {
            print("⚠️ 沒有歷史數據")
            return nil
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 生成過去 7 天的日期
        let past7Days = (0...6).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: today)
        }.reversed()
        
        // 按日期分組
        let groupedByDay = Dictionary(grouping: histories) { history in
            calendar.startOfDay(for: history.recordedDate)
        }
        
        // 為每一天統計數量
        var dataPoints: [CountDataPoint] = []
        
        for date in past7Days {
            if let dayHistories = groupedByDay[date] {
                // 去重（同一天可能有多次快照）
                let uniqueTracks = Set(dayHistories.map { $0.trackId })
                let count = uniqueTracks.count
                
                dataPoints.append(CountDataPoint(
                    date: date,
                    count: count
                ))
                print("  - \(date): \(count) 首歌")
            } else {
                dataPoints.append(CountDataPoint(
                    date: date,
                    count: 0
                ))
                print("  - \(date): 0 首歌（無數據）")
            }
        }
        
        return AlbumCountTrend(
            albumId: albumId,
            albumName: "",  // 在 View 層設定
            dataPoints: dataPoints
        )
    }
    
    // MARK: - 處理藝人數量趨勢數據
    func processArtistCountTrend(histories: [RankingHistory], artistId: String) -> ArtistCountTrend? {
        guard !histories.isEmpty else {
            print("⚠️ 沒有歷史數據")
            return nil
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 生成過去 7 天的日期
        let past7Days = (0...6).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: today)
        }.reversed()
        
        // 按日期分組
        let groupedByDay = Dictionary(grouping: histories) { history in
            calendar.startOfDay(for: history.recordedDate)
        }
        
        // 為每一天統計數量
        var dataPoints: [CountDataPoint] = []
        
        for date in past7Days {
            if let dayHistories = groupedByDay[date] {
                // 去重（同一天可能有多次快照）
                let uniqueTracks = Set(dayHistories.map { $0.trackId })
                let count = uniqueTracks.count
                
                dataPoints.append(CountDataPoint(
                    date: date,
                    count: count
                ))
                print("  - \(date): \(count) 首歌")
            } else {
                dataPoints.append(CountDataPoint(
                    date: date,
                    count: 0
                ))
                print("  - \(date): 0 首歌（無數據）")
            }
        }
        
        return ArtistCountTrend(
            artistId: artistId,
            artistName: "",  // 在 View 層設定
            dataPoints: dataPoints
        )
    }
    
    // MARK: - 從本地快取處理專輯趨勢
    private func processAlbumCountTrendFromCache(albumId: String, userId: String, timeRange: String, since: Date) -> AlbumCountTrend? {
        let filtered = localCache.filter { history in
            history.userId == userId &&
            history.timeRange == timeRange &&
            history.recordedDate >= since &&
            history.albumId == albumId
        }
        
        guard !filtered.isEmpty else {
            return nil
        }
        
        return processAlbumCountTrend(histories: filtered, albumId: albumId)
    }
    
    private func fetchAlbumCountTrendFromHistory(
        db: CKDatabase?,
        userId: String,
        albumId: String,
        timeRange: String,
        fallbackTrackIds: Set<String>?,
        since: Date,
        completion: @escaping (AlbumCountTrend?) -> Void
    ) {
        guard let db = db else {
            let trend = processAlbumCountTrendFromCache(albumId: albumId, userId: userId, timeRange: timeRange, since: since)
            completion(trend)
            return
        }
        
        let userPredicate = NSPredicate(format: "userId == %@", userId)
        let timeRangePredicate = NSPredicate(format: "timeRange == %@", timeRange)
        let datePredicate = NSPredicate(format: "recordedDate >= %@", since as NSDate)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            userPredicate, timeRangePredicate, datePredicate
        ])
        
        let query = CKQuery(recordType: recordType, predicate: compoundPredicate)
        query.sortDescriptors = [NSSortDescriptor(key: "recordedDate", ascending: false)]
        
        print("☁️ 從 CloudKit 查詢專輯歷史數據 (fallback)...")
        
        var fetchedHistories: [RankingHistory] = []
        
        func finishWithHistories(_ histories: [RankingHistory]) {
            print("✅ 從 CloudKit 查詢到 \(histories.count) 筆歷史記錄（含所有分頁）")
            
            let recordsWithAlbumId = histories.filter { $0.albumId != nil && !$0.albumId!.isEmpty }
            print("📋 其中 \(recordsWithAlbumId.count) 筆記錄包含 albumId")
            if let latest = histories.sorted(by: { $0.recordedDate > $1.recordedDate }).first {
                print("📅 最新記錄日期: \(latest.recordedDate), albumId: \(latest.albumId ?? "nil")")
            }
            
            let albumHistories = self.filterAlbumHistories(histories, albumId: albumId, fallbackTrackIds: fallbackTrackIds)
            print("📊 其中 \(albumHistories.count) 筆屬於該專輯（含 fallback track IDs）")
            
            let trend = self.processAlbumCountTrend(histories: albumHistories, albumId: albumId)
            
            DispatchQueue.main.async {
                completion(trend)
            }
        }
        
        func fetchPage(cursor: CKQueryOperation.Cursor? = nil) {
            let operation: CKQueryOperation
            if let cursor = cursor {
                operation = CKQueryOperation(cursor: cursor)
            } else {
                operation = CKQueryOperation(query: query)
            }
            
            operation.resultsLimit = 400
            operation.desiredKeys = ["trackId", "recordedDate", "albumId", "timeRange", "userId"]
            
            operation.recordMatchedBlock = { _, recordResult in
                switch recordResult {
                case .success(let record):
                    if let history = self.convertToRankingHistory(record: record) {
                        fetchedHistories.append(history)
                    }
                case .failure(let error):
                    print("❌ 解析記錄失敗: \(error.localizedDescription)")
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success(let cursor):
                    if let cursor = cursor {
                        print("📄 已取得 \(fetchedHistories.count) 筆資料，繼續下一頁…")
                        fetchPage(cursor: cursor)
                    } else {
                        finishWithHistories(fetchedHistories)
                    }
                case .failure(let error):
                    print("❌ CloudKit 查詢失敗: \(error.localizedDescription)")
                    let trend = self.processAlbumCountTrendFromCache(albumId: albumId, userId: userId, timeRange: timeRange, since: since)
                    DispatchQueue.main.async {
                        completion(trend)
                    }
                }
            }
            
            db.add(operation)
        }
        
        fetchPage()
    }
    
    // MARK: - 從本地快取處理藝人趨勢
    private func processArtistCountTrendFromCache(artistId: String, userId: String, timeRange: String, since: Date) -> ArtistCountTrend? {
        let filtered = localCache.filter { history in
            guard history.userId == userId &&
                  history.timeRange == timeRange &&
                  history.recordedDate >= since,
                  let artistIds = history.artistIds else {
                return false
            }
            return artistIds.split(separator: ",").map(String.init).contains(artistId)
        }
        
        guard !filtered.isEmpty else {
            return nil
        }
        
        return processArtistCountTrend(histories: filtered, artistId: artistId)
    }
    
    private func fetchArtistCountTrendFromHistory(
        db: CKDatabase?,
        userId: String,
        artistId: String,
        timeRange: String,
        fallbackTrackIds: Set<String>?,
        since: Date,
        completion: @escaping (ArtistCountTrend?) -> Void
    ) {
        guard let db = db else {
            let trend = processArtistCountTrendFromCache(artistId: artistId, userId: userId, timeRange: timeRange, since: since)
            completion(trend)
            return
        }
        
        let userPredicate = NSPredicate(format: "userId == %@", userId)
        let timeRangePredicate = NSPredicate(format: "timeRange == %@", timeRange)
        let datePredicate = NSPredicate(format: "recordedDate >= %@", since as NSDate)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            userPredicate, timeRangePredicate, datePredicate
        ])
        
        let query = CKQuery(recordType: recordType, predicate: compoundPredicate)
        query.sortDescriptors = [NSSortDescriptor(key: "recordedDate", ascending: false)]
        
        print("☁️ 從 CloudKit 查詢藝人歷史數據 (fallback)...")
        
        var fetchedHistories: [RankingHistory] = []
        
        func finishWithHistories(_ histories: [RankingHistory]) {
            print("✅ 從 CloudKit 查詢到 \(histories.count) 筆歷史記錄（含所有分頁）")
            
            let artistHistories = self.filterArtistHistories(histories, artistId: artistId, fallbackTrackIds: fallbackTrackIds)
            print("📊 其中 \(artistHistories.count) 筆包含該藝人（含 fallback track IDs）")
            
            let trend = self.processArtistCountTrend(histories: artistHistories, artistId: artistId)
            
            DispatchQueue.main.async {
                completion(trend)
            }
        }
        
        func fetchPage(cursor: CKQueryOperation.Cursor? = nil) {
            let operation: CKQueryOperation
            if let cursor = cursor {
                operation = CKQueryOperation(cursor: cursor)
            } else {
                operation = CKQueryOperation(query: query)
            }
            
            operation.resultsLimit = 400
            operation.desiredKeys = ["trackId", "recordedDate", "artistIds", "timeRange", "userId"]
            
            operation.recordMatchedBlock = { _, recordResult in
                switch recordResult {
                case .success(let record):
                    if let history = self.convertToRankingHistory(record: record) {
                        fetchedHistories.append(history)
                    }
                case .failure(let error):
                    print("❌ 解析記錄失敗: \(error.localizedDescription)")
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success(let cursor):
                    if let cursor = cursor {
                        print("📄 已取得 \(fetchedHistories.count) 筆資料，繼續下一頁…")
                        fetchPage(cursor: cursor)
                    } else {
                        finishWithHistories(fetchedHistories)
                    }
                case .failure(let error):
                    print("❌ CloudKit 查詢失敗: \(error.localizedDescription)")
                    let trend = self.processArtistCountTrendFromCache(artistId: artistId, userId: userId, timeRange: timeRange, since: since)
                    DispatchQueue.main.async {
                        completion(trend)
                    }
                }
            }
            
            db.add(operation)
        }
        
        fetchPage()
    }
}
