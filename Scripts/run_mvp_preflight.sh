#!/usr/bin/env bash
set -euo pipefail

skip_ios_build=0

for arg in "$@"; do
  case "$arg" in
    --skip-ios-build)
      skip_ios_build=1
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

echo "== MVP rule verifier =="
swift run TimeTankMVPVerifier

echo "== MVP acceptance verifier =="
swift run TimeTankMVPAcceptanceVerifier

echo "== Project metadata lint =="
plutil -lint TimeTank.xcodeproj/project.pbxproj
plutil -lint TimeTank/TimeTank.entitlements
plutil -lint TimeTankMonitor/Info.plist
plutil -lint TimeTankMonitor/TimeTankMonitor.entitlements
plutil -lint TimeTankShieldAction/Info.plist
plutil -lint TimeTankShieldAction/TimeTankShieldAction.entitlements
plutil -lint TimeTankShieldConfiguration/Info.plist
plutil -lint TimeTankShieldConfiguration/TimeTankShieldConfiguration.entitlements
plutil -lint TimeTankReport/Info.plist
plutil -lint TimeTankReport/TimeTankReport.entitlements
plutil -lint TimeTankWidget/Info.plist
plutil -lint TimeTankWidgetExtension.entitlements

if [[ "$skip_ios_build" == "1" ]]; then
  echo "== iOS build skipped by --skip-ios-build =="
  exit 0
fi

echo "== Xcode availability =="
xcode-select -p
xcodebuild -version

echo "== Unsigned iOS Simulator build =="
xcodebuild \
  -project TimeTank.xcodeproj \
  -scheme TimeTank \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
