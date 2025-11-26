# MyPlaylist 本地化指南

## 📱 完成狀態

✅ **已完成四語本地化**

本專案現已支援：
- 🇬🇧 英文 (en)
- 🇹🇼 繁體中文 (zh-Hant)
- 🇯🇵 日文 (ja)
- 🇰🇷 韓文 (ko)

---

## 🗂️ 檔案結構

### 核心本地化檔案
- **`MyPlaylist/Localizable.xcstrings`**: String Catalog 格式的本地化字串檔案

### 已本地化的檔案
#### Views
- `ContentView.swift` - Tab 標籤、時間範圍
- `HomeView.swift` - 首頁所有區塊
- `TopView.swift` - 排行榜內容類型與時間範圍
- `SettingsView.swift` - 設定頁面
- `UserProfileView.swift` - 個人檔案
- `LoginView.swift` - 登入按鈕
- `RecentlyPlayedView.swift` - 最近播放
- `TopTracksView.swift` - 熱門歌曲
- `TopArtistsView.swift` - 熱門藝術家
- `TopGenresView.swift` - 熱門類型
- `TrackDetailView.swift` - 歌曲詳情
- `ArtistDetailView.swift` - 藝術家詳情
- `AlbumDetailView.swift` - 專輯詳情

#### Components
- `ArtistRow.swift` - 藝術家列表項目
- `GenreRow.swift` - 音樂類型列表項目

---

## 🔑 本地化 Key 命名規則

採用階層式命名，格式為：`<功能>.<類型>.<描述>`

### 範例
```
tab.home                        → "首頁" / "Home"
login.prompt.title              → "請登入 Spotify" / "Please log in to Spotify"
home.nowPlaying                 → "正在播放" / "Now Playing"
home.empty.noMusic              → "目前沒有播放音樂" / "No music playing"
detail.popularity               → "0-10 人氣" / "0-10 Popularity"
settings.features               → "功能特色" / "Features"
```

---

## 🛠️ 如何使用本地化字串

### 在 SwiftUI View 中

#### 1. 直接使用 LocalizedStringKey
```swift
Text("tab.home")  // SwiftUI 會自動查找本地化字串
```

#### 2. 使用 String(localized:)
```swift
Text(String(localized: "login.title"))
```

#### 3. 包含參數的字串
```swift
Text(String(localized: "home.viewRecent", 
    defaultValue: "View recent \(count) plays"))
```

#### 4. 使用 LocalizedStringKey 初始化
```swift
Text(LocalizedStringKey("settings.features"))
```

---

## 📝 新增本地化字串

### 在 Xcode 中編輯 Localizable.xcstrings

1. 在 Xcode 中打開 `Localizable.xcstrings`
2. 點擊 `+` 新增 Key
3. 輸入 Key 名稱（例如：`new.feature.title`）
4. 為每個語言（zh-Hant 和 en）輸入對應翻譯

### 手動編輯 JSON（進階）

在 `Localizable.xcstrings` 中新增：

```json
"new.feature.title" : {
  "localizations" : {
    "en" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "New Feature"
      }
    },
    "zh-Hant" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "新功能"
      }
    },
    "ja" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "新機能"
      }
    },
    "ko" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "새로운 기능"
      }
    }
  }
}
```

---

## 🌍 測試本地化

### 在模擬器中測試

1. 打開 **Settings** → **General** → **Language & Region**
2. 更改 **iPhone Language** 為：
   - **English** - 測試英文介面
   - **繁體中文（台灣）** - 測試繁中介面
   - **日本語** - 測試日文介面
   - **한국어** - 測試韓文介面
3. 重新啟動 App

### 在 Xcode 中快速測試

1. **Edit Scheme** → **Run** → **Options**
2. 設定 **App Language** 為：
   - `en` - 英文
   - `zh-Hant` - 繁體中文
   - `ja` - 日文
   - `ko` - 韓文
3. 運行 App

---

## 📊 本地化覆蓋範圍

### ✅ 已完成
- Tab 標籤（首頁、排行榜、設定）
- 登入相關文字
- 首頁所有區塊標題與空狀態提示
- 排行榜篩選選項
- 設定頁面功能說明
- 個人檔案與登出確認
- 詳細頁面（歌曲、藝術家、專輯）
- 時間範圍選擇器（1個月、6個月、所有時間）
- 音訊特徵標籤
- 錯誤與空狀態訊息

### 🔄 可擴充項目
- 更多語系（西班牙文、法文、德文等）
- 更細緻的複數形式處理
- 地區性日期與數字格式優化

---

## 🚀 最佳實踐

1. **使用 Key 而非硬編碼字串**
   ```swift
   ❌ Text("登入")
   ✅ Text("login.title")
   ```

2. **保持 Key 命名一致性**
   - 使用小寫與點號分隔
   - 遵循階層式命名

3. **為動態內容提供預設值**
   ```swift
   String(localized: "home.viewRecent", 
          defaultValue: "View recent \(count) plays")
   ```

4. **在新增功能時同步更新本地化**
   - 新增 UI 文字時立即建立本地化 Key
   - 為所有支援語言提供翻譯

---

## 📞 問題排查

### 本地化字串沒有顯示

1. **檢查 Key 拼寫** - 確認 Key 與 `Localizable.xcstrings` 中完全一致
2. **Clean Build Folder** - Xcode → Product → Clean Build Folder
3. **重新啟動 App** - 有時需要完全重啟
4. **檢查語系設定** - 確認裝置/模擬器語言設定正確

### 顯示 Key 而非翻譯文字

- Key 可能不存在於 String Catalog
- 檢查是否有錯字或大小寫問題
- 確認 `Localizable.xcstrings` 已加入專案 Target

---

## 👨‍💻 開發者

Made by Kenny

---

## 📄 授權

此專案為個人開發，使用時請遵循 Spotify API 使用條款。

