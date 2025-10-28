import SwiftUI

extension Color {
    static let spotifyGreen = Color(red: 0.11, green: 0.84, blue: 0.38)
    static let spotifyText = Color(red: 0.07, green: 0.07, blue: 0.07)
}

struct ContentView: View {
    @State private var accessToken: String? = nil
    @State private var isLoggedIn = false  // 控制登入狀態
    @State private var tracks: [Track] = []
    @State private var userProfile: SpotifyUser? = nil
    @ObservedObject var audioPlayer = AudioPlayer()

    // 確保畫面在狀態變化時強制更新
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            Color.spotifyText.ignoresSafeArea()

            if isLoggedIn {
                TabView {
                    HomeView(
                        audioPlayer: audioPlayer,
                        accessToken: accessToken ?? "",
                        userProfile: userProfile,
                        logout: logout
                    )
                    .tabItem {
                        Label("首頁", systemImage: "house.fill")
                    }
                    
                    TopView(
                        audioPlayer: audioPlayer,
                        userProfile: userProfile,
                        logout: logout,
                        accessToken: accessToken ?? ""
                    )
                    .tabItem {
                        Label("排行榜", systemImage: "chart.bar.fill")
                    }
                    
                    SettingsView()
                    .tabItem {
                        Label("設定", systemImage: "gearshape.fill")
                    }
                }
                .accentColor(Color.white)  // 設置 Tab 的主題色
            } else {
                LoginView(login: login)  // 顯示登入畫面
            }
        }
        .onOpenURL { url in
            handleSpotifyCallback(url: url)  // 監聽 Spotify 回調 URL
        }
        .onAppear {
            checkIfLoggedIn()  // 每次顯示時檢查登入狀態
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                checkIfLoggedIn()  // App 從背景返回時檢查登入狀態
            }
        }
    }

    // Spotify 登入流程
    func login() {
        guard let url = URL(string: SpotifyAuthService.loginURLString()) else { return }
        UIApplication.shared.open(url)
    }

    // 登出流程
    func logout() {
        UserDefaults.standard.removeObject(forKey: "access_token")
        self.accessToken = nil
        self.isLoggedIn = false
    }

    // Spotify 回調處理
    func handleSpotifyCallback(url: URL) {
        guard let code = extractCode(from: url) else { return }

        SpotifyAuthService.fetchAccessToken(code: code) { token in
            DispatchQueue.main.async {
                if let token = token {
                    // 儲存 token 並更新狀態
                    UserDefaults.standard.set(token, forKey: "access_token")
                    self.accessToken = token
                    self.isLoggedIn = true  // 更新登入狀態
                    fetchUserProfile(token: token)
                    fetchTopTracks(token: token, timeRange: .shortTerm)
                }
            }
        }
    }

    // 檢查是否已登入
    func checkIfLoggedIn() {
        if let token = UserDefaults.standard.string(forKey: "access_token") {
            self.accessToken = token
            self.isLoggedIn = true
            fetchUserProfile(token: token)
            fetchTopTracks(token: token, timeRange: .shortTerm)
        } else {
            SpotifyAuthService.refreshAccessToken { newToken in
                if let newToken = newToken {
                    DispatchQueue.main.async {
                        self.accessToken = newToken
                        self.isLoggedIn = true
                        UserDefaults.standard.set(newToken, forKey: "access_token")
                        fetchUserProfile(token: newToken)
                        fetchTopTracks(token: newToken, timeRange: .shortTerm)
                    }
                } else {
                    print("需要重新登入")
                }
            }
        }
    }

    // 取得使用者資料
    func fetchUserProfile(token: String) {
        SpotifyAPIService.fetchCurrentUserProfile(accessToken: token) { user in
            DispatchQueue.main.async {
                self.userProfile = user
            }
        }
    }

    // 取得熱門歌曲資料
    func fetchTopTracks(token: String, timeRange: TimeRange) {
        SpotifyAPIService.fetchTopTracks(accessToken: token, timeRange: timeRange.rawValue) { fetchedTracks in
            DispatchQueue.main.async {
                self.tracks = fetchedTracks
            }
        }
    }

    // 提取授權碼
    func extractCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value
    }
}

enum TimeRange: String, CaseIterable {
    case shortTerm = "short_term"  // 一個月
    case mediumTerm = "medium_term"  // 半年
    case longTerm = "long_term"  // 一年

    var title: String {
        switch self {
        case .shortTerm: return "1 Month"
        case .mediumTerm: return "6 Months"
        case .longTerm: return "1 Year"
        }
    }
}

#Preview {
    ContentView()
}
