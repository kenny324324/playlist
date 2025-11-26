# ☁️ CloudKit 設定指南

本指南將教你如何在 Xcode 中啟用 CloudKit，讓你的 App 支援跨裝置同步。

---

## 📋 前置需求

1. ✅ Apple Developer 帳號（免費帳號也可以）
2. ✅ 已登入 Xcode 的 Apple ID
3. ✅ 裝置已登入 iCloud 帳號

---

## 🛠️ 設定步驟

### 步驟 1：在 Xcode 中開啟專案

打開 `MyPlaylist.xcodeproj`

### 步驟 2：選擇專案目標

1. 在左側檔案導覽中，點擊最上方的專案圖示
2. 在 **TARGETS** 列表中，選擇 `MyPlaylist`

### 步驟 3：啟用 iCloud Capability

1. 切換到 **Signing & Capabilities** 標籤
2. 點擊 **+ Capability** 按鈕
3. 搜尋並選擇 **iCloud**

### 步驟 4：設定 iCloud 服務

在新增的 iCloud 區塊中：

1. ✅ 勾選 **CloudKit**
2. 在 **Containers** 區域，你會看到一個預設容器：
   ```
   iCloud.$(CFBundleIdentifier)
   ```
   或者類似的名稱，例如：
   ```
   iCloud.com.yourname.MyPlaylist
   ```
3. 確保這個容器已被勾選

### 步驟 5：設定 CloudKit Schema（可選但建議）

1. 點擊 **CloudKit Dashboard** 按鈕（在 iCloud 設定區塊中）
2. 這會打開瀏覽器，進入 CloudKit 控制台
3. 選擇你的 Container
4. 在左側選單選擇 **Schema** > **Record Types**
5. 點擊 **+** 新增 Record Type：
   - **Record Type Name**: `RankingHistory`
   - 新增以下欄位：

   | Field Name | Field Type |
   |------------|------------|
   | userId | String |
   | trackId | String |
   | rank | Int(64) |
   | timeRange | String |
   | recordedDate | Date/Time |

6. 點擊 **Save** 儲存

> **注意**：如果不手動設定 Schema，CloudKit 會在第一次使用時自動建立，但手動設定可以確保欄位類型正確。

### 步驟 6：設定 Background Modes（可選）

如果你想要背景同步，可以啟用：

1. 在 **Signing & Capabilities** 中，點擊 **+ Capability**
2. 搜尋並選擇 **Background Modes**
3. 勾選：
   - ✅ **Remote notifications**（用於 CloudKit 推送更新）

---

## 🧪 測試設定

### 在模擬器測試

1. 打開模擬器的 **Settings** > **Apple ID**
2. 登入你的 Apple ID（需要真實的 iCloud 帳號）
3. 確保 iCloud Drive 已啟用
4. 執行 App，查看 Console 是否有 CloudKit 成功訊息

### 在真機測試

1. 確保裝置已登入 iCloud
2. 在 **設定** > **[你的名字]** > **iCloud** 中確認 iCloud Drive 已啟用
3. 安裝 App 並測試

### 測試跨裝置同步

1. 在裝置 A 上記錄排名資料
2. 等待約 5-10 秒（CloudKit 同步時間）
3. 在裝置 B 上打開 App，應該可以看到裝置 A 的資料

---

## 🎯 驗證 CloudKit 是否正常運作

### 檢查 Console Log

執行 App 後，在 Xcode Console 中應該看到：

```
✅ CloudKit: 成功儲存 50 筆排名記錄
```

如果看到錯誤訊息：
```
❌ CloudKit 儲存失敗: ...
```

請檢查：
1. ✅ 裝置是否登入 iCloud
2. ✅ iCloud Capability 是否正確設定
3. ✅ 網路連線是否正常

### 檢查 CloudKit Dashboard

1. 打開 [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. 選擇你的 Container
3. 切換到 **Data** > **Records**
4. 應該可以看到 `RankingHistory` 的記錄

---

## ⚙️ CloudKit 配額

### 免費額度（每個 App）

| 項目 | 免費額度 | 說明 |
|------|---------|------|
| **儲存空間** | 10 GB | 所有用戶共用 |
| **資料傳輸** | 200 GB/月 | 下載流量 |
| **請求次數** | 400 次/秒 | API 呼叫 |

**對於個人 App**：這些額度綽綽有餘！

---

## 🔧 常見問題

### Q1: 模擬器無法使用 CloudKit？
**A**: 確保模擬器已登入 Apple ID。Settings > Apple ID > Sign In

### Q2: 真機測試時提示權限錯誤？
**A**: 檢查 Signing & Capabilities 中的 Team 是否正確選擇

### Q3: 資料沒有同步到其他裝置？
**A**: CloudKit 同步需要幾秒到幾分鐘。請確保：
- 兩台裝置都登入同一個 iCloud 帳號
- 網路連線正常
- iCloud Drive 已啟用

### Q4: 如何清除 CloudKit 測試資料？
**A**: 在 CloudKit Dashboard > Data > Records 中手動刪除，或在 App 中呼叫：
```swift
CloudKitRankingService.shared.clearHistory(for: userId) { success in
    print(success ? "清除成功" : "清除失敗")
}
```

### Q5: 離線時 App 還能用嗎？
**A**: 可以！我們的實作包含本地快取，離線時會使用快取資料，上線後自動同步到 CloudKit。

---

## 📚 進階設定

### 開發環境 vs 正式環境

CloudKit 有兩個環境：
- **Development**：開發測試用
- **Production**：正式上架後使用

預設使用 Development 環境。要切換到 Production：

```swift
// 在 CloudKitRankingService.swift 中修改
private init() {
    container = CKContainer.default()
    // 改為使用 Production 環境
    privateDatabase = container.publicCloudDatabase
}
```

### 監控同步狀態

可以監聽 CloudKit 的通知：

```swift
NotificationCenter.default.addObserver(
    forName: .CKAccountChanged,
    object: nil,
    queue: .main
) { _ in
    print("iCloud 帳號狀態改變")
}
```

---

## ✅ 完成檢查清單

設定完成後，請確認：

- [ ] Xcode 中已啟用 iCloud Capability
- [ ] iCloud 容器已勾選
- [ ] CloudKit Schema 已建立（或允許自動建立）
- [ ] 裝置已登入 iCloud
- [ ] App 可以正常儲存和讀取資料
- [ ] 跨裝置同步功能正常

---

## 🎉 大功告成！

現在你的 App 已經支援跨裝置同步了！

**使用體驗**：
- 📱 iPhone 上查看排行
- 💻 切換到 iPad，資料自動出現
- 🔄 兩台裝置的資料保持同步

如有任何問題，請參考：
- [Apple CloudKit 官方文檔](https://developer.apple.com/documentation/cloudkit)
- [CloudKit 最佳實踐](https://developer.apple.com/videos/play/wwdc2021/10086/)

