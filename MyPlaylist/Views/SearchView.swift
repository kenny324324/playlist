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
    
    var body: some View {
        ZStack {
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
                SearchInitialContentView()
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
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("search.initial.title")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text("search.initial.subtitle")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("search.login.message")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: login) {
                Text("search.login.button")
                    .font(.system(size: 16, weight: .semibold))
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
