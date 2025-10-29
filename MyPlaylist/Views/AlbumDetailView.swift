import SwiftUI

struct AlbumDetailView: View {
    let albumId: String
    let albumName: String
    let accessToken: String
    @ObservedObject var audioPlayer: AudioPlayer
    
    @State private var albumDetail: AlbumDetail?
    @State private var artistDetails: [ArtistDetail] = []
    @State private var isLoading = true
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let album = albumDetail {
                    // 專輯封面
                    albumCoverSection(album: album)
                    
                    // 專輯資訊
                    albumInfoSection(album: album)
                    
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
                    Text("detail.cannotLoad.album")
                        .foregroundColor(.gray)
                        .padding(.top, 100)
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
    
    // MARK: - Album Cover Section
    private func albumCoverSection(album: AlbumDetail) -> some View {
        GeometryReader { geometry in
            if let imageUrl = album.images.first?.url,
               let url = URL(string: imageUrl) {
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
            }
        }
        .frame(height: UIScreen.main.bounds.width)
    }
    
    // MARK: - Album Info Section
    private func albumInfoSection(album: AlbumDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // 專輯名稱
            Text(album.name)
                .font(.custom("SpotifyMix-Bold", size: 32))
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
                            .font(.custom("SpotifyMix-Bold", size: 22))
                            .foregroundColor(.spotifyGreen)
                        Text("detail.track")
                            .font(.custom("SpotifyMix-Medium", size: 12))
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
                    }
                }
                
                HStack(spacing: 12) {
                    // Type of album 卡片
                    VStack(alignment: .leading, spacing: 4) {
                        Text(album.album_type.capitalized)
                            .font(.custom("SpotifyMix-Bold", size: 22))
                            .foregroundColor(.spotifyGreen)
                        Text("detail.typeOfAlbum")
                            .font(.custom("SpotifyMix-Medium", size: 12))
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
                            .font(.custom("SpotifyMix-Bold", size: 22))
                            .foregroundColor(.spotifyGreen)
                        Text("detail.releaseDate")
                            .font(.custom("SpotifyMix-Medium", size: 12))
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
                .font(.custom("SpotifyMix-Bold", size: 20))
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
        .padding(.bottom, 30)
    }
    
    private func trackRowView(track: AlbumTrack, album: AlbumDetail) -> some View {
        HStack(spacing: 12) {
            // 曲目編號
            Text("\(track.track_number)")
                .font(.custom("SpotifyMix-Bold", size: 18))
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
                    .font(.custom("SpotifyMix-Bold", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artists.map { $0.name }.joined(separator: ", "))
                    .font(.custom("SpotifyMix-Medium", size: 14))
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
    private func openInSpotifyButton(album: AlbumDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("detail.externalLinks")
                .font(.custom("SpotifyMix-Bold", size: 20))
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
}

