#!/bin/bash

# 完全重置 Xcode 專案的建置快取
# 這會強制 Xcode 重新編譯所有檔案

echo "🧹 開始清理 Xcode 建置快取..."

cd "/Users/jonathanyu/Desktop/𝙿𝚎𝚛𝚜𝚘𝚗𝚗𝚎𝚕/MyPlaylist"

# 1. 刪除 DerivedData
echo "📁 清理 DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/MyPlaylist-*

# 2. 清理專案的 build 資料夾
echo "📁 清理專案 build 資料夾..."
rm -rf build/
rm -rf .build/

# 3. 清理模擬器
echo "📱 清理模擬器..."
xcrun simctl shutdown all
xcrun simctl erase all

echo "✅ 清理完成！"
echo ""
echo "請在 Xcode 中："
echo "1. 按 Shift + Command + K (Clean Build Folder)"
echo "2. 按 Command + B (Build)"
echo "3. 按 Command + R (Run)"

