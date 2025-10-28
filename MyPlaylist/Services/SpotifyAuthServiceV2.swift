import Foundation
import AuthenticationServices

/// 使用 ASWebAuthenticationSession 的新版認證服務
/// 提供更原生的 App 內登入體驗，同時符合 Spotify 安全規範
class SpotifyAuthServiceV2: NSObject, ObservableObject {
    static let shared = SpotifyAuthServiceV2()
    
    static let clientID = "ad27c119b1734fd4b8b10795a180aeaa"
    static let redirectURI = "myplaylist://callback"
    static let scope = "user-top-read user-read-recently-played user-read-currently-playing user-read-playback-state user-library-read playlist-read-private playlist-read-collaborative user-follow-read"
    
    private var authSession: ASWebAuthenticationSession?
    
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
    
    // MARK: - 使用 ASWebAuthenticationSession 登入
    func login(presentationContext: ASWebAuthenticationPresentationContextProviding,
               completion: @escaping (Result<String, Error>) -> Void) {
        // 生成 PKCE 參數
        let codeVerifier = SpotifyPKCE.generateVerifier()
        TokenStorage.saveCodeVerifier(codeVerifier)
        let codeChallenge = SpotifyPKCE.codeChallenge(for: codeVerifier)
        
        // 建立授權 URL
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: Self.clientID),
            URLQueryItem(name: "scope", value: Self.scope),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "show_dialog", value: "true")
        ]
        
        guard let authURL = components?.url else {
            completion(.failure(NSError(domain: "SpotifyAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // 建立 ASWebAuthenticationSession
        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "myplaylist"
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            if let error = error {
                // 如果用戶取消，不視為錯誤
                if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    print("用戶取消登入")
                }
                completion(.failure(error))
                return
            }
            
            guard let callbackURL = callbackURL,
                  let code = self.extractCode(from: callbackURL) else {
                completion(.failure(NSError(domain: "SpotifyAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "無法取得授權碼"])))
                return
            }
            
            // 使用授權碼換取 access token
            self.fetchAccessToken(code: code) { token in
                if let token = token {
                    completion(.success(token))
                } else {
                    completion(.failure(NSError(domain: "SpotifyAuth", code: -3, userInfo: [NSLocalizedDescriptionKey: "無法取得 access token"])))
                }
            }
        }
        
        // 設定呈現上下文
        authSession?.presentationContextProvider = presentationContext
        
        // 優先使用臨時瀏覽器會話（不共享 cookie），更安全
        authSession?.prefersEphemeralWebBrowserSession = false
        
        // 開始認證流程
        authSession?.start()
    }
    
    // MARK: - Fetch Access Token
    private func fetchAccessToken(code: String, completion: @escaping (String?) -> Void) {
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
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "client_id", value: Self.clientID),
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
                Self.persistTokens(response: authResponse)
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
    
    // 提取授權碼
    private func extractCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding Helper
/// 用於提供 ASWebAuthenticationSession 的呈現上下文
class WebAuthenticationPresentationContextProvider: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // 使用現代的方式取得 key window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.windows.first { $0.isKeyWindow } ?? windowScene.windows.first ?? ASPresentationAnchor()
        }
        return ASPresentationAnchor()
    }
}

