import SwiftUI

struct TopView: View {
    @ObservedObject var audioPlayer: AudioPlayer
    var userProfile: SpotifyUser?
    let isLoggedIn: Bool
    let login: () -> Void
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
            switch self {
            case .tracks: return String(localized: "top.tracks")
            case .artists: return String(localized: "top.artists")
            case .genres: return String(localized: "top.genres")
            }
        }
    }
    
    enum TimeRange: String, CaseIterable {
        case shortTerm = "short_term"
        case mediumTerm = "medium_term"
        case longTerm = "long_term"
        
        var title: String {
            switch self {
            case .shortTerm: return String(localized: "timeRange.1month")
            case .mediumTerm: return String(localized: "timeRange.6months")
            case .longTerm: return String(localized: "timeRange.allTime")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 主要內容區域
                contentView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    userProfileButton
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarFilterMenus
                }
            }
            .onAppear {
                if isLoggedIn {
                    loadData()
                }
            }
            .onChange(of: isLoggedIn) { loggedIn in
                if !loggedIn {
                    clearData()
                }
            }
            .onChange(of: accessToken) { token in
                // 當 accessToken 更新時（登入成功），載入資料
                if !token.isEmpty && isLoggedIn {
                    loadData()
                }
            }
        }
    }
    
    private var contentTypeSelector: some View { EmptyView() }
    
    private var contentView: some View {
        Group {
            if !isLoggedIn {
                // 未登入提示
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("login.prompt.title")
                        .font(.custom("SpotifyMix-Bold", size: 24))
                        .foregroundColor(.white)
                    Text("login.prompt.topChart")
                        .font(.custom("SpotifyMix-Medium", size: 16))
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else if isLoading {
                // 載入中：顯示 15 個佔位符，禁止捲動
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 5) {
                        ForEach(0..<15, id: \.self) { index in
                            loadingPlaceholder(index: index + 1)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
                .disabled(true)
            } else {
                // 載入完成：顯示實際內容，可以捲動
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 5) {
                        switch selectedContentType {
                        case .tracks:
                            tracksContent
                        case .artists:
                            artistsContent
                        case .genres:
                            genresContent
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    // 左右兩個按鈕 + Menu（左：類型；右：時間），中間保留分隔線（供 toolbar 使用）
    private var toolbarFilterMenus: some View {
        HStack(spacing: 8) {
            // 類型選單按鈕
            Menu {
                ForEach(ContentType.allCases, id: \.self) { type in
                    Button(action: {
                        if selectedContentType != type {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                selectedContentType = type
                            }
                            loadData()
                        }
                    }) {
                        HStack {
                            Text(type.title)
                            if selectedContentType == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedContentType.title)
                        .font(.custom("SpotifyMix-Medium", size: 15))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.8)
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())

            // 分隔線
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 22)
                .padding(.horizontal, 2)

            // 時間選單按鈕
            Menu {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        if selectedTimeRange != range {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                selectedTimeRange = range
                            }
                            loadData()
                        }
                    }) {
                        HStack {
                            Text(range.title)
                            if selectedTimeRange == range {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedTimeRange.title)
                        .font(.custom("SpotifyMix-Medium", size: 15))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.8)
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 6)
    }
    
    private var tracksContent: some View {
        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
            NavigationLink(
                destination: TrackDetailView(
                    trackId: track.id,
                    accessToken: accessToken,
                    audioPlayer: audioPlayer
                )
            ) {
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
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var artistsContent: some View {
        Group {
            if artists.isEmpty {
                EmptyView()
            } else {
                ForEach(Array(artists.enumerated()), id: \.element.id) { index, artist in
                    NavigationLink(destination: ArtistDetailView(artistId: artist.id, artistName: artist.name, accessToken: accessToken, audioPlayer: audioPlayer)) {
                        ArtistRow(artist: artist, index: index + 1)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 5)
                    }
                    .buttonStyle(PlainButtonStyle())
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
    
    private var timeRangeSelector: some View { EmptyView() }
    
    private var userProfileButton: some View {
        Group {
            if isLoggedIn {
                // 已登入：顯示頭像
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
            } else {
                // 未登入：顯示登入按鈕
                Button(action: login) {
                    Text("login.title")
                        .font(.custom("SpotifyMix-Medium", size: 14))
                        .foregroundColor(Color.spotifyText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.spotifyGreen)
                        .cornerRadius(20)
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
    
    private func clearData() {
        tracks = []
        artists = []
        genres = [:]
        isLoading = false
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
        isLoggedIn: false,
        login: {},
        logout: {},
        accessToken: ""
    )
    .preferredColorScheme(.dark)
} 
