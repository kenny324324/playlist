import SwiftUI

// MARK: - 搜尋類別枚舉
enum SearchCategory: String, CaseIterable {
    case all
    case tracks
    case artists
    case albums
    
    var localizedName: LocalizedStringKey {
        switch self {
        case .all:
            return "search.category.all"
        case .tracks:
            return "search.category.tracks"
        case .artists:
            return "search.category.artists"
        case .albums:
            return "search.category.albums"
        }
    }
    
    var apiTypes: [String] {
        switch self {
        case .all:
            return ["track", "artist", "album"]
        case .tracks:
            return ["track"]
        case .artists:
            return ["artist"]
        case .albums:
            return ["album"]
        }
    }
}

// MARK: - 主搜尋頁面
struct SearchView: View {
    @ObservedObject var audioPlayer: AudioPlayer
    let accessToken: String
    let isLoggedIn: Bool
    let login: () -> Void
    let logout: () -> Void
    let selectedTab: Int
    
    @State private var searchText = ""
    @State private var selectedCategory: SearchCategory = .all
    @State private var searchResults: SearchResponse?
    @State private var isSearching = false
    @State private var isSearchActive = false
    @State private var newReleases: [NewReleaseAlbum] = []
    @State private var isLoadingBrowseData = false
    
    var body: some View {
        ZStack {
            // 背景顏色
            Color.spotifyText.ignoresSafeArea()
            
            if !isLoggedIn {
                // 未登入狀態
                LoginPromptView(login: login)
            } else if isSearchActive {
                // Focus 鍵盤後：顯示搜尋結果頁面
                SearchResultsView(
                    searchText: searchText,
                    selectedCategory: $selectedCategory,
                    searchResults: searchResults,
                    isSearching: isSearching,
                    audioPlayer: audioPlayer,
                    accessToken: accessToken
                )
            } else {
                // 未 Focus 鍵盤：顯示初始頁面
                SearchInitialContentView(
                    newReleases: newReleases,
                    isLoading: isLoadingBrowseData,
                    audioPlayer: audioPlayer,
                    accessToken: accessToken,
                    searchText: $searchText,
                    selectedCategory: $selectedCategory,
                    isSearchActive: $isSearchActive
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .isSearchable(selectedTab: selectedTab, searchText: $searchText, isPresented: $isSearchActive)
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty {
                performSearch()
            } else {
                searchResults = nil
                isSearching = false
            }
        }
        .onChange(of: selectedCategory) { _ in
            if !searchText.isEmpty {
                performSearch()
            }
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 1 {
                isSearchActive = false
            }
        }
        .onChange(of: isSearchActive) { active in
            if !active && searchText.isEmpty {
                searchResults = nil
                isSearching = false
            }
        }
        .onAppear {
            if isLoggedIn && newReleases.isEmpty {
                loadBrowseData()
            }
        }
    }
    
    // MARK: - 載入瀏覽資料
    private func loadBrowseData() {
        guard !accessToken.isEmpty else { return }
        
        isLoadingBrowseData = true
        
        // 取得新發行專輯
        SpotifyAPIService.fetchNewReleases(accessToken: accessToken, limit: 10) { albums in
            DispatchQueue.main.async {
                self.newReleases = albums
                self.isLoadingBrowseData = false
            }
        }
    }
    
    // MARK: - 執行搜尋
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        
        SpotifyAPIService.search(
            query: searchText,
            types: selectedCategory.apiTypes,
            accessToken: accessToken,
            limit: 20
        ) { response in
            DispatchQueue.main.async {
                self.isSearching = false
                self.searchResults = response
            }
        }
    }
}

// MARK: - 初始頁面（未 Focus 鍵盤時）
struct SearchInitialContentView: View {
    let newReleases: [NewReleaseAlbum]
    let isLoading: Bool
    @ObservedObject var audioPlayer: AudioPlayer
    let accessToken: String
    
    // 需要從父視圖傳入這些 Binding 來控制搜尋
    @Binding var searchText: String
    @Binding var selectedCategory: SearchCategory
    @Binding var isSearchActive: Bool
    
