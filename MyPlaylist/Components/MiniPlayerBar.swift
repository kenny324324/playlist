import SwiftUI

// MARK: - 底部迷你播放條
struct MiniPlayerBar: View {
    let track: CurrentlyPlayingTrack?
    @ObservedObject var audioPlayer: AudioPlayer
    let onTapTrack: (String) -> Void
    
    @State private var dominantColor: Color = Color.gray.opacity(0.2)
    
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
                            .onAppear {
                                extractDominantColor(from: image)
                            }
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
                        .font(.appFont(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(track.artists.map(\.name).joined(separator: ", "))
                        .font(.appFont(size: 11, weight: .medium))
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
                ZStack {
                    // 漸變背景
                    LinearGradient(
                        gradient: Gradient(colors: [
                            dominantColor.opacity(0.5),
                            dominantColor.opacity(0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                    // 頂部細線分隔
                    VStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 0.3)
                        Spacer()
                    }
                }
            )
            .contentShape(Rectangle())  // 整個區域都可以點擊
            .onTapGesture {
                onTapTrack(track.id)
            }
            .animation(.easeInOut(duration: 0.5), value: dominantColor)
            .onChange(of: track.id) { _ in
                // 當歌曲切換時重置顏色
                dominantColor = Color.gray.opacity(0.2)
            }
        } else {
            // 沒有播放中的歌曲
            HStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
                
                Text("player.noCurrentlyPlaying")
                    .font(.appFont(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.leading, 18)
            .padding(.trailing, 14)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Helper Methods
    private func extractDominantColor(from image: Image) {
        // 將 SwiftUI Image 轉換為 UIImage
        let renderer = ImageRenderer(content: image)
        if let uiImage = renderer.uiImage {
            uiImage.getDominantColor { color in
                if let color = color {
                    dominantColor = Color(color)
                }
            }
        }
    }
}
