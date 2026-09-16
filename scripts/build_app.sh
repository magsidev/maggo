#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Maggo"
BUNDLE_ID="com.maggo.app"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

echo "==> 1. Building ${APP_NAME} in Release mode..."
cd "${PROJECT_DIR}"
swift build -c release

RELEASE_BIN="$(swift build -c release --show-bin-path)/${APP_NAME}"

echo "==> 2. Assembling ${APP_NAME}.app bundle..."
rm -rf "${BUILD_DIR}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
if [ -f "${PROJECT_DIR}/AppIcon.icns" ]; then
    cp "${PROJECT_DIR}/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

cp "${RELEASE_BIN}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

echo "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

cat <<EOF > "${APP_BUNDLE}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSDesktopFolderUsageDescription</key>
    <string>Maggo requires access to Desktop to browse and manage your files.</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>Maggo requires access to Documents to browse and manage your files.</string>
    <key>NSDownloadsFolderUsageDescription</key>
    <string>Maggo requires access to Downloads to browse and manage your files.</string>
    <key>NSPicturesFolderUsageDescription</key>
    <string>Maggo requires access to your Pictures and Photo Booth library to display your smart photo gallery.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Maggo requires access to your photo library to display your pictures.</string>
    <key>NSRemovableVolumesUsageDescription</key>
    <string>Maggo requires access to external drives to manage your files.</string>
</dict>
</plist>
EOF

echo "==> 3. Ad-hoc code signing for Apple Silicon..."
codesign --force --deep -s - "${APP_BUNDLE}"

echo "==> 4. Verifying code signature..."
codesign -dv "${APP_BUNDLE}"

echo "==> 5. Creating web distribution zip..."
cd "${BUILD_DIR}"
ditto -c -k --keepParent "${APP_NAME}.app" "${APP_NAME}-macOS.zip"

echo "==> 6. Creating DMG..."
hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_NAME}.app" -ov -format UDZO "${APP_NAME}-macOS.dmg"

echo "=========================================="
echo "✅ Build & packaging complete!"
echo "   App:  ${APP_BUNDLE}"
echo "   Zip:  ${BUILD_DIR}/${APP_NAME}-macOS.zip"
echo "   DMG:  ${BUILD_DIR}/${APP_NAME}-macOS.dmg"
echo "=========================================="
