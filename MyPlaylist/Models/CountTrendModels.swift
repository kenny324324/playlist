import Foundation

// MARK: - 數量趨勢數據模型（用於專輯和藝人統計圖表）

/// 單一數量數據點
struct CountDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int  // 該時間點有幾首歌在 Top 50
}

/// 專輯數量趨勢
struct AlbumCountTrend {
    let albumId: String
    let albumName: String
    let dataPoints: [CountDataPoint]  // 最多 7 個點
    
    var hasData: Bool {
        return dataPoints.contains { $0.count > 0 }
    }
    
    var maxCount: Int {
        return dataPoints.map { $0.count }.max() ?? 0
    }
    
    var totalCount: Int {
        return dataPoints.map { $0.count }.reduce(0, +)
    }
}

/// 藝人數量趨勢
struct ArtistCountTrend {
    let artistId: String
    let artistName: String
    let dataPoints: [CountDataPoint]  // 最多 7 個點
    
    var hasData: Bool {
        return dataPoints.contains { $0.count > 0 }
    }
    
    var maxCount: Int {
        return dataPoints.map { $0.count }.max() ?? 0
    }
    
    var totalCount: Int {
        return dataPoints.map { $0.count }.reduce(0, +)
    }
}

