# 儀表板規劃筆記

## 目標
- 讓使用者一開啟 App 即可掌握最新聆聽行為與個人趨勢。
- 保持 Spotify 品牌風格，延續現有視覺與互動語言。
- 預留擴充空間（例如情緒分析、分享、其他串流服務整合）。

## 儀表板核心區塊
- **今日聆聽分鐘數**：顯示當日累計播放時間，附上刷新時間或趨勢箭頭。
- **當週最常聽歌曲／藝人**：前 3 名卡片或列表，可導向 Top 頁面詳看完整排行。
- **快速捷徑**：連結至「正在播放」「最新收藏」「我的播放清單」等常用區域。
- **情緒與節奏趨勢（待定）**：若未來有穩定資料來源，再加入 energy/BPM 走勢圖。

## 資料來源與彙整
- **今日聆聽分鐘數**
  - Endpoint：`GET /v1/me/player/recently-played`
  - 作法：抓取 24 小時內紀錄，依日期累計 `track.duration_ms`；儲存最後一筆 `played_at`，避免重複計算。
  - 快取：使用 `UserDefaults`（`DailyListeningLog` 結構：日期字串＋分鐘數）。
- **當週最常聽歌曲／藝人**
  - 方案 A：`GET /v1/me/top/tracks` 與 `GET /v1/me/top/artists` + `short_term`。
  - 方案 B：從最近播放紀錄中篩 7 天資料，自行統計次數或總播放時間。
  - 快取：`WeeklyTopCache`（包含更新時間與前 N 名清單），減少重複 API 呼叫。
- **情緒／BPM（暫緩）**
  - 原計畫使用 `GET /v1/audio-features` 或 `GET /v1/audio-analysis`，因官方標註 Deprecated 先暫停實作。
  - 預留 service interface，未來若有替代方案可直接對接。

## 架構設計
- **Services**
  - 新增 `DashboardMetricsService`：集中 Spotify API 呼叫、分頁、資料整理與快取寫入。
- **ViewModel**
  - 新增 `DashboardViewModel`：負責 UI 狀態、錯誤處理、定時刷新（例如 App 前景化或手動下拉時觸發）。
- **Models**
  - 擴充 `Models/`，加入 `DashboardSummaryCard`, `WeeklyTopEntry`, `ListeningLog` 等資料結構。
- **快取策略**
  - 初期使用 `UserDefaults` + JSON 編碼；若未來要保留長期趨勢再導入 CoreData/SQLite。

## UI 佈局建議
- Tab 位置：置於 `tab.home`，讓儀表板成為首頁體驗。
- 佈局：`ScrollView` + `LazyVStack`，以「總覽卡片」→「趨勢圖」→「快速捷徑」的順序呈現。
- 元件：新增 `Components/Dashboard/` 子資料夾，放置可重用的卡片、標題列、骨架載入器等。
- 風格：承襲 Spotify 深色系與 spotifyGreen 強調色，卡片背景可用透明玻璃效果或淺灰矩形。
- 空狀態：未登入或資料不足時顯示提示與操作建議（例如引導登入、提示等待同步）。

## 建議實作順序
1. 拉出 UI 雛形（靜態資料），確認首頁流程與定位。
2. 實作 `DashboardMetricsService` 的今日分鐘數計算與快取；串接到 ViewModel/畫面。
3. 擴充每週熱門歌曲／藝人統計，加入手動刷新與快取邏輯。
4. 完善錯誤處理、載入骨架、空狀態提示。
5. 規劃分享／卡片互動（例如導向 Top 頁、收藏播放清單）。
6. 等待/蒐集 Spotify 新的情緒或 BPM 資料來源，再評估加入趨勢圖。
