import SwiftUI

struct LaunchScreenView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isAnimating = false
    @State private var loadingProgress: Double = 0.0
    @State private var loadingText: LocalizedStringKey = "launch.loading.checking"
    @State private var shouldPreloadData: Bool = true
    
    var onLoadingComplete: () -> Void
    var checkLoginAndPreload: (() -> Void)? = nil
    
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
                    // App 名稱
                    Text("SpoStats")
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
                
                // 底部區域：載入文字 + 進度條
                VStack(spacing: 16) {
                    // 載入文字（放大、變粗）
                    Text(loadingText)
                        .font(.custom("SpotifyMix-Bold", size: 18))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: loadingText)
                    
                    // 進度條
                    ProgressView(value: loadingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: themeManager.themeColor))
                        .frame(width: 200)
                        .scaleEffect(y: 1.5, anchor: .center)  // 讓進度條粗 1.5 倍
                        .opacity(0.8)
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
        
        // 完成載入（最少顯示 2 秒保證使用者看到品牌）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.linear(duration: 0.2)) {
                loadingProgress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    onLoadingComplete()
                }
            }
        }
    }
}

#Preview {
    LaunchScreenView(onLoadingComplete: {})
        .preferredColorScheme(.dark)
}

