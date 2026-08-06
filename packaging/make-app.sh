#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP="Blink.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp packaging/Info.plist "$APP/Contents/Info.plist"
cp "$(swift build -c release --show-bin-path)/Blink" "$APP/Contents/MacOS/Blink"

# 앱 아이콘 생성 후 번들에 포함
bash packaging/make-icon.sh
cp packaging/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# 로컬 실행용 ad-hoc 서명 (SMAppService 등록에 필요)
codesign --force --deep --sign - "$APP"

echo "생성됨: $APP"
echo "설치: '$APP'를 /Applications 로 이동한 뒤 실행하세요."
