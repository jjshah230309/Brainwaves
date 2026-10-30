#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build Brainwaves.app with SwiftPM only (no Xcode project, no Xcode IDE).
# Requires the Command Line Tools for Xcode: xcode-select --install
#
# Usage: scripts/build-app.sh [--universal] [--no-am]
#   --universal  build for arm64 and x86_64
#   --no-am      compile amplitude modulation out (see docs/design/legal.md §3)
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ "$(uname)" != "Darwin" ]]; then
  echo "error: the SwiftUI app can only be built on macOS" >&2
  exit 1
fi

ARCH_FLAGS=()
SWIFT_FLAGS=()
for arg in "$@"; do
  case "$arg" in
    --universal) ARCH_FLAGS=(--arch arm64 --arch x86_64) ;;
    --no-am) SWIFT_FLAGS=(-Xswiftc -DBRAINWAVES_NO_AM) ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

VERSION="0.1.0"
APP="build/Brainwaves.app"

swift build -c release --product BrainwavesApp ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"} ${SWIFT_FLAGS[@]+"${SWIFT_FLAGS[@]}"}
BIN_DIR="$(swift build -c release --product BrainwavesApp ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"} --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/BrainwavesApp" "$APP/Contents/MacOS/Brainwaves"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Brainwaves</string>
  <key>CFBundleDisplayName</key><string>Brainwaves</string>
  <key>CFBundleIdentifier</key><string>io.github.jjshah230309.brainwaves</string>
  <key>CFBundleExecutable</key><string>Brainwaves</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.healthcare-fitness</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSSupportsAutomaticTermination</key><false/>
  <key>NSHumanReadableCopyright</key><string>MIT licence. Not a medical device.</string>
</dict>
</plist>
PLIST

# Ad-hoc signature, so the app runs locally. Distribution needs a Developer ID and notarisation (roadmap M4).
# No entitlements are requested: in particular, no network access.
codesign --force --deep --sign - "$APP"

echo "Built $APP"
echo "Run with: open $APP"
