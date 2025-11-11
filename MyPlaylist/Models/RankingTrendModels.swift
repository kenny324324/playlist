import Foundation

// MARK: - 排名趨勢資料模型

/// 單一排名資料點
struct RankingDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let rank: Int?  // nil 表示跌出榜外
    let isFilled: Bool  // 是否為填補的資料
    let isOutOfChart: Bool  // 是否跌出榜外
}

/// 排名趨勢資料
struct RankingTrend {
    let trackId: String
    let trackName: String
    let dataPoints: [RankingDataPoint]  // 每日 7 個點
    
    var hasData: Bool {
        return !dataPoints.isEmpty
    }
    
    var highestRank: Int? {
        return dataPoints.compactMap { $0.rank }.min()
    }
    
    var lowestRank: Int? {
        return dataPoints.compactMap { $0.rank }.max()
    }
    
    var rankChange: Int? {
        let rankedPoints = dataPoints.filter { $0.rank != nil }
        guard rankedPoints.count >= 2,
              let first = rankedPoints.first?.rank,
              let last = rankedPoints.last?.rank else {
            return nil
        }
        return first - last  // 正數表示上升（排名變小）
    }
    
    /// 從原始歷史記錄創建排名趨勢
    static func from(histories: [RankingHistory], trackName: String) -> RankingTrend {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Debug: 輸出原始資料
        print("📊 [RankingTrend] 收到 \(histories.count) 筆歷史記錄")
        for history in histories.prefix(5) {
            print("  - \(history.recordedDate): Rank #\(history.rank)")
        }
        
        // 生成過去 7 天的日期（包含今天，所以是從 -6 到 0）
        let past7Days = (0...6).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: today)
        }.reversed()  // 反轉，讓最早的在前面
        
        print("📊 [RankingTrend] 查詢過去 7 天（包含今天）：")
        for date in past7Days {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            formatter.timeZone = calendar.timeZone
            print("  - \(formatter.string(from: date))")
        }
        
        // 按日期分組原始資料
        let groupedByDay = Dictionary(grouping: histories) { history in
            calendar.startOfDay(for: history.recordedDate)
        }
        
        print("📊 [RankingTrend] 按日期分組後有 \(groupedByDay.keys.count) 天有資料")
        
        // 為每一天生成資料點
        var points: [RankingDataPoint] = []
        var lastKnownRank: Int? = nil
        var consecutiveMissing = 0
        
        for date in past7Days {
            if let dayHistories = groupedByDay[date],
               let latest = dayHistories.max(by: { $0.recordedDate < $1.recordedDate }) {
                // 有資料：使用當天最新記錄
                points.append(RankingDataPoint(
                    date: latest.recordedDate,
                    rank: latest.rank,
                    isFilled: false,
                    isOutOfChart: false
                ))
                lastKnownRank = latest.rank
                consecutiveMissing = 0
            } else {
                consecutiveMissing += 1
                
                if consecutiveMissing >= 2 {
                    // 連續缺失 2+ 天：判定為跌出榜外
                    points.append(RankingDataPoint(
                        date: calendar.date(byAdding: .hour, value: 12, to: date)!,
                        rank: nil,
                        isFilled: false,
                        isOutOfChart: true
                    ))
                } else if let lastRank = lastKnownRank {
                    // 缺失 1 天：使用前一天的排名填補
                    points.append(RankingDataPoint(
                        date: calendar.date(byAdding: .hour, value: 12, to: date)!,
                        rank: lastRank,
                        isFilled: true,
                        isOutOfChart: false
                    ))
                } else {
                    // 一開始就沒資料：跌出榜外
                    points.append(RankingDataPoint(
                        date: calendar.date(byAdding: .hour, value: 12, to: date)!,
                        rank: nil,
                        isFilled: false,
                        isOutOfChart: true
                    ))
                }
            }
        }
        
        return RankingTrend(
            trackId: histories.first?.trackId ?? "",
            trackName: trackName,
            dataPoints: points
        )
    }
}

