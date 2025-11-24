import Foundation
import SwiftUI

extension Notification.Name {
    static let spotifyCallback = Notification.Name("spotifyCallback")
    static let spotifyUnauthorized = Notification.Name("spotifyUnauthorized")
    static let spotifyTokenExpired = Notification.Name("spotifyTokenExpired")
}

// MARK: - Font Extension
extension Font {
    enum FontWeight {
        case medium
        case bold
        case extraBold
        
        var fontName: String {
            switch self {
            case .medium:
                return "SpotifyMix-Medium"
            case .bold:
                return "SpotifyMix-Bold"
            case .extraBold:
                return "SpotifyMix-Extrabold"
            }
        }
        
        // 支援 scale 運算
        static func * (weight: FontWeight, scale: CGFloat) -> FontWeight {
            return weight
        }
    }
    
    static func appFont(size: CGFloat, weight: FontWeight) -> Font {
        return .custom(weight.fontName, size: size)
    }
}

// MARK: - Shimmer Effect Extension
extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
                    .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = UIScreen.main.bounds.width * 2
                }
            }
    }
}
