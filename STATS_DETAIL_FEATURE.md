# 統計卡片詳細資訊功能實作完成

## 📋 功能概述

為專輯詳細頁和藝人詳細頁的統計卡片增加了點擊功能，點擊後會彈出 Sheet 顯示相關歌曲的詳細列表，包含排名資訊。

## ✅ 完成的工作

### 1. 更新 `StatsCalculationService.swift`
- 新增 `RankedTrack` 資料結構，保存歌曲的詳細資訊和排名
- 更新 `AlbumStats` 和 `ArtistStats`，增加四個歌曲列表屬性：
  - `shortTermTracks` - 4週 Top 50 的詳細歌曲列表
  - `mediumTermTracks` - 6個月 Top 50 的詳細歌曲列表
  - `longTermTracks` - 所有時間 Top 50 的詳細歌曲列表
  - `recentTracks` - 最近50次播放的詳細歌曲列表
- 修改 `calculateAlbumStats()` 和 `calculateArtistStats()` 方法，不僅計算數量，還保存完整的歌曲列表和排名

### 2. 創建 `StatsDetailViews.swift`
- 實作 `StatsDetailSheet` - 統一的 Sheet View 用於顯示統計詳情
  - 顯示標題和副標題
  - 列表顯示所有相關歌曲，按排名順序
  - 支援點擊歌曲進入歌曲詳細頁
  - 包含空狀態處理
- 實作 `StatsCardType` enum - 管理8種不同的統計卡片類型
  - 專輯4種：短期、中期、長期、最近播放
  - 藝人4種：短期、中期、長期、最近播放
  - 提供本地化標題和副標題的方法

### 3. 更新 `SmallStatCard.swift`
- 增加 `onTap` 參數，支援點擊事件
- 將卡片包裝在 `Button` 中
- 新增 `StatCardButtonStyle` 提供按壓視覺回饋（縮放和透明度效果）

### 4. 更新 `AlbumDetailView.swift`
- 增加 Sheet 控制狀態變數：
  - `showStatsDetail` - 控制 Sheet 顯示
  - `selectedStatsType` - 記錄選中的統計類型
- 修改 `albumStatsSection()` 為每個卡片增加 `onTap` 處理
- 增加 Sheet 綁定，顯示 `StatsDetailSheet`
- 新增輔助方法：
  - `getTracks()` - 根據類型獲取對應的歌曲列表
  - `getTrackCount()` - 根據類型獲取歌曲數量

### 5. 更新 `ArtistDetailView.swift`
- 同樣的修改方式，與 `AlbumDetailView.swift` 保持一致
- 增加 Sheet 控制和輔助方法

### 6. 更新 `Localizable.xcstrings`
- 新增 `common.done` - "完成" 按鈕文字
- 新增 16 個 `stats.detail.*` 本地化字串：
  - 標題相關（8個）：album/artist × shortTerm/mediumTerm/longTerm/recent
  - 副標題相關（8個）：同上，支援參數化
- 支援4種語言：英文、日文、韓文、繁體中文

## 🎯 功能特點

### 使用者體驗
1. **點擊卡片** - 統計卡片現在都可以點擊
2. **視覺回饋** - 點擊時有縮放和透明度動畫
3. **詳細列表** - Sheet 中顯示完整的歌曲列表
4. **排名顯示** - 
   - Top 50 卡片：顯示 #1, #2, #3... 等排名
   - 最近播放：顯示第 1 次、第 2 次... 等順序
5. **前10名高亮** - 排名前10的歌曲以綠色顯示
6. **可導航** - 點擊歌曲可進入歌曲詳細頁

### 技術特點
1. **延遲載入** - 只有切換到 Stats 分頁時才載入數據
2. **資料完整** - 保存完整的歌曲資訊，包括封面、藝人、專輯名稱
3. **可重用元件** - `StatsDetailSheet` 可用於不同的統計類型
4. **類型安全** - 使用 enum 管理不同的統計卡片類型
5. **國際化** - 完整支援多語言

## 📱 支援的統計卡片（共8個）

### 專輯詳細頁（4個）
1. 過去4週 Top 50
2. 過去6個月 Top 50
3. 所有時間 Top 50
4. 最近50次播放

### 藝人詳細頁（4個）
1. 過去4週 Top 50
2. 過去6個月 Top 50
3. 所有時間 Top 50
4. 最近50次播放

## 🚀 使用方式

1. 進入專輯或藝人詳細頁
2. 切換到 "Stats" 分頁
3. 點擊任意統計卡片
4. 在彈出的 Sheet 中查看詳細歌曲列表
5. 點擊任意歌曲進入歌曲詳細頁

## 📂 檔案結構

```
MyPlaylist/
├── Services/
│   └── StatsCalculationService.swift (已更新)
├── Views/
│   ├── StatsDetailViews.swift (新建)
│   ├── AlbumDetailView.swift (已更新)
│   └── ArtistDetailView.swift (已更新)
├── Components/
│   └── SmallStatCard.swift (已更新)
└── Localizable.xcstrings (已更新)
```

## ✨ 實作亮點

- **架構清晰**：統計計算、UI 顯示、Sheet 管理分離明確
- **程式碼可維護**：使用 enum 和 helper methods 降低重複代碼
- **使用者體驗佳**：流暢的動畫、清晰的資訊呈現、直觀的互動
- **國際化完整**：所有文字都支援多語言

## 🎉 完成狀態

所有功能已實作完成，無 linter 錯誤，可以直接編譯運行！

