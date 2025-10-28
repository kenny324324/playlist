import SwiftUI

// MARK: - 漸層淡出文字視圖
struct FadingText: View {
    let text: String
    let font: Font
    let foregroundColor: Color
    let backgroundColor: Color
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 原始文字
            Text(text)
                .font(font)
                .foregroundColor(foregroundColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 右側漸層遮罩 - 從透明到背景色
            HStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: backgroundColor.opacity(0), location: 0.0),
                        .init(color: backgroundColor.opacity(0.3), location: 0.3),
                        .init(color: backgroundColor.opacity(0.7), location: 0.7),
                        .init(color: backgroundColor, location: 1.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 25)
            }
            .allowsHitTesting(false)
        }
        .frame(height: 20)
    }
}

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
                    .font(.custom("SpotifyMix-Bold", size: 22))
                    .lineLimit(1)
            }
            .frame(width: 50, alignment: .center)
            
            // 灰色框框內容
            HStack(spacing: 6) {
                // 專輯封面
                AsyncImage(url: URL(string: track.album.images.first?.url ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
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
                                .font(.system(size: 16))
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(6)
                .clipped()

                // 歌曲資訊
                VStack(alignment: .leading, spacing: 4) {
                    FadingText(
                        text: track.name,
                        font: .custom("SpotifyMix-Bold", size: 17),
                        foregroundColor: .white,
                        backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                    )

                    FadingText(
                        text: track.artists.map(\.name).joined(separator: ", "),
                        font: .custom("SpotifyMix-Medium", size: 15),
                        foregroundColor: .gray,
                        backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                    )
                }

                Spacer()

                // 右箭頭
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .frame(height: 45)
            .padding(8)
            .padding(.trailing, 12)
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
    }
}
