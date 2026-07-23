#!/bin/bash
#
# release.sh — build, sign, notarize, and publish an Edward release.
#
# Pipeline: archive (Developer ID) → export → zip → notarize → staple →
#           Sparkle EdDSA signature → appcast.xml → stage into site/public/.
#
# Prerequisites (one-time):
#   * Developer ID Application cert in the login Keychain
#   * Sparkle EdDSA key in the login Keychain (bin/generate_keys)
#   * Notary credentials: xcrun notarytool store-credentials "$NOTARY_PROFILE" \
#       --apple-id <apple-id> --team-id "$TEAM_ID"
#
# Usage: scripts/release.sh          # then deploy with:
#        (cd site && firebase deploy --only hosting:theedward --project jasonsmithio)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEAM_ID="${TEAM_ID:-H7YGQM6U9W}"
NOTARY_PROFILE="${NOTARY_PROFILE:-edward-notary}"
SITE_PUBLIC="$REPO_ROOT/site/public"
DOWNLOAD_BASE_URL="https://theedward.app"
WORK_DIR="$REPO_ROOT/build/release"
ARCHIVE="$WORK_DIR/Edward.xcarchive"
EXPORT_DIR="$WORK_DIR/export"

SPARKLE_BIN="$(ls -d "$HOME"/Library/Developer/Xcode/DerivedData/Edward-*/SourcePackages/artifacts/sparkle/Sparkle/bin 2>/dev/null | head -1)"
[ -n "$SPARKLE_BIN" ] || { echo "error: Sparkle bin tools not found (build once in Xcode to fetch SPM packages)"; exit 1; }

rm -rf "$WORK_DIR" && mkdir -p "$WORK_DIR"

echo "==> Archiving (Release, Developer ID, team $TEAM_ID)"
xcodebuild -project "$REPO_ROOT/Edward.xcodeproj" -scheme Edward -configuration Release \
  -destination 'generic/platform=macOS' -archivePath "$ARCHIVE" archive \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  ENABLE_HARDENED_RUNTIME=YES \
  OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" | tail -3

APP="$ARCHIVE/Products/Applications/Edward.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
ZIP_NAME="Edward-$VERSION.zip"
ZIP="$WORK_DIR/$ZIP_NAME"

echo "==> Re-signing Sparkle nested components (deepest-first, required for notarization)"
IDENTITY="Developer ID Application"
SPARKLE_FW="$APP/Contents/Frameworks/Sparkle.framework"
# Downloader keeps its sandbox entitlement; preserve it.
codesign -f -s "$IDENTITY" -o runtime --timestamp --preserve-metadata=entitlements \
  "$SPARKLE_FW/Versions/B/XPCServices/Downloader.xpc"
codesign -f -s "$IDENTITY" -o runtime --timestamp \
  "$SPARKLE_FW/Versions/B/XPCServices/Installer.xpc"
codesign -f -s "$IDENTITY" -o runtime --timestamp \
  "$SPARKLE_FW/Versions/B/Autoupdate"
codesign -f -s "$IDENTITY" -o runtime --timestamp \
  "$SPARKLE_FW/Versions/B/Updater.app"
codesign -f -s "$IDENTITY" -o runtime --timestamp "$SPARKLE_FW"
# Nested re-signs invalidated the outer seal — re-sign the app, keeping its entitlements.
codesign -f -s "$IDENTITY" -o runtime --timestamp --preserve-metadata=entitlements "$APP"

echo "==> Verifying signature"
codesign --verify --deep --strict "$APP"
SIGN_INFO="$(codesign -dvv "$APP" 2>&1)"
case "$SIGN_INFO" in
  *"Authority=Developer ID"*) echo "Developer ID signature confirmed" ;;
  *) echo "error: app is not signed with Developer ID"; exit 1 ;;
esac

echo "==> Zipping $ZIP_NAME"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Notarizing (waits for Apple)"
NOTARY_OUT="$(xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1)"
echo "$NOTARY_OUT"
case "$NOTARY_OUT" in
  *"status: Accepted"*) ;;
  *) SUB_ID="$(echo "$NOTARY_OUT" | awk '/id:/{print $2; exit}')"
     echo "error: notarization not Accepted. Log: xcrun notarytool log $SUB_ID --keychain-profile $NOTARY_PROFILE"
     exit 1 ;;
esac

echo "==> Stapling ticket to app, re-zipping"
xcrun stapler staple "$APP"
rm -f "$ZIP" && ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Gatekeeper assessment"
spctl --assess --type execute -vv "$APP" 2>&1 | tail -2

echo "==> Sparkle EdDSA signature + appcast"
SIGNATURE_LINE="$("$SPARKLE_BIN/sign_update" "$ZIP")"   # sparkle:edSignature="..." length="..."
BUILD_NUM="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Contents/Info.plist")"
MIN_OS="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$APP/Contents/Info.plist" 2>/dev/null || echo 14.0)"
PUB_DATE="$(LC_ALL=en_US date -u "+%a, %d %b %Y %H:%M:%S +0000")"

cat > "$WORK_DIR/appcast.xml" <<APPCAST
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Edward</title>
    <link>$DOWNLOAD_BASE_URL/appcast.xml</link>
    <description>Updates for Edward, a macOS menu bar manager.</description>
    <language>en</language>
    <item>
      <title>Version $VERSION</title>
      <pubDate>$PUB_DATE</pubDate>
      <sparkle:version>$BUILD_NUM</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MIN_OS</sparkle:minimumSystemVersion>
      <enclosure url="$DOWNLOAD_BASE_URL/releases/$ZIP_NAME" $SIGNATURE_LINE type="application/octet-stream"/>
    </item>
  </channel>
</rss>
APPCAST

echo "==> Staging into site/public"
mkdir -p "$SITE_PUBLIC/releases"
cp "$ZIP" "$SITE_PUBLIC/releases/$ZIP_NAME"
cp "$WORK_DIR/appcast.xml" "$SITE_PUBLIC/appcast.xml"

echo ""
echo "Release $VERSION (build $BUILD_NUM) staged."
echo "Deploy with: (cd site && firebase deploy --only hosting:theedward --project jasonsmithio)"
