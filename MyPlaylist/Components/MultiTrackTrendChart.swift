import SwiftUI

// MARK: - 多軌排名趨勢圖表（Top 5）

struct MultiTrackTrendChart: View {
    let trends: [TrackTrend]  // Top 5 歌曲的趨勢
    @State private var lineProgress: CGFloat = 0.0
    @State private var pulseAnimation: Bool = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // 主題顏色順序（使用系統定義的 10 種主題色）
    private let themeColors: [ThemeColor] = [
        .color1,   // #1
        .color2,   // #2
        .color3,   // #3
        .color4,   // #4
        .color5,   // #5
        .color6,   // #6
        .color7,   // #7
        .color8,   // #8
        .color9,   // #9
        .color10   // #10
    ]
    
    // 根據索引安全獲取顏色（跟隨當前色調）
    private func getColor(for index: Int) -> Color {
        let themeColor = themeColors[index % themeColors.count]
        return themeColor.color(for: themeManager.currentTone)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 圖表
            GeometryReader { geometry in
                ZStack {
                    // Y軸標籤
                    yAxisLabels(in: geometry.size)
                    
                    // 垂直日期線
                    verticalDateLines(in: geometry.size)
                    
                    // 所有歌曲的折線
                    ForEach(Array(trends.enumerated()), id: \.offset) { index, trackTrend in
                        trackPath(for: trackTrend, color: getColor(for: index), in: geometry.size)
                    }
                    
                    // 所有歌曲的資料點
                    ForEach(Array(trends.enumerated()), id: \.offset) { index, trackTrend in
                        dataPointCircles(for: trackTrend, color: getColor(for: index), isTopRank: index == 0, in: geometry.size)
                    }
                }
            }
            .frame(height: 160)
            .padding(.leading, 30)  // 為Y軸留空間
            .padding(.trailing, 10)
            
            // X軸日期標籤
            dateLabels
                .padding(.leading, 30)
            
            // 圖例
            trackLegend
        }
        .onAppear {
            // 啟動折線繪製動畫
            withAnimation(Animation.linear(duration: 0.5)) {
                lineProgress = 1.0
            }
            
            // 啟動波紋動畫（只在第一名）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    pulseAnimation = true
                }
            }
        }
    }
    
    // MARK: - Y軸標籤
    private func yAxisLabels(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            ForEach(1...5, id: \.self) { rank in
                Text("#\(rank)")
                    .font(.appFont(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(height: size.height / 4)
            }
        }
        .frame(width: 25, height: size.height, alignment: .leading)
        .position(x: -15, y: size.height / 2)
    }
    
    // MARK: - 垂直日期線
    private func verticalDateLines(in size: CGSize) -> some View {
        let paddingX: CGFloat = 10
        let availableWidth = size.width - 2 * paddingX
        
        return Path { path in
            for i in 0..<7 {
                let x = paddingX + CGFloat(i) / 6 * availableWidth
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
        }
        .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
    }
    
    // MARK: - 單一歌曲的折線路徑
    private func trackPath(for trackTrend: TrackTrend, color: Color, in size: CGSize) -> some View {
        let paddingX: CGFloat = 10
        let availableWidth = size.width - 2 * paddingX
        
        var solidPath = Path()  // 實線路徑（在 Top 5 內）
        var dashedPath = Path()  // 虛線路徑（進出 Top 5）
        var previousPoint: CGPoint? = nil
        var previousWasOutOfTop5 = false
        
        for (index, point) in trackTrend.dataPoints.enumerated() {
            let x = paddingX + CGFloat(index) / 6 * availableWidth
            
            if let rank = point.rank, rank <= 5 {
                // 在 Top 5 內
                let y = size.height * CGFloat(rank - 1) / 4
                let currentPoint = CGPoint(x: x, y: y)
                
                if let prev = previousPoint {
                    // 前一個點存在且在 Top 5：正常連線（實線）
                    solidPath.addLine(to: currentPoint)
                } else if previousWasOutOfTop5 && index > 0 {
                    // 前一個點在榜外，當前點進榜：從中間點畫虛線到當前點
                    let prevX = paddingX + CGFloat(index - 1) / 6 * availableWidth
                    let midX = (prevX + x) / 2  // 兩個日期的中間點
                    let bottomPoint = CGPoint(x: midX, y: size.height)
                    
                    dashedPath.move(to: bottomPoint)
                    dashedPath.addLine(to: currentPoint)
                    
                    // 當前點設為實線的起點
                    solidPath.move(to: currentPoint)
                } else {
                    // 第一個點：開始新的線段
                    solidPath.move(to: currentPoint)
                }
                
                previousPoint = currentPoint
                previousWasOutOfTop5 = false
            } else {
                // 掉出 Top 5：畫虛線到中間點的底部
                if let prev = previousPoint, index > 0 {
                    let prevX = paddingX + CGFloat(index - 1) / 6 * availableWidth
                    let midX = (prevX + x) / 2  // 兩個日期的中間點
                    let bottomPoint = CGPoint(x: midX, y: size.height)
                    
                    dashedPath.move(to: prev)
                    dashedPath.addLine(to: bottomPoint)
                }
                previousPoint = nil
                previousWasOutOfTop5 = true
            }
        }
        
        return ZStack {
            // 虛線（進出 Top 5）
            dashedPath
                .trim(from: 0, to: lineProgress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: 2.5,
                        dash: [5, 3]
                    )
                )
            
            // 實線（在 Top 5 內）
            solidPath
                .trim(from: 0, to: lineProgress)
                .stroke(color, lineWidth: 2.5)
        }
    }
    
    // MARK: - 資料點圓圈
    private func dataPointCircles(for trackTrend: TrackTrend, color: Color, isTopRank: Bool, in size: CGSize) -> some View {
        let paddingX: CGFloat = 10
        let availableWidth = size.width - 2 * paddingX
        let lastIndex = trackTrend.dataPoints.count - 1
        
        return ForEach(Array(trackTrend.dataPoints.enumerated()), id: \.offset) { index, point in
            let x = paddingX + CGFloat(index) / 6 * availableWidth
            let isLatestPoint = index == lastIndex
            let delay = Double(index) * 0.08
            let pointThreshold = CGFloat(index) / 6.0
            
            if let rank = point.rank, rank <= 5 {
                let y = size.height * CGFloat(rank - 1) / 4
                
                ZStack {
                    // 波紋效果（只在第一名且是最新的點）
                    if isTopRank && isLatestPoint {
                        Circle()
                            .stroke(color.opacity(0.5), lineWidth: 2)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseAnimation ? 2.5 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 1.0)
                            .position(x: x, y: y)
                        
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseAnimation ? 3.5 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 0.8)
                            .position(x: x, y: y)
                    }
                    
                    // 圓點
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                    
                    // 背景色外框
                    Circle()
                        .stroke(Color(red: 0.15, green: 0.15, blue: 0.15), lineWidth: 2)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
                .opacity(lineProgress >= pointThreshold ? 1.0 : 0.0)
                .animation(.linear(duration: 0.1).delay(delay), value: lineProgress)
            }
        }
    }
    
    // MARK: - X軸日期標籤
    private var dateLabels: some View {
        GeometryReader { geometry in
            let paddingX: CGFloat = 10
            let availableWidth = geometry.size.width - 2 * paddingX
            
            ForEach(0..<7) { i in
                let date = Calendar.current.date(byAdding: .day, value: -6 + i, to: Date())!
                let x = paddingX + CGFloat(i) / 6 * availableWidth
                
                Text(formatDate(date))
                    .font(.appFont(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .position(x: x, y: 10)
            }
        }
        .frame(height: 20)
    }
    
    // MARK: - 圖例
    private var trackLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 直接按照 trends 順序顯示（HomeView 已排序）
            ForEach(Array(trends.enumerated()), id: \.offset) { index, trackTrend in
                HStack(spacing: 8) {
                    // 顏色指示器
                    Circle()
                        .fill(getColor(for: index))
                        .frame(width: 10, height: 10)
                    
                    // 歌曲資訊
                    Text(trackTrend.trackName)
                        .font(.appFont(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("•")
                        .foregroundColor(.gray)
                        .font(.system(size: 10))
                    
                    Text(trackTrend.artistName)
                        .font(.appFont(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .cornerRadius(10)
    }
    
    // MARK: - 輔助方法
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - 資料模型

struct TrackTrend: Identifiable {
    let id: String
    let trackName: String
    let artistName: String
    let dataPoints: [RankingDataPoint]
    
    init(track: Track, dataPoints: [RankingDataPoint]) {
        self.id = track.id
        self.trackName = track.name
        self.artistName = track.artists.first?.name ?? ""
        self.dataPoints = dataPoints
    }
}

// MARK: - Preview
#Preview {
    let mockTrends = [
        TrackTrend(
            track: Track(id: "1", name: "Song A", previewUrl: nil, artists: [Track.TrackArtist(id: "a1", name: "Artist A")], album: Track.TrackAlbum(id: "al1", name: "Album", images: [])),
            dataPoints: [
                RankingDataPoint(date: Date(), rank: 2, isFilled: false, isOutOfChart: false),
                RankingDataPoint(date: Date(), rank: 1, isFilled: false, isOutOfChart: false),
                RankingDataPoint(date: Date(), rank: 1, isFilled: false, isOutOfChart: false),
                RankingDataPoint(date: Date(), rank: 1, isFilled: false, isOutOfChart: false),
                RankingDataPoint(date: Date(), rank: 1, isFilled: false, isOutOfChart: false),
                RankingDataPoint(date: Date(), rank: 1, isFilled: false, isOutOfChart: false),
                RankingDataPoint(date: Date(), rank: 1, isFilled: false, isOutOfChart: false)
            ]
        ),
        TrackTrend(
            track: Track(id: "2", name: "Song B", previewUrl: nil, artists: [Track.TrackArtist(id: "a2", name: "Artist B")], album: Track.TrackAlbum(id: "al2", name: "Album", images: [])),
            dataPoints: [
                RankingDataPoint(date: Date(), rank: 1, isFilled: false, isOutOfChart: false),
                RankingDataPoint(date: Date(), rank: 2, isFilled: false, isOutOfChart: false),
                RankingDataPoint(date: Date(), rank: 3, isFilled: false, isOutOfChart: false),
                RankingDataPoint(date: Date(), rank: 2, isFilled: false, isOutOfChart: false),
                RankingDataPoint(date: Date(), rank: 2, isFilled: false, isOutOfChart: false),
                RankingDataPoint(date: Date(), rank: 2, isFilled: false, isOutOfChart: false),
                RankingDataPoint(date: Date(), rank: 2, isFilled: false, isOutOfChart: false)
            ]
        )
    ]
    
    return MultiTrackTrendChart(trends: mockTrends)
        .padding(16)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(12)
        .padding()
        .background(Color.spotifyText)
}

