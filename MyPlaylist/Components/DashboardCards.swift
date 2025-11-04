import SwiftUI

// MARK: - 今日聆聽時間卡片
struct TodayListeningCard: View {
    let minutes: Int
    let trackCount: Int
    let lastUpdated: Date
    let onTap: () -> Void
    
    @State private var displayedMinutes: Int = 0
    @State private var displayedTrackCount: Int = 0
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // 標題與歌曲數量
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.spotifyGreen)
                    Text("dashboard.todayListening")
                        .font(.custom("SpotifyMix-Bold", size: 18))
                        .foregroundColor(.white)
                    Spacer()
                    
                    // 歌曲數量（右上角）
                    HStack(spacing: 4) {
                        Text("\(displayedTrackCount)")
                            .font(.custom("SpotifyMix-Bold", size: 13))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.easeOut(duration: 1.2), value: displayedTrackCount)
                        Text("dashboard.tracksCount")
                            .font(.custom("SpotifyMix-Medium", size: 13))
                            .foregroundColor(.gray)
                            .animation(nil, value: displayedTrackCount)
                    }
                }
                
                Spacer()  // 自適應填充空間
                
                // 主要數字（只顯示分鐘）
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(displayedMinutes)")
                        .font(.custom("SpotifyMix-Extrabold", size: 48))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 1.2), value: displayedMinutes)
                    Text("dashboard.minutes")
                        .font(.custom("SpotifyMix-Medium", size: 18))
                        .foregroundColor(.gray)
                        .animation(nil, value: displayedMinutes)  // 取消文字動畫
                }
                
                Spacer()  // 自適應填充空間
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 160)  // 固定高度，與佔位符一致
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.spotifyGreen.opacity(0.15),
                        Color(red: 0.12, green: 0.12, blue: 0.12)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.spotifyGreen.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // 數字增長動畫
            animateNumbers()
        }
        .onChange(of: minutes) { _ in
            animateNumbers()
        }
    }
    
    private func animateNumbers() {
        // 重置為 0
        displayedMinutes = 0
        displayedTrackCount = 0
        
        // 使用固定的動畫時長
        withAnimation(.easeOut(duration: 1.2)) {
            displayedMinutes = minutes
            displayedTrackCount = trackCount
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return String(localized: "dashboard.justNow")
        } else if seconds < 3600 {
            let mins = seconds / 60
            // 使用固定格式，不同語言在 Localizable.xcstrings 中定義
            if Locale.current.language.languageCode?.identifier == "zh" {
                return "\(mins) 分鐘前"
            } else {
                return "\(mins) min ago"
            }
        } else {
            let hours = seconds / 3600
            if Locale.current.language.languageCode?.identifier == "zh" {
                return "\(hours) 小時前"
            } else {
                return "\(hours) hr ago"
            }
        }
    }
}

// MARK: - 每月熱門項目卡片
struct WeeklyTopCard: View {
    let title: String
    let icon: String
    let entries: [WeeklyTopEntry]
    let showViewAll: Bool
    let onTapEntry: (WeeklyTopEntry) -> Void
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // 標題（與 HomeView 其他區域一致）
            Text(title)
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            // 項目列表
            if entries.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(entries.prefix(3).enumerated()), id: \.element.id) { index, entry in
                        WeeklyTopRow(entry: entry, rank: index + 1, onTap: {
                            onTapEntry(entry)
                        })
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("dashboard.empty.noData")
                .font(.custom("SpotifyMix-Medium", size: 18))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(16)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .cornerRadius(15)
    }
}

// MARK: - 每月熱門項目行
struct WeeklyTopRow: View {
    let entry: WeeklyTopEntry
    let rank: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 8) {
                // 排名和變化指示器（與 TrackRow 一致）
                VStack(spacing: 5) {
                    // 排名變化指示器
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 12, height: 2)
                        .cornerRadius(1)
                    
                    Text("#\(rank)")
                        .foregroundColor(.white)
                        .font(.custom("SpotifyMix-Bold", size: 22))
                        .lineLimit(1)
                }
                .frame(width: 50, alignment: .center)
                
                // 灰色框框內容
                HStack(spacing: 6) {
                    // 封面圖
                    AsyncImage(url: entry.imageUrl.flatMap { URL(string: $0) }) { phase in
                        switch phase {
                        case .empty:
                            placeholderImage
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(entry.artistName == nil ? 3 : 6)  // 藝人稍微圓一點，歌曲方形
                    .clipped()
                    
                    // 資訊
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.name)
                            .font(.custom("SpotifyMix-Bold", size: 17))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if let artistName = entry.artistName {
                            Text(artistName)
                                .font(.custom("SpotifyMix-Medium", size: 15))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // 箭頭
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .frame(height: 45)
                .padding(8)
                .padding(.trailing, 12)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(10)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var placeholderImage: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Image(systemName: entry.artistName == nil ? "person.fill" : "music.note")
                .foregroundColor(.gray)
                .font(.system(size: 16))
        }
    }
}

// MARK: - 載入中的 Dashboard 佔位符
struct DashboardLoadingPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 今日聆聽卡片佔位符 - 與實際卡片樣式一致
            VStack(alignment: .leading, spacing: 0) {
                // 標題與右上角歌曲數量佔位符
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 18)
                    Spacer()
                    // 右上角歌曲數量佔位符（無 icon）
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 13)
                }
                .shimmer()
                
                Spacer()  // 自適應填充空間
                
                // 數字佔位符
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 48)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 18)
                }
                .shimmer()
                
                Spacer()  // 自適應填充空間
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 160)  // 固定高度
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.spotifyGreen.opacity(0.15),
                        Color(red: 0.12, green: 0.12, blue: 0.12)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.spotifyGreen.opacity(0.3), lineWidth: 1)
            )
            
            // 本月熱門佔位符（與實際樣式一致）
            ForEach(0..<2) { section in
                VStack(alignment: .leading, spacing: 15) {
                    // 標題佔位符
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 22)
                        .shimmer()
                    
                    // 項目佔位符
                    VStack(spacing: 10) {
                        ForEach(0..<3) { _ in
                            HStack(alignment: .center, spacing: 8) {
                                // 排名佔位符
                                VStack(spacing: 5) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 12, height: 2)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 35, height: 22)
                                }
                                .frame(width: 50)
                                
                                // 卡片佔位符
                                HStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.3))
                                        .aspectRatio(1, contentMode: .fit)
                                        .shimmer()
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 150, height: 17)
                                            .shimmer()
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 100, height: 15)
                                            .shimmer()
                                    }
                                    
                                    Spacer()
                                }
                                .frame(height: 45)
                                .padding(8)
                                .padding(.trailing, 12)
                                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Dashboard 空狀態
struct DashboardEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("dashboard.empty.title")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            Text("dashboard.empty.message")
                .font(.custom("SpotifyMix-Medium", size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .cornerRadius(15)
    }
}

