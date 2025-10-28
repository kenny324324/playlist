import SwiftUI
import UIKit

struct PlayerView: View {
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var showPlayer: Bool
    @Binding var currentTrack: Track?  // 接收並綁定目前播放的歌曲

    @State private var dominantColor: Color = .white
    @State private var albumImage: UIImage? = nil

    static let imageCache = NSCache<NSString, UIImage>()  // 公開快取

    var body: some View {
        ZStack {
            // 使用主要色調作為背景
            dominantColor
                .opacity(0.8)
                .edgesIgnoringSafeArea(.all)

            HStack(spacing: 15) {
                // 顯示專輯封面
                if let albumImage = albumImage {
                    Image(uiImage: albumImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }

                // 顯示歌曲資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentTrack?.name ?? "Unknown Track")
                        .foregroundColor(.primary)
                        .font(.custom("SpotifyMix-Medium", size: 14))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(currentTrack?.artists.map(\.name).joined(separator: ", ") ?? "Unknown Artist")
                        .foregroundColor(.white)
                        .font(.custom("SpotifyMix-Medium", size: 12))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()

                // 停止播放按鈕
                Button(action: {
                    audioPlayer.stop()
                    withAnimation {
                        showPlayer = false
                    }
                }) {
                    Text("Stop")
                        .foregroundColor(.white)
                        .frame(width: 80, height: 30)
                        .background(Color.spotifyGreen)
                        .cornerRadius(10)
                }
                .padding(.trailing, 10)
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 60)
        .clipShape(TopCornerRoundedRectangle(radius: 10))
        .shadow(radius: 10)
        .transition(.move(edge: .bottom))
        .animation(.easeInOut, value: showPlayer)
        .onChange(of: currentTrack) { _ in
            // 每次切換歌曲時重置並加載封面和色調
            resetAlbumData()
            loadAlbumImage()
        }
    }

    // 重置封面和色調
    private func resetAlbumData() {
        albumImage = nil
        dominantColor = .white
    }

    // 加載專輯封面並設置主要色調
    private func loadAlbumImage() {
        guard let track = currentTrack,
              let imageUrl = track.album.images.first?.url,
              let url = URL(string: imageUrl) else { return }

        if let cachedImage = Self.imageCache.object(forKey: url.absoluteString as NSString) {
            albumImage = cachedImage
            extractDominantColor(from: cachedImage)
        } else {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    // 檢查是否為當前播放的歌曲
                    if track.id == currentTrack?.id {
                        Self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
                        albumImage = image
                        extractDominantColor(from: image)
                    }
                }
            }.resume()
        }
    }

    // 提取主要色調
    private func extractDominantColor(from image: UIImage) {
        image.getDominantColor { color in
            if let color = color {
                dominantColor = Color(color)
            }
        }
    }
}

// 上方圓角矩形
struct TopCornerRoundedRectangle: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.addArc(center: CGPoint(x: radius, y: radius),
                    radius: radius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
        path.addArc(center: CGPoint(x: rect.width - radius, y: radius),
                    radius: radius,
                    startAngle: .degrees(270),
                    endAngle: .degrees(0),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

// UIImage 擴展：提取主要色調
extension UIImage {
    func getDominantColor(completion: @escaping (UIColor?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            guard let cgImage = self.cgImage else {
                completion(nil)
                return
            }
            let width = 10, height = 10
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let rawData = calloc(width * height * 4, MemoryLayout<CUnsignedChar>.size)
            let context = CGContext(data: rawData,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: width * 4,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

            let data = UnsafePointer<CUnsignedChar>(context?.data?.assumingMemoryBound(to: CUnsignedChar.self))
            let totalPixels = width * height

            var red = 0, green = 0, blue = 0

            for i in 0..<totalPixels {
                let pixelIndex = i * 4
                red += Int(data?[pixelIndex] ?? 0)
                green += Int(data?[pixelIndex + 1] ?? 0)
                blue += Int(data?[pixelIndex + 2] ?? 0)
            }

            let avgRed = red / totalPixels
            let avgGreen = green / totalPixels
            let avgBlue = blue / totalPixels

            DispatchQueue.main.async {
                completion(UIColor(red: CGFloat(avgRed) / 255.0,
                                   green: CGFloat(avgGreen) / 255.0,
                                   blue: CGFloat(avgBlue) / 255.0,
                                   alpha: 1.0))
            }
        }
    }
}

#Preview {
    PlayerView(
        audioPlayer: AudioPlayer(),
        showPlayer: .constant(true),
        currentTrack: .constant(Track(
            id: "preview123",
            name: "Preview Song",
            previewUrl: "https://example.com/preview.mp3",
            artists: [Track.TrackArtist(name: "Preview Artist")],
            album: Track.TrackAlbum(images: [Track.TrackAlbum.TrackImage(url: "https://i.scdn.co/image/ab67616d0000b273")])
        ))
    )
    .preferredColorScheme(.dark)
}
