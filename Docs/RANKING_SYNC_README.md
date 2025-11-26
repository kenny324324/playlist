# 🎵 歌曲排名追蹤與跨裝置同步功能說明

## ✨ 功能概述

這個功能讓你追蹤 Spotify Top Tracks 的排名變化，並且支援**跨裝置自動同步**！

### 🎯 主要功能

1. **排名變化追蹤**
   - 🟢 上升：綠色向上箭頭 + 上升名次
   - 🔴 下降：紅色向下箭頭 + 下降名次
   - 🆕 新進榜：綠色 "NEW" 標籤
   - ➖ 不變：灰色橫線

2. **跨裝置同步**
   - 📱 iPhone 上的資料自動同步到 iPad
   - 💻 Mac 上的資料也會同步
   - 🔄 所有裝置保持一致

3. **智慧記錄**
   - ⏰ 每小時自動記錄一次
   - 🗑️ 自動清理 7 天前的舊資料
   - 💾 支援離線使用（本地快取）

---

## 📊 運作方式

### 儲存機制：CloudKit

使用 Apple 的 CloudKit 服務：
- ☁️ 資料儲存在 iCloud
- 🔒 完全私密（只有你能看到）
- 🆓 完全免費
- 🚀 自動同步

### 資料結構

每筆記錄包含：
```swift
{
  userId: "你的 Spotify ID",
  trackId: "歌曲 ID",
  rank: 排名（1-50），
  timeRange: "short_term" / "medium_term" / "long_term",
  recordedDate: 記錄時間
}
```

### 同步時間軸

```
時間點 0:00 - iPhone 上查看排行
  ↓
記錄到 CloudKit
  ↓
1-5 秒後 - 自動同步到 iCloud
  ↓
iPad 打開 App
  ↓
自動從 CloudKit 下載資料
  ↓
顯示排名變化
```

---

## 🎮 使用方式

### 首次使用

1. **設定 Xcode**
   - 請參考 `CLOUDKIT_SETUP.md` 啟用 CloudKit
   
2. **登入 iCloud**
   - 確保裝置已登入 iCloud 帳號
   - 設定 > [你的名字] > iCloud

3. **啟動 App**
   - 第一次載入會自動建立 CloudKit Schema
   - 開始記錄你的排名

### 日常使用

1. **查看排名變化**
   - 打開 App > Top 標籤
   - 選擇時間範圍（1個月/6個月/全部）
   - 查看每首歌的排名變化指示器

2. **跨裝置同步**
   - 在任一裝置上使用
   - 資料會自動同步到其他裝置
   - 無需任何手動操作

3. **切換帳號**
   - 每個 Spotify 帳號的資料獨立
   - 不會互相干擾
   - 登出後重新登入資料依然存在

---

## 🔧 技術實作細節

### 雙層架構：CloudKit + 本地快取

```
┌─────────────────────────────────┐
│   TopView (UI Layer)            │
├─────────────────────────────────┤
│   CloudKitRankingService        │
│   ┌───────────┬───────────────┐ │
│   │ CloudKit  │  Local Cache  │ │
│   │  (雲端)   │   (本地快取)   │ │
│   └───────────┴───────────────┘ │
└─────────────────────────────────┘
```

### 工作流程

1. **讀取資料**
   ```
   先從本地快取讀取（快速顯示）
   ↓
   背景從 CloudKit 同步最新資料
   ↓
   如有更新，自動刷新畫面
   ```

2. **儲存資料**
   ```
   同時儲存到本地快取和 CloudKit
   ↓
   CloudKit 自動同步到 iCloud
   ↓
   其他裝置自動接收更新
   ```

3. **離線模式**
   ```
   沒有網路時使用本地快取
   ↓
   恢復網路後自動同步
   ```

---

## 📱 使用場景

### 場景 1：單一裝置使用

```
第一次使用：所有歌曲顯示灰色橫線
  ↓
1 小時後：開始顯示排名變化
  ↓
持續追蹤：看到歌曲排名的起伏
```

### 場景 2：跨裝置使用

```
iPhone 上記錄
  ↓
切換到 iPad
  ↓
看到 iPhone 上記錄的排名變化
  ↓
在 iPad 上查看新排名
  ↓
資料同步回 iPhone
```

### 場景 3：多帳號使用

