# Demo 模式 - 完整說明

## 🎯 目的

由於本 App 需要 Spotify Premium 付費帳號才能使用，為了通過 Apple App Store 審核，我們實作了 **Demo 模式**功能。

Demo 模式讓 Apple 審核團隊無需 Spotify 帳號即可完整測試所有功能。

---

## ✨ 特點

- ✅ **條件編譯**：使用 `#if APPSTORE_REVIEW` 確保 Demo 按鈕只在審核版本顯示
- ✅ **完整數據**：包含 50+ 歌曲、8 位藝人、4 個播放列表等模擬數據
- ✅ **真實體驗**：所有 UI/UX 與正式版本完全相同
- ✅ **音樂播放**：使用 Apple Music 預覽 API，可實際播放音樂
- ✅ **安全隔離**：審核版本和正式版本完全分離

---

## 📁 檔案結構

### 新增的檔案

```
MyPlaylist/
├── Services/
│   └── DemoModeManager.swift          # Demo 模式管理器
├── Models/
│   └── MockSpotifyData.swift          # 模擬 Spotify 數據
├── XCODE_設定指南.md                  # Xcode 設定教學
├── APP_STORE_審核說明.md              # 審核說明文件
└── DEMO_MODE_README.md               # 本文件
```

### 修改的檔案

```
MyPlaylist/
├── Views/
│   ├── LoginView.swift               # 添加 Demo 按鈕（條件編譯）
│   ├── ContentView.swift             # 支援 Demo 模式 + 視覺指示器
│   └── HomeView.swift                # 支援 Demo 模式按鈕
└── Services/
    └── SpotifyAPIService.swift        # 所有 API 支援 Demo 模式
```

---

## 🛠️ 技術實作

### 1. DemoModeManager

管理 Demo 模式的全局狀態。

```swift
class DemoModeManager: ObservableObject {
    static let shared = DemoModeManager()
    
    @Published var isDemoMode: Bool = false
    
    func enableDemoMode() {
        isDemoMode = true
    }
}
```

### 2. MockSpotifyData

提供完整的模擬數據。

包含：
- ✅ 用戶資料（demoUser）
- ✅ 50 首歌曲（demoTracks）
- ✅ 8 位藝人（demoArtists）
- ✅ 4 個播放列表（demoPlaylists）
- ✅ 目前播放（demoCurrentlyPlaying）
- ✅ 最近播放（demoRecentlyPlayed）
- ✅ 收藏歌曲/專輯（demoSavedTracks/Albums）
- ✅ 追蹤的藝人（demoFollowedArtists）
- ✅ 搜尋結果（demoSearchResults）
- ✅ 新發行專輯（demoNewReleases）

### 3. 條件編譯

使用 Swift 的條件編譯功能：

```swift
#if APPSTORE_REVIEW
// 這段代碼只在審核版本中編譯
Button("🎭 Demo 模式 (供審核使用)") {
    enterDemoMode()
}
#endif
```

### 4. SpotifyAPIService 整合

所有 API 函數都檢查 Demo 模式：

```swift
static func fetchTopTracks(...) {
    // Demo 模式：返回模擬數據
    if isDemoMode {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(MockSpotifyData.demoTracks)
        }
        return
    }
    
    // 正常模式：呼叫真實 API
    ...
}
```

---

## 🎨 用戶界面

### Demo 按鈕（僅審核版本）

位置：**HomeView** 未登入狀態

外觀：
- 橙色按鈕
- 圖示：🎭 (theatermasks)
- 文字：「Demo 模式 (供審核使用)」

### Demo 模式指示器

當 Demo 模式啟用時，頂部顯示橙色標籤：

```
🎭 Demo 模式 🎭
```

特點：
- 顯示在所有頁面頂部
- 橙色背景，白色文字
- 陰影效果
- zIndex: 999（確保在最上層）

---

## 📋 使用流程

### 開發測試

