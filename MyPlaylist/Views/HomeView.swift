import SwiftUI
import Combine

// MARK: - 漸層淡出文字視圖（HomeView 專用）
struct HomeFadingText: View {
    let text: String
    let font: Font
    let foregroundColor: Color
    let backgroundColor: Color
    let lineLimit: Int
    
    init(text: String, font: Font, foregroundColor: Color, backgroundColor: Color, lineLimit: Int = 1) {
        self.text = text
        self.font = font
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        GeometryReader { geometry in
            text(withWidth: geometry.size.width)
                .mask(
                    fadeGradient(for: geometry.size.width)
                        .frame(width: geometry.size.width)
                )
        }
        .frame(height: lineLimit == 1 ? 20 : CGFloat(20 * lineLimit))
    }
    
    @ViewBuilder
    private func text(withWidth width: CGFloat) -> some View {
        let base = Text(text)
            .font(font)
            .foregroundColor(foregroundColor)
            .lineLimit(lineLimit)
            .multilineTextAlignment(.leading)
            .layoutPriority(1)
        
        if lineLimit == 1 {
            base
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: width, alignment: .leading)
        } else {
            base
                .frame(width: width, alignment: .leading)
        }
    }
    
    private func fadeGradient(for width: CGFloat) -> LinearGradient {
        guard width > 0 else {
            return LinearGradient(
                gradient: Gradient(colors: [.white]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        
        let fadeWidth = min(width * 0.35, 60)
        let fadeStart = max(0, (width - fadeWidth) / width)
        
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: fadeStart),
                .init(color: .clear, location: 1)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - 水平滾動淡出遮罩修飾符
struct HorizontalScrollFadingModifier: ViewModifier {
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .overlay(
                HStack(spacing: 0) {
                    // 左側漸層遮罩
                    LinearGradient(
                        gradient: Gradient(colors: [
                            backgroundColor,
                            backgroundColor.opacity(0.8),
                            backgroundColor.opacity(0.5),
                            backgroundColor.opacity(0.2),
                            backgroundColor.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                    
                    Spacer()
                    
                    // 右側漸層遮罩
                    LinearGradient(
                        gradient: Gradient(colors: [
                            backgroundColor.opacity(0),
                            backgroundColor.opacity(0.2),
                            backgroundColor.opacity(0.5),
                            backgroundColor.opacity(0.8),
                            backgroundColor
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                }
                .padding(.horizontal, -20)
                .allowsHitTesting(false)
            )
    }
}

extension View {
    func horizontalScrollFading(backgroundColor: Color = .black) -> some View {
        self.modifier(HorizontalScrollFadingModifier(backgroundColor: backgroundColor))
    }
}

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("updateFrequency") private var updateFrequency: Int = 5
    private let currentlyPlayingTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let dashboardAutoRefreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var currentlyPlaying: CurrentlyPlayingTrack? = nil
    @State private var isSpotifyPlaying: Bool = false
    @State private var recentlyPlayed: [RecentlyPlayedTrack] = []
    @State private var savedTracks: [SavedTrackItem] = []
    @State private var savedAlbums: [SavedAlbumItem] = []
    @State private var userPlaylists: [Playlist] = []
    @State private var followedArtists: [Artist] = []
    @State private var isLoading = false  // 改為預設 false，避免一開始就顯示佔位符
    @State private var showUserProfile = false
    @State private var refreshRotation: Double = 0
    @State private var showAllRecentlyPlayed = false
    @State private var lastUpdateTime: Date = Date()
    @ObservedObject var audioPlayer: AudioPlayer
    
    // Dashboard 相關狀態
    @State private var dashboardSummary: DashboardSummary? = nil
    @State private var isDashboardLoading = false  // 改為預設 false
    @State private var showTodayPlayed = false
    @State private var showClearCacheAlert = false
    
    // Top 5 趨勢圖表
    @State private var top5Trends: [TrackTrend] = []
    @State private var isLoadingTrends = false
    
    // 追蹤上次載入時間，用於智能刷新
    @State private var lastDataLoadTime: Date?
    
    // 隱藏的 Demo 入口計數器（完全隱藏，無視覺提示）
    @State private var iconTapCount: Int = 0
    @State private var lastIconTapTime: Date = Date()
    
    // 強制刷新 navigation bar
    @State private var navigationBarId = UUID()
    
    let accessToken: String
    let userProfile: SpotifyUser?
    let isLoggedIn: Bool
    let login: () -> Void
    let logout: () -> Void
    var enterDemoMode: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
                if isLoggedIn {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            // 🎯 Dashboard 儀表板區域
                            dashboardSection
                            
                            // 分隔線
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.vertical, 5)
                            
                            // 正在播放區域
                            currentlyPlayingSection
                            
                            // 最近收藏的歌曲區域
                            savedTracksSection
                            
                            // 最近收藏的專輯區域
                            savedAlbumsSection
                            
                            // 用戶的播放列表區域
                            userPlaylistsSection
                            
                            // 最近播放區域
                            recentlyPlayedSection
                            
                            // 追蹤的藝術家區域
                            followedArtistsSection
                                .padding(.bottom, 30)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                } else {
                    // 未登入提示 - 隱藏的 Demo 入口（快速點擊圖標 5 次，無視覺提示）
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .onTapGesture {
                                handleIconTap()
                            }
                        Text("login.prompt.title")
                            .font(.appFont(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text("login.prompt.message")
                            .font(.appFont(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        .background(Color.spotifyText.ignoresSafeArea())
        .navigationTitle(isLoggedIn ? "tab.home" : "")  // 未登入時不顯示標題
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .id(navigationBarId)  // 使用 ID 強制重新渲染
        .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Group {
                        if isLoggedIn {
                            // 已登入：顯示頭像或預設圖示
                            if let user = userProfile,
                               let imageUrl = user.images?.first?.url,
                               let url = URL(string: imageUrl) {
                                Button(action: {
                                    showUserProfile = true
                                }) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                            .clipShape(Circle())
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: AdaptiveSize.toolbarAvatarSize, height: AdaptiveSize.toolbarAvatarSize)
                                }
                                .frame(width: AdaptiveSize.toolbarAvatarSize, height: AdaptiveSize.toolbarAvatarSize)
                                .contentShape(Rectangle())
                                .sheet(isPresented: $showUserProfile) {
                                    UserProfileView(userProfile: user, accessToken: accessToken, logout: logout)
                                        .presentationDetents(PresentationDetent.adaptiveDetents)
                                }
                            } else {
                                // 已登入但沒有頭像：顯示預設圖示
                                Button(action: {
                                    showUserProfile = true
                                }) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: AdaptiveSize.toolbarAvatarSize))
                                        .foregroundColor(.spotifyGreen)
                                }
                                .sheet(isPresented: $showUserProfile) {
                                    if let user = userProfile {
                                        UserProfileView(userProfile: user, accessToken: accessToken, logout: logout)
                                            .presentationDetents(PresentationDetent.adaptiveDetents)
                                    }
                                }
                            }
                        } else {
                            // 未登入：永遠顯示登入按鈕
                            if #available(iOS 26.0, *) {
                                Button(action: login) {
                                    Text("login.title")
                                        .adaptiveFont(name: "SpotifyMix-Bold", phoneSize: 18, padSize: 22)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, AdaptiveSize.size(phone: 16, pad: 24))
                                        .padding(.vertical, AdaptiveSize.size(phone: 8, pad: 12))
                                }
                                .buttonStyle(.glassProminent)
                                .tint(Color.spotifyGreen)
                            } else if #available(iOS 17.0, *) {
                                Button(action: login) {
                                    Text("login.title")
                                        .adaptiveFont(name: "SpotifyMix-Bold", phoneSize: 18, padSize: 22)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, AdaptiveSize.size(phone: 16, pad: 24))
                                        .padding(.vertical, AdaptiveSize.size(phone: 8, pad: 12))
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .tint(Color.spotifyGreen)
                            } else {
                                Button(action: login) {
                                    Text("login.title")
                                        .adaptiveFont(name: "SpotifyMix-Bold", phoneSize: 18, padSize: 22)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, AdaptiveSize.size(phone: 16, pad: 24))
                                        .padding(.vertical, AdaptiveSize.size(phone: 8, pad: 12))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.spotifyGreen)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 刷新按鈕（長按清除快取）- 只在登入時顯示
                    if isLoggedIn {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                refreshRotation += 360
                            }
                            loadData()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: UIDevice.isPad ? 20 : 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: AdaptiveSize.toolbarAvatarSize, height: AdaptiveSize.toolbarAvatarSize)
                                .rotationEffect(.degrees(refreshRotation))
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 1.0)
                                .onEnded { _ in
                                    showClearCacheAlert = true
                                }
                        )
                    }
                }
            }
        .onAppear {
            // 強制刷新 navigation bar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigationBarId = UUID()
            }
            
            print("🏠 [HomeView onAppear]")
            print("  - isLoggedIn: \(isLoggedIn)")
            print("  - accessToken 長度: \(accessToken.count)")
            print("  - isLoading: \(isLoading)")
            print("  - isDashboardLoading: \(isDashboardLoading)")
            print("  - dashboardSummary: \(dashboardSummary != nil ? "有資料" : "nil")")
            print("  - lastDataLoadTime: \(lastDataLoadTime?.description ?? "nil")")
            
            guard isLoggedIn && !accessToken.isEmpty else { 
                print("❌ [onAppear] 未登入或 Token 為空，不載入資料")
                return 
            }
            
            // 如果沒有資料，首次載入（移除 !isLoading 條件）
            if dashboardSummary == nil {
                print("📱 [onAppear] 資料為空，觸發首次載入")
                loadData(using: accessToken, showLoading: true)
                return
            }
            
            // 智能刷新：如果距離上次載入超過 30 秒，背景刷新
            if let lastLoad = lastDataLoadTime {
                let timeSinceLastLoad = Date().timeIntervalSince(lastLoad)
                if timeSinceLastLoad > 30 {
                    print("📱 [onAppear] 距離上次載入 \(Int(timeSinceLastLoad)) 秒，背景刷新資料")
                    loadData(showLoading: false)
                } else {
                    print("📱 [onAppear] 距離上次載入 \(Int(timeSinceLastLoad)) 秒，無需刷新")
                }
            } else {
                // 沒有記錄時間，首次載入應該顯示載入狀態
                print("📱 [onAppear] 無載入記錄，首次載入資料")
                loadData(showLoading: true)
            }
        }
        .onReceive(currentlyPlayingTimer) { _ in
            guard scenePhase == .active && isLoggedIn else { return }
            
            // 檢查是否達到更新頻率
            let now = Date()
            let timeInterval = now.timeIntervalSince(lastUpdateTime)
            
            if timeInterval >= Double(updateFrequency) {
                lastUpdateTime = now
                refreshCurrentlyPlaying()
            }
        }
        .onReceive(dashboardAutoRefreshTimer) { _ in
            guard scenePhase == .active && isLoggedIn else { return }
            loadData(showLoading: false)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && isLoggedIn {
                refreshCurrentlyPlaying()
            }
        }
        .alert("清除 Dashboard 快取", isPresented: $showClearCacheAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                // 清除快取
                DashboardMetricsService.shared.clearCache()
                // 重新載入
                withAnimation(.easeInOut(duration: 0.5)) {
                    refreshRotation += 360
                }
                loadData()
                print("🗑️ 已清除 Dashboard 快取並重新載入")
            }
        } message: {
            Text("這將清除今日聆聽時間和本月熱門資料的快取，並重新從 Spotify 載入資料。")
        }
        .onChange(of: isLoggedIn) { loggedIn in
            print("🔄 [onChange isLoggedIn] \(loggedIn)")
            print("  - accessToken 長度: \(accessToken.count)")
            if loggedIn && !accessToken.isEmpty {
                print("  - 觸發 loadData (from isLoggedIn change)")
                loadData(using: accessToken)
            } else if !loggedIn {
                print("  - 清除資料")
                clearData()
            } else if loggedIn && accessToken.isEmpty {
                print("  - 已登入但 Token 尚未準備好，等待 token...")
            }
        }
        .onChange(of: accessToken) { token in
            print("🔑 [onChange accessToken]")
            print("  - isLoggedIn: \(isLoggedIn)")
            print("  - token 長度: \(token.count)")
            print("  - dashboardSummary: \(dashboardSummary != nil ? "有資料" : "nil")")
            
            // 關鍵修改：不再檢查 isLoggedIn，只要有 token 就載入
            // 因為 token 的存在本身就代表已登入
            if !token.isEmpty {
                // 只有在沒有資料時才載入，避免重複載入
                if dashboardSummary == nil {
                    print("  - 觸發 loadData (from accessToken change, no data yet)")
                    loadData(using: token)
                } else {
                    print("  - 已有資料，跳過載入")
                }
            } else if token.isEmpty {
                print("  - Token 為空，清除資料")
                clearData()
            }
        }
        .sheet(isPresented: $showAllRecentlyPlayed) {
            RecentlyPlayedView(audioPlayer: audioPlayer, accessToken: accessToken)
        }
    }
    
    // MARK: - Top 5 Trend Section
    private var top5TrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.top5Trends")
                .font(.appFont(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            MultiTrackTrendChart(trends: top5Trends)
                .padding(16)
                .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                .cornerRadius(12)
        }
    }
    
    // 單獨的趨勢圖載入佔位符
    private var top5TrendLoadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 180, height: 22)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 300)
                .shimmer()
        }
    }
    
    
    // MARK: - Dashboard Section
    private var dashboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isDashboardLoading {
                DashboardLoadingPlaceholder()
                // 趨勢圖佔位符已整合至 DashboardLoadingPlaceholder 中
            } else if let summary = dashboardSummary {
                // 今日聆聽卡片
                TodayListeningCard(
                    minutes: summary.todayListeningMinutes,
                    trackCount: summary.todayListeningTrackCount,
                    lastUpdated: summary.lastUpdated,
                    onTap: {
                        showTodayPlayed = true
                    }
                )
                .background(
                    NavigationLink(
                        destination: TodayPlayedView(
                            tracks: summary.todayPlayedTracks,
                            totalMinutes: summary.todayListeningMinutes,
                            accessToken: accessToken,
                            audioPlayer: audioPlayer
                        ),
                        isActive: $showTodayPlayed
                    ) {
                        EmptyView()
                    }
                    .opacity(0                    )
                )
                
                // Top 5 趨勢圖表（Dashboard 載入完成後）
                Group {
                    if !top5Trends.isEmpty {
                        // 有資料時顯示實際內容
                        top5TrendSection
                            .id("trend_chart")  // 穩定的標識符
                    } else if isLoadingTrends {
                        // 只有在載入中且沒資料時才顯示佔位符
                        top5TrendLoadingPlaceholder
                    }
                    // 如果不在載入中且沒資料，不顯示任何內容
                }
                
                // 本月熱門歌曲
                VStack(alignment: .leading, spacing: 15) {
                    Text(String(localized: "dashboard.monthlyTopTracks"))
                        .font(.appFont(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    if summary.weeklyTopTracks.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("dashboard.empty.noTopTracks")
                                .font(.appFont(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .padding(16)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                        .cornerRadius(15)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(summary.weeklyTopTracks.prefix(3).enumerated()), id: \.element.id) { index, entry in
                                NavigationLink(destination: TrackDetailView(trackId: entry.id, accessToken: accessToken, audioPlayer: audioPlayer)) {
                                    WeeklyTopRowContent(entry: entry, rank: index + 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // 本月熱門藝人
                VStack(alignment: .leading, spacing: 15) {
                    Text(String(localized: "dashboard.monthlyTopArtists"))
                        .font(.appFont(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    if summary.weeklyTopArtists.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "person.2")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("dashboard.empty.noTopArtists")
                                .font(.appFont(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .padding(16)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                        .cornerRadius(15)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(summary.weeklyTopArtists.prefix(3).enumerated()), id: \.element.id) { index, entry in
                                NavigationLink(destination: ArtistDetailView(artistId: entry.id, artistName: entry.name, accessToken: accessToken, audioPlayer: audioPlayer)) {
                                    WeeklyTopRowContent(entry: entry, rank: index + 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            } else {
                DashboardEmptyState()
            }
        }
    }
    
    private var currentlyPlayingSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("home.nowPlaying")
                .font(.appFont(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            if isLoading && currentlyPlaying == nil {
                // 載入中的佔位符
                CurrentlyPlayingPlaceholder()
            } else if let track = currentlyPlaying {
                CurrentlyPlayingCard(track: track, audioPlayer: audioPlayer)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("home.empty.noMusic")
                        .font(.appFont(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            }
        }
    }
    
    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("home.recentlyPlayed")
                .font(.appFont(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            if isLoading && recentlyPlayed.isEmpty {
                // 載入中的佔位符
                LazyVStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { _ in
                        RecentlyPlayedPlaceholder()
                    }
                }
            } else if recentlyPlayed.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("home.empty.noHistory")
                        .font(.appFont(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(recentlyPlayed.prefix(10))) { item in
                        NavigationLink(destination: TrackDetailView(trackId: item.track.id, accessToken: accessToken, audioPlayer: audioPlayer)) {
                            RecentlyPlayedRow(item: item, audioPlayer: audioPlayer)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // 如果有超過10首，顯示底部的查看更多按鈕
                if recentlyPlayed.count > 10 {
                    Button(action: {
                        showAllRecentlyPlayed = true
                    }) {
                        HStack {
                            Text(String(localized: "home.viewRecent", defaultValue: "View recent \(recentlyPlayed.count) plays"))
                                .font(.appFont(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private var savedTracksSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("home.savedTracks")
                .font(.appFont(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            if isLoading && savedTracks.isEmpty {
                LazyVStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { _ in
                        RecentlyPlayedPlaceholder()
                    }
                }
            } else if savedTracks.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "heart")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("home.empty.noSavedTracks")
                        .font(.appFont(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(savedTracks.prefix(5)) { item in
                        NavigationLink(destination: TrackDetailView(trackId: item.track.id, accessToken: accessToken, audioPlayer: audioPlayer)) {
                            SavedTrackRow(item: item, audioPlayer: audioPlayer)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    private var savedAlbumsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("home.savedAlbums")
                .font(.appFont(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            if isLoading && savedAlbums.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            AlbumPlaceholder()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            } else if savedAlbums.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "square.stack")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("home.empty.noSavedAlbums")
                        .font(.appFont(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            } else {
                ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(savedAlbums.prefix(10)) { item in
                                NavigationLink(destination: AlbumDetailView(albumId: item.album.id, albumName: item.album.name, accessToken: accessToken, audioPlayer: audioPlayer)) {
                                    AlbumCard(album: item.album)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, -20)
                }
                .horizontalScrollFading()
            }
        }
    }
    
    private var userPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("home.myPlaylists")
                .font(.appFont(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            if isLoading && userPlaylists.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            PlaylistPlaceholder()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            } else if userPlaylists.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("home.empty.noPlaylists")
                        .font(.appFont(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            } else {
                ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(userPlaylists.prefix(10)) { playlist in
                                PlaylistCard(playlist: playlist)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, -20)
                }
                .horizontalScrollFading()
            }
        }
    }
    
    private var followedArtistsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("home.followedArtists")
                .font(.appFont(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            if isLoading && followedArtists.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            ArtistPlaceholder()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            } else if followedArtists.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "person.2")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("home.empty.noFollowedArtists")
                        .font(.appFont(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            } else {
                ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(followedArtists.prefix(20)) { artist in
                                NavigationLink(destination: ArtistDetailView(artistId: artist.id, artistName: artist.name, accessToken: accessToken, audioPlayer: audioPlayer)) {
                                    ArtistCard(artist: artist)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, -20)
                }
                .horizontalScrollFading()
            }
        }
    }
    
    private func loadData(using tokenOverride: String? = nil, showLoading: Bool = true) {
        print("🔄 [loadData] 開始載入")
        print("  - showLoading: \(showLoading)")
        print("  - isLoading 當前: \(isLoading)")
        print("  - isDashboardLoading 當前: \(isDashboardLoading)")
        
        let authToken = tokenOverride ?? accessToken
        print("  - Token 長度: \(authToken.count)")
        
        guard !authToken.isEmpty else {
            print("❌ [loadData] Token 為空，取消載入")
            if showLoading {
                isLoading = false
                isDashboardLoading = false
            }
            return
        }
        
        if showLoading {
            print("📊 [loadData] 設定載入狀態為 true")
            isLoading = true
            isDashboardLoading = true
        } else {
            print("📊 [loadData] 背景載入，不改變載入狀態")
        }
        
        let group = DispatchGroup()
        print("📊 [loadData] 開始並行載入...")
        
        // 🎯 獲取 Dashboard 資料
        group.enter()
        DashboardMetricsService.shared.fetchDashboardSummary(accessToken: authToken) { summary in
            DispatchQueue.main.async {
                self.dashboardSummary = summary
                self.isDashboardLoading = false
                group.leave()
            }
        }
        
        // 獲取正在播放的歌曲
        group.enter()
        SpotifyAPIService.fetchCurrentlyPlaying(accessToken: authToken) { response in
            DispatchQueue.main.async {
                let isPlaying = response?.is_playing ?? false
                self.isSpotifyPlaying = isPlaying
                self.currentlyPlaying = isPlaying ? response?.item : nil
                group.leave()
            }
        }
        
        // 獲取最近播放的歌曲
        group.enter()
        SpotifyAPIService.fetchRecentlyPlayed(accessToken: authToken) { tracks in
            DispatchQueue.main.async {
                self.recentlyPlayed = tracks
                group.leave()
            }
        }
        
        // 獲取收藏的歌曲
        group.enter()
        SpotifyAPIService.fetchSavedTracks(accessToken: authToken, limit: 10) { tracks in
            DispatchQueue.main.async {
                self.savedTracks = tracks
                group.leave()
            }
        }
        
        // 獲取收藏的專輯
        group.enter()
        SpotifyAPIService.fetchSavedAlbums(accessToken: authToken, limit: 10) { albums in
            DispatchQueue.main.async {
                self.savedAlbums = albums
                group.leave()
            }
        }
        
        // 獲取用戶播放列表
        group.enter()
        SpotifyAPIService.fetchUserPlaylists(accessToken: authToken) { playlists in
            DispatchQueue.main.async {
                self.userPlaylists = playlists
                group.leave()
            }
        }
        
        // 獲取追蹤的藝術家
        group.enter()
        SpotifyAPIService.fetchFollowedArtists(accessToken: authToken, limit: 20) { artists in
            DispatchQueue.main.async {
                self.followedArtists = artists
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print("✅ [loadData] 所有資料載入完成")
            print("  - 設定 isLoading = false")
            print("  - dashboardSummary: \(self.dashboardSummary != nil ? "有資料" : "nil")")
            print("  - recentlyPlayed 數量: \(self.recentlyPlayed.count)")
            
            self.isLoading = false
            
            // 記錄載入完成時間
            self.lastDataLoadTime = Date()
            print("📊 [loadData] 資料載入完成，記錄時間: \(Date())")
            
            // 載入 Top 5 趨勢圖表
            self.loadTop5Trends(accessToken: authToken)
        }
    }
    
    // MARK: - 載入 Top 5 趨勢
    private func loadTop5Trends(accessToken: String) {
        // 如果已經在載入中，避免重複載入
        guard !isLoadingTrends else {
            print("⚠️ [Top5Trends] 已經在載入中，跳過重複載入")
            return
        }
        
        isLoadingTrends = true
        
        // 先獲取用戶資料
        SpotifyAPIService.fetchCurrentUserProfile(accessToken: accessToken) { userProfile in
            guard let userId = userProfile?.id else {
                print("⚠️ [Top5Trends] 無法獲取 userId")
                DispatchQueue.main.async {
                    self.isLoadingTrends = false
                }
                return
            }
            
            print("📊 [Top5Trends] 開始載入 Top 5 趨勢")
            print("  - userId: \(userId)")
        
        // 第一步：查詢過去 7 天所有曾經進入 Top 5 的歌曲
        CloudKitRankingService.shared.fetchAllTop5TracksInLast7Days(
            userId: userId,
            timeRange: "short_term"
        ) { trackIds in
            print("📊 [Top5Trends] fetchAllTop5TracksInLast7Days 返回結果")
            print("  - 找到 \(trackIds.count) 首曾經進入 Top 5 的歌曲")
            
            // 如果沒有歷史記錄，使用當前的 Top 5 作為預設顯示
            guard !trackIds.isEmpty else {
                print("⚠️ [Top5Trends] 沒有找到任何歷史記錄，將使用當前 Top 5")
                
                // 獲取當前 Top 5
                SpotifyAPIService.fetchTopTracks(accessToken: accessToken, timeRange: "short_term") { currentTracks in
                    let top5Tracks = Array(currentTracks.prefix(5))
                    var trends: [TrackTrend] = []
                    
                    for track in top5Tracks {
                        let currentRank = currentTracks.firstIndex(where: { $0.id == track.id }).map { $0 + 1 } ?? 999
                        
                        // 創建只有今天的資料點（7 天，但只有今天有排名）
                        let calendar = Calendar.current
                        let today = calendar.startOfDay(for: Date())
                        let dataPoints = (0...6).reversed().map { daysAgo -> RankingDataPoint in
                            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
                            // 只有今天（daysAgo == 0）有排名
                            if daysAgo == 0 {
                                return RankingDataPoint(date: date, rank: currentRank, isFilled: false, isOutOfChart: false)
                            } else {
                                return RankingDataPoint(date: date, rank: nil, isFilled: false, isOutOfChart: true)
                            }
                        }
                        
                        let trackTrend = TrackTrend(track: track, dataPoints: dataPoints)
                        trends.append(trackTrend)
                    }
                    
                    DispatchQueue.main.async {
                        self.top5Trends = trends
                        self.isLoadingTrends = false
                        print("✅ [Top5Trends] 使用當前 Top 5，顯示 \(trends.count) 條趨勢線")
                    }
                }
                return
            }
            
            print("  - Track IDs: \(trackIds.prefix(10).joined(separator: ", "))\(trackIds.count > 10 ? "..." : "")")
            print("  - 這些歌曲在過去 7 天內曾經進入過 Top 5")
            
            // 第二步：獲取當前 Top 50 以取得歌曲資訊
            SpotifyAPIService.fetchTopTracks(accessToken: accessToken, timeRange: "short_term") { currentTracks in
                var trends: [TrackTrend] = []
                let group = DispatchGroup()
                
                // 第三步：為每首歌獲取歷史排名和歌曲資訊
                for trackId in trackIds {
                    group.enter()
                    
                    // 找到該歌曲的詳細資訊
                    if let track = currentTracks.first(where: { $0.id == trackId }) {
                        let currentRank = currentTracks.firstIndex(where: { $0.id == trackId }).map { $0 + 1 }
                        
                        CloudKitRankingService.shared.fetchTrackRankingHistory(
                            userId: userId,
                            trackId: trackId,
                            timeRange: "short_term"
                        ) { histories in
                            let rankingTrend = RankingTrend.from(
                                histories: histories,
                                trackName: track.name,
                                currentRank: currentRank
                            )
                            
                            let trackTrend = TrackTrend(
                                track: track,
                                dataPoints: rankingTrend.dataPoints
                            )
                            
                            DispatchQueue.main.async {
                                trends.append(trackTrend)
                                group.leave()
                            }
                        }
                    } else {
                        // 歌曲已經不在當前 Top 50，從 CloudKit 記錄中獲取名稱
                        CloudKitRankingService.shared.fetchTrackRankingHistory(
                            userId: userId,
                            trackId: trackId,
                            timeRange: "short_term"
                        ) { histories in
                            guard let firstHistory = histories.first else {
                                group.leave()
                                return
                            }
                            
                            let rankingTrend = RankingTrend.from(
                                histories: histories,
                                trackName: "Unknown Track",  // 無法取得名稱
                                currentRank: nil  // 已不在榜內
                            )
                            
                            // 創建臨時 Track（用於顯示）
                            let tempTrack = Track(
                                id: trackId,
                                name: "Unknown Track",
                                previewUrl: nil,
                                artists: [Track.TrackArtist(id: nil, name: "Unknown Artist")],
                                album: Track.TrackAlbum(id: nil, name: nil, images: [])
                            )
                            
                            let trackTrend = TrackTrend(
                                track: tempTrack,
                                dataPoints: rankingTrend.dataPoints
                            )
                            
                            DispatchQueue.main.async {
                                trends.append(trackTrend)
                                group.leave()
                            }
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    print("📊 [Top5Trends] 收到 \(trends.count) 條趨勢資料")
                    
                    // 按照當前排名排序（主要）+ 出現次數（次要）
                    let sortedTrends = trends.sorted { trend1, trend2 in
                        // 獲取當前排名（最新的排名）
                        let currentRank1 = trend1.dataPoints.last(where: { $0.rank != nil })?.rank ?? 999
                        let currentRank2 = trend2.dataPoints.last(where: { $0.rank != nil })?.rank ?? 999
                        
                        // 如果當前排名不同，按排名排序
                        if currentRank1 != currentRank2 {
                            return currentRank1 < currentRank2
                        }
                        
                        // 如果當前排名相同，按出現次數排序
                        let count1 = trend1.dataPoints.filter { $0.rank ?? 6 <= 5 }.count
                        let count2 = trend2.dataPoints.filter { $0.rank ?? 6 <= 5 }.count
                        return count1 > count2
                    }
                    
                    // Debug: 輸出每首歌的資料點和當前排名
                    for (index, trend) in sortedTrends.enumerated() {
                        let inTop5Count = trend.dataPoints.filter { $0.rank ?? 6 <= 5 }.count
                        let currentRank = trend.dataPoints.last(where: { $0.rank != nil })?.rank ?? 999
                        print("  #\(index + 1) \(trend.trackName): 當前 #\(currentRank), 在 Top 5 出現 \(inTop5Count)/7 天")
                    }
                    
                    // 先設置資料，再結束載入狀態，避免閃爍
                    self.top5Trends = sortedTrends
                    self.isLoadingTrends = false
                    
                    print("✅ [Top5Trends] 最終顯示 \(sortedTrends.count) 條趨勢線")
                }
            }
            }
        }
    }
    
    private func refreshCurrentlyPlaying() {
        guard !accessToken.isEmpty else { return }
        SpotifyAPIService.fetchCurrentlyPlaying(accessToken: accessToken) { response in
            DispatchQueue.main.async {
                let isPlaying = response?.is_playing ?? false
                self.isSpotifyPlaying = isPlaying
                self.currentlyPlaying = isPlaying ? response?.item : nil
            }
        }
    }
    
    private func clearData() {
        currentlyPlaying = nil
        isSpotifyPlaying = false
        recentlyPlayed = []
        savedTracks = []
        savedAlbums = []
        userPlaylists = []
        followedArtists = []
        dashboardSummary = nil
        top5Trends = []
        isLoading = true
        isDashboardLoading = true
        isLoadingTrends = false  // 確保重置趨勢圖載入狀態
        lastDataLoadTime = nil  // 清除載入時間記錄
    }
    
    // MARK: - 隱藏的 Demo 入口邏輯
    
    /// 處理圖標點擊 - 快速點擊 5 次進入 Demo Mode（完全隱藏，無視覺提示）
    private func handleIconTap() {
        let now = Date()
        let timeSinceLastTap = now.timeIntervalSince(lastIconTapTime)
        
        // 如果距離上次點擊超過 2 秒，重置計數器
        if timeSinceLastTap > 2.0 {
            iconTapCount = 0
        }
        
        lastIconTapTime = now
        iconTapCount += 1
        
        // 達到 5 次點擊，進入 Demo Mode
        if iconTapCount >= 5 {
            triggerDemoMode()
        }
    }
    
    /// 觸發 Demo Mode
    private func triggerDemoMode() {
        // 震動反饋
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // 重置計數器
        iconTapCount = 0
        
        // 執行 Demo Mode
        enterDemoMode?()
        
        print("🎭 隱藏入口已觸發 - 進入 Demo Mode")
    }
}

struct CurrentlyPlayingCard: View {
    let track: CurrentlyPlayingTrack
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 12) {
            // 專輯封面
            if let imageUrl = track.album.images.first?.url,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                                .font(.system(size: 24))
                        )
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxHeight: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .id(url.absoluteString)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxHeight: 100)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                            .font(.system(size: 24))
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HomeFadingText(
                    text: track.name,
                    font: .appFont(size: 20, weight: .bold),
                    foregroundColor: .white,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12),
                    lineLimit: 2
                )
                
                HomeFadingText(
                    text: track.artists.map(\.name).joined(separator: ", "),
                    font: .appFont(size: 16, weight: .medium),
                    foregroundColor: .gray,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
                
                HomeFadingText(
                    text: track.album.name,
                    font: .appFont(size: 14, weight: .medium),
                    foregroundColor: .gray,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
                
                if let previewUrl = track.preview_url {
                    Button(action: {
                        audioPlayer.playPreview(from: previewUrl)
                    }) {
                        HStack {
                            Image(systemName: audioPlayer.isPlaying && audioPlayer.currentPreviewUrl == previewUrl ? "pause.fill" : "play.fill")
                            Text("home.preview")
                        }
                        .font(.appFont(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.spotifyGreen)
                        .cornerRadius(15)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .cornerRadius(15)
        .frame(maxWidth: .infinity)
    }
}

struct RecentlyPlayedRow: View {
    let item: RecentlyPlayedTrack
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 6) {
            AsyncImage(url: URL(string: item.track.album.images.first?.url ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(8)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                HomeFadingText(
                    text: item.track.name,
                    font: .appFont(size: 16, weight: .medium),
                    foregroundColor: .white,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
                
                HomeFadingText(
                    text: item.track.artists.map(\.name).joined(separator: ", "),
                    font: .appFont(size: 14, weight: .medium),
                    foregroundColor: .gray,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
            }
            
            Spacer()
            
            // 歌曲時長
            Text(formatDuration(item.track.duration_ms))
                .font(.appFont(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            if let previewUrl = item.track.preview_url {
                Button(action: {
                    audioPlayer.playPreview(from: previewUrl)
                }) {
                    Image(systemName: audioPlayer.isPlaying && audioPlayer.currentPreviewUrl == previewUrl ? "pause.fill" : "play.fill")
                        .font(.system(size: UIDevice.isPad ? 20 : 16))
                        .foregroundColor(.white)
                        .frame(width: AdaptiveSize.playButtonSize, height: AdaptiveSize.playButtonSize)
                        .background(Color.spotifyGreen)
                        .clipShape(Circle())
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .frame(height: 45)
        .padding(8)
        .padding(.trailing, 12)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
    
    private func formatDuration(_ milliseconds: Int) -> String {
        let totalSeconds = milliseconds / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Placeholder Views
struct CurrentlyPlayingPlaceholder: View {
    var body: some View {
        HStack(spacing: 12) {
            // 專輯封面佔位符
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1, contentMode: .fit)
                .frame(maxHeight: 100)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 6) {
                // 歌曲名稱佔位符
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 20)
                    .shimmer()
                
                // 藝術家佔位符
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 16)
                    .shimmer()
                
                // 專輯佔位符
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 140, height: 14)
                    .shimmer()
                
                // 按鈕佔位符
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 28)
                    .shimmer()
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .cornerRadius(15)
        .frame(maxWidth: .infinity)
    }
}

struct RecentlyPlayedPlaceholder: View {
    var body: some View {
        HStack(spacing: 6) {
            // 專輯封面佔位符
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1, contentMode: .fit)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 4) {
                // 歌曲名稱佔位符
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 16)
                    .shimmer()
                
                // 藝術家佔位符
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 14)
                    .shimmer()
            }
            
            Spacer()
            
            // 時長佔位符
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 35, height: 14)
                .shimmer()
            
            // 播放按鈕佔位符
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 30, height: 30)
                .shimmer()
        }
        .frame(height: 45)
        .padding(8)
        .padding(.trailing, 12)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - New Component Views

struct SavedTrackRow: View {
    let item: SavedTrackItem
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 6) {
            AsyncImage(url: URL(string: item.track.album.images.first?.url ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(8)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                HomeFadingText(
                    text: item.track.name,
                    font: .appFont(size: 16, weight: .medium),
                    foregroundColor: .white,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
                
                HomeFadingText(
                    text: item.track.artists.map(\.name).joined(separator: ", "),
                    font: .appFont(size: 14, weight: .medium),
                    foregroundColor: .gray,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
            }
            
            Spacer()
            
            if let previewUrl = item.track.previewUrl {
                Button(action: {
                    audioPlayer.playPreview(from: previewUrl)
                }) {
                    Image(systemName: audioPlayer.isPlaying && audioPlayer.currentPreviewUrl == previewUrl ? "pause.fill" : "play.fill")
                        .font(.system(size: UIDevice.isPad ? 20 : 16))
                        .foregroundColor(.white)
                        .frame(width: AdaptiveSize.playButtonSize, height: AdaptiveSize.playButtonSize)
                        .background(Color.spotifyGreen)
                        .clipShape(Circle())
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .frame(height: 45)
        .padding(8)
        .padding(.trailing, 12)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
}

struct AlbumCard: View {
    let album: Album
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: album.images.first?.url ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                            .font(.system(size: 30))
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(width: 140)
            .cornerRadius(8)
            .clipped()
            
            HomeFadingText(
                text: album.name,
                font: .appFont(size: 14, weight: .medium),
                foregroundColor: .white,
                backgroundColor: .black,
                lineLimit: 1
            )
            .frame(width: 140, alignment: .leading)
            
            HomeFadingText(
                text: album.artists.map(\.name).joined(separator: ", "),
                font: .appFont(size: 12, weight: .medium),
                foregroundColor: .gray,
                backgroundColor: .black,
                lineLimit: 1
            )
            .frame(width: 140, alignment: .leading)
        }
    }
}

struct PlaylistCard: View {
    let playlist: Playlist
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: playlist.images.first?.url ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "music.note.list")
                            .foregroundColor(.gray)
                            .font(.system(size: 30))
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(width: 140)
            .cornerRadius(8)
            .clipped()
            
            HomeFadingText(
                text: playlist.name,
                font: .appFont(size: 14, weight: .medium),
                foregroundColor: .white,
                backgroundColor: .black,
                lineLimit: 1
            )
            .frame(width: 140, alignment: .leading)
        }
    }
}

struct ArtistCard: View {
    let artist: Artist
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            AsyncImage(url: URL(string: artist.images.first?.url ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 40))
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(width: 140)
            .clipShape(Circle())
            
            ZStack {
                HomeFadingText(
                    text: artist.name,
                    font: .appFont(size: 14, weight: .medium),
                    foregroundColor: .white,
                    backgroundColor: .black,
                    lineLimit: 1
                )
            }
            .frame(width: 140)
            
            ZStack {
                HomeFadingText(
                    text: "\(artist.followers.total.formatted()) \(String(localized: "component.followers"))",
                    font: .appFont(size: 12, weight: .medium),
                    foregroundColor: .gray,
                    backgroundColor: .black,
                    lineLimit: 1
                )
            }
            .frame(width: 140)
        }
    }
}

struct AlbumPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 140, height: 140)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 14)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 12)
                .shimmer()
        }
    }
}

struct PlaylistPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 140, height: 140)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 14)
                .shimmer()
        }
    }
}

struct ArtistPlaceholder: View {
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 140, height: 140)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 14)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 12)
                .shimmer()
        }
    }
}

// MARK: - WeeklyTopRow Content (用於 NavigationLink)
struct WeeklyTopRowContent: View {
    let entry: WeeklyTopEntry
    let rank: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // 排名和變化指示器
            VStack(spacing: 5) {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 12, height: 2)
                    .cornerRadius(1)
                
                Text("#\(rank)")
                    .foregroundColor(.white)
                    .font(.appFont(size: 22, weight: .bold))
                    .lineLimit(1)
            }
            .frame(width: 50, alignment: .center)
            
            // 灰色框框內容
            HStack(spacing: 6) {
                // 封面圖
                AsyncImage(url: entry.imageUrl.flatMap { URL(string: $0) }) { phase in
                    switch phase {
                    case .empty:
                        placeholderImage
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(entry.artistName == nil ? 3 : 6)
                .clipped()
                
                // 資訊
                VStack(alignment: .leading, spacing: 4) {
                    HomeFadingText(
                        text: entry.name,
                        font: .appFont(size: 17, weight: .bold),
                        foregroundColor: .white,
                        backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                    )
                    
                    if let artistName = entry.artistName {
                        HomeFadingText(
                            text: artistName,
                            font: .appFont(size: 15, weight: .medium),
                            foregroundColor: .gray,
                            backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                        )
                    }
                }
                
                Spacer()
                
                // 箭頭
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 45)
            .padding(8)
            .padding(.trailing, 12)
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var placeholderImage: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Image(systemName: entry.artistName == nil ? "person.fill" : "music.note")
                .foregroundColor(.gray)
                .font(.system(size: 16))
        }
    }
}

//#Preview {
//    HomeView(audioPlayer: AudioPlayer(), accessToken: "", userProfile: nil, logout: {})
//        .preferredColorScheme(.dark)
//        .background(Color.spotifyText)
//}
