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
    
    // 通知設定
    @StateObject private var notificationService = NotificationService.shared
    @AppStorage("dailyNotificationEnabled") private var dailyNotificationEnabled: Bool = true  // 預設開啟
    @AppStorage("dailyNotificationHour") private var dailyNotificationHour: Int = 20
    @AppStorage("dailyNotificationMinute") private var dailyNotificationMinute: Int = 0
    @State private var showNotificationTimeAlert = false
#if DEBUG
    // CloudKit 補寫（僅開發模式可見）
    @State private var showBackfillConfirmAlert = false
    @State private var showBackfillResultAlert = false
    @State private var backfillResultMessage: String = ""
    @State private var isBackfillingRankingHistory = false
#endif
#if DEBUG
    @State private var diagnosticsSnapshot: CloudKitRankingService.CloudKitDiagnosticsSnapshot?
    @State private var isDiagnosticsLoading = false
    @State private var lastSnapshotDate: Date? = DailySnapshotScheduler.shared.lastSnapshotDate()
#endif
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 一般設定
                generalSettingsSection
                
                // 個人化
                personalizationSection
                
                // 通知設定
                notificationSection
                
                // 儲存與快取
                storageSection
                
                // 授權狀態
                authorizationSection
                
#if DEBUG
                // 診斷資訊
                diagnosticsSection
#endif
                
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
                      notificationService.checkAuthorizationStatus()
                      applyNotificationSettings()
#if DEBUG
                      refreshDiagnosticsSnapshot()
                      lastSnapshotDate = DailySnapshotScheduler.shared.lastSnapshotDate()
