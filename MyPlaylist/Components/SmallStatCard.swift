import SwiftUI

// MARK: - Small Stat Card (Reusable Component)
struct SmallStatCard: View {
    let number: String
    let text: String
    var highlightWord: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(number)
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.spotifyGreen)
            
            if let highlightWord = highlightWord {
                highlightedText(fullText: text, highlightWord: highlightWord)
            } else {
                Text(text)
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(12)
    }
    
    private func highlightedText(fullText: String, highlightWord: String) -> some View {
        let parts = fullText.components(separatedBy: highlightWord)
        
        return Group {
            if parts.count == 2 {
                (Text(parts[0])
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(.white) +
                Text(highlightWord)
                    .font(.custom("SpotifyMix-Bold", size: 14))
                    .foregroundColor(.spotifyGreen) +
                Text(parts[1])
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(.white))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(fullText)
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

