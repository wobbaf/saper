#!/usr/bin/env zsh
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$PROJECT_DIR/saper.xcodeproj"
ARCHIVE="$PROJECT_DIR/build/saper.xcarchive"
EXPORT_DIR="$PROJECT_DIR/build/saper-appstore"
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"
API_KEY="MJYPRN4GK9"
API_ISSUER="0cba0ee4-4705-4b38-b98f-4de8790ade63"
API_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${API_KEY}.p8"
TEAM="Z5NCL9CX9B"

cd "$PROJECT_DIR"

echo "==> Pulling main..."
git checkout main
git pull origin main

echo "==> Bumping build number..."
CURRENT=$(grep -m1 "CURRENT_PROJECT_VERSION" "$PROJECT/project.pbxproj" | grep -o '[0-9]*')
NEXT=$((CURRENT + 1))
sed -i '' "s/CURRENT_PROJECT_VERSION = $CURRENT;/CURRENT_PROJECT_VERSION = $NEXT;/g" "$PROJECT/project.pbxproj"
echo "    Build $CURRENT -> $NEXT"

echo "==> Archiving..."
rm -rf "$ARCHIVE" "$EXPORT_DIR"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme saper \
  -destination "generic/platform=iOS" \
  -configuration Release \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$API_KEY_PATH" \
  -authenticationKeyID "$API_KEY" \
  -authenticationKeyIssuerID "$API_ISSUER" \
  DEVELOPMENT_TEAM="$TEAM" \
  | grep -E "error:|ARCHIVE SUCCEEDED|BUILD FAILED"

echo "==> Exporting..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  | grep -E "error:|EXPORT SUCCEEDED|FAILED"

echo "==> Uploading to TestFlight..."
xcrun altool --upload-app \
  -f "$EXPORT_DIR/saper.ipa" \
  -t ios \
  --apiKey "$API_KEY" \
  --apiIssuer "$API_ISSUER" \
  2>&1 | grep -E "UPLOAD SUCCEEDED|UPLOAD FAILED|ERROR|Delivery UUID"

echo "==> Committing build number..."
git add "$PROJECT/project.pbxproj"
git commit -m "Bump build number to $NEXT"
git push origin main

echo "==> Done. Build 1.0 ($NEXT) is processing in TestFlight."
