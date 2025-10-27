import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 30) {
                    // App 圖示
                    Image(systemName: "music.note.house")
                        .font(.system(size: 80))
                        .foregroundColor(.spotifyGreen)
                    
                    // App 名稱
                    Text("MyPlaylist")
                        .font(.custom("SpotifyMix-Bold", size: 32))
                        .foregroundColor(.white)
                    
                    // 版本資訊
                    Text("Version 1.0.0")
                        .font(.custom("SpotifyMix-Medium", size: 16))
                        .foregroundColor(.gray)
                    
                    // 開發者資訊
                    Text("Made by Kenny")
                        .font(.custom("SpotifyMix-Medium", size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 功能說明
                VStack(alignment: .leading, spacing: 15) {
                    Text("功能特色")
                        .font(.custom("SpotifyMix-Bold", size: 20))
                        .foregroundColor(.white)
                    
                    FeatureRow(icon: "house.fill", title: "首頁", description: "查看正在播放和最近播放")
                    FeatureRow(icon: "chart.bar.fill", title: "排行榜", description: "熱門歌曲、藝術家和音樂類型")
                    FeatureRow(icon: "play.fill", title: "音樂預覽", description: "試聽 30 秒歌曲片段")
                    FeatureRow(icon: "person.circle.fill", title: "個人檔案", description: "查看個人資訊和播放清單")
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                
                Spacer()
            }
            .padding()
            .navigationTitle("設定")
            .background(Color.spotifyText.ignoresSafeArea())
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.spotifyGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("SpotifyMix-Medium", size: 16))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.custom("SpotifyMix-Medium", size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}
