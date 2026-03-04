#!/bin/bash
set -euo pipefail

# Build the executable
swift build -c release

# Create .app bundle structure
APP_DIR="build/SystemPulse.app/Contents"
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

# Copy executable
cp .build/release/SystemPulse "$APP_DIR/MacOS/SystemPulse"

# Copy Info.plist
cp Info.plist "$APP_DIR/Info.plist"

echo "Built SystemPulse.app at build/SystemPulse.app"
