# Xcode 設定指南 - Demo 模式配置

本指南將幫助您設定 Xcode，以支援 Demo 模式的條件編譯功能。

## 📋 概述

Demo 模式使用 Swift 的條件編譯功能 (`#if APPSTORE_REVIEW`)，讓您可以建立兩個不同的版本：

- **審核版本**：包含 Demo 模式按鈕，供 Apple 審核團隊使用
- **正式版本**：不包含 Demo 模式按鈕，給一般用戶使用

---

## 🛠️ 設定步驟

### 步驟 1：創建新的 Build Configuration

1. 打開 `MyPlaylist.xcodeproj`
2. 在左側專案導覽器中，點擊最上方的**專案檔案**（藍色圖示）
3. 確認選中的是 **PROJECT**（不是 Target）

   ```
   PROJECT
   ↓
   MyPlaylist
   ```

4. 點擊 **Info** 標籤
5. 找到 **Configurations** 區塊
6. 展開 **Configurations** 列表，您會看到：
   ```
   Debug
   Release
   ```

7. 點擊 `Release` 旁邊的 **+** 按鈕
8. 選擇 **Duplicate "Release" Configuration**
9. 命名為 `AppStoreReview`

完成後應該有：
```
✓ Debug
✓ Release  
✓ AppStoreReview  ← 新增的
```

---

### 步驟 2：添加編譯標誌（Compiler Flag）

1. 選擇 **Target**（不是 Project）

   ```
   TARGETS
   ↓
   MyPlaylist
   ```

2. 點擊 **Build Settings** 標籤
3. 確認頂部選擇的是 **All** 和 **Combined**
4. 在搜尋框輸入：`Other Swift Flags`
5. 找到 **Other Swift Flags** 設定項
6. 展開 **AppStoreReview** 這一列（點擊旁邊的箭頭）
7. 雙擊 **AppStoreReview** 列
8. 在彈出的視窗中，點擊 **+** 按鈕
9. 輸入：`-D APPSTORE_REVIEW`
10. 點擊視窗外的任何地方關閉

應該看起來像這樣：

```
Other Swift Flags
├─ Debug          : (空的)
├─ Release        : (空的)
└─ AppStoreReview : -D APPSTORE_REVIEW  ← 新增的
```

⚠️ **注意**：
- 前面要有 `-D` 
- 不要包含 `#` 符號
- 格式：`-D APPSTORE_REVIEW`

---

### 步驟 3：創建審核專用 Scheme

#### 3.1 複製現有 Scheme

1. 點擊 Xcode 頂部中央的 **Scheme 選擇器**（在播放按鈕旁邊）
2. 選擇 **Edit Scheme...**
3. 點擊左下角的 **Duplicate Scheme** 按鈕
4. 命名新 Scheme 為：`MyPlaylist (AppStore Review)`
5. 勾選 **Shared**（這樣團隊成員都能使用）

#### 3.2 配置 Run

1. 確保左側選中 **Run**
2. 在右側的 **Build Configuration** 下拉選單
3. 選擇 **AppStoreReview**

```
Run
├─ Info
│  └─ Build Configuration: AppStoreReview ✓
```

#### 3.3 配置 Archive

1. 在左側選擇 **Archive**
2. 在右側的 **Build Configuration** 下拉選單
3. 選擇 **AppStoreReview**

```
Archive
├─ Archive Info
│  └─ Build Configuration: AppStoreReview ✓
```

4. 點擊 **Close** 關閉視窗

---

### 步驟 4：驗證設定

#### 4.1 檢查 Build Configuration

1. 選擇 Project → Target → Build Settings
2. 搜尋 `Other Swift Flags`
3. 確認 AppStoreReview 有 `-D APPSTORE_REVIEW`

#### 4.2 檢查 Scheme

1. Xcode 頂部應該有兩個 Scheme：
   ```
   MyPlaylist
   MyPlaylist (AppStore Review)
   ```

#### 4.3 測試編譯

##### 測試正式版本：
```
1. 切換到 "MyPlaylist" Scheme
2. Product → Build (⌘B)
3. 應該編譯成功
4. Demo 按鈕不會出現 ✓
```

##### 測試審核版本：
```
1. 切換到 "MyPlaylist (AppStore Review)" Scheme  
2. Product → Build (⌘B)
3. 應該編譯成功
4. Demo 按鈕會出現 ✓
```

---

## 📦 打包和提交流程

### 提交審核時（有 Demo 按鈕）

1. **切換 Scheme**
   ```
   Xcode 頂部 → MyPlaylist (AppStore Review)
   ```

2. **設定版本號**
   - Target → General → Identity
   - Version: `1.0.0`
   - Build: `100`

3. **Archive**
   ```
   Product → Archive
   或按 ⌃⌘B (Control + Command + B)
   ```

4. **上傳到 App Store Connect**
   - Archive 完成後會開啟 Organizer
   - 選擇剛才的 Archive
   - 點擊 **Distribute App**
   - 選擇 **App Store Connect**
   - 按照步驟完成上傳

