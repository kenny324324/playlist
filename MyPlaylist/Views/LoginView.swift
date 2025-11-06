import SwiftUI

struct LoginView: View {
    let login: () -> Void
    let enterDemoMode: (() -> Void)?
    
    init(login: @escaping () -> Void, enterDemoMode: (() -> Void)? = nil) {
        self.login = login
        self.enterDemoMode = enterDemoMode
    }

    var body: some View {
        VStack {
            Spacer()
            
            // Spotify 登入按鈕
            Button(action: login) {
                Text("login.button")
                    .font(.custom("SpotifyMix-Medium", size: 22))
                    .foregroundColor(Color.spotifyText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.spotifyGreen)
                    .cornerRadius(50)
            }
            .padding(.horizontal, 23)
            
            #if APPSTORE_REVIEW
            // Demo 模式按鈕（僅在審核版本顯示）
            if let enterDemo = enterDemoMode {
                Button(action: enterDemo) {
                    HStack {
                        Image(systemName: "theatermasks")
                        Text("Demo Mode (For Review)")
                    }
                    .font(.custom("SpotifyMix-Medium", size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(50)
                }
                .padding(.horizontal, 23)
                .padding(.top, 12)
            }
            #endif
            
            Spacer()
                .frame(height: 50)
        }
        .background(Color.spotifyText.ignoresSafeArea())
    }
}

#Preview {
    LoginView(login: {})
        .preferredColorScheme(.dark)
}
