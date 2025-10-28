import SwiftUI

// MARK: - 漸層淡出文字視圖
struct GenreFadingText: View {
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

struct GenreRow: View {
    let index: Int  // 類型的編號
    let genre: String  // 類型名稱
    let count: Int  // 顯示次數

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // 左側排名數字
            Text("#\(index)")
                .foregroundColor(.gray)
                .font(.custom("SpotifyMix-Bold", size: 20))
                .lineLimit(1)
                .frame(width: 35, alignment: .center)

            // 右側內容卡片
            HStack(spacing: 12) {
                // 類型名稱
                GenreFadingText(
                    text: genre.capitalized,
                    font: .custom("SpotifyMix-Bold", size: 17),
                    foregroundColor: .white,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )

                Spacer()

                // 類型的聆聽次數
                Text("\(count) times")
                    .foregroundColor(.gray)
                    .font(.custom("SpotifyMix-Medium", size: 15))
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
