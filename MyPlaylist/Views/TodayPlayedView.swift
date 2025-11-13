import SwiftUI

// MARK: - 今日播放記錄頁面
struct TodayPlayedView: View {
    let accessToken: String
    @ObservedObject var audioPlayer: AudioPlayer
    @Environment(\.dismiss) var dismiss
    
    @State private var tracks: [TodayPlayedTrack]
    @State private var totalMinutes: Int
    @State private var isRefreshing = false
    @State private var refreshRotation: Double = 0
    
    init(tracks: [TodayPlayedTrack], totalMinutes: Int, accessToken: String, audioPlayer: AudioPlayer) {
        self.accessToken = accessToken
        self._audioPlayer = ObservedObject(initialValue: audioPlayer)
        _tracks = State(initialValue: tracks)
        _totalMinutes = State(initialValue: totalMinutes)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 頂部統計信息
                statsHeader
                
                // 歌曲列表
                if tracks.isEmpty {
                    emptyState
                } else {
                    tracksList
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.spotifyText.ignoresSafeArea())
        .navigationTitle(todayDateString)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    guard !isRefreshing else { return }
                    withAnimation(.easeInOut(duration: 0.5)) {
                        refreshRotation += 360
                    }
                    refresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(refreshRotation))
                }
                .disabled(isRefreshing)
            }
        }
        .onAppear {
            if tracks.isEmpty {
                refresh()
            }
        }
    }
    
    private func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        DashboardMetricsService.shared.fetchTodayListeningMinutes(accessToken: accessToken) { minutes, _, tracks in
            DispatchQueue.main.async {
                self.totalMinutes = minutes
                self.tracks = tracks
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isRefreshing = false
                }
            }
        }
    }
    
    // MARK: - 頂部統計
    private var statsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("todayPlayed.title")
                .font(.appFont(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 24) {
                // 總時長
                VStack(alignment: .leading, spacing: 4) {
                    Text("todayPlayed.totalDuration")
                        .font(.appFont(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(totalMinutes)")
                            .font(.appFont(size: 28, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                        Text("todayPlayed.minutes")
                            .font(.appFont(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                // 歌曲數量
                VStack(alignment: .leading, spacing: 4) {
                    Text("todayPlayed.trackCount")
                        .font(.appFont(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(tracks.count)")
                            .font(.appFont(size: 28, weight: .bold))
                            .foregroundColor(.spotifyGreen)
                        Text("todayPlayed.tracks")
                            .font(.appFont(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    // MARK: - 歌曲列表
    private var tracksList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("todayPlayed.playbackHistory")
                .font(.appFont(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(tracks) { track in
                    NavigationLink(destination: TrackDetailView(trackId: track.id.components(separatedBy: "_").first ?? track.id, accessToken: accessToken, audioPlayer: audioPlayer)) {
                        TodayPlayedRow(track: track, audioPlayer: audioPlayer)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - 空狀態
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("todayPlayed.empty")
                .font(.appFont(size: 18, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - 日期字串
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
}

// MARK: - 今日播放記錄行
struct TodayPlayedRow: View {
    let track: TodayPlayedTrack
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 6) {
            // 專輯封面
            AsyncImage(url: track.imageUrl.flatMap { URL(string: $0) }) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(8)
            .clipped()
            
            // 歌曲信息
            VStack(alignment: .leading, spacing: 4) {
                HomeFadingText(
                    text: track.name,
                    font: .appFont(size: 16, weight: .medium),
                    foregroundColor: .white,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
                
                HomeFadingText(
                    text: "\(track.artistName) · \(track.durationFormatted)",
                    font: .appFont(size: 14, weight: .medium),
                    foregroundColor: .gray,
                    backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12)
                )
            }
            
            Spacer()
            
            // 播放時間（右側）
            Text(track.formattedTime)
                .font(.appFont(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(height: 45)
        .padding(8)
        .padding(.trailing, 12)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
}
