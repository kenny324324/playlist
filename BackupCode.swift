/*
import SwiftUI

extension Color {
    static let spotifyGreen = Color(UIColor(red: 0.11, green: 0.84, blue: 0.38, alpha: 1.0))
    static let spotifyText = Color(UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0))
}

struct ContentView: View {
    @State private var accessToken: String? = nil
    @State private var isLoggedIn = false
    @State private var tracks: [Track] = []
    @State private var userProfile: SpotifyUser? = nil
    @State private var selectedTimeRange: TimeRange = .shortTerm
    @State private var showAllTracks = false
    @ObservedObject var audioPlayer = AudioPlayer()

    var body: some View {
        ZStack {
            Color.spotifyText.ignoresSafeArea()

            NavigationView {
                if isLoggedIn {
                    VStack(spacing: 0) {
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.title).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .background(Color.spotifyText)

                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 15) {
                                ForEach(Array(displayedTracks().enumerated()), id: \.element.id) { index, track in
                                    TrackRow(track: track, index: index + 1, audioPlayer: audioPlayer)
                                }

                                Button(action: { withAnimation { showAllTracks.toggle() } }) {
                                    Text(showAllTracks ? "Show Less" : "Show More")
                                        .font(.custom("SpotifyMix-Medium", size: 16))
                                        .foregroundColor(Color.spotifyGreen)
                                }
                                .padding(.top, 10)
                                .padding(.horizontal, 23)
                                .padding(.bottom, 20)
                            }
                            .padding(.top, 20)
                        }
                        .background(Color.spotifyText)
                        .navigationTitle("Top Tracks")
                        .toolbar {
                            // 左側的 ToolbarItem - Made by Kenny
                            ToolbarItem(placement: .navigationBarLeading) {
                                Text("Made by Kenny")
                                    .font(.custom("SpotifyMix-Medium", size: 12))
                                    .foregroundColor(.gray)  // 顯示灰色文字
                                    .opacity(0.7)  // 降低不透明度
                            }

                            // 右側的 ToolbarItem - Logout 與大頭貼
                            ToolbarItem(placement: .navigationBarTrailing) {
                                HStack(spacing: 8) {  // 減少內部元素間距
                                    // Logout 按鈕
                                    Button(action: logout) {
                                        Text("Logout")
                                            .font(.custom("SpotifyMix-Medium", size: 16))
                                            .foregroundColor(Color.spotifyText)
                                            .padding(.vertical, 5)
                                            .padding(.horizontal, 15)  // 避免按鈕過寬
                                            .background(Color.spotifyGreen)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    // 使用者大頭貼
                                    if let user = userProfile,
                                       let imageUrl = user.images?.first?.url,
                                       let url = URL(string: imageUrl) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .clipShape(Circle())  // 圓形大頭貼
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 30, height: 30)  // 固定大頭貼尺寸
                                        .clipShape(Circle())  // 防止變形
                                    }
                                }
                            }
                        }
                        .onAppear {
                            if let token = accessToken {
                                fetchUserProfile(token: token)
                                fetchTopTracks(token: token, timeRange: selectedTimeRange)
                            }
                        }
                        .onChange(of: selectedTimeRange) { newRange in
                            if let token = accessToken {
                                fetchTopTracks(token: token, timeRange: newRange)
                            }
                        }
                    }
                } else {
                    VStack {
                        Spacer()
                        Button(action: login) {
                            Text("Login with Spotify")
                                .font(.custom("SpotifyMix-Medium", size: 20))
                                .foregroundColor(Color.spotifyText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.spotifyGreen)
                                .cornerRadius(50)
                        }
                        .padding(.horizontal, 23)
                    }
                    .background(Color.spotifyText)
                }
            }
            .onOpenURL { url in
                handleSpotifyCallback(url: url)
            }
            .onAppear {
                if let token = UserDefaults.standard.string(forKey: "access_token") {
                    self.accessToken = token
                    self.isLoggedIn = true
                } else {
                    // 如果 access token 遺失，嘗試使用 refresh token 獲取新 token
                    SpotifyAuthService.refreshAccessToken { newToken in
                        if let newToken = newToken {
                            DispatchQueue.main.async {
                                self.accessToken = newToken
                                self.isLoggedIn = true
                            }
                        } else {
                            print("Failed to refresh token, user needs to log in again")
                        }
                    }
                }
            }
        }
    }

    // Spotify 登入流程
    func login() {
        guard let url = URL(string: SpotifyAuthService.loginURLString()) else { return }
        UIApplication.shared.open(url)
    }

    // 登出流程
    func logout() {
        UserDefaults.standard.removeObject(forKey: "access_token")
        self.accessToken = nil
        self.isLoggedIn = false
    }

    // 顯示歌曲列表
    func displayedTracks() -> [Track] {
        showAllTracks ? tracks : Array(tracks.prefix(10))
    }

    // Spotify 回調處理
    func handleSpotifyCallback(url: URL) {
        guard let code = extractCode(from: url) else { return }
        SpotifyAuthService.fetchAccessToken(code: code) { token in
            DispatchQueue.main.async {
                if let token = token {
                    UserDefaults.standard.set(token, forKey: "access_token")
                    self.accessToken = token
                    self.isLoggedIn = true
                }
            }
        }
    }

    // 取得使用者資料
    func fetchUserProfile(token: String) {
        SpotifyAPIService.fetchCurrentUserProfile(accessToken: token) { user in
            DispatchQueue.main.async {
                self.userProfile = user
            }
        }
    }

    // 取得熱門歌曲
    func fetchTopTracks(token: String, timeRange: TimeRange) {
        SpotifyAPIService.fetchTopTracks(accessToken: token, timeRange: timeRange.rawValue) { fetchedTracks in
            DispatchQueue.main.async {
                self.tracks = fetchedTracks
            }
        }
    }


    func extractCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value
    }
}

import SwiftUI

struct TrackRow: View {
    let track: Track
    let index: Int  // 歌曲索引
    @ObservedObject var audioPlayer: AudioPlayer  // 傳入音訊播放器

    var body: some View {
        Button(action: {
            if let previewUrl = track.previewUrl {
                audioPlayer.playPreview(from: previewUrl)  // 播放或停止音檔
            }
        }) {
            HStack(alignment: .center, spacing: 10) {
                // 顯示索引
                Text("\(index)")
                    .font(.custom("SpotifyMix-Medium", size: 16))
                    .foregroundColor(.gray)
                    .frame(width: 30, alignment: .center)

                // 專輯封面
                AsyncImage(url: URL(string: track.album.images.first?.url ?? "")) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .clipped()

                // 歌曲名稱和藝術家名稱
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.custom("SpotifyMix-Medium", size: 16))
                        .foregroundColor(.primary)
                        .lineLimit(1)  // 限制為一行
                        .truncationMode(.tail)  // 超過範圍顯示「...」

                    Text(track.artists.map(\.name).joined(separator: ", "))
                        .font(.custom("SpotifyMix-Medium", size: 12))
                        .foregroundColor(.gray)

                    // 根據 previewUrl 顯示提示
                    if let _ = track.previewUrl {
                        Text("Preview Available")
                            .font(.custom("SpotifyMix-Medium", size: 12))
                            .foregroundColor(.green)
                    } else {
                        Text("No Preview Available")
                            .font(.custom("SpotifyMix-Medium", size: 12))
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                // 如果目前正在播放該歌曲，顯示「播放中」
                if audioPlayer.currentPreviewUrl == track.previewUrl && audioPlayer.isPlaying {
                    Text("Playing")
                        .font(.custom("SpotifyMix-Medium", size: 14))
                        .foregroundColor(Color.spotifyGreen)
                }
            }
            .padding(.horizontal)
        }
        // 如果歌曲沒有預覽音檔，禁用按鈕
        .disabled(track.previewUrl == nil)
        .opacity(track.previewUrl == nil ? 0.5 : 1.0)  // 無預覽時降低透明度
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
        case .longTerm: return "1 Year"
        }
    }
}*/
