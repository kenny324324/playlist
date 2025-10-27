import SwiftUI
import UIKit

struct AsyncImageView: View {
    let url: String?
    let placeholder: String
    let size: CGSize
    let cornerRadius: CGFloat
    let isCircle: Bool
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var hasError = false
    
    init(url: String?, 
         placeholder: String = "photo", 
         size: CGSize = CGSize(width: 50, height: 50), 
         cornerRadius: CGFloat = 5,
         isCircle: Bool = false) {
        self.url = url
        self.placeholder = placeholder
        self.size = size
        self.cornerRadius = cornerRadius
        self.isCircle = isCircle
    }
    
    var body: some View {
        Group {
            if let image = image {
                Group {
                    if isCircle {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(Circle())
                    } else {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                }
            } else if hasError {
                // 載入失敗時顯示預設圖示
                Group {
                    if isCircle {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: size.width, height: size.height)
                            .overlay(
                                Image(systemName: placeholder)
                                    .foregroundColor(.gray)
                                    .font(.system(size: min(size.width, size.height) * 0.4))
                            )
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: size.width, height: size.height)
                            .overlay(
                                Image(systemName: placeholder)
                                    .foregroundColor(.gray)
                                    .font(.system(size: min(size.width, size.height) * 0.4))
                            )
                    }
                }
            } else {
                // 載入中顯示預設圖示，不顯示 loading 指示器
                Group {
                    if isCircle {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: size.width, height: size.height)
                            .overlay(
                                Image(systemName: placeholder)
                                    .foregroundColor(.gray)
                                    .font(.system(size: min(size.width, size.height) * 0.4))
                            )
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: size.width, height: size.height)
                            .overlay(
                                Image(systemName: placeholder)
                                    .foregroundColor(.gray)
                                    .font(.system(size: min(size.width, size.height) * 0.4))
                            )
                    }
                }
            }
        }
        .onAppear {
            loadImage()
        }
        .task {
            // 添加一個 2 秒的超時機制
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if isLoading {
                DispatchQueue.main.async {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadImage() {
        guard let urlString = url, !urlString.isEmpty,
              let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.hasError = true
                self.isLoading = false
            }
            return
        }
        
        // 檢查快取
        if let cachedImage = ImageCache.shared.get(forKey: url.absoluteString) {
            DispatchQueue.main.async {
                self.image = cachedImage
                self.isLoading = false
            }
            return
        }
        
        // 設置較短的超時時間，避免長時間載入
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let downloadedImage = UIImage(data: data) {
                    self.image = downloadedImage
                    ImageCache.shared.set(downloadedImage, forKey: url.absoluteString)
                    self.hasError = false
                } else {
                    // 載入失敗，顯示預設圖示
                    self.hasError = true
                }
                self.isLoading = false
            }
        }.resume()
    }
}

// 圖片快取類別
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100 // 最多快取 100 張圖片
        cache.totalCostLimit = 1024 * 1024 * 50 // 50MB
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func removeAll() {
        cache.removeAllObjects()
    }
} 