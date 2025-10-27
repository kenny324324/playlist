import SwiftUI

struct TrackRow: View {
    let track: Track
    let index: Int
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var selectedTrack: Track?
    @Binding var showPlayer: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // 排名和變化指示器（在框框外面）
            VStack(spacing: 5) {
                // 排名變化指示器（目前顯示橫線，未來可顯示上升/下降）
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 12, height: 2)
                    .cornerRadius(1)
                
                Text("#\(index)")
                    .foregroundColor(.white)
                    .font(.custom("SpotifyMix-Bold", size: 20))
                    .lineLimit(1)
            }
            .frame(width: 50, alignment: .center)
            
            // 灰色框框內容
            Button(action: {
                // 點擊後跳轉到歌曲詳情頁面（稍後實現）
                selectedTrack = track
            }) {
                HStack(spacing: 12) {
                    // 專輯封面
                    AsyncImageView(
                        url: track.album.images.first?.url,
                        placeholder: "music.note",
                        size: CGSize(width: 45, height: 45),
                        cornerRadius: 6
                    )

                    // 歌曲資訊
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.name)
                            .foregroundColor(.white)
                            .font(.custom("SpotifyMix-Bold", size: 15))
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Text(track.artists.map(\.name).joined(separator: ", "))
                            .foregroundColor(.gray)
                            .font(.custom("SpotifyMix-Medium", size: 13))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    Spacer()

                    // 右箭頭
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
