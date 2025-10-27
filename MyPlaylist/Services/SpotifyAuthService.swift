import Foundation

struct SpotifyAuthResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
}

// ArtistsResponse moved to SpotifyAPIService.swift to avoid duplication

class SpotifyAuthService {
    static let clientID = "ad27c119b1734fd4b8b10795a180aeaa"
    static let clientSecret = "84f5cf35b2a54d5486503301440384cc"
    static let redirectURI = "myplaylist://callback"
    static let scope = "user-top-read user-read-recently-played user-read-currently-playing user-read-playback-state"
    
    static var tokenExpirationDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: "token_expiration_date") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "token_expiration_date")
        }
    }

    static func loginURLString() -> String {
        return """
        https://accounts.spotify.com/authorize?response_type=code&client_id=\(clientID)&scope=\(scope)&redirect_uri=\(redirectURI)&show_dialog=true
        """
    }

    // MARK: - Fetch Access Token
    static func fetchAccessToken(code: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let credentials = "\(clientID):\(clientSecret)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        request.addValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI
        ]
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("Error fetching access token: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            do {
                let authResponse = try JSONDecoder().decode(SpotifyAuthResponse.self, from: data)
                
                // 儲存 access token 與 refresh token
                UserDefaults.standard.set(authResponse.access_token, forKey: "access_token")
                if let refreshToken = authResponse.refresh_token {
                    UserDefaults.standard.set(refreshToken, forKey: "refresh_token")
                }
                tokenExpirationDate = Date().addingTimeInterval(TimeInterval(authResponse.expires_in))
                completion(authResponse.access_token)
            } catch {
                print("Error decoding access token: \(error)")
                completion(nil)
            }
        }.resume()
    }

    // MARK: - Refresh Access Token
    static func refreshAccessToken(completion: @escaping (String?) -> Void) {
        guard let refreshToken = UserDefaults.standard.string(forKey: "refresh_token") else {
            print("No refresh token available")
            completion(nil)
            return
        }

        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let credentials = "\(clientID):\(clientSecret)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        request.addValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("Error refreshing access token: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            do {
                let authResponse = try JSONDecoder().decode(SpotifyAuthResponse.self, from: data)

                // 儲存新的 access token
                UserDefaults.standard.set(authResponse.access_token, forKey: "access_token")
                tokenExpirationDate = Date().addingTimeInterval(TimeInterval(authResponse.expires_in))
                completion(authResponse.access_token)
            } catch {
                print("Error decoding refreshed access token: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    // MARK: - Ensure Valid Access Token
    static func ensureValidAccessToken(completion: @escaping (String?) -> Void) {
        if let expirationDate = tokenExpirationDate, expirationDate > Date(),
           let accessToken = UserDefaults.standard.string(forKey: "access_token") {
            completion(accessToken)
        } else {
            refreshAccessToken(completion: completion)
        }
    }
    
    // MARK: - Fetch Top Artists method moved to SpotifyAPIService
    // MARK: - 檢查 Token 是否過期
        static func isTokenExpired() -> Bool {
            // 確認 tokenExpirationDate 是否存在且尚未過期
            guard let expirationDate = tokenExpirationDate else {
                return true // 若無過期日期，視為已過期
            }
            return Date() >= expirationDate // 當前時間 >= 過期時間，則視為過期
        }
}
