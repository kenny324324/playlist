import SwiftUI

// MARK: - 搜尋結果頁面（Focus 鍵盤後）
struct SearchResultsView: View {
    let searchText: String
    @Binding var selectedCategory: SearchCategory
    let searchResults: SearchResponse?
    let isSearching: Bool
    let audioPlayer: AudioPlayer
    let accessToken: String
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 背景內容區域（全屏）
            if isSearching {
                // 載入中 - 顯示佔位符
                SearchLoadingPlaceholderView()
            } else if let results = searchResults {
                // 顯示搜尋結果
                SearchResultsContentView(
                    results: results,
                    selectedCategory: selectedCategory,
                    audioPlayer: audioPlayer,
                    accessToken: accessToken
                )
            } else if searchText.isEmpty {
                // 空白狀態
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 8)
                        
                    Text("search.placeholder.title") // Needs localization
                        .font(.appFont(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        
                    Text("search.placeholder.subtitle") // Needs localization
                        .font(.appFont(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.spotifyText)
            }
            
            // 懸浮按鈕（右上角）
            if #available(iOS 26.0, *) {
                Menu {
                    Picker("搜尋分類", selection: $selectedCategory) {
                        ForEach(SearchCategory.allCases, id: \.self) { category in
                            Text(category.localizedName).tag(category)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    HStack(spacing: 8) {
                        Text(selectedCategory.localizedName)
                            .font(.appFont(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Material.ultraThinMaterial) // 使用毛玻璃效果
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.trailing, 16)
                .padding(.top, 12)
            } else {
                Menu {
                    Picker("搜尋分類", selection: $selectedCategory) {
                        ForEach(SearchCategory.allCases, id: \.self) { category in
                            Text(category.localizedName).tag(category)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    HStack(spacing: 8) {
                        Text(selectedCategory.localizedName)
                            .font(.appFont(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.trailing, 16)
                .padding(.top, 12)
            }
        }
        // 移除整個 SearchResultsView 的不透明背景
        // .background(Color.spotifyText) 
    }
}

// MARK: - 搜尋結果內容
struct SearchResultsContentView: View {
    let results: SearchResponse
    let selectedCategory: SearchCategory
    let audioPlayer: AudioPlayer
    let accessToken: String
    
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 顯示歌曲結果
                if selectedCategory == .all || selectedCategory == .tracks {
                    if let tracks = results.tracks?.items, !tracks.isEmpty {
                        SearchSectionView(titleKey: "search.category.tracks") {
                            ForEach(tracks) { track in
                                NavigationLink(destination: TrackDetailView(
                                    trackId: track.id,
                                    accessToken: accessToken,
                                    audioPlayer: audioPlayer
                                )) {
                                    SearchTrackRow(track: track)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // 顯示藝人結果
                if selectedCategory == .all || selectedCategory == .artists {
                    if let artists = results.artists?.items, !artists.isEmpty {
                        SearchSectionView(titleKey: "search.category.artists") {
                            ForEach(artists) { artist in
                                NavigationLink(destination: ArtistDetailView(
                                    artistId: artist.id,
                                    artistName: artist.name,
                                    accessToken: accessToken,
                                    audioPlayer: audioPlayer
                                )) {
                                    SearchArtistRow(artist: artist)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // 顯示專輯結果
                if selectedCategory == .all || selectedCategory == .albums {
                    if let albums = results.albums?.items, !albums.isEmpty {
                        SearchSectionView(titleKey: "search.category.albums") {
                            ForEach(albums) { album in
                                NavigationLink(destination: AlbumDetailView(
                                    albumId: album.id,
                                    albumName: album.name,
                                    accessToken: accessToken,
                                    audioPlayer: audioPlayer
                                )) {
                                    SearchAlbumRow(album: album)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // 無結果提示
                if isEmptyResults {
                    VStack(spacing: 15) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("search.empty.title")
                            .font(.appFont(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("search.empty.message")
                            .font(.appFont(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 70)
            .padding(.bottom, keyboardHeight > 0 ? 20 : 0)
        }
        .scrollIndicators(.hidden)
        .background(Color.spotifyText)
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.25)) {
                        keyboardHeight = keyboardFrame.height
                    }
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = 0
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
    
    private var isEmptyResults: Bool {
        let hasNoTracks = results.tracks?.items.isEmpty ?? true
        let hasNoArtists = results.artists?.items.isEmpty ?? true
        let hasNoAlbums = results.albums?.items.isEmpty ?? true
        
        switch selectedCategory {
        case .all:
            return hasNoTracks && hasNoArtists && hasNoAlbums
        case .tracks:
            return hasNoTracks
        case .artists:
            return hasNoArtists
        case .albums:
            return hasNoAlbums
        }
    }
}

// MARK: - 搜尋區段視圖
struct SearchSectionView<Content: View>: View {
    let titleKey: LocalizedStringKey
    let content: Content
    
    init(titleKey: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.titleKey = titleKey
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(titleKey)
                .font(.appFont(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            content
        }
    }
}

// MARK: - 搜尋歌曲行
struct SearchTrackRow: View {
    let track: Track
    
    var body: some View {
        HStack(spacing: 15) {
            // 專輯封面
            if let imageURL = track.album.images.first?.url {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            }
            
            // 歌曲資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(track.name)
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artists.map(\.name).joined(separator: ", "))
                    .font(.appFont(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// MARK: - 搜尋藝人行
struct SearchArtistRow: View {
    let artist: SearchArtist
    
    var body: some View {
        HStack(spacing: 15) {
            // 藝人圖片
            if let imageURL = artist.images.first?.url {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            
            // 藝人資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 5) {
                    Text("search.row.artist")
                        .font(.appFont(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    if let followers = artist.followers?.total {
                        Text("•")
                            .foregroundColor(.gray)
                        Text("\(formatNumber(followers)) \(Text("search.row.followers"))")
                            .font(.appFont(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - 搜尋專輯行
struct SearchAlbumRow: View {
    let album: Album
    
    var body: some View {
        HStack(spacing: 15) {
            // 專輯封面
            if let imageURL = album.images.first?.url {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            }
            
            // 專輯資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 5) {
                    Text("search.row.album")
                        .font(.appFont(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    if let artist = album.artists.first {
                        Text("•")
                            .foregroundColor(.gray)
                        Text(artist.name)
                            .font(.appFont(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// MARK: - 載入中佔位符
struct SearchLoadingPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<8, id: \.self) { _ in
                    HStack(spacing: 15) {
                        // 圖片佔位符
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .shimmer()
                        
                        // 文字佔位符
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 16)
                                .frame(maxWidth: .infinity)
                                .shimmer()
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 14)
                                .frame(width: 120)
                                .shimmer()
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 70)
        }
        .background(Color.spotifyText)
    }
}
