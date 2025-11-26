import SwiftUI
import AuthenticationServices

// MARK: - 啟動畫面過渡動畫選項
enum LaunchTransitionStyle: String, CaseIterable, Identifiable {
    case fade = "fade"                    // 淡入淡出
    case scaleUpFade = "scaleUpFade"     // 放大淡出
    case scaleDownFade = "scaleDownFade" // 縮小淡出
    case slideUp = "slideUp"             // 向上滑動
    case slideUpFade = "slideUpFade"     // 向上滑動 + 淡出
    
    var id: String { rawValue }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .fade:
            return "settings.launchTransition.fade"
        case .scaleUpFade:
            return "settings.launchTransition.scaleUpFade"
        case .scaleDownFade:
            return "settings.launchTransition.scaleDownFade"
        case .slideUp:
            return "settings.launchTransition.slideUp"
        case .slideUpFade:
            return "settings.launchTransition.slideUpFade"
        }
    }
    
    var icon: String {
        switch self {
        case .fade:
            return "circle.dotted"
        case .scaleUpFade:
            return "arrow.up.left.and.arrow.down.right"
        case .scaleDownFade:
            return "arrow.down.right.and.arrow.up.left"
        case .slideUp:
            return "arrow.up"
        case .slideUpFade:
            return "arrow.up.circle"
        }
    }
    
    var transition: AnyTransition {
        switch self {
        case .fade:
            return .opacity
        case .scaleUpFade:
            return .scale(scale: 1.2).combined(with: .opacity)
        case .scaleDownFade:
            return .scale(scale: 0.8).combined(with: .opacity)
        case .slideUp:
            return .move(edge: .top)
        case .slideUpFade:
            return .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            )
        }
    }
}

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
    @State private var trackDetailSheetItem: TrackDetailSheetItem? = nil
    
    // 用於 ASWebAuthenticationSession
    @StateObject private var presentationContextProvider = WebAuthenticationPresentationContextProvider()

    // 確保畫面在狀態變化時強制更新
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("updateFrequency") private var updateFrequency: Int = 5
    @State private var lastUpdateTime: Date = Date()
    
    // 啟動載入畫面控制
    @State private var showLaunchScreen = true
    
    // 通知權限請求標記
    @AppStorage("hasRequestedNotificationPermission") private var hasRequestedNotificationPermission: Bool = false
    @AppStorage("dailyNotificationEnabled") private var dailyNotificationEnabled: Bool = true
    @AppStorage("dailyNotificationHour") private var dailyNotificationHour: Int = 20
    @AppStorage("dailyNotificationMinute") private var dailyNotificationMinute: Int = 0
    
    // 過渡動畫樣式（從設定讀取）
    @AppStorage("launchTransitionStyle") private var transitionStyleRaw: String = LaunchTransitionStyle.fade.rawValue
    
    private var transitionStyle: LaunchTransitionStyle {
        LaunchTransitionStyle(rawValue: transitionStyleRaw) ?? .fade
    }
    
    // 定時器：每秒檢查，但根據設定頻率執行
    private let currentlyPlayingTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var didApplyUITestArguments = false
    @State private var isRefreshingAccessToken = false

    var body: some View {
        ZStack {
            Color.spotifyText.ignoresSafeArea()
            
            // 顯示啟動載入畫面或主畫面
            if showLaunchScreen {
                LaunchScreenView(
                    onLoadingComplete: {
                        // 載入完成後隱藏啟動畫面
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showLaunchScreen = false
                        }
                        
                        // 首次啟動時請求通知權限
                        requestNotificationPermissionIfNeeded()
                    },
                    checkLoginAndPreload: { completion in
                        // 在啟動畫面時預載資料，完成後回調（傳入 success 狀態）
                        checkIfLoggedInWithCompletion { success in
                            completion(success)
                        }
                    },
                    userName: userProfile?.display_name,
                    isLoggedIn: isLoggedIn
                )
                .transition(transitionStyle.transition)  // 使用選擇的過渡動畫
            } else {
                mainContent
                    .id("main_content")  // 強制重新渲染
            }
        }
        .onOpenURL { url in
            handleSpotifyCallback(url: url)  // 監聽 Spotify 回調 URL
        }
        .onAppear {
            // 檢查編譯標誌（用於調試）
            DebugHelper.checkCompilationFlags()
            applyUITestArgumentsIfNeeded()
            
            // 記錄 App 啟動（用於評分提示）
            AppRatingManager.shared.recordAppLaunch()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && !showLaunchScreen {
                checkIfLoggedIn()  // App 從背景返回時檢查登入狀態
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .spotifyUnauthorized)) { _ in
            resetSessionState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .spotifyTokenExpired)) { _ in
            handleTokenExpiration()
        }
        .onReceive(currentlyPlayingTimer) { _ in
            if scenePhase == .active && isLoggedIn && !showLaunchScreen {
                // 檢查是否達到更新頻率
                let now = Date()
                let timeInterval = now.timeIntervalSince(lastUpdateTime)
                
                if timeInterval >= Double(updateFrequency) {
                    lastUpdateTime = now
                fetchCurrentlyPlaying()
                }
            }
        }
        .sheet(item: $trackDetailSheetItem) { item in
            NavigationStack {
                TrackDetailView(trackId: item.id, accessToken: accessToken ?? "", audioPlayer: audioPlayer)
            }
        }
    }
    
    // MARK: - 主要內容
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            // Demo 模式指示器已移除（避免被 Apple 審核視為測試版本）
            // 如果需要調試，可以查看 Console 日誌確認 Demo Mode 狀態

            if #available(iOS 26.0, *) {
                TabView(selection: $selectedTab) {
                    Tab("tab.home", systemImage: "house.fill", value: 0) {
                        NavigationView {
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
                        .navigationViewStyle(.stack)  // 確保使用正確的 navigation style
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
                    .disabled(!isLoggedIn)  // 未登入時禁用搜尋
                    
                    Tab("tab.top", systemImage: "chart.bar.fill", value: 2) {
                        NavigationView {
                            TopView(
                                audioPlayer: audioPlayer,
                                userProfile: userProfile,
                                isLoggedIn: isLoggedIn,
                                login: login,
                                logout: logout,
                                accessToken: accessToken ?? ""
                            )
                        }
                    }
                    .disabled(!isLoggedIn)
                    
                    Tab("tab.settings", systemImage: "gearshape.fill", value: 3) {
                        NavigationView {
                            SettingsView(
                                userProfile: userProfile,
                                accessToken: accessToken ?? "",
                                isLoggedIn: isLoggedIn,
                                logout: logout
                            )
                        }
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
                    // 只在登入時顯示 MiniPlayerBar（無論是否有播放內容）
                    if isLoggedIn {
                        MiniPlayerBar(
                            track: currentlyPlaying,
                            audioPlayer: audioPlayer,
                            onTapTrack: { trackId in
                                trackDetailSheetItem = TrackDetailSheetItem(id: trackId)
                            }
                        )
                    } else {
                        // 未登入時返回空視圖，完全不顯示 bottom accessory
                        EmptyView()
                    }
                }
            } else {
                TabView(selection: $selectedTab) {
                    Tab("tab.home", systemImage: "house.fill", value: 0) {
                        NavigationView {
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
                        .navigationViewStyle(.stack)  // 確保使用正確的 navigation style
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
                    .disabled(!isLoggedIn)  // 未登入時禁用搜尋
                    
                    Tab("tab.top", systemImage: "chart.bar.fill", value: 2) {
                        NavigationView {
                            TopView(
                                audioPlayer: audioPlayer,
                                userProfile: userProfile,
                                isLoggedIn: isLoggedIn,
                                login: login,
                                logout: logout,
                                accessToken: accessToken ?? ""
                            )
                        }
                    }
                    .disabled(!isLoggedIn)
                    
                    Tab("tab.settings", systemImage: "gearshape.fill", value: 3) {
                        NavigationView {
                            SettingsView(
                                userProfile: userProfile,
                                accessToken: accessToken ?? "",
                                isLoggedIn: isLoggedIn,
                                logout: logout
                            )
                        }
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
        .onAppear {
            checkIfLoggedIn()  // 每次顯示時檢查登入狀態
        }
    }

    private func handleTokenExpiration() {
        guard isLoggedIn else { return }
        guard !isRefreshingAccessToken else { return }
        
        isRefreshingAccessToken = true
        SpotifyAuthServiceV2.refreshAccessToken { token in
            DispatchQueue.main.async {
                self.isRefreshingAccessToken = false
                guard let token = token else {
                    self.resetSessionState()
                    return
                }
                self.establishSession(with: token)
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
        
        // 重置主題色為預設綠色
        ThemeManager.shared.resetToDefault()
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
    
    // 檢查是否已登入（帶完成回調，用於載入畫面）
    func checkIfLoggedInWithCompletion(completion: @escaping (Bool) -> Void) {
        SpotifyAuthServiceV2.ensureValidAccessToken { token in
            DispatchQueue.main.async {
                guard let token = token else {
                    self.resetSessionState()
                    // 沒有登入，但不算失敗（可以進入登入畫面）
                    completion(true)
                    return
                }
                self.establishSessionWithCompletion(with: token, completion: completion)
            }
        }
    }
    
    private func establishSessionWithCompletion(with token: String, completion: @escaping (Bool) -> Void) {
        self.accessToken = token
        self.isLoggedIn = true
        DailySnapshotScheduler.shared.scheduleIfNeeded(accessToken: token)
        
        // 使用 DispatchGroup 來等待兩個 API 都完成
        let group = DispatchGroup()
        var userFetchSuccess = false
        var tracksFetchSuccess = false
        
        // 取得使用者資料
        group.enter()
        SpotifyAPIService.fetchCurrentUserProfile(accessToken: token) { user in
            DispatchQueue.main.async {
                if user != nil {
                    self.userProfile = user
                    userFetchSuccess = true
                }
                group.leave()
            }
        }
        
        // 取得熱門歌曲
        group.enter()
        SpotifyAPIService.fetchTopTracks(accessToken: token, timeRange: "short_term") { fetchedTracks in
            DispatchQueue.main.async {
                if !fetchedTracks.isEmpty {
                    self.tracks = fetchedTracks
                    tracksFetchSuccess = true
                }
                group.leave()
            }
        }
        
        // 設置最長等待時間（10 秒），避免網路問題導致無限等待
        let timeout = DispatchTime.now() + .seconds(10)
        var hasNotified = false
        
        group.notify(queue: .main) {
            guard !hasNotified else { return }
            hasNotified = true
            
            // 檢查是否至少有一個 API 成功
            let success = userFetchSuccess || tracksFetchSuccess
            
            if success {
                print("✅ [Launch] 資料載入完成")
                completion(true)
            } else {
                print("❌ [Launch] 資料載入失敗")
                self.resetSessionState()
                completion(false)
            }
        }
        
        // 超時保護
        DispatchQueue.global().asyncAfter(deadline: timeout) {
            DispatchQueue.main.async {
                guard !hasNotified else { return }
                hasNotified = true
                
                print("⚠️ [Launch] 資料載入超時")
                
                // 超時視為網路問題
                self.resetSessionState()
                completion(false)
            }
        }
    }

    private func establishSession(with token: String) {
        self.accessToken = token
        self.isLoggedIn = true
        DailySnapshotScheduler.shared.scheduleIfNeeded(accessToken: token)
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
    
    // MARK: - 通知權限請求
    
    /// 首次啟動時請求通知權限
    private func requestNotificationPermissionIfNeeded() {
        // 如果已經請求過，就不再請求
        guard !hasRequestedNotificationPermission else {
            return
        }
        
        // 延遲 0.5 秒再請求，讓啟動過渡動畫完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationService.shared.requestAuthorization { granted in
                // 標記已請求過
                self.hasRequestedNotificationPermission = true
                
                if granted {
                    print("✅ 通知權限已授予，啟用每日提醒")
                    // 自動排程每日通知
                    NotificationService.shared.scheduleDailyReminder(
                        hour: self.dailyNotificationHour,
                        minute: self.dailyNotificationMinute,
                        enabled: self.dailyNotificationEnabled
                    )
                } else {
                    print("⚠️ 用戶拒絕通知權限")
                }
            }
        }
    }
    
    private func applyUITestArgumentsIfNeeded() {
        guard !didApplyUITestArguments else { return }
        let arguments = ProcessInfo.processInfo.arguments
        
        if arguments.contains("-uiTestDemoMode") {
            demoModeManager.enableDemoMode()
            accessToken = demoModeManager.demoAccessToken
            userProfile = MockSpotifyData.demoUser
            tracks = MockSpotifyData.demoTracks
            isLoggedIn = true
        }
        
        didApplyUITestArguments = true
    }
}

private struct TrackDetailSheetItem: Identifiable {
    let id: String
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
