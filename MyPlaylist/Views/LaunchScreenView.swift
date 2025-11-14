import SwiftUI

struct LaunchScreenView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isAnimating = false
    @State private var loadingProgress: Double = 0.0
    @State private var loadingText: LocalizedStringKey = "launch.loading.checking"
    @State private var shouldPreloadData: Bool = true
    @State private var showWelcomeText: Bool = false
    
    var onLoadingComplete: () -> Void
    var checkLoginAndPreload: (() -> Void)? = nil
    var userName: String? = nil
    var isLoggedIn: Bool = false
    
    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.spotifyText,
                    Color.spotifyText.opacity(0.95),
                    Color(red: 0.08, green: 0.08, blue: 0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // 中間區域：App 名稱 + 波紋動畫
                VStack(spacing: 30) {
                    // App 名稱（動態取得）
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "spo.stats")
                        .font(.custom("SpotifyMix-Bold", size: 42))
                        .foregroundColor(.white)
                        .shadow(color: themeManager.themeColor.opacity(0.3), radius: 10)
                    
                    // 載入動畫 - 三個跳動的條（波紋）
                    HStack(spacing: 10) {
                        ForEach(0..<3) { index in
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            themeManager.themeColor,
                                            themeManager.themeColor.opacity(0.7)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 10, height: 35)
                                .scaleEffect(y: isAnimating ? 1.0 : 0.4)
                                .animation(
                                    Animation
                                        .easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                                .shadow(color: themeManager.themeColor.opacity(0.5), radius: 5)
                        }
                    }
                }
                
                Spacer()
                
                // 底部區域：載入文字 / 歡迎文字 + 進度條
                VStack(spacing: 16) {
                    // 文字區域（固定寬度避免跳動）
                    Group {
                        if showWelcomeText {
                            // 歡迎文字（主題色 + 光暈）
                            if isLoggedIn, let userName = userName {
                                Text("\(userName)" + String(localized: "launch.welcome.ready"))
                                    .font(.custom("SpotifyMix-Bold", size: 18))
                                    .foregroundColor(themeManager.themeColor)
                                    .multilineTextAlignment(.center)
                                    .shadow(color: themeManager.themeColor.opacity(0.6), radius: 10)
                                    .shadow(color: themeManager.themeColor.opacity(0.3), radius: 20)
                                    .transition(.opacity)
                            } else {
                                Text("launch.welcome.pleaseLogin")
                                    .font(.custom("SpotifyMix-Bold", size: 18))
                                    .foregroundColor(themeManager.themeColor)
                                    .multilineTextAlignment(.center)
                                    .shadow(color: themeManager.themeColor.opacity(0.6), radius: 10)
                                    .shadow(color: themeManager.themeColor.opacity(0.3), radius: 20)
                                    .transition(.opacity)
                            }
                        } else {
                            // 載入文字（放大、變粗）
                            Text(loadingText)
                                .font(.custom("SpotifyMix-Bold", size: 18))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: loadingText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    
                    // 進度條
                    ProgressView(value: loadingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: themeManager.themeColor))
                        .frame(width: 200)
                        .scaleEffect(y: 1.5, anchor: .center)  // 讓進度條粗 1.5 倍
                        .opacity(showWelcomeText ? 0 : 0.8)
                }
                .padding(.bottom, 60)
            }
            .padding()
        }
        .onAppear {
            startLoading()
        }
    }
    
    // MARK: - 載入流程
    private func startLoading() {
        isAnimating = true
        
        // 步驟 1: 檢查帳號狀態
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loadingText = "launch.loading.checking"
            withAnimation(.linear(duration: 0.7)) {
                loadingProgress = 0.2
            }
            
            // 在背景執行登入檢查
            if let preload = checkLoginAndPreload {
                preload()
            }
        }
        
        // 步驟 2: 載入音樂資料
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            loadingText = "launch.loading.data"
            withAnimation(.linear(duration: 0.5)) {
                loadingProgress = 0.6
            }
        }
        
        // 步驟 3: 準備完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            loadingText = "launch.loading.ready"
            withAnimation(.linear(duration: 0.3)) {
                loadingProgress = 0.9
            }
        }
        
        // 步驟 4: 顯示歡迎文字（最少顯示 1 秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.linear(duration: 0.2)) {
                loadingProgress = 1.0
            }
            
            // 切換到歡迎文字
            withAnimation(.easeInOut(duration: 0.3)) {
                showWelcomeText = true
            }
        }
        
        // 完成載入（最少顯示 1 秒歡迎文字）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                onLoadingComplete()
            }
        }
    }
}

#Preview {
    LaunchScreenView(onLoadingComplete: {})
        .preferredColorScheme(.dark)
}

