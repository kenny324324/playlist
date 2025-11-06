# Apple Music 整合 - 快速開始指南

## ⚡️ 重要：必須在 Xcode 中完成的設定

### 步驟 1：添加 MusicKit 框架 ⭐️ 最重要！

1. 打開 `MyPlaylist.xcodeproj`
2. 在左側專案導覽器中，點擊最上方的專案檔案（藍色圖示）
3. 在中間選擇 **MyPlaylist** Target
4. 點擊 **General** 標籤
5. 向下滾動找到 **"Frameworks, Libraries, and Embedded Content"** 區塊
6. 點擊下方的 **"+"** 按鈕
7. 在彈出視窗的搜尋框中輸入 `MusicKit`
8. 選擇 `MusicKit.framework`
9. 確認右側的 "Embed" 欄位顯示 **"Do Not Embed"**
10. 點擊 **Add**

完成後應該會看到 MusicKit.framework 出現在列表中。

### 步驟 2：確認檔案已添加

以下檔案已自動創建和更新，請確認它們都在專案中：

**新增的檔案：**
- ✅ `Services/AppleMusicService.swift`
- ✅ `Views/AppleMusicAuthView.swift`
- ✅ `APPLE_MUSIC_INTEGRATION.md`
- ✅ `APPLE_MUSIC_QUICKSTART.md`

**已更新的檔案：**
- ✅ `Services/AudioPlayer.swift`
- ✅ `MyPlaylist.entitlements`
- ✅ `Localizable.xcstrings`
- ✅ `Views/TrackDetailView.swift`
- ✅ `Views/HomeView.swift`
- ✅ `Components/MiniPlayerBar.swift`

### 步驟 3：建置專案

1. 在 Xcode 中按 **⇧⌘K** (Shift + Command + K) 清理建置
2. 按 **⌘B** (Command + B) 建置專案
3. 確認沒有編譯錯誤
4. 按 **⌘R** (Command + R) 執行

## 🎵 功能說明

### 智能播放系統

您的 App 現在有雙重音樂預覽來源：

```
點擊播放按鈕
    ↓
Spotify preview URL 可用？
    ├─ 是 → 使用 Spotify 播放 ✅
    └─ 否 → 使用 Apple Music 播放 🎵
```

### 使用者體驗

1. **首次播放時**
   - 如果 Spotify 沒有 preview URL
   - 系統會自動請求 Apple Music 授權
   - 使用者點擊「好」即可

2. **已授權後**
   - 完全自動化
   - 使用者不需要做任何額外操作
   - 播放按鈕會顯示當前使用的來源

3. **播放來源顯示**
   - 在歌曲詳細頁面，播放時會顯示 "Apple Music" 或 "Spotify"
   - 讓使用者知道目前使用哪個服務

## 🔍 測試步驟

完成設定後，建議進行以下測試：

### 基本功能測試
1. ✅ **建置成功** - 沒有紅色錯誤
2. ✅ **App 啟動** - 可以正常開啟
3. ✅ **導覽正常** - 可以瀏覽歌曲列表

### 播放功能測試
4. ✅ **授權請求** - 點擊播放會彈出授權視窗
5. ✅ **授權成功** - 授權後可以播放
6. ✅ **播放控制** - 播放/暫停按鈕正常運作
7. ✅ **切換歌曲** - 可以切換到不同歌曲
8. ✅ **停止播放** - 可以正常停止

### 進階測試
9. ✅ **HomeView 播放** - 首頁的播放按鈕正常
10. ✅ **TrackDetail 播放** - 詳細頁面播放正常
11. ✅ **MiniPlayer 播放** - 底部播放條正常
12. ✅ **來源顯示** - 正確顯示播放來源

## ⚠️ 常見問題

### Q: 編譯時出現 "Cannot find 'MusicKit' in scope"

**A:** 這表示 MusicKit 框架沒有正確添加。請重新執行「步驟 1」。

確認檢查項目：
- MusicKit.framework 是否出現在 "Frameworks, Libraries, and Embedded Content" 列表中？
- "Embed" 設定是否為 "Do Not Embed"？

### Q: 執行時 App 立即崩潰

**A:** 可能的原因：
1. 檢查是否所有新檔案都已添加到 Target
2. 清理建置資料夾 (⇧⌘K) 後重新建置
3. 檢查 Console 的錯誤訊息

### Q: Apple Music 授權一直失敗

**A:** 可能的原因：
1. **網路問題** - 確認裝置有網路連線
2. **系統設定** - 檢查系統設定中 App 的權限
3. **地區限制** - Apple Music 在某些地區可能不可用

### Q: 播放時沒有聲音

**A:** 檢查項目：
1. 系統音量是否開啟
2. App 是否有音訊權限
3. Console 中是否有錯誤訊息
4. 嘗試播放其他歌曲

### Q: 想要查看使用哪個播放來源

**A:** 在 `TrackDetailView` 播放時，播放按鈕旁邊會顯示來源標籤：
- 顯示 "Apple Music" = 使用 Apple Music
- 顯示 "Spotify" = 使用 Spotify preview

## 📊 技術架構

### 核心組件

1. **AppleMusicService**
   - 負責 Apple Music 授權
   - 處理歌曲搜尋
   - 管理授權狀態

2. **AudioPlayer (已升級)**
   - 統一管理兩種播放來源
   - 自動選擇可用來源
   - 提供播放狀態追蹤

3. **UI 組件 (已更新)**
   - 所有播放按鈕都支援新系統
   - 自動顯示播放狀態
   - 提供來源資訊

### 播放流程

```swift
// 使用者點擊播放
Task {
    await audioPlayer.playTrack(
        trackName: "歌曲名稱",
        artistName: "藝人名稱",
        spotifyPreviewUrl: track.preview_url,  // 可能為 nil
        trackId: track.id
    )
}

// AudioPlayer 自動處理：
// 1. 檢查 Spotify URL
// 2. 如果沒有，搜尋 Apple Music
// 3. 播放找到的歌曲
```

## 🎯 重要提醒

### 關於 Apple Music 訂閱
- ❌ **不需要** Apple Music 訂閱就可以播放預覽
- ✅ 只需要授權 App 使用 Apple Music API
- ℹ️ 預覽播放是免費的功能

### 關於隱私
- App 只會搜尋歌曲資訊
- 不會存取使用者的 Apple Music 資料庫
- 不會上傳任何個人資訊

### 關於授權
- 授權是一次性的
- 使用者可以隨時在系統設定中撤銷
- App 會在需要時重新請求

## 📚 更多資訊

**完整技術文檔：** `APPLE_MUSIC_INTEGRATION.md`

**主要變更：**
- 新增 Apple Music 整合
- 保留所有原有功能
- 增強音樂預覽可靠性
- 改善使用者體驗

## ✅ 完成確認

如果您看到以下情況，表示整合成功：

- [x] 專案可以成功建置（無編譯錯誤）
- [x] App 可以正常啟動和運行
- [x] 點擊播放按鈕會觸發授權或播放
- [x] 可以聽到音樂預覽
- [x] 播放控制按鈕運作正常

恭喜！您的 App 現在擁有更可靠的音樂預覽功能了！🎉

