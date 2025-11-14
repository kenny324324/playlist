import SwiftUI

struct AlbumDetailView: View {
    let albumId: String
    let albumName: String
    let accessToken: String
    @ObservedObject var audioPlayer: AudioPlayer
    
    @State private var albumDetail: AlbumDetail?
    @State private var artistDetails: [ArtistDetail] = []
    @State private var isLoading = true
    @State private var selectedTab: DetailTab = .info
    @State private var albumStats: AlbumStats?
    @State private var isLoadingStats = false
    @State private var statsError: String?
    
    // 長條圖數據
    @State private var albumCountTrend: AlbumCountTrend?
    @State private var isLoadingTrend = false
    
    // Sheet 控制狀態
    @State private var selectedStatsType: StatsCardType?
    
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
                        albumDetailPlaceholder()
                    } else if let album = albumDetail {
                        // 專輯封面
                        albumCoverSection(album: album)
                        
                        // 分頁選擇器
                        tabSelector
                            .offset(y: -10)
                        
                        // 專輯名稱（兩個分頁都顯示）
                        albumTitleSection(album: album)
                            .offset(y: -10)
                        
                        // 根據選擇的分頁顯示內容
                        VStack(spacing: 0) {
                            if selectedTab == .info {
                                // Info 分頁內容
                                albumInfoCardsSection(album: album)
                                
                                // 專輯曲目
                                if !album.tracks.items.isEmpty {
                                    albumTracksSection(album: album)
                                }
                                
                                // 藝人資訊
                                if !artistDetails.isEmpty {
                                    artistInfoSection()
                                }
                                
                                // 在 Spotify 中打開
                                openInSpotifyButton(album: album)
                            } else {
                        // Stats 分頁內容
                        if let stats = albumStats {
                            albumStatsSection(stats: stats, albumName: album.name)
                        } else if let statsError = statsError {
                            Text(statsError)
                                .font(.appFont(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                                .padding(.top, 40)
                        } else if isLoadingStats {
                            statsLoadingPlaceholder()
                        }
                            }
                        }
                        .offset(y: -10)
                    } else {
                        Text("detail.cannotLoad.album")
                            .foregroundColor(.gray)
                            .padding(.top, 100)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
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
            .onChange(of: selectedTab) { newTab in
                // 當切換到 Stats 分頁且尚未載入統計數據時，載入統計數據
                if newTab == .stats && albumStats == nil && !isLoadingStats {
                    loadAlbumStats()
                }
            }
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
    
    // MARK: - Album Title Section
    private func albumTitleSection(album: AlbumDetail) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(album.name)
                .font(.appFont(size: 32, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Album Info Cards Section (不含專輯名稱)
    private func albumInfoCardsSection(album: AlbumDetail) -> some View {
        VStack(spacing: 24) {
            // 資訊卡片
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Track 卡片
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(album.tracks.items.first?.track_number ?? 1)")
                            .font(.appFont(size: 22, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                        Text("detail.track")
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .cornerRadius(12)
                    
                    // Popularity 卡片
                    if let popularity = album.popularity {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f", Double(popularity) / 10.0))
                                .font(.appFont(size: 22, weight: .bold))
                                .foregroundColor(.spotifyGreen)
                            Text("detail.popularity")
                                .font(.appFont(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                        .cornerRadius(12)
                    }
                }
                
                HStack(spacing: 12) {
                    // Type of album 卡片
                    VStack(alignment: .leading, spacing: 4) {
                        Text(album.album_type.capitalized)
                            .font(.appFont(size: 22, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                        Text("detail.typeOfAlbum")
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .cornerRadius(12)
                    
                    // Release Date 卡片
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatReleaseDate(album.release_date ?? ""))
                            .font(.appFont(size: 22, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("detail.releaseDate")
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
    }
    
    // MARK: - Album Cover Section
    private func albumCoverSection(album: AlbumDetail) -> some View {
        GeometryReader { geometry in
            if let imageUrl = album.images.first?.url,
               let url = URL(string: imageUrl) {
                ZStack(alignment: .top) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                            )
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
                    
                    // 頂部漸層遮罩（讓導航欄按鈕更清晰）
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
    
    // MARK: - Album Info Section
    private func albumInfoSection(album: AlbumDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // 專輯名稱
            Text(album.name)
                .font(.appFont(size: 32, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            // 資訊卡片
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Track 卡片
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(album.tracks.items.first?.track_number ?? 1)")
                            .font(.appFont(size: 22, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                        Text("detail.track")
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .cornerRadius(12)
                    
                    // Popularity 卡片
                    if let popularity = album.popularity {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f", Double(popularity) / 10.0))
                                .font(.appFont(size: 22, weight: .bold))
                                .foregroundColor(.spotifyGreen)
                            Text("detail.popularity")
                                .font(.appFont(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                        .cornerRadius(12)
                    }
                }
                
                HStack(spacing: 12) {
                    // Type of album 卡片
                    VStack(alignment: .leading, spacing: 4) {
                        Text(album.album_type.capitalized)
                            .font(.appFont(size: 22, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                        Text("detail.typeOfAlbum")
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .cornerRadius(12)
                    
                    // Release date 卡片
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatReleaseDate(album.release_date ?? ""))
                            .font(.appFont(size: 22, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                        Text("detail.releaseDate")
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Album Tracks Section
    private func albumTracksSection(album: AlbumDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("detail.albumContent")
                .font(.appFont(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                ForEach(album.tracks.items) { track in
                    NavigationLink(destination: TrackDetailView(trackId: track.id, accessToken: accessToken, audioPlayer: audioPlayer)) {
                        trackRowView(track: track, album: album)
                    }
                }
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 30)
    }
    
    private func trackRowView(track: AlbumTrack, album: AlbumDetail) -> some View {
        HStack(spacing: 12) {
            // 曲目編號
            Text("\(track.track_number)")
                .font(.appFont(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, alignment: .center)
            
            // 專輯封面
            if let imageUrl = album.images.first?.url,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 45, height: 45)
                .cornerRadius(4)
            }
            
            // 歌曲資訊
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artists.map { $0.name }.joined(separator: ", "))
                    .font(.appFont(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08))
        .cornerRadius(8)
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
    
    // MARK: - Artist Info Section
    private func artistInfoSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("detail.artist")
                .font(.appFont(size: 20, weight: .bold))
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
                                    .font(.appFont(size: 14, weight: .bold))
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
    private func openInSpotifyButton(album: AlbumDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("detail.externalLinks")
                .font(.appFont(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            Button(action: {
                if let url = URL(string: album.uri) {
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
                        .font(.appFont(size: 15, weight: .bold))
                        .foregroundColor(.spotifyDefaultGreen)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.spotifyDefaultGreen)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.spotifyDefaultGreen.opacity(0.1))
                .cornerRadius(10)
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Helper Functions
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
                loadAlbumDetails(with: token)
            }
        }
    }
    
    private func loadAlbumDetails(with token: String) {
        SpotifyAPIService.fetchAlbumDetail(albumId: albumId, accessToken: token) { detail in
            DispatchQueue.main.async {
                self.albumDetail = detail
                
                // 獲取藝人詳細資訊
                if let artists = detail?.artists {
                    let group = DispatchGroup()
                    var tempArtistDetails: [ArtistDetail] = []
                    
                    for artist in artists {
                        group.enter()
                        SpotifyAPIService.fetchArtistDetail(artistId: artist.id, accessToken: token) { artistDetail in
                            if let artistDetail = artistDetail {
                                tempArtistDetails.append(artistDetail)
                            }
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        self.artistDetails = tempArtistDetails
                        self.isLoading = false
                    }
                } else {
                    self.isLoading = false
                }
            }
        }
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
                formatter.dateFormat = isChineseLocale ? "yyyy.M" : "MMM yyyy"
                return formatter.string(from: date)
            }
        } else if dateString.count == 10 {
            // YYYY-MM-DD 格式
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                // 根據語系決定格式
                let isChineseLocale = Locale.current.language.languageCode?.identifier == "zh"
                formatter.dateFormat = isChineseLocale ? "yyyy.M.d" : "d MMM yyyy"
                return formatter.string(from: date)
            }
        }
        
        return dateString
    }
    
    // MARK: - Placeholder
    private func albumDetailPlaceholder() -> some View {
        VStack(spacing: 0) {
            // 專輯封面佔位符
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: UIScreen.main.bounds.width)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 24) {
                // 專輯名稱佔位符
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
                
                // 曲目列表佔位符
                VStack(alignment: .leading, spacing: 16) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 24)
                        .shimmer()
                    
                    ForEach(0..<5, id: \.self) { _ in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .shimmer()
                            
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 200, height: 18)
                                    .shimmer()
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 150, height: 14)
                                    .shimmer()
                            }
                            
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 14)
                                .shimmer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 藝人資訊佔位符
                VStack(alignment: .leading, spacing: 16) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 24)
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
                
                Spacer()
                    .frame(height: 100)
            }
        }
    }
    
    // MARK: - Album Stats Section
    private func albumStatsSection(stats: AlbumStats, albumName: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 長條圖（移到上面）
            if isLoadingTrend {
                trendChartLoadingPlaceholder()
            } else {
                trendChartSection(trend: albumCountTrend)
            }
            
            // 統計卡片（移到下面）
            VStack(spacing: 16) {
                // 第一行：4週 + 6個月
                HStack(spacing: 12) {
                SmallStatCard(
                    number: "\(stats.tracksInShortTerm)",
                    text: "\(stats.tracksInShortTerm) \(String(localized: "stats.album.tracksOf")) \(albumName) \(String(localized: "stats.album.inTop50.4weeks"))",
                    highlightWord: albumName,
                    onTap: {
                        presentAlbumStats(type: .albumShortTerm)
                    }
                )
                
                SmallStatCard(
                    number: "\(stats.tracksInMediumTerm)",
                    text: "\(stats.tracksInMediumTerm) \(String(localized: "stats.album.tracksOf")) \(albumName) \(String(localized: "stats.album.inTop50.6months"))",
                    highlightWord: albumName,
                    onTap: {
                        presentAlbumStats(type: .albumMediumTerm)
                    }
                )
            }
            
            // 第二行：所有時間 + 最近50次
            HStack(spacing: 12) {
                SmallStatCard(
                    number: "\(stats.tracksInLongTerm)",
                    text: "\(stats.tracksInLongTerm) \(String(localized: "stats.album.tracksOf")) \(albumName) \(String(localized: "stats.album.inTop50.allTime"))",
                    highlightWord: albumName,
                    onTap: {
                        presentAlbumStats(type: .albumLongTerm)
                    }
                )
                
                SmallStatCard(
                    number: "\(stats.recentPlayCount)",
                    text: "\(stats.recentPlayCount) \(String(localized: "stats.album.tracksFrom")) \(albumName) \(String(localized: "stats.album.appearedInLast50"))",
                    highlightWord: albumName,
                    onTap: {
                        presentAlbumStats(type: .albumRecent)
                    }
                )
            }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 24)
        .padding(.bottom, 30)
        .sheet(item: $selectedStatsType) { statsType in
            if let stats = albumStats, let album = albumDetail {
                StatsDetailSheet(
                    title: statsType.getTitle(name: album.name),
                    subtitle: statsType.getSubtitle(name: album.name, count: getTrackCount(for: statsType, stats: stats)),
                    tracks: getTracks(for: statsType, stats: stats),
                    accessToken: accessToken,
                    isRecentlyPlayed: statsType.isRecentlyPlayed,
                    audioPlayer: audioPlayer
                )
            } else {
                StatsDetailLoadingView()
            }
        }
    }
    
    private func presentAlbumStats(type: StatsCardType) {
        guard albumStats != nil, albumDetail != nil else {
            return
        }
        selectedStatsType = type
    }
    
    // MARK: - Trend Chart Section
    
    private func trendChartSection(trend: AlbumCountTrend?) -> some View {
        // 如果沒有數據，創建 7 個空的數據點
        let dataPoints: [CountDataPoint]
        if let trend = trend, trend.hasData {
            dataPoints = trend.dataPoints
        } else {
            // 創建過去 7 天的空數據點
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let points = (0...6).compactMap { daysAgo -> CountDataPoint? in
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
                return CountDataPoint(date: date, count: 0)
            }
            dataPoints = Array(points.reversed())
        }
        
        return CountBarChart(
            dataPoints: dataPoints,
            title: String(localized: "rankingTrend.past7Days"),
            emptyMessage: trend == nil || !trend!.hasData ? String(localized: "stats.chart.noData") : nil
        )
        .padding(16)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    private func trendChartLoadingPlaceholder() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 220)
            .shimmer()
            .padding(.horizontal, 20)
    }
    
    
    // MARK: - Helper Functions for Stats
    private func getTracks(for type: StatsCardType, stats: AlbumStats) -> [RankedTrack] {
        switch type {
        case .albumShortTerm:
            return stats.shortTermTracks
        case .albumMediumTerm:
            return stats.mediumTermTracks
        case .albumLongTerm:
            return stats.longTermTracks
        case .albumRecent:
            return stats.recentTracks
        default:
            return []
        }
    }
    
    private func getTrackCount(for type: StatsCardType, stats: AlbumStats) -> Int {
        switch type {
        case .albumShortTerm:
            return stats.tracksInShortTerm
        case .albumMediumTerm:
            return stats.tracksInMediumTerm
        case .albumLongTerm:
            return stats.tracksInLongTerm
        case .albumRecent:
            return stats.recentPlayCount
        default:
            return 0
        }
    }
    
    // MARK: - Load Album Stats
    private func loadAlbumStats() {
        isLoadingStats = true
        statsError = nil
        
        SpotifyAuthService.ensureValidAccessToken { token in
            guard let token = token else {
                DispatchQueue.main.async {
                    self.isLoadingStats = false
                    self.statsError = String(localized: "detail.stats.authError", defaultValue: "無法取得統計資料，請重新登入。")
                }
                return
            }
            
            StatsCalculationService.shared.calculateAlbumStats(
                albumId: self.albumId,
                accessToken: token,
                cacheKey: token
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let stats):
                        self.albumStats = stats
                        self.statsError = nil
                    case .failure(let error):
                        self.albumStats = nil
                        self.statsError = error.localizedDescription
                    }
                    self.isLoadingStats = false
                }
            }
            
            // 同時查詢長條圖數據
            self.loadAlbumCountTrend()
        }
    }
    
    // MARK: - Load Album Count Trend
    private func loadAlbumCountTrend() {
        isLoadingTrend = true
        
        // 先獲取用戶資料以取得 userId
        SpotifyAPIService.fetchCurrentUserProfile(accessToken: accessToken) { userProfile in
            guard let userId = userProfile?.id else {
                DispatchQueue.main.async {
                    self.isLoadingTrend = false
                }
                return
            }
            
            // 從 CloudKit 查詢專輯數量趨勢
            CloudKitRankingService.shared.fetchAlbumCountTrend(
                userId: userId,
                albumId: self.albumId,
                timeRange: "short_term"
            ) { trend in
                DispatchQueue.main.async {
                    self.albumCountTrend = trend
                    self.isLoadingTrend = false
                }
            }
        }
    }
    
    // MARK: - Stats Loading Placeholder
    private func statsLoadingPlaceholder() -> some View {
        VStack(spacing: 16) {
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
        .padding(.bottom, 24)
    }
}