1. 在 Xcode 切換到 **MyPlaylist (AppStore Review)** Scheme
2. 執行 App（⌘R）
3. 會看到橙色 Demo 按鈕
4. 點擊進入 Demo 模式
5. 測試所有功能

### 提交審核

1. 使用 **MyPlaylist (AppStore Review)** Scheme
2. Archive（⌃⌘B）
3. 上傳到 App Store Connect
4. 填寫審核說明（見 `APP_STORE_審核說明.md`）
5. 設定「手動發布」
6. 提交審核

### 審核通過後

1. 切換到 **MyPlaylist** Scheme
2. Build 號 +1
3. Archive 正式版本
4. 上傳新 Build
5. 在 App Store Connect 選擇新 Build
6. 發布給用戶

---

## 🔍 驗證方法

### 確認審核版本（有 Demo 按鈕）

```bash
# 1. 切換 Scheme
Xcode → MyPlaylist (AppStore Review)

# 2. 建置並執行
Product → Run (⌘R)

# 3. 檢查
✅ 首頁應該看到橙色 Demo 按鈕
✅ 點擊後頂部出現 Demo 模式標籤
✅ 所有功能正常運作
```

### 確認正式版本（無 Demo 按鈕）

```bash
# 1. 切換 Scheme
Xcode → MyPlaylist

# 2. 建置並執行
Product → Run (⌘R)

# 3. 檢查
✅ 首頁應該看不到 Demo 按鈕
✅ 只有正常的登入提示
✅ 需要 Spotify 登入才能使用
```

---

## 🎵 Demo 模式功能清單

當進入 Demo 模式後，以下功能都可以使用：

### ✅ 首頁（Home）
- Dashboard 儀表板
- 正在播放
- 最近收藏的歌曲
- 最近收藏的專輯
- 用戶播放列表
- 最近播放記錄
- 追蹤的藝人

### ✅ 搜尋（Search）
- 搜尋歌曲
- 搜尋藝人
- 搜尋專輯
- 精選播放列表
- 新發行專輯

### ✅ 排行榜（Top）
- 熱門歌曲（1個月/6個月/1年）
- 熱門藝人（1個月/6個月/1年）
- 熱門曲風
- 排名變化追蹤

### ✅ 設定（Settings）
- 用戶資料顯示
- 更新頻率設定
- 主題設定
- 關於資訊

### ✅ 播放功能
- 音樂預覽播放（使用 Apple Music API）
- 播放控制（播放/暫停/停止）
- Mini Player
- 進度條
- 專輯封面顯示

### ✅ 詳細資訊
- 歌曲詳細頁面
- 藝人詳細頁面
- 專輯詳細頁面
- 音訊特徵分析

---

## ⚠️ 限制和注意事項

### Demo 模式的限制

1. **數據固定**
   - 使用預設的模擬數據
   - 不會連接真實 Spotify API
   - 數據不會更新

2. **功能模擬**
   - 所有操作都是模擬的
   - 不會影響真實的 Spotify 帳號
   - 無法儲存或修改資料

3. **音樂播放**
   - 使用 Apple Music 預覽（30秒）
   - 某些歌曲可能沒有預覽
   - 需要網路連線

### 正式版本的差異

| 功能 | Demo 模式 | 正式版本 |
|-----|---------|---------|
| 數據來源 | 模擬數據 | Spotify API |
| 登入需求 | 不需要 | 需要 Spotify Premium |
| 數據更新 | 固定不變 | 即時更新 |
| 音樂播放 | Apple Music 預覽 | Spotify 預覽 + Apple Music |
| 排名追蹤 | 模擬數據 | 真實追蹤 |

---

## 🐛 疑難排解

### Demo 按鈕沒有出現

**原因**：可能使用了錯誤的 Scheme

**解決方法**：
1. 檢查 Xcode 頂部 Scheme 選擇器
2. 確認選擇的是 **MyPlaylist (AppStore Review)**
3. Product → Clean Build Folder (⇧⌘K)
4. 重新建置

