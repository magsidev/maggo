#!/bin/bash
set -e

echo "=========================================="
echo "  🚀 Installing Maggo for macOS..."
echo "=========================================="

TEMP_DIR=$(mktemp -d)
ZIP_FILE="${TEMP_DIR}/Maggo-macOS.zip"
DOWNLOAD_URL="https://raw.githubusercontent.com/magsidev/maggo/main/website/public/downloads/Maggo-macOS.zip"

echo "==> 1. Downloading latest Maggo release..."
if ! curl -fsSL --progress-bar -o "${ZIP_FILE}" "${DOWNLOAD_URL}"; then
    echo "❌ Download failed. Please check your internet connection or download directly from https://github.com/magsidev/maggo"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

echo "==> 2. Installing to /Applications..."
killall Maggo 2>/dev/null || true
rm -rf /Applications/Maggo.app
ditto -x -k "${ZIP_FILE}" /Applications/

echo "==> 3. Configuring security & permissions..."
xattr -cr /Applications/Maggo.app

echo "==> 4. Cleaning temporary files..."
rm -rf "${TEMP_DIR}"

echo "=========================================="
echo "  ✅ Maggo successfully installed!"
echo "     Location: /Applications/Maggo.app"
echo "=========================================="

# Launch app cleanly
open /Applications/Maggo.app
