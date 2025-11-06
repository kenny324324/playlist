import SwiftUI
import MusicKit

struct AppleMusicAuthView: View {
    @StateObject private var appleMusicService = AppleMusicService()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // 圖示
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.spotifyGreen)
            
            // 標題
            Text("applemusic.auth.title")
                .font(.custom("SpotifyMix-Bold", size: 28))
                .foregroundColor(.white)
            
            // 說明
            VStack(spacing: 12) {
                Text("applemusic.auth.description")
                    .font(.custom("SpotifyMix-Medium", size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Text("applemusic.auth.reason")
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            
            // 狀態顯示
            HStack {
                Image(systemName: appleMusicService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(appleMusicService.isAuthorized ? .green : .red)
                
                Text(appleMusicService.isAuthorized ? "applemusic.auth.authorized" : "applemusic.auth.notAuthorized")
                    .font(.custom("SpotifyMix-Medium", size: 16))
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            
            // 按鈕
            if !appleMusicService.isAuthorized {
                Button(action: {
                    Task {
                        let authorized = await appleMusicService.requestAuthorization()
                        if authorized {
                            // 授權成功，可以關閉視圖
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                dismiss()
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "music.note")
                        Text("applemusic.auth.button")
                    }
                    .font(.custom("SpotifyMix-Bold", size: 18))
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.spotifyGreen)
                    .cornerRadius(25)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    AppleMusicAuthView()
}

