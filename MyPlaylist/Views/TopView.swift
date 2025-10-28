import SwiftUI

struct TopView: View {
    @ObservedObject var audioPlayer: AudioPlayer
    var userProfile: SpotifyUser?
    let logout: () -> Void
    let accessToken: String
    
    @State private var selectedContentType: ContentType = .tracks
    @State private var selectedTimeRange: TimeRange = .shortTerm
    
    @State private var tracks: [Track] = []
    @State private var artists: [Artist] = []
    @State private var genres: [String: Int] = [:]
    
    @State private var showPlayer = false
    @State private var selectedTrack: Track? = nil
    @State private var showUserProfile = false
    @State private var isLoading = false
    
    enum ContentType: String, CaseIterable {
        case tracks = "Tracks"
        case artists = "Artists"
        case genres = "Genres"
        
        var title: String {
            return self.rawValue
        }
    }
    
    enum TimeRange: String, CaseIterable {
        case shortTerm = "short_term"
        case mediumTerm = "medium_term"
        case longTerm = "long_term"
        
        var title: String {
            switch self {
            case .shortTerm: return "1 Month"
            case .mediumTerm: return "6 Months"
            case .longTerm: return "All Time"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 上方類型選擇 Tab
                contentTypeSelector
                
                // 主要內容區域
                contentView
                
                // 下方時間選擇 Tab
                timeRangeSelector
                
                // 播放器功能已移除
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Made by Kenny")
                        .font(.custom("SpotifyMix-Medium", size: 14))
                        .foregroundColor(.gray)
                        .opacity(0.7)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    userProfileButton
                }
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private var contentTypeSelector: some View {
        HStack(spacing: 0) {
            ForEach(ContentType.allCases, id: \.self) { type in
                Button(action: {
                    selectedContentType = type
                    loadData()
                }) {
                    VStack(spacing: 8) {
                        Text(type.title)
                            .font(.custom("SpotifyMix-Medium", size: 18))
                            .foregroundColor(selectedContentType == type ? Color.spotifyGreen : .gray)
                        
                        Rectangle()
                            .fill(selectedContentType == type ? Color.spotifyGreen : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 5) {
                if isLoading {
                    // 顯示載入中的佔位符
                    ForEach(0..<8, id: \.self) { index in
                        loadingPlaceholder(index: index + 1)
                    }
                } else {
                    switch selectedContentType {
                    case .tracks:
                        tracksContent
                    case .artists:
                        artistsContent
                    case .genres:
                        genresContent
                    }
                }
            }
            .padding(.top, 20)
        }
    }
    
    private var tracksContent: some View {
        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
            TrackRow(
                track: track,
                index: index + 1,
                audioPlayer: audioPlayer,
                selectedTrack: $selectedTrack,
                showPlayer: $showPlayer
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 5)
        }
    }
    
    private var artistsContent: some View {
        Group {
            if artists.isEmpty {
                EmptyView()
            } else {
                ForEach(Array(artists.enumerated()), id: \.element.id) { index, artist in
                    ArtistRow(artist: artist, index: index + 1)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 5)
                }
                if artists.count < 8 {
                    ForEach(artists.count..<8, id: \.self) { index in
                        emptyArtistRow(index: index + 1)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 5)
                    }
                }
            }
        }
    }
    
    private var genresContent: some View {
        ForEach(Array(sortedGenres().enumerated()), id: \.element.key) { index, genreData in
            let (genre, count) = genreData
            GenreRow(index: index + 1, genre: genre, count: count)
        }
    }
    
    private var timeRangeSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    selectedTimeRange = range
                    loadData()
                }) {
                    Text(range.title)
                        .font(.custom("SpotifyMix-Medium", size: 15))
                        .foregroundColor(selectedTimeRange == range ? Color.spotifyGreen : .white.opacity(0.7))
                        .frame(minWidth: 64)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 14)
                        .background(
                            selectedTimeRange == range ? Color.white.opacity(0.18) : Color.clear
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(3)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 40)
        .padding(.bottom, 18)
        .offset(y: -10)
    }
    
    private var userProfileButton: some View {
        Group {
            if let user = userProfile,
               let imageUrl = user.images?.first?.url {
                Button(action: {
                    showUserProfile = true
                }) {
                    AsyncImageView(
                        url: imageUrl,
                        placeholder: "person.fill",
                        size: CGSize(width: 30, height: 30),
                        cornerRadius: 15,
                        isCircle: true
                    )
                }
                .sheet(isPresented: $showUserProfile) {
                    UserProfileView(
                        userProfile: user,
                        accessToken: accessToken,
                        logout: logout
                    )
                    .presentationDetents([.medium])
                }
            }
        }
    }
    
    private func loadData() {
        isLoading = true
        
        switch selectedContentType {
        case .tracks:
            loadTracks()
        case .artists:
            loadArtists()
        case .genres:
            loadGenres()
        }
    }
    
    private func loadTracks() {
        SpotifyAPIService.fetchTopTracks(
            accessToken: accessToken,
            timeRange: selectedTimeRange.rawValue
        ) { fetchedTracks in
            DispatchQueue.main.async {
                self.tracks = fetchedTracks
                self.isLoading = false
            }
        }
    }
    
    private func loadArtists() {
        SpotifyAPIService.fetchTopArtists(
            accessToken: accessToken,
            timeRange: selectedTimeRange.rawValue
        ) { fetchedArtists in
            DispatchQueue.main.async {
                self.artists = fetchedArtists
                self.isLoading = false
            }
        }
    }
    
    private func loadGenres() {
        SpotifyAPIService.fetchTopArtists(
            accessToken: accessToken,
            timeRange: selectedTimeRange.rawValue
        ) { fetchedArtists in
            var genreCount: [String: Int] = [:]
            for artist in fetchedArtists {
                for genre in artist.genres {
                    genreCount[genre, default: 0] += 1
                }
            }
            DispatchQueue.main.async {
                self.genres = genreCount
                self.isLoading = false
            }
        }
    }
    
    private func sortedGenres() -> [(key: String, value: Int)] {
        genres.sorted { $0.value > $1.value }
    }
    
    private func loadingPlaceholder(index: Int) -> some View {
        HStack(alignment: .center, spacing: 8) {
            // 排名和變化指示器（在框框外面）
            VStack(spacing: 5) {
                // 排名變化指示器（目前顯示橫線，未來可顯示上升/下降）
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 12, height: 2)
                    .cornerRadius(1)
                
                Text("#\(index)")
                    .foregroundColor(.white)
                    .font(.custom("SpotifyMix-Bold", size: 22))
                    .lineLimit(1)
            }
            .frame(width: 50, alignment: .center)
            
            // 灰色框框內容
            HStack(spacing: 6) {
                // 專輯封面佔位符
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .shimmer()

                // 歌曲資訊佔位符
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 17)
                        .shimmer()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 15)
                        .shimmer()
                }

                Spacer()

                // 右箭頭
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .frame(height: 45)
            .padding(8)
            .padding(.trailing, 12)
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.bottom, 5)
    }
    
    // 空白 Artist Row，維持版面高度
    private func emptyArtistRow(index: Int) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text("#\(index)")
                .foregroundColor(.gray)
                .font(.custom("SpotifyMix-Bold", size: 20))
                .lineLimit(1)
                .frame(width: 35, alignment: .center)
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 22.5)
                    .fill(Color.clear)
                    .frame(width: 45, height: 45)
                VStack(alignment: .leading, spacing: 2) {
                    Text("")
                        .font(.custom("SpotifyMix-Bold", size: 17))
                        .foregroundColor(.clear)
                    Text("")
                        .font(.custom("SpotifyMix-Medium", size: 15))
                        .foregroundColor(.clear)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("")
                        .font(.custom("SpotifyMix-Medium", size: 14))
                        .foregroundColor(.clear)
                    Text("")
                        .font(.custom("SpotifyMix-Medium", size: 16))
                        .foregroundColor(.clear)
                }
                .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TopView(
        audioPlayer: AudioPlayer(),
        userProfile: nil,
        logout: {},
        accessToken: ""
    )
    .preferredColorScheme(.dark)
} 
