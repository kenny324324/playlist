#!/bin/bash
# 將所有 .icon 資料夾內的 SVG 轉換為 PNG
# 使用 qlmanage (macOS 內建) 來轉換

set -e

echo "🔄 開始轉換 SVG 圖示為 PNG..."
echo ""

# 檢查是否有 rsvg-convert 或使用 qlmanage
if command -v rsvg-convert &> /dev/null; then
    CONVERTER="rsvg"
    echo "✅ 使用 rsvg-convert"
elif command -v qlmanage &> /dev/null; then
    CONVERTER="qlmanage"
    echo "✅ 使用 qlmanage (macOS 內建)"
else
    echo "❌ 找不到 SVG 轉換工具"
    echo "請安裝: brew install librsvg"
    exit 1
fi

echo ""

# 計數器
CONVERTED=0
FAILED=0

# 遍歷所有 .icon 資料夾
for icon_dir in AppIcon-*.icon; do
    if [ ! -d "$icon_dir" ]; then
        continue
    fi
    
    echo "📁 處理: $icon_dir"
    
    ASSETS_DIR="$icon_dir/Assets"
    if [ ! -d "$ASSETS_DIR" ]; then
        echo "   ⚠️  跳過 (無 Assets 資料夾)"
        continue
    fi
    
    # 檢查是否已有 PNG
    if ls "$ASSETS_DIR"/*.png 1> /dev/null 2>&1; then
        echo "   ℹ️  已有 PNG 檔案，跳過"
        continue
    fi
    
    # 找出所有 SVG
    SVG_FILES=("$ASSETS_DIR"/*.svg)
    if [ ! -f "${SVG_FILES[0]}" ]; then
        echo "   ⚠️  找不到 SVG 檔案"
        continue
    fi
    
    # 使用第一個 SVG 作為來源 (通常是主圖)
    MAIN_SVG="${SVG_FILES[0]}"
    OUTPUT_PNG="$ASSETS_DIR/Front.png"
    
    echo "   🎨 轉換: $(basename "$MAIN_SVG") -> Front.png"
    
    if [ "$CONVERTER" = "rsvg" ]; then
        # 使用 rsvg-convert，產生 1024x1024 的 PNG
        if rsvg-convert -w 1024 -h 1024 "$MAIN_SVG" -o "$OUTPUT_PNG" 2>/dev/null; then
            echo "   ✅ 轉換成功"
            CONVERTED=$((CONVERTED + 1))
        else
            echo "   ❌ 轉換失敗"
            FAILED=$((FAILED + 1))
        fi
    else
        # 使用 qlmanage (較不理想，但 macOS 內建)
        # 先用 sips 將 SVG 轉為 PNG
        if /usr/bin/sips -s format png "$MAIN_SVG" --out "$OUTPUT_PNG" --resampleWidth 1024 2>/dev/null 1>&2; then
            echo "   ✅ 轉換成功"
            CONVERTED=$((CONVERTED + 1))
        else
            echo "   ❌ 轉換失敗"
            FAILED=$((FAILED + 1))
        fi
    fi
    
    echo ""
done

echo "═══════════════════════════════════════"
echo "📊 轉換完成"
echo "═══════════════════════════════════════"
echo "✅ 成功: $CONVERTED"
echo "❌ 失敗: $FAILED"
echo ""

if [ $CONVERTED -gt 0 ]; then
    echo "✨ 下一步："
    echo "   1. 在 Xcode 中 Clean Build Folder (⌘⇧K)"
    echo "   2. 重新 Build 專案"
    echo "   3. 測試 Icon 切換功能"
    echo ""
fi

if [ $FAILED -gt 0 ]; then
    echo "⚠️  部分轉換失敗，建議安裝 librsvg："
    echo "   brew install librsvg"
    echo ""
fi


