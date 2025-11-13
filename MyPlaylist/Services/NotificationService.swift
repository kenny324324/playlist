import Foundation
import UserNotifications
import SwiftUI

/// 通知服務管理器
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // 通知識別符
    private let dailyReminderIdentifier = "daily_stats_reminder"
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - 權限管理
    
    /// 檢查通知授權狀態
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
                print("📱 通知授權狀態: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    /// 請求通知權限
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                
                if let error = error {
                    print("❌ 請求通知權限失敗: \(error.localizedDescription)")
                } else if granted {
                    print("✅ 通知權限已授予")
                } else {
                    print("⚠️ 用戶拒絕了通知權限")
                }
                
                self.checkAuthorizationStatus()
                completion(granted)
            }
        }
    }
    
    // MARK: - 每日提醒通知
    
    /// 設定每日提醒通知
    /// - Parameters:
    ///   - hour: 小時 (0-23)
    ///   - minute: 分鐘 (0-59)
    ///   - enabled: 是否啟用
    func scheduleDailyReminder(hour: Int, minute: Int, enabled: Bool) {
        // 先移除舊的通知
        cancelDailyReminder()
        
        guard enabled, isAuthorized else {
            print("⚠️ 通知未啟用或未授權")
            return
        }
        
        // 建立通知內容
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.daily.title")
        content.body = String(localized: "notification.daily.body")
        content.sound = .default
        content.badge = 1
        
        // 設定觸發時間（每天的指定時間）
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 建立請求
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        // 加入通知中心
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ 排程每日通知失敗: \(error.localizedDescription)")
            } else {
                print("✅ 已排程每日通知：\(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    /// 取消每日提醒通知
    func cancelDailyReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
        print("🗑️ 已取消每日通知")
    }
    
    /// 檢查是否已排程每日通知
    func checkDailyReminderStatus(completion: @escaping (Bool, Date?) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            let dailyReminder = requests.first { $0.identifier == self.dailyReminderIdentifier }
            
            if let trigger = dailyReminder?.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                DispatchQueue.main.async {
                    completion(true, nextTriggerDate)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, nil)
                }
            }
        }
    }
    
    // MARK: - 即時通知（測試用）
    
    /// 發送測試通知（立即）
    func sendTestNotification() {
        guard isAuthorized else {
            print("⚠️ 通知未授權，無法發送測試通知")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.test.title")
        content.body = String(localized: "notification.test.body")
        content.sound = .default
        
        // 5 秒後觸發
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ 發送測試通知失敗: \(error.localizedDescription)")
            } else {
                print("✅ 測試通知將在 5 秒後發送")
            }
        }
    }
    
    // MARK: - 清除角標
    
    /// 清除 App 角標數字
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("❌ 清除角標失敗: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 開啟系統設定
    
    /// 開啟系統通知設定頁面
    func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 授權狀態擴充
extension UNAuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined:
            return String(localized: "notification.status.notDetermined")
        case .denied:
            return String(localized: "notification.status.denied")
        case .authorized:
            return String(localized: "notification.status.authorized")
        case .provisional:
            return String(localized: "notification.status.provisional")
        case .ephemeral:
            return String(localized: "notification.status.ephemeral")
        @unknown default:
            return String(localized: "notification.status.unknown")
        }
    }
}

