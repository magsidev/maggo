#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Maggo"
INSTALL_DIR="/Applications"
TMP_DIR="/tmp/${APP_NAME}_install"

# Update this URL to point to your live website download or GitHub release URL
DOWNLOAD_URL="${DOWNLOAD_URL:-https://github.com/your-username/maggo/releases/latest/download/Maggo-macOS.zip}"

echo "==> Installing ${APP_NAME} for macOS..."

mkdir -p "${TMP_DIR}"

if [[ -f "${PROJECT_DIR:-}/build/${APP_NAME}-macOS.zip" ]]; then
    echo "==> Using local build package..."
    cp "${PROJECT_DIR}/build/${APP_NAME}-macOS.zip" "${TMP_DIR}/${APP_NAME}.zip"
else
    echo "==> Downloading ${APP_NAME}..."
    curl -fsSL "${DOWNLOAD_URL}" -o "${TMP_DIR}/${APP_NAME}.zip"
fi

echo "==> Extracting to ${INSTALL_DIR}..."
unzip -q -o "${TMP_DIR}/${APP_NAME}.zip" -d "${INSTALL_DIR}"

echo "==> Removing quarantine attributes to ensure seamless launch..."
xattr -cr "${INSTALL_DIR}/${APP_NAME}.app"

rm -rf "${TMP_DIR}"

echo "=========================================================="
echo "🎉 ${APP_NAME} installed successfully in ${INSTALL_DIR}!"
echo "   You can now launch it directly from Spotlight or Finder."
echo "=========================================================="
