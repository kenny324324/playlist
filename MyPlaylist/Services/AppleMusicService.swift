import Foundation
import MusicKit

@MainActor
class AppleMusicService: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    
    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// 檢查授權狀態
    func checkAuthorizationStatus() async {
        let status = await MusicAuthorization.currentStatus
        authorizationStatus = status
        isAuthorized = (status == .authorized)
    }
    
    /// 請求授權
    func requestAuthorization() async -> Bool {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        isAuthorized = (status == .authorized)
        return isAuthorized
    }
    
    // MARK: - Search
    
    /// 搜尋歌曲
    /// - Parameters:
    ///   - trackName: 歌曲名稱
    ///   - artistName: 藝人名稱
    /// - Returns: 找到的第一首歌曲，如果沒找到則返回 nil
    func searchTrack(trackName: String, artistName: String) async -> Song? {
        // 確保已授權
        guard isAuthorized else {
            print("Apple Music 未授權")
            return nil
        }
        
        // 建立搜尋字串
        let searchTerm = "\(trackName) \(artistName)"
        
        do {
            // 建立搜尋請求
            var request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
            request.limit = 5  // 限制結果數量
            
            let response = try await request.response()
            
            // 返回第一個結果
            if let firstSong = response.songs.first {
                print("找到 Apple Music 歌曲: \(firstSong.title) - \(firstSong.artistName)")
                return firstSong
            } else {
                print("在 Apple Music 找不到歌曲: \(searchTerm)")
                return nil
            }
        } catch {
            print("搜尋 Apple Music 歌曲時發生錯誤: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 透過 ISRC 搜尋歌曲（更精確的匹配方式）
    /// - Parameter isrc: International Standard Recording Code
    /// - Returns: 找到的歌曲
    func searchTrackByISRC(_ isrc: String) async -> Song? {
        guard isAuthorized else {
            print("Apple Music 未授權")
            return nil
        }
        
        do {
            var request = MusicCatalogSearchRequest(term: isrc, types: [Song.self])
            request.limit = 1
            
            let response = try await request.response()
            return response.songs.first
        } catch {
            print("透過 ISRC 搜尋時發生錯誤: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Playback Helper
    
    /// 取得歌曲的預覽 URL（如果有的話）
    /// - Parameter song: Apple Music 歌曲
    /// - Returns: 預覽 URL
    func getPreviewURL(for song: Song) -> URL? {
        // MusicKit 的 Song 物件本身就可以直接播放
        // 不需要額外的 preview URL
        return song.previewAssets?.first?.url
    }
}

