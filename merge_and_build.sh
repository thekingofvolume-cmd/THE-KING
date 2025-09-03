#!/usr/bin/env bash
set -euo pipefail

# === CONFIG ===
PROJECT_DIR="./THE-KING-APP"  # Change to your Android project folder
PATCH_ZIP="./android_patch.zip"
PUBKEY_B64="MCowBQYDK2VwAyEA______________________________"
CERT_SHA256="ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
BACKEND_URL="https://api.the-king.trade"
BACKEND_HOST="api.the-king.trade"
SPKI_PIN="sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# === UNZIP PATCH ===
echo "Unzipping patch..."
rm -rf ./_patch_temp
unzip -q "$PATCH_ZIP" -d ./_patch_temp

# === COPY FILES ===
echo "Merging patch into project..."
cp -r ./_patch_temp/app/src/main/java/* "$PROJECT_DIR/app/src/main/java/"
cp -r ./_patch_temp/app/src/main/assets/* "$PROJECT_DIR/app/src/main/assets/"

# === REPLACE PLACEHOLDERS ===
echo "Replacing placeholders..."
find "$PROJECT_DIR/app/src/main/java" -type f -name "*.kt" -exec sed -i '' \
  -e "s|MCowBQYDK2VwAyEA______________________________|$PUBKEY_B64|g" \
  -e "s|ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff|$CERT_SHA256|g" \
  -e "s|https://api.example.com|$BACKEND_URL|g" \
  -e "s|api.example.com|$BACKEND_HOST|g" \
  -e "s|sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=|$SPKI_PIN|g" {} +

# === BUILD APK ===
echo "Building APK..."
cd "$PROJECT_DIR"
./gradlew assembleDebug

APK_PATH=$(find ./app/build/outputs/apk/debug -name "*.apk" | head -n 1)
echo "✅ Build complete: $APK_PATH"
echo "To install: adb install -r \"$APK_PATH\""C:\Users\THE KING\Desktop\THE KING OF VOLUME
cd - ..
# === CLEAN UP ===
echo "Cleaning up..."
rm -rf ./_patch_temp
# rm -rf "$PROJECT_DIR/app/src/main/java/com/theking/app"  # Uncomment to remove patched files after build
# rm -rf "$PROJECT_DIR/app/src/main/assets"  # Uncomment to remove patched files after build
echo "Done."
echo "Note: Patched source files are retained in the project directory."
# Example: rm -rf "$PROJECT_DIR/app/src/main/java/com/theking/app"  # Uncomment to remove patched files after build
# Example: rm -rf "$PROJECT_DIR/app/src/main/assets"  # Uncomment to remove patched files after build
echo "Done."
echo "Note: Patched source files are retained in the project directory."
echo "Note: Patched source files are retained in the project directory."
echo "Note: Patched source files are retained in the project directory."
echo "Note: Patched source files are retained in the project directory."C:\Users\THE KING\Desktop\THE KING OF VOLUME\merge_and_build.sh
echo "Note: Patched source files are retained in the project directory."

C:\Users\THE KING\Desktop\THE KING OF VOLUME\merge_and_build.sh
echo "Note: Patched source files are retained in the project directory."
echo "Note: Patched source files are retained in the project directory."