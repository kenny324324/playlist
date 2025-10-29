import SwiftUI

struct LoginView: View {
    let login: () -> Void

    var body: some View {
        VStack {
            Spacer()
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
        }
        .background(Color.spotifyText.ignoresSafeArea())
    }
}

#Preview {
    LoginView(login: {})
        .preferredColorScheme(.dark)
}
