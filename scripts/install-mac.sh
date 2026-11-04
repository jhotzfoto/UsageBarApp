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
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/UsageBarApp.app"
cp -R "$APP" "$HOME/Applications/"
open "$HOME/Applications/UsageBarApp.app"
echo "Installed ~/Applications/UsageBarApp.app"
