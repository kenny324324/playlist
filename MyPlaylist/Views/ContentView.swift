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
    @State private var selectedTab = 0  // 控制選中的 tab
    @ObservedObject var audioPlayer = AudioPlayer()

    // 確保畫面在狀態變化時強制更新
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            Color.spotifyText.ignoresSafeArea()

            if isLoggedIn {
                if #available(iOS 26.0, *) {
                    TabView(selection: $selectedTab) {
                        Tab("首頁", systemImage: "house.fill", value: 0) {
                            HomeView(
                                audioPlayer: audioPlayer,
                                accessToken: accessToken ?? "",
                                userProfile: userProfile,
                                logout: logout
                            )
                        }
                        
                        Tab("排行榜", systemImage: "chart.bar.fill", value: 1) {
                            TopView(
                                audioPlayer: audioPlayer,
                                userProfile: userProfile,
                                logout: logout,
                                accessToken: accessToken ?? ""
                            )
                        }
                        
                        Tab("設定", systemImage: "gearshape.fill", value: 2) {
                            SettingsView()
                        }
                    }
                    .tint(Color.spotifyGreen)
                    .tabViewStyle(.sidebarAdaptable)
                    //.tabBarMinimizeBehavior(.onScrollDown)
                    /*.tabViewBottomAccessory{
                        Text("\(Image(systemName: "swift")) Made with SwiftUI")
                            .foregroundStyle(.orange)
                            .padding()
                    }*/
                } else {
                    TabView(selection: $selectedTab) {
                        Tab("首頁", systemImage: "house.fill", value: 0) {
                            HomeView(
                                audioPlayer: audioPlayer,
                                accessToken: accessToken ?? "",
                                userProfile: userProfile,
                                logout: logout
                            )
                        }
                        
                        Tab("排行榜", systemImage: "chart.bar.fill", value: 1) {
                            TopView(
                                audioPlayer: audioPlayer,
                                userProfile: userProfile,
                                logout: logout,
                                accessToken: accessToken ?? ""
                            )
                        }
                        
                        Tab("設定", systemImage: "gearshape.fill", value: 2) {
                            SettingsView()
                        }
                    }
                    .tint(Color.spotifyGreen)
                    .tabViewStyle(.sidebarAdaptable)
                }
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
        .onReceive(NotificationCenter.default.publisher(for: .spotifyUnauthorized)) { _ in
            resetSessionState()
        }
    }

    // Spotify 登入流程
    func login() {
        guard let url = SpotifyAuthService.loginURL() else { return }
        UIApplication.shared.open(url)
    }

    // 登出流程
    func logout() {
        SpotifyAuthService.logout()
        resetSessionState()
    }

    private func resetSessionState() {
        self.accessToken = nil
        self.isLoggedIn = false
        self.userProfile = nil
        self.tracks = []
    }

    // Spotify 回調處理
    func handleSpotifyCallback(url: URL) {
        guard let code = extractCode(from: url) else { return }

        SpotifyAuthService.fetchAccessToken(code: code) { token in
            DispatchQueue.main.async {
                guard let token = token else {
                    resetSessionState()
                    return
                }
                establishSession(with: token)
            }
        }
    }

    // 檢查是否已登入
    func checkIfLoggedIn() {
        SpotifyAuthService.ensureValidAccessToken { token in
            DispatchQueue.main.async {
                guard let token = token else {
                    resetSessionState()
                    return
                }
                establishSession(with: token)
            }
        }
    }

    private func establishSession(with token: String) {
        self.accessToken = token
        self.isLoggedIn = true
        fetchUserProfile(token: token)
        fetchTopTracks(token: token, timeRange: .shortTerm)
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
