import SwiftUI

// MARK: - 底部迷你播放條
struct MiniPlayerBar: View {
    let track: CurrentlyPlayingTrack?
    @ObservedObject var audioPlayer: AudioPlayer
    let onTapTrack: (String) -> Void
    
    var body: some View {
        if let track = track {
            HStack(spacing: 12) {
                // 專輯封面
                AsyncImage(url: URL(string: track.album.images.first?.url ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.3)
                            ProgressView()
                                .tint(.white)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 32, height: 32)
                .cornerRadius(4)
                .clipped()
                
                // 歌曲資訊
                VStack(alignment: .leading, spacing: 3) {
                    Text(track.name)
                        .font(.custom("SpotifyMix-Bold", size: 13))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(track.artists.map(\.name).joined(separator: ", "))
                        .font(.custom("SpotifyMix-Medium", size: 11))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 播放按鈕（如果有預覽 URL）
                if let previewUrl = track.preview_url {
                    Button(action: {
                        audioPlayer.playPreview(from: previewUrl)
                    }) {
                        Image(systemName: audioPlayer.isPlaying && audioPlayer.currentPreviewUrl == previewUrl ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.leading, 18)
            .padding(.trailing, 14)
            .padding(.vertical, 6)
            .background(
                // 頂部細線分隔
                VStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 0.3)
                    Spacer()
                }
            )
            .contentShape(Rectangle())  // 整個區域都可以點擊
            .onTapGesture {
                onTapTrack(track.id)
            }
        } else {
            // 沒有播放中的歌曲
            HStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
                
                Text("player.noCurrentlyPlaying")
                    .font(.custom("SpotifyMix-Medium", size: 13))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.leading, 18)
            .padding(.trailing, 14)
            .padding(.vertical, 8)
        }
    }
}


