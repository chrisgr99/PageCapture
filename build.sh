#!/bin/zsh
# Builds build/PageCapture.app and signs it with a stable identity,
# so the Screen Recording grant survives rebuilds.
set -e
cd "$(dirname "$0")"
swift build -c release
APP=build/PageCapture.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/PageCapture "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"
codesign --force --sign 0BE37A6B0B3B426FD40F8DEAAFF32EA5120839C0 "$APP"
echo "Built $APP"