```
用戶 A 在 iPhone 上使用
  ↓
用戶 B 在同一台 iPhone 上登入
  ↓
看到的是自己的排名變化（不是用戶 A 的）
  ↓
用戶 A 重新登入
  ↓
資料完整保留
```

---

## 🎨 UI 展示

### 排名變化指示器

```
#1  ↑3   歌曲名稱     → 從第 4 名上升到第 1 名
#2  ➖   歌曲名稱     → 排名不變
#3  NEW  歌曲名稱     → 新進榜
#4  ↓2   歌曲名稱     → 從第 2 名下降到第 4 名
```

### 載入狀態

載入時顯示灰色橫線（佔位符）：
```
#1  ➖   [載入中...]
#2  ➖   [載入中...]
```

---

## ⚙️ 設定選項

### 記錄頻率

目前設定：**每 1 小時記錄一次**

如需修改，在 `CloudKitRankingService.swift` 中：
```swift
// 第 53 行
let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!

// 改為 30 分鐘
let thirtyMinutesAgo = Calendar.current.date(byAdding: .minute, value: -30, to: Date())!
```

### 資料保留時間

目前設定：**保留 7 天**

如需修改，在 `CloudKitRankingService.swift` 中：
```swift
// 第 324 行
let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

// 改為 14 天
let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
```

---

## 🐛 疑難排解

### 問題：看不到排名變化

**可能原因**：
1. 第一次使用（還沒有歷史資料）
2. 距離上次記錄不到 1 小時
3. CloudKit 同步延遲

**解決方法**：
- 等待至少 1 小時
- 檢查網路連線
- 查看 Console log 是否有錯誤訊息

### 問題：跨裝置沒有同步

**檢查項目**：
1. ✅ 所有裝置都登入同一個 iCloud 帳號
2. ✅ iCloud Drive 已啟用
3. ✅ 網路連線正常
4. ✅ 等待 5-10 秒（CloudKit 同步需要時間）

### 問題：CloudKit 錯誤

**常見錯誤**：
- `CKErrorNotAuthenticated`：未登入 iCloud
- `CKErrorNetworkUnavailable`：網路問題
- `CKErrorQuotaExceeded`：超過儲存額度（極少發生）

**解決方法**：
- 檢查 iCloud 登入狀態
- 確認網路連線
- 如超過額度，清理舊資料

---

## 📊 資料管理

### 清除特定用戶資料

```swift
if let userId = userProfile?.id {
    CloudKitRankingService.shared.clearHistory(for: userId) { success in
        if success {
            print("✅ 清除成功")
        }
    }
}
```

### 檢查同步狀態

在 Xcode Console 中查看：
```
✅ CloudKit: 成功儲存 50 筆排名記錄
✅ CloudKit: 清理了 120 筆舊記錄
```

### 查看 CloudKit 資料

1. 打開 [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. 選擇你的 Container
3. Data > Records > RankingHistory
4. 可以看到所有記錄

---

## 🚀 效能優化

### 本地快取

- 第一次讀取使用快取（毫秒級）
- 背景同步 CloudKit（不阻塞 UI）
- 智慧更新（只在資料變化時刷新）

### 批次操作

- 一次儲存 50 首歌（批次上傳）
- 減少網路請求次數
- 降低耗電量

### 自動清理

- 定期清理舊資料
- 保持資料庫輕量
- 不影響使用者體驗

---

## 💡 未來可能的擴展

### 可以加入的功能

1. **統計圖表**
   - 顯示排名變化趨勢
   - 長期排名走勢圖

2. **排行榜分享**
   - 分享當前 Top 10
   - 好友排行比較

3. **推播通知**
   - 歌曲進入 Top 10 時通知
   - 排名大幅變動時提醒

4. **更多時間維度**
   - 每日快照
   - 每週統計
   - 每月回顧

---

## 📚 相關文件

- `CLOUDKIT_SETUP.md` - CloudKit 設定指南
- `CloudKitRankingService.swift` - 核心服務程式碼
- `RankingHistory` Model - 資料結構定義

---

## 🎉 總結

這個功能讓你可以：
- 📊 追蹤歌曲排名變化
- 🔄 跨裝置自動同步
- 💾 離線也能使用
- 🆓 完全免費
- 🔒 完全私密

享受你的音樂排行追蹤之旅！🎵