    // 情緒標籤資料
    let moodTags: [(String, LocalizedStringKey, String)] = [
        ("Happy", "mood.happy", "😊"),
        ("Chill", "mood.chill", "☕️"),
        ("Workout", "mood.workout", "💪"),
        ("Party", "mood.party", "🎉"),
        ("Focus", "mood.focus", "📚"),
        ("Sad", "mood.sad", "🌧")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isLoading {
                    // 載入中
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.spotifyGreen)
                        Text("search.loading")
                            .font(.appFont(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else if newReleases.isEmpty {
                    // 空狀態
                    VStack {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("search.initial.title")
                                .font(.appFont(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text("search.initial.subtitle")
                                .font(.appFont(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 顯示新發行專輯
                    VStack(alignment: .leading, spacing: 24) {
                        // 情緒標籤區塊
                        VStack(alignment: .leading, spacing: 12) {
                            Text("search.mood.title")
                                .font(.appFont(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(moodTags, id: \.0) { tag in
                                        Button(action: {
                                            // 點擊標籤直接搜尋
                                            searchText = tag.0 + " Mix" // 搜尋 "Happy Mix" 等
                                            selectedCategory = .all // 預設搜尋全部 (通常會包含歌單)
                                            isSearchActive = true // 激活搜尋狀態
                                        }) {
                                            HStack(spacing: 6) {
                                                Text(tag.2) // Emoji
                                                Text(tag.1) // Localized Key
                                                    .font(.appFont(size: 14, weight: .medium))
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.1))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.horizontal, -20)
                            .horizontalScrollFading(backgroundColor: .spotifyText)
                        }
                        
                        NewReleasesSection(
                            newReleases: newReleases,
                            audioPlayer: audioPlayer,
                            accessToken: accessToken
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }
}

// MARK: - 新發行專輯區塊
struct NewReleasesSection: View {
    let newReleases: [NewReleaseAlbum]
    @ObservedObject var audioPlayer: AudioPlayer
    let accessToken: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("search.new.releases")
                .font(.appFont(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(newReleases) { album in
                        NavigationLink(destination: AlbumDetailView(
                            albumId: album.id,
                            albumName: album.name,
                            accessToken: accessToken,
                            audioPlayer: audioPlayer
                        )) {
                            NewReleaseCard(album: album)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
            .horizontalScrollFading(backgroundColor: .spotifyText)
        }
    }
}

// MARK: - 新發行專輯卡片
struct NewReleaseCard: View {
    let album: NewReleaseAlbum
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 專輯封面
            AsyncImage(url: URL(string: album.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
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
            
            // 專輯名稱
            Text(album.name)
                .font(.appFont(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
            
            // 藝人名稱
            Text(album.artistNames)
                .font(.appFont(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
        }
    }
}

// MARK: - 登入提示視圖
struct LoginPromptView: View {
    let login: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.spotifyGreen)
            
            Text("search.login.title")
                .font(.appFont(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("search.login.message")
                .font(.appFont(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: login) {
                Text("search.login.button")
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 14)
                    .background(Color.spotifyGreen)
                    .cornerRadius(25)
            }
            .padding(.top, 20)
        }
        .padding(40)
    }
}

// MARK: - ViewModifier for Conditional Searchable
struct IsSearchable: ViewModifier {
    let selectedTab: Int
    @Binding var searchText: String
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        if selectedTab == 1 {
            if #available(iOS 17.0, *) {
                content
                    .searchable(
                        text: $searchText,
                        isPresented: $isPresented,
                        prompt: Text("搜尋Spotify")
                    )
            } else {
                content
                    .searchable(text: $searchText, prompt: Text("搜尋Spotify"))
                    .onChange(of: searchText) { newValue in
                        isPresented = !newValue.isEmpty
                    }
            }
        } else {
            content
        }
    }
}

extension View {
    func isSearchable(selectedTab: Int, searchText: Binding<String>, isPresented: Binding<Bool>) -> some View {
        modifier(IsSearchable(selectedTab: selectedTab, searchText: searchText, isPresented: isPresented))
    }
}

// MARK: - Preview
#Preview {
    SearchView(
        audioPlayer: AudioPlayer(),
        accessToken: "",
        isLoggedIn: false,
        login: {},
        logout: {},
        selectedTab: 1
    )
}
