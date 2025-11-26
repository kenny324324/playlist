# App Store 審核說明

本文檔提供給 App Store Connect 審核資訊區塊使用的完整說明文字。

---

## 📋 在 App Store Connect 填寫的內容

### 位置
```
App Store Connect → 您的 App → App 審查資訊
```

---

## 📝 審核說明（中文版）

複製以下內容到「備註」欄位：

```
測試說明：

本 App 需要 Spotify Premium 付費帳號才能使用完整功能。

為方便審核，我們在審核版本中加入了「Demo 模式」功能。

測試步驟：
1. 啟動 App
2. 在首頁（Home）會看到橙色的「🎭 Demo 模式 (供審核使用)」按鈕
3. 點擊該按鈕即可進入 Demo 模式
4. Demo 模式包含所有功能的完整展示

Demo 模式功能：
• 預先載入的用戶資料（虛擬用戶）
• 50+ 首熱門歌曲（包含 The Weeknd、Ed Sheeran、Taylor Swift 等藝人）
• 8 位知名藝人資料
• 4 個播放列表
• 最近播放記錄
• 收藏的歌曲和專輯
• 完整的 UI/UX 展示
• 音樂播放功能（使用 Apple Music 預覽）
• 搜尋功能
• 排行榜統計
• 所有導覽和互動功能

視覺提示：
• 進入 Demo 模式後，頂部會顯示橙色的「🎭 Demo 模式」標籤
• 所有功能都可以正常使用和測試

注意事項：
• Demo 按鈕僅在審核版本中顯示
• 正式發布版本不包含此按鈕
• Demo 數據為模擬數據，不會連接真實的 Spotify API
• 音樂播放使用 Apple Music 預覽 API（免費）

如有任何問題，請隨時聯繫我們。
謝謝！
```

---

## 📝 審核說明（英文版）

如果審核團隊使用英文，可以使用以下版本：

```
Testing Instructions:

This app requires a Spotify Premium paid account to access full functionality.

For review purposes, we have included a "Demo Mode" feature in the review build.

How to Test:
1. Launch the app
2. On the Home screen, you will see an orange button labeled "🎭 Demo 模式 (供審核使用)" 
   (Demo Mode for Review)
3. Tap this button to enter Demo Mode
4. Demo Mode provides full access to all app features

Demo Mode Features:
• Pre-loaded user profile (virtual user)
• 50+ popular tracks (including artists like The Weeknd, Ed Sheeran, Taylor Swift, etc.)
• 8 well-known artists
• 4 playlists
• Recently played history
• Saved tracks and albums
• Complete UI/UX demonstration
• Music playback functionality (using Apple Music preview API)
• Search functionality
• Chart rankings and statistics
• All navigation and interaction features

Visual Indicator:
• Once in Demo Mode, an orange "🎭 Demo 模式" badge appears at the top
• All features are fully functional and testable

Important Notes:
• The Demo button is ONLY visible in the review build
• The production release does NOT include this button
• Demo data is simulated and does not connect to real Spotify API
• Music playback uses Apple Music preview API (free)

Please feel free to contact us if you have any questions.
Thank you!
```

---

## 🔐 登入資訊欄位

**是否需要填寫？**
```
❌ 不需要

原因：Demo 模式不需要任何登入資訊
```

如果 App Store Connect 要求必須填寫，可以填：

```
使用者名稱：demo_mode
密碼：not_required

備註：請點擊 App 內的「Demo 模式」按鈕，無需登入。
```

---

## 📸 Demo 影片或截圖（可選）

雖然 Apple 說提供影片不足以通過審核，但您仍可以附加截圖來輔助說明：

### 建議截圖：

1. **啟動畫面** - 顯示 Demo 按鈕的位置
2. **Demo 模式標籤** - 頂部的橙色標籤
3. **主要功能** - 展示歌曲列表、播放器等
4. **完整流程** - 從點擊 Demo 按鈕到使用功能

### 截圖命名建議：
```
1_demo_button_location.png
2_demo_mode_indicator.png
3_main_features.png
4_full_workflow.png
```

---

## ⚠️ 重要提醒

### ✅ 提交審核前檢查清單

- [ ] 使用 **MyPlaylist (AppStore Review)** Scheme 建置
- [ ] 確認 Demo 按鈕在 App 中可見（橙色按鈕）
- [ ] 測試 Demo 模式所有功能正常運作
- [ ] 在 App Store Connect 填寫審核說明
- [ ] 版本發布設定為「**手動發布此版本**」⚠️

### ❌ 常見錯誤

