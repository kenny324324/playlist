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
    var rankChange: RankChange?  // 新增：排名變化參數

    // 優化：使用 @State 避免每次重繪時重新計算
    @State private var artistNames: String = ""

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // 排名和變化指示器（在框框外面）
            VStack(spacing: 5) {
                // 排名變化指示器
                rankChangeIndicator
                
                Text("#\(index)")
                    .foregroundColor(.white)
                    .font(.appFont(size: 22, weight: .bold))
                    .lineLimit(1)
            }
            .frame(width: 50, alignment: .center)
            
            // 灰色框框內容
            HStack(spacing: 6) {
                // 專輯封面 - 使用優化的 AsyncImageView（支援快取）
                AsyncImageView(
                    url: track.album.images.first?.url,
                    placeholder: "music.note",
                    size: CGSize(width: 45, height: 45),
                    cornerRadius: 6,
                    isCircle: false
                )

                // 歌曲資訊
                VStack(alignment: .leading, spacing: 4) {
                    FadingText(
                        text: track.name,
                        font: .appFont(size: 17, weight: .bold),
                        foregroundColor: .white,
                        backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                    )

                    FadingText(
                        text: artistNames,
                        font: .appFont(size: 15, weight: .medium),
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
        .onAppear {
            // 只在首次出現時計算藝人名稱
            if artistNames.isEmpty {
                artistNames = track.artists.map(\.name).joined(separator: ", ")
            }
        }
    }
    
    // MARK: - 排名變化指示器
    @ViewBuilder
    private var rankChangeIndicator: some View {
        if let change = rankChange {
            switch change {
            case .up(let amount):
                // 上升：柔和綠色向上三角形
                HStack(spacing: 2) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 13, weight: .bold))
                    if amount > 1 {
                        Text("\(amount)")
                            .font(.system(size: 11, weight: .bold))
                    }
                }
                .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.4))
                .frame(height: 14)
                
            case .down(let amount):
                // 下降：柔和紅色向下三角形
                HStack(spacing: 2) {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 13, weight: .bold))
                    if amount > 1 {
                        Text("\(amount)")
                            .font(.system(size: 11, weight: .bold))
                    }
                }
                .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.4))
                .frame(height: 14)
                
            case .new:
                // 新進榜：藍色 "NEW"
                Text("NEW")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.85))
                    .frame(height: 14)
                
            case .same:
                // 不變：灰色橫線
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 12, height: 2)
                    .cornerRadius(1)
            }
        } else {
            // 沒有資料：灰色橫線
            Rectangle()
                .fill(Color.gray)
                .frame(width: 12, height: 2)
                .cornerRadius(1)
        }
    }
}
