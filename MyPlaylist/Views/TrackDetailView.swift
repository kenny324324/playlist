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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let track = trackDetail {
                    // 專輯封面
                    albumArtSection(track: track)
                    
                    // 基本資訊
                    trackInfoSection(track: track)
                    
                    // 音訊特徵
                    if let features = audioFeatures {
                        audioFeaturesSection(features: features)
                    }
                    
                    // 藝人資訊
                    if !artistDetails.isEmpty {
                        artistInfoSection()
                    }
                } else {
                    Text("無法載入歌曲資訊")
                        .foregroundColor(.gray)
                        .padding(.top, 100)
                }
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationTitle("歌曲資訊")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshAccessTokenAndLoad()
        }
    }
    
    // MARK: - Album Art Section
    private func albumArtSection(track: TrackDetail) -> some View {
        VStack(spacing: 16) {
            if let imageUrl = track.album.images.first?.url,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(width: 280, height: 280)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            }
        }
        .padding(.top, 30)
        .padding(.bottom, 20)
    }
    
    // MARK: - Track Info Section
    private func trackInfoSection(track: TrackDetail) -> some View {
        VStack(spacing: 20) {
            // 歌曲名稱
            Text(track.name)
                .font(.custom("SpotifyMix-Bold", size: 26))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 藝人名稱
            Text(track.artists.map(\.name).joined(separator: ", "))
                .font(.custom("SpotifyMix-Medium", size: 18))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 試聽按鈕
            if let previewUrl = track.preview_url {
                Button(action: {
                    audioPlayer.playPreview(from: previewUrl)
                }) {
                    HStack {
                        Image(systemName: audioPlayer.isPlaying && audioPlayer.currentPreviewUrl == previewUrl ? "pause.fill" : "play.fill")
                            .font(.system(size: 18))
                        Text(audioPlayer.isPlaying && audioPlayer.currentPreviewUrl == previewUrl ? "暫停" : "試聽")
                            .font(.custom("SpotifyMix-Bold", size: 16))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.spotifyGreen)
                    .cornerRadius(25)
                }
                .padding(.vertical, 10)
            }
            
            // 基本資訊卡片
            VStack(spacing: 0) {
                InfoRow(label: "專輯", value: track.album.name)
                Divider().background(Color.gray.opacity(0.3))
                
                if let releaseDate = track.album.release_date {
                    InfoRow(label: "發行日期", value: formatReleaseDate(releaseDate))
                    Divider().background(Color.gray.opacity(0.3))
                }
                
                InfoRow(label: "曲目編號", value: "\(track.track_number) / \(track.album.total_tracks)")
                Divider().background(Color.gray.opacity(0.3))
                
                InfoRow(label: "時長", value: formatDuration(track.duration_ms))
                Divider().background(Color.gray.opacity(0.3))
                
                InfoRow(label: "人氣", value: "\(track.popularity) / 100")
                Divider().background(Color.gray.opacity(0.3))
                
                InfoRow(label: "露骨內容", value: track.explicit ? "是" : "否")
            }
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Audio Features Section
    private func audioFeaturesSection(features: AudioFeatures) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("音訊特徵")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                AudioFeatureBar(label: "舞動性", value: features.danceability, color: .green)
                Divider().background(Color.gray.opacity(0.3))
                
                AudioFeatureBar(label: "能量", value: features.energy, color: .red)
                Divider().background(Color.gray.opacity(0.3))
                
                AudioFeatureBar(label: "愉悅度", value: features.valence, color: .yellow)
                Divider().background(Color.gray.opacity(0.3))
                
                AudioFeatureBar(label: "聲樂", value: features.speechiness, color: .blue)
                Divider().background(Color.gray.opacity(0.3))
                
                AudioFeatureBar(label: "原聲", value: features.acousticness, color: .orange)
                Divider().background(Color.gray.opacity(0.3))
                
                AudioFeatureBar(label: "器樂", value: features.instrumentalness, color: .purple)
                Divider().background(Color.gray.opacity(0.3))
                
                AudioFeatureBar(label: "現場", value: features.liveness, color: .pink)
            }
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // 音樂理論資訊
            VStack(spacing: 0) {
                InfoRow(label: "節奏 (BPM)", value: String(format: "%.0f", features.tempo))
                Divider().background(Color.gray.opacity(0.3))
                
                InfoRow(label: "調性", value: "\(features.keyString) \(features.modeString)")
                Divider().background(Color.gray.opacity(0.3))
                
                InfoRow(label: "拍號", value: "\(features.time_signature)/4")
                Divider().background(Color.gray.opacity(0.3))
                
                InfoRow(label: "響度", value: String(format: "%.1f dB", features.loudness))
            }
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Artist Info Section
    private func artistInfoSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("藝人資訊")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ForEach(artistDetails, id: \.id) { artist in
                VStack(spacing: 12) {
                    // 藝人圖片
                    if let imageUrl = artist.images.first?.url,
                       let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 40))
                                )
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    }
                    
                    // 藝人名稱
                    Text(artist.name)
                        .font(.custom("SpotifyMix-Bold", size: 20))
                        .foregroundColor(.white)
                    
                    // 藝人資訊
                    VStack(spacing: 0) {
                        InfoRow(label: "追蹤數", value: "\(artist.followers.total.formatted())")
                        Divider().background(Color.gray.opacity(0.3))
                        
                        InfoRow(label: "人氣", value: "\(artist.popularity) / 100")
                        
                        if !artist.genres.isEmpty {
                            Divider().background(Color.gray.opacity(0.3))
                            HStack {
                                Text("流派")
                                    .font(.custom("SpotifyMix-Medium", size: 16))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(artist.genres.prefix(3).joined(separator: ", "))
                                    .font(.custom("SpotifyMix-Medium", size: 16))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                    .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
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
        }
    }
    
    private func refreshAccessTokenAndLoad() {
        isLoading = true
        SpotifyAuthService.ensureValidAccessToken { token in
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
        
        // 嘗試不同的日期格式
        if dateString.count == 4 {
            // 只有年份
            return dateString
        } else if dateString.count == 7 {
            // YYYY-MM 格式
            formatter.dateFormat = "yyyy-MM"
            if let date = formatter.date(from: dateString) {
                formatter.dateFormat = "yyyy 年 M 月"
                return formatter.string(from: date)
            }
        } else {
            // 完整日期
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                formatter.dateFormat = "yyyy 年 M 月 d 日"
                return formatter.string(from: date)
            }
        }
        
        return dateString
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
