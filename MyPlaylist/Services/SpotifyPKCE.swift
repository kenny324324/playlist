import Foundation
import CryptoKit

enum SpotifyPKCE {
    static func generateVerifier() -> String {
        let length = 64
        let charset = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        var verifier = ""
        verifier.reserveCapacity(length)
        for _ in 0..<length {
            if let char = charset.randomElement() {
                verifier.append(char)
            }
        }
        return verifier
    }

    static func codeChallenge(for verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        return base64URLEncoded(Data(hash))
    }

    private static func base64URLEncoded(_ data: Data) -> String {
        let base64 = data.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
