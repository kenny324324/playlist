//
//  DebugHelper.swift
//  MyPlaylist
//
//  用於檢查編譯標誌是否正確設定
//

import Foundation

class DebugHelper {
    static func checkCompilationFlags() {
        #if APPSTORE_REVIEW
        print("✅ APPSTORE_REVIEW flag 已啟用 - Demo 模式應該可用")
        #else
        print("❌ APPSTORE_REVIEW flag 未啟用 - Demo 按鈕不會顯示")
        #endif
        
        #if DEBUG
        print("ℹ️ 這是 Debug 建置")
        #else
        print("ℹ️ 這是 Release 建置")
        #endif
    }
}


