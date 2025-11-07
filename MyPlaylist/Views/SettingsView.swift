import SwiftUI

struct SettingsView: View {
    let userProfile: SpotifyUser?
    let accessToken: String
    let isLoggedIn: Bool
    let logout: () -> Void
    
    @State private var showUserProfile = false
    @State private var showClearImageCacheAlert = false
    @State private var showClearDataCacheAlert = false
    @State private var showReauthorizeAlert = false
    @State private var cacheSize: String = "計算中..."
    
    // 設定選項
    @AppStorage("updateFrequency") private var updateFrequency: Int = 5
    @AppStorage("defaultTimeRange") private var defaultTimeRange: String = "short_term"
    
    // 個人化設定
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 一般設定
                    generalSettingsSection
                    
                    // 個人化
                    personalizationSection
                    
                    // 儲存與快取
                    storageSection
                    
                    // 授權狀態
                    authorizationSection
                    
                    // 關於
                    aboutSection
                }
                .padding()
                .padding(.top, 10)
            }
            .background(Color.spotifyText.ignoresSafeArea())
            .navigationTitle("settings.title")
                      .navigationBarTitleDisplayMode(.inline)
                      .toolbar {
                          ToolbarItem(placement: .navigationBarLeading) {
                              if isLoggedIn {
                                  // 用戶頭像按鈕
                                  if let user = userProfile,
                                     let imageUrl = user.images?.first?.url,
                                     let url = URL(string: imageUrl) {
                                      Button(action: {
                                          showUserProfile = true
                                      }) {
                                          AsyncImage(url: url) { image in
                                              image.resizable()
                                                  .clipShape(Circle())
                                          } placeholder: {
                                              ProgressView()
                                          }
                                          .frame(width: AdaptiveSize.toolbarAvatarSize, height: AdaptiveSize.toolbarAvatarSize)
                                      }
                                      .frame(width: AdaptiveSize.toolbarAvatarSize, height: AdaptiveSize.toolbarAvatarSize)
                                      .contentShape(Rectangle())
                                      .sheet(isPresented: $showUserProfile) {
                                          UserProfileView(userProfile: user, accessToken: accessToken, logout: logout)
                                              .presentationDetents(PresentationDetent.adaptiveDetents)
                                      }
                                  }
                              }
                          }
                      }
                      .onAppear {
                          calculateCacheSize()
                      }
                  }
              }
    
    // MARK: - 一般設定
    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("settings.section.general")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                // 語言設定 - 打開系統設定
                Button(action: {
                    openAppSettings()
                }) {
                    HStack(spacing: 15) {
                        Image(systemName: "globe")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.themeColor)
                            .frame(width: 30)
                        
                        Text(LocalizedStringKey("settings.language"))
                            .font(.custom("SpotifyMix-Medium", size: 16))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // 語言膠囊
                        Text(currentSystemLanguage())
                            .font(.custom("SpotifyMix-Medium", size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Capsule())
                    }
                    .padding()
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.leading, 50)
                
                // 資料更新頻率
                Menu {
                    ForEach([5, 10, 30, 60], id: \.self) { freq in
                        Button(action: {
                            updateFrequency = freq
                        }) {
                            HStack {
                                Text(String(format: String(localized: "settings.seconds.format"), freq))
                                if updateFrequency == freq {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 15) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.themeColor)
                            .frame(width: 30)
                        
                        Text(LocalizedStringKey("settings.updateFrequency"))
                            .font(.custom("SpotifyMix-Medium", size: 16))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(String(format: String(localized: "settings.seconds.format"), updateFrequency))
                            .font(.custom("SpotifyMix-Medium", size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Capsule())
                    }
                    .padding()
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.leading, 50)
                
                // 預設時間範圍
                Menu {
                    ForEach([("short_term", "timeRange.1month"), ("medium_term", "timeRange.6months"), ("long_term", "timeRange.1year")], id: \.0) { code, nameKey in
                        Button(action: {
                            defaultTimeRange = code
                        }) {
                            HStack {
                                Text(LocalizedStringKey(nameKey))
                                if defaultTimeRange == code {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 15) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.themeColor)
                            .frame(width: 30)
                        
                        Text(LocalizedStringKey("settings.defaultTimeRange"))
                            .font(.custom("SpotifyMix-Medium", size: 16))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(LocalizedStringKey(timeRangeDisplayName(defaultTimeRange)))
                            .font(.custom("SpotifyMix-Medium", size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Capsule())
                    }
                    .padding()
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
    }
    
    // MARK: - 個人化
    private var personalizationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("settings.section.personalization")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                // 主題色彩選擇
                VStack(spacing: 0) {
                    HStack(spacing: 15) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.themeColor)
                            .frame(width: 30)
                        
                        Text(LocalizedStringKey("settings.themeColor"))
                            .font(.custom("SpotifyMix-Medium", size: 16))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // 色系選擇下拉選單（膠囊狀）
                        Menu {
                            ForEach(ColorTone.allCases) { tone in
                                Button(action: {
                                    HapticManager.shared.light()
                                    withAnimation(.spring(response: 0.3)) {
                                        themeManager.setTone(tone)
                                    }
                                }) {
                                    HStack {
                                        Text(tone.displayName)
                                        if themeManager.currentTone == tone {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text(themeManager.currentTone.displayName)
                                .font(.custom("SpotifyMix-Medium", size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    
                    // 顏色選擇網格
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 15) {
                        ForEach(ThemeColor.allCases) { theme in
                            Button(action: {
                                HapticManager.shared.light()
                                withAnimation(.spring(response: 0.3)) {
                                    themeManager.setTheme(theme)
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(theme.color(for: themeManager.currentTone))
                                        .frame(width: 50, height: 50)
                                    
                                    if themeManager.currentTheme == theme {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.leading, 50)
                
                // 觸覺回饋開關
                Toggle(isOn: $hapticFeedbackEnabled) {
                    HStack(spacing: 15) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.themeColor)
                            .frame(width: 30)
                        
                        Text(LocalizedStringKey("settings.hapticFeedback"))
                            .font(.custom("SpotifyMix-Medium", size: 16))
                            .foregroundColor(.white)
                    }
                }
                .tint(themeManager.themeColor)
                .padding()
                .onChange(of: hapticFeedbackEnabled) { newValue in
                    HapticManager.shared.setEnabled(newValue)
                    if newValue {
                        HapticManager.shared.light()
                    }
                }
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
    }
    
    // MARK: - 儲存與快取
    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("settings.section.storage")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                // 快取大小顯示
                SettingRow(
                    icon: "internaldrive",
                    title: "settings.cacheSize",
                    value: cacheSize,
                    showChevron: false,
                    themeColor: themeManager.themeColor
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.leading, 50)
                
                // 清除圖片快取
                Button(action: {
                    showClearImageCacheAlert = true
                }) {
                    SettingRow(
                        icon: "photo",
                        title: "settings.clearImageCache",
                        value: "",
                        showChevron: false,
                        isDestructive: false,
                        themeColor: themeManager.themeColor
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.leading, 50)
                
                // 清除統計快取
                Button(action: {
                    showClearDataCacheAlert = true
                }) {
                    SettingRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "settings.clearDataCache",
                        value: "",
                        showChevron: false,
                        isDestructive: false,
                        themeColor: themeManager.themeColor
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
        .alert("settings.clearImageCache", isPresented: $showClearImageCacheAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("settings.clear", role: .destructive) {
                clearImageCache()
            }
        } message: {
            Text("settings.clearImageCache.message")
        }
        .alert("settings.clearDataCache", isPresented: $showClearDataCacheAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("settings.clear", role: .destructive) {
                clearDataCache()
            }
        } message: {
            Text("settings.clearDataCache.message")
        }
    }
    
    // MARK: - 授權狀態
    private var authorizationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("settings.section.authorization")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                // 授權狀態
                SettingRow(
                    icon: "checkmark.shield.fill",
                    title: "settings.authStatus",
                    value: isLoggedIn ? "settings.authorized" : "settings.notAuthorized",
                    showChevron: false,
                    valueColor: isLoggedIn ? themeManager.themeColor : .red,
                    themeColor: themeManager.themeColor
                )
                
                if isLoggedIn {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.leading, 50)
                    
                    // 重新授權
                    Button(action: {
                        showReauthorizeAlert = true
                    }) {
                        SettingRow(
                            icon: "arrow.clockwise.circle",
                            title: "settings.reauthorize",
                            value: "",
                            showChevron: false,
                            themeColor: themeManager.themeColor
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
        .alert("settings.reauthorize", isPresented: $showReauthorizeAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("settings.reauthorize.confirm", role: .destructive) {
                reauthorize()
            }
        } message: {
            Text("settings.reauthorize.message")
        }
    }
    
    // MARK: - 關於
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("settings.section.about")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                // App 圖示和名稱
                HStack(spacing: 15) {
                    // 使用真實的 App Icon
                    if let appIcon = getAppIcon() {
                        Image(uiImage: appIcon)
                            .resizable()
                            .frame(width: 60, height: 60)
                            .cornerRadius(13)
                            .overlay(
                                RoundedRectangle(cornerRadius: 13)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    } else {
                        // 備用方案：使用 Assets 中的圖片
                        Image("AppIconImage")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .cornerRadius(13)
                            .overlay(
                                RoundedRectangle(cornerRadius: 13)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MyPlaylist")
                            .font(.custom("SpotifyMix-Bold", size: 20))
                            .foregroundColor(.white)
                        
                        Text("settings.version")
                            .font(.custom("SpotifyMix-Medium", size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.leading, 50)
                
                // 開發者
                SettingRow(
                    icon: "person.fill",
                    title: "settings.developer",
                    value: "Kenny",
                    showChevron: false,
                    themeColor: themeManager.themeColor
                )
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
    }
    
    // MARK: - Helper Functions
    
    private func getAppIcon() -> UIImage? {
        // 嘗試從 app bundle 中讀取實際的 app icon
        if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        
        // 備用方案：嘗試從 Assets 中讀取
        return UIImage(named: "AppIconImage")
    }
    
    private func currentSystemLanguage() -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "zh-Hant"
        switch languageCode {
        case "zh": return "繁體中文"
        case "en": return "English"
        case "ja": return "日本語"
        case "ko": return "한국어"
        default: return "繁體中文"
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func timeRangeDisplayName(_ range: String) -> String {
        switch range {
        case "short_term": return String(localized: "timeRange.1month")
        case "medium_term": return String(localized: "timeRange.6months")
        case "long_term": return String(localized: "timeRange.1year")
        default: return String(localized: "timeRange.1month")
        }
    }
    
    private func calculateCacheSize() {
        DispatchQueue.global(qos: .background).async {
            var totalBytes: Int64 = 0
            
            // 1. 計算 URLCache 大小（圖片快取）
            let urlCache = URLCache.shared
            totalBytes += Int64(urlCache.currentDiskUsage)
            totalBytes += Int64(urlCache.currentMemoryUsage)
            
            // 2. 計算檔案系統快取目錄大小
            if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(
                        at: cacheURL,
                        includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                        options: [.skipsHiddenFiles]
                    )
                    
                    for fileURL in contents {
                        // 遞迴計算子目錄
                        totalBytes += Int64(calculateDirectorySize(url: fileURL))
                    }
                } catch {
                    print("❌ 計算快取大小錯誤: \(error.localizedDescription)")
                }
            }
            
            // 3. 估算 UserDefaults 資料大小（Dashboard 快取）
            if let dailyLog = UserDefaults.standard.dailyListeningLog {
                // 估算每個 track ID 約 100 bytes
                let estimatedDailyLogSize = dailyLog.trackDurations.count * 100
                totalBytes += Int64(estimatedDailyLogSize)
            }
            
            if let weeklyCache = UserDefaults.standard.weeklyTopCache {
                // 估算每個項目約 200 bytes
                let estimatedWeeklyCacheSize = (weeklyCache.tracks.count + weeklyCache.artists.count) * 200
                totalBytes += Int64(estimatedWeeklyCacheSize)
            }
            
            // 格式化顯示
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            formatter.allowedUnits = [.useKB, .useMB, .useGB]
            formatter.includesUnit = true
            
            DispatchQueue.main.async {
                self.cacheSize = formatter.string(fromByteCount: totalBytes)
                print("📦 總快取大小: \(formatter.string(fromByteCount: totalBytes))")
                print("   - URLCache (磁碟): \(formatter.string(fromByteCount: Int64(urlCache.currentDiskUsage)))")
                print("   - URLCache (記憶體): \(formatter.string(fromByteCount: Int64(urlCache.currentMemoryUsage)))")
            }
        }
    }
    
    private func calculateDirectorySize(url: URL) -> Int {
        var totalSize = 0
        
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            
            if resourceValues.isDirectory == true {
                // 如果是目錄，遞迴計算
                let contents = try FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
                for fileURL in contents {
                    totalSize += calculateDirectorySize(url: fileURL)
                }
            } else {
                // 如果是檔案，加入大小
                totalSize += resourceValues.fileSize ?? 0
            }
        } catch {
            print("❌ 計算目錄大小錯誤: \(error.localizedDescription)")
        }
        
        return totalSize
    }
    
    private func clearImageCache() {
        URLCache.shared.removeAllCachedResponses()
        print("✅ 已清除圖片快取")
        // 重新計算快取大小
        calculateCacheSize()
    }
    
    private func clearDataCache() {
        DashboardMetricsService.shared.clearCache()
        print("✅ 已清除統計資料快取")
        // 重新計算快取大小
        calculateCacheSize()
    }
    
    private func reauthorize() {
        logout()
        // 用戶需要重新登入
    }
}

// MARK: - Setting Row Component
struct SettingRow: View {
    let icon: String
    let title: String
    let value: String
    let showChevron: Bool
    var isDestructive: Bool = false
    var valueColor: Color = .gray
    var themeColor: Color = .green
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isDestructive ? .red : themeColor)
                .frame(width: 30)
            
            Text(LocalizedStringKey(title))
                .font(.custom("SpotifyMix-Medium", size: 16))
                .foregroundColor(isDestructive ? .red : .white)
            
            Spacer()
            
            if !value.isEmpty {
                Text(LocalizedStringKey(value))
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(valueColor)
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

#Preview {
    SettingsView(
        userProfile: SpotifyUser(
            display_name: "Kenny",
            images: nil,
            email: "kenny@example.com",
            id: "user123",
            followers: nil
        ),
        accessToken: "preview_token",
        isLoggedIn: true,
        logout: {}
    )
    .preferredColorScheme(.dark)
}
