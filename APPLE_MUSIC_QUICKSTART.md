# Apple Music 整合 - 快速開始指南

## ⚡️ 必須完成的設定步驟

### 1. 在 Xcode 中添加 MusicKit 框架

這是**最重要**的步驟！

1. 打開 `MyPlaylist.xcodeproj`
2. 在左側選擇專案檔案（藍色圖示）
3. 選擇 **MyPlaylist** Target
4. 點擊 **General** 標籤
5. 滾動到 **"Frameworks, Libraries, and Embedded Content"**
6. 點擊 **"+"** 按鈕
7. 在搜尋框輸入 `MusicKit`
8. 選擇 `MusicKit.framework`
9. 確保 "Embed" 設定為 **"Do Not Embed"**（因為是系統框架）
10. 點擊 **Add**

### 2. 驗證設定

確認以下檔案已經正確更新（已自動完成）：
- ✅ `MyPlaylist.entitlements` - 已添加網路權限
- ✅ `Services/AppleMusicService.swift` - 已創建
- ✅ `Services/AudioPlayer.swift` - 已更新
- ✅ `Views/AppleMusicAuthView.swift` - 已創建
- ✅ `Localizable.xcstrings` - 已添加翻譯

### 3. 建置並執行

```bash
# 在 Terminal 中（可選）
cd /Users/jonathanyu/Desktop/𝙿𝚎𝚛𝚜𝚘𝚗𝚗𝚎𝚕/MyPlaylist
open MyPlaylist.xcodeproj
```

或直接在 Xcode 中：
1. 點擊 **Product** → **Clean Build Folder** (⇧⌘K)
2. 點擊 **Product** → **Build** (⌘B)
3. 點擊 **Run** (⌘R)

## 🎵 使用方式

### 第一次使用

1. 啟動 App
2. 點擊任何歌曲的**播放按鈕**
3. 如果 Spotify preview 不可用：
   - 系統會自動彈出 Apple Music 授權請求
   - 點擊 **"OK"** 授權
4. 授權成功後，歌曲會自動播放

### 檢查播放來源

在 `TrackDetailView` 中，播放時會顯示來源標籤：
- 如果顯示 "**Apple Music**" → 使用 Apple Music 播放
- 如果顯示 "**Spotify**" → 使用 Spotify preview 播放

## 🔧 故障排除

### 編譯錯誤：Cannot find 'MusicKit' in scope

**原因**：沒有在 Xcode 中添加 MusicKit 框架

**解決方法**：參考上面的「步驟 1」

### 執行時錯誤：Apple Music Service 未初始化

**原因**：AudioPlayer 初始化失敗

**解決方法**：確認所有檔案都已正確添加到 Target

### Apple Music 授權一直失敗

**可能原因**：
1. 使用者拒絕授權 → 請在系統設定中重新授權
2. 網路問題 → 檢查網路連線
3. Apple Music 在該地區不可用 → 會 fallback 到沒有預覽

## 📝 測試清單

在提交前請測試：
- [ ] 建置成功（無錯誤）
- [ ] App 可以正常啟動
- [ ] 點擊播放按鈕可以觸發 Apple Music 授權
- [ ] 授權後可以播放音樂
- [ ] 播放/暫停按鈕狀態正確
- [ ] 可以正常停止播放
- [ ] 切換不同歌曲時播放正常

## 🎯 下一步

完成設定後，您的 App 現在：
- ✅ 優先使用 Spotify preview（如果可用）
- ✅ 自動 fallback 到 Apple Music
- ✅ 提供無縫的音樂預覽體驗

所有原有功能保持不變，只是增加了更可靠的音樂預覽能力！

## 需要幫助？

查看完整文檔：`APPLE_MUSIC_INTEGRATION.md`

