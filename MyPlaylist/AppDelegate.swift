import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 🔥 先檢查並清除舊版本的 Token（一次性遷移）
        migrateTokenStorageIfNeeded()
        
        // 確保 token 有效
        ensureTokenValidity()
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            return .portrait // 僅允許豎屏
        }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("Received callback URL: \(url)")  // Debug
        NotificationCenter.default.post(name: .spotifyCallback, object: url)
        return true
    }

    private func ensureTokenValidity() {
        // 使用 SpotifyAuthServiceV2 確保 token 有效
        SpotifyAuthServiceV2.ensureValidAccessToken { accessToken in
            if let token = accessToken {
                print("Token 有效: \(token)")
                // 可以在這裡繼續應用的邏輯，例如載入主畫面
            } else {
                print("Token 無效或過期，需要重新授權")
                // 在這裡可以顯示登入畫面或提示用戶重新授權
            }
        }
    }
    
    /// 一次性遷移：清除舊版本儲存的 Token（不會在 App 刪除時清除的版本）
    private func migrateTokenStorageIfNeeded() {
        let migrationKey = "TokenStorageMigrated_v2"
        
        // 檢查是否已經遷移過
        if UserDefaults.standard.bool(forKey: migrationKey) {
            print("✅ Token storage 已經是新版本，無需遷移")
            return
        }
        
        // 清除所有舊的 Token
        print("🔄 檢測到舊版本 Token，正在清除...")
        TokenStorage.clearAll()
        print("✅ 舊 Token 已清除，下次登入將使用新的安全設定")
        
        // 標記為已遷移
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
