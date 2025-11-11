import SwiftUI

// MARK: - 排名趨勢曲線圖

struct RankingTrendChart: View {
    let trend: RankingTrend
    @State private var selectedPoint: RankingDataPoint? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            chartHeader
            
            GeometryReader { geometry in
                ZStack {
                    verticalDateLines(in: geometry.size)
                    dataPointLabels(in: geometry.size)
                    trendPath(in: geometry.size)
                    dataPointCircles(in: geometry.size)
                }
            }
            .frame(height: 160)
            .padding(.top, 20)  // 頂部留白，避免標籤碰到上方文字
            
            dateLabels
        }
    }
    
    // MARK: - 圖表標題和統計
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("rankingTrend.past7Days")
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(.gray)
                
                if let change = trend.rankChange {
                    HStack(spacing: 4) {
                        if change == 0 {
                            Image(systemName: "minus")
                                .font(.system(size: 12))
                            Text("rankingTrend.noChange")
                                .font(.custom("SpotifyMix-Medium", size: 14))
                        } else {
                            Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 12))
                            Text(change > 0 ? "+\(change)" : "\(change)")
                                .font(.custom("SpotifyMix-Bold", size: 16))
                        }
                    }
                    .foregroundColor(change > 0 ? .spotifyGreen : change < 0 ? .red : .gray)
                }
            }
            
            Spacer()
            
            if let highest = trend.highestRank, let lowest = trend.lowestRank {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("rankingTrend.best")
                            .font(.custom("SpotifyMix-Medium", size: 11))
                            .foregroundColor(.gray)
                        Text("#\(highest)")
                            .font(.custom("SpotifyMix-Bold", size: 14))
                            .foregroundColor(.spotifyGreen)
                    }
                    HStack(spacing: 4) {
                        Text("rankingTrend.worst")
                            .font(.custom("SpotifyMix-Medium", size: 11))
                            .foregroundColor(.gray)
                        Text("#\(lowest)")
                            .font(.custom("SpotifyMix-Bold", size: 14))
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    // MARK: - 動態 Y 軸範圍計算
    private func calculateYAxisRange() -> (min: Int, max: Int) {
        guard let highest = trend.highestRank,
              let lowest = trend.lowestRank else {
            return (1, 50)
        }
        
        let range = lowest - highest
        let buffer = max(Int(Double(range) * 0.3), 5)
        
        let minRank = max(1, highest - buffer)
        let maxRank = min(50, lowest + buffer)
        
        // 確保至少有 10 的範圍
        if maxRank - minRank < 10 {
            let mid = (minRank + maxRank) / 2
            return (max(1, mid - 5), min(50, mid + 5))
        }
        
        return (minRank, maxRank)
    }
    
    
    // MARK: - 垂直日期線
    private func verticalDateLines(in size: CGSize) -> some View {
        let paddingX: CGFloat = 10  // 左右留白
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
    
    // MARK: - 趨勢路徑（曲線和填充）
    private func trendPath(in size: CGSize) -> some View {
        let yRange = calculateYAxisRange()
        let paddingX: CGFloat = 10  // 左右留白
        let availableWidth = size.width - 2 * paddingX
        
        var path = Path()
        var fillPath = Path()
        var previousPoint: CGPoint? = nil
        var fillStarted = false
        
        for (index, point) in trend.dataPoints.enumerated() {
            let x = paddingX + CGFloat(index) / 6 * availableWidth
            
            if let rank = point.rank {
                // 有排名：正常曲線
                // rankInRange: 0 = 最好排名（在上方 y=0），1 = 最差排名（在下方 y=size.height）
                let rankInRange = CGFloat(rank - yRange.min) / CGFloat(yRange.max - yRange.min)
                let y = rankInRange * size.height  // 修正：移除 (1 - ...)
                let currentPoint = CGPoint(x: x, y: y)
                
                if let prev = previousPoint {
                    path.addLine(to: currentPoint)
                    if fillStarted {
                        fillPath.addLine(to: currentPoint)
                    }
                } else {
                    // 開始新的曲線段
                    path.move(to: currentPoint)
                    fillPath.move(to: CGPoint(x: x, y: size.height))
                    fillPath.addLine(to: currentPoint)
                    fillStarted = true
                }
                
                previousPoint = currentPoint
            } else {
                // 跌出榜外：畫斜線到底部
                if let prev = previousPoint {
                    let bottomPoint = CGPoint(x: x, y: size.height)
                    path.addLine(to: bottomPoint)
                    fillPath.addLine(to: bottomPoint)
                    fillPath.addLine(to: CGPoint(x: prev.x, y: size.height))
                    fillPath.closeSubpath()
                }
                previousPoint = nil
                fillStarted = false
            }
        }
        
        // 結束填充路徑
        if let prev = previousPoint, fillStarted {
            fillPath.addLine(to: CGPoint(x: prev.x, y: size.height))
            fillPath.closeSubpath()
        }
        
        return ZStack {
            // 填充區域（Spotify Green 漸層）
            fillPath.fill(
                LinearGradient(
                    colors: [Color.spotifyGreen.opacity(0.2), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // 曲線（Spotify Green）
            path.stroke(Color.spotifyGreen, lineWidth: 2)
        }
    }
    
    // MARK: - 資料點標籤（排名數字）
    private func dataPointLabels(in size: CGSize) -> some View {
        let yRange = calculateYAxisRange()
        let paddingX: CGFloat = 10  // 左右留白
        let availableWidth = size.width - 2 * paddingX
        
        return ForEach(Array(trend.dataPoints.enumerated()), id: \.offset) { index, point in
            let x = paddingX + CGFloat(index) / 6 * availableWidth
            
            if let rank = point.rank {
                let rankInRange = CGFloat(rank - yRange.min) / CGFloat(yRange.max - yRange.min)
                let y = rankInRange * size.height
                
                // 動態計算標籤位置（上方或下方）
                let labelOffset = calculateLabelOffset(
                    for: index,
                    currentRank: rank,
                    yRange: yRange
                )
                
                // 排名標籤
                Text("#\(rank)")
                    .font(.custom("SpotifyMix-Bold", size: 9))
                    .foregroundColor(.spotifyGreen)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                            .padding(.horizontal, -3)
                            .padding(.vertical, -1)
                    )
                    .position(x: x, y: y + labelOffset)
            }
        }
    }
    
    // MARK: - 計算標籤偏移量（避免與折線重疊）
    private func calculateLabelOffset(for index: Int, currentRank: Int, yRange: (min: Int, max: Int)) -> CGFloat {
        let baseOffset: CGFloat = 15  // 基礎偏移量
        
        // 獲取下一個點的排名
        let nextRank = index < trend.dataPoints.count - 1 ? trend.dataPoints[index + 1].rank : nil
        
        // 如果是最後一個點，標籤放上方
        guard let next = nextRank else {
            return -baseOffset
        }
        
        // 根據到下一個點的走向決定標籤位置
        if next < currentRank {
            // 下一個點排名更好（向上走），標籤放下方避免與向上的線重疊
            return baseOffset
        } else if next > currentRank {
            // 下一個點排名更差（向下走），標籤放上方避免與向下的線重疊
            return -baseOffset
        } else {
            // 持平，標籤放上方
            return -baseOffset
        }
    }
    
    // MARK: - 資料點圓圈
    private func dataPointCircles(in size: CGSize) -> some View {
        let yRange = calculateYAxisRange()
        let paddingX: CGFloat = 10  // 左右留白
        let availableWidth = size.width - 2 * paddingX
        
        return ForEach(Array(trend.dataPoints.enumerated()), id: \.offset) { index, point in
            let x = paddingX + CGFloat(index) / 6 * availableWidth
            
            if let rank = point.rank {
                let rankInRange = CGFloat(rank - yRange.min) / CGFloat(yRange.max - yRange.min)
                let y = rankInRange * size.height
                
                ZStack {
                    // 圓點（所有點都用 Spotify Green）
                    Circle()
                        .fill(Color.spotifyGreen)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                    
                    // 加上背景色外框
                    Circle()
                        .stroke(Color(red: 0.15, green: 0.15, blue: 0.15), lineWidth: 2)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
    }
    
    // MARK: - X 軸日期標籤
    private var dateLabels: some View {
        GeometryReader { geometry in
            let paddingX: CGFloat = 10  // 左右留白
            let availableWidth = geometry.size.width - 2 * paddingX
            
            ForEach(0..<7) { i in
                let date = Calendar.current.date(byAdding: .day, value: -6 + i, to: Date())!
                let x = paddingX + CGFloat(i) / 6 * availableWidth
                
                Text(formatDate(date))
                    .font(.custom("SpotifyMix-Medium", size: 11))
                    .foregroundColor(.white)
                    .position(x: x, y: 10)
            }
        }
        .frame(height: 20)
    }
    
    // MARK: - 輔助方法
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    let mockTrend = RankingTrend(
        trackId: "test",
        trackName: "Test Song",
        dataPoints: [
            RankingDataPoint(date: Date(), rank: 10, isFilled: false, isOutOfChart: false),
            RankingDataPoint(date: Date(), rank: 8, isFilled: false, isOutOfChart: false),
            RankingDataPoint(date: Date(), rank: 5, isFilled: false, isOutOfChart: false),
            RankingDataPoint(date: Date(), rank: 5, isFilled: true, isOutOfChart: false),
            RankingDataPoint(date: Date(), rank: 3, isFilled: false, isOutOfChart: false),
            RankingDataPoint(date: Date(), rank: nil, isFilled: false, isOutOfChart: true),
            RankingDataPoint(date: Date(), rank: 15, isFilled: false, isOutOfChart: false)
        ]
    )
    
    return RankingTrendChart(trend: mockTrend)
        .padding(16)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(12)
        .padding()
        .background(Color.spotifyText)
}

