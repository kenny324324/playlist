import SwiftUI

struct UserProfileView: View {
    let userProfile: SpotifyUser
    let accessToken: String
    let logout: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var playlists: [Playlist] = []
    // 用來控制 Alert 顯示的狀態
    @State private var showingLogoutAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 用戶資訊區域，包含登出按鈕
            userInfoSection
                .padding(.top, 20)
                .padding(.horizontal, 20)

            // 播放清單標題和滾動區域
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Playlists")
                    .font(.custom("SpotifyMix-Bold", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                playlistSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()  // 使登出按鈕靠近底部
            
            // Made by Kenny 標籤
            Text("Made by Kenny")
                .font(.custom("SpotifyMix-Medium", size: 12))
                .foregroundColor(.gray)
                .opacity(0.7)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

        }
        .onAppear {
            fetchPlaylists()
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle("Profile")
        .alert(isPresented: $showingLogoutAlert) {
            Alert(
                title: Text("Confirm Logout"),
                message: Text("Are you sure you want to log out?"),
                primaryButton: .destructive(Text("Logout")) {
                    logout()
                    dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var userInfoSection: some View {
        HStack(spacing: 20) {
            userImageView
            VStack(alignment: .leading, spacing: 5) {
                Text(userProfile.display_name ?? "Unknown User")
                    .font(.custom("SpotifyMix-Bold", size: 16))
                    .foregroundColor(.white)

                Text("Followers: \(userProfile.followers?.total ?? 0)")
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            logoutButton // 把登出按鈕放在最右邊
        }
        .padding(15)
        .background(Color.white.opacity(0.1))
        .cornerRadius(25)
    }
    
    private var userImageView: some View {
        Group {
            if let imageUrl = userProfile.images?.first?.url,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.gray)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 60, height: 60)
            }
        }
    }

    private var playlistSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 3), spacing: 5) {
                ForEach(playlists) { playlist in
                    HStack(alignment: .center, spacing: 10) {
                        playlistImageView(for: playlist)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 0))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(playlist.name)
                                .font(.custom("SpotifyMix-Medium", size: 14))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(playlist.owner.display_name ?? "Unknown Owner")
                                .font(.custom("SpotifyMix-Medium", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .frame(width: 300, height: 60, alignment: .leading)
                }
            }
        }
    }

    private var logoutButton: some View {
        Button(action: {
            showingLogoutAlert = true // 顯示 Alert
        }) {
            Text("Log out")
                .font(.custom("SpotifyMix-Bold", size: 14))
                .foregroundColor(Color.spotifyText)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(20)
        }
    }

    private func fetchPlaylists() {
        SpotifyAPIService.fetchUserPlaylists(accessToken: accessToken) { fetchedPlaylists in
            DispatchQueue.main.async {
                self.playlists = fetchedPlaylists
            }
        }
    }
    
    private func playlistImageView(for playlist: Playlist) -> some View {
        Group {
            if let imageUrl = playlist.images.first?.url,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 60, height: 60)
            }
        }
    }
}

#Preview {
    UserProfileView(
        userProfile: SpotifyUser(
            display_name: "Kenny Chen",
            images: [SpotifyImage(url: "https://i.scdn.co/image/ab6775700000ee85f8b5b5c4b5e5c5b5e5c5b5c5")],
            email: "kenny@example.com",
            id: "user123",
            followers: SpotifyUser.Followers(total: 1234)
        ),
        accessToken: "preview_token",
        logout: {}
    )
    .preferredColorScheme(.dark)
    .background(Color.spotifyText)
}
