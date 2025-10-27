import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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
        // 使用 SpotifyAuthService 確保 token 有效
        SpotifyAuthService.ensureValidAccessToken { accessToken in
            if let token = accessToken {
                print("Token 有效: \(token)")
                // 可以在這裡繼續應用的邏輯，例如載入主畫面
            } else {
                print("Token 無效或過期，需要重新授權")
                // 在這裡可以顯示登入畫面或提示用戶重新授權
            }
        }
    }
}
