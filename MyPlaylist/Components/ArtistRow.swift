import SwiftUI

struct ArtistRow: View {
    let artist: Artist
    let index: Int  // 顯示藝術家的排名

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
                    .font(.custom("SpotifyMix-Bold", size: 20))
                    .lineLimit(1)
            }
            .frame(width: 50, alignment: .center)

            // 右側內容卡片
            HStack(spacing: 12) {
                // 藝術家圖片
                AsyncImageView(
                    url: artist.images.first?.url,
                    placeholder: "person.fill",
                    size: CGSize(width: 45, height: 45),
                    cornerRadius: 6,
                    isCircle: false
                )

                // 藝術家名稱與追蹤者
                VStack(alignment: .leading, spacing: 2) {
                    Text(artist.name)
                        .foregroundColor(.white)
                        .font(.custom("SpotifyMix-Bold", size: 15))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text("Followers: \(artist.followers.total)")
                        .foregroundColor(.gray)
                        .font(.custom("SpotifyMix-Medium", size: 13))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()

                // 受歡迎程度
                VStack(spacing: 2) {
                    Text("Popularity")
                        .foregroundColor(.gray)
                        .font(.custom("SpotifyMix-Medium", size: 12))
                    Text("\(artist.popularity)")
                        .foregroundColor(Color.spotifyGreen)
                        .font(.custom("SpotifyMix-Medium", size: 14))
                }
                .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
