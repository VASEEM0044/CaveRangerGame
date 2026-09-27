#!/usr/bin/env bash
# ==============================================================================
# Cave Ranger — Physical iOS Device IPA Build Script
# Target: iPhone (arm64 / arm64e) compatible with iOS 17.0.0 (TrollStore / Sideload)
# ==============================================================================

set -e

PROJECT_NAME="CaveRangerGame"
SCHEME_NAME="CaveRangerGame"
CONFIGURATION="Release"
BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
PAYLOAD_DIR="${BUILD_DIR}/Payload"
IPA_NAME="CaveRanger.ipa"
OUTPUT_IPA="${BUILD_DIR}/${IPA_NAME}"

echo "=========================================================="
echo " Building ${PROJECT_NAME} for Physical iOS Device (arm64)"
echo " Configuration : ${CONFIGURATION}"
echo " Destination   : generic/platform=iOS (Physical Device)"
echo "=========================================================="

# 1. Clean previous build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# 2. Archive for physical iOS device (generic/platform=iOS)
# CODE_SIGNING_ALLOWED=NO enables compiling a clean unsigned binary ready for TrollStore/Ldid
echo "==> Step 1/3: Creating Xcode Release Archive..."
xcodebuild clean archive \
  -project "${PROJECT_NAME}.xcodeproj" \
  -scheme "${SCHEME_NAME}" \
  -configuration "${CONFIGURATION}" \
  -destination "generic/platform=iOS" \
  -archivePath "${ARCHIVE_PATH}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO

# 3. Locate compiled .app bundle inside archive
APP_BUNDLE=$(find "${ARCHIVE_PATH}/Products/Applications" -name "*.app" -maxdepth 1 2>/dev/null | head -n 1)

if [ -z "${APP_BUNDLE}" ] || [ ! -d "${APP_BUNDLE}" ]; then
  echo "❌ Error: App bundle not found in ${ARCHIVE_PATH}/Products/Applications/"
  ls -la "${ARCHIVE_PATH}/Products/Applications" || true
  exit 1
fi

echo "==> Step 2/3: Packaging ${PROJECT_NAME}.app into IPA Payload structure..."
mkdir -p "${PAYLOAD_DIR}"
cp -R "${APP_BUNDLE}" "${PAYLOAD_DIR}/"

# 4. Create standard IPA zip archive
echo "==> Step 3/3: Creating ${IPA_NAME}..."
cd "${BUILD_DIR}"
zip -qr -9 "${IPA_NAME}" "Payload"
cd ..

if [ -f "${OUTPUT_IPA}" ]; then
  IPA_SIZE=$(du -h "${OUTPUT_IPA}" | cut -f1)
  echo "=========================================================="
  echo "✅ BUILD SUCCESS!"
  echo " Output IPA: ${OUTPUT_IPA} (${IPA_SIZE})"
  echo " Target     : iPhone 11 (iOS 17.0.0 / TrollStore compatible)"
  echo " Install via: AirDrop / iCloud Drive / TrollStore App"
  echo "=========================================================="
else
  echo "❌ Error: Failed to generate IPA."
  exit 1
fi
