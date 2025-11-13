import SwiftUI

// MARK: - 圖片和顏色快取管理器
class MiniPlayerCacheManager: ObservableObject {
    static let shared = MiniPlayerCacheManager()
    
    private var imageCache: [String: UIImage] = [:]
    private var colorCache: [String: Color] = [:]
    
    func getImage(for url: String) -> UIImage? {
        return imageCache[url]
    }
    
    func setImage(_ image: UIImage, for url: String) {
        imageCache[url] = image
        objectWillChange.send()
    }
    
    func getColor(for trackId: String) -> Color? {
        return colorCache[trackId]
    }
    
    func setColor(_ color: Color, for trackId: String) {
        colorCache[trackId] = color
        objectWillChange.send()
    }
}

// MARK: - 底部迷你播放條
struct MiniPlayerBar: View {
    let track: CurrentlyPlayingTrack?
    @ObservedObject var audioPlayer: AudioPlayer
    let onTapTrack: (String) -> Void
    
    @StateObject private var cache = MiniPlayerCacheManager.shared
    @State private var currentTrackId: String = ""
    @State private var isLoadingImage = false
    
    // 使用 computed property 來避免圖片消失
    private var coverImage: UIImage? {
        guard let track = track,
              let imageUrl = track.album.images.first?.url else {
            return nil
        }
        return cache.getImage(for: imageUrl)
    }
    
    private var dominantColor: Color {
        guard let track = track else {
            return Color.gray.opacity(0.2)
        }
        return cache.getColor(for: track.id) ?? Color.gray.opacity(0.2)
    }
    
    var body: some View {
        if let track = track {
            HStack(spacing: 12) {
                // 專輯封面 - 使用快取圖片
                Group {
                    if let image = coverImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if isLoadingImage {
                        ZStack {
                            Color.gray.opacity(0.3)
                            ProgressView()
                                .tint(.white)
                        }
                    } else {
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        }
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
                    .animation(.easeInOut(duration: 0.3), value: dominantColor)
                    
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
            .onAppear {
                loadTrackDataIfNeeded(track)
            }
            .onChange(of: track.id) { _ in
                loadTrackDataIfNeeded(track)
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
    
    /// 只在需要時加載資料
    private func loadTrackDataIfNeeded(_ track: CurrentlyPlayingTrack) {
        currentTrackId = track.id
        
        guard let imageUrlString = track.album.images.first?.url else {
            return
        }
        
        // 檢查是否已有圖片快取
        let hasImage = cache.getImage(for: imageUrlString) != nil
        let hasColor = cache.getColor(for: track.id) != nil
        
        if hasImage && hasColor {
            // 都有快取，不需要做任何事
            return
        }
        
        if hasImage && !hasColor {
            // 有圖片但沒顏色，提取顏色
            if let cachedImage = cache.getImage(for: imageUrlString) {
                extractAndCacheColor(from: cachedImage, trackId: track.id)
            }
            return
        }
        
        // 沒有圖片快取，需要下載
        if !hasImage {
            isLoadingImage = true
            loadImageFromURL(imageUrlString, trackId: track.id)
        }
    }
    
    /// 從 URL 下載圖片
    private func loadImageFromURL(_ urlString: String, trackId: String) {
        guard let url = URL(string: urlString) else {
            isLoadingImage = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                DispatchQueue.main.async {
                    self.isLoadingImage = false
                }
                return
            }
            
            DispatchQueue.main.async {
                // 存入快取（這會觸發 View 更新，因為 cache 是 @Published）
                self.cache.setImage(image, for: urlString)
                
                if self.currentTrackId == trackId {
                    self.isLoadingImage = false
                }
                
                // 提取並快取顏色
                self.extractAndCacheColor(from: image, trackId: trackId)
            }
        }.resume()
    }
    
    /// 提取並快取主色調
    private func extractAndCacheColor(from image: UIImage, trackId: String) {
        // 檢查是否已經有快取的顏色
        if cache.getColor(for: trackId) != nil {
            return
        }
        
        image.getDominantColor { color in
            if let color = color {
                let swiftUIColor = Color(color)
                // 存入快取（這會觸發 View 更新）
                self.cache.setColor(swiftUIColor, for: trackId)
            }
        }
    }
}
