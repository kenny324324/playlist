//
//  DemoModeManager.swift
//  MyPlaylist
//
//  Demo 模式管理器 - 用於 App Store 審核
//

import Foundation
import Combine

class DemoModeManager: ObservableObject {
    static let shared = DemoModeManager()
    
    // 是否啟用 Demo 模式
    @Published var isDemoMode: Bool = false
    
    // Demo 用戶資料
    @Published var demoAccessToken: String = "demo_access_token_for_review"
    
    private init() {
        // 初始化時 Demo 模式預設關閉
        self.isDemoMode = false
    }
    
    // MARK: - Demo 模式控制
    
    /// 啟用 Demo 模式
    func enableDemoMode() {
        print("✅ Demo 模式已啟用")
        isDemoMode = true
    }
    
    /// 關閉 Demo 模式
    func disableDemoMode() {
        print("❌ Demo 模式已關閉")
        isDemoMode = false
    }
    
    // MARK: - 條件編譯檢查
    
    /// 檢查是否為審核版本（編譯時決定）
    var isReviewBuild: Bool {
        #if APPSTORE_REVIEW
        return true
        #else
        return false
        #endif
    }
    
    /// 檢查 Demo 按鈕是否應該顯示（僅在審核版本中顯示）
    var shouldShowDemoButton: Bool {
        return isReviewBuild
    }
}

