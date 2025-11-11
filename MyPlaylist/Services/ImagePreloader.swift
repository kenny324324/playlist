import UIKit
import Foundation

// MARK: - 圖片預載服務
/// 在列表滾動前預先載入即將出現的圖片，提升滾動流暢度

class ImagePreloader {
    static let shared = ImagePreloader()
    
    // 預載隊列（低優先級，不影響主執行緒）
    private let preloadQueue = DispatchQueue(label: "com.myplaylist.imagepreload", qos: .utility)
    
    // 預載任務追蹤（避免重複預載）
    private var preloadingURLs = Set<String>()
    private let lock = NSLock()
    
    private init() {}
    
    // MARK: - 預載 Track 圖片
    /// 預載一組 Track 的封面圖
    func preloadTracks(_ tracks: [Track]) {
        let imageURLs = tracks.compactMap { $0.album.images.first?.url }
        preloadImages(urls: imageURLs)
    }
    
    // MARK: - 預載 Artist 圖片
    /// 預載一組 Artist 的頭像
    func preloadArtists(_ artists: [Artist]) {
        let imageURLs = artists.compactMap { $0.images.first?.url }
        preloadImages(urls: imageURLs)
    }
    
    // MARK: - 預載指定範圍的項目
    /// 當列表滾動時，預載接下來 5-10 個項目的圖片
    func preloadTracksInRange(_ tracks: [Track], currentIndex: Int, lookahead: Int = 10) {
        let startIndex = max(0, currentIndex)
        let endIndex = min(tracks.count, currentIndex + lookahead)
        
        guard startIndex < endIndex else { return }
        
        let tracksToPreload = Array(tracks[startIndex..<endIndex])
        preloadTracks(tracksToPreload)
    }
    
    // MARK: - 通用預載方法
    private func preloadImages(urls: [String]) {
        guard !urls.isEmpty else { return }
        
        PerformanceLogger.shared.logImagePreload(count: urls.count)
        
        preloadQueue.async { [weak self] in
            guard let self = self else { return }
            
            for url in urls {
                // 檢查是否已經在快取中
                if ImageCache.shared.get(forKey: url) != nil {
                    continue
                }
                
                // 檢查是否正在預載
                self.lock.lock()
                let isPreloading = self.preloadingURLs.contains(url)
                if !isPreloading {
                    self.preloadingURLs.insert(url)
                }
                self.lock.unlock()
                
                if isPreloading {
                    continue
                }
                
                // 開始預載
                self.downloadAndCacheImage(url: url)
            }
        }
    }
    
    // MARK: - 下載並快取圖片
    private func downloadAndCacheImage(url: String) {
        guard let imageURL = URL(string: url) else {
            removeFromPreloading(url)
            return
        }
        
        var request = URLRequest(url: imageURL)
        request.timeoutInterval = 10.0 // 預載可以用較長的超時時間
        request.cachePolicy = .returnCacheDataElseLoad
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            defer {
                self?.removeFromPreloading(url)
            }
            
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                return
            }
            
            // 儲存到快取
            ImageCache.shared.set(image, forKey: url)
        }.resume()
    }
    
    // MARK: - 清理預載狀態
    private func removeFromPreloading(_ url: String) {
        lock.lock()
        preloadingURLs.remove(url)
        lock.unlock()
    }
    
    // MARK: - 取消所有預載
    func cancelAll() {
        lock.lock()
        preloadingURLs.removeAll()
        lock.unlock()
    }
    
    // MARK: - 智能預載（根據可見範圍）
    /// 智能預載：根據當前可見的項目自動預載前後項目
    func smartPreload(tracks: [Track], visibleIndices: [Int], lookahead: Int = 8, lookbehind: Int = 3) {
        guard let firstVisibleIndex = visibleIndices.min() else { return }
        
        // 預載前面的項目
        let startIndex = max(0, firstVisibleIndex - lookbehind)
        
        // 預載後面的項目
        let endIndex = min(tracks.count, firstVisibleIndex + lookahead)
        
        guard startIndex < endIndex else { return }
        
        let tracksToPreload = Array(tracks[startIndex..<endIndex])
        preloadTracks(tracksToPreload)
    }
}

