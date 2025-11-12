import SwiftUI

struct TrackDetailView: View {
    let trackId: String
    let accessToken: String
    @ObservedObject var audioPlayer: AudioPlayer
    @Environment(\.dismiss) private var dismiss
    
    @State private var trackDetail: TrackDetail?
    @State private var audioFeatures: AudioFeatures?
    @State private var artistDetails: [ArtistDetail] = []
    @State private var isLoading = true
    @State private var selectedTab: DetailTab = .info
    @State private var trackStats: TrackStats?
    @State private var isLoadingStats = false
    @State private var rankingTrend: RankingTrend?
    @State private var isLoadingTrend = false
    @State private var canPlayPreview = true  // 預設可以播放，檢查後如果不行再改
    
    struct TrackStats {
        var rankShortTerm: Int?      // 4週排名
        var rankMediumTerm: Int?     // 6個月排名
        var rankLongTerm: Int?       // 所有時間排名
        var recentPlayCount: Int = 0 // 最近50次播放中出現次數
    }
    
    enum DetailTab: String, CaseIterable {
        case info
        case stats
        
        var localizedTitle: String {
            switch self {
            case .info:
                return String(localized: "detail.tab.info")
            case .stats:
                return String(localized: "detail.tab.stats")
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.spotifyText.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if isLoading {
                        trackDetailPlaceholder()
                    } else if let track = trackDetail {
                        // 專輯封面
                        albumArtSection(track: track)
                        
                        // 分頁選擇器
                        tabSelector
                            .offset(y: -10)
                        
                        // 歌曲名稱（兩個分頁都顯示）
                        trackTitleSection(track: track)
                            .offset(y: -10)
                        
                        // 根據選擇的分頁顯示內容
                        VStack(spacing: 0) {
                            if selectedTab == .info {
                                // Info 分頁內容
                                
                                // 基本資訊（人氣、時長、試聽、專輯）
                                trackInfoCardsSection(track: track)
                                
                                // 藝人資訊
                                if !artistDetails.isEmpty {
                                    artistInfoSection()
                                }
                                
                                // 在 Spotify 中打開
                                openInSpotifyButton(track: track)
                            } else {
                                // Stats 分頁內容
                                
                                // 統計卡片
                                if let stats = trackStats, let trackName = trackDetail?.name {
                                    trackStatsSection(stats: stats, trackName: trackName)
                                } else if isLoadingStats {
                                    statsLoadingPlaceholder()
                                }
                                
                                // 音訊特徵
                                if let features = audioFeatures {
                                    audioFeaturesSection(features: features)
                                }
                            }
                        }
                        .offset(y: -10)
                    } else {
                        Text("detail.cannotLoad.track")
                            .foregroundColor(.gray)
                            .padding(.top, 100)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    guard canPlayPreview, let track = trackDetail else { return }
                    Task {
                        let artistNames = track.artists.map { $0.name }.joined(separator: ", ")
                        await audioPlayer.playTrack(
                            trackName: track.name,
                            artistName: artistNames,
                            spotifyPreviewUrl: track.preview_url,
                            trackId: track.id
                        )
                    }
                }) {
                    if !canPlayPreview {
                        Image(systemName: "music.note.slash")
                            .font(.system(size: 14))
                    } else if let track = trackDetail, audioPlayer.isPlaying && audioPlayer.currentTrackId == track.id {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14))
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(canPlayPreview ? Color.spotifyGreen : Color.gray)
                .disabled(!canPlayPreview)
            }
        }
        .onAppear {
            refreshAccessTokenAndLoad()
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.localizedTitle)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
            .onAppear {
                // 設定 Segmented Control 的選中背景色為 Spotify Green 的 0.2 透明度
                UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.spotifyGreen.opacity(0.2))
                
