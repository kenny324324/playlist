import AVFoundation

class AudioPlayer: ObservableObject {
    @Published var isPlaying: Bool = false  // 播放狀態
    @Published var currentPreviewUrl: String?  // 當前播放音檔的 URL
    @Published var currentTime: Double = 0  // 當前播放時間
    @Published var duration: Double = 0  // 音檔的總時長

    private var player: AVPlayer?
    private var timeObserver: Any?

    // 播放或停止音檔
    func playPreview(from url: String) {
        if currentPreviewUrl == url, isPlaying {
            stop()  // 如果同一首歌正在播放，則停止
        } else {
            stop()  // 確保新播放前停止舊音檔
            startNewPlayback(url: url)
        }
    }

    // 開始播放新音檔
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

        // 更新音檔總時長
        if let duration = player?.currentItem?.asset.duration {
            self.duration = CMTimeGetSeconds(duration)
        } else {
            self.duration = 0
        }
    }

    // 停止播放
    func stop() {
        print("Stopping playback")
        player?.pause()
        player = nil

        // 清除狀態
        isPlaying = false
        currentTime = 0  // 重設播放時間
        duration = 0  // 重設總時長
        currentPreviewUrl = nil

        // 移除時間觀察者
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
}
