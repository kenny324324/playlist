# Apple Music API 整合指南

## 概述

由於 Spotify Preview URL API 已經不可用，本專案現已整合 Apple Music API（MusicKit）作為音樂預覽的備援方案。

## 功能特性

✅ **智能播放系統**
- 優先使用 Spotify preview URL（如果可用）
- 自動 fallback 到 Apple Music
- 無縫切換，使用者體驗流暢

✅ **支援的功能**
- 30 秒音樂預覽播放
- 所有原有的 UI 組件保持不變
- 自動授權管理

## 已完成的修改

### 1. 權限設定
- ✅ 更新 `MyPlaylist.entitlements` 添加網路權限
- ✅ MusicKit 框架已整合

### 2. 新增的檔案

#### `Services/AppleMusicService.swift`
- Apple Music 授權管理
- 歌曲搜尋功能
- ISRC 精確匹配（可選）

#### `Services/AudioPlayer.swift` (已更新)
- 新增 `PlaybackSource` 枚舉（spotify, appleMusic, none）
- 新增 `playTrack()` 方法：智能播放，自動選擇來源
- 更新 `stop()` 方法：支援兩種播放來源

#### `Views/AppleMusicAuthView.swift`
- Apple Music 授權介面
- 顯示授權狀態
- 引導使用者授權

### 3. 更新的 UI 組件

所有使用音樂預覽的組件都已更新：
- ✅ `TrackDetailView.swift`
- ✅ `HomeView.swift`
- ✅ `MiniPlayerBar.swift`

### 4. 本地化字串
已添加以下本地化鍵值（支援 en, ja, ko, zh-Hant）：
- `applemusic.auth.title`
- `applemusic.auth.description`
- `applemusic.auth.reason`
- `applemusic.auth.authorized`
- `applemusic.auth.notAuthorized`
- `applemusic.auth.button`

## 使用方式

### 自動播放（推薦）

所有現有的播放按鈕都已自動更新，會優先嘗試 Spotify，失敗時自動使用 Apple Music：

```swift
Button(action: {
    Task {
        await audioPlayer.playTrack(
            trackName: track.name,
            artistName: artistNames,
            spotifyPreviewUrl: track.preview_url,
            trackId: track.id
        )
    }
}) {
    // 播放按鈕 UI
}
```

### 檢查播放來源

```swift
if audioPlayer.playbackSource == .appleMusic {
    // 使用 Apple Music 播放
} else if audioPlayer.playbackSource == .spotify {
    // 使用 Spotify 播放
}
```

## 在 Xcode 中的設定

### 必須完成的步驟：

1. **在 Xcode 中添加 MusicKit 框架**
   - 打開專案
   - 選擇 Target → General
   - 在 "Frameworks, Libraries, and Embedded Content" 中點擊 "+"
   - 搜尋並添加 `MusicKit.framework`

2. **設定 Capabilities**
   - 選擇 Target → Signing & Capabilities
   - 確認已啟用 "App Sandbox"（macOS）或適當的 capabilities（iOS）

3. **Info.plist 設定**（如果需要）
   - 添加 `NSAppleMusicUsageDescription` 描述為什麼需要使用 Apple Music
   - 範例：「此 App 使用 Apple Music 提供音樂預覽功能」

## 測試流程

1. **首次使用時**
   - 點擊任何播放按鈕
   - 如果 Spotify preview URL 不可用，系統會自動請求 Apple Music 授權
   - 授權完成後即可播放

2. **已授權後**
   - 播放按鈕會自動選擇可用的來源
   - 在 UI 上會顯示當前使用的播放來源（Spotify 或 Apple Music）

## 技術細節

### AudioPlayer 播放邏輯

```
使用者點擊播放
    ↓
檢查 Spotify preview URL
    ↓
有 URL？ 
    是 → 使用 Spotify AVPlayer 播放
    否 ↓
檢查 Apple Music 授權
    ↓
已授權？
    否 → 請求授權
    是 ↓
搜尋 Apple Music 歌曲
    ↓
找到歌曲？
    是 → 使用 MusicKit 播放
    否 → 顯示錯誤訊息
```

### 搜尋策略

Apple Music 搜尋使用：
1. 歌曲名稱 + 藝人名稱組合搜尋
2. 限制結果為 5 個
3. 返回最佳匹配（第一個結果）

可選：使用 ISRC（國際標準錄音編碼）進行精確匹配

## 注意事項

⚠️ **Apple Music 訂閱**
- 播放預覽**不需要** Apple Music 訂閱
- 如果使用者有訂閱，體驗會更好

⚠️ **地區限制**
- Apple Music 在某些地區可能有限制
- 搜尋結果可能因地區而異

⚠️ **授權狀態**
- 使用者可以隨時在系統設定中撤銷授權
- App 會在需要時自動重新請求授權

## 未來改進方向

- [ ] 添加播放來源指示器到更多 UI 組件
- [ ] 緩存 Apple Music 搜尋結果以提升性能
- [ ] 支援更多音樂平台（如 Deezer）
- [ ] 添加使用者偏好設定（選擇優先使用的平台）

## 相關文件

- [Apple MusicKit Documentation](https://developer.apple.com/documentation/musickit)
- [Spotify Web API](https://developer.spotify.com/documentation/web-api)

## 授權

本專案遵循原有授權條款。Apple Music 和 MusicKit 是 Apple Inc. 的商標。

