import SwiftUI

// MARK: - 數量長條圖（專輯/藝人統計）

struct CountBarChart: View {
    let dataPoints: [CountDataPoint]
    let title: String
    let emptyMessage: String?  // 如果有值，顯示空狀態提示
    let onBarTap: ((CountDataPoint) -> Void)?  // 點擊長條的回調
    @State private var animationProgress: CGFloat = 0
    
    private let spotifyGreen = Color(red: 0.114, green: 0.725, blue: 0.329)
    
    init(dataPoints: [CountDataPoint], title: String, emptyMessage: String? = nil, onBarTap: ((CountDataPoint) -> Void)? = nil) {
        self.dataPoints = dataPoints
        self.title = title
        self.emptyMessage = emptyMessage
        self.onBarTap = onBarTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            chartHeader
            
            ZStack {
                GeometryReader { geometry in
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(dataPoints) { point in
                            barColumn(point: point, maxCount: maxCount, in: geometry.size)
                        }
                    }
                }
                .frame(height: 120)  // 從 160 降低到 120
                
                // 空狀態提示（如果有 emptyMessage）
                if let message = emptyMessage {
                    Text(message)
                        .font(.appFont(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, maxHeight: 120)  // 從 160 降低到 120
                }
            }
            
            dateLabels
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animationProgress = 1.0
            }
        }
    }
    
    // MARK: - 圖表標題
    private var chartHeader: some View {
        HStack {
            Text(title)
                .font(.appFont(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    // MARK: - 單個長條
    private func barColumn(point: CountDataPoint, maxCount: Int, in size: CGSize) -> some View {
        let columnWidth = size.width / CGFloat(dataPoints.count)
        let barWidth = columnWidth * 0.7  // 70% 用於長條，30% 用於間距
        let height = maxCount > 0 ? (CGFloat(point.count) / CGFloat(maxCount)) * size.height * animationProgress : 0
        
        return VStack(spacing: 4) {
            // 數字（在長條上方）
            if point.count > 0 {
                Text("\(point.count)")
                    .font(.appFont(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(animationProgress)
            } else {
                Spacer()
                    .frame(height: 16)
            }
            
            // 長條
            RoundedRectangle(cornerRadius: 4)
                .fill(point.count > 0 ? spotifyGreen : Color.gray.opacity(0.2))
                .frame(width: barWidth, height: max(height, point.count > 0 ? 4 : 2))
        }
        .frame(width: columnWidth, height: size.height, alignment: .bottom)
        .contentShape(Rectangle())  // 讓整個區域可點擊
        .onTapGesture {
            // 只有當有資料且有回調時才觸發
            if point.count > 0, let onBarTap = onBarTap {
                onBarTap(point)
            }
        }
    }
    
    // MARK: - X 軸日期標籤
    private var dateLabels: some View {
        HStack(spacing: 0) {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, point in
                Text(formatDate(point.date))
                    .font(.appFont(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - 計算屬性
    private var maxCount: Int {
        return dataPoints.map { $0.count }.max() ?? 0
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    let mockPoints = [
        CountDataPoint(date: Date().addingTimeInterval(-6*24*3600), count: 3),
        CountDataPoint(date: Date().addingTimeInterval(-5*24*3600), count: 5),
        CountDataPoint(date: Date().addingTimeInterval(-4*24*3600), count: 4),
        CountDataPoint(date: Date().addingTimeInterval(-3*24*3600), count: 7),
        CountDataPoint(date: Date().addingTimeInterval(-2*24*3600), count: 6),
        CountDataPoint(date: Date().addingTimeInterval(-1*24*3600), count: 8),
        CountDataPoint(date: Date(), count: 5)
    ]
    
    return ZStack {
        Color.black.ignoresSafeArea()
        
        CountBarChart(dataPoints: mockPoints, title: String(localized: "rankingTrend.past7Days"), emptyMessage: nil)
            .padding(16)
            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            .cornerRadius(12)
            .padding(20)
    }
}

