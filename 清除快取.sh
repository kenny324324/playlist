#!/bin/bash

echo "🧹 開始清除 Xcode 快取..."
echo ""

# 清除 DerivedData
echo "📦 清除 DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "✅ DerivedData 已清除"
echo ""

# 清除模擬器快取
echo "📱 清除模擬器快取..."
xcrun simctl shutdown all 2>/dev/null
xcrun simctl erase all 2>/dev/null
echo "✅ 模擬器快取已清除"
echo ""

echo "🎉 清除完成！"
echo ""
echo "📝 接下來請執行以下步驟："
echo "1. 在 Xcode 中執行 Product → Clean Build Folder (Shift + Cmd + K)"
echo "2. 重新編譯並運行 App (Cmd + R)"
echo "3. 如果還有問題，請重新啟動 Mac"
echo ""

