#!/bin/zsh
# Removes UsageBarApp from this Mac: the app (and its widgets), its shared data and its settings.
# The Claude Code Keychain item is never touched.
set -uo pipefail
pkill -x UsageBarApp 2>/dev/null
rm -rf "$HOME/Applications/UsageBarApp.app"
rm -rf "$HOME/Library/Group Containers/KFT88Q5XQ9.com.joshhotz.usagebarapp"
defaults delete com.joshhotz.UsageBarApp 2>/dev/null
rm -rf "$HOME/Library/Application Support/UsageBarApp"
rm -rf "$HOME/Library/Developer/Xcode/DerivedData/UsageBarApp" "$HOME/Library/Developer/Xcode/DerivedData/UsageCore-spm"
echo "UsageBarApp removed. If you turned on 'Open at login', also remove it in System Settings > General > Login Items."
echo "If you added the status line, remove the statusLine entry from ~/.claude/settings.json."
