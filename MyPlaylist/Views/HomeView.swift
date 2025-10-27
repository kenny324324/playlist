import SwiftUI

struct HomeView: View {
    @State private var currentlyPlaying: CurrentlyPlayingTrack? = nil
    @State private var recentlyPlayed: [RecentlyPlayedTrack] = []
    @State private var isLoading = true
    @State private var showUserProfile = false
    @State private var refreshRotation: Double = 0
    @ObservedObject var audioPlayer: AudioPlayer
    
    let accessToken: String
    let userProfile: SpotifyUser?
    let logout: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 正在播放區域
                        currentlyPlayingSection
                        
                        // 最近播放區域
                        recentlyPlayedSection
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
    }
    
    private var currentlyPlayingSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("正在播放")
                .font(.custom("SpotifyMix-Bold", size: 20))
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
                        .font(.custom("SpotifyMix-Medium", size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
            }
        }
    }
    
    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("最近播放")
                .font(.custom("SpotifyMix-Bold", size: 20))
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
                        .font(.custom("SpotifyMix-Medium", size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(recentlyPlayed) { item in
                        RecentlyPlayedRow(item: item, audioPlayer: audioPlayer)
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
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
}

struct CurrentlyPlayingCard: View {
    let track: CurrentlyPlayingTrack
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 15) {
            // 專輯封面
            AsyncImageView(
                url: track.album.images.first?.url,
                placeholder: "music.note",
                size: CGSize(width: 80, height: 80),
                cornerRadius: 10
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(track.name)
                    .font(.custom("SpotifyMix-Bold", size: 18))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(track.artists.map(\.name).joined(separator: ", "))
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Text(track.album.name)
                    .font(.custom("SpotifyMix-Medium", size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                if let previewUrl = track.preview_url {
                    Button(action: {
                        audioPlayer.playPreview(from: previewUrl)
                    }) {
                        HStack {
                            Image(systemName: audioPlayer.isPlaying && audioPlayer.currentPreviewUrl == previewUrl ? "pause.fill" : "play.fill")
                            Text("試聽")
                        }
                        .font(.custom("SpotifyMix-Medium", size: 12))
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
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct RecentlyPlayedRow: View {
    let item: RecentlyPlayedTrack
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(
                url: item.track.album.images.first?.url,
                placeholder: "music.note",
                size: CGSize(width: 50, height: 50),
                cornerRadius: 8
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.track.name)
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(item.track.artists.map(\.name).joined(separator: ", "))
                    .font(.custom("SpotifyMix-Medium", size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 歌曲時長
            Text(formatDuration(item.track.duration_ms))
                .font(.custom("SpotifyMix-Medium", size: 12))
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
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
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
        HStack(spacing: 15) {
            // 專輯封面佔位符
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
                .frame(width: 80, height: 80)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 8) {
                // 歌曲名稱佔位符
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 180, height: 18)
                    .shimmer()
                
                // 藝術家佔位符
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 14)
                    .shimmer()
                
                // 專輯佔位符
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 140, height: 12)
                    .shimmer()
                
                // 按鈕佔位符
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 24)
                    .shimmer()
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct RecentlyPlayedPlaceholder: View {
    var body: some View {
        HStack(spacing: 12) {
            // 專輯封面佔位符
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .frame(width: 50, height: 50)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 4) {
                // 歌曲名稱佔位符
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 14)
                    .shimmer()
                
                // 藝術家佔位符
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 12)
                    .shimmer()
            }
            
            Spacer()
            
            // 時長佔位符
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(width: 35, height: 12)
                .shimmer()
            
            // 播放按鈕佔位符
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 30, height: 30)
                .shimmer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
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

#Preview {
    HomeView(audioPlayer: AudioPlayer(), accessToken: "", userProfile: nil, logout: {})
        .preferredColorScheme(.dark)
        .background(Color.spotifyText)
}
