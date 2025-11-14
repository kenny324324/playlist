import SwiftUI

// MARK: - 單日統計 Sheet
struct DailyStatsSheet: View {
    let date: Date
    let targetName: String  // 專輯或藝人名稱
    let histories: [RankingHistory]?  // nil 表示載入中
    let accessToken: String
    @ObservedObject var audioPlayer: AudioPlayer
    @Environment(\.dismiss) private var dismiss
    
    @State private var trackDetails: [(trackId: String, rank: Int, detail: TrackDetail?)] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.spotifyText.ignoresSafeArea()
                
                if histories == nil {
                    // 等待 CloudKit 查詢
                    loadingView
                } else if isLoading {
                    // 正在載入歌曲詳情
                    loadingView
                } else if trackDetails.isEmpty {
                    // 沒有資料
                    emptyStateView
                } else {
                    // 顯示歌曲列表
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            subtitleView
                                .padding(.top, 20)
                                .padding(.bottom, 8)
                            
                            LazyVStack(spacing: 0) {
                                ForEach(Array(trackDetails.enumerated()), id: \.offset) { index, item in
                                    NavigationLink(destination: TrackDetailView(
                                        trackId: item.trackId,
                                        accessToken: accessToken,
                                        audioPlayer: audioPlayer
                                    )) {
                                        trackRowView(
                                            trackId: item.trackId,
                                            rank: item.rank,
                                            trackDetail: item.detail
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 8)
                            
                            Spacer(minLength: 24)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle(formatDate(date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                    .foregroundColor(.spotifyGreen)
                    .font(.appFont(size: 16, weight: .bold))
                }
            }
        }
        .onAppear {
            print("📱 [DailyStatsSheet] onAppear - histories: \(histories?.count ?? -1) 筆")
            loadTracks()
        }
        .onChange(of: histories) { newHistories in
            print("🔄 [DailyStatsSheet] onChange - histories: \(newHistories?.count ?? -1) 筆")
            // 當 histories 從 nil 變為有值時重新載入
            if newHistories != nil {
                loadTracks()
            }
        }
    }
    
    // MARK: - Subtitle View
    private var subtitleView: some View {
        let count = histories?.count ?? 0
        let text = "\(count) \(String(localized: "stats.chart.tracks")) · \(targetName)"
        return Text(text)
            .font(.appFont(size: 14, weight: .medium))
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }
    
    // MARK: - Track Row View
    private func trackRowView(trackId: String, rank: Int, trackDetail: TrackDetail?) -> some View {
        HStack(spacing: 12) {
            // 排名
            Text("#\(rank)")
                .font(.appFont(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let track = trackDetail {
                // 封面
                if let imageUrl = track.album.images.first?.url, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 56, height: 56)
                    .cornerRadius(8)
                }
                
                // 歌曲資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.appFont(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(track.artists.map { $0.name }.joined(separator: ", "))
                        .font(.appFont(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            } else {
                // 佔位符（載入中）
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 56, height: 56)
                    .shimmer()
                
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 18)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 14)
                        .shimmer()
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .spotifyGreen))
                .scaleEffect(1.2)
            
            Text(String(localized: "common.loading"))
                .font(.appFont(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(String(localized: "stats.chart.noData"))
                .font(.appFont(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Load Tracks
    private func loadTracks() {
        print("📊 [DailyStatsSheet] loadTracks() called")
        print("  - histories: \(histories?.count ?? -1) 筆")
        print("  - isLoading: \(isLoading)")
        
        guard let histories = histories, !histories.isEmpty else {
            print("⚠️ [DailyStatsSheet] histories 是 nil 或空")
            // histories 為 nil 或空，保持 loading 狀態等待數據
            if histories != nil {
                // histories 不是 nil 但是空的，表示真的沒有資料
                print("  → histories 是空陣列，設置 isLoading = false")
                isLoading = false
            } else {
                print("  → histories 是 nil，保持 isLoading = true")
            }
            // 如果 histories 是 nil，保持 isLoading = true，繼續顯示 loading
            return
        }
        
        // 開始載入歌曲詳情
        print("✅ [DailyStatsSheet] 開始載入 \(histories.count) 首歌曲")
        isLoading = true
        
        // 按排名排序
        let sortedHistories = histories.sorted { $0.rank < $1.rank }
        
        // 初始化 trackDetails（先設為 nil）
        trackDetails = sortedHistories.map { (trackId: $0.trackId, rank: $0.rank, detail: nil) }
        print("  - trackDetails 已初始化，共 \(trackDetails.count) 筆")
        
        // 使用 DispatchGroup 來等待所有請求完成
        let group = DispatchGroup()
        
        for (index, history) in sortedHistories.enumerated() {
            group.enter()
            print("🔍 [DailyStatsSheet] 查詢歌曲 \(index + 1)/\(sortedHistories.count): \(history.trackId)")
            SpotifyAPIService.fetchTrackDetail(trackId: history.trackId, accessToken: accessToken) { detail in
                DispatchQueue.main.async {
                    if index < self.trackDetails.count {
                        self.trackDetails[index].detail = detail
                        print("✅ [DailyStatsSheet] 取得歌曲 \(index + 1) 詳情: \(detail?.name ?? "nil")")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            print("🎉 [DailyStatsSheet] 所有歌曲載入完成，設置 isLoading = false")
            self.isLoading = false
        }
    }
    
    // MARK: - Format Date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/dd (EEE)"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
}
