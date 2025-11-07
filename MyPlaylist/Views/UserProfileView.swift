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
        GeometryReader { geometry in
            // 使用更穩健的判斷方式：結合寬度和高度
            // iPad Sheet 的寬度通常 > 500pt
            let screenWidth = geometry.size.width
            let isLargeScreen = screenWidth > 500 || UIDevice.current.userInterfaceIdiom == .pad
            let scale: CGFloat = isLargeScreen ? 1.5 : 1.0
            
            // 計算可用高度，決定每列顯示幾個項目
            let availableHeight = geometry.size.height
            let itemsPerColumn = calculateItemsPerColumn(availableHeight: availableHeight, scale: scale)
            
            let _ = print("🔍 Width: \(Int(screenWidth))pt, Height: \(Int(availableHeight))pt, Scale: \(scale)x, Items: \(itemsPerColumn)")
            
            VStack(spacing: 0) {
                // 用戶資訊區域，包含登出按鈕
                userInfoSection(scale: scale)
                    .padding(.top, 20 * scale)
                    .padding(.horizontal, 20 * scale)

                // 播放清單標題和滾動區域
                VStack(alignment: .leading, spacing: 10 * scale) {
                    Text("profile.playlists")
                        .font(.custom("SpotifyMix-Bold", size: 20 * scale))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    playlistSection(scale: scale, itemsPerColumn: itemsPerColumn)
                }
                .padding(.horizontal, 20 * scale)
                .padding(.top, 20 * scale)

                Spacer()  // 使登出按鈕靠近底部
                
                // Made by Kenny 標籤
                Text("settings.madeBy")
                    .font(.custom("SpotifyMix-Medium", size: 14 * scale))
                    .foregroundColor(.gray)
                    .opacity(0.7)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

            }
        }
        .onAppear {
            fetchPlaylists()
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle("profile.title")
        .alert(isPresented: $showingLogoutAlert) {
            Alert(
                title: Text("profile.logout.confirm.title"),
                message: Text("profile.logout.confirm.message"),
                primaryButton: .destructive(Text("profile.logout.confirm.button")) {
                    logout()
                    dismiss()
                },
                secondaryButton: .cancel(Text("common.cancel"))
            )
        }
    }
    
    private func userInfoSection(scale: CGFloat) -> some View {
        HStack(spacing: 12 * scale) {  // 從 20 * scale 改為 12 * scale
            userImageView(scale: scale)
            
            VStack(alignment: .leading, spacing: 5 * scale) {
                Text(userProfile.display_name ?? String(localized: "profile.unknownUser"))
                    .font(.custom("SpotifyMix-Bold", size: 18 * scale))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(String(localized: "profile.followers", defaultValue: "Followers: \(userProfile.followers?.total ?? 0)"))
                    .font(.custom("SpotifyMix-Medium", size: 16 * scale))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)  // 讓文字區域佔用更多空間
            
            logoutButton(scale: scale)
        }
        .padding(15 * scale)
        .background(Color.white.opacity(0.1))
        .cornerRadius(25 * scale)
    }
    
    private func userImageView(scale: CGFloat) -> some View {
        Group {
            let imageSize = 60.0 * scale
            if let imageUrl = userProfile.images?.first?.url,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.gray)
                }
                .frame(width: imageSize, height: imageSize)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: imageSize, height: imageSize)
            }
        }
    }

    private func playlistSection(scale: CGFloat, itemsPerColumn: Int) -> some View {
        let itemHeight = 60 * scale
        let spacing = 10 * scale
        let totalHeight = CGFloat(itemsPerColumn) * itemHeight + CGFloat(itemsPerColumn - 1) * spacing
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 20 * scale) {
                ForEach(0..<Int(ceil(Double(playlists.count) / Double(itemsPerColumn))), id: \.self) { pageIndex in
                    VStack(alignment: .leading, spacing: spacing) {
                        ForEach(getPlaylistsForPage(pageIndex, itemsPerColumn: itemsPerColumn)) { playlist in
                            HStack(alignment: .center, spacing: 10 * scale) {
                                playlistImageView(for: playlist)
                                    .frame(width: 50 * scale, height: 50 * scale)
                                    .clipShape(RoundedRectangle(cornerRadius: 5 * scale))

                                VStack(alignment: .leading, spacing: 4 * scale) {
                                    Text(playlist.name)
                                        .font(.custom("SpotifyMix-Medium", size: 16 * scale))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Text(playlist.owner.display_name ?? String(localized: "profile.unknownOwner"))
                                        .font(.custom("SpotifyMix-Medium", size: 14 * scale))
                                        .foregroundColor(.white.opacity(0.6))
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .frame(width: 300 * scale, height: itemHeight)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(height: totalHeight)
                }
            }
        }
        .frame(height: totalHeight)
    }
    
    private func getPlaylistsForPage(_ pageIndex: Int, itemsPerColumn: Int) -> [Playlist] {
        let startIndex = pageIndex * itemsPerColumn
        let endIndex = min(startIndex + itemsPerColumn, playlists.count)
        return Array(playlists[startIndex..<endIndex])
    }
    
    /// 根據 Sheet detent 判斷每列應該顯示幾個項目
    /// - Medium detent (較小) → 2 個項目
    /// - Large detent (較大) → 3 個項目
    private func calculateItemsPerColumn(availableHeight: CGFloat, scale: CGFloat) -> Int {
        // 根據實際測試的高度值設定臨界值：
        // 469pt (Large) → 3 個項目
        // 367pt (Medium) → 2 個項目
        // 臨界值設為中間值：420pt
        
        let mediumDetentThreshold: CGFloat = 420  // 臨界值
        
        if availableHeight >= mediumDetentThreshold {
            // Large detent (≥ 420pt) - 顯示 3 個項目
            return 3
        } else {
            // Medium detent (< 420pt) - 顯示 2 個項目
            return 2
        }
    }

    private func logoutButton(scale: CGFloat) -> some View {
        Button(action: {
            showingLogoutAlert = true // 顯示 Alert
        }) {
            Text("profile.logout")
                .font(.custom("SpotifyMix-Bold", size: 16 * scale))
                .foregroundColor(Color.spotifyText)
                .padding(.vertical, 8 * scale)
                .padding(.horizontal, 16 * scale)
                .background(Color.white)
                .cornerRadius(20 * scale)
        }
        .buttonStyle(PlainButtonStyle())
        // 確保按鈕有足夠的點擊區域
        .frame(minWidth: 90 * scale, minHeight: 40 * scale)
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
