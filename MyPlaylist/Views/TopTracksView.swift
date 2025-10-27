import SwiftUI

struct TopTracksView: View {
    @Binding var tracks: [Track]
    @ObservedObject var audioPlayer: AudioPlayer
    var userProfile: SpotifyUser?
    let logout: () -> Void  // 登出閉包
    let accessToken: String

    @State private var selectedTimeRange: TrackTimeRange = .shortTerm
    @State private var showPlayer = false
    @State private var selectedTrack: Track? = nil
    @State private var albumImage: UIImage? = nil
    @State private var dominantColor: Color = .white
    @State private var showUserProfile = false  // 控制 UserProfileView 的彈出顯示

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Picker for time range selection
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TrackTimeRange.allCases, id: \.self) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 15) {
                        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                            TrackRow(
                                track: track,
                                index: index + 1,
                                audioPlayer: audioPlayer,
                                selectedTrack: $selectedTrack,
                                showPlayer: $showPlayer
                            )
                        }
                    }
                    .padding(.top, 20)
                }
                .navigationTitle("Top Tracks")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Made by Kenny")
                            .font(.custom("SpotifyMix-Medium", size: 12))
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

                if showPlayer {
                    PlayerView(
                        audioPlayer: audioPlayer,
                        showPlayer: $showPlayer,
                        currentTrack: $selectedTrack
                    )
                }
            }
            .onChange(of: selectedTimeRange) { newRange in
                fetchTopTracks(timeRange: newRange)
            }
        }
    }

    private func fetchTopTracks(timeRange: TrackTimeRange) {
        SpotifyAPIService.fetchTopTracks(accessToken: accessToken, timeRange: timeRange.rawValue) { fetchedTracks in
            DispatchQueue.main.async {
                self.tracks = fetchedTracks
            }
        }
    }

    private func loadAlbumImage(for track: Track) {
        guard let imageUrl = track.album.images.first?.url,
              let url = URL(string: imageUrl) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.albumImage = image
                    extractDominantColor(from: image)
                }
            }
        }.resume()
    }

    private func extractDominantColor(from image: UIImage) {
        image.getDominantColor { color in
            if let color = color {
                self.dominantColor = Color(color)
            }
        }
    }
}

// 更新為 TrackTimeRange 以避免名稱衝突
enum TrackTimeRange: String, CaseIterable {
    case shortTerm = "short_term"  // 一個月
    case mediumTerm = "medium_term"  // 半年
    case longTerm = "long_term"  // 一年

    var title: String {
        switch self {
        case .shortTerm: return "1 Month"
        case .mediumTerm: return "6 Months"
        case .longTerm: return "1 Year"
        }
    }
}
