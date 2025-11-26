import Foundation
import Testing
@testable import MyPlaylist

struct CountTrendTests {
    
    @Test
    func albumTrendBuildsSevenDaysWindow() throws {
        let service = CloudKitRankingService.shared
        let histories = [
            makeHistory(daysAgo: 0, trackId: "track_1", albumId: "album_1"),
            makeHistory(daysAgo: 0, trackId: "track_2", albumId: "album_1"),
            makeHistory(daysAgo: 2, trackId: "track_3", albumId: "album_1"),
            makeHistory(daysAgo: 4, trackId: "track_4", albumId: "album_1"),
            makeHistory(daysAgo: 4, trackId: "track_4", albumId: "album_1") // duplicate same day
        ]
        
        let trend = service.processAlbumCountTrend(histories: histories, albumId: "album_1")
        #expect(trend != nil)
        #expect(trend?.dataPoints.count == 7)
        #expect(trend?.dataPoints.last?.count == 2)
        
        // ensure duplicates per day removed
        let dayWithDuplicates = trend?.dataPoints.dropFirst(2).first { $0.count == 1 }
        #expect(dayWithDuplicates != nil)
    }
    
    @Test
    func albumFilterFallsBackToTrackIds() {
        let service = CloudKitRankingService.shared
        let histories = [
            makeHistory(daysAgo: 1, trackId: "track_match"),
            makeHistory(daysAgo: 1, trackId: "track_ignore")
        ]
        
        let filtered = service.filterAlbumHistories(histories, albumId: "missing_album", fallbackTrackIds: ["track_match"])
        #expect(filtered.count == 1)
        #expect(filtered.first?.trackId == "track_match")
    }
    
    @Test
    func artistFilterFallsBackToTrackIds() {
        let service = CloudKitRankingService.shared
        let histories = [
            makeHistory(daysAgo: 1, trackId: "track_match", artistIds: nil),
            makeHistory(daysAgo: 1, trackId: "track_ignore", artistIds: nil)
        ]
        
        let filtered = service.filterArtistHistories(histories, artistId: "artist_1", fallbackTrackIds: ["track_match"])
        #expect(filtered.count == 1)
        #expect(filtered.first?.trackId == "track_match")
    }
    
    private func makeHistory(daysAgo: Int, trackId: String, albumId: String? = nil, artistIds: String? = nil) -> RankingHistory {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return RankingHistory(
            userId: "user_1",
            trackId: trackId,
            rank: 1,
            timeRange: "short_term",
            recordedDate: date,
            albumId: albumId,
            artistIds: artistIds
        )
    }
}

