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
                        .font(.custom("SpotifyMix-Bold", size: 34))
                        .foregroundColor(.white)
                    
                    // 版本資訊
                    Text("settings.version")
                        .font(.custom("SpotifyMix-Medium", size: 18))
                        .foregroundColor(.gray)
                    
                    // 開發者資訊
                    Text("settings.madeBy")
                        .font(.custom("SpotifyMix-Medium", size: 16))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 功能說明
                VStack(alignment: .leading, spacing: 15) {
                    Text("settings.features")
                        .font(.custom("SpotifyMix-Bold", size: 22))
                        .foregroundColor(.white)
                    
                    FeatureRow(icon: "house.fill", titleKey: "settings.feature.home", descriptionKey: "settings.feature.home.description")
                    FeatureRow(icon: "chart.bar.fill", titleKey: "settings.feature.topCharts", descriptionKey: "settings.feature.topCharts.description")
                    FeatureRow(icon: "play.fill", titleKey: "settings.feature.preview", descriptionKey: "settings.feature.preview.description")
                    FeatureRow(icon: "person.circle.fill", titleKey: "settings.feature.profile", descriptionKey: "settings.feature.profile.description")
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                
                Spacer()
            }
            .padding()
            .navigationTitle("settings.title")
            .background(Color.spotifyText.ignoresSafeArea())
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let titleKey: String
    let descriptionKey: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.spotifyGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(titleKey))
                    .font(.custom("SpotifyMix-Medium", size: 18))
                    .foregroundColor(.white)
                
                Text(LocalizedStringKey(descriptionKey))
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
        .background(Color.spotifyText)
}
