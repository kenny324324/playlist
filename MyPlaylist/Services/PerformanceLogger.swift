import Foundation

// MARK: - 性能日誌系統
/// 提供清晰的 Console 輸出，方便測試和除錯

class PerformanceLogger {
    static let shared = PerformanceLogger()
    
    private init() {}
    
    // MARK: - 快取相關日誌
    
    func logCacheHit(type: String, source: String = "記憶體") {
        print("✅ [快取命中] \(type) - 從\(source)載入")
        print("   ⏱️ 載入時間: ~0.1 秒")
        print("   💾 節省網路請求: 1 次")
        printSeparator()
    }
    
    func logCacheMiss(type: String) {
        print("❌ [快取未命中] \(type) - 快取不存在或已過期")
        print("   🌐 開始 API 請求...")
        printSeparator()
    }
    
    func logForceRefresh(type: String) {
        print("🔄 [強制刷新] \(type)")
        print("   ⚠️ 忽略所有快取")
        print("   🌐 從 API 獲取最新資料")
        printSeparator()
    }
    
    func logCacheSave(type: String, count: Int) {
        print("💾 [儲存快取] \(type)")
        print("   📊 項目數量: \(count)")
        print("   ⏰ 有效期: 5 分鐘")
        printSeparator()
    }
    
    // MARK: - 圖片相關日誌
    
    func logImageCacheHit(url: String, source: String) {
        let shortUrl = url.components(separatedBy: "/").last ?? "unknown"
        print("🖼️ [圖片快取命中] \(shortUrl)")
        print("   📍 來源: \(source)")
    }
    
    func logImageCacheMiss(url: String) {
        let shortUrl = url.components(separatedBy: "/").last ?? "unknown"
        print("🌐 [圖片下載] \(shortUrl)")
    }
    
    func logImagePreload(count: Int) {
        print("⚡ [圖片預載] 開始預載 \(count) 張圖片")
        print("   🎯 背景處理，不影響主執行緒")
        printSeparator()
    }
    
    func logImageCacheCleaned(count: Int) {
        print("🧹 [清理快取] 已清除 \(count) 個過期圖片")
        print("   📅 清理條件: 超過 7 天未使用")
        printSeparator()
    }
    
    // MARK: - API 請求日誌
    
    func logAPIRequest(endpoint: String, params: [String: String] = [:]) {
        print("🌐 [API 請求] \(endpoint)")
        if !params.isEmpty {
            print("   📋 參數: \(params)")
        }
        print("   ⏳ 請求中...")
    }
    
    func logAPISuccess(endpoint: String, duration: TimeInterval, itemCount: Int? = nil) {
        print("✅ [API 成功] \(endpoint)")
        print("   ⏱️ 耗時: \(String(format: "%.2f", duration)) 秒")
        if let count = itemCount {
            print("   📊 獲取 \(count) 個項目")
        }
        printSeparator()
    }
    
    func logAPIError(endpoint: String, error: String) {
        print("❌ [API 錯誤] \(endpoint)")
        print("   🚨 錯誤: \(error)")
        printSeparator()
    }
    
    // MARK: - 性能指標日誌
    
    func logPerformanceMetric(action: String, duration: TimeInterval) {
        print("📊 [性能指標] \(action)")
        print("   ⏱️ 耗時: \(String(format: "%.3f", duration)) 秒")
        
        // 性能評級
        let rating: String
        if duration < 0.1 {
            rating = "⚡ 極快"
        } else if duration < 0.5 {
            rating = "✅ 快速"
        } else if duration < 1.0 {
            rating = "⚠️ 一般"
        } else {
            rating = "🐌 較慢"
        }
        print("   🎯 評級: \(rating)")
        printSeparator()
    }
    
    // MARK: - 記憶體相關日誌
    
    func logMemoryWarning() {
        print("⚠️ [記憶體警告] 系統記憶體不足")
        print("   🧹 開始清理快取...")
        print("   💾 釋放記憶體中")
        printSeparator()
    }
    
    func logMemoryUsage(mb: Double) {
        print("💾 [記憶體使用] \(String(format: "%.1f", mb)) MB")
        let status = mb < 80 ? "✅ 正常" : mb < 120 ? "⚠️ 偏高" : "🚨 過高"
        print("   🎯 狀態: \(status)")
        printSeparator()
    }
    
    // MARK: - 用戶操作日誌
    
    func logUserAction(action: String, details: String = "") {
        print("👤 [用戶操作] \(action)")
        if !details.isEmpty {
            print("   📝 詳情: \(details)")
        }
        printSeparator()
    }
    
    // MARK: - 測試相關日誌
    
    func logTestStart(testName: String) {
        printDoubleSeparator()
        print("🧪 [測試開始] \(testName)")
        print("   📅 時間: \(currentTimeString())")
        printSeparator()
    }
    
    func logTestEnd(testName: String, success: Bool) {
        printSeparator()
        let icon = success ? "✅" : "❌"
        print("\(icon) [測試結束] \(testName)")
        print("   結果: \(success ? "通過" : "失敗")")
        printDoubleSeparator()
    }
    
    func logTestStep(step: String) {
        print("📍 [測試步驟] \(step)")
    }
    
    // MARK: - 快取統計日誌
    
    func logCacheStats(imageCache: String, apiCacheCount: Int) {
        print("📊 [快取統計]")
        print("   🖼️ 圖片快取: \(imageCache)")
        print("   📦 API 快取: \(apiCacheCount) 個項目")
        printSeparator()
    }
    
    // MARK: - 啟動日誌
    
    func logAppLaunch() {
        printDoubleSeparator()
        print("🚀 [App 啟動] MyPlaylist")
        print("   📅 時間: \(currentTimeString())")
        print("   📱 平台: iOS")
        printDoubleSeparator()
    }
    
    // MARK: - 工具方法
    
    private func printSeparator() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    private func printDoubleSeparator() {
        print("════════════════════════════════════════")
    }
    
    private func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    // MARK: - 快速日誌方法（簡化版）
    
    func log(_ message: String, icon: String = "ℹ️") {
        print("\(icon) \(message)")
    }
    
    func success(_ message: String) {
        log(message, icon: "✅")
    }
    
    func error(_ message: String) {
        log(message, icon: "❌")
    }
    
    func warning(_ message: String) {
        log(message, icon: "⚠️")
    }
    
    func info(_ message: String) {
        log(message, icon: "ℹ️")
    }
}

// MARK: - 全域簡寫
let logger = PerformanceLogger.shared

