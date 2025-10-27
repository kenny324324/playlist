import SwiftUI

struct GenreRow: View {
    let index: Int  // 類型的編號
    let genre: String  // 類型名稱
    let count: Int  // 顯示次數

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // 左側排名數字
            Text("#\(index)")
                .foregroundColor(.gray)
                .font(.custom("SpotifyMix-Bold", size: 18))
                .lineLimit(1)
                .frame(width: 35, alignment: .center)

            // 右側內容卡片
            HStack(spacing: 12) {
                // 類型名稱
                Text(genre.capitalized)
                    .foregroundColor(.white)
                    .font(.custom("SpotifyMix-Bold", size: 15))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                // 類型的聆聽次數
                Text("\(count) times")
                    .foregroundColor(.gray)
                    .font(.custom("SpotifyMix-Medium", size: 13))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(10)
        }
    }
}