### Demo 模式進入後沒有數據

**原因**：可能是 Demo 模式啟用失敗

**解決方法**：
1. 檢查 Console 輸出
2. 確認 `DemoModeManager.shared.isDemoMode` 為 true
3. 重新點擊 Demo 按鈕

### 審核版本無法 Archive

**原因**：Build Configuration 設定錯誤

**解決方法**：
1. Edit Scheme → Archive
2. 確認 Build Configuration 為 **AppStoreReview**
3. 檢查 Other Swift Flags 有 `-D APPSTORE_REVIEW`

---

## 📚 相關文檔

1. **[XCODE_設定指南.md](./XCODE_設定指南.md)**
   - 詳細的 Xcode 設定步驟
   - Build Configuration 設定
   - Scheme 創建教學

2. **[APP_STORE_審核說明.md](./APP_STORE_審核說明.md)**
   - App Store Connect 填寫內容
   - 審核說明範本
   - 常見問題回應

3. **[APPLE_MUSIC_快速開始.md](./APPLE_MUSIC_快速開始.md)**
   - Apple Music 整合說明
   - 播放功能介紹

---

## 🎯 最佳實踐

### 開發時

1. **使用正確的 Scheme**
   - 日常開發：MyPlaylist
   - 測試 Demo：MyPlaylist (AppStore Review)

2. **定期測試**
   - 每次修改後測試兩個版本
   - 確保功能一致

3. **保持代碼整潔**
   - Demo 相關代碼使用條件編譯
   - 添加清楚的註解

### 提交審核時

1. **提前準備**
   - 提交前完整測試 Demo 模式
   - 準備清楚的審核說明
   - 檢查所有文檔

2. **版本管理**
   - 使用 Git tag 標記版本
   - 記錄 Build 號
   - 保留審核版本的 Archive

3. **快速響應**
   - 審核通過後立即上傳正式版本
   - 及時回應審核團隊問題

---

## ✅ 檢查清單

提交前請確認：

### 代碼層面
- [ ] DemoModeManager 正確實作
- [ ] MockSpotifyData 包含完整數據
- [ ] 所有 API 函數支援 Demo 模式
- [ ] 條件編譯正確使用

### Xcode 設定
- [ ] 創建 AppStoreReview Build Configuration
- [ ] 設定 Other Swift Flags: `-D APPSTORE_REVIEW`
- [ ] 創建 AppStore Review Scheme
- [ ] Scheme 的 Run 和 Archive 都設為 AppStoreReview

### 功能測試
- [ ] 審核版本：Demo 按鈕可見且正常運作
- [ ] 正式版本：Demo 按鈕不可見
- [ ] Demo 模式：所有功能正常
- [ ] 音樂播放：預覽可以正常播放

### 文檔準備
- [ ] 閱讀 XCODE_設定指南.md
- [ ] 閱讀 APP_STORE_審核說明.md
- [ ] 準備審核說明文字
- [ ] 準備截圖（可選）

### App Store Connect
- [ ] 上傳審核版本（Build 100）
- [ ] 填寫審核說明
- [ ] 設定「手動發布」
- [ ] 準備正式版本（Build 101）

---

## 🎉 結語

Demo 模式的實作確保了：

1. ✅ **審核順利**：審核團隊可以完整測試所有功能
2. ✅ **用戶體驗**：正式用戶不會看到任何審核相關的內容
3. ✅ **代碼品質**：使用條件編譯保持代碼整潔
4. ✅ **維護簡單**：未來更新時可以重複使用相同流程

現在您已經完全了解 Demo 模式的實作和使用方式了！

祝審核順利！🚀

---

## 📞 技術支援

如果遇到問題：

1. 查看相關文檔的疑難排解章節
2. 檢查 Xcode Console 的錯誤訊息
3. 確認每個設定步驟都正確完成
4. 清理建置資料夾後重試

---

**版本**：1.0.0  
**最後更新**：2025-11-06  
**作者**：MyPlaylist Development Team

