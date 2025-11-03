import SwiftUI

// MARK: - 今日播放記錄頁面
struct TodayPlayedView: View {
    let tracks: [TodayPlayedTrack]
    let totalMinutes: Int
    let accessToken: String
    @ObservedObject var audioPlayer: AudioPlayer
    @Environment(\.dismiss) var dismiss
    
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
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(todayDateString)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - 頂部統計
    private var statsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今天播放歌曲")
                .font(.custom("SpotifyMix-Bold", size: 24))
                .foregroundColor(.white)
            
            HStack(spacing: 24) {
                // 總時長
                VStack(alignment: .leading, spacing: 4) {
                    Text("總時長")
                        .font(.custom("SpotifyMix-Medium", size: 13))
                        .foregroundColor(.gray)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(totalMinutes)")
                            .font(.custom("SpotifyMix-Bold", size: 28))
                            .foregroundColor(.spotifyGreen)
                        Text("分鐘")
                            .font(.custom("SpotifyMix-Medium", size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                // 歌曲數量
                VStack(alignment: .leading, spacing: 4) {
                    Text("歌曲數量")
                        .font(.custom("SpotifyMix-Medium", size: 13))
                        .foregroundColor(.gray)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(tracks.count)")
                            .font(.custom("SpotifyMix-Bold", size: 28))
                            .foregroundColor(.spotifyGreen)
                        Text("首")
                            .font(.custom("SpotifyMix-Medium", size: 14))
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
            Text("播放記錄")
                .font(.custom("SpotifyMix-Bold", size: 18))
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
            Text("今天還沒有播放記錄")
                .font(.custom("SpotifyMix-Medium", size: 18))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - 日期字串
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 M 月 d 日"
        formatter.locale = Locale(identifier: "zh_TW")
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
                Text(track.name)
                    .font(.custom("SpotifyMix-Medium", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 0) {
                    Text(track.artistName)
                        .font(.custom("SpotifyMix-Medium", size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Text(" · ")
                        .font(.custom("SpotifyMix-Medium", size: 14))
                        .foregroundColor(.gray)
                    
                    Text(track.durationFormatted)
                        .font(.custom("SpotifyMix-Medium", size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // 播放時間（右側）
            Text(track.formattedTime)
                .font(.custom("SpotifyMix-Medium", size: 14))
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