                // 設定選中時的文字樣式：主題色（綠色）+ Spotify Bold 字體 + 較大字號
                let selectedFont = UIFont(name: "SpotifyMix-Bold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
                UISegmentedControl.appearance().setTitleTextAttributes([
                    .foregroundColor: UIColor(Color.spotifyGreen),
                    .font: selectedFont
                ], for: .selected)
                
                // 設定未選中時的文字樣式：白色 + Spotify Bold 字體 + 較大字號
                let normalFont = UIFont(name: "SpotifyMix-Bold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
                UISegmentedControl.appearance().setTitleTextAttributes([
                    .foregroundColor: UIColor.white,
                    .font: normalFont
                ], for: .normal)
            }
        }
    }
    
    // MARK: - Track Title Section
    private func trackTitleSection(track: TrackDetail) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(track.name)
                .font(.custom("SpotifyMix-Bold", size: 32))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Album Art Section
    private func albumArtSection(track: TrackDetail) -> some View {
        GeometryReader { geometry in
            if let imageUrl = track.album.images.first?.url,
               let url = URL(string: imageUrl) {
                ZStack(alignment: .top) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(ProgressView())
                    }
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipped()
                    .overlay(
                        // 底部漸層，讓圖片和下方資訊區塊有過渡效果
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.spotifyText
                            ],
                            startPoint: .init(x: 0.5, y: 0.7),
                            endPoint: .bottom
                        )
                    )

                    // 頂部漸層（導航欄區域）
                    LinearGradient(
                        colors: [
                            Color.spotifyText.opacity(0.7),
                            Color.spotifyText.opacity(0.01)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.safeAreaInsets.top + 120)
                }
            }
        }
        .frame(height: UIScreen.main.bounds.width)
    }
    
    // MARK: - Track Info Cards Section (不含歌曲名稱)
    private func trackInfoCardsSection(track: TrackDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // 人氣和時長卡片
            HStack(spacing: 12) {
                // 人氣卡片
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", Double(track.popularity) / 10.0))
                        .font(.custom("SpotifyMix-Bold", size: 22))
                        .foregroundColor(.spotifyGreen)
                    Text("detail.popularity")
                        .font(.custom("SpotifyMix-Medium", size: 12))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                .cornerRadius(12)
                
                // 時長卡片
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDuration(track.duration_ms))
                        .font(.custom("SpotifyMix-Bold", size: 22))
                        .foregroundColor(.spotifyGreen)
                    Text("detail.duration")
                        .font(.custom("SpotifyMix-Medium", size: 12))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            
            // 專輯區塊
            VStack(alignment: .leading, spacing: 12) {
                Text("detail.album")
                    .font(.custom("SpotifyMix-Bold", size: 20))
                    .foregroundColor(.white)
                
                NavigationLink(destination: AlbumDetailView(albumId: track.album.id, albumName: track.album.name, accessToken: accessToken, audioPlayer: audioPlayer)) {
                    HStack(spacing: 16) {
                        if let imageUrl = track.album.images.first?.url,
                           let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.album.name)
                                .font(.custom("SpotifyMix-Bold", size: 18))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            if let releaseDate = track.album.release_date {
                                Text(formatReleaseDate(releaseDate))
                                    .font(.custom("SpotifyMix-Medium", size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Audio Features Section
    private func audioFeaturesSection(features: AudioFeatures) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Audio features 標題
            Text("detail.audioFeatures")
                .font(.custom("SpotifyMix-Bold", size: 20))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 24)
            
            // 音訊特徵進度條
            VStack(alignment: .leading, spacing: 16) {
                AudioFeatureProgressBar(label: "Acoustic", value: features.acousticness)
                AudioFeatureProgressBar(label: "Danceable", value: features.danceability)
                AudioFeatureProgressBar(label: "Energetic", value: features.energy)
                AudioFeatureProgressBar(label: "Instrumental", value: features.instrumentalness)
                AudioFeatureProgressBar(label: "Lively", value: features.liveness)
                AudioFeatureProgressBar(label: "Popularity", value: Double(trackDetail?.popularity ?? 0) / 100.0)
                AudioFeatureProgressBar(label: "Speechful", value: features.speechiness)
                AudioFeatureProgressBar(label: "Valence", value: features.valence)
            }
            .padding(.horizontal, 20)
            
            // Audio analysis 標題
            Text("Audio analysis")
                .font(.custom("SpotifyMix-Bold", size: 20))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            
            // 音訊分析卡片網格
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    AudioAnalysisCard(
                        value: features.keyString,
                        label: "Key"
                    )
                    
                    AudioAnalysisCard(
                        value: String(format: "%.3f", features.tempo),
                        label: "BPM"
                    )
                }
                
                HStack(spacing: 12) {
                    AudioAnalysisCard(
                        value: String(format: "%.3f", features.loudness),
                        label: "Overall Loudness"
                    )
                    
                    AudioAnalysisCard(
                        value: features.modeString,
                        label: "Mode"
                    )
                }
                
                HStack(spacing: 12) {
                    AudioAnalysisCard(
                        value: "\(features.time_signature)/4",
                        label: "Time Signature"
                    )
                    
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Artist Info Section
    private func artistInfoSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("detail.artists")
                .font(.custom("SpotifyMix-Bold", size: 20))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(artistDetails, id: \.id) { artist in
                        NavigationLink(destination: ArtistDetailView(artistId: artist.id, artistName: artist.name, accessToken: accessToken, audioPlayer: audioPlayer)) {
                            VStack(spacing: 12) {
                                // 藝人圓形頭像
                                if let imageUrl = artist.images.first?.url,
                                   let url = URL(string: imageUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 30))
                                            )
                                    }
                                    .frame(width: 110, height: 110)
                                    .clipShape(Circle())
                                }
                                
                                Text(artist.name)
                                    .font(.custom("SpotifyMix-Bold", size: 14))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 110)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Open in Spotify Button
    private func openInSpotifyButton(track: TrackDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("detail.externalLinks")
                .font(.custom("SpotifyMix-Bold", size: 20))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            Button(action: {
                if let url = URL(string: track.uri) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 12) {
                    // Spotify logo
                    Image("spotify-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    
                    Text("detail.openInSpotify")
                        .font(.custom("SpotifyMix-Bold", size: 15))
                        .foregroundColor(.spotifyGreen)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.spotifyGreen)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.spotifyGreen.opacity(0.1))
                .cornerRadius(10)
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Helper Functions
    private func loadTrackDetails(with token: String) {
        let group = DispatchGroup()
        artistDetails.removeAll()
        audioFeatures = nil
        
        // 確保尚未取得資料時顯示載入狀態
        isLoading = true
        
        // 獲取歌曲詳情
        group.enter()
        SpotifyAPIService.fetchTrackDetail(trackId: trackId, accessToken: token) { detail in
            DispatchQueue.main.async {
                self.trackDetail = detail
                
                // 獲取藝人詳情
                if let detail = detail {
                    for artist in detail.artists {
                        group.enter()
                        SpotifyAPIService.fetchArtistDetail(artistId: artist.id, accessToken: token) { artistDetail in
                            DispatchQueue.main.async {
                                if let artistDetail = artistDetail {
                                    self.artistDetails.append(artistDetail)
                                }
                                group.leave()
                            }
                        }
                    }
                }
                
                group.leave()
            }
        }
        
        // 獲取音訊特徵
        group.enter()
        SpotifyAPIService.fetchAudioFeatures(trackId: trackId, accessToken: token) { features in
            DispatchQueue.main.async {
                self.audioFeatures = features
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
            // 檢查預覽是否可用
            self.checkPreviewAvailability()
            
            // 預先載入統計數據和排名趨勢
            self.loadTrackStats()
        }
    }
    
    // MARK: - Preview Availability Check
    
    /// 檢查預覽是否可用（Spotify 或 Apple Music）
    /// 預設為可播放，只在確定不能播放時才更新狀態
    private func checkPreviewAvailability() {
        guard let track = trackDetail else {
            return
        }
        
        // 先檢查 Spotify preview URL
        if track.preview_url != nil && !track.preview_url!.isEmpty {
            // Spotify 可用，保持預設的可播放狀態
            print("✅ Spotify preview 可用")
            return
        }
        
        // 沒有 Spotify preview，在背景檢查 Apple Music
        print("⏳ Spotify preview 不可用，檢查 Apple Music...")
        
        Task {
            let artistNames = track.artists.map { $0.name }.joined(separator: ", ")
            let appleMusicService = AppleMusicService()
            
            // 確保已授權
            if !appleMusicService.isAuthorized {
                _ = await appleMusicService.requestAuthorization()
            }
            
            // 搜尋 Apple Music
            if let song = await appleMusicService.searchTrack(trackName: track.name, artistName: artistNames) {
                // 檢查是否有預覽
                if song.previewAssets?.first != nil {
                    print("✅ Apple Music preview 可用")
                    // 保持預設的可播放狀態
                    return
                }
            }
            
            // 兩者都沒有，更新為不可播放
            await MainActor.run {
                canPlayPreview = false
                print("❌ 無可用預覽")
            }
        }
    }
    
    private func refreshAccessTokenAndLoad() {
        isLoading = true
        SpotifyAuthServiceV2.ensureValidAccessToken { token in
            DispatchQueue.main.async {
                let effectiveToken = token ?? (accessToken.isEmpty ? nil : accessToken)
                guard let token = effectiveToken else {
                    self.isLoading = false
                    NotificationCenter.default.post(name: .spotifyUnauthorized, object: nil)
                    return
                }
                loadTrackDetails(with: token)
            }
        }
    }
    
    private func formatDuration(_ milliseconds: Int) -> String {
        let totalSeconds = milliseconds / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatReleaseDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        // 嘗試不同的日期格式
        if dateString.count == 4 {
            // 只有年份
            return dateString
        } else if dateString.count == 7 {
            // YYYY-MM 格式
            formatter.dateFormat = "yyyy-MM"
            if let date = formatter.date(from: dateString) {
                // 根據語系決定格式
                let isChineseLocale = Locale.current.language.languageCode?.identifier == "zh"
                formatter.dateFormat = isChineseLocale ? "yyyy 年 M 月" : "MMM yyyy"
                return formatter.string(from: date)
            }
        } else {
            // 完整日期
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                // 根據語系決定格式
                let isChineseLocale = Locale.current.language.languageCode?.identifier == "zh"
                formatter.dateFormat = isChineseLocale ? "yyyy 年 M 月 d 日" : "d MMM yyyy"
                return formatter.string(from: date)
            }
        }
        
        return dateString
    }
    
    // MARK: - Track Stats Loading
    
    private func loadTrackStats() {
        isLoadingStats = true
        
        SpotifyAuthServiceV2.ensureValidAccessToken { token in
            guard let token = token else {
                DispatchQueue.main.async {
                    self.isLoadingStats = false
                }
                return
            }
            
            let group = DispatchGroup()
            var stats = TrackStats()
            
            // 獲取不同時間範圍的排名
            for (timeRange, rankType) in [("short_term", "short"), ("medium_term", "medium"), ("long_term", "long")] {
                group.enter()
                SpotifyAPIService.fetchTopTracks(accessToken: token, timeRange: timeRange) { tracks in
                    if let rank = tracks.firstIndex(where: { $0.id == self.trackId }) {
                        DispatchQueue.main.async {
                            switch rankType {
                            case "short":
                                stats.rankShortTerm = rank + 1
                            case "medium":
                                stats.rankMediumTerm = rank + 1
                            case "long":
                                stats.rankLongTerm = rank + 1
                            default:
                                break
                            }
                        }
                    }
                    group.leave()
                }
            }
            
            // 獲取最近播放記錄中的出現次數
            group.enter()
            SpotifyAPIService.fetchRecentlyPlayed(accessToken: token, limit: 50) { recentTracks in
                let count = recentTracks.filter { $0.track.id == self.trackId }.count
                DispatchQueue.main.async {
                    stats.recentPlayCount = count
                }
                group.leave()
            }
            
            group.notify(queue: .main) {
                self.trackStats = stats
                self.isLoadingStats = false
                
                // 載入排名趨勢（使用 short_term）
                self.loadRankingTrend(for: "short_term")
            }
        }
    }
    
    // MARK: - Ranking Trend Loading
    
    private func loadRankingTrend(for timeRange: String) {
        guard let trackName = trackDetail?.name else {
            return
        }
        
        isLoadingTrend = true
        
        // 先獲取用戶資料以取得 userId
        SpotifyAPIService.fetchCurrentUserProfile(accessToken: accessToken) { userProfile in
            guard let userId = userProfile?.id else {
                DispatchQueue.main.async {
                    self.isLoadingTrend = false
                }
                return
            }
            
            CloudKitRankingService.shared.fetchTrackRankingHistory(
                userId: userId,
                trackId: self.trackId,
                timeRange: timeRange
            ) { histories in
                DispatchQueue.main.async {
                    // 使用當前的即時排名（如果有的話）
                    let currentRank = self.trackStats?.rankShortTerm
                    
                    self.rankingTrend = RankingTrend.from(
                        histories: histories,
                        trackName: trackName,
                        currentRank: currentRank
                    )
                    self.isLoadingTrend = false
                }
            }
        }
    }
    
    // MARK: - Track Stats Section
    
    private func trackStatsSection(stats: TrackStats, trackName: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 排名趨勢圖（移到上面）
            if isLoadingTrend {
                trendChartLoadingPlaceholder()
            } else if let trend = rankingTrend {
                if trend.hasData {
                    trendChartSection(trend: trend)
                } else {
                    trendChartEmptyState()
                }
            }
            
            // 統計卡片（移到下面）
            VStack(alignment: .leading, spacing: 12) {
                // 第一行：4週排名 + 6個月排名
                HStack(spacing: 12) {
                    SmallStatCard(
                        number: stats.rankShortTerm != nil ? "#\(stats.rankShortTerm!)" : "-",
                        text: String(localized: "stats.ofYourMostStreamed.4weeks")
                    )
                    
                    SmallStatCard(
                        number: stats.rankMediumTerm != nil ? "#\(stats.rankMediumTerm!)" : "-",
                        text: String(localized: "stats.ofYourMostStreamed.6months")
                    )
                }
                
                // 第二行：所有時間排名 + 最近播放次數
                HStack(spacing: 12) {
                    SmallStatCard(
                        number: stats.rankLongTerm != nil ? "#\(stats.rankLongTerm!)" : "-",
                        text: String(localized: "stats.ofYourMostStreamed.allTime")
                    )
                    
                    SmallStatCard(
                        number: "\(stats.recentPlayCount)",
                        text: String(localized: "stats.times") + " \(trackName) " + String(localized: "stats.appearedInLast50"),
                        highlightWord: trackName
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 24)
        .padding(.bottom, 30)
    }
    
    // MARK: - Trend Chart Section
    
    private func trendChartSection(trend: RankingTrend) -> some View {
        RankingTrendChart(trend: trend)
            .padding(16)
            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            .cornerRadius(12)
            .padding(.horizontal, 20)
    }
    
    private func trendChartLoadingPlaceholder() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 280)
            .shimmer()
            .padding(.horizontal, 20)
    }
    
    private func trendChartEmptyState() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("rankingTrend.noHistory")
                .font(.custom("SpotifyMix-Medium", size: 16))
                .foregroundColor(.gray)
            
            Text("rankingTrend.keepListening")
                .font(.custom("SpotifyMix-Medium", size: 14))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    private func statsLoadingPlaceholder() -> some View {
        VStack(spacing: 12) {
            // 第一行
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 100)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 100)
                    .shimmer()
            }
            
            // 第二行
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 100)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 100)
                    .shimmer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 30)
    }
    
    // MARK: - Placeholder
    private func trackDetailPlaceholder() -> some View {
        VStack(spacing: 0) {
            // 專輯封面佔位符
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: UIScreen.main.bounds.width)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 24) {
                // 歌曲名稱佔位符
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .shimmer()
                
                // 資訊卡片佔位符
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 70)
                            .shimmer()
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 70)
                            .shimmer()
                    }
                    
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 70)
                            .shimmer()
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 70)
                            .shimmer()
                    }
                }
                .padding(.horizontal, 20)
                
                // 藝人資訊佔位符
                VStack(alignment: .leading, spacing: 16) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 24)
                        .shimmer()
                    
                    ForEach(0..<2, id: \.self) { _ in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .shimmer()
                            
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 150, height: 20)
                                    .shimmer()
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 100, height: 16)
                                    .shimmer()
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 音訊特徵佔位符
                VStack(alignment: .leading, spacing: 16) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 24)
                        .shimmer()
                    
                    VStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { _ in
                            VStack(alignment: .leading, spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 100, height: 16)
                                    .shimmer()
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 8)
                                    .shimmer()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                    .frame(height: 100)
            }
        }
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("SpotifyMix-Medium", size: 16))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.custom("SpotifyMix-Medium", size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct AudioFeatureBar: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.custom("SpotifyMix-Medium", size: 16))
                    .foregroundColor(.gray)
                Spacer()
                Text(String(format: "%.0f%%", value * 100))
                    .font(.custom("SpotifyMix-Medium", size: 16))
                    .foregroundColor(.white)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    // 進度條
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - New Audio Components

struct AudioFeatureProgressBar: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.custom("SpotifyMix-Medium", size: 14))
                .foregroundColor(.white)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    // 進度條 - 使用白色
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * CGFloat(value), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

struct AudioAnalysisCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.custom("SpotifyMix-Bold", size: 32))
                .foregroundColor(.white)
            Text(label)
                .font(.custom("SpotifyMix-Medium", size: 14))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(12)
    }
}

// MARK: - Small Stat Card

