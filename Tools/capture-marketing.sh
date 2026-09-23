#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_ROOT="${1:-$ROOT/marketing}"
DERIVED_DATA="$ROOT/build/MarketingCapture"
BUNDLE_ID="com.viuniverse.pspo-one"
SCHEME="vipm"
PRACTICE_PART="-Ng-WNrdl0nSTizDrKra"
SCREENS=(home practice question explanation exam navigator results profile)

device_udid() {
  local name="$1"
  xcrun simctl list devices available \
    | grep -F "    $name (" \
    | head -n 1 \
    | grep -Eo '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}'
}

capture_device() {
  local device_name="$1"
  local output_name="$2"
  local udid
  udid="$(device_udid "$device_name")"
  if [[ -z "$udid" ]]; then
    echo "Simulator not found: $device_name" >&2
    exit 1
  fi

  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl install "$udid" "$DERIVED_DATA/Build/Products/Debug-iphonesimulator/vipm.app"
  xcrun simctl ui "$udid" appearance light
  xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4

  mkdir -p "$OUTPUT_ROOT/$output_name/en"
  local index=1
  for screen in "${SCREENS[@]}"; do
    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$udid" "$BUNDLE_ID" \
      -MarketingCapture 1 \
      -MarketingScreen "$screen" \
      -MarketingRoute "$PRACTICE_PART" \
      -AppleLanguages '(en)' \
      -AppleLocale en_US \
      -appLanguage en \
      -hasSeenTour true >/dev/null
    sleep 4
    printf -v number '%02d' "$index"
    xcrun simctl io "$udid" screenshot "$OUTPUT_ROOT/$output_name/en/$number-$screen.png" >/dev/null
    index=$((index + 1))
  done

  xcrun simctl status_bar "$udid" clear
  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
}

xcodebuild \
  -project "$ROOT/vipm.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build

case "${CAPTURE_DEVICE:-both}" in
  iphone) capture_device "iPhone 17 Pro" iphone ;;
  ipad) capture_device "iPad Pro 13-inch (M5)" ipad ;;
  both)
    capture_device "iPhone 17 Pro" iphone
    capture_device "iPad Pro 13-inch (M5)" ipad
    ;;
  *) echo "CAPTURE_DEVICE must be iphone, ipad, or both" >&2; exit 1 ;;
esac

echo "Captured screenshots: $OUTPUT_ROOT"
