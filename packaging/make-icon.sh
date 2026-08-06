#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

ICONSET="packaging/AppIcon.iconset"
OUT="packaging/AppIcon.icns"

rm -rf "$ICONSET"
swift packaging/make-icon.swift "$ICONSET"
iconutil -c icns "$ICONSET" -o "$OUT"
rm -rf "$ICONSET"

echo "생성됨: $OUT"
