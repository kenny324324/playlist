import SwiftUI

struct RecentlyPlayedView: View {
    @State private var recentlyPlayed: [RecentlyPlayedTrack] = []
    @State private var isLoading = true
    @ObservedObject var audioPlayer: AudioPlayer
    @Environment(\.dismiss) var dismiss
    
    let accessToken: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    // 載入中的佔位符
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(0..<20, id: \.self) { _ in
                                RecentlyPlayedPlaceholder()
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 20)
                    }
                } else if recentlyPlayed.isEmpty {
                    // 空狀態
                    VStack(spacing: 20) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("home.empty.noHistory")
                            .font(.custom("SpotifyMix-Medium", size: 20))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 顯示所有最近播放
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(recentlyPlayed) { item in
                                NavigationLink(destination: TrackDetailView(trackId: item.track.id, accessToken: accessToken, audioPlayer: audioPlayer)) {
                                    RecentlyPlayedRow(item: item, audioPlayer: audioPlayer)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("home.recentlyPlayed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.close") {
                        dismiss()
                    }
                    .font(.custom("SpotifyMix-Medium", size: 18))
                    .foregroundColor(.spotifyGreen)
                }
            }
            .background(Color.spotifyText.ignoresSafeArea())
        }
        .onAppear {
            loadAllRecentlyPlayed()
        }
    }
    
    private func loadAllRecentlyPlayed() {
        isLoading = true
        SpotifyAPIService.fetchRecentlyPlayed(accessToken: accessToken, limit: 50) { tracks in
            DispatchQueue.main.async {
                self.recentlyPlayed = tracks
                self.isLoading = false
            }
        }
    }
}

#Preview {
    RecentlyPlayedView(
        audioPlayer: AudioPlayer(),
        accessToken: "preview_token"
    )
    .preferredColorScheme(.dark)
}

