import SwiftUI

// MARK: - 排名趨勢曲線圖

struct RankingTrendChart: View {
    let trend: RankingTrend
    @State private var selectedPoint: RankingDataPoint? = nil
    @State private var pulseAnimation: Bool = false
    @State private var lineProgress: CGFloat = 0.0  // 折線繪製進度
    
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
        .onAppear {
            // 啟動折線繪製動畫（從左到右，勻速）
            withAnimation(Animation.linear(duration: 0.5)) {
                lineProgress = 1.0
            }
            
            // 啟動波紋動畫（延遲啟動，等折線繪製完成）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    pulseAnimation = true
                }
            }
        }
    }
    
    // MARK: - 圖表標題和統計
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("rankingTrend.past7Days")
                    .font(.appFont(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                if let change = trend.rankChange {
                    HStack(spacing: 4) {
                        if change == 0 {
                            Image(systemName: "minus")
                                .font(.system(size: 12))
                            Text("rankingTrend.noChange")
                                .font(.appFont(size: 14, weight: .medium))
                        } else {
                            Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 12))
                            Text(change > 0 ? "+\(change)" : "\(change)")
                                .font(.appFont(size: 16, weight: .bold))
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
                            .font(.appFont(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                        Text("#\(highest)")
                            .font(.appFont(size: 14, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                    }
                    HStack(spacing: 4) {
                        Text("rankingTrend.worst")
                            .font(.appFont(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                        Text("#\(lowest)")
                            .font(.appFont(size: 14, weight: .bold))
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
        
        var completePath = Path()  // 完整的連續路徑（實線）
        var dashedPath = Path()  // 虛線路徑（進榜/出榜，疊加在完整路徑上）
        var fillPath = Path()
        var previousPoint: CGPoint? = nil
        var previousWasOutOfChart = false  // 追蹤前一個點是否在榜外
        var fillStarted = false
        var isFirstSegment = true
        
        for (index, point) in trend.dataPoints.enumerated() {
            let x = paddingX + CGFloat(index) / 6 * availableWidth
            
            if let rank = point.rank {
                // 有排名：正常曲線
                let rankInRange = CGFloat(rank - yRange.min) / CGFloat(yRange.max - yRange.min)
                let y = rankInRange * size.height
                let currentPoint = CGPoint(x: x, y: y)
                
                if let prev = previousPoint {
                    // 前一個點存在且在榜內：正常連線（實線）
                    completePath.addLine(to: currentPoint)
                    if fillStarted {
                        fillPath.addLine(to: currentPoint)
                    }
                } else if previousWasOutOfChart && index > 0 {
                    // 前一個點在榜外，當前點進榜
                    // 如果進榜到最低排名，不畫虛線（因為會是平的）
                    if rank == yRange.max {
                        if isFirstSegment {
                            completePath.move(to: currentPoint)
                            isFirstSegment = false
                        }
                        fillPath.move(to: CGPoint(x: x, y: size.height))
                        fillPath.addLine(to: currentPoint)
                        fillStarted = true
                    } else {
                        // 從中間點畫斜線到當前點（虛線）
                        let prevX = paddingX + CGFloat(index - 1) / 6 * availableWidth
                        let midX = (prevX + x) / 2  // 兩個日期的中間點
                        let bottomPoint = CGPoint(x: midX, y: size.height)
                        
                        if isFirstSegment {
                            completePath.move(to: bottomPoint)
                            dashedPath.move(to: bottomPoint)
                            isFirstSegment = false
                        } else {
                            completePath.addLine(to: bottomPoint)
                            dashedPath.move(to: bottomPoint)
                        }
                        completePath.addLine(to: currentPoint)
                        dashedPath.addLine(to: currentPoint)
                        
                        // 填充也從底部開始
                        fillPath.move(to: bottomPoint)
                        fillPath.addLine(to: currentPoint)
                        fillStarted = true
                    }
                } else {
                    // 第一個點：開始新的曲線段
                    if isFirstSegment {
                        completePath.move(to: currentPoint)
                        isFirstSegment = false
                    }
                    fillPath.move(to: CGPoint(x: x, y: size.height))
                    fillPath.addLine(to: currentPoint)
                    fillStarted = true
                }
                
                previousPoint = currentPoint
                previousWasOutOfChart = false
            } else {
                // 跌出榜外：畫斜線到中間點的底部（虛線）
                // 但如果前一個點是最低排名，不畫虛線（因為會是平的）
                if let prev = previousPoint, index > 0 {
                    // 檢查前一個點的排名
                    if let prevRank = trend.dataPoints[index - 1].rank, prevRank == yRange.max {
                        // 從最低排名掉出榜外，不畫虛線
                    } else {
                        let prevX = paddingX + CGFloat(index - 1) / 6 * availableWidth
                        let midX = (prevX + x) / 2  // 兩個日期的中間點
                        let bottomPoint = CGPoint(x: midX, y: size.height)
                        
                        completePath.addLine(to: bottomPoint)
                        dashedPath.move(to: prev)
                        dashedPath.addLine(to: bottomPoint)
                    }
                    
                    // 關閉填充路徑
                    if fillStarted {
                    fillPath.addLine(to: CGPoint(x: prev.x, y: size.height))
                    fillPath.closeSubpath()
                    }
                }
                previousPoint = nil
                previousWasOutOfChart = true
                fillStarted = false
            }
        }
        
        // 結束填充路徑
        if let prev = previousPoint, fillStarted {
            fillPath.addLine(to: CGPoint(x: prev.x, y: size.height))
            fillPath.closeSubpath()
        }
        
        return ZStack {
            // 填充區域（Spotify Green 漸層）- 使用遮罩跟隨折線顯示
            fillPath
                .fill(
                LinearGradient(
                    colors: [Color.spotifyGreen.opacity(0.2), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
                .mask(
                    Rectangle()
                        .frame(width: size.width * lineProgress, height: size.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                )
            
            // 先繪製完整路徑作為底層（實線）
            completePath
                .trim(from: 0, to: lineProgress)
                .stroke(Color.spotifyGreen, lineWidth: 2)
            
            // 在進榜/出榜部分疊加虛線
            dashedPath
                .trim(from: 0, to: lineProgress)
                .stroke(
                    Color.spotifyGreen,
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: [5, 3]
                    )
                )
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
                
                // 計算淡入延遲（根據點的位置）
                let delay = Double(index) * 0.08
                
                // 排名標籤
                Text("#\(rank)")
                    .font(.appFont(size: 9, weight: .bold))
                    .foregroundColor(.spotifyGreen)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                            .padding(.horizontal, -3)
                            .padding(.vertical, -1)
                    )
                    .position(x: x, y: y + labelOffset)
                    .opacity(lineProgress >= CGFloat(index) / 6.0 ? 1.0 : 0.0)
                    .animation(.linear(duration: 0.1).delay(delay), value: lineProgress)
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
        let lastIndex = trend.dataPoints.count - 1  // 最後一個點的索引
        
        return ForEach(Array(trend.dataPoints.enumerated()), id: \.offset) { index, point in
            let x = paddingX + CGFloat(index) / 6 * availableWidth
            let isLatestPoint = index == lastIndex  // 是否為最新的點
            
            if let rank = point.rank {
                let rankInRange = CGFloat(rank - yRange.min) / CGFloat(yRange.max - yRange.min)
                let y = rankInRange * size.height
                
                // 計算出現延遲（根據點的位置）
                let delay = Double(index) * 0.08
                
                // 計算該點應該顯示的進度閾值
                let pointThreshold = CGFloat(index) / 6.0
                
                ZStack {
                    // 波紋效果（只顯示在最新的點，始終渲染但根據動畫狀態控制顯示）
                    if isLatestPoint {
                        Circle()
                            .stroke(Color.spotifyGreen.opacity(0.5), lineWidth: 2)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseAnimation ? 2.5 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 1.0)
                            .position(x: x, y: y)
                        
                        Circle()
                            .stroke(Color.spotifyGreen.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseAnimation ? 3.5 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 0.8)
                            .position(x: x, y: y)
                    }
                    
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
                .opacity(lineProgress >= pointThreshold ? 1.0 : 0.0)
                .animation(.linear(duration: 0.2).delay(delay), value: lineProgress)
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
                    .font(.appFont(size: 11, weight: .medium))
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

