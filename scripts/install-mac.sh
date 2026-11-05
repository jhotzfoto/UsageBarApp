#!/bin/zsh
# Builds UsageBarApp (Release, signed with the free personal team) and installs it to ~/Applications.
# Build products stay out of iCloud (DerivedData). Re-run after changing anything in mac/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DD="$HOME/Library/Developer/Xcode/DerivedData/UsageBarApp"
cd "$ROOT/mac"
xcodegen generate >/dev/null
xcodebuild -project UsageBarApp.xcodeproj -scheme UsageBarApp -configuration Release -derivedDataPath "$DD" build \
  | grep -E "error:|BUILD (SUCCEEDED|FAILED)" || true
APP="$DD/Build/Products/Release/UsageBarApp.app"
[ -d "$APP" ] || { echo "Build failed"; exit 1; }
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
rm -rf "$HOME/Applications/UsageBarApp.app"
cp -R "$APP" "$HOME/Applications/"
open "$HOME/Applications/UsageBarApp.app"
echo "Installed ~/Applications/UsageBarApp.app"
