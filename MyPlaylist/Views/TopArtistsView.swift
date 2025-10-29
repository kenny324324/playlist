import SwiftUI

struct TopArtistsView: View {
    @State private var artists: [Artist] = []  // 存放藝術家資料
    @State private var showUserProfile = false  // 控制 UserProfileView 的彈出顯示

    let accessToken: String  // Spotify 的 access token
    let userProfile: SpotifyUser?  // 使用者資料
    let logout: () -> Void  // 登出函式

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 15) {
                        ForEach(artists.indices, id: \.self) { index in
                            ArtistRow(artist: artists[index], index: index + 1)  // 正確傳遞 Artist 和索引
                        }
                    }
                }
                .navigationTitle("nav.topArtists")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("settings.madeBy")
                            .font(.custom("SpotifyMix-Medium", size: 14))
                            .foregroundColor(.gray)
                            .opacity(0.7)
                    }
                    
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
            }
            .onAppear {
                fetchTopArtists()
            }
        }
    }

    // 呼叫 Spotify API 取得熱門藝術家資料
    private func fetchTopArtists() {
        SpotifyAPIService.fetchTopArtists(accessToken: accessToken) { fetchedArtists in
            DispatchQueue.main.async {
                self.artists = fetchedArtists
            }
        }
    }
}

#Preview {
    TopArtistsView(
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
