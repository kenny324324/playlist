import SwiftUI

struct LoginView: View {
    let login: () -> Void
    let enterDemoMode: (() -> Void)?
    
    // 隱藏的 Demo 入口計數器（完全隱藏，無視覺提示）
    @State private var logoTapCount: Int = 0
    @State private var lastTapTime: Date = Date()
    
    init(login: @escaping () -> Void, enterDemoMode: (() -> Void)? = nil) {
        self.login = login
        self.enterDemoMode = enterDemoMode
    }

    var body: some View {
        VStack {
            Spacer()
            
            // Logo 區域 - 隱藏的 Demo 入口（快速點擊 5 次，無視覺提示）
            VStack(spacing: 20) {
                Image("AppIconImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .onTapGesture {
                        handleLogoTap()
                    }
                
                Text("spo.stats")
                    .font(.appFont(size: 42, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 60)
            
            Spacer()
            
            // Spotify 登入按鈕
            Button(action: login) {
                HStack {
                    Image("spotify-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                    
                    Text("login.button")
                        .font(.appFont(size: 20, weight: .medium))
                }
                .foregroundColor(Color.spotifyText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.spotifyGreen)
                .cornerRadius(50)
            }
            .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 50)
        }
        .background(Color.spotifyText.ignoresSafeArea())
    }
    
    // MARK: - 隱藏的 Demo 入口邏輯
    
    /// 處理 Logo 點擊 - 快速點擊 5 次進入 Demo Mode（完全隱藏，無視覺提示）
    private func handleLogoTap() {
        let now = Date()
        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)
        
        // 如果距離上次點擊超過 2 秒，重置計數器
        if timeSinceLastTap > 2.0 {
            logoTapCount = 0
        }
        
        lastTapTime = now
        logoTapCount += 1
        
        // 達到 5 次點擊，進入 Demo Mode
        if logoTapCount >= 5 {
            triggerDemoMode()
        }
    }
    
    /// 觸發 Demo Mode
    private func triggerDemoMode() {
        // 震動反饋
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // 重置計數器
        logoTapCount = 0
        
        // 執行 Demo Mode
        enterDemoMode?()
        
        print("🎭 隱藏入口已觸發 - 進入 Demo Mode")
    }
}

#Preview {
    LoginView(login: {})
        .preferredColorScheme(.dark)
}