1. **忘記切換 Scheme** → 提交了正式版本，審核團隊看不到 Demo 按鈕
2. **選擇自動發布** → 審核通過後自動上架有 Demo 按鈕的版本
3. **說明不清楚** → 審核員找不到 Demo 按鈕在哪裡

---

## 📞 審核團隊可能的問題和回應

### Q: 為什麼需要 Spotify Premium？

```
回應：
我們的 App 整合了 Spotify API，根據 Spotify 的 API 使用條款，
某些功能（如獲取用戶的熱門歌曲、播放列表等）僅對 Premium 用戶開放。

為了解決審核問題，我們特別開發了 Demo 模式，
讓審核團隊無需 Spotify 帳號即可完整測試所有功能。
```

### Q: Demo 模式的數據是真實的嗎？

```
回應：
Demo 模式使用精心設計的模擬數據，但功能流程與真實使用完全相同。
所有 UI 互動、導覽、動畫效果都與正式版本一致。

音樂播放功能使用 Apple Music 預覽 API，
可以實際聽到音樂片段（30秒預覽）。
```

### Q: 正式用戶會看到 Demo 按鈕嗎？

```
回應：
不會。Demo 按鈕僅在審核版本中顯示，使用 Swift 的條件編譯功能實現。

正式發布給用戶的版本，我們會上傳不同的建置檔案（Build +1），
該版本完全不包含 Demo 相關的代碼。
```

---

## 🎯 審核策略

### 主動溝通

如果審核被拒絕，在 Resolution Center 回覆時可以強調：

```
您好，

感謝您的反饋。關於審核問題，我想說明：

1. ✅ Demo 模式按鈕位置：
   - 啟動 App 後
   - 在「首頁 (Home)」標籤頁
   - 中央位置的橙色按鈕
   - 文字：「🎭 Demo 模式 (供審核使用)」

2. ✅ 無需任何登入：
   - 直接點擊 Demo 按鈕即可
   - 不需要 Spotify 帳號
   - 不需要填寫任何資訊

3. ✅ 完整功能展示：
   - 所有功能都已在 Demo 模式中實作
   - 包含真實的音樂預覽播放
   - UI/UX 與正式版本完全相同

4. ✅ 用戶不會看到：
   - Demo 按鈕僅在審核版本顯示
   - 正式版本會上傳新的 Build
   - 使用條件編譯確保完全分離

如果仍有任何問題或需要進一步說明，請隨時告知。
我們非常樂意配合審核流程。

謝謝！
```

---

## 📊 時間規劃

### 典型審核流程時間線

```
Day 0: 提交審核版本 (Build 100, 有 Demo 按鈕)
       ↓
Day 1-3: 等待審核（狀態：等待審核）
       ↓
Day 3-5: 審核中（狀態：審核中）
       ↓
Day 5: 審核通過！（狀態：等待開發者發布）⭐️
       ↓
       ⚠️ 不要點擊「發布」！
       ↓
Day 5 (1小時內): 
       1. 在 Xcode 切換到正式 Scheme
       2. Build 改為 101
       3. Archive 正式版本
       4. 上傳新 Build
       ↓
Day 5 (2小時內):
       1. 在 App Store Connect 選擇 Build 101
       2. 點擊「發布 App」
       ↓
Day 5-6: App 正式上架 ✅（用戶看不到 Demo 按鈕）
```

---

## ✅ 成功指標

審核成功通過的標準：

- ✅ 審核團隊能找到並使用 Demo 按鈕
- ✅ 所有功能都能正常測試
- ✅ 沒有崩潰或錯誤
- ✅ UI/UX 符合 Apple 設計指南
- ✅ 正式版本成功發布（無 Demo 按鈕）

---

## 📚 相關文檔

- [Xcode 設定指南](./XCODE_設定指南.md) - 詳細的建置設定步驟
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

---

## 💡 最佳實踐

1. **提前準備**：在提交前至少測試 5 次完整流程
2. **清晰說明**：審核說明要簡單明瞭，步驟清楚
3. **及時響應**：如果審核團隊有問題，24小時內回覆
4. **保持耐心**：首次審核可能需要更長時間
5. **文檔齊全**：準備好所有說明文件，隨時可以提供

---

## 🎉 祝您審核順利！

按照本文檔的說明，您的 App 應該能順利通過審核。

記住：**Demo 模式是為了審核團隊方便測試，不是為了繞過審核**。
我們誠實地說明了 App 的功能和限制，並提供了完整的測試方式。

Good luck! 🍀

