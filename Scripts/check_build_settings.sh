#!/bin/bash

echo "🔍 檢查 Build Settings..."
echo ""

xcodebuild -project MyPlaylist.xcodeproj -target MyPlaylist -showBuildSettings 2>/dev/null | grep -i "APPICON\|ALTERNATE" | grep -v "ALTERNATE_GROUP\|ALTERNATE_MODE\|ALTERNATE_OWNER"

echo ""
echo "✅ 檢查完成"
