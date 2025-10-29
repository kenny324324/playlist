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
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let artist = artistDetail {
                    // 藝人照片
                    artistImageSection(artist: artist)
                    
                    // 藝人資訊
                    artistInfoSection(artist: artist)
                    
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
                    Text("detail.cannotLoad.artist")
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
    
    // MARK: - Artist Image Section
    private func artistImageSection(artist: ArtistDetail) -> some View {
        GeometryReader { geometry in
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
                            ProgressView()
                        )
                }
                .frame(width: geometry.size.width, height: geometry.size.width)
                .clipped()
            }
        }
        .frame(height: UIScreen.main.bounds.width)
    }
    
    // MARK: - Artist Info Section
    private func artistInfoSection(artist: ArtistDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // 藝人名稱
            Text(artist.name)
                .font(.custom("SpotifyMix-Bold", size: 32))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            // 人氣和粉絲數卡片
            HStack(spacing: 12) {
                // 人氣卡片
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", Double(artist.popularity) / 10.0))
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
                
                // 粉絲數卡片
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatFollowers(artist.followers.total))
                        .font(.custom("SpotifyMix-Bold", size: 22))
                        .foregroundColor(.spotifyGreen)
                    Text("detail.followers")
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
            
            // 流派
            if !artist.genres.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("detail.genres")
                        .font(.custom("SpotifyMix-Bold", size: 20))
                        .foregroundColor(.white)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(artist.genres, id: \.self) { genre in
                            Text(genre)
                                .font(.custom("SpotifyMix-Medium", size: 14))
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
                .font(.custom("SpotifyMix-Bold", size: 20))
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
                            .font(.custom("SpotifyMix-Bold", size: 14))
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
        .sheet(isPresented: $showAllTracks) {
            allTracksSheet()
        }
    }
    
    private func trackRowView(track: ArtistTopTrack, index: Int) -> some View {
        HStack(spacing: 12) {
            // 排名
            Text("\(index + 1)")
                .font(.custom("SpotifyMix-Bold", size: 18))
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
    
    // MARK: - Albums Section
    private func albumsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top albums")
                .font(.custom("SpotifyMix-Bold", size: 20))
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
                            .font(.custom("SpotifyMix-Bold", size: 14))
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
            
            // 專輯資訊
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.custom("SpotifyMix-Bold", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(album.artists.map { $0.name }.joined(separator: ", "))
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
    
    // MARK: - Open in Spotify Button
    private func openInSpotifyButton(artist: ArtistDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("detail.externalLinks")
                .font(.custom("SpotifyMix-Bold", size: 20))
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
                Color.black.ignoresSafeArea()
                
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
                Color.black.ignoresSafeArea()
                
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

