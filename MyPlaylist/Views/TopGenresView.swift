import SwiftUI

struct TopGenresView: View {
    @State private var genres: [String: Int] = [:]  // 存放類型及出現次數
    @State private var showUserProfile = false  // 控制 UserProfileView 的彈出顯示

    let accessToken: String  // Spotify access token
    let userProfile: SpotifyUser?  // 使用者資料
    let logout: () -> Void  // 登出函式

    var body: some View {
        NavigationView {
            VStack {
            if genres.isEmpty {
                ProgressView("loading.genres")  // 顯示載入狀態
            } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 15) {
                            ForEach(Array(sortedGenres().enumerated()), id: \.element.key) { index, genreData in
                                let (genre, count) = genreData
                                GenreRow(index: index + 1, genre: genre, count: count)  // 傳遞編號和資料
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("nav.topGenres")
            .toolbar {
                // 左側 ToolbarItem
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("settings.madeBy")
                        .font(.custom("SpotifyMix-Medium", size: 14))
                        .foregroundColor(.gray)
                        .opacity(0.7)
                }
                
                // 右側 ToolbarItem
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        if let user = userProfile,
                           let imageUrl = user.images?.first?.url,
                           let url = URL(string: imageUrl) {
                            // 使用 Button 來觸發彈出視圖
                            Button(action: {
                                showUserProfile = true  // 顯示 UserProfileView
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
                                UserProfileView(userProfile: user, accessToken: accessToken, logout: logout)
                                    .presentationDetents([.medium])  // 設置固定的中等高度
                            }
                        }
                    }
                }
            }
            .onAppear {
                fetchTopGenres()  // 載入 Spotify 資料
            }
        }
    }

    // 呼叫 Spotify API，取得熱門藝術家並計算類型次數
    private func fetchTopGenres() {
        SpotifyAPIService.fetchTopArtists(accessToken: accessToken) { artists in
            var genreCount: [String: Int] = [:]
            for artist in artists {
                for genre in artist.genres {
                    genreCount[genre, default: 0] += 1
                }
            }
            DispatchQueue.main.async {
                self.genres = genreCount
            }
        }
    }

    // 將類型依次數排序
    private func sortedGenres() -> [(key: String, value: Int)] {
        genres.sorted { $0.value > $1.value }
    }
}

#Preview {
    TopGenresView(
        accessToken: "preview_token",
        userProfile: SpotifyUser(
            display_name: "Preview User",
            images: [SpotifyImage(url: "https://i.scdn.co/image/ab6775700000ee85")],
            email: "user@example.com",
            id: "user123",
            followers: SpotifyUser.Followers(total: 500)
        ),
        logout: {}
    )
    .preferredColorScheme(.dark)
    .background(Color.spotifyText)
}
