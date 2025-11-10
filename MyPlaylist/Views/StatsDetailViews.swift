import SwiftUI

// MARK: - Stats Detail Sheet View
struct StatsDetailSheet: View {
    let title: String
    let subtitle: String
    let tracks: [RankedTrack]
    let accessToken: String
    let isRecentlyPlayed: Bool
    @ObservedObject var audioPlayer: AudioPlayer
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.spotifyText.ignoresSafeArea()
                
                if tracks.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            subtitleView
                                .padding(.top, 20)
                                .padding(.bottom, 8)
                            
                            LazyVStack(spacing: 0) {
                                ForEach(tracks) { track in
                                    NavigationLink(destination: TrackDetailView(trackId: track.trackId, accessToken: accessToken, audioPlayer: audioPlayer)) {
                                        trackRowView(track: track)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 8)
                            
                            Spacer(minLength: 24)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                    .foregroundColor(.spotifyGreen)
                    .font(.custom("SpotifyMix-Bold", size: 16))
                }
            }
        }
    }
    
    // MARK: - Subtitle View
    private var subtitleView: some View {
        Text(subtitle)
            .font(.custom("SpotifyMix-Medium", size: 14))
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }
    
    // MARK: - Track Row View
    private func trackRowView(track: RankedTrack) -> some View {
        HStack(spacing: 12) {
            if !isRecentlyPlayed {
                Text("#\(track.rank)")
                    .font(.custom("SpotifyMix-Bold", size: 18))
                    .foregroundColor(.white)
                    .frame(width: 40, alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            if let imageUrl = track.albumImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(ProgressView().tint(.white))
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(Image(systemName: "music.note").foregroundColor(.gray))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    @unknown default:
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 45, height: 45)
                .cornerRadius(4)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 45, height: 45)
                    .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.trackName)
                    .font(.custom("SpotifyMix-Bold", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artistNames)
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .cornerRadius(8)
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 56))
                .foregroundColor(.gray)
            
            Text(String(localized: "stats.detail.noTracks"))
                .font(.custom("SpotifyMix-Bold", size: 18))
                .foregroundColor(.white)
            
            Text(String(localized: "stats.detail.noTracksDescription"))
                .font(.custom("SpotifyMix-Medium", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Fallback Loading View
struct StatsDetailLoadingView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.spotifyText.ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .spotifyGreen))
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Stats Card Type Helper
enum StatsCardType: String, Identifiable {
    case albumShortTerm
    case albumMediumTerm
    case albumLongTerm
    case albumRecent
    case artistShortTerm
    case artistMediumTerm
    case artistLongTerm
    case artistRecent
    
    var id: String { rawValue }
    
    func getTitle(name: String) -> String {
        switch self {
        case .albumShortTerm:
            return String(localized: "stats.detail.title.album.shortTerm")
        case .albumMediumTerm:
            return String(localized: "stats.detail.title.album.mediumTerm")
        case .albumLongTerm:
            return String(localized: "stats.detail.title.album.longTerm")
        case .albumRecent:
            return String(localized: "stats.detail.title.album.recent")
        case .artistShortTerm:
            return String(localized: "stats.detail.title.artist.shortTerm")
        case .artistMediumTerm:
            return String(localized: "stats.detail.title.artist.mediumTerm")
        case .artistLongTerm:
            return String(localized: "stats.detail.title.artist.longTerm")
        case .artistRecent:
            return String(localized: "stats.detail.title.artist.recent")
        }
    }
    
    func getSubtitle(name: String, count: Int) -> String {
        let format: String
        switch self {
        case .albumShortTerm:
            format = NSLocalizedString("stats.detail.subtitle.album.shortTerm %lld %@", comment: "Album short term stats detail subtitle")
        case .albumMediumTerm:
            format = NSLocalizedString("stats.detail.subtitle.album.mediumTerm %lld %@", comment: "Album medium term stats detail subtitle")
        case .albumLongTerm:
            format = NSLocalizedString("stats.detail.subtitle.album.longTerm %lld %@", comment: "Album long term stats detail subtitle")
        case .albumRecent:
            format = NSLocalizedString("stats.detail.subtitle.album.recent %lld %@", comment: "Album recent plays stats detail subtitle")
        case .artistShortTerm:
            format = NSLocalizedString("stats.detail.subtitle.artist.shortTerm %lld %@", comment: "Artist short term stats detail subtitle")
        case .artistMediumTerm:
            format = NSLocalizedString("stats.detail.subtitle.artist.mediumTerm %lld %@", comment: "Artist medium term stats detail subtitle")
        case .artistLongTerm:
            format = NSLocalizedString("stats.detail.subtitle.artist.longTerm %lld %@", comment: "Artist long term stats detail subtitle")
        case .artistRecent:
            format = NSLocalizedString("stats.detail.subtitle.artist.recent %lld %@", comment: "Artist recent plays stats detail subtitle")
        }
        return String(format: format, locale: Locale.current, count, name)
    }
    
    var isRecentlyPlayed: Bool {
        switch self {
        case .albumRecent, .artistRecent:
            return true
        default:
            return false
        }
    }
}

