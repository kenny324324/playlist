import Foundation

struct SpotifyAuthResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
}

enum SpotifyAuthError: Error {
    case missingCodeVerifier
    case invalidHTTPStatus(Int)
    case decodingError(Error)
}

class SpotifyAuthService {
    static let clientID = "ad27c119b1734fd4b8b10795a180aeaa"
    static let redirectURI = "myplaylist://callback"
    static let scope = "user-top-read user-read-recently-played user-read-currently-playing user-read-playback-state user-library-read playlist-read-private playlist-read-collaborative user-follow-read"

    private static var tokenExpirationDate: Date? {
        get { TokenStorage.loadExpirationDate() }
        set {
            guard let date = newValue else {
                TokenStorage.deleteExpirationDate()
                return
            }
            TokenStorage.saveExpirationDate(date)
        }
    }

    static func loginURL() -> URL? {
        let codeVerifier = SpotifyPKCE.generateVerifier()
        TokenStorage.saveCodeVerifier(codeVerifier)
        let codeChallenge = SpotifyPKCE.codeChallenge(for: codeVerifier)

        var components = URLComponents(string: "https://accounts.spotify.com/authorize")
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "show_dialog", value: "true")
        ]

        return components?.url
    }

    // MARK: - Fetch Access Token
    static func fetchAccessToken(code: String, completion: @escaping (String?) -> Void) {
        guard let codeVerifier = TokenStorage.loadCodeVerifier() else {
            print("Missing code verifier for PKCE exchange.")
            completion(nil)
            return
        }

        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "code_verifier", value: codeVerifier)
        ]
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { TokenStorage.deleteCodeVerifier() }

            guard error == nil, let data = data, let httpResponse = response as? HTTPURLResponse else {
                print("Error fetching access token: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            guard httpResponse.statusCode == 200 else {
                print("Failed to fetch access token, status code: \(httpResponse.statusCode)")
                completion(nil)
                return
            }

            do {
                let authResponse = try JSONDecoder().decode(SpotifyAuthResponse.self, from: data)
                persistTokens(response: authResponse)
                completion(authResponse.access_token)
            } catch {
                print("Error decoding access token: \(error)")
                completion(nil)
            }
        }.resume()
    }

    // MARK: - Refresh Access Token
    static func refreshAccessToken(completion: @escaping (String?) -> Void) {
        guard let refreshToken = TokenStorage.loadRefreshToken() else {
            print("No refresh token available")
            completion(nil)
            return
        }

        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "client_id", value: clientID)
        ]
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil, let data = data, let httpResponse = response as? HTTPURLResponse else {
                print("Error refreshing access token: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            guard httpResponse.statusCode == 200 else {
                print("Failed to refresh access token, status code: \(httpResponse.statusCode)")
                TokenStorage.clearAll()
                completion(nil)
                return
            }

            do {
                let authResponse = try JSONDecoder().decode(SpotifyAuthResponse.self, from: data)
                persistTokens(response: authResponse, fallbackRefreshToken: refreshToken)
                completion(authResponse.access_token)
            } catch {
                print("Error decoding refreshed access token: \(error)")
                completion(nil)
            }
        }.resume()
    }

    // MARK: - Ensure Valid Access Token
    static func ensureValidAccessToken(completion: @escaping (String?) -> Void) {
        if let expirationDate = tokenExpirationDate,
           expirationDate > Date(),
           let storedToken = TokenStorage.loadAccessToken() {
            completion(storedToken)
        } else {
            refreshAccessToken(completion: completion)
        }
    }

    static func logout() {
        TokenStorage.clearAll()
    }

    // MARK: - Token helpers
    static func isTokenExpired() -> Bool {
        guard let expirationDate = tokenExpirationDate else { return true }
        return Date() >= expirationDate
    }

    private static func persistTokens(response: SpotifyAuthResponse, fallbackRefreshToken: String? = nil) {
        TokenStorage.saveAccessToken(response.access_token)
        if let refreshToken = response.refresh_token ?? fallbackRefreshToken {
            TokenStorage.saveRefreshToken(refreshToken)
        }
        tokenExpirationDate = Date().addingTimeInterval(TimeInterval(response.expires_in))
    }
}
