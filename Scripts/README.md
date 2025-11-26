# MyPlaylist 腳本工具

本資料夾包含 MyPlaylist 專案的實用腳本工具。

## 📜 腳本清單

### 🔧 開發工具

#### `check_build_settings.sh`
檢查 Xcode 專案的建置設定。

**用途**：
- 驗證建置配置
- 檢查簽名設定
- 確認 Info.plist 設定

**使用方法**：
```bash
./check_build_settings.sh
```

---

#### `convert_icons_to_png.sh`
將各種格式的圖示轉換為 PNG 格式。

**用途**：
- 轉換 SVG/AI 等格式為 PNG
- 生成不同尺寸的 App Icon
- 準備 App Store 資源

**使用方法**：
```bash
./convert_icons_to_png.sh [輸入文件路徑]
```

---

### 🧹 維護工具

#### `清除快取.sh`
清除專案的各種快取文件。

**清除內容**：
- URLCache（圖片快取）
- UserDefaults 快取
- 暫存文件
- DerivedData

**使用方法**：
```bash
./清除快取.sh
```

**⚠️ 注意**：執行後需要重新建置專案。

---

#### `完全重置步驟.sh`
完全重置專案到初始狀態。

**重置內容**：
- 清除所有快取
- 刪除 DerivedData
- 清除 UserDefaults
- 重置本地資料庫

**使用方法**：
```bash
./完全重置步驟.sh
```

**⚠️ 警告**：
- 會刪除所有本地資料
- 無法復原
- 建議先備份重要資料

---

## 🚀 使用前準備

### 賦予執行權限

首次使用前，需要賦予腳本執行權限：

```bash
cd Scripts
chmod +x *.sh
```

或單獨賦予：

```bash
chmod +x check_build_settings.sh
chmod +x convert_icons_to_png.sh
chmod +x 清除快取.sh
chmod +x 完全重置步驟.sh
```

### 驗證腳本

執行前建議先查看腳本內容：

```bash
cat check_build_settings.sh
```

---

## 📝 腳本開發規範

如果需要新增腳本，請遵循以下規範：

### 命名規則

- **英文** - 通用工具（例如：`build.sh`）
- **中文** - 專案特定工具（例如：`清除快取.sh`）
- 使用小寫字母和底線（英文）
- 使用描述性名稱

### 腳本結構

```bash
#!/bin/bash

# 腳本說明
# 作者：Your Name
# 日期：YYYY-MM-DD

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 主要功能
main() {
    echo -e "${GREEN}開始執行...${NC}"
    
    # 你的程式碼
    
    echo -e "${GREEN}完成！${NC}"
}

# 執行主函數
main "$@"
```

### 錯誤處理

- 使用 `set -e` 遇錯即停
- 提供清晰的錯誤訊息
- 使用顏色區分訊息類型

### 文件記錄

- 在腳本開頭說明用途
- 提供使用範例
- 列出必要的前置條件

---

## 🛡️ 安全提示

### 執行前檢查

1. **確認來源**
   - 只執行信任的腳本
   - 查看腳本內容

2. **備份資料**
   - 執行刪除操作前先備份
   - 使用 Git 保存重要檔案

3. **測試環境**
   - 先在測試環境執行
   - 確認無誤後才在生產環境使用

### 權限管理

```bash
# 查看腳本權限
ls -la *.sh

# 只給自己執行權限
chmod 700 script.sh

# 給所有人執行權限
chmod 755 script.sh
```

---

## 📊 常用命令

### 批次執行

```bash
# 執行所有腳本
for script in *.sh; do
    ./"$script"
done
```

### 查看腳本

```bash
# 查看腳本內容
cat check_build_settings.sh

# 使用語法高亮
bat check_build_settings.sh  # 需要安裝 bat
```

### 除錯

```bash
# 顯示執行過程
bash -x check_build_settings.sh

# 檢查語法
bash -n check_build_settings.sh
```

---

## 🔗 相關資源

- [Bash 腳本教學](https://www.shellscript.sh/)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)

---

## 📝 維護日誌

### 最近更新

**2024-11-26**
- 整理所有腳本到 Scripts 資料夾
- 創建 README 文件
- 標準化腳本格式

---

**最後更新**: 2024-11-26
**維護者**: Kenny

