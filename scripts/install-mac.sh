#!/bin/zsh
# Builds UsageBarApp (Release, signed with the free personal team) and installs it to ~/Applications.
# Build products stay out of iCloud (DerivedData). Re-run after changing anything in mac/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DD="$HOME/Library/Developer/Xcode/DerivedData/UsageBarApp"
cd "$ROOT/mac"
xcodegen generate >/dev/null
APP="$DD/Build/Products/Release/UsageBarApp.app"
rm -rf "$APP"   # so a failed build can never install the previous one
set +e
xcodebuild -project UsageBarApp.xcodeproj -scheme UsageBarApp -configuration Release -derivedDataPath "$DD" build \
  | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
BUILD_STATUS=${pipestatus[1]}
set -e
[ "$BUILD_STATUS" -eq 0 ] && [ -d "$APP" ] || { echo "Build failed; nothing installed"; exit 1; }
pkill -x UsageBarApp 2>/dev/null || true
# First install only: copy UsageBar's history (read only) so the app's history starts 2026-11-01.
# Done here, not in the app, so the app never needs access to iCloud Drive for it.
DATA="$HOME/Library/Application Support/UsageBarApp"
UB="$ROOT/../UsageBar/data"
mkdir -p "$DATA"
if [ ! -f "$DATA/usage_log.csv" ] && [ -f "$UB/usage_log.csv" ]; then
  cp "$UB/usage_log.csv" "$DATA/usage_log.csv"
  [ -f "$UB/usage_daily.csv" ] && [ ! -f "$DATA/usage_daily.csv" ] && cp "$UB/usage_daily.csv" "$DATA/usage_daily.csv"
  echo "Imported UsageBar history"
fi
mkdir -p "$HOME/Applications"
# Update in place (same path and bundle) so macOS and Ice keep the menu bar item's place.
rsync -a --delete "$APP/" "$HOME/Applications/UsageBarApp.app/"
open "$HOME/Applications/UsageBarApp.app"
echo "Installed ~/Applications/UsageBarApp.app"
