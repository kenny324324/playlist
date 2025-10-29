import SwiftUI
import AuthenticationServices

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
    
    // 用於 ASWebAuthenticationSession
    @StateObject private var presentationContextProvider = WebAuthenticationPresentationContextProvider()

    // 確保畫面在狀態變化時強制更新
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            Color.spotifyText.ignoresSafeArea()

            if #available(iOS 26.0, *) {
                TabView(selection: $selectedTab) {
                    Tab("tab.home", systemImage: "house.fill", value: 0) {
                        HomeView(
                            audioPlayer: audioPlayer,
                            accessToken: accessToken ?? "",
                            userProfile: userProfile,
                            isLoggedIn: isLoggedIn,
                            login: login,
                            logout: logout
                        )
                    }
                    
                    Tab("tab.top", systemImage: "chart.bar.fill", value: 1) {
                        TopView(
                            audioPlayer: audioPlayer,
                            userProfile: userProfile,
                            isLoggedIn: isLoggedIn,
                            login: login,
                            logout: logout,
                            accessToken: accessToken ?? ""
                        )
                    }
                    .disabled(!isLoggedIn)
                    
                    Tab("tab.settings", systemImage: "gearshape.fill", value: 2) {
                        SettingsView()
                    }
                    .disabled(!isLoggedIn)
                }
                .tint(Color.spotifyGreen)
                .tabViewStyle(.sidebarAdaptable)
                .onChange(of: isLoggedIn) { loggedIn in
                    if !loggedIn {
                        selectedTab = 0
                    }
                }
                //.tabBarMinimizeBehavior(.onScrollDown)
                /*.tabViewBottomAccessory{
                    Text("\(Image(systemName: "swift")) Made with SwiftUI")
                        .foregroundStyle(.orange)
                        .padding()
                }*/
            } else {
                TabView(selection: $selectedTab) {
                    Tab("tab.home", systemImage: "house.fill", value: 0) {
                        HomeView(
                            audioPlayer: audioPlayer,
                            accessToken: accessToken ?? "",
                            userProfile: userProfile,
                            isLoggedIn: isLoggedIn,
                            login: login,
                            logout: logout
                        )
                    }
                    
                    Tab("tab.top", systemImage: "chart.bar.fill", value: 1) {
                        TopView(
                            audioPlayer: audioPlayer,
                            userProfile: userProfile,
                            isLoggedIn: isLoggedIn,
                            login: login,
                            logout: logout,
                            accessToken: accessToken ?? ""
                        )
                    }
                    .disabled(!isLoggedIn)
                    
                    Tab("tab.settings", systemImage: "gearshape.fill", value: 2) {
                        SettingsView()
                    }
                    .disabled(!isLoggedIn)
                }
                .tint(Color.spotifyGreen)
                .tabViewStyle(.sidebarAdaptable)
                .onChange(of: isLoggedIn) { loggedIn in
                    if !loggedIn {
                        selectedTab = 0
                    }
                }
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

    // Spotify 登入流程 - 新版使用 ASWebAuthenticationSession
    func login() {
        SpotifyAuthServiceV2.shared.login(presentationContext: presentationContextProvider) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let token):
                    self.establishSession(with: token)
                case .failure(let error):
                    print("登入失敗: \(error.localizedDescription)")
                    self.resetSessionState()
                }
            }
        }
    }
    
    // 舊版登入流程 - 使用外部瀏覽器（若需要恢復，取消註解並註解掉上面的新版）
    /*
    func login() {
        guard let url = SpotifyAuthService.loginURL() else { return }
        UIApplication.shared.open(url)
    }
    */

    // 登出流程
    func logout() {
        SpotifyAuthServiceV2.logout()  // 新版
        // SpotifyAuthService.logout()  // 舊版，若需要恢復則取消註解
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
        SpotifyAuthServiceV2.ensureValidAccessToken { token in  // 新版
        // SpotifyAuthService.ensureValidAccessToken { token in  // 舊版，若需要恢復則取消註解
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
        case .shortTerm: return String(localized: "timeRange.1month")
        case .mediumTerm: return String(localized: "timeRange.6months")
        case .longTerm: return String(localized: "timeRange.1year")
        }
    }
}

#Preview {
    ContentView()
}
