import SwiftUI

enum UITestScenario {
    case statsHarness
    
    static func current() -> UITestScenario? {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-uiTestStatsHarness") {
            return .statsHarness
        }
        return nil
    }
}

struct UITestHarnessRoot: View {
    let scenario: UITestScenario
    
    var body: some View {
        switch scenario {
        case .statsHarness:
            StatsUITestHarnessView()
        }
    }
}

private struct StatsUITestHarnessView: View {
    private let mockTrend = AlbumCountTrend(
        albumId: "ui_test_album",
        albumName: "UI Test Album",
        dataPoints: StatsUITestHarnessView.generateDataPoints()
    )
    
    private static func generateDataPoints() -> [CountDataPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return CountDataPoint(date: date, count: max(1, 7 - offset))
        }.reversed()
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Stats Harness Ready")
                .font(.appFont(size: 22, weight: .bold))
                .foregroundColor(.white)
                .accessibilityIdentifier("statsHarness.title")
            
            CountBarChart(
                dataPoints: mockTrend.dataPoints,
                title: "Harness Past 7 Days",
                emptyMessage: nil
            )
            .accessibilityIdentifier("statsHarness.chart")
            
            HStack(spacing: 12) {
                SmallStatCard(
                    number: "7",
                    text: "7 首歌曲在過去 4 週保持 Top 50",
                    highlightWord: nil,
                    onTap: nil
                )
                SmallStatCard(
                    number: "15",
                    text: "總共 15 次出現在最近 50 次播放",
                    highlightWord: nil,
                    onTap: nil
                )
            }
        }
        .padding()
        .background(Color.spotifyText.ignoresSafeArea())
    }
}

