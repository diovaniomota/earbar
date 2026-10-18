#!/bin/bash
set -euo pipefail

APP_NAME="Earbar"
APP_BUNDLE="$APP_NAME.app"
SDK_PATH=$(xcrun --show-sdk-path)
# Build for this Mac's architecture (arm64 or x86_64); override with ARCH=…
ARCH="${ARCH:-$(uname -m)}"

echo "Building $APP_NAME ($ARCH)..."

swiftc -parse-as-library \
  -O \
  -target "$ARCH-apple-macosx14.0" \
  -sdk "$SDK_PATH" \
  -framework IOBluetooth \
  -framework CoreBluetooth \
  -framework ServiceManagement \
  -framework AppKit \
  -framework SwiftUI \
  Sources/Models/BudsModel.swift \
  Sources/Models/BudsStatus.swift \
  Sources/Models/NoiseControlMode.swift \
  Sources/Models/EqualizerPreset.swift \
  Sources/Models/TouchControls.swift \
  Sources/Diagnostics/DiagnosticsLog.swift \
  Sources/Firmware/FirmwareBinary.swift \
  Sources/Firmware/FirmwareCatalog.swift \
  Sources/Firmware/FirmwareUpdater.swift \
  Sources/Bluetooth/CRC16.swift \
  Sources/Bluetooth/MessageId.swift \
  Sources/Bluetooth/SppMessage.swift \
  Sources/Bluetooth/BluetoothManager.swift \
  Sources/App/PreviewRenderer.swift \
  Sources/Views/BudsModelUI.swift \
  Sources/Views/GlassKit.swift \
  Sources/Views/AncStrengthStepper.swift \
  Sources/Views/ListenModePicker.swift \
  Sources/Views/MenuPopoverView.swift \
  Sources/Views/WizardView.swift \
  Sources/Views/DashboardView.swift \
  Sources/Views/SoundAncView.swift \
  Sources/Views/EqualizerView.swift \
  Sources/Views/EarbudControlsView.swift \
  Sources/Views/FindMyEarbudsView.swift \
  Sources/Views/AboutView.swift \
  Sources/Views/FirmwareUpdateView.swift \
  Sources/Views/PopoverView.swift \
  Sources/App/LaunchAtLogin.swift \
  Sources/App/StatusBarController.swift \
  Sources/App/AppDelegate.swift \
  Sources/App/EarbarApp.swift \
  -o "$APP_NAME"

echo "Creating app bundle..."

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

mv "$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp Sources/Resources/Info.plist "$APP_BUNDLE/Contents/"
[ -f Sources/Resources/AppIcon.icns ] && cp Sources/Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/"

# Copy localization bundles (*.lproj) so the app follows the Mac's language.
for lproj in Sources/Resources/*.lproj; do
  [ -d "$lproj" ] && cp -R "$lproj" "$APP_BUNDLE/Contents/Resources/"
done

# Ad-hoc code sign so macOS TCC can establish a stable identity for the app.
# Without a signature, TCC cannot read the Info.plist usage strings and the
# app crashes on first Bluetooth access ("missing usage description").
echo "Signing (ad-hoc)..."
codesign --force --sign - \
  --identifier io.github.diovaniomota.earbar \
  "$APP_BUNDLE"
codesign --verify --verbose "$APP_BUNDLE" 2>&1 | tail -1

echo "Done! Run with: open $APP_BUNDLE"
