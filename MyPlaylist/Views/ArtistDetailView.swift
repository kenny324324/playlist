import SwiftUI

struct ArtistDetailView: View {
    let artistId: String
    let artistName: String
    let accessToken: String
    @ObservedObject var audioPlayer: AudioPlayer
    
    @State private var artistDetail: ArtistDetail?
    @State private var topTracks: [ArtistTopTrack] = []
    @State private var albums: [ArtistAlbum] = []
    @State private var isLoading = true
    @State private var showAllTracks = false
    @State private var showAllAlbums = false
    @State private var selectedTab: DetailTab = .info
    @State private var artistStats: ArtistStats?
    @State private var statsError: String?
    @State private var isLoadingStats = false
    
    // 長條圖數據
    @State private var artistCountTrend: ArtistCountTrend?
    @State private var isLoadingTrend = false
    
    // Sheet 控制狀態
    @State private var selectedStatsType: StatsCardType?
    
    // 使用者資訊 / Token
    @State private var currentUserId: String?
    @State private var resolvedAccessToken: String?
    
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
                        artistDetailPlaceholder()
                    } else if let artist = artistDetail {
                        // 藝人照片
                        artistImageSection(artist: artist)
                        
                        // 分頁選擇器
                        tabSelector
                            .offset(y: -10)
                        
                        // 藝人名稱（兩個分頁都顯示）
                        artistTitleSection(artist: artist)
                            .offset(y: -10)
                        
                        // 根據選擇的分頁顯示內容
                        VStack(spacing: 0) {
                            if selectedTab == .info {
                                // Info 分頁內容
                                artistInfoCardsSection(artist: artist)
                                
                                // 熱門歌曲
                                if !topTracks.isEmpty {
                                    topTracksSection()
                                }
                                
                                // 熱門專輯
                                if !albums.isEmpty {
                                    albumsSection()
                                }
                                
                                // 在 Spotify 中打開
                                openInSpotifyButton(artist: artist)
                            } else {
                                // Stats 分頁內容
                                if let stats = artistStats {
                                    artistStatsSection(stats: stats, artistName: artist.name)
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
                        Text("detail.cannotLoad.artist")
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
            // 記錄顯著事件（查看藝人詳情）
            AppRatingManager.shared.recordEvent(.viewedArtistDetail)
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
                if newTab == .stats && artistStats == nil && !isLoadingStats {
                    loadArtistStats()
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
    
    // MARK: - Artist Title Section
    private func artistTitleSection(artist: ArtistDetail) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(artist.name)
                .font(.appFont(size: 32, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Artist Info Cards Section (不含藝人名稱)
    private func artistInfoCardsSection(artist: ArtistDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // 人氣和粉絲數卡片
            HStack(spacing: 12) {
                // 人氣卡片
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", Double(artist.popularity) / 10.0))
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
                
                // 粉絲數卡片
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatFollowers(artist.followers.total))
                        .font(.appFont(size: 22, weight: .bold))
                        .foregroundColor(.spotifyGreen)
                    Text("detail.followers")
                        .font(.appFont(size: 12, weight: .medium))
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
            
            // 流派
            if !artist.genres.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("detail.genres")
                        .font(.appFont(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(artist.genres.prefix(10), id: \.self) { genre in
                            Text(genre)
                                .font(.appFont(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.spotifyGreen.opacity(0.2))
                                .foregroundColor(.spotifyGreen)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Artist Image Section
    private func artistImageSection(artist: ArtistDetail) -> some View {
        GeometryReader { geometry in
            if let imageUrl = artist.images.first?.url,
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
    
    // MARK: - Artist Info Section
    private func artistInfoSection(artist: ArtistDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // 藝人名稱
            Text(artist.name)
                .font(.appFont(size: 32, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            // 人氣和粉絲數卡片
            HStack(spacing: 12) {
                // 人氣卡片
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", Double(artist.popularity) / 10.0))
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
                
                // 粉絲數卡片
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatFollowers(artist.followers.total))
                        .font(.appFont(size: 22, weight: .bold))
                        .foregroundColor(.spotifyGreen)
                    Text("detail.followers")
                        .font(.appFont(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            // 流派
            if !artist.genres.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("detail.genres")
                        .font(.appFont(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(artist.genres, id: \.self) { genre in
                            Text(genre)
                                .font(.appFont(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Top Tracks Section
    private func topTracksSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("detail.topTracks")
                .font(.appFont(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                ForEach(Array(topTracks.prefix(2).enumerated()), id: \.element.id) { index, track in
                    NavigationLink(destination: TrackDetailView(trackId: track.id, accessToken: accessToken, audioPlayer: audioPlayer)) {
                        trackRowView(track: track, index: index)
                    }
                }
            }
            
            // View more button
            if topTracks.count > 2 {
                Button(action: {
                    showAllTracks = true
                }) {
                    HStack(spacing: 6) {
                        Text("View more")
                            .font(.appFont(size: 14, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 30)
        .sheet(isPresented: $showAllTracks) {
            allTracksSheet()
        }
    }
    
    private func trackRowView(track: ArtistTopTrack, index: Int) -> some View {
        HStack(spacing: 12) {
            // 排名
            Text("\(index + 1)")
                .font(.appFont(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, alignment: .center)
            
            // 專輯封面
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
    
    // MARK: - Albums Section
    private func albumsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top albums")
                .font(.appFont(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                ForEach(Array(albums.prefix(2).enumerated()), id: \.element.id) { index, album in
                    NavigationLink(destination: AlbumDetailView(albumId: album.id, albumName: album.name, accessToken: accessToken, audioPlayer: audioPlayer)) {
                        albumRowView(album: album, index: index)
                    }
                }
            }
            
            // View more button
            if albums.count > 2 {
                Button(action: {
                    showAllAlbums = true
                }) {
                    HStack(spacing: 6) {
                        Text("View more")
                            .font(.appFont(size: 14, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .padding(.bottom, 30)
        .sheet(isPresented: $showAllAlbums) {
            allAlbumsSheet()
        }
    }
    
    private func albumRowView(album: ArtistAlbum, index: Int) -> some View {
        HStack(spacing: 12) {
            // 排名
            Text("\(index + 1)")
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
            
            // 專輯資訊
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(album.artists.map { $0.name }.joined(separator: ", "))
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
    
    // MARK: - Open in Spotify Button
    private func openInSpotifyButton(artist: ArtistDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("detail.externalLinks")
                .font(.appFont(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            Button(action: {
                if let url = URL(string: artist.uri) {
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
                self.resolvedAccessToken = token
                loadArtistDetails(with: token)
            }
        }
    }
    
    private func loadArtistDetails(with token: String) {
        // 同時獲取所有資料
        let group = DispatchGroup()
        
        // 獲取藝人詳細資訊
        group.enter()
        SpotifyAPIService.fetchArtistDetail(artistId: artistId, accessToken: token) { detail in
            DispatchQueue.main.async {
                self.artistDetail = detail
                group.leave()
            }
        }
        
        // 獲取熱門歌曲
        group.enter()
        SpotifyAPIService.fetchArtistTopTracks(artistId: artistId, accessToken: token) { tracks in
            DispatchQueue.main.async {
                self.topTracks = tracks
                group.leave()
            }
        }
        
        // 獲取專輯
        group.enter()
        SpotifyAPIService.fetchArtistAlbums(artistId: artistId, accessToken: token) { albums in
            DispatchQueue.main.async {
                self.albums = albums
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    private func formatFollowers(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000.0)
        }
        return "\(count)"
    }
    
    // MARK: - Sheet Views
    private func allTracksSheet() -> some View {
        NavigationView {
            ZStack {
                Color.spotifyText.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(topTracks.enumerated()), id: \.element.id) { index, track in
                            NavigationLink(destination: TrackDetailView(trackId: track.id, accessToken: accessToken, audioPlayer: audioPlayer)) {
                                trackRowView(track: track, index: index)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Top Tracks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showAllTracks = false
                    }
                    .foregroundColor(.spotifyGreen)
                }
            }
        }
    }
    
    private func allAlbumsSheet() -> some View {
        NavigationView {
            ZStack {
                Color.spotifyText.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(albums.enumerated()), id: \.element.id) { index, album in
                            NavigationLink(destination: AlbumDetailView(albumId: album.id, albumName: album.name, accessToken: accessToken, audioPlayer: audioPlayer)) {
                                albumRowView(album: album, index: index)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Top Albums")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showAllAlbums = false
                    }
                    .foregroundColor(.spotifyGreen)
                }
            }
        }
    }
    
    // MARK: - Placeholder
    private func artistDetailPlaceholder() -> some View {
        VStack(spacing: 0) {
            // 藝人照片佔位符
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: UIScreen.main.bounds.width)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 24) {
                // 藝人名稱佔位符
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
                
                // 風格標籤佔位符
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 24)
                        .shimmer()
                    
                    VStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { _ in
                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: CGFloat.random(in: 60...100), height: 32)
                                        .shimmer()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 熱門歌曲佔位符
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
                
                // 熱門專輯佔位符
                VStack(alignment: .leading, spacing: 16) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 24)
                        .shimmer()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { _ in
                                VStack(alignment: .leading, spacing: 8) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 150, height: 150)
                                        .shimmer()
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 120, height: 16)
                                        .shimmer()
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 80, height: 14)
                                        .shimmer()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 10)
                
                Spacer()
                    .frame(height: 100)
            }
        }
    }
    
    // MARK: - Artist Stats Section
    private func artistStatsSection(stats: ArtistStats, artistName: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 長條圖（移到上面）
            if isLoadingTrend {
                trendChartLoadingPlaceholder()
            } else {
                trendChartSection(trend: artistCountTrend)
            }
            
            // 統計卡片（移到下面）
            VStack(spacing: 16) {
                // 第一行：4週 + 6個月
                HStack(spacing: 12) {
                SmallStatCard(
                    number: "\(stats.tracksInShortTerm)",
                    text: "\(stats.tracksInShortTerm) \(String(localized: "stats.artist.tracksOf")) \(artistName) \(String(localized: "stats.album.inTop50.4weeks"))",
                    highlightWord: artistName,
                    onTap: {
                        presentArtistStats(type: .artistShortTerm)
                    }
                )
                
                SmallStatCard(
                    number: "\(stats.tracksInMediumTerm)",
                    text: "\(stats.tracksInMediumTerm) \(String(localized: "stats.artist.tracksOf")) \(artistName) \(String(localized: "stats.album.inTop50.6months"))",
                    highlightWord: artistName,
                    onTap: {
                        presentArtistStats(type: .artistMediumTerm)
                    }
                )
            }
            
            // 第二行：所有時間 + 最近50次
            HStack(spacing: 12) {
                SmallStatCard(
                    number: "\(stats.tracksInLongTerm)",
                    text: "\(stats.tracksInLongTerm) \(String(localized: "stats.artist.tracksOf")) \(artistName) \(String(localized: "stats.album.inTop50.allTime"))",
                    highlightWord: artistName,
                    onTap: {
                        presentArtistStats(type: .artistLongTerm)
                    }
                )
                
                SmallStatCard(
                    number: "\(stats.recentPlayCount)",
                    text: "\(stats.recentPlayCount) \(String(localized: "stats.artist.tracksBy")) \(artistName) \(String(localized: "stats.artist.appearedInLast50"))",
                    highlightWord: artistName,
                    onTap: {
                        presentArtistStats(type: .artistRecent)
                    }
                )
            }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 24)
        .padding(.bottom, 30)
        .sheet(item: $selectedStatsType) { statsType in
            if let stats = artistStats, let artist = artistDetail {
                StatsDetailSheet(
                    title: statsType.getTitle(name: artist.name),
                    subtitle: statsType.getSubtitle(name: artist.name, count: getTrackCount(for: statsType, stats: stats)),
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
    
    private func presentArtistStats(type: StatsCardType) {
        guard artistStats != nil, artistDetail != nil else {
            return
        }
        selectedStatsType = type
    }
    
    // MARK: - Trend Chart Section
    
    private func trendChartSection(trend: ArtistCountTrend?) -> some View {
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
    private func getTracks(for type: StatsCardType, stats: ArtistStats) -> [RankedTrack] {
        switch type {
        case .artistShortTerm:
            return stats.shortTermTracks
        case .artistMediumTerm:
            return stats.mediumTermTracks
        case .artistLongTerm:
            return stats.longTermTracks
        case .artistRecent:
            return stats.recentTracks
        default:
            return []
        }
    }
    
    private func getTrackCount(for type: StatsCardType, stats: ArtistStats) -> Int {
        switch type {
        case .artistShortTerm:
            return stats.tracksInShortTerm
        case .artistMediumTerm:
            return stats.tracksInMediumTerm
        case .artistLongTerm:
            return stats.tracksInLongTerm
        case .artistRecent:
            return stats.recentPlayCount
        default:
            return 0
        }
    }
    
    // MARK: - Load Artist Stats
    private func loadArtistStats() {
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
            
            self.resolvedAccessToken = token
            let cacheIdentifier = self.currentUserId ?? token
            
            StatsCalculationService.shared.calculateArtistStats(
                artistId: self.artistId,
                accessToken: token,
                cacheKey: cacheIdentifier
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let stats):
                        self.artistStats = stats
                        self.statsError = nil
                        
                        let combinedTracks = stats.shortTermTracks + stats.mediumTermTracks + stats.longTermTracks
                        let fallbackTrackIds = Set(combinedTracks.map { $0.trackId })
                        self.loadArtistCountTrend(fallbackTrackIds: fallbackTrackIds)
                    case .failure(let error):
                        self.artistStats = nil
                        self.statsError = error.localizedDescription
                    }
                    self.isLoadingStats = false
                }
            }
            
            // 同時查詢長條圖數據
            self.loadArtistCountTrend()
        }
    }
    
    // MARK: - Load Artist Count Trend
    private func loadArtistCountTrend(fallbackTrackIds: Set<String>? = nil) {
        isLoadingTrend = true
        
        ensureUserId { userId in
            guard let userId = userId else {
                DispatchQueue.main.async {
                    self.isLoadingTrend = false
                }
                return
            }
            
            CloudKitRankingService.shared.fetchArtistCountTrend(
                userId: userId,
                artistId: self.artistId,
                timeRange: "short_term",
                fallbackTrackIds: fallbackTrackIds
            ) { trend in
                DispatchQueue.main.async {
                    self.artistCountTrend = trend
                    self.isLoadingTrend = false
                }
            }
        }
    }
    
    private func ensureUserId(completion: @escaping (String?) -> Void) {
        if let cachedId = currentUserId {
            completion(cachedId)
            return
        }
        
        guard let tokenToUse = resolvedAccessToken ?? (accessToken.isEmpty ? nil : accessToken) else {
            completion(nil)
            return
        }
        
        SpotifyAPIService.fetchCurrentUserProfile(accessToken: tokenToUse) { userProfile in
            DispatchQueue.main.async {
                if let id = userProfile?.id {
                    self.currentUserId = id
                }
                completion(userProfile?.id)
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

// MARK: - FlowLayout Helper
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
