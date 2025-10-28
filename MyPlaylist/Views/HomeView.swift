import SwiftUI

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
        ZStack(alignment: .leading) {
            // 原始文字
            Text(text)
                .font(font)
                .foregroundColor(foregroundColor)
                .lineLimit(lineLimit)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 右側漸層遮罩
            HStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: backgroundColor.opacity(0), location: 0.0),
                        .init(color: backgroundColor.opacity(0.3), location: 0.3),
                        .init(color: backgroundColor.opacity(0.7), location: 0.7),
                        .init(color: backgroundColor, location: 1.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 25)
            }
            .allowsHitTesting(false)
        }
        .frame(height: lineLimit == 1 ? 20 : CGFloat(20 * lineLimit))
    }
}

struct HomeView: View {
    @State private var currentlyPlaying: CurrentlyPlayingTrack? = nil
    @State private var recentlyPlayed: [RecentlyPlayedTrack] = []
    @State private var savedTracks: [SavedTrackItem] = []
    @State private var savedAlbums: [SavedAlbumItem] = []
    @State private var userPlaylists: [Playlist] = []
    @State private var recommendations: [Track] = []
    @State private var newReleases: [Album] = []
    @State private var featuredPlaylists: [Playlist] = []
    @State private var isLoading = true
    @State private var showUserProfile = false
    @State private var refreshRotation: Double = 0
    @State private var showAllRecentlyPlayed = false
    @ObservedObject var audioPlayer: AudioPlayer
    
    let accessToken: String
    let userProfile: SpotifyUser?
    let logout: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 上半部（個人化內容）
                        // 正在播放區域
                        currentlyPlayingSection
                        
                        // 最近收藏的歌曲區域
                        savedTracksSection
                        
                        // 最近收藏的專輯區域
                        savedAlbumsSection
                        
                        // 用戶的播放列表區域
                        userPlaylistsSection
                        
                        // 下半部（發現新音樂）
                        // 最近播放區域
                        recentlyPlayedSection
                        
                        // 為你推薦區域
                        recommendationsSection
                        
                        // 新發行音樂區域
                        newReleasesSection
                        
