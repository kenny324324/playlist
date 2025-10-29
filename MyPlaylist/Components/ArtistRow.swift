import SwiftUI

// MARK: - 漸層淡出文字視圖
struct ArtistFadingText: View {
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
            
            // 右側漸層遮罩
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

struct ArtistRow: View {
    let artist: Artist
    let index: Int  // 顯示藝術家的排名
    
    // 格式化追蹤者數量
    private func formatFollowers(_ count: Int) -> String {
        let locale = Locale.current
        let isChineseLocale = locale.language.languageCode?.identifier == "zh"
        
        if isChineseLocale {
            // 中文：使用「萬位追蹤者」
            if count >= 10000 {
                let value = Double(count) / 10000.0
                return String(format: "%.1f萬位追蹤者", value)
            } else {
                return "\(count)位追蹤者"
            }
        } else {
            // 英文：使用「M followers」、「B followers」
            if count >= 1_000_000_000 {
                let value = Double(count) / 1_000_000_000.0
                return String(format: "%.1fB followers", value)
            } else if count >= 1_000_000 {
                let value = Double(count) / 1_000_000.0
                return String(format: "%.1fM followers", value)
            } else if count >= 1_000 {
                let value = Double(count) / 1_000.0
                return String(format: "%.1fK followers", value)
            } else {
                return "\(count) followers"
            }
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // 跟 TrackRow 一樣的左側排名區塊
            VStack(spacing: 5) {
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

            // 右側內容卡片
            HStack(spacing: 6) {
                // 藝術家圖片
                AsyncImage(url: URL(string: artist.images.first?.url ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "person.fill")
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
                            Image(systemName: "person.fill")
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

                // 藝術家名稱與追蹤者
                VStack(alignment: .leading, spacing: 4) {
                    ArtistFadingText(
                        text: artist.name,
                        font: .custom("SpotifyMix-Bold", size: 17),
                        foregroundColor: .white,
                        backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                    )

                    ArtistFadingText(
                        text: formatFollowers(artist.followers.total),
                        font: .custom("SpotifyMix-Medium", size: 15),
                        foregroundColor: .gray,
                        backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                    )
                }

                Spacer()

                // 受歡迎程度
                VStack(spacing: 2) {
                    Text("component.popularity")
                        .foregroundColor(.gray)
                        .font(.custom("SpotifyMix-Medium", size: 14))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("\(artist.popularity)")
                        .foregroundColor(Color.spotifyGreen)
                        .font(.custom("SpotifyMix-Medium", size: 16))
                }
                .frame(width: 70, alignment: .trailing)
            }
            .frame(height: 45)
            .padding(8)
            .padding(.trailing, 12)
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(PlainButtonStyle())
    }
}