#endif
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
    
    // MARK: - 通知設定
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("settings.section.notifications")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                // 通知授權狀態
                Button(action: {
                    if notificationService.authorizationStatus == .notDetermined {
                        // 請求權限
                        notificationService.requestAuthorization { granted in
                            if granted {
                                // 權限授予後，根據開關狀態決定是否排程
                                applyNotificationSettings()
                            }
                        }
                    } else if notificationService.authorizationStatus == .denied {
                        // 開啟系統設定
                        notificationService.openNotificationSettings()
                    }
                }) {
                    HStack(spacing: 15) {
                        Image(systemName: notificationService.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.themeColor)
                            .frame(width: 30)
                        
                        Text(LocalizedStringKey("settings.notificationPermission"))
                            .font(.custom("SpotifyMix-Medium", size: 16))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(notificationService.authorizationStatus.displayName)
                            .font(.custom("SpotifyMix-Medium", size: 14))
                            .foregroundColor(notificationService.isAuthorized ? themeManager.themeColor : .red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Capsule())
                        
                        if notificationService.authorizationStatus != .authorized {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(notificationService.authorizationStatus == .authorized)
                
                if notificationService.isAuthorized {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.leading, 50)
                    
                    // 每日提醒開關
                    Toggle(isOn: $dailyNotificationEnabled) {
                        HStack(spacing: 15) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.themeColor)
                                .frame(width: 30)
                            
                            Text(LocalizedStringKey("settings.dailyReminder"))
                                .font(.custom("SpotifyMix-Medium", size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    .tint(themeManager.themeColor)
                    .padding()
                    .onChange(of: dailyNotificationEnabled) { _ in
                        HapticManager.shared.light()
                        applyNotificationSettings()
                    }
                    
                    if dailyNotificationEnabled {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.leading, 50)
                        
                        // 提醒時間設定
                        Button(action: {
                            showNotificationTimeAlert = true
                        }) {
                            HStack(spacing: 15) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(themeManager.themeColor)
                                    .frame(width: 30)
                                
                                Text(LocalizedStringKey("settings.reminderTime"))
                                    .font(.custom("SpotifyMix-Medium", size: 16))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text(String(format: "%02d:%02d", dailyNotificationHour, dailyNotificationMinute))
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
                        .sheet(isPresented: $showNotificationTimeAlert) {
                            NotificationTimePickerView(
                                hour: $dailyNotificationHour,
                                minute: $dailyNotificationMinute,
                                onSave: {
                                    applyNotificationSettings()
                                }
                            )
                            .presentationDetents([.height(350)])
                        }
                        
                        // MARK: - 測試通知按鈕（已隱藏）
                        /*
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.leading, 50)
                        
                        // 測試通知按鈕
                        Button(action: {
                            HapticManager.shared.light()
                            notificationService.sendTestNotification()
                        }) {
                            HStack(spacing: 15) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(themeManager.themeColor)
                                    .frame(width: 30)
                                
                                Text(LocalizedStringKey("settings.testNotification"))
                                    .font(.custom("SpotifyMix-Medium", size: 16))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding()
                        }
                        .buttonStyle(PlainButtonStyle())
                        */
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
#if DEBUG
        .alert("補寫 CloudKit 資料", isPresented: $showBackfillConfirmAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("開始補寫", action: backfillCloudKitHistory)
        } message: {
            Text("會將此裝置最近 7 天的 Top 50 快照寫入 iCloud，用來補齊缺漏資料。")
        }
        .alert("補寫結果", isPresented: $showBackfillResultAlert) {
            Button("common.ok", role: .cancel) { }
        } message: {
            Text(backfillResultMessage)
        }
#endif
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
                    
#if DEBUG
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.leading, 50)
                    
                    Button(action: {
                        showBackfillConfirmAlert = true
                    }) {
                        SettingRow(
                            icon: "icloud.and.arrow.up",
                            title: "補寫 CloudKit 排名資料",
                            value: isBackfillingRankingHistory ? "處理中…" : "",
                            showChevron: false,
                            themeColor: themeManager.themeColor
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isBackfillingRankingHistory)
                    .opacity(isBackfillingRankingHistory ? 0.6 : 1.0)
#endif
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
    
#if DEBUG
    // MARK: - 診斷資訊
    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("診斷資訊")
                .font(.custom("SpotifyMix-Bold", size: 22))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 10) {
                if !isLoggedIn {
                    Text("登入後會顯示 CloudKit 線上資料覆蓋與快照資訊。")
                        .font(.custom("SpotifyMix-Medium", size: 15))
                        .foregroundColor(.gray)
                } else if isDiagnosticsLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("載入中…")
                            .font(.custom("SpotifyMix-Medium", size: 15))
                            .foregroundColor(.gray)
                    }
                } else if let snapshot = diagnosticsSnapshot {
                    diagnosticsRow(title: "CloudKit 狀態", value: diagnosticsStatusText(snapshot.syncStatus))
                    diagnosticsRow(title: "快取筆數", value: "\(snapshot.totalEntries)")
                    diagnosticsRow(title: "覆蓋天數", value: "\(snapshot.distinctDays)")
                    diagnosticsRow(title: "最早記錄", value: formattedDate(snapshot.earliestDate))
                    diagnosticsRow(title: "最新記錄", value: formattedDate(snapshot.latestDate))
                    diagnosticsRow(title: "每日快照時間", value: formattedDate(lastSnapshotDate))
                } else {
                    Text("目前沒有可用的診斷資料。")
                        .font(.custom("SpotifyMix-Medium", size: 15))
                        .foregroundColor(.gray)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                Button(action: {
                    refreshDiagnosticsSnapshot()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重新整理")
                    }
                    .font(.custom("SpotifyMix-Medium", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .cornerRadius(15)
        }
    }
#endif
    
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
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "spo.stats")
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
#if DEBUG
    private func backfillCloudKitHistory() {
        guard !isBackfillingRankingHistory else { return }
        guard let userId = userProfile?.id else {
            backfillResultMessage = "無法取得使用者資訊，請重新登入後再試一次。"
            showBackfillResultAlert = true
            return
        }
        
        isBackfillingRankingHistory = true
        CloudKitRankingService.shared.backfillLocalCacheToCloudKit(
            userId: userId,
            timeRange: defaultTimeRange
        ) { result in
            DispatchQueue.main.async {
                self.isBackfillingRankingHistory = false
                
                switch result {
                case .success(let count):
                    if count == 0 {
                        self.backfillResultMessage = "目前沒有可補寫的本地資料。"
                    } else {
                        self.backfillResultMessage = "已補寫 \(count) 筆資料到 CloudKit。"
                    }
                case .failure(let error):
                    self.backfillResultMessage = "補寫失敗：\(error.localizedDescription)"
                }
                
                self.showBackfillResultAlert = true
            }
        }
    }
#endif
    
#if DEBUG
    private func refreshDiagnosticsSnapshot() {
        guard isLoggedIn, let userId = userProfile?.id else {
            diagnosticsSnapshot = nil
            return
        }
        
        isDiagnosticsLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let snapshot = CloudKitRankingService.shared.diagnosticsSnapshot(userId: userId, timeRange: defaultTimeRange)
            DispatchQueue.main.async {
                self.diagnosticsSnapshot = snapshot
                self.lastSnapshotDate = DailySnapshotScheduler.shared.lastSnapshotDate()
                self.isDiagnosticsLoading = false
            }
        }
    }
    
    private func diagnosticsRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.custom("SpotifyMix-Medium", size: 15))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.custom("SpotifyMix-Bold", size: 15))
                .foregroundColor(.white)
        }
    }
    
    private func diagnosticsStatusText(_ status: CloudKitSyncStatus) -> String {
        switch status {
        case .available:
            return "可用"
        case .syncing:
            return "同步中"
        case .unavailable:
            return "不可用"
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
#endif
    
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
    
    // MARK: - 通知相關
    
    private func applyNotificationSettings() {
        notificationService.scheduleDailyReminder(
            hour: dailyNotificationHour,
            minute: dailyNotificationMinute,
            enabled: dailyNotificationEnabled
        )
    }
}

// MARK: - 時間選擇器視圖
struct NotificationTimePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var hour: Int
    @Binding var minute: Int
    let onSave: () -> Void
    
    // 使用臨時狀態，只有按勾勾時才保存
    @State private var tempHour: Int
    @State private var tempMinute: Int
    
    init(hour: Binding<Int>, minute: Binding<Int>, onSave: @escaping () -> Void) {
        self._hour = hour
        self._minute = minute
        self.onSave = onSave
        // 初始化臨時變數
        self._tempHour = State(initialValue: hour.wrappedValue)
        self._tempMinute = State(initialValue: minute.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    // 小時選擇（綁定到臨時變數）
                    Picker("Hour", selection: $tempHour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d", h))
                                .font(.custom("SpotifyMix-Bold", size: 22))
                                .tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                    .clipped()
                    
                    Text(":")
                        .font(.custom("SpotifyMix-Bold", size: 28))
                        .foregroundColor(.white)
                    
                    // 分鐘選擇（綁定到臨時變數）
                    Picker("Minute", selection: $tempMinute) {
                        ForEach(0..<60, id: \.self) { m in
                            Text(String(format: "%02d", m))
                                .font(.custom("SpotifyMix-Bold", size: 22))
                                .tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                    .clipped()
                }
                .padding()
                .padding(.top, 20)
                
                Text("settings.reminderTime.description")
                    .font(.custom("SpotifyMix-Medium", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("settings.reminderTime")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 左側：取消按鈕（不保存，直接關閉）
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                
                // 右側：儲存按鈕（與播放按鈕一致：使用 borderedProminent + tint）
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.light()
                        // 儲存臨時變數到實際變數
                        hour = tempHour
                        minute = tempMinute
                        // 執行保存回調
                        onSave()
                        dismiss()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.spotifyText)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.spotifyGreen)
                }
            }
        }
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