                        // 精選播放列表區域
                        featuredPlaylistsSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("首頁")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
                            .frame(width: 30, height: 30)
                        }
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                        .sheet(isPresented: $showUserProfile) {
                            UserProfileView(userProfile: user, accessToken: accessToken, logout: logout)
                                .presentationDetents([.medium])
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 刷新按鈕
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            refreshRotation += 360
                        }
                        loadData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .rotationEffect(.degrees(refreshRotation))
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showAllRecentlyPlayed) {
            RecentlyPlayedView(audioPlayer: audioPlayer, accessToken: accessToken)
        }
    }
    
    private var currentlyPlayingSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("正在播放")
                .font(.custom("SpotifyMix-Bold", size: 22))
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
                    Text("目前沒有播放音樂")
                        .font(.custom("SpotifyMix-Medium", size: 18))
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
            Text("最近播放")
                .font(.custom("SpotifyMix-Bold", size: 22))
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
                    Text("暫無播放紀錄")
                        .font(.custom("SpotifyMix-Medium", size: 18))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(recentlyPlayed.prefix(10))) { item in
                        RecentlyPlayedRow(item: item, audioPlayer: audioPlayer)
                    }
                }
                
                // 如果有超過10首，顯示底部的查看更多按鈕
                if recentlyPlayed.count > 10 {
                    Button(action: {
                        showAllRecentlyPlayed = true
                    }) {
                        HStack {
                            Text("查看最近 \(recentlyPlayed.count) 首播放")
                                .font(.custom("SpotifyMix-Medium", size: 16))
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
            Text("最近收藏的歌曲")
                .font(.custom("SpotifyMix-Bold", size: 22))
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
                    Text("暫無收藏歌曲")
                        .font(.custom("SpotifyMix-Medium", size: 18))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(savedTracks.prefix(5)) { item in
                        SavedTrackRow(item: item, audioPlayer: audioPlayer)
                    }
                }
            }
        }
    }
    
    private var savedAlbumsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("最近收藏的專輯")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            if isLoading && savedAlbums.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            AlbumPlaceholder()
                        }
                    }
                }
            } else if savedAlbums.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "square.stack")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("暫無收藏專輯")
                        .font(.custom("SpotifyMix-Medium", size: 18))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(savedAlbums.prefix(10)) { item in
                            AlbumCard(album: item.album)
                        }
                    }
                }
            }
        }
    }
    
    private var userPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("我的播放列表")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            if isLoading && userPlaylists.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            PlaylistPlaceholder()
                        }
                    }
                }
            } else if userPlaylists.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("暫無播放列表")
                        .font(.custom("SpotifyMix-Medium", size: 18))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(userPlaylists.prefix(10)) { playlist in
                            PlaylistCard(playlist: playlist)
                        }
                    }
                }
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("為你推薦")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            if isLoading && recommendations.isEmpty {
                LazyVStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { _ in
                        RecentlyPlayedPlaceholder()
                    }
                }
            } else if recommendations.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("暫無推薦")
                        .font(.custom("SpotifyMix-Medium", size: 18))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(recommendations.prefix(5)) { track in
                        RecommendationRow(track: track, audioPlayer: audioPlayer)
                    }
                }
            }
        }
    }
    
    private var newReleasesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("新發行音樂")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            if isLoading && newReleases.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            AlbumPlaceholder()
                        }
                    }
                }
            } else if newReleases.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("暫無新發行")
                        .font(.custom("SpotifyMix-Medium", size: 18))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(newReleases.prefix(10)) { album in
                            AlbumCard(album: album)
                        }
                    }
                }
            }
        }
    }
    
    private var featuredPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("精選播放列表")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            if isLoading && featuredPlaylists.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            PlaylistPlaceholder()
                        }
                    }
                }
            } else if featuredPlaylists.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "star")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("暫無精選")
                        .font(.custom("SpotifyMix-Medium", size: 18))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(16)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(15)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(featuredPlaylists.prefix(10)) { playlist in
                            PlaylistCard(playlist: playlist)
                        }
                    }
                }
            }
        }
    }
    
    private func loadData() {
        isLoading = true
        
        let group = DispatchGroup()
        
        // 獲取正在播放的歌曲
        group.enter()
        SpotifyAPIService.fetchCurrentlyPlaying(accessToken: accessToken) { track in
            DispatchQueue.main.async {
                self.currentlyPlaying = track
                group.leave()
            }
        }
        
        // 獲取最近播放的歌曲
        group.enter()
        SpotifyAPIService.fetchRecentlyPlayed(accessToken: accessToken) { tracks in
            DispatchQueue.main.async {
                self.recentlyPlayed = tracks
                group.leave()
            }
        }
        
        // 獲取收藏的歌曲
        group.enter()
        SpotifyAPIService.fetchSavedTracks(accessToken: accessToken, limit: 10) { tracks in
            DispatchQueue.main.async {
                self.savedTracks = tracks
                group.leave()
            }
        }
        
        // 獲取收藏的專輯
        group.enter()
        SpotifyAPIService.fetchSavedAlbums(accessToken: accessToken, limit: 10) { albums in
            DispatchQueue.main.async {
                self.savedAlbums = albums
                group.leave()
            }
        }
        
        // 獲取用戶播放列表
        group.enter()
        SpotifyAPIService.fetchUserPlaylists(accessToken: accessToken) { playlists in
            DispatchQueue.main.async {
                self.userPlaylists = playlists
                group.leave()
            }
        }
        
        // 獲取推薦歌曲
        group.enter()
        SpotifyAPIService.fetchRecommendations(accessToken: accessToken, limit: 10) { tracks in
            DispatchQueue.main.async {
                self.recommendations = tracks
                group.leave()
            }
        }
        
        // 獲取新發行音樂
        group.enter()
        SpotifyAPIService.fetchNewReleases(accessToken: accessToken, limit: 10) { albums in
            DispatchQueue.main.async {
                self.newReleases = albums
                group.leave()
            }
        }
        
        // 獲取精選播放列表
        group.enter()
        SpotifyAPIService.fetchFeaturedPlaylists(accessToken: accessToken, limit: 10) { playlists in
            DispatchQueue.main.async {
                self.featuredPlaylists = playlists
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
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
                    font: .custom("SpotifyMix-Bold", size: 20),
                    foregroundColor: .white,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12),
                    lineLimit: 2
                )
                
                HomeFadingText(
                    text: track.artists.map(\.name).joined(separator: ", "),
                    font: .custom("SpotifyMix-Medium", size: 16),
                    foregroundColor: .gray,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
                
                HomeFadingText(
                    text: track.album.name,
                    font: .custom("SpotifyMix-Medium", size: 14),
                    foregroundColor: .gray,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
                
                if let previewUrl = track.preview_url {
                    Button(action: {
                        audioPlayer.playPreview(from: previewUrl)
                    }) {
                        HStack {
                            Image(systemName: audioPlayer.isPlaying && audioPlayer.currentPreviewUrl == previewUrl ? "pause.fill" : "play.fill")
                            Text("試聽")
                        }
                        .font(.custom("SpotifyMix-Medium", size: 14))
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
                    font: .custom("SpotifyMix-Medium", size: 16),
                    foregroundColor: .white,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
                
                HomeFadingText(
                    text: item.track.artists.map(\.name).joined(separator: ", "),
                    font: .custom("SpotifyMix-Medium", size: 14),
                    foregroundColor: .gray,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
            }
            
            Spacer()
            
            // 歌曲時長
            Text(formatDuration(item.track.duration_ms))
                .font(.custom("SpotifyMix-Medium", size: 14))
                .foregroundColor(.gray)
            
            if let previewUrl = item.track.preview_url {
                Button(action: {
                    audioPlayer.playPreview(from: previewUrl)
                }) {
                    Image(systemName: audioPlayer.isPlaying && audioPlayer.currentPreviewUrl == previewUrl ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.spotifyGreen)
                        .clipShape(Circle())
                }
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

// MARK: - Shimmer Effect
extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
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
                    font: .custom("SpotifyMix-Medium", size: 16),
                    foregroundColor: .white,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
                
                HomeFadingText(
                    text: item.track.artists.map(\.name).joined(separator: ", "),
                    font: .custom("SpotifyMix-Medium", size: 14),
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
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.spotifyGreen)
                        .clipShape(Circle())
                }
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
            
            Text(album.name)
                .font(.custom("SpotifyMix-Medium", size: 14))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
            
            Text(album.artists.map(\.name).joined(separator: ", "))
                .font(.custom("SpotifyMix-Medium", size: 12))
                .foregroundColor(.gray)
                .lineLimit(1)
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
            
            Text(playlist.name)
                .font(.custom("SpotifyMix-Medium", size: 14))
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 140, alignment: .leading)
        }
    }
}

struct RecommendationRow: View {
    let track: Track
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 6) {
            AsyncImage(url: URL(string: track.album.images.first?.url ?? "")) { phase in
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
                    text: track.name,
                    font: .custom("SpotifyMix-Medium", size: 16),
                    foregroundColor: .white,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
                
                HomeFadingText(
                    text: track.artists.map(\.name).joined(separator: ", "),
                    font: .custom("SpotifyMix-Medium", size: 14),
                    foregroundColor: .gray,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
            }
            
            Spacer()
            
            if let previewUrl = track.previewUrl {
                Button(action: {
                    audioPlayer.playPreview(from: previewUrl)
                }) {
                    Image(systemName: audioPlayer.isPlaying && audioPlayer.currentPreviewUrl == previewUrl ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.spotifyGreen)
                        .clipShape(Circle())
                }
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

//#Preview {
//    HomeView(audioPlayer: AudioPlayer(), accessToken: "", userProfile: nil, logout: {})
//        .preferredColorScheme(.dark)
//        .background(Color.spotifyText)
//}