5. **在 App Store Connect 設定**
   - 登入 [App Store Connect](https://appstoreconnect.apple.com)
   - 選擇您的 App
   - 進入「App 資訊」→「App 審查資訊」
   - **版本發布**選擇：**手動發布此版本** ⚠️ 重要！

---

### 審核通過後（無 Demo 按鈕）

1. **切換 Scheme**
   ```
   Xcode 頂部 → MyPlaylist
   ```

2. **更新 Build 號**
   - Target → General → Identity
   - Version: `1.0.0`（相同）
   - Build: `101`（+1）

3. **Archive**
   ```
   Product → Archive
   ```

4. **上傳新版本**
   - 重複上傳步驟
   - 這次上傳的是沒有 Demo 按鈕的版本

5. **在 App Store Connect 選擇新 Build**
   - 回到 App Store Connect
   - 選擇 Build `101`（新的）
   - 點擊「發布 App」

6. **用戶下載的版本**
   - ✅ 沒有 Demo 按鈕
   - ✅ 乾淨的正式版本

---

## 🔍 常見問題排除

### Q1: Build 時出現 "Use of unresolved identifier 'APPSTORE_REVIEW'"

**原因**：編譯標誌沒有正確設定

**解決方法**：
1. 檢查 Build Settings → Other Swift Flags
2. 確認格式：`-D APPSTORE_REVIEW`（注意 `-D` 和空格）
3. 清理專案：Product → Clean Build Folder (⇧⌘K)
4. 重新建置

---

### Q2: 切換 Scheme 後 Demo 按鈕沒有變化

**原因**：可能使用了舊的建置檔案

**解決方法**：
```bash
1. Product → Clean Build Folder (⇧⌘K)
2. 關閉 Xcode
3. 刪除 DerivedData：
   ~/Library/Developer/Xcode/DerivedData/MyPlaylist-*
4. 重新開啟 Xcode
5. 重新建置
```

---

### Q3: Archive 時找不到 AppStoreReview Configuration

**原因**：Scheme 的 Archive 設定沒有改為 AppStoreReview

**解決方法**：
1. Edit Scheme
2. 選擇 Archive
3. Build Configuration 改為 **AppStoreReview**
4. 重新 Archive

---

### Q4: 兩個 Scheme 看起來沒有差別

**原因**：需要檢查 Build Configuration

**驗證方法**：
```swift
// 在程式碼中添加：
#if APPSTORE_REVIEW
print("✅ 這是審核版本")
#else
print("❌ 這是正式版本")
#endif
```

在 Console 中檢查輸出。

---

## 📊 快速對照表

| 項目 | 正式版本 (MyPlaylist) | 審核版本 (MyPlaylist AppStore Review) |
|-----|---------------------|-----------------------------------|
| **Scheme** | MyPlaylist | MyPlaylist (AppStore Review) |
| **Build Configuration** | Release | AppStoreReview |
| **Other Swift Flags** | (空的) | -D APPSTORE_REVIEW |
| **Demo 按鈕** | ❌ 不顯示 | ✅ 顯示 |
| **提交給誰** | 一般用戶 | Apple 審核團隊 |
| **Build 號** | 101 | 100 |

---

## ✅ 設定完成檢查清單

在提交審核前，請確認：

- [ ] 創建了 `AppStoreReview` Build Configuration
- [ ] 在 Other Swift Flags 中添加了 `-D APPSTORE_REVIEW`
- [ ] 創建了 `MyPlaylist (AppStore Review)` Scheme
- [ ] Scheme 的 Run 和 Archive 都設定為 AppStoreReview
- [ ] 使用審核 Scheme 編譯後，Demo 按鈕有出現
- [ ] 使用正式 Scheme 編譯後，Demo 按鈕沒有出現
- [ ] 在 App Store Connect 設定「手動發布」
- [ ] 準備好正式版本（Build +1）隨時可以上傳

---

## 📝 更新流程摘要

**每次更新時：**

```
1. 修改代碼
2. 更新 Version 和 Build
3. Archive 審核版本 (Scheme: AppStore Review)
4. 提交審核
5. ⏸️ 等待審核通過（不要發布）
6. Archive 正式版本 (Scheme: MyPlaylist)
7. 上傳正式版本 (Build +1)
8. 在 App Store Connect 選擇正式版本
9. 發布給用戶 ✅
```

---

## 💡 提示

- **永遠記得**：審核通過後不要立即發布，先上傳正式版本
- **Version 相同**：審核版本和正式版本的 Version 號碼應該相同
- **Build 遞增**：正式版本的 Build 號應該是審核版本 +1
- **保持整潔**：建議在 Git 中為每個版本打 tag

```bash
# 審核版本
git tag v1.0.0-review-100

# 正式版本
git tag v1.0.0-release-101
```

---

## 🆘 需要幫助？

如果遇到問題：

1. 查看本文檔的「常見問題排除」
2. 清理建置資料夾並重新編譯
3. 檢查 Console 輸出的錯誤訊息
4. 確認每個步驟都正確完成

---

完成設定後，您就可以開始使用 Demo 模式功能了！🎉

