#!/usr/bin/env bash
set -euo pipefail

APP="Chaxie"
BUNDLE="$APP.app"

rm -rf "$BUNDLE" "$APP"

echo "==> 编译..."
swiftc -O -o "$APP" Sources/main.swift \
    -framework Cocoa -framework UserNotifications

echo "==> 组装 $BUNDLE ..."
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp Info.plist "$BUNDLE/Contents/Info.plist"
mv "$APP" "$BUNDLE/Contents/MacOS/$APP"

# 如果项目根目录有 AppIcon.icns，自动接入图标
if [ -f AppIcon.icns ]; then
    cp AppIcon.icns "$BUNDLE/Contents/Resources/AppIcon.icns"
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" \
        "$BUNDLE/Contents/Info.plist" 2>/dev/null || true
fi

echo "==> Ad-hoc 签名（通知需要）..."
codesign --force --deep --sign - "$BUNDLE"

echo "==> 完成：$BUNDLE"
