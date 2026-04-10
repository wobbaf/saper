#!/usr/bin/env zsh
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.ship.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Copy .ship.env.example and fill in your credentials."
  exit 1
fi
source "$ENV_FILE"

PROJECT="$PROJECT_DIR/saper.xcodeproj"
ARCHIVE="$PROJECT_DIR/build/saper.xcarchive"
EXPORT_DIR="$PROJECT_DIR/build/saper-appstore"
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"
API_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_API_KEY}.p8"

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
  -authenticationKeyID "$ASC_API_KEY" \
  -authenticationKeyIssuerID "$ASC_API_ISSUER" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
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
  --apiKey "$ASC_API_KEY" \
  --apiIssuer "$ASC_API_ISSUER" \
  2>&1 | grep -E "UPLOAD SUCCEEDED|UPLOAD FAILED|ERROR|Delivery UUID"

echo "==> Committing build number..."
git add "$PROJECT/project.pbxproj"
git commit -m "Bump build number to $NEXT"
git push origin main

echo "==> Done. Build 1.0 ($NEXT) is processing in TestFlight."
