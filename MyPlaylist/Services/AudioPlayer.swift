import AVFoundation
import MusicKit

@MainActor
class AudioPlayer: ObservableObject {
    @Published var isPlaying: Bool = false  // 播放狀態
    @Published var currentPreviewUrl: String?  // 當前播放音檔的 URL（用於 Spotify）
    @Published var currentTrackId: String?  // 當前播放的歌曲 ID
    @Published var currentTime: Double = 0  // 當前播放時間
    @Published var duration: Double = 0  // 音檔的總時長
    @Published var playbackSource: PlaybackSource = .none  // 播放來源

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var appleMusicPlayer = ApplicationMusicPlayer.shared
    private var appleMusicService: AppleMusicService?
    
    enum PlaybackSource {
        case none
        case spotify
        case appleMusic
    }
    
    init() {
        self.appleMusicService = AppleMusicService()
    }

    // MARK: - Spotify Preview Playback
    
    /// 播放 Spotify 預覽（使用 URL）
    func playPreview(from url: String) {
        if currentPreviewUrl == url, isPlaying, playbackSource == .spotify {
            stop()  // 如果同一首歌正在播放，則停止
        } else {
            stop()  // 確保新播放前停止舊音檔
            startNewPlayback(url: url)
        }
    }
    
    // MARK: - Smart Playback with Apple Music Fallback
    
    /// 智能播放：優先使用 Spotify，如果沒有則使用 Apple Music
    func playTrack(trackName: String, artistName: String, spotifyPreviewUrl: String?, trackId: String) async {
        // 如果正在播放同一首歌，則停止
        if currentTrackId == trackId, isPlaying {
            stop()
            return
        }
        
        stop()  // 停止當前播放
        currentTrackId = trackId
        
        // 優先使用 Spotify preview URL
        if let previewUrl = spotifyPreviewUrl, !previewUrl.isEmpty {
            print("使用 Spotify preview URL 播放")
            startNewPlayback(url: previewUrl)
            playbackSource = .spotify
            return
        }
        
        // Fallback 到 Apple Music
        print("Spotify preview URL 不可用，嘗試使用 Apple Music")
        await playWithAppleMusic(trackName: trackName, artistName: artistName)
    }
    
    // MARK: - Apple Music Playback
    
    /// 使用 Apple Music 播放預覽（只播放 30 秒預覽版）
    private func playWithAppleMusic(trackName: String, artistName: String) async {
        guard let service = appleMusicService else {
            print("Apple Music Service 未初始化")
            return
        }
        
        // 確保已授權
        if !service.isAuthorized {
            let authorized = await service.requestAuthorization()
            if !authorized {
                print("Apple Music 授權失敗")
                return
            }
        }
        
        // 搜尋歌曲
        guard let song = await service.searchTrack(trackName: trackName, artistName: artistName) else {
            print("在 Apple Music 找不到歌曲")
            return
        }
        
        print("找到 Apple Music 歌曲: \(song.title)")
        
        // 獲取預覽 URL（30 秒片段）
        guard let previewAsset = song.previewAssets?.first else {
            print("此歌曲沒有預覽片段")
            return
        }
        
        guard let previewURL = previewAsset.url else {
            print("無法獲取預覽 URL")
            return
        }
        
        print("開始播放 Apple Music 預覽: \(previewURL.absoluteString)")
        
        // 使用 AVPlayer 播放預覽（就像播放 Spotify preview 一樣）
        startNewPlayback(url: previewURL.absoluteString)
        playbackSource = .appleMusic
    }
    
    /// 停止 Apple Music 播放
    private func stopAppleMusic() {
        appleMusicPlayer.stop()
    }

    // MARK: - Spotify AVPlayer Playback
    
    /// 開始播放新音檔（Spotify URL）
    private func startNewPlayback(url: String) {
        guard let audioUrl = URL(string: url) else {
            print("無效的音訊 URL")
            return
        }

        print("Starting new playback for URL: \(url)")
        player = AVPlayer(url: audioUrl)

        // 確保移除舊的時間觀察者，避免重複
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }

        // 設置時間觀察者來更新進度
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
        }

        // 播放並更新狀態
        player?.play()
        currentPreviewUrl = url
        isPlaying = true
        playbackSource = .spotify

        // 更新音檔總時長
        if let duration = player?.currentItem?.asset.duration {
            self.duration = CMTimeGetSeconds(duration)
        } else {
            self.duration = 0
        }
    }

    // MARK: - Stop Playback
    
    /// 停止播放（處理所有來源）
    func stop() {
        print("Stopping playback (Source: \(playbackSource))")
        
        // 停止 Spotify AVPlayer
        player?.pause()
        player = nil
        
        // 停止 Apple Music
        if playbackSource == .appleMusic {
            stopAppleMusic()
        }

        // 清除狀態
        isPlaying = false
        currentTime = 0  // 重設播放時間
        duration = 0  // 重設總時長
        currentPreviewUrl = nil
        currentTrackId = nil
        playbackSource = .none

        // 移除時間觀察者
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
}
