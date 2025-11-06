import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var demoModeManager = DemoModeManager.shared
    @State private var accessToken: String? = nil
    @State private var isLoggedIn = false  // 控制登入狀態
    @State private var tracks: [Track] = []
    @State private var userProfile: SpotifyUser? = nil
    @State private var selectedTab = 0  // 控制選中的 tab
    @ObservedObject var audioPlayer = AudioPlayer()
    
    // 當前播放相關
    @State private var currentlyPlaying: CurrentlyPlayingTrack? = nil
    @State private var currentlyPlayingProgressMs: Int = 0
    @State private var isSpotifyPlaying: Bool = false
    @State private var showTrackDetailFromPlayer = false
    @State private var selectedTrackIdFromPlayer: String? = nil
    
    // 用於 ASWebAuthenticationSession
    @StateObject private var presentationContextProvider = WebAuthenticationPresentationContextProvider()

    // 確保畫面在狀態變化時強制更新
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("updateFrequency") private var updateFrequency: Int = 5
    @State private var lastUpdateTime: Date = Date()
    
    // 定時器：每秒檢查，但根據設定頻率執行
    private let currentlyPlayingTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.spotifyText.ignoresSafeArea()
            
            // Demo 模式指示器
            if demoModeManager.isDemoMode {
                VStack {
                    HStack {
                        Image(systemName: "theatermasks.fill")
                        Text("Demo Mode")
                        Image(systemName: "theatermasks.fill")
                    }
                    .font(.custom("SpotifyMix-Bold", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .cornerRadius(20)
                    .shadow(radius: 4)
                    Spacer()
                }
                .padding(.top, 50)
                .zIndex(999)
            }

            if #available(iOS 26.0, *) {
                TabView(selection: $selectedTab) {
                    Tab("tab.home", systemImage: "house.fill", value: 0) {
                        HomeView(
                            audioPlayer: audioPlayer,
                            accessToken: accessToken ?? "",
                            userProfile: userProfile,
                            isLoggedIn: isLoggedIn,
                            login: login,
                            logout: logout,
                            enterDemoMode: enterDemoMode
                        )
                    }
                    
                    Tab("tab.search", systemImage: "magnifyingglass", value: 1, role: .search) {
                        NavigationView {
                            SearchView(
                                audioPlayer: audioPlayer,
                                accessToken: accessToken ?? "",
                                isLoggedIn: isLoggedIn,
                                login: login,
                                logout: logout,
                                selectedTab: selectedTab
                            )
                        }
                    }
                    
                    Tab("tab.top", systemImage: "chart.bar.fill", value: 2) {
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
                    
                    Tab("tab.settings", systemImage: "gearshape.fill", value: 3) {
                        SettingsView(
                            userProfile: userProfile,
                            accessToken: accessToken ?? "",
                            isLoggedIn: isLoggedIn,
                            logout: logout
                        )
                    }
                    .disabled(!isLoggedIn)
                }
                .tint(Color.spotifyGreen)
                .tabViewStyle(.sidebarAdaptable)
                .onChange(of: isLoggedIn) { loggedIn in
                    if !loggedIn {
                        selectedTab = 0
                        currentlyPlaying = nil
                    } else {
                        fetchCurrentlyPlaying()
                    }
                }
                .tabBarMinimizeBehavior(.onScrollDown)
                .tabViewBottomAccessory {
                    if isLoggedIn {
                        MiniPlayerBar(
                            track: currentlyPlaying,
                            audioPlayer: audioPlayer,
                            onTapTrack: { trackId in
                                selectedTrackIdFromPlayer = trackId
                                showTrackDetailFromPlayer = true
                            }
                        )
                    }
                }
            } else {
                TabView(selection: $selectedTab) {
                    Tab("tab.home", systemImage: "house.fill", value: 0) {
                        HomeView(
                            audioPlayer: audioPlayer,
                            accessToken: accessToken ?? "",
                            userProfile: userProfile,
                            isLoggedIn: isLoggedIn,
                            login: login,
                            logout: logout,
                            enterDemoMode: enterDemoMode
                        )
                    }
                    
                    Tab("tab.search", systemImage: "magnifyingglass", value: 1, role: .search) {
                        NavigationView {
                            SearchView(
                                audioPlayer: audioPlayer,
                                accessToken: accessToken ?? "",
                                isLoggedIn: isLoggedIn,
                                login: login,
                                logout: logout,
                                selectedTab: selectedTab
                            )
                        }
                    }
                    
                    Tab("tab.top", systemImage: "chart.bar.fill", value: 2) {
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
                    
                    Tab("tab.settings", systemImage: "gearshape.fill", value: 3) {
                        SettingsView(
                            userProfile: userProfile,
                            accessToken: accessToken ?? "",
                            isLoggedIn: isLoggedIn,
                            logout: logout
                        )
                    }
                    .disabled(!isLoggedIn)
                }
                .tint(Color.spotifyGreen)
                .tabViewStyle(.sidebarAdaptable)
                .onChange(of: isLoggedIn) { loggedIn in
                    if !loggedIn {
                        selectedTab = 0
                        currentlyPlaying = nil
                    } else {
                        fetchCurrentlyPlaying()
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
        .onReceive(currentlyPlayingTimer) { _ in
            if scenePhase == .active && isLoggedIn {
                // 檢查是否達到更新頻率
                let now = Date()
                let timeInterval = now.timeIntervalSince(lastUpdateTime)
                
                if timeInterval >= Double(updateFrequency) {
                    lastUpdateTime = now
                fetchCurrentlyPlaying()
                }
            }
        }
        .sheet(isPresented: $showTrackDetailFromPlayer) {
            if let trackId = selectedTrackIdFromPlayer {
                NavigationView {
                    TrackDetailView(trackId: trackId, accessToken: accessToken ?? "", audioPlayer: audioPlayer)
                }
            }
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
    
    // 進入 Demo 模式（僅在審核版本可用）
    func enterDemoMode() {
        print("🎭 進入 Demo 模式")
        demoModeManager.enableDemoMode()
        
        // 模擬登入狀態
        self.accessToken = demoModeManager.demoAccessToken
        self.isLoggedIn = true
        self.userProfile = MockSpotifyData.demoUser
        self.tracks = MockSpotifyData.demoTracks
        self.currentlyPlaying = MockSpotifyData.demoCurrentlyPlaying
    }
    
    // 登出流程
    func logout() {
        // 如果是 Demo 模式，關閉 Demo 模式
        if demoModeManager.isDemoMode {
            demoModeManager.disableDemoMode()
        }
        
        SpotifyAuthServiceV2.logout()
        resetSessionState()
    }

    private func resetSessionState() {
        // 不清除排名歷史記錄，讓每個用戶的資料保留
        // 當用戶重新登入時，會自動使用該用戶的歷史記錄
        
        self.accessToken = nil
        self.isLoggedIn = false
        self.userProfile = nil
        self.tracks = []
        self.currentlyPlaying = nil
        self.currentlyPlayingProgressMs = 0
        self.isSpotifyPlaying = false
    }
    
    // 獲取當前播放的歌曲
    private func fetchCurrentlyPlaying() {
        guard let token = accessToken, !token.isEmpty else { return }
        
        SpotifyAPIService.fetchCurrentlyPlaying(accessToken: token) { response in
            DispatchQueue.main.async {
                let newTrack = response?.item
                self.currentlyPlayingProgressMs = response?.progress_ms ?? 0
                self.isSpotifyPlaying = response?.is_playing ?? false
                
                if let newTrack {
                    if self.currentlyPlaying?.id != newTrack.id {
                        self.currentlyPlaying = newTrack
                    }
                } else {
                    self.currentlyPlaying = nil
                }
            }
        }
    }

    // Spotify 回調處理
    func handleSpotifyCallback(url: URL) {
        SpotifyAuthServiceV2.handleRedirectURL(url) { token in
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
        SpotifyAuthServiceV2.ensureValidAccessToken { token in
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
