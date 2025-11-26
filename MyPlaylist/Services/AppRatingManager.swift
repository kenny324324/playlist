//
//  AppRatingManager.swift
//  MyPlaylist
//
//  Created by Kenny's Macbook on 2024/11/26.
//

import SwiftUI
import StoreKit

/// App 評分管理器
/// 負責管理應用程式評分請求的時機與邏輯
class AppRatingManager {
    static let shared = AppRatingManager()
    
    private init() {}
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let appLaunchCount = "appLaunchCount"
        static let lastRatingRequestDate = "lastRatingRequestDate"
        static let userHasRatedApp = "userHasRatedApp"
        static let significantEventCount = "significantEventCount"
    }
    
    // MARK: - 評分條件參數
    private enum Criteria {
        static let minimumLaunchCount = 5           // 至少啟動 5 次
        static let minimumDaysSinceLastRequest = 30 // 距離上次請求至少 30 天
        static let significantEventThreshold = 10   // 顯著事件達到 10 次
    }
    
    // MARK: - Public Methods
    
    /// 記錄 App 啟動
    func recordAppLaunch() {
        incrementLaunchCount()
    }
    
    /// 記錄顯著事件（例如：查看歌曲詳情、分享內容等）
    func recordSignificantEvent() {
        incrementSignificantEventCount()
        checkAndRequestReviewIfAppropriate()
    }
    
    /// 手動請求評分（從設定頁面觸發）
    func requestReview() {
        print("⭐️ [AppRating] 用戶點擊評分按鈕")
        
        // 記錄用戶主動評分
        markUserHasRated()
        
        // 請求評分
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            print("✅ [AppRating] 正在請求顯示評分對話框...")
            SKStoreReviewController.requestReview(in: scene)
            print("📱 [AppRating] requestReview() 已呼叫")
            
            #if DEBUG
            print("⚠️ [AppRating] 注意：在 TestFlight 或開發版本中，評分對話框可能不會顯示")
            #endif
        } else {
            print("❌ [AppRating] 無法取得 UIWindowScene")
        }
    }
    
    /// 開啟 App Store 評分頁面（手動評分）
    func openAppStoreRating() {
        // 獲取 App ID（需要替換成實際的 App Store ID）
        guard let appStoreURL = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID?action=write-review") else {
            return
        }
        
        UIApplication.shared.open(appStoreURL)
    }
    
    /// 檢查是否應該顯示評分請求
    func checkAndRequestReviewIfAppropriate() {
        guard shouldRequestReview() else { return }
        
        // 更新最後請求日期
        updateLastRequestDate()
        
        // 請求評分
        requestReview()
    }
    
    /// 重置評分狀態（用於測試）
    #if DEBUG
    func resetRatingStatus() {
        UserDefaults.standard.removeObject(forKey: Keys.appLaunchCount)
        UserDefaults.standard.removeObject(forKey: Keys.lastRatingRequestDate)
        UserDefaults.standard.removeObject(forKey: Keys.userHasRatedApp)
        UserDefaults.standard.removeObject(forKey: Keys.significantEventCount)
        print("✅ 已重置評分狀態")
    }
    
    /// 獲取當前統計資訊（用於調試）
    func getStatistics() -> [String: Any] {
        return [
            "啟動次數": getLaunchCount(),
            "顯著事件次數": getSignificantEventCount(),
            "已評分": hasUserRated(),
            "上次請求日期": getLastRequestDate() ?? "從未",
            "距離上次請求天數": daysSinceLastRequest()
        ]
    }
    #endif
    
    // MARK: - Private Helper Methods
    
    /// 判斷是否應該請求評分
    private func shouldRequestReview() -> Bool {
        // 1. 如果用戶已經評分過，不再請求
        if hasUserRated() {
            return false
        }
        
        // 2. 檢查啟動次數
        let launchCount = getLaunchCount()
        guard launchCount >= Criteria.minimumLaunchCount else {
            return false
        }
        
        // 3. 檢查顯著事件次數
        let eventCount = getSignificantEventCount()
        guard eventCount >= Criteria.significantEventThreshold else {
            return false
        }
        
        // 4. 檢查距離上次請求的時間間隔
        let daysSinceLastRequest = daysSinceLastRequest()
        if daysSinceLastRequest < Criteria.minimumDaysSinceLastRequest {
            return false
        }
        
        return true
    }
    
    /// 獲取啟動次數
    private func getLaunchCount() -> Int {
        return UserDefaults.standard.integer(forKey: Keys.appLaunchCount)
    }
    
    /// 增加啟動次數
    private func incrementLaunchCount() {
        let currentCount = getLaunchCount()
        UserDefaults.standard.set(currentCount + 1, forKey: Keys.appLaunchCount)
        
        print("📱 App 啟動次數: \(currentCount + 1)")
    }
    
    /// 獲取顯著事件次數
    private func getSignificantEventCount() -> Int {
        return UserDefaults.standard.integer(forKey: Keys.significantEventCount)
    }
    
    /// 增加顯著事件次數
    private func incrementSignificantEventCount() {
        let currentCount = getSignificantEventCount()
        UserDefaults.standard.set(currentCount + 1, forKey: Keys.significantEventCount)
        
        print("⭐️ 顯著事件次數: \(currentCount + 1)")
    }
    
    /// 獲取上次請求日期
    private func getLastRequestDate() -> Date? {
        return UserDefaults.standard.object(forKey: Keys.lastRatingRequestDate) as? Date
    }
    
    /// 更新最後請求日期
    private func updateLastRequestDate() {
        UserDefaults.standard.set(Date(), forKey: Keys.lastRatingRequestDate)
    }
    
    /// 計算距離上次請求的天數
    private func daysSinceLastRequest() -> Int {
        guard let lastRequestDate = getLastRequestDate() else {
            return Int.max // 如果從未請求過，返回最大值
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastRequestDate, to: Date())
        return components.day ?? 0
    }
    
    /// 檢查用戶是否已評分
    private func hasUserRated() -> Bool {
        return UserDefaults.standard.bool(forKey: Keys.userHasRatedApp)
    }
    
    /// 標記用戶已評分
    private func markUserHasRated() {
        UserDefaults.standard.set(true, forKey: Keys.userHasRatedApp)
    }
}

// MARK: - Significant Events
extension AppRatingManager {
    /// 預定義的顯著事件類型
    enum SignificantEvent {
        case viewedTrackDetail      // 查看歌曲詳情
        case viewedArtistDetail     // 查看藝人詳情
        case viewedAlbumDetail      // 查看專輯詳情
        case sharedContent          // 分享內容
        case viewedDashboard        // 查看儀表板
        case viewedStats            // 查看統計資料
        case changedTheme           // 更改主題
        case enabledNotification    // 啟用通知
    }
    
    /// 記錄特定類型的顯著事件
    func recordEvent(_ event: SignificantEvent) {
        recordSignificantEvent()
        
        #if DEBUG
        print("🎯 記錄事件: \(event)")
        #endif
    }
}

