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
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 100)
                    } else if let track = trackDetail {
                        // 專輯封面
                        albumArtSection(track: track)
                        
                        // 基本資訊
                        trackInfoSection(track: track)
                        
                        // 藝人資訊
                        if !artistDetails.isEmpty {
                            artistInfoSection()
                        }
                        
                        // 音訊特徵
                        if let features = audioFeatures {
                            audioFeaturesSection(features: features)
                        }
                        
                        // 在 Spotify 中打開
                        openInSpotifyButton(track: track)
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
        .onAppear {
            refreshAccessTokenAndLoad()
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

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.45),
                            Color.black.opacity(0.01)
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
    
    // MARK: - Track Info Section
    private func trackInfoSection(track: TrackDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // 歌曲名稱
            Text(track.name)
                .font(.custom("SpotifyMix-Bold", size: 32))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
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
            
            // 試聽區塊
            if let previewUrl = track.preview_url {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("home.preview")
                            .font(.custom("SpotifyMix-Bold", size: 20))
                            .foregroundColor(.white)
                        Image(systemName: "music.note")
                            .foregroundColor(.spotifyGreen)
                            .font(.system(size: 20))
                    }
                    
                    Button(action: {
                        audioPlayer.playPreview(from: previewUrl)
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: audioPlayer.isPlaying && audioPlayer.currentPreviewUrl == previewUrl ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
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
