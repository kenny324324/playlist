# MyPlaylist - Spotify 音樂統計應用

## 📁 專案結構

```
MyPlaylist/
├── 📱 Views/                    # 主要視圖檔案
│   ├── HomeView.swift          # 首頁 - 正在播放和最近播放
│   ├── TopTracksView.swift     # 熱門歌曲頁面
│   ├── TopArtistsView.swift    # 熱門藝術家頁面
│   ├── TopGenresView.swift     # 音樂類型統計頁面
│   ├── UserProfileView.swift   # 使用者檔案頁面
│   ├── LoginView.swift         # 登入頁面
│   ├── PlayerView.swift        # 音樂播放器控制項
│   ├── SettingsView.swift      # 設定頁面
│   └── SafariView.swift        # Safari 視圖包裝器
│
├── 🔧 Services/                 # 服務層
│   ├── SpotifyAPIService.swift # Spotify API 呼叫服務
│   ├── SpotifyAuthService.swift # Spotify 認證服務
│   └── AudioPlayer.swift       # 音訊播放服務
│
├── 📊 Models/                   # 資料模型
│   └── SpotifyModels.swift     # Spotify 相關資料結構
│
├── 🧩 Components/               # 可重用元件
│   ├── TrackRow.swift          # 歌曲列表項目
│   ├── ArtistRow.swift         # 藝術家列表項目
│   └── GenreRow.swift          # 音樂類型列表項目
│
├── 🏠 根目錄檔案
│   ├── MyPlaylistApp.swift     # 應用程式入口點
│   ├── ContentView.swift       # 主要內容視圖
│   ├── AppDelegate.swift       # 應用程式代理
│   └── Extensions.swift        # Swift 擴展
│
└── 📦 資源檔案
    ├── Assets.xcassets/        # 圖片和顏色資源
    ├── Info.plist             # 應用程式設定
    ├── Preview Content/       # SwiftUI Preview 資源
    └── *.ttf                  # 自訂字體檔案
```

## 🎯 功能特色

### 🏠 首頁 (HomeView)
- **正在播放**：顯示 Spotify 目前播放的歌曲
- **最近播放**：顯示播放歷史記錄
- **刷新按鈕**：手動更新資料
- **音樂試聽**：播放歌曲預覽

### 📊 統計頁面
- **熱門歌曲**：按時間範圍顯示最常聽的歌曲
- **熱門藝術家**：顯示最愛的藝術家資訊
- **音樂類型**：分析音樂偏好統計

### 👤 使用者功能
- **Spotify 登入**：OAuth 2.0 認證流程
- **個人檔案**：顯示使用者資訊和播放清單
- **音樂播放**：30 秒預覽播放功能

## 🛠 技術架構

### 架構模式
- **MVVM**：使用 SwiftUI 的 @State 和 @ObservedObject
- **服務層**：分離 API 呼叫和業務邏輯
- **元件化**：可重用的 UI 元件

### 主要技術
- **SwiftUI**：現代化 UI 框架
- **AVPlayer**：音訊播放
- **URLSession**：網路請求
- **UserDefaults**：本地資料儲存

### Spotify API 整合
- **OAuth 2.0**：安全的認證流程
- **Token 管理**：自動刷新過期 token
- **多個端點**：播放資料、使用者資訊、播放清單

## 🎨 設計特色

### 視覺設計
- **深色主題**：符合 Spotify 品牌風格
- **自訂字體**：SpotifyMix 字體系列
- **綠色強調色**：品牌一致性

### 使用者體驗
- **響應式設計**：適配不同螢幕尺寸
- **流暢動畫**：提升互動體驗
- **直觀導航**：Tab 式導航結構

## 📱 支援功能

### 裝置支援
- **iPhone**：主要目標平台
- **iPad**：適配支援
- **iOS 16.6+**：最低系統要求

### 權限需求
- **網路存取**：Spotify API 呼叫
- **音訊播放**：音樂預覽功能

## 🔄 開發工作流程

### 新增功能
1. 在對應資料夾創建新檔案
2. 遵循現有的命名規範
3. 更新相關的 import 語句
4. 測試功能完整性

### 檔案命名規範
- **Views**：`功能名稱View.swift`
- **Services**：`功能名稱Service.swift`
- **Models**：`功能名稱Models.swift`
- **Components**：`功能名稱Row.swift` 或 `功能名稱Component.swift`

## 🚀 未來規劃

### 短期目標
- [ ] 優化載入效能
- [ ] 添加更多音樂統計
- [ ] 改善錯誤處理

### 長期目標
- [ ] 支援 Apple Music
- [ ] 社交功能
- [ ] 播放清單管理
- [ ] 離線功能

---

**開發者**：Kenny  
**版本**：1.0  
**最後更新**：2024年7月 