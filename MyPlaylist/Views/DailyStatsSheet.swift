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
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 標題區域
                    headerSection
                    
                    // 歌曲列表
                    if isLoading {
                        loadingPlaceholder()
                    } else if trackDetails.isEmpty {
                        emptyState
                    } else {
                        tracksList
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 22))
                    }
                }
            }
        }
        .onAppear {
            loadTracks()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formatDate(date))
                .font(.appFont(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            if let histories = histories {
                Text("\(histories.count) \(String(localized: "stats.chart.tracks")) · \(targetName)")
                    .font(.appFont(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            } else {
                Text("--")
                    .font(.appFont(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
    }
    
    // MARK: - Tracks List
    private var tracksList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(trackDetails.enumerated()), id: \.offset) { index, item in
                    DailyTrackRow(
                        trackId: item.trackId,
                        rank: item.rank,
                        trackDetail: item.detail,
                        accessToken: accessToken,
                        audioPlayer: audioPlayer
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    
                    if index < trackDetails.count - 1 {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.leading, 90)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Loading Placeholder
    private func loadingPlaceholder() -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { index in
                    HStack(spacing: 12) {
                        // 排名佔位符
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 20)
                            .shimmer()
                        
                        // 封面佔位符
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .shimmer()
                        
                        // 歌曲資訊佔位符
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
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
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
        guard let histories = histories, !histories.isEmpty else {
            isLoading = false
            return
        }
        
        // 按排名排序
        let sortedHistories = histories.sorted { $0.rank < $1.rank }
        
        // 初始化 trackDetails（先設為 nil）
        trackDetails = sortedHistories.map { (trackId: $0.trackId, rank: $0.rank, detail: nil) }
        
        // 使用 DispatchGroup 來等待所有請求完成
        let group = DispatchGroup()
        
        for (index, history) in sortedHistories.enumerated() {
            group.enter()
            SpotifyAPIService.fetchTrackDetail(trackId: history.trackId, accessToken: accessToken) { detail in
                DispatchQueue.main.async {
                    if index < self.trackDetails.count {
                        self.trackDetails[index].detail = detail
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
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

// MARK: - Daily Track Row
struct DailyTrackRow: View {
    let trackId: String
    let rank: Int
    let trackDetail: TrackDetail?
    let accessToken: String
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        NavigationLink(destination: TrackDetailView(
            trackId: trackId,
            accessToken: accessToken,
            audioPlayer: audioPlayer
        )) {
            HStack(spacing: 12) {
                // 排名
                Text("#\(rank)")
                    .font(.appFont(size: 14, weight: .bold))
                    .foregroundColor(.spotifyGreen)
                    .frame(width: 40, alignment: .leading)
                
                if let track = trackDetail {
                    // 封面
                    if let imageUrl = track.album.images.first?.url, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                    }
                    
                    // 歌曲資訊
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.name)
                            .font(.appFont(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(track.artists.map { $0.name }.joined(separator: ", "))
                            .font(.appFont(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                } else {
                    // 佔位符（載入中）
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
    }
}

