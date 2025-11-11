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

// 圖片快取類別 - 優化版本（記憶體 + 磁碟快取）
class ImageCache {
    static let shared = ImageCache()
    
    // 記憶體快取
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // 磁碟快取目錄
    private let diskCacheURL: URL
    
    // 快取隊列（避免競態條件）
    private let cacheQueue = DispatchQueue(label: "com.myplaylist.imagecache", attributes: .concurrent)
    
    private init() {
        // 設定記憶體快取限制
        memoryCache.countLimit = 150 // 最多快取 150 張圖片（原本 100）
        memoryCache.totalCostLimit = 1024 * 1024 * 100 // 100MB（原本 50MB）
        
        // 設定磁碟快取目錄
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = cacheDir.appendingPathComponent("ImageCache", isDirectory: true)
        
        // 創建磁碟快取目錄
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // 監聽記憶體警告，清理快取
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // 定期清理過期的磁碟快取（7天）
        Task {
            await cleanExpiredDiskCache()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 讀取快取（記憶體 -> 磁碟）
    func get(forKey key: String) -> UIImage? {
        // 1. 先查記憶體快取
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        // 2. 查磁碟快取
        if let diskImage = getDiskCache(forKey: key) {
            // 將磁碟圖片加載回記憶體快取
            let cost = diskImage.pngData()?.count ?? 0
            memoryCache.setObject(diskImage, forKey: key as NSString, cost: cost)
            return diskImage
        }
        
        return nil
    }
    
    // MARK: - 儲存快取（記憶體 + 磁碟）
    func set(_ image: UIImage, forKey key: String) {
        // 計算圖片大小（用於記憶體快取限制）
        let cost = image.pngData()?.count ?? 0
        
        // 1. 儲存到記憶體快取
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
        
        // 2. 非同步儲存到磁碟快取
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.setDiskCache(image, forKey: key)
        }
    }
    
    // MARK: - 移除快取
    func remove(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.removeDiskCache(forKey: key)
        }
    }
    
    // MARK: - 清空所有快取
    func removeAll() {
        memoryCache.removeAllObjects()
        
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.removeItem(at: self.diskCacheURL)
            try? FileManager.default.createDirectory(at: self.diskCacheURL, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - 記憶體警告處理
    @objc private func handleMemoryWarning() {
        PerformanceLogger.shared.logMemoryWarning()
        PerformanceLogger.shared.log("清理圖片快取", icon: "🧹")
        memoryCache.removeAllObjects()
    }
    
    // MARK: - 磁碟快取操作
    private func getDiskCache(forKey key: String) -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(key.md5Hash)
        
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // 更新最後訪問時間（用於 LRU 清理）
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: fileURL.path
        )
        
        return image
    }
    
    private func setDiskCache(_ image: UIImage, forKey key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileURL = diskCacheURL.appendingPathComponent(key.md5Hash)
        try? data.write(to: fileURL)
    }
    
    private func removeDiskCache(forKey key: String) {
        let fileURL = diskCacheURL.appendingPathComponent(key.md5Hash)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - 清理過期快取（7天前的）
    private func cleanExpiredDiskCache() async {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }
        
        let expirationDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7天前
        var removedCount = 0
        
        for fileURL in files {
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let modificationDate = attributes[.modificationDate] as? Date else {
                continue
            }
            
            if modificationDate < expirationDate {
                try? fileManager.removeItem(at: fileURL)
                removedCount += 1
            }
        }
        
        if removedCount > 0 {
            PerformanceLogger.shared.logImageCacheCleaned(count: removedCount)
        }
    }
    
    // MARK: - 獲取快取大小
    func getCacheSize() -> String {
        var totalSize: Int64 = 0
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return "0 MB"
        }
        
        for fileURL in files {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }
        
        let sizeInMB = Double(totalSize) / (1024 * 1024)
        return String(format: "%.2f MB", sizeInMB)
    }
}

// MARK: - String MD5 擴充（用於生成快取檔案名稱）
extension String {
    var md5Hash: String {
        let data = Data(self.utf8)
        let hash = data.reduce(0) { ($0 << 5) &- $0 &+ Int($1) }
        return "\(abs(hash))"
    }
} 